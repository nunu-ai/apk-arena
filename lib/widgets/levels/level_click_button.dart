import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelClickButton extends LevelWidget {
  const LevelClickButton({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelClickButton> createState() => _LevelClickButton();
}

class _LevelClickButton extends State<LevelClickButton> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton(
        onPressed: () {
          // Complete the level successfully
          widget.onComplete(true);
        },
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 24),
          backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.4),
          foregroundColor: NunuColors.primaryLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'CLICK ME!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}