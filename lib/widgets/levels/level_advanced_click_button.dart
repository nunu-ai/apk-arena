import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelAdvancedClickButton extends LevelWidget {
  const LevelAdvancedClickButton({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelAdvancedClickButton> createState() => _LevelAdvancedClickButton();
}

class _LevelAdvancedClickButton extends State<LevelAdvancedClickButton> {
  final Random _rng = Random();
  Alignment _alignment = Alignment.center;
  int _streak = 0;

  @override
  void initState() {
    super.initState();
    _alignment = _randomAlignment();
  }

  Alignment _randomAlignment() {
    final double x = (_rng.nextDouble() * 2 - 1) * 0.9; // keep away from edges
    final double y = (_rng.nextDouble() * 2 - 1) * 0.9;
    return Alignment(x, y);
  }

  void _handlePressed() {
    final int nextStreak = _streak + 1;
    if (nextStreak >= 3) {
      widget.onComplete(true);
      return;
    }
    setState(() {
      _streak = nextStreak;
      _alignment = _randomAlignment();
    });
  }

  void _handleMissTap() {
    if (_streak == 0) {
      // nothing to reset; still randomize to keep movement
      setState(() {
        _alignment = _randomAlignment();
      });
      return;
    }
    setState(() {
      _streak = 0;
      _alignment = _randomAlignment();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Capture taps anywhere not on the button to reset the streak
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _handleMissTap,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Clicks: $_streak/3',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        AnimatedAlign(
          alignment: _alignment,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: FilledButton(
            onPressed: _handlePressed,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.4),
              foregroundColor: NunuColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(0, 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: const Text(
              'CLICK',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
