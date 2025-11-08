// lib/data/gemini/heuristic_analyzer.dart
import '../../core/constants.dart';
import 'emotion_result.dart';
import 'topic_filter.dart';

class HeuristicAnalyzer {
  final TopicFilter topicFilter;

  HeuristicAnalyzer(this.topicFilter);

  Future<EmotionResult> analyze(String text) async {
    final isCrisis = await topicFilter.isCrisis(text);
    if (isCrisis) {
      return EmotionResult(
        emotion: AppConstants.emotionSadness,
        score: 0.9,
        severity: 95,
        advice: '', // lo rellena el caller con prompt de BD
        type: AnalysisType.heuristic,
      );
    }

    final t = text.toLowerCase();
    String emotion = AppConstants.emotionNeutral;
    int severity = 30;
    double score = 0.5;

    if (t.contains('ansie') || t.contains('preocup')) {
      emotion = AppConstants.emotionAnxiety;
      severity = 60;
      score = 0.8;
    } else if (t.contains('triste') || t.contains('deprim')) {
      emotion = AppConstants.emotionSadness;
      severity = 55;
      score = 0.75;
    } else if (t.contains('enojo') || t.contains('rabia')) {
      emotion = AppConstants.emotionAnger;
      severity = 65;
      score = 0.8;
    } else if (t.contains('feliz') || t.contains('alegr')) {
      emotion = AppConstants.emotionHappiness;
      severity = 15;
      score = 0.8;
    }

    return EmotionResult(
      emotion: emotion,
      score: score,
      severity: severity,
      advice: '',
      type: AnalysisType.heuristic,
    );
  }
}
