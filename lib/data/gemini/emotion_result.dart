enum AnalysisType { ai, heuristic }

class EmotionResult {
  final String emotion; // happiness|sadness|anxiety|anger|neutral
  final double score; // 0..1
  final int severity; // 0..100
  final String advice;
  final AnalysisType type;

  EmotionResult({
    required this.emotion,
    required this.score,
    required this.severity,
    required this.advice,
    this.type = AnalysisType.ai,
  });

  bool get isAiGenerated => type == AnalysisType.ai;

  // método normal, NO getter
  bool isCrisis(int crisisThreshold) => severity >= crisisThreshold;
}
