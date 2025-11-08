// lib/presentation/providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/gemini/gemini_service.dart';
import '../data/gemini/emotion_result.dart';
import '../data/repositories/emotion_repository.dart';
import '../data/services/places_service.dart';
import '../data/services/post_service.dart';

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final supabase = Supabase.instance.client;
  return GeminiService(supabase);
});

final emotionRepoProvider = Provider<EmotionRepository>((ref) {
  // ajusta según tu constructor real de EmotionRepository
  return EmotionRepository();
  // o si también usa Supabase:
  // final supabase = Supabase.instance.client;
  // return EmotionRepository(supabase);
});

final lastEmotionProvider = StateProvider<EmotionResult?>((_) => null);

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final placesServiceProvider = Provider<PlacesService>((ref) {
  return PlacesService();
});

final postServiceProvider = Provider<PostService>((ref) => PostService());

final postsStreamProvider = StreamProvider((ref) {
  final svc = ref.read(postServiceProvider);
  return svc.streamPosts();
});
