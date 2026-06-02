/// Result of a finished level run. [score] is always in [0, 1] after normalization.
class LevelOutcome {
  static const int maxAdditionalMetrics = 4;
  static const Set<String> _redundantTimeMetricKeys = {
    'time_ms',
    'duration_ms',
    'elapsed_ms',
    'elapsed_time_ms',
    'completion_time_ms',
    'total_time_ms',
  };
  static const List<String> _priorityMetricKeys = [
    'timed_out',
    'abandoned',
    'gave_up',
  ];

  final double score;
  final Map<String, dynamic> metrics;
  final Set<String>? visibleMetricKeys;

  LevelOutcome({
    required double score,
    Map<String, dynamic>? metrics,
    Iterable<String>? visibleMetricKeys,
  }) : score = _normalizeScore(score),
       metrics = _sanitizeMetrics(metrics),
       visibleMetricKeys = visibleMetricKeys == null
           ? null
           : Set<String>.unmodifiable(
               visibleMetricKeys.where(_sanitizeMetrics(metrics).containsKey),
             );

  static double _normalizeScore(double s) {
    if (s.isNaN || s.isInfinite) return 0;
    if (s < 0) return 0;
    if (s > 1) return 1;
    return s;
  }

  static Map<String, dynamic> _sanitizeMetrics(Map<String, dynamic>? metrics) {
    if (metrics == null || metrics.isEmpty) return {};

    final source = Map<String, dynamic>.from(metrics);
    final sanitized = <String, dynamic>{};

    void addIfAllowed(String key, dynamic value) {
      if (sanitized.length >= maxAdditionalMetrics) return;
      if (_redundantTimeMetricKeys.contains(key)) return;
      if (_isNumericArrayMetric(value)) return;
      sanitized[key] = value;
    }

    for (final key in _priorityMetricKeys) {
      if (source.containsKey(key)) {
        addIfAllowed(key, source[key]);
      }
    }

    for (final entry in source.entries) {
      if (sanitized.containsKey(entry.key)) continue;
      addIfAllowed(entry.key, entry.value);
    }

    return sanitized;
  }

  static bool _isNumericArrayMetric(dynamic value) {
    return value is List && value.every((item) => item is num);
  }
}
