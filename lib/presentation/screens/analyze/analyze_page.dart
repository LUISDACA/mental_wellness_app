import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/env.dart';
import '../../../data/services/speech_service.dart';
import '../../../data/services/profile_service.dart';
import '../../providers.dart';
import 'widgets/history_list.dart';
import 'widgets/analyze_input.dart';
import 'widgets/result_overlay.dart';
import 'widgets/loading_overlay.dart';

class AnalyzePage extends ConsumerStatefulWidget {
  const AnalyzePage({super.key});
  @override
  ConsumerState<AnalyzePage> createState() => _AnalyzePageState();
}

class _AnalyzePageState extends ConsumerState<AnalyzePage> {
  final _textCtrl = TextEditingController();
  final _listCtrl = ScrollController();
  final _speech = SpeechService();
  final _profileSvc = ProfileService();

  bool _loading = false;
  bool _listening = false;

  String? _avatarUrl;
  List<Map<String, dynamic>> _history = [];

  bool _showResult = false;
  String? _rEmotion;
  int? _rSeverity; // 0..100
  num? _rScore; // 0..1
  String? _rAdvice;

  @override
  void initState() {
    super.initState();
    _prime();
  }

  @override
  void dispose() {
    _listCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _prime() async {
    setState(() => _loading = true);
    try {
      final me = await _profileSvc.getOrCreateMyProfile();
      _avatarUrl = _profileSvc.publicAvatarUrl(me.avatarPath);
      await _loadHistory();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cargar: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadHistory() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _history = []);
      return;
    }

    final rows = await Supabase.instance.client
        .from('emotion_entries')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: true)
        .limit(200);

    final parsed = (rows as List)
        .map((e) => (e as Map).map((k, v) => MapEntry('$k', v)))
        .toList();

    setState(() => _history = parsed);

    await Future.delayed(const Duration(milliseconds: 40));
    if (_listCtrl.hasClients) {
      _listCtrl.jumpTo(_listCtrl.position.maxScrollExtent);
    }
  }

  Future<bool> _ensureMic() async {
    try {
      final status = await Permission.microphone.request();
      return status.isGranted || status.isLimited;
    } catch (_) {
      return true;
    }
  }

  Future<void> _onDictate() async {
    if (_listening) {
      await _speech.stop();
      setState(() => _listening = false);
      return;
    }
    final ok = await _ensureMic();
    if (!ok) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permiso de micrófono denegado')),
      );
      return;
    }
    final init = await _speech.init();
    if (!init) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Dictado no disponible en este dispositivo')),
      );
      return;
    }
    setState(() => _listening = true);
    await _speech.start((partial) {
      setState(() {
        _textCtrl.text = partial;
        _textCtrl.selection =
            TextSelection.collapsed(offset: _textCtrl.text.length);
      });
    });
  }

  // Detecta si el resultado corresponde al caso "no puedo analizar este mensaje"
  bool _isOutOfScopeResult({
    required String emotion,
    required int severity,
    required num score,
    required String advice,
  }) {
    return emotion.toLowerCase() == 'neutral' &&
        severity == 0 &&
        (score == 0 || score == 0.0) &&
        advice.contains(
            'No puedo analizar este mensaje porque no está relacionado con tus emociones o tu bienestar emocional');
  }

  Future<void> _onAnalyze() async {
    final input = _textCtrl.text.trim();
    if (input.isEmpty) return;

    final gemini = ref.read(geminiServiceProvider);
    final repo = ref.read(emotionRepoProvider);

    setState(() => _loading = true);
    try {
      // 1) analizamos SOLO el texto del usuario
      final res = await gemini.analyzeText(input);
      ref.read(lastEmotionProvider.notifier).state = res;

      final isOutOfScope = _isOutOfScopeResult(
        emotion: res.emotion,
        severity: res.severity,
        score: res.score,
        advice: res.advice,
      );

      if (isOutOfScope) {
        // ❌ NO guardamos en emotion_entries
        // ❌ NO añadimos al _history
        // ✅ Solo mostramos el mensaje al usuario
        setState(() {
          _rEmotion = 'Neutral';
          _rSeverity = 0;
          _rScore = 0;
          _rAdvice = res.advice;
          _showResult = true;
          _textCtrl.clear();
        });
        return;
      }

      // 2) Solo si es un análisis válido, guardamos en DB
      final uid = Supabase.instance.client.auth.currentUser?.id;
      if (uid == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Inicia sesión para guardar el análisis')),
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

      // 3) Actualizamos la lista en memoria
      final now = DateTime.now().toUtc();
      setState(() {
        _history.add({
          'created_at': now.toIso8601String(),
          'text_input': input,
          'detected_emotion': res.emotion,
          'score': res.score,
          'severity': res.severity,
          'advice': res.advice,
          'model': Env.geminiModel,
        });
        _textCtrl.clear();

        _rEmotion = res.emotion;
        _rSeverity = res.severity;
        _rScore = res.score;
        _rAdvice = res.advice;
        _showResult = true;
      });

      await Future.delayed(const Duration(milliseconds: 30));
      if (_listCtrl.hasClients) {
        _listCtrl.animateTo(
          _listCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error analizando: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analizar emoción'),
        actions: [
          IconButton(
            tooltip: 'Recargar historial',
            onPressed: _loadHistory,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // LISTADO HISTORIAL
              Expanded(
                child: HistoryList(
                  history: _history,
                  controller: _listCtrl,
                  avatarUrl: _avatarUrl,
                  locale: locale,
                ),
              ),

              // INPUT + BOTONES
              AnalyzeInput(
                controller: _textCtrl,
                listening: _listening,
                onDictate: _onDictate,
                onAnalyze: _onAnalyze,
              ),
            ],
          ),

          // OVERLAY RESULTADO
          ResultOverlay(
            visible: _showResult,
            emotion: _rEmotion,
            severity: _rSeverity,
            score: _rScore,
            advice: _rAdvice,
            onClose: () => setState(() => _showResult = false),
            onOpenSos: () {
              context.go('/sos');
            },
          ),

          LoadingOverlay(loading: _loading),
        ],
      ),
    );
  }
}
