class EmotionEntry {
  final String id;
  final String detectedEmotion;
  final double score;
  final int severity;
  final String? advice;
  final DateTime createdAt;

  EmotionEntry({
    required this.id,
    required this.detectedEmotion,
    required this.score,
    required this.severity,
    this.advice,
    required this.createdAt,
  });

  factory EmotionEntry.fromJson(Map<String, dynamic> json) => EmotionEntry(
        id: json['id'] as String,
        detectedEmotion: json['detected_emotion'] as String,
        score: (json['score'] as num).toDouble(),
        severity: (json['severity'] as num).toInt(),
        advice: json['advice'] as String?,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'detected_emotion': detectedEmotion,
        'score': score,
        'severity': severity,
        'advice': advice,
        'created_at': createdAt.toIso8601String(),
      };
}
