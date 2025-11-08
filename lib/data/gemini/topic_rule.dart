// lib/data/gemini/topic_rule.dart
class TopicRule {
  final String pattern;
  final String kind; // 'emotion' | 'crisis'
  final String matchType; // 'contains' | 'regex'

  TopicRule({
    required this.pattern,
    required this.kind,
    required this.matchType,
  });

  factory TopicRule.fromRow(Map<String, dynamic> row) {
    return TopicRule(
      pattern: row['pattern'] as String,
      kind: row['kind'] as String,
      matchType: (row['match_type'] as String?) ?? 'contains',
    );
  }

  bool get isEmotion => kind == 'emotion';
  bool get isCrisis => kind == 'crisis';

  bool matches(String text) {
    final t = text.toLowerCase();
    final p = pattern.toLowerCase();
    if (matchType == 'regex') return RegExp(p).hasMatch(t);
    return t.contains(p);
  }
}
