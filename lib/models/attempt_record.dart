class AttemptRecord {
  final int levelNumber;
  final String levelTitle;
  final String category;
  final String timestamp;
  /// Derived: [score] >= 1.0. Kept for older analytics files.
  final bool success;
  final double score;
  final int durationMs;
  final Map<String, dynamic>? metrics;

  AttemptRecord({
    required this.levelNumber,
    required this.levelTitle,
    required this.category,
    required this.timestamp,
    required this.success,
    required this.score,
    required this.durationMs,
    this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      'levelTitle': levelTitle,
      'category': category,
      'timestamp': timestamp,
      'success': success,
      'score': score,
      'durationMs': durationMs,
      if (metrics != null && metrics!.isNotEmpty) 'metrics': metrics,
    };
  }

  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    final scoreVal = json['score'];
    final score = scoreVal is num
        ? scoreVal.toDouble()
        : ((json['success'] as bool?) == true ? 1.0 : 0.0);
    final success = json['success'] is bool
        ? json['success'] as bool
        : score >= 1.0;
    return AttemptRecord(
      levelNumber: json['levelNumber'] as int,
      levelTitle: json['levelTitle'] as String,
      category: json["category"] as String,
      timestamp: json['timestamp'] as String,
      success: success,
      score: score,
      durationMs: json['durationMs'] as int,
      metrics: json['metrics'] != null
          ? Map<String, dynamic>.from(json['metrics'] as Map)
          : null,
    );
  }
}
