// lib/data/gemini/topic_filter.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/logger.dart';
import 'topic_rule.dart';

class TopicFilter {
  final SupabaseClient supabase;
  final List<TopicRule> _rules = [];
  bool _loaded = false;

  TopicFilter(this.supabase);

  Future<void> _loadIfNeeded() async {
    if (_loaded) return;
    try {
      final rows = await supabase
          .from('empathy_topic_rules')
          .select('pattern, kind, match_type')
          .eq('active', true);

      for (final row in rows as List<dynamic>) {
        _rules.add(TopicRule.fromRow(row as Map<String, dynamic>));
      }

      AppLogger.info(
        'Loaded ${_rules.length} topic rules',
        tag: 'TopicFilter',
      );
    } catch (e, stack) {
      AppLogger.error(
        'Error loading topic rules',
        error: e,
        stack: stack,
        tag: 'TopicFilter',
      );
    } finally {
      _loaded = true;
    }
  }

  Future<bool> isEmotional(String text) async {
    await _loadIfNeeded();
    if (_rules.isEmpty) {
      AppLogger.warning(
        'No topic rules configured; treating as out-of-scope',
        tag: 'TopicFilter',
      );
      return false;
    }
    final t = text.toLowerCase();
    final crisis = _rules.any((r) => r.isCrisis && r.matches(t));
    if (crisis) return true;
    return _rules.any((r) => r.isEmotion && r.matches(t));
  }

  Future<bool> isCrisis(String text) async {
    await _loadIfNeeded();
    if (_rules.isEmpty) return false;
    final t = text.toLowerCase();
    return _rules.any((r) => r.isCrisis && r.matches(t));
  }
}
