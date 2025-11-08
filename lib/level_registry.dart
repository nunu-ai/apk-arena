import '../models/level_data.dart';
import '../widgets/level_widget.dart';
import 'widgets/levels/level_click_button.dart';

class LevelEntry {
  final LevelData data;
  final LevelWidget Function(Function(bool) onComplete) widgetBuilder;

  LevelEntry({
    required this.data,
    required this.widgetBuilder,
  });
}

final Map<int, LevelEntry> levelsRegistry = {
  0: LevelEntry(
    data: LevelData(title: "Simple Button", instructions: "Click the Button!"),
    widgetBuilder: (onComplete) => LevelClickButton(onComplete: onComplete),
  ),
};

List<int> getAvailableLevels() {
  return levelsRegistry.keys.toList()..sort();
}

List<int> getLevelsForDifficulty(int difficulty) {
  return levelsRegistry.entries
      .where((entry) => 100*difficulty <= entry.key && entry.key < 100*(difficulty+1))
      .map((entry) => entry.key)
      .toList()..sort();
}

LevelEntry? getLevel(int levelNumber) {
  return levelsRegistry[levelNumber];
}