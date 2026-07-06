# Contributing Levels

This page covers how to setup the project for development if you want to add your own levels.

## Setup

**Prerequisites:** Flutter SDK, Android Studio, VS Code or Rider with Flutter extension

```bash
flutter pub get
flutter run
```

Or choose an emulator in VS Code/Rider and click play.

**Build for release:**
```bash
flutter build apk --release
flutter build ios --release
```

---

## Project structure

```
lib/
├── services/
│   ├── progress_service.dart      # persistent progress tracking
│   └── notification_service.dart  # OS-level integrations (2FA, etc.)
│
├── theme/
│   └── app_theme.dart             # nunu.ai brand theming (dark theme)
│
├── screens/
│   ├── level_selector.dart        # main menu with category tabs
│   ├── level_screen.dart          # level wrapper (timing, completion)
│   └── level_completion_screen.dart # results screen
│
├── widgets/
│   ├── level_widget.dart          # abstract base class for ALL levels
│   ├── level_tile.dart            # grid item in level selector
│   │
│   ├── levels/                    # ⭐ all levels go here
│   │   ├── level_click_button.dart
│   │   ├── level_swipe_directions.dart
│   │   └── ...
│   │
│   └── level_components/          # reusable UI components
│       ├── dice.dart
│       ├── contact_list_item.dart
│       └── gmail/
│
└── level_registry.dart            # ⭐ register new levels here
```

---

## Creating a new level

### Step 1 — create the widget

Create `lib/widgets/levels/level_your_name.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelYourName extends LevelWidget {
  const LevelYourName({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelYourName> createState() => _LevelYourNameState();
}

class _LevelYourNameState extends State<LevelYourName> {
  void _complete(double score) {
    widget.onComplete(LevelOutcome(score: score));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Center(child: /* your UI */),
    );
  }
}
```

**Rules:**
1. Must extend `LevelWidget`
2. Must call `widget.onComplete(LevelOutcome(...))` when the run ends — both success and failure paths
3. File name must start with `level_`
4. Use `NunuColors.*` for theming unless you are recreating a real app's UI

`LevelOutcome.score` is clamped to `[0, 1]`: `1` = perfect run, `0` = total failure. Pass an optional `metrics` map for diagnostic numbers.

**Time limit:** defaults to 60 minutes. Override in `LevelData`:
```dart
timeLimit: Duration(minutes: 5)
```
When time expires the shell calls `onComplete` with `score: 0` and `timed_out` in metrics.

### Step 2 — register in the registry

Add to the appropriate list in `lib/level_registry.dart`:

```dart
import 'package:apk_arena/widgets/levels/level_your_name.dart';

// category lists and their ID ranges:
// primitivesLevels   0–99
// visionLevels       100–199
// memoryLevels       200–299
// iqLevels           300–399
// tempospatialLevels 400–499
// gamesLevels        500–599
// tasksLevels        600–699

LevelEntry(
  data: LevelData(
    title: "Clever Title",           // don't spoil the mechanic
    instructions: "Clear objective!",
    // timeLimit: Duration(minutes: 5),
  ),
  widgetBuilder: (onComplete) => LevelYourName(onComplete: onComplete),
),
```

### Step 3 — test it

Run the app, navigate to your level and verify both the success and failure paths.

---

## Reusable utilities

### Progress service

```dart
import '../../services/progress_service.dart';

final status = ProgressService.instance.getLevelStatus(levelNumber);
final best = status?.bestScore; // 0–1, or null if never completed
```

### Notifications

```dart
import '../../services/notification_service.dart';

await NotificationService().show2FACode('123456');
```

### RNG / seed service

Use `SeedService` instead of `Random()` directly so that levels are reproducible when a harness passes a `?seed=` deeplink parameter.

```dart
import '../../services/seed_service.dart';

final _rng = SeedService.instance.createRandom();

// use _rng exactly like dart:math Random
final value = _rng.nextInt(6) + 1;
```

`createRandom()` returns a seeded `Random` when a seed is active, or an unseeded one otherwise. Call it once at level init — don't call it per frame.
