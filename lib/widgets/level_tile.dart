import 'package:apk_arena/models/level_status.dart';
import 'package:apk_arena/theme/app_theme.dart';
import 'package:flutter/material.dart';

class LevelTile extends StatelessWidget {
  final int levelNumber;
  final String title;
  final LevelStatus? status;
  final VoidCallback onTap;

  const LevelTile({
    Key? key,
    required this.levelNumber,
    required this.title,
    required this.status,
    required this.onTap,
  }) : super(key: key);

  double? get _best => status?.bestScore;

  Color get _color {
    final b = _best;
    if (b == null) return NunuColors.secondaryMain;
    if (b >= 0.85) return NunuColors.successMain;
    if (b >= 0.5) return NunuColors.warningMain;
    return NunuColors.errorMain;
  }

  Color get _textColor {
    final b = _best;
    if (b == null) return NunuColors.secondaryLight;
    if (b >= 0.85) return NunuColors.successLight;
    if (b >= 0.5) return NunuColors.warningLight;
    return NunuColors.errorLight;
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _color, width: 2),
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Stack(
          children: [
            // number + title centered
            Positioned.fill(
              bottom: 18,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$levelNumber',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      title.toLowerCase(),
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _textColor.withValues(alpha: 0.9),
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // score bar pinned to bottom
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: _best ?? 0,
                  backgroundColor: _color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(_color.withValues(alpha: 0.9)),
                  minHeight: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
