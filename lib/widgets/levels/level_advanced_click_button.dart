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
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Place the button near the top-right to avoid center and make it harder
        Positioned(
          top: 24,
          right: 24,
          child: FilledButton(
            onPressed: () {
              widget.onComplete(true);
            },
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
