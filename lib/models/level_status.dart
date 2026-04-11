class LevelStatus {
  /// Best score seen for this level in [0, 1]. `null` if no run has finished yet.
  final double? bestScore;

  /// Elapsed time (ms) for the run that achieved [bestScore] (or tied with a faster time).
  final int? durationMsAtBest;

  LevelStatus({
    this.bestScore,
    this.durationMsAtBest,
  });

  LevelStatus copyWith({
    double? bestScore,
    int? durationMsAtBest,
  }) {
    return LevelStatus(
      bestScore: bestScore ?? this.bestScore,
      durationMsAtBest: durationMsAtBest ?? this.durationMsAtBest,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bestScore': bestScore,
      'durationMsAtBest': durationMsAtBest,
    };
  }

  factory LevelStatus.fromJson(Map<String, dynamic> json) {
    // New format
    if (json.containsKey('bestScore')) {
      final bs = json['bestScore'];
      return LevelStatus(
        bestScore: bs == null ? null : (bs as num).toDouble(),
        durationMsAtBest: json['durationMsAtBest'] as int?,
      );
    }

    // Legacy: result + completionTime
    final resultIndex = json['result'] as int?;
    if (resultIndex != null && resultIndex >= 0 && resultIndex < 3) {
      // 0 notAttempted, 1 success, 2 failed
      final completionMs = json['completionTime'] as int?;
      if (resultIndex == 1) {
        return LevelStatus(
          bestScore: 1.0,
          durationMsAtBest: completionMs,
        );
      }
      if (resultIndex == 2) {
        return LevelStatus(
          bestScore: 0.0,
          durationMsAtBest: completionMs,
        );
      }
    }

    return LevelStatus();
  }
}
