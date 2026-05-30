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
import 'package:apk_arena/widgets/levels/level_rush_hour.dart';
import 'package:apk_arena/widgets/levels/level_scrabble.dart';
import 'package:apk_arena/widgets/levels/level_scroll_mastery.dart';
import 'package:apk_arena/widgets/levels/level_sequence_memory.dart';
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
    data: LevelData(
      title: "star lanes",
      instructions:
          "start on 1 and drag through every number in order in one stroke; wrong first touch, wrong next body, or lifting early costs a life.",
    ),
    widgetBuilder: (onComplete) => LevelConnectTheDots(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "ink discipline",
      instructions: "trace 5 shapes. stay inside the glow. 3 lives per shape.",
    ),
    widgetBuilder: (onComplete) => LevelTraceDrawing(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Click Gauntlet",
      instructions:
          "stage 1: tap the logo 20 times; it shrinks each hit. 10 hearts — a miss costs one. stage 2: six constellations — the last three scramble the numbers. connect in order and protect your 10 lives.",
    ),
    widgetBuilder: (onComplete) => LevelClickAccuracy(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Swipe Lab",
      instructions:
          "Follow the card, then escape through the shrinking gap. Five hearts — wrong swipes cost one.",
    ),
    widgetBuilder: (onComplete) => LevelSwipeDirections(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Sync Chamber",
      instructions:
          "Hold all 3 pads together, then swipe up on all 3 lanes at once!",
    ),
    widgetBuilder: (onComplete) => LevelMultiTapSync(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Slider Gauntlet",
      instructions:
          "Set the age and decimal targets. Ten lives — wrong submits cost one.",
    ),
    widgetBuilder: (onComplete) => LevelSliderSkills(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Scroll Lab",
      instructions:
          "Five scroll challenges: lists, documents, find target, horizontal, 2D grid.",
    ),
    widgetBuilder: (onComplete) => LevelScrollMastery(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "enchanted socket",
      instructions:
          "four enchantments — each more treacherous than the last. 10 lives.",
    ),
    widgetBuilder: (onComplete) => LevelGemSocket(onComplete: onComplete),
  ),
];

final List<LevelEntry> visionLevels = [
  LevelEntry(
    data: LevelData(
      title: "parade of nations",
      instructions: "count the country flags and enter the total.",
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
      title: "Count the Dots",
      instructions: "Enter the numbers on each die from left to right!",
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
      title: "emoji soup",
      instructions:
          "find and tap the 3 targets in each stage. 3 lives per stage.",
    ),
    widgetBuilder: (onComplete) => LevelEmojiBallHunt(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "pixel perfect",
      instructions: "recreate the pattern shown above!",
    ),
    widgetBuilder: (onComplete) => LevelPatternMatch(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Prove You're Human",
      instructions:
          "Complete every captcha step in order. 10 lives — wrong answers cost one. Your total time is recorded at the end.",
    ),
    widgetBuilder: (onComplete) => LevelCaptcha(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Spot the Bug",
      instructions:
          "Compare the Reference Design with the Production Build. Are they the same or different?",
    ),
    widgetBuilder: (onComplete) => LevelSpotDifference(onComplete: onComplete),
  ),
];

final List<LevelEntry> memoryLevels = [
  LevelEntry(
    data: LevelData(
      title: "User Agreement",
      instructions: "Review the user agreement.",
    ),
    widgetBuilder: (onComplete) => LevelTosQuiz(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(title: "memory match", instructions: "clear all boards."),
    widgetBuilder: (onComplete) => LevelMemoryMatch(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "rabbit hole",
      instructions:
          "explore the filesystem efficiently and answer all questions!",
    ),
    widgetBuilder: (onComplete) => LevelFileExplorer(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "trial & error",
      instructions:
          "survive the full session. each screen has one correct symbol. wrong picks reset the chain.",
      timeLimit: Duration(minutes: 31),
    ),
    widgetBuilder: (onComplete) => LevelTrialSequence(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Count & Submit",
      instructions:
          "Three counting stages — buttons shuffle after every tap, no tallies. Track your presses and prove it.",
    ),
    widgetBuilder: (onComplete) => LevelActionCounter(onComplete: onComplete),
  ),
];

final List<LevelEntry> iqLevels = [
  LevelEntry(
    data: LevelData(
      title: "push-box gauntlet",
      instructions: "push the boxes into the holes.",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelPushBoxCampaign(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "spot the imposter",
      instructions: "find the odd one out in each round.",
    ),
    widgetBuilder: (onComplete) => LevelOddOneOut(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "blackout",
      instructions: "turn off all the lights.",
    ),
    widgetBuilder: (onComplete) => LevelLightsOut(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "button alchemy",
      instructions: "reach the target using buttons a, b, c.",
    ),
    widgetBuilder: (onComplete) => LevelButtonAlchemy(onComplete: onComplete),
  ),
];

final List<LevelEntry> tempospatialLevels = [
  LevelEntry(
    data: LevelData(
      title: "labyrinth gauntlet",
      instructions: "clear two mazes back to back. fewer moves = higher score.",
    ),
    widgetBuilder: (onComplete) => LevelDoubleMaze(onComplete: onComplete),
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
      title: "road rage",
      instructions:
          "steer left and right to dodge obstacles. reach the finish line!",
    ),
    widgetBuilder: (onComplete) => LevelCarSteering(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "pixel serpent",
      instructions: "eat 15 apples without hitting yourself or the wall.",
    ),
    widgetBuilder: (onComplete) => LevelSnake(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "escape the simulation",
      instructions: "find the exit. you are inside the machine.",
    ),
    widgetBuilder: (onComplete) => LevelFpsMaze(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Sequence Memory",
      instructions: "Memorize and repeat the sequence!",
    ),
    widgetBuilder: (onComplete) => LevelSequenceMemory(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Space Collector",
      instructions: "Collect all coins and enter the total count!",
    ),
    widgetBuilder: (onComplete) => LevelCoinCollector(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "reflex arena",
      instructions: "whack the moles! 30 seconds on the clock.",
    ),
    widgetBuilder: (onComplete) => LevelWhackAMole(onComplete: onComplete),
  ),
];

final List<LevelEntry> gamesLevels = [
  LevelEntry(
    data: LevelData(
      title: "merge protocol",
      instructions: "score as high as you can before time runs out",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelCascadeProtocol(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Mega Merge",
      instructions: "Score as much as possible by completing orders",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelMegaMerge(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "traffic jam",
      instructions: "clear all rush hour jams.",
      timeLimit: Duration(hours: 1),
    ),
    widgetBuilder: (onComplete) => LevelRushHour(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "sector defense",
      instructions: "drag towers onto the grid to defend against all waves",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelTowerDefense(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "tiny factory",
      instructions:
          "earn as many parts as possible by delivering high quality items",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelTinyFactory(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Bingo",
      instructions: "Mark the called numbers quickly to get a BINGO!",
    ),
    widgetBuilder: (onComplete) => LevelBingo(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "word builder",
      instructions: "make the word \"paper\"",
    ),
    widgetBuilder: (onComplete) => LevelScrabble(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(title: "jump man", instructions: "reach the flag!"),
    widgetBuilder: (onComplete) => LevelMarioPlatformer(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "chain reaction",
      instructions:
          "link matching gems by dragging through neighbours. longer chains = more points. reach 50 to pass.",
    ),
    widgetBuilder: (onComplete) => LevelLinkChain(onComplete: onComplete),
  ),
];

final List<LevelEntry> tasksLevels = [
  LevelEntry(
    data: LevelData(
      title: "sleep logistics",
      instructions: "make sure all alarms are set correctly for next week!",
    ),
    widgetBuilder: (onComplete) =>
        LevelCalendarAlarmPlanner(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "operation warehouse",
      instructions: "use the delivery receipt to update inventory.",
    ),
    widgetBuilder: (onComplete) =>
        LevelInventoryReconciliation(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "pizza night",
      instructions: "read the chat. order everyone's final picks.",
    ),
    widgetBuilder: (onComplete) => LevelGroupOrder(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "signup gauntlet",
      instructions:
          "complete all 5 signup flows using the given account details, then finish each login.",
      timeLimit: Duration(minutes: 30),
    ),
    widgetBuilder: (onComplete) => LevelSignupGauntlet(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Email Riddle",
      instructions: "Handle your inbox. Reply, archive, or delete every email until no new ones arrive.",
    ),
    widgetBuilder: (onComplete) => LevelEmailRiddle(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "breakfast checkout",
      instructions: "order exactly one plain bagel.",
    ),
    widgetBuilder: (onComplete) => LevelUpsellCheckout(onComplete: onComplete),
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

List<int> getLevelsForDifficulty(int difficulty) {
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

String getDifficultyName(int levelNumber) {
  if (levelNumber < 100) return 'primitives';
  if (levelNumber < 200) return 'vision';
  if (levelNumber < 300) return 'memory';
  if (levelNumber < 400) return 'iq';
  if (levelNumber < 500) return 'tempospatial';
  if (levelNumber < 700) return 'tasks';
  return 'unknown';
}
