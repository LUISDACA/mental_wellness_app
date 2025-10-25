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
  final _repo = ChatRepository();
  final _history = <({String role, String content})>[];

  @override
  Widget build(BuildContext context) {
    final gemini = ref.read(geminiServiceProvider);
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Companion Chat')),
      body: user == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('You must sign in to use chat'),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/sign-in'),
                    child: const Text('Go to Sign In'),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: FutureBuilder(
                    future: _repo.all(),
                    builder: (context, snap) {
                      final items =
                          (snap.data ?? []) as List<Map<String, dynamic>>;
                      return ListView(
                        padding: const EdgeInsets.all(12),
                        children: [
                          for (final m in items)
                            Align(
                              alignment: m['role'] == 'user'
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: m['role'] == 'user'
                                      ? Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                      : Theme.of(context)
                                          .colorScheme
                                          .surfaceVariant,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(m['content']),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _input,
                        decoration:
                            const InputDecoration(hintText: 'Write here...'),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: () async {
                        final text = _input.text.trim();
                        if (text.isEmpty) return;
                        _input.clear();

                        await _repo.add(role: 'user', content: text);
                        _history.add((role: 'user', content: text));

                        try {
                          final reply =
                              await gemini.chatOnce(text, history: _history);
                          _history.add((role: 'assistant', content: reply));
                          await _repo.add(role: 'assistant', content: reply);
                          if (mounted) setState(() {});
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Chat error: $e')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
