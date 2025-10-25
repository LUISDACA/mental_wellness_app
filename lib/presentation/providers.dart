import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/services/gemini_service.dart';
import '../data/repositories/emotion_repository.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) => GeminiService());
final emotionRepoProvider = Provider<EmotionRepository>((ref) => EmotionRepository());

final lastEmotionProvider = StateProvider<EmotionResult?>((_) => null);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});
