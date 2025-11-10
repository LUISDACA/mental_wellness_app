import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env.dart';

class HealthCheckResult {
  final bool supabaseOk;
  final bool aiOk;
  final String? supabaseError;
  final String? aiError;

  const HealthCheckResult({
    required this.supabaseOk,
    required this.aiOk,
    this.supabaseError,
    this.aiError,
  });
}

class HealthService {
  SupabaseClient get _sb => Supabase.instance.client;

  /// Chequeo principal
  Future<HealthCheckResult> run() async {
    final (supabaseOk, supabaseError) = await _checkSupabaseVerbose();
    final (aiOk, aiError) = await _checkAi();

    return HealthCheckResult(
      supabaseOk: supabaseOk,
      aiOk: aiOk,
      supabaseError: supabaseError,
      aiError: aiError,
    );
  }

  /// Supabase es crítico.
  /// 1. Verifica que SUPABASE_URL y ANON_KEY existan.
  /// 2. Intenta leer una tabla conocida.
  ///    - Si falla, marcamos supabaseOk = false.
  ///
  /// IMPORTANTE:
  /// - Asegúrate de que 'empathy_prompts' existe y tiene policy de SELECT pública.
  /// - Si no, cambia 'empathy_prompts' por una tabla que seguro funcione.
  Future<(bool, String?)> _checkSupabaseVerbose() async {
    if (Env.supabaseUrl.isEmpty || Env.supabaseAnonKey.isEmpty) {
      return (false, 'SUPABASE_URL o SUPABASE_ANON_KEY vacíos en Env');
    }

    try {
      await _sb.from('app_health').select('key').limit(1);
      return (true, null);
    } catch (e) {
      // Si esta tabla falla, intentamos una segunda opción: emotion_entries
      try {
        await _sb.from('app_health').select('id').limit(1);
        return (true, null);
      } catch (e2) {
        return (false, e2.toString());
      }
    }
  }

  /// IA / Gemini es opcional:
  /// - Si OFFLINE_MODE = true → OK (usas heurística).
  /// - Si no hay GEMINI_API_KEY → OK (app sigue, solo sin IA avanzada).
  /// - Si hay key+modelo → probamos un ping.
  Future<(bool, String?)> _checkAi() async {
    if (Env.offlineMode || Env.geminiApiKey.isEmpty) {
      // No bloqueamos la app si no hay IA o está en modo offline.
      return (true, null);
    }

    if (Env.geminiModel.isEmpty) {
      return (false, 'GEMINI_MODEL vacío');
    }

    try {
      final model = GenerativeModel(
        model: Env.geminiModel,
        apiKey: Env.geminiApiKey,
      );
      final res = await model.generateContent([Content.text('ping')]);
      final ok = (res.text ?? '').isNotEmpty;
      return (ok, ok ? null : 'Respuesta vacía de Gemini');
    } catch (e) {
      // Si falla Gemini, consideramos aiOk = false,
      // pero el StatusBanner solo lo usará para mostrar "AI limitada", no rojo total.
      return (false, e.toString());
    }
  }
}
