# 🤖 Guide for AI Agents Working on APK Arena

## 📋 Overview

APK Arena is a Flutter-based mobile benchmark app designed to test AI agents across multiple dimensions:
- **Device Interaction Skills** - Touch, swipe, gestures, and fine-grained control
- **Task Solving** - UI navigation and complex multi-step flows
- **Vision Capabilities** - Image recognition and spatial awareness
- **Model IQ** - Logic, pattern recognition, problem-solving
- **Memory** - Multi-step task retention

## 🎯 Project Purpose 
This app serves as a lightweight, easy-to-deploy alternative to complex benchmarks like Android World. It can be installed in 30 seconds and immediately used to test mobile AI agents.

## 📁 Project Structure
```
lib/
├── services/
│   ├── progress_service.dart      # Persistent progress tracking
│   └── notification_service.dart  # OS-level integrations (2FA, etc.)
│
├── theme/
│   └── app_theme.dart             # Nunu.ai brand theming (dark theme)
│
├── screens/
│   ├── level_selector.dart        # Main menu with difficulty tabs
│   ├── level_screen.dart          # Level wrapper (handles timing, completion)
│   └── level_completion_screen.dart # Results screen
│
├── widgets/
│   ├── level_widget.dart          # Abstract base class for ALL levels
│   ├── level_tile.dart            # Grid item in level selector
│   │
│   ├── levels/                    # ⭐ ALL LEVELS GO HERE ⭐
│   │   ├── level_click_button.dart
│   │   ├── level_swipe_directions.dart
│   │   ├── level_2fa_login.dart
│   │   ├── level_email_riddle.dart
│   │   └── ...
│   │
│   └── level_components/          # Reusable UI components
│       ├── dice.dart
│       ├── contact_list_item.dart
│       └── gmail/
│           ├── gmail_email_list.dart
│           ├── gmail_email_detail.dart
│           └── gmail_email_compose.dart
│
└── level_registry.dart            # ⭐ REGISTER NEW LEVELS HERE ⭐
```

## 🎨 Theming Guidelines

### Default Theme: Nunu.ai Brand
The app uses a dark cyberpunk theme with these primary colors:

```dart
// Primary (Pink/Magenta)
NunuColors.primaryMain     // #E55CD8
NunuColors.primaryLight    // #F79EDE
NunuColors.primaryDark     // #9A2EA4

// Secondary (Purple)
NunuColors.secondaryMain   // #805CE5
NunuColors.secondaryLight  // #BA9EF7

// Background
NunuColors.backgroundDefault // #0A0A1C (very dark blue)
NunuColors.backgroundPaper   // #16122F (slightly lighter)

// Semantic Colors
NunuColors.successMain     // #22C55E (green)
NunuColors.errorMain       // #FF5630 (red)
NunuColors.warningMain     // #FFAB00 (yellow)
```

**When to use Nunu theme:**
- ✅ Default for all custom/original levels
- ✅ Gaming-themed challenges
- ✅ Abstract puzzles
- ✅ Sci-fi scenarios

### Custom Themes for Specific UIs
When recreating existing app interfaces, match their design:

**Examples:**
- Gmail level → Use Gmail's red/white color scheme
- Instagram level → Use Instagram's gradient and black/white
- iOS Contacts → Use iOS gray/blue design
- Terminal level → Use green-on-black classic terminal

**Key principle:** *Authenticity over brand consistency for UI recreation levels*

## ✍️ Writing & Text Casing

- **default casing**: use all-lowercase for UI labels, buttons, and copy
- **caps usage**: ALL-CAPS is acceptable as a deliberate style, but use sparingly
- **consistency**: pick one per level/screen (all-lowercase or ALL-CAPS) and stick to it
- **exceptions**: when mimicking real apps, match their original casing (e.g., Gmail, Android Calendar) including component text

## 🎮 Level Design Philosophy

### Cultural References & Humor
APK Arena embraces gaming culture and internet humor. Examples:

**Portal/Aperture Science:**
- Email riddle level features GLaDOS, Cave Johnson, Wheatley, Chell
- References to cake, neurotoxin, combustible lemons
- Corporate dystopia humor

**Better Call Saul:**
- Contact scroll level features "Saul Goodman" with phone "(505) CALL-SAUL"

**DVD Screensaver:**
- Classic bouncing DVD logo that changes color on bounce
- Nostalgic 2000s reference

**Meme Culture:**
- "Feeding the Algorithm" (Instagram double-tap level)
- Popup Hell (annoying nested popups)
- CAPTCHA challenges

### Avoid
- ❌ Heavy-handed corporate speak
- ❌ Boring generic instructions
- ❌ Explaining jokes in the level title (let users discover the humor)

## 📝 Creating a New Level

### Step 1: Create Level Widget
Create `lib/widgets/levels/level_your_name.dart`:

```dart
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelYourName extends LevelWidget {
  const LevelYourName({Key? key, required super.onComplete}) : super(key: key);

  @override
  State createState() => _LevelYourNameState();
}

class _LevelYourNameState extends State {
  // Your state variables here
  bool _isComplete = false;
  
  void _checkCompletion() {
    if (/* completion criteria */) {
      widget.onComplete(true);  // Success!
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Center(
        child: YourUI(),
      ),
    );
  }
}
```

**Critical Rules:**
1. ✅ **MUST** extend `LevelWidget`
2. ✅ **MUST** call `widget.onComplete(true)` for success
3. ✅ **MUST** call `widget.onComplete(false)` for failure (optional, but good for wrong answers)
4. ✅ File **MUST** start with `level_` prefix
5. ✅ Use `NunuColors.*` for theming (unless recreating specific UI)

### Step 2: Register in Registry

Add to `level_registry.dart`:

```dart
import 'package:apk_arena/widgets/levels/level_your_name.dart';

// Choose difficulty tier:
final List easyLevels = [    // 0-99
final List mediumLevels = [  // 100-199
final List hardLevels = [    // 200-299

  // Add your level:
  LevelEntry(
    data: LevelData(
      title: "Clever Title",              // DON'T spoil the solution!
      instructions: "Clear objective!",    // Be specific about goal
    ),
    widgetBuilder: (onComplete) => LevelYourName(onComplete: onComplete),
  ),
];
```

**Title & Instruction Guidelines:**

✅ **Good Examples:**
- Title: "Prove You're Human" | Instructions: "Complete the CAPTCHA verification!"
- Title: "Better Call Saul" | Instructions: "Find Saul Goodman in your contacts!"
- Title: "Feeding the Algorithm" | Instructions: "Like the post!"

❌ **Bad Examples:**
- Title: "Double Tap Level" (spoils the mechanic)
- Title: "Solve This" | Instructions: "Do the thing" (too vague)
- Title: "Instagram Clone" (breaks immersion, should be thematic)

## 🎯 Level Difficulty Guidelines

### Easy Levels (0-99)
**Target: Simple interactions, clear objectives**

Examples:
- Single button press
- Basic swipes (up/down/left/right)
- Simple form fills
- Hold duration
- Connect dots in sequence

**Characteristics:**
- Single-step tasks
- Immediate feedback
- Obvious success criteria
- seconds to 1-3 mins to complete

### Medium Levels (100-199)
**Target: Multi-step flows, moderate complexity**

Examples:
- Multi-step sign-up forms
- 2FA authentication flow
- Email reading and replying
- Pattern recognition (dice counting)
- Nested navigation

**Characteristics:**
- 2-20 step processes
- Requires reading/understanding
- Some trial and error acceptable
- 5-15 minutes to complete

### Hard Levels (200-299)
**Target: Complex tasks, advanced skills**

Examples:
- Moving target interaction (DVD logo)
- Complex multi-path navigation
- Time-sensitive challenges
- Memory + execution combined
- Puzzle solving

**Characteristics:**
- complex logic or straight up impossible for current agents
- Requires planning
- May need multiple attempts
- 15 minutes to hours to complete

## 🔧 Common Patterns & Utilities

### Using Progress Service
```dart
import '../../services/progress_service.dart';

final _progressService = ProgressService.instance;

// Check if level completed
final status = _progressService.getLevelStatus(levelNumber);
if (status?.result == LevelResult.success) {
  // Level was completed
}
```

### Using Notifications
```dart
import '../../services/notification_service.dart';

// Send notification (useful for 2FA, reminders, etc.)
await NotificationService().show2FACode('123456');
```

### Using Reusable Components
```dart
import '../level_components/dice.dart';
import '../level_components/contact_list_item.dart';

// Use existing UI components
DiceWidget(value: 5, size: 50)

ContactListItem(
  name: 'John Doe',
  subtitle: '555-1234',
  onTap: () => handleTap(),
)
```

## 🚀 Quick Start Checklist

For AI agents creating a new level:

- [ ] Read this entire document
- [ ] Look at 2-3 existing levels for patterns
- [ ] Choose appropriate difficulty tier
- [ ] Create level file in `lib/widgets/levels/`
- [ ] Extend `LevelWidget` base class
- [ ] Implement `widget.onComplete(bool)` calls
- [ ] Add cultural references / humor (gaming, memes, sci-fi)
- [ ] Register in `level_registry.dart`
- [ ] Write clever title (don't spoil solution!)
- [ ] Write clear instructions
- [ ] Test thoroughly
- [ ] Check theme consistency