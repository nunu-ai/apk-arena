![APK ARENA - A Benchmark App for Mobile AI Agents](assets/docs/thumbnail.png)

APK arena is an open benchmark for **vision-based phone use AI agents** — a native Android/iOS app you can set up in 30 seconds and run against any agent harness.

Check out the results we achieve with our harness or get the app and run the benchmark yourself! 

---

## 📖 Overview

While existing benchmarks like [Android World](https://github.com/google-research/android_world) provide comprehensive testing environments, they come with an annoying and complex setup and on top of that they are slowly saturated. So, inspired by the [WebGames](https://webgames.convergence.ai/) we developed our own, fast to setup and easy to use benchmark. 

![different levels](assets/docs/phones.gif)

Most levels came out of a real problem we hit building our harness and agents in production at nunu.ai, e.g. gestures that kept failing, a game our agents played badly, a task we could not complete reliably. 

Each level is an isolated game, task or challenge that gets automatically scored between 0 and 100 based on the key metrics we are interested in. For games it can be score, for tasks it can be mistakes or time, for interactions etc it is swipes, for vision accuracy etc.

![different levels](assets/docs/categories.png)

We feature 50+ levels across 7 categories:

| Category | What it tests |
|---|---|
| 👆 **Primitives** | Basic touchscreen control and fine motor accuracy — tapping, swiping, complex gestures |
| 👁️ **Vision** | Reading the screen: counting, matching, visual search |
| 🧠 **Memory** | Detecting important information and recalling it across long tasks |
| 🧩 **IQ** | Reasoning and rule induction, mostly puzzles |
| ⏱️ **Tempospatial** | Temporal and spatial reasoning |
| 🎮 **Games** | Multi-step games requiring strategy |
| ✅ **Tasks** | Real workflows: using phone UI, following multi-step instructions |


---

## 🎨 Creating your own Levels

### 🚀 Setup

**Prerequisites**
- Flutter SDK
- Android Studio
- VS Code or Rider with Flutter Extension

**Installation**
```bash
flutter pub get
```

**Run**
```bash
flutter run
```

or choose the emulator in VS Code/Rider and click play 🙏

**Build**
```bash
flutter build apk --release
flutter build ios --release
```


### ⌨️ Coding a new Level

Create a new level file `lib/widgets/levels/level_click.dart`. Make sure the level starts with `level_`. Now make a new Widget that extends `LevelWidget`.

In `Widget build(BuildContext context)` you can render anything you want and don't forget to call `widget.onComplete` when the level is passed/failed.

```dart
import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelYourChallenge extends LevelWidget {
  const LevelYourChallenge({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelYourChallenge> createState() => _LevelYourChallengeState();
}

class _LevelYourChallengeState extends State<LevelYourChallenge> {
  void _handleSuccess() {
    if (/* success condition */) {
      widget.onComplete(LevelOutcome(score: 1));  // perfect run
    } else {
      widget.onComplete(LevelOutcome(score: 0));  // failure
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Center(
        child: ElevatedButton(
          onPressed: _handleSuccess,
          child: const Text('Complete Challenge'),
        ),
      ),
    );
  }
}
```

**Step 2: Register your Level**
Add your level to one of the difficulty lists in `level_registry.dart`:

Give your level a title and instructions, but make sure the title doesn't spoil the solution :)

```dart
import 'package:apk_arena/widgets/levels/level_your_challenge.dart';

// Choose the correct category list in level_registry.dart:
// primitivesLevels, visionLevels, memoryLevels, iqLevels,
// tempospatialLevels, gamesLevels, or tasksLevels

  LevelEntry(
    data: LevelData(
      title: "Your Challenge Name",
      instructions: "Clear instructions for the user!"
    ),
    widgetBuilder: (onComplete) => LevelYourChallenge(onComplete: onComplete),
  ),
```

**Step 3: Test Your Level**
Run the app, find your level and test it

## 🗂️ Structure
```
lib/
├── services/
│   ├── progress_service.dart      # Persistent progress management
│   └── notification_service.dart  # System notifications (for 2FA, etc.)
│                                  # any os level integration goes here
├── theme/
│   └── app_theme.dart             # nunu.ai brand theming
│                                  # add more level themes here
├── screens/
│   ├── level_selector.dart        # Main menu with difficulty tabs and level cards
│   ├── level_screen.dart          # Wrapper around level widgets to handle completion etc
│   └── level_completion_screen.dart # Results & navigation
├── widgets/
│   ├── level_widget.dart          # Abstract base class for levels
│   ├── level_tile.dart            # Level selector grid item
│   ├── levels/
│   │   ├── level_click_button.dart
│   │   ├── level_swipe_directions.dart
│   │   ├── level_2fa_login.dart
│   │   └── ...                    # more levels go here
│   └── level_components/          # reusable components that are used in multiple levels
│
└── level_registry.dart            # Central level management
```

---

Made with ❤️ by the nunu.ai team - for better mobile agents
