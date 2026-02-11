class AttemptRecord {
  final int levelNumber;
  final String levelTitle;
  final String difficulty;
  final String timestamp;
  final bool success;
  final int durationMs;
  final Map<String, dynamic>? metrics;

  AttemptRecord({
    required this.levelNumber,
    required this.levelTitle,
    required this.difficulty,
    required this.timestamp,
    required this.success,
    required this.durationMs,
    this.metrics,
  });

  Map<String, dynamic> toJson() {
    return {
      'levelNumber': levelNumber,
      'levelTitle': levelTitle,
      'difficulty': difficulty,
      'timestamp': timestamp,
      'success': success,
      'durationMs': durationMs,
      if (metrics != null && metrics!.isNotEmpty) 'metrics': metrics,
    };
  }

  factory AttemptRecord.fromJson(Map<String, dynamic> json) {
    return AttemptRecord(
      levelNumber: json['levelNumber'] as int,
      levelTitle: json['levelTitle'] as String,
      difficulty: json['difficulty'] as String,
      timestamp: json['timestamp'] as String,
      success: json['success'] as bool,
      durationMs: json['durationMs'] as int,
      metrics: json['metrics'] != null
          ? Map<String, dynamic>.from(json['metrics'] as Map)
          : null,
    );
  }
}
