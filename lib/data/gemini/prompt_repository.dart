// lib/data/gemini/prompt_repository.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';

class PromptRepository {
  final SupabaseClient supabase;
  final Map<String, String> _cache = {};
  bool _loaded = false;

  PromptRepository(this.supabase);

  Future<void> _loadIfNeeded() async {
    if (_loaded) return;
    try {
      final rows =
          await supabase.from('empathy_prompts').select('key, content');
      for (final row in rows as List<dynamic>) {
        final key = row['key'] as String?;
        final content = row['content'] as String?;
        if (key != null && content != null) {
          _cache[key] = content;
        }
      }
      AppLogger.info(
        'Loaded ${_cache.length} prompts from Supabase',
        tag: 'PromptRepository',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Error loading prompts from Supabase',
        error: e,
        stack: stack,
        tag: 'PromptRepository',
      );
    } finally {
      _loaded = true;
    }
  }

  Future<String> get(String key, {bool required = false}) async {
    await _loadIfNeeded();
    final value = _cache[key]?.trim() ?? '';
    if (required && value.isEmpty) {
      throw StateError('Missing required prompt: $key');
    }
    if (value.isEmpty) {
      AppLogger.warning('Missing prompt for key: $key',
          tag: 'PromptRepository');
    }
    return value;
  }
}
