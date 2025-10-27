import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/env.dart';
import '../../../data/services/speech_service.dart';
import '../../providers.dart';

class AnalyzePage extends ConsumerStatefulWidget {
  const AnalyzePage({super.key});
  @override
  ConsumerState<AnalyzePage> createState() => _APState();
}

class _APState extends ConsumerState<AnalyzePage> {
  final _text = TextEditingController();
  final _speech = SpeechService();
  bool _listening = false;

  Future<bool> _ensureMic() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      // En web/escritorio puede no aplicar; dejamos pasar.
      return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final gemini = ref.read(geminiServiceProvider);
    final repo = ref.read(emotionRepoProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Analyze Emotion')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _text,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: 'How are you feeling? Write it here...',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton(
                  onPressed: () async {
                    if (!_listening) {
                      final allow = await _ensureMic();
                      if (!allow) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Microphone permission denied')),
                        );
                        return;
                      }
                      final ok = await _speech.init();
                      if (ok) {
                        setState(() => _listening = true);
                        await _speech.start((partial) {
                          setState(() {
                            _text.text = partial;
                            _text.selection = TextSelection.fromPosition(
                              TextPosition(offset: _text.text.length),
                            );
                          });
                        });
                      } else {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content:
                                  Text('Speech recognition not available')),
                        );
                      }
                    } else {
                      await _speech.stop();
                      setState(() => _listening = false);
                    }
                  },
                  child: Text(_listening ? 'Stop mic' : 'Dictate'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () async {
                    final input = _text.text.trim();
                    if (input.isEmpty) return;

                    try {
                      final res = await gemini.analyzeText(input);
                      ref.read(lastEmotionProvider.notifier).state = res;

                      final uid = Supabase.instance.client.auth.currentUser?.id;
                      if (uid == null) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Please sign in to save your analysis.')),
                        );
                      } else {
                        await repo.save(
                          userId: uid,
                          text: input,
                          emotion: res.emotion,
                          score: res.score,
                          severity: res.severity,
                          advice: res.advice,
                          model: Env.geminiModel,
                        );
                      }

                      if (!mounted) return;
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(
                              'Detected: ${res.emotion} (${(res.score * 100).toStringAsFixed(0)}%)'),
                          content: Text(
                              'Advice: ${res.advice}\nSeverity: ${res.severity}/100'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                            if (res.severity >= 75)
                              TextButton(
                                onPressed: () async {
                                  // TODO: leer de DB un contacto SOS real
                                  final uri = Uri(scheme: 'tel', path: '123');
                                  await launchUrl(uri);
                                },
                                child: const Text('SOS'),
                              ),
                          ],
                        ),
                      );
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Analyze error: $e')),
                      );
                    }
                  },
                  child: const Text('Analyze'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
