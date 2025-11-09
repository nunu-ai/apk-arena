import 'package:apk_arena/widgets/levels/level_connect_the_dots.dart';
import 'package:apk_arena/widgets/levels/level_double_tap_like.dart';
import 'package:apk_arena/widgets/levels/level_hold.dart';
import 'package:apk_arena/widgets/levels/level_simple_signup.dart';
import 'package:apk_arena/widgets/levels/level_swipe_directions.dart';
import 'package:apk_arena/widgets/levels/level_wire_task.dart';
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
  1: LevelEntry(
    data: LevelData(title: "Swipe Directions", instructions: "Swipe in the shown direction!"),
    widgetBuilder: (onComplete) => LevelSwipeDirections(onComplete: onComplete),
  ),
  3: LevelEntry(
    data: LevelData(title: "Feeding the Algorithm", instructions: "Like the post!"),
    widgetBuilder: (onComplete) => LevelDoubleTapLike(onComplete: onComplete),
  ),
  4: LevelEntry(
    data: LevelData(title: "Connect the Stars", instructions: "Draw a line through all the stars!"),
    widgetBuilder: (onComplete) => LevelConnectTheDots(onComplete: onComplete),
  ),
  5: LevelEntry(
    data: LevelData(title: "Hold your Ground", instructions: "Click the button for the specified duration!"),
    widgetBuilder: (onComplete) => LevelHold(onComplete: onComplete),
  ),
  6: LevelEntry(
    data: LevelData(title: "Fix Wiring", instructions: "Connect each wire to its matching color!"),
    widgetBuilder: (onComplete) => LevelWireTask(onComplete: onComplete),
  ),
  100: LevelEntry(
    data: LevelData(title: "Sign Up Flow", instructions: "Complete the sign-up form!"),
    widgetBuilder: (onComplete) => LevelSimpleSignup(onComplete: onComplete),
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