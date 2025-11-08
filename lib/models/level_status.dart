
enum LevelResult {
  notAttempted,
  success,
  failed,
}

class LevelStatus {
  final LevelResult result;
  final Duration? completionTime;

  LevelStatus({
    required this.result,
    this.completionTime,
  });

  LevelStatus copyWith({
    LevelResult? result,
    Duration? completionTime,
  }) {
    return LevelStatus(
      result: result ?? this.result,
      completionTime: completionTime ?? this.completionTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'result': result.index,
      'completionTime': completionTime?.inMilliseconds,
    };
  }

  factory LevelStatus.fromJson(Map<String, dynamic> json) {
    return LevelStatus(
      result: LevelResult.values[json['result'] as int],
      completionTime: json['completionTime'] != null
          ? Duration(milliseconds: json['completionTime'] as int)
          : null,
    );
  }
}