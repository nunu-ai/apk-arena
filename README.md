# 🏆 APK_ARENA 🤖

**A Benchmark App for Mobile AI Agents**

While existing benchmarks like Android World provide comprehensive testing environments, they come with significant overhead: they are complex to setup and take forever before you can run a single task.

Inspired by  [webgames](https://webgames.convergence.ai/) from convergence, we wanted something simpler:

APK Arena is a native Android/iOS app that you can install in 30 seconds. Just download, run, and start testing your mobile agent.

## 📖 Overview

APK Arena is a benchmark application designed to evaluate mobile AI agents across multiple critical dimensions:
- **🎯 Device Interaction Skills** - Testing touch, swipe and complex gesture handling and fine-grained control
- **📱 Task Solving and Understanding** - Evaluating UI navigation and task solving capabilities through complex mobile interfaces
- **👁️ Vision Capabilities** - Assessing image recognition, spatial awareness, and visual problem-solving
- **🧠 Model IQ** - Measuring logical reasoning, pattern recognition, and problem-solving abilities
- **💾 Memory** - Testing retention over multi-step task completion

The app presents agents with increasingly complex challenges across three difficulty tiers, from simple button clicks to intricate multi-step flows.

## 🎯 Try It With Your Agent!

Got a mobile AI agent? Put it to the test!
1. Install APK Arena on an emulator or real device
2. Point your agent at the app
3. Tell it to solve as many levels as possible
4. Share your results or new level ideas!

## 🚀 Getting Started

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

## 🎨 Creating Levels
**Step 1: Create Your Level Widget**

Create a new level file `lib/widgets/levels/level_click.dart`. Make sure the level starts with `level_`. Now make a new Widget that extends `LevelWidget`.

In `Widget build(BuildContext context)` you can render anything you want and don't forget to call `widget.onComplete` when the level is passed/failed.

```dart
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelYourChallenge extends LevelWidget {
  const LevelYourChallenge({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelYourChallenge> createState() => _LevelYourChallengeState();
}

class _LevelYourChallengeState extends State<LevelYourChallenge> {
  // Your state variables
  int _attempts = 0;
  
  void _handleSuccess() {
    // Validate completion criteria
    if (/* success condition */) {
      widget.onComplete(true);  // Success!
    } else {
      widget.onComplete(false); // Failure
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

final List<LevelEntry> easyLevels = [
  // ... existing levels
  LevelEntry(
    data: LevelData(
      title: "Your Challenge Name",
      instructions: "Clear instructions for the user!"
    ),
    widgetBuilder: (onComplete) => LevelYourChallenge(onComplete: onComplete),
  ),
];
```

**Step 3: Test Your Level**
Run the app, find your level and test it

## Structure
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

## 📝 License
This project is licensed under the MIT License - see the LICENSE file for details.

Made with ❤️ by the nunu.ai team - for better mobile agents



