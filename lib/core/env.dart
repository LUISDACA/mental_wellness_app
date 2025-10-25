class Env {
  static const supabaseUrl =
      String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  static const supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  static const geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  static const geminiModel = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-1.5-flash-latest',
  );

  static const defaultSosLabel = String.fromEnvironment(
    'DEFAULT_SOS_LABEL',
    defaultValue: 'Emergency',
  );

  /// ✅ En web, usa SIEMPRE constructores const de entorno:
  static const offlineMode =
      bool.fromEnvironment('OFFLINE_MODE', defaultValue: false);
}
