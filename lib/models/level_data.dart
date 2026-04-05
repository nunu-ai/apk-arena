class LevelData {
  final String title;
  final String instructions;

  /// Max time for one run. `null` means default (60 minutes) in [LevelScreen].
  final Duration? timeLimit;

  LevelData({
    required this.title,
    required this.instructions,
    this.timeLimit,
  });
}