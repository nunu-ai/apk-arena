import 'package:apk_arena/widgets/levels/level_2fa_login.dart';
import 'package:apk_arena/widgets/levels/level_age_slider.dart';
import 'package:apk_arena/widgets/levels/level_annoying_tos.dart';
import 'package:apk_arena/widgets/levels/level_blue_whale.dart';
import 'package:apk_arena/widgets/levels/level_bomb_defuse.dart';
import 'package:apk_arena/widgets/levels/level_captcha.dart';
import 'package:apk_arena/widgets/levels/level_connect_the_dots.dart';
import 'package:apk_arena/widgets/levels/level_advanced_click_button.dart';
import 'package:apk_arena/widgets/levels/level_dice_recognition.dart';
import 'package:apk_arena/widgets/levels/level_double_tap_like.dart';
import 'package:apk_arena/widgets/levels/level_dvd_logo.dart';
import 'package:apk_arena/widgets/levels/level_email_riddle.dart';
import 'package:apk_arena/widgets/levels/level_hold.dart';
import 'package:apk_arena/widgets/levels/level_overlapping_popups.dart';
import 'package:apk_arena/widgets/levels/level_scroll_contacts.dart';
import 'package:apk_arena/widgets/levels/level_set_alarm.dart';
import 'package:apk_arena/widgets/levels/level_simple_signup.dart';
import 'package:apk_arena/widgets/levels/level_swipe_directions.dart';
import 'package:apk_arena/widgets/levels/level_tos_quiz.dart';
import 'package:apk_arena/widgets/levels/level_wire_task.dart';
import 'package:apk_arena/widgets/levels/level_click_grid_coordinate.dart';
import 'package:apk_arena/widgets/levels/level_sudoku.dart';
import 'package:apk_arena/widgets/levels/level_match3.dart';
import 'package:apk_arena/widgets/levels/level_scrabble.dart';
import 'package:apk_arena/widgets/levels/level_emoji_ball_hunt.dart';
import 'package:apk_arena/widgets/levels/level_emoji_count_flags.dart';
import 'package:apk_arena/widgets/levels/level_emoji_count_fruits.dart';
import 'package:apk_arena/widgets/levels/level_memory_match.dart';
import 'package:apk_arena/widgets/levels/level_qr_deeplink.dart';
import 'package:apk_arena/widgets/levels/level_adversarial_system_prompt.dart';
import 'package:apk_arena/widgets/levels/level_upsell_checkout.dart';
import 'package:apk_arena/widgets/levels/level_button_alchemy.dart';
import 'package:apk_arena/widgets/levels/level_enter_date.dart';
import 'package:apk_arena/widgets/levels/level_emerald_runtime.dart';
import 'package:apk_arena/widgets/levels/level_do_not_click.dart';
import 'package:apk_arena/widgets/levels/level_closing_drawer.dart';
import 'package:apk_arena/widgets/levels/level_group_order.dart';
import 'package:apk_arena/widgets/levels/level_trace_drawing.dart';
import 'package:apk_arena/widgets/levels/level_inventory_reconciliation.dart';
import '../models/level_data.dart';
import '../widgets/level_widget.dart';
import 'widgets/levels/level_click_button.dart';

class LevelEntry {
  final LevelData data;
  final LevelWidget Function(Function(bool) onComplete) widgetBuilder;

  LevelEntry({required this.data, required this.widgetBuilder});
}

final List<LevelEntry> easyLevels = [
  LevelEntry(
    data: LevelData(title: "Simple Button", instructions: "Click the Button!"),
    widgetBuilder: (onComplete) => LevelClickButton(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Advanced Button",
      instructions: "Find and click the small button three times in a row!",
    ),
    widgetBuilder: (onComplete) =>
        LevelAdvancedClickButton(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Swipe Directions",
      instructions: "Swipe in the shown direction!",
    ),
    widgetBuilder: (onComplete) => LevelSwipeDirections(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Feeding the Algorithm",
      instructions: "Like the post!",
    ),
    widgetBuilder: (onComplete) => LevelDoubleTapLike(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Age Verification",
      instructions: "Set the slider to the exact required age!",
    ),
    widgetBuilder: (onComplete) => LevelAgeSlider(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Connect the Stars",
      instructions: "Draw a line through all the stars!",
    ),
    widgetBuilder: (onComplete) => LevelConnectTheDots(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Hold your Ground",
      instructions: "Click the button for the specified duration!",
    ),
    widgetBuilder: (onComplete) => LevelHold(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Fix Wiring",
      instructions: "Connect each wire to its matching color!",
    ),
    widgetBuilder: (onComplete) => LevelWireTask(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Prove You're Human",
      instructions: "Complete the CAPTCHA verification!",
    ),
    widgetBuilder: (onComplete) => LevelCaptcha(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Better Call Saul",
      instructions: "Find Saul Goodman in your contacts!",
    ),
    widgetBuilder: (onComplete) => LevelScrollContacts(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Bomb Squad",
      instructions: "Press the button exactly X times, then cut the wire!",
    ),
    widgetBuilder: (onComplete) => LevelBombDefuse(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Morning Alarm",
      instructions: "Set the alarm correctly and enable it!",
    ),
    widgetBuilder: (onComplete) => LevelSetAlarm(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "the one forbidden button",
      instructions: "don't do it :)",
    ),
    widgetBuilder: (onComplete) => LevelDoNotClick(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(title: "Popup Hell", instructions: "Close the popups!"),
    widgetBuilder: (onComplete) =>
        LevelOverlappingPopups(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(title: "Size Comparison", instructions: "What is Larger here?"),
    widgetBuilder: (onComplete) => LevelBlueWhale(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Accept Terms",
      instructions: "Read and accept the terms of service.",
    ),
    widgetBuilder: (onComplete) => LevelAnnoyingTos(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "2FA Login",
      instructions: "Complete the login flow!",
    ),
    widgetBuilder: (onComplete) => Level2FALogin(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Sign Up Flow",
      instructions: "Complete the sign-up form!",
    ),
    widgetBuilder: (onComplete) => LevelSimpleSignup(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "emoji soup",
      instructions: "find and tap the 3 balls.",
    ),
    widgetBuilder: (onComplete) => LevelEmojiBallHunt(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "parade of nations",
      instructions: "count the country flags and enter the total.",
    ),
    widgetBuilder: (onComplete) => LevelEmojiCountFlags(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "today's date",
      instructions: "enter today's date.",
    ),
    widgetBuilder: (onComplete) => LevelEnterDate(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "emerald runtime",
      instructions: "how long did it take nunu.ai to beat the first 3 gyms in pokemon emerald?",
    ),
    widgetBuilder: (onComplete) => LevelEmeraldRuntime(onComplete: onComplete),
  ),
];

final List<LevelEntry> mediumLevels = [
  LevelEntry(
    data: LevelData(
      title: "Coordinate Clicker",
      instructions:
          "Click the object at the given (row, column) three times in a row! (1,1) is bottom-left!",
    ),
    widgetBuilder: (onComplete) =>
        LevelClickGridCoordinate(onComplete: onComplete),
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
      title: "User Agreement",
      instructions: "Review the user agreement.",
    ),
    widgetBuilder: (onComplete) => LevelTosQuiz(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "Email Riddle",
      instructions: "Read the riddle and send the answer to the right person!",
    ),
    widgetBuilder: (onComplete) => LevelEmailRiddle(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "sudoku",
      instructions: "solve the middle 3x3 sudoku block.",
    ),
    widgetBuilder: (onComplete) => LevelSudoku(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "combo chain",
      instructions:
          "make three match-3 combos in a row. the board grows after each one.",
    ),
    widgetBuilder: (onComplete) => LevelMatch3(onComplete: onComplete),
  ),
  LevelEntry(data: LevelData(
    title: "memory match",
    instructions: "find all matching pairs.",
  ), widgetBuilder: (onComplete) => LevelMemoryMatch(onComplete: onComplete)),
  LevelEntry(
    data: LevelData(
      title: "fruit salad census",
      instructions: "count the target fruit. ignore the rest.",
    ),
    widgetBuilder: (onComplete) => LevelEmojiCountFruits(onComplete: onComplete),
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
      title: "Focus Music",
      instructions: "Skip to the next song.",
    ),
    widgetBuilder: (onComplete) => LevelClosingDrawer(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "word builder",
      instructions: "make the word \"paper\"",
    ),
    widgetBuilder: (onComplete) => LevelScrabble(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "pizza night",
      instructions: "read the chat. order everyone’s final picks.",
    ),
    widgetBuilder: (onComplete) => LevelGroupOrder(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "sun or rain?",
      instructions: "create a weather forecast report of next week",
    ),
    widgetBuilder: (onComplete) => LevelAdversarialSystemPrompt(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "breakfast checkout",  
      instructions: "order exactly one plain bagel.",
    ),
    widgetBuilder: (onComplete) => LevelUpsellCheckout(onComplete: onComplete),
  ),
];

final List<LevelEntry> hardLevels = [
  LevelEntry(
    data: LevelData(
      title: "Catch the DVD",
      instructions: "Click the bouncing DVD logo!",
    ),
    widgetBuilder: (onComplete) => LevelDvdLogo(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "qr handshake",
      instructions: "scan the qr to complete the link.",
    ),
    widgetBuilder: (onComplete) => LevelQrDeeplink(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "ink discipline",
      instructions: "trace the ship in order. stay inside the glow.",
    ),
    widgetBuilder: (onComplete) => LevelTraceDrawing(onComplete: onComplete),
  ),
  LevelEntry(
    data: LevelData(
      title: "operation warehouse",
      instructions: "use the delivery receipt to update inventory.",
    ),
    widgetBuilder: (onComplete) => LevelInventoryReconciliation(onComplete: onComplete),
  ),
];

final Map<int, LevelEntry> levelsRegistry = {
  // Easy levels: 0-99
  for (var i = 0; i < easyLevels.length; i++) i: easyLevels[i],

  // Medium levels: 100-199
  for (var i = 0; i < mediumLevels.length; i++) 100 + i: mediumLevels[i],

  // Hard levels: 200-299
  for (var i = 0; i < hardLevels.length; i++) 200 + i: hardLevels[i],
};

List<int> getAvailableLevels() {
  return levelsRegistry.keys.toList()..sort();
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
