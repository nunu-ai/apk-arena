import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LevelHud extends StatelessWidget {
  const LevelHud({
    super.key,
    this.timerText,
    this.stageText,
    this.lives,
    this.infoTitle,
    this.infoBody,
    this.infoOnPressed,
    this.trailing,
  });

  final String? timerText;
  final String? stageText;
  final String? lives;
  final String? infoTitle;
  final String? infoBody;
  final VoidCallback? infoOnPressed;
  final Widget? trailing;

  static String emojiLives(int current, int max) {
    final safeCurrent = current.clamp(0, max).toInt();
    return List.generate(max, (i) => i < safeCurrent ? '❤️' : '🖤').join();
  }

  bool get _hasInfo =>
      infoOnPressed != null || (infoTitle != null && infoBody != null);

  @override
  Widget build(BuildContext context) {
    if (timerText == null &&
        stageText == null &&
        lives == null &&
        !_hasInfo &&
        trailing == null) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withValues(alpha: 0.96),
        border: Border(
          bottom: BorderSide(
            color: NunuColors.primaryMain.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          if (stageText != null) _HudLabel(label: 'stage', value: stageText!),
          if (timerText != null) _HudLabel(label: 'time', value: timerText!),
          if (lives != null)
            Flexible(
              child: Text(
                lives!,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: const TextStyle(fontSize: 14, height: 1),
              ),
            ),
          if (trailing != null) Flexible(child: trailing!),
          if (_hasInfo)
            LevelInfoButton(
              title: infoTitle,
              body: infoBody,
              onPressed: infoOnPressed,
            ),
        ],
      ),
    );
  }
}

class _HudLabel extends StatelessWidget {
  const _HudLabel({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NunuColors.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: NunuColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class LevelInfoButton extends StatelessWidget {
  const LevelInfoButton({super.key, this.title, this.body, this.onPressed})
    : assert(
        onPressed != null || (title != null && body != null),
        'provide either onPressed or title/body',
      );

  final String? title;
  final String? body;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NunuColors.primaryMain.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap:
            onPressed ??
            () {
              showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text(title!),
                  content: Text(
                    body!,
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('got it'),
                    ),
                  ],
                ),
              );
            },
        child: const Padding(
          padding: EdgeInsets.all(5),
          child: Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: NunuColors.primaryLight,
          ),
        ),
      ),
    );
  }
}
