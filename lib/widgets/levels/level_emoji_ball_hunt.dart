import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelEmojiBallHunt extends LevelWidget {
  const LevelEmojiBallHunt({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelEmojiBallHunt> createState() => _LevelEmojiBallHuntState();
}

class _LevelEmojiBallHuntState extends State<LevelEmojiBallHunt> {
  final Random _rand = Random();

  // Generated once on first layout
  bool _generated = false;
  final List<_EmojiItem> _faces = [];
  final List<_EmojiItem> _balls = [];
  final Set<int> _foundBallIndexes = {};

  static const List<String> _faceEmojis = [
    '😀','😃','😄','😁','😆','😅','😂','🙂','😉','😜','🤪','🤗','😏','😎','😴',
    '😡','😱','😭','🤔','😬','🥲','🤩','🥵','🥶','🤧','🤮','🤯','🥳','😇','😈'
  ];

  static const List<String> _ballEmojis = ['🏀','⚽','🏈'];

  void _generateItems(Size size) {
    if (_generated) return;
    _generated = true;

    final width = size.width;
    final height = size.height;

    // Generate many faces with varied sizes
    final int faceCount = 90; // dense but performant
    for (int i = 0; i < faceCount; i++) {
      final emoji = _faceEmojis[_rand.nextInt(_faceEmojis.length)];
      final double fontSize = _rand.nextInt(4) * 8 + 24; // 24,32,40,48
      final double x = _rand.nextDouble() * max(0, width - fontSize);
      final double y = _rand.nextDouble() * max(0, height - fontSize - 24);
      _faces.add(_EmojiItem(emoji: emoji, size: fontSize, offset: Offset(x, y)));
    }

    // Generate three small balls, placed after faces so they render on top
    for (int i = 0; i < _ballEmojis.length; i++) {
      final emoji = _ballEmojis[i];
      const double fontSize = 18; // intentionally small target
      final double x = _rand.nextDouble() * max(0, width - fontSize);
      final double y = _rand.nextDouble() * max(0, height - fontSize - 24);
      _balls.add(_EmojiItem(emoji: emoji, size: fontSize, offset: Offset(x, y)));
    }
  }

  void _handleWrongTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('wrong emoji!'),
        backgroundColor: NunuColors.errorMain,
        duration: Duration(milliseconds: 900),
      ),
    );
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) widget.onComplete(false);
    });
  }

  void _handleBallTap(int index) {
    if (_foundBallIndexes.contains(index)) return;
    setState(() {
      _foundBallIndexes.add(index);
    });
    if (_foundBallIndexes.length == _balls.length) {
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _generateItems(Size(constraints.maxWidth, constraints.maxHeight));
        return Container(
          color: NunuColors.backgroundDefault,
          child: Stack(
            children: [
              // Faces (background, clickable = fail)
              for (final f in _faces)
                Positioned(
                  left: f.offset.dx,
                  top: f.offset.dy,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _handleWrongTap,
                    child: Text(
                      f.emoji,
                      style: TextStyle(fontSize: f.size, height: 1.0),
                    ),
                  ),
                ),

              // Balls (foreground, small targets)
              for (int i = 0; i < _balls.length; i++)
                Positioned(
                  left: _balls[i].offset.dx,
                  top: _balls[i].offset.dy,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _handleBallTap(i),
                    child: Opacity(
                      opacity: _foundBallIndexes.contains(i) ? 0.35 : 1.0,
                      child: Text(
                        _balls[i].emoji,
                        style: TextStyle(
                          fontSize: _balls[i].size,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
                ),

              // Progress indicator
              Positioned(
                left: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NunuColors.primaryMain.withOpacity(0.6)),
                  ),
                  child: Text(
                    'balls: ${_foundBallIndexes.length}/${_balls.length}',
                    style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmojiItem {
  final String emoji;
  final double size;
  final Offset offset;
  _EmojiItem({required this.emoji, required this.size, required this.offset});
}

