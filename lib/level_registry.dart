import 'package:apk_arena/widgets/levels/level_action_counter.dart';
import 'package:apk_arena/widgets/levels/level_bingo.dart';
import 'package:apk_arena/widgets/levels/level_button_alchemy.dart';
import 'package:apk_arena/widgets/levels/level_calendar_alarm_planner.dart';
import 'package:apk_arena/widgets/levels/level_captcha.dart';
import 'package:apk_arena/widgets/levels/level_car_steering.dart';
import 'package:apk_arena/widgets/levels/level_cascade_protocol.dart';
import 'package:apk_arena/widgets/levels/level_click_accuracy.dart';
import 'package:apk_arena/widgets/levels/level_coin_collector.dart';
import 'package:apk_arena/widgets/levels/level_connect_the_dots.dart';
import 'package:apk_arena/widgets/levels/level_dice_recognition.dart';
import 'package:apk_arena/widgets/levels/level_double_maze.dart';
import 'package:apk_arena/widgets/levels/level_dvd_logo.dart';
import 'package:apk_arena/widgets/levels/level_email_riddle.dart';
import 'package:apk_arena/widgets/levels/level_emoji_ball_hunt.dart';
import 'package:apk_arena/widgets/levels/level_emoji_count_flags.dart';
import 'package:apk_arena/widgets/levels/level_emoji_count_fruits.dart';
import 'package:apk_arena/widgets/levels/level_eye_chart.dart';
import 'package:apk_arena/widgets/levels/level_file_explorer.dart';
import 'package:apk_arena/widgets/levels/level_fps_maze.dart';
import 'package:apk_arena/widgets/levels/level_gem_socket.dart';
import 'package:apk_arena/widgets/levels/level_group_order.dart';
import 'package:apk_arena/widgets/levels/level_inventory_reconciliation.dart';
import 'package:apk_arena/widgets/levels/level_lights_out.dart';
import 'package:apk_arena/widgets/levels/level_link_chain.dart';
import 'package:apk_arena/widgets/levels/level_mario_platformer.dart';
import 'package:apk_arena/widgets/levels/level_mega_merge.dart';
import 'package:apk_arena/widgets/levels/level_memory_match.dart';
import 'package:apk_arena/widgets/levels/level_multi_tap_sync.dart';
import 'package:apk_arena/widgets/levels/level_odd_one_out.dart';
import 'package:apk_arena/widgets/levels/level_pattern_match.dart';
import 'package:apk_arena/widgets/levels/level_push_box_campaign.dart';
import 'package:apk_arena/widgets/levels/level_ricochet_lab.dart';
import 'package:apk_arena/widgets/levels/level_rush_hour.dart';
import 'package:apk_arena/widgets/levels/level_scrabble.dart';
import 'package:apk_arena/widgets/levels/level_scroll_mastery.dart';
import 'package:apk_arena/widgets/levels/level_sequence_memory.dart';
import 'package:apk_arena/widgets/levels/level_shattered_portrait.dart';
import 'package:apk_arena/widgets/levels/level_signup_gauntlet.dart';
import 'package:apk_arena/widgets/levels/level_slider_skills.dart';
import 'package:apk_arena/widgets/levels/level_snake.dart';
import 'package:apk_arena/widgets/levels/level_spot_difference.dart';
import 'package:apk_arena/widgets/levels/level_swipe_directions.dart';
import 'package:apk_arena/widgets/levels/level_tiny_factory.dart';
import 'package:apk_arena/widgets/levels/level_tos_quiz.dart';
import 'package:apk_arena/widgets/levels/level_tower_defense.dart';
import 'package:apk_arena/widgets/levels/level_trace_drawing.dart';
import 'package:apk_arena/widgets/levels/level_trial_sequence.dart';
import 'package:apk_arena/widgets/levels/level_upsell_checkout.dart';
import 'package:apk_arena/widgets/levels/level_whack_a_mole.dart';
import 'package:apk_arena/widgets/levels/level_word_law.dart';

import '../models/level_data.dart';
import '../models/level_outcome.dart';
import '../widgets/level_widget.dart';

class LevelEntry {
  final LevelData data;
  final LevelWidget Function(void Function(LevelOutcome outcome) onComplete)
  widgetBuilder;

  LevelEntry({required this.data, required this.widgetBuilder});
}

final List<LevelEntry> primitivesLevels = [
  LevelEntry(
    data: LevelData(title: "click accuracy", instructions: "tap the logo."),
    widgetBuilder: (onComplete) => LevelClickAccuracy(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Swipe Lab",
      instructions: "swipe as shown and pass through the gaps.",
    ),
    widgetBuilder: (onComplete) => LevelSwipeDirections(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Scroll Lab",
      instructions: "complete each scroll challenge.",
    ),
    widgetBuilder: (onComplete) => LevelScrollMastery(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Slider Gauntlet",
      instructions: "set each slider to the target and submit.",
    ),
    widgetBuilder: (onComplete) => LevelSliderSkills(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "ink discipline",
      instructions: "trace each shape inside the glow.",
    ),
    widgetBuilder: (onComplete) => LevelTraceDrawing(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "star lanes",
      instructions: "drag through the numbers in order.",
    ),
    widgetBuilder: (onComplete) => LevelConnectTheDots(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "enchanted socket",
      instructions: "place each gem in the correct socket.",
    ),
    widgetBuilder: (onComplete) => LevelGemSocket(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Sync Chamber",
      instructions: "follow the instructions on screen to start the reactor.",
    ),
    widgetBuilder: (onComplete) => LevelMultiTapSync(onComplete: onComplete),
  ),
];

final List<LevelEntry> visionLevels = [
  LevelEntry(
    data: LevelData(
      title: "parade of nations",
      instructions: "count the flags and enter the total.",
    ),
    widgetBuilder: (onComplete) => LevelEmojiCountFlags(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "fruit salad census",
      instructions: "count the target fruit. ignore the rest.",
    ),
    widgetBuilder: (onComplete) =>
        LevelEmojiCountFruits(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "emoji soup",
      instructions: "find and tap the targets.",
    ),
    widgetBuilder: (onComplete) => LevelEmojiBallHunt(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Count the Dots",
      instructions: "enter each die value from left to right.",
    ),
    widgetBuilder: (onComplete) => LevelDiceRecognition(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "read the chart",
      instructions: "type exactly what you see on screen.",
    ),
    widgetBuilder: (onComplete) => LevelEyeChart(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "pixel perfect",
      instructions: "recreate the shown pattern.",
    ),
    widgetBuilder: (onComplete) => LevelPatternMatch(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Prove You're Human",
      instructions: "complete every captcha step.",
    ),
    widgetBuilder: (onComplete) => LevelCaptcha(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Spot the Bug",
      instructions: "decide if the two screens match.",
    ),
    widgetBuilder: (onComplete) => LevelSpotDifference(onComplete: onComplete),
  ),
];

final List<LevelEntry> memoryLevels = [
  LevelEntry(
    data: LevelData(
      title: "User Agreement",
      instructions: "review the user agreement.",
    ),
    widgetBuilder: (onComplete) => LevelTosQuiz(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "rabbit hole",
      instructions: "find answers in the filesystem.",
    ),
    widgetBuilder: (onComplete) => LevelFileExplorer(
      onComplete: onComplete,
      timeLimit: const Duration(minutes: 30),
    ),
  ),
  LevelEntry(
    data: LevelData(
      title: "trial & error",
      instructions: "remember the correct symbols and survive.",
      timeLimit: Duration(minutes: 31),
    ),
    widgetBuilder: (onComplete) => LevelTrialSequence(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Count & Submit",
      instructions: "count your presses and submit the totals.",
    ),
    widgetBuilder: (onComplete) => LevelActionCounter(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(title: "memory match", instructions: "clear all boards."),
    widgetBuilder: (onComplete) => LevelMemoryMatch(onComplete: onComplete),
  ),
];

final List<LevelEntry> iqLevels = [
  LevelEntry(
    data: LevelData(
      title: "spot the imposter",
      instructions: "find the odd one out in each round.",
    ),
    widgetBuilder: (onComplete) => LevelOddOneOut(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "button alchemy",
      instructions: "reach the target using buttons a, b, c.",
    ),
    widgetBuilder: (onComplete) => LevelButtonAlchemy(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "blackout",
      instructions: "clear every board — turn all the lights off.",
      timeLimit: Duration(hours: 3),
    ),
    widgetBuilder: (onComplete) => LevelLightsOut(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "push-box gauntlet",
      instructions: "push the boxes into the holes. mind the gates.",
      timeLimit: Duration(minutes: 60),
    ),
    widgetBuilder: (onComplete) => LevelPushBoxCampaign(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "ricochet lab",
      instructions:
          "get the marked robot onto its ring. robots slide until they hit something.",
      timeLimit: Duration(minutes: 60),
    ),
    widgetBuilder: (onComplete) => LevelRicochetLab(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "shattered portrait",
      instructions: "restore the paintings.",
      timeLimit: Duration(minutes: 60),
    ),
    widgetBuilder: (onComplete) =>
        LevelShatteredPortrait(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "syntax error",
      instructions: "reach the win condition.",
      timeLimit: Duration(minutes: 60),
    ),
    widgetBuilder: (onComplete) => LevelWordLaw(onComplete: onComplete),
  ),
];

final List<LevelEntry> tempospatialLevels = [
  LevelEntry(
    data: LevelData(
      title: "labyrinth gauntlet",
      instructions: "clear the mazes.",
    ),
    widgetBuilder: (onComplete) => LevelDoubleMaze(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Space Collector",
      instructions: "collect all coins and enter the total.",
    ),
    widgetBuilder: (onComplete) => LevelCoinCollector(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Catch the DVD",
      instructions: "catch the target in each stage.",
    ),
    widgetBuilder: (onComplete) => LevelDvdLogo(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Sequence Memory",
      instructions: "memorize and repeat the sequence.",
    ),
    widgetBuilder: (onComplete) => LevelSequenceMemory(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "reflex arena",
      instructions: "whack the moles, leave the bombs alone.",
    ),
    widgetBuilder: (onComplete) => LevelWhackAMole(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "road rage",
      instructions: "dodge obstacles and reach the finish.",
    ),
    widgetBuilder: (onComplete) => LevelCarSteering(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "snake",
      instructions: "eat the apples without crashing.",
    ),
    widgetBuilder: (onComplete) => LevelSnake(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "escape the simulation",
      instructions: "find the exit twice. the second layer is off the map.",
    ),
    widgetBuilder: (onComplete) => LevelFpsMaze(onComplete: onComplete),
  ),
];

final List<LevelEntry> gamesLevels = [
  LevelEntry(
    data: LevelData(
      title: "Bingo",
      instructions: "mark called numbers to get a bingo.",
    ),
    widgetBuilder: (onComplete) => LevelBingo(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Mega Merge",
      instructions: "complete orders to score points.",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelMegaMerge(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "match three",
      instructions: "make matches before time runs out.",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelCascadeProtocol(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "chain reaction",
      instructions: "link matching gems to score points.",
    ),
    widgetBuilder: (onComplete) => LevelLinkChain(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "traffic jam",
      instructions: "clear all rush hour jams.",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelRushHour(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "scrabble",
      instructions: "place tiles to make valid words and score points.",
    ),
    widgetBuilder: (onComplete) => LevelScrabble(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(title: "jump man", instructions: "reach the flag."),
    widgetBuilder: (onComplete) => LevelMarioPlatformer(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "sector defense",
      instructions: "place towers to stop all waves.",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelTowerDefense(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "tiny factory",
      instructions: "deliver quality items to earn parts.",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelTinyFactory(onComplete: onComplete),
  ),
];

final List<LevelEntry> tasksLevels = [
  LevelEntry(
    data: LevelData(
      title: "sleep logistics",
      instructions:
          "set up alarms for next week's schedule. the current ones are from last week, fix them too.",
      timeLimit: Duration(hours: 1),
    ),
    widgetBuilder: (onComplete) =>
        LevelCalendarAlarmPlanner(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "signup gauntlet",
      instructions: "complete each signup and login flow.",
      timeLimit: Duration(hours: 1),
    ),
    widgetBuilder: (onComplete) => LevelSignupGauntlet(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "breakfast checkout",
      instructions: "order exactly one plain bagel.",
      timeLimit: Duration(hours: 1),
    ),
    widgetBuilder: (onComplete) => LevelUpsellCheckout(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Email Riddle",
      instructions: "handle every email correctly.",
      timeLimit: Duration(hours: 1),
    ),
    widgetBuilder: (onComplete) => LevelEmailRiddle(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "pizza night",
      instructions: "order everyone's final picks.",
      timeLimit: Duration(hours: 1),
    ),
    widgetBuilder: (onComplete) => LevelGroupOrder(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "operation warehouse",
      instructions: "use the receipt to update inventory.",
      timeLimit: Duration(hours: 1),
    ),
    widgetBuilder: (onComplete) =>
        LevelInventoryReconciliation(onComplete: onComplete),
  ),
];

final Map<int, LevelEntry> levelsRegistry = {
  for (var i = 0; i < primitivesLevels.length; i++) i: primitivesLevels[i],
  for (var i = 0; i < visionLevels.length; i++) 100 + i: visionLevels[i],
  for (var i = 0; i < memoryLevels.length; i++) 200 + i: memoryLevels[i],
  for (var i = 0; i < iqLevels.length; i++) 300 + i: iqLevels[i],
  for (var i = 0; i < tempospatialLevels.length; i++)
    400 + i: tempospatialLevels[i],
  for (var i = 0; i < gamesLevels.length; i++) 500 + i: gamesLevels[i],
  for (var i = 0; i < tasksLevels.length; i++) 600 + i: tasksLevels[i],
};

List<int> getAvailableLevels() {
  return levelsRegistry.keys.toList()..sort();
}

/// Next level id in global registry order, or `null` if none after [levelNumber].
int? getNextSequentialLevel(int levelNumber) {
  final all = getAvailableLevels();
  final i = all.indexOf(levelNumber);
  if (i == -1 || i >= all.length - 1) return null;
  return all[i + 1];
}

List<int> getLevelsForCategory(int difficulty) {
  return levelsRegistry.entries
      .where(
        (entry) =>
            100 * difficulty <= entry.key && entry.key < 100 * (difficulty + 1),
      )
      .map((entry) => entry.key)
      .toList()
    ..sort();
}

int? findLevelNumberByTitle(String title) {
  for (final entry in levelsRegistry.entries) {
    if (entry.value.data.title == title) return entry.key;
  }
  return null;
}

LevelEntry? getLevel(int levelNumber) {
  return levelsRegistry[levelNumber];
}

String getCategoryName(int levelNumber) {
  if (levelNumber < 100) return 'primitives';
  if (levelNumber < 200) return 'vision';
  if (levelNumber < 300) return 'memory';
  if (levelNumber < 400) return 'iq';
  if (levelNumber < 500) return 'tempospatial';
  if (levelNumber < 600) return 'games';
  if (levelNumber < 700) return 'tasks';
  return 'unknown';
}
