import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/env.dart';

class Supa {
  static Future<void> init() async {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
      realtimeClientOptions: const RealtimeClientOptions(eventsPerSecond: 20),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
