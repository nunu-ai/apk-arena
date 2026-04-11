import 'package:apk_arena/models/level_status.dart';
import 'package:apk_arena/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LevelTile extends StatelessWidget {
  final int levelNumber;
  final LevelStatus? status;
  final VoidCallback onTap;

  const LevelTile({
    Key? key,
    required this.levelNumber,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  double? get _best => status?.bestScore;

  Color getBorderColor() {
    final b = _best;
    if (b == null) return NunuColors.secondaryMain;
    if (b >= 0.85) return NunuColors.successMain;
    if (b >= 0.5) return NunuColors.warningMain;
    return NunuColors.errorMain;
  }

  Color getTextColor() {
    final b = _best;
    if (b == null) return NunuColors.secondaryLight;
    if (b >= 0.85) return NunuColors.successLight;
    if (b >= 0.5) return NunuColors.warningMain;
    return NunuColors.errorLight;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: getBorderColor(),
            width: 2,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Text(
                '$levelNumber',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: getTextColor(),
                ),
              ),
            ),
            if (_best != null)
              Positioned(
                bottom: 4,
                left: 0,
                right: 0,
                child: Text(
                  '${(_best! * 100).round()}%',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: getTextColor().withValues(alpha: 0.95),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
