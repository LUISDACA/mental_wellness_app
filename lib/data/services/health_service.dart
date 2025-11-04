import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env.dart';

class HealthCheckResult {
  final bool supabaseOk;
  final bool geminiOk;
  final String? supabaseError;
  final String? geminiError;
  HealthCheckResult(
      {required this.supabaseOk,
      required this.geminiOk,
      this.supabaseError,
      this.geminiError});
}

class HealthService {
  final _sb = Supabase.instance.client;

  Future<bool> init() => _checkSupabase();

  Future<bool> _checkSupabase() async {
    try {
      // 'recommendations' has public read policy in our schema
      await _sb.from('recommendations').select().limit(1);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<(bool, String?)> _checkSupabaseVerbose() async {
    try {
      await _sb.from('recommendations').select().limit(1);
      return (true, null);
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<(bool, String?)> _checkGemini() async {
    try {
      final model =
          GenerativeModel(model: Env.geminiModel, apiKey: Env.geminiApiKey);
      final res = await model.generateContent([Content.text('ping')]);
      final ok = (res.text ?? '').isNotEmpty;
      return (ok, ok ? null : 'Empty response');
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<HealthCheckResult> run() async {
    final (sOk, sErr) = await _checkSupabaseVerbose();
    final (gOk, gErr) = await _checkGemini();
    return HealthCheckResult(
        supabaseOk: sOk, geminiOk: gOk, supabaseError: sErr, geminiError: gErr);
  }
}
