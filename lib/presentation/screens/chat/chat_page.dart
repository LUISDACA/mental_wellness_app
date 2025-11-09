// lib/presentation/screens/chat/chat_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/chat_repository.dart';
import '../../providers.dart';
import 'widgets/message_list.dart';
import 'widgets/message_input.dart';

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
      // Ordena por fecha ascendente por si el repo no lo garantiza
      rows.sort((a, b) =>
          _parseDt(a['created_at']).compareTo(_parseDt(b['created_at'])));
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

  // ---------- Helpers ----------
  DateTime _parseDt(dynamic v) {
    if (v is DateTime) return v;
    return DateTime.tryParse('$v') ?? DateTime.now();
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
                : MessageList(
                    messages: _messages,
                    assistantTyping: _assistantTyping,
                    controller: _scroll,
                  ),
          ),
          MessageInput(controller: _input, onSend: _send),
        ],
      ),
    );
  }
}
