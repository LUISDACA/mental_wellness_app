import '../../core/constants.dart';

class EmotionEntry {
  final String id;
  final String detectedEmotion;
  final double score;
  final int severity;
  final String? advice;
  final DateTime createdAt;

  EmotionEntry({
    required this.id,
    required String detectedEmotion,
    required double score,
    required int severity,
    this.advice,
    required this.createdAt,
  })  : detectedEmotion = _validateEmotion(detectedEmotion),
        score = _validateScore(score),
        severity = _validateSeverity(severity);

  /// Validates that the emotion is one of the recognized types
  static String _validateEmotion(String emotion) {
    if (!AppConstants.validEmotions.contains(emotion)) {
      throw ArgumentError(
        'Invalid emotion: "$emotion". Must be one of: ${AppConstants.validEmotions.join(", ")}',
      );
    }
    return emotion;
  }

  /// Validates that the score is between 0.0 and 1.0
  static double _validateScore(double score) {
    if (score < AppConstants.scoreMin || score > AppConstants.scoreMax) {
      throw RangeError(
        'Score must be between ${AppConstants.scoreMin} and ${AppConstants.scoreMax}, got: $score',
      );
    }
    return score;
  }

  /// Validates that the severity is between 0 and 100
  static int _validateSeverity(int severity) {
    if (severity < AppConstants.severityMin ||
        severity > AppConstants.severityMax) {
      throw RangeError(
        'Severity must be between ${AppConstants.severityMin} and ${AppConstants.severityMax}, got: $severity',
      );
    }
    return severity;
  }

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
