/// Result of a finished level run. [score] is always in [0, 1] after normalization.
class LevelOutcome {
  final double score;
  final Map<String, dynamic> metrics;
  final Set<String>? visibleMetricKeys;

  LevelOutcome({
    required double score,
    Map<String, dynamic>? metrics,
    Iterable<String>? visibleMetricKeys,
  }) : score = _normalizeScore(score),
       metrics = Map<String, dynamic>.from(metrics ?? const {}),
       visibleMetricKeys = visibleMetricKeys == null
           ? null
           : Set<String>.unmodifiable(visibleMetricKeys);

  static double _normalizeScore(double s) {
    if (s.isNaN || s.isInfinite) return 0;
    if (s < 0) return 0;
    if (s > 1) return 1;
    return s;
  }
}
