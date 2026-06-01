import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class LevelHudBullet {
  const LevelHudBullet(this.emoji, this.text);
  final String emoji;
  final String text;
}

class LevelHud extends StatelessWidget {
  const LevelHud({
    super.key,
    this.timerText,
    this.stageText,
    this.lives,
    this.infoTitle,
    this.infoItems,
    this.infoOnPressed,
    this.trailing,
  });

  final String? timerText;
  final String? stageText;
  final String? lives;
  final String? infoTitle;
  final List<LevelHudBullet>? infoItems;
  final VoidCallback? infoOnPressed;
  final Widget? trailing;

  static String emojiLives(int current, int max) {
    final safeCurrent = current.clamp(0, max).toInt();
    return List.generate(max, (i) => i < safeCurrent ? '❤️' : '🖤').join();
  }

  bool get _hasInfo =>
      infoOnPressed != null ||
      (infoTitle != null && infoItems != null && infoItems!.isNotEmpty);

  static const _statStyle = TextStyle(
    color: NunuColors.textPrimary,
    fontSize: 13,
    fontWeight: FontWeight.w800,
    height: 1,
    fontFeatures: [FontFeature.tabularFigures()],
  );

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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
          if (stageText != null)
            Text(stageText!, style: _statStyle, overflow: TextOverflow.ellipsis),
          if (timerText != null)
            Text('⏱ $timerText', style: _statStyle),
          if (lives != null)
            Flexible(
              child: Text(
                lives!,
                overflow: TextOverflow.fade,
                softWrap: false,
                style: _statStyle,
              ),
            ),
          if (trailing != null) Flexible(child: trailing!),
          if (_hasInfo)
            LevelInfoButton(
              title: infoTitle,
              items: infoItems,
              onPressed: infoOnPressed,
            ),
        ],
      ),
    );
  }
}

class LevelInfoButton extends StatelessWidget {
  const LevelInfoButton({super.key, this.title, this.items, this.onPressed})
    : assert(
        onPressed != null || (title != null && items != null),
        'provide either onPressed or title+items',
      );

  final String? title;
  final List<LevelHudBullet>? items;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NunuColors.primaryMain.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed ?? () => _showSheet(context),
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

  void _showSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NunuColors.backgroundPaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.4,
        maxChildSize: 0.85,
        minChildSize: 0.25,
        builder: (ctx, scrollCtrl) => SingleChildScrollView(
          controller: scrollCtrl,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: NunuColors.textSecondary.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                title!,
                style: const TextStyle(
                  color: NunuColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 18),
              for (final item in items!) ...[
                _Bullet(item),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.item);
  final LevelHudBullet item;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 28,
          child: Text(item.emoji, style: const TextStyle(fontSize: 16)),
        ),
        Expanded(
          child: Text(
            item.text,
            style: const TextStyle(
              color: NunuColors.textSecondary,
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
