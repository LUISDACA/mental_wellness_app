// lib/presentation/screens/chat/chat_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/chat_repository.dart';
import '../../providers.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});
  @override
  ConsumerState<ChatPage> createState() => _CP();
}

class _CP extends ConsumerState<ChatPage> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final _repo = ChatRepository();

  /// Lista de mensajes en memoria (ascendente: viejo → nuevo).
  final List<Map<String, dynamic>> _messages = [];

  /// Historial para pasar a Gemini (user/assistant).
  List<({String role, String content})> get _history => _messages
      .map((m) => (role: '${m['role']}', content: '${m['content']}'))
      .toList();

  bool _loadingInit = true;
  bool _assistantTyping = false;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final rows = await _repo.all(); // [{role, content, created_at}, ...]
      _messages
        ..clear()
        ..addAll(rows.map((e) => {
              'role': e['role'],
              'content': e['content'],
              'created_at': e['created_at'],
            }));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar el chat: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loadingInit = false);
        // baja al último mensaje
        await Future<void>.delayed(const Duration(milliseconds: 60));
        _scrollToBottom(jump: true);
      }
    }
  }

  void _scrollToBottom({bool jump = false}) {
    if (!_scroll.hasClients) return;
    final max = _scroll.position.maxScrollExtent;
    if (jump) {
      _scroll.jumpTo(max);
    } else {
      _scroll.animateTo(
        max,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _send() async {
    final gemini = ref.read(geminiServiceProvider);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes iniciar sesión para chatear')),
      );
      return;
    }

    final text = _input.text.trim();
    if (text.isEmpty) return;

    // 1) pinta mi mensaje al instante
    _input.clear();
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
    });
    _scrollToBottom();

    // Guarda en BD (no bloquea la UI)
    unawaited(_repo.add(role: 'user', content: text));

    // 2) muestra indicador “escribiendo…”
    setState(() => _assistantTyping = true);
    _scrollToBottom();

    try {
      // 3) pide respuesta a Gemini con el historial
      final reply = await gemini.chatOnce(text, history: _history);

      // 4) quita “escribiendo…” y agrega respuesta
      setState(() {
        _assistantTyping = false;
        _messages.add({
          'role': 'assistant',
          'content': reply,
          'created_at': DateTime.now().toIso8601String(),
        });
      });
      _scrollToBottom();

      // Guarda respuesta en BD
      unawaited(_repo.add(role: 'assistant', content: reply));
    } catch (e) {
      if (!mounted) return;
      setState(() => _assistantTyping = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Chat error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Chat de compañía')),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Debes iniciar sesión para usar el chat'),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: () => Navigator.of(context).pushNamed('/sign-in'),
                child: const Text('Ir a Iniciar sesión'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Chat de compañía')),
      body: Column(
        children: [
          Expanded(
            child: _loadingInit
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    itemCount: _messages.length + (_assistantTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      // si el último es "escribiendo..."
                      final isTypingRow =
                          _assistantTyping && index == _messages.length;
                      if (isTypingRow) {
                        return const _TypingBubble();
                      }

                      final m = _messages[index];
                      final isUser = m['role'] == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 720),
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isUser
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primaryContainer
                                  : Theme.of(context)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${m['content']}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _input,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe aquí…',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(12)),
                        ),
                        filled: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Burbuja “escribiendo…” con 3 puntitos animados simples
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> {
  int _dots = 1;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(milliseconds: 400), (_) {
      setState(() => _dots = _dots % 3 + 1);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = 'Escribiendo${'.' * _dots}';
    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ),
    );
  }
}
