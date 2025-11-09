// Modelo para entradas del historial emocional

class HistoryEntry {
  final DateTime createdAt;
  final String emotion; // happiness | sadness | anxiety | anger | neutral
  final double score;
  final int severity;
  final String? advice; // consejo de la IA
  final String? textInput; // lo que escribiste

  HistoryEntry({
    required this.createdAt,
    required this.emotion,
    required this.score,
    required this.severity,
    this.advice,
    this.textInput,
  });

  factory HistoryEntry.fromMap(Map<String, dynamic> m) {
    final rawEmotion =
        (m['detected_emotion'] ?? m['emotion'] ?? m['label'] ?? 'neutral')
            .toString();
    final dtRaw = (m['created_at'] ?? m['timestamp'] ?? m['date']).toString();
    final advice =
        (m['advice'] ?? m['ai_advice'] ?? m['response'] ?? m['message'])
            ?.toString();
    final text = (m['text_input'] ?? m['text'] ?? m['prompt'])?.toString();

    return HistoryEntry(
      createdAt: DateTime.parse(dtRaw),
      emotion: _canonicalEmotion(rawEmotion),
      score: (m['score'] is num) ? (m['score'] as num).toDouble() : 0.0,
      severity: (m['severity'] is num) ? (m['severity'] as num).toInt() : 0,
      advice: advice,
      textInput: text,
    );
  }

  static String _canonicalEmotion(String raw) {
    final s = raw.trim().toLowerCase();
    if (s == 'happiness' || s == 'felicidad' || s.contains('alegr')) {
      return 'happiness';
    }
    if (s == 'sadness' || s == 'tristeza' || s.contains('depres')) {
      return 'sadness';
    }
    if (s == 'anxiety' ||
        s == 'ansiedad' ||
        s.contains('estres') ||
        s.contains('estrés') ||
        s.contains('miedo')) {
      return 'anxiety';
    }
    if (s == 'anger' || s == 'enojo' || s == 'ira' || s.contains('rabia')) {
      return 'anger';
    }
    if (s == 'neutral' || s.contains('calm') || s.contains('tranq')) {
      return 'neutral';
    }
    return 'neutral';
  }
}