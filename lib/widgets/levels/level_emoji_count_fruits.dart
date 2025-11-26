import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelEmojiCountFruits extends LevelWidget {
  const LevelEmojiCountFruits({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelEmojiCountFruits> createState() => _LevelEmojiCountFruitsState();
}

class _LevelEmojiCountFruitsState extends State<LevelEmojiCountFruits> {
  final Random _rand = Random();

  bool _generated = false;
  final List<_EmojiItem> _items = [];
  late final int _targetCount;
  late final String _target;

  final TextEditingController _controller = TextEditingController();

  static const List<String> _fruits = [
    '🍎', '🍏', '🍌', '🍊', '🍋', '🍐', '🍇', '🍓', '🍍', '🍑',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generate(Size size) {
    if (_generated) return;
    _generated = true;

    final width = size.width;
    final height = size.height;

    _target = _fruits[_rand.nextInt(_fruits.length)];
    _targetCount = 5 + _rand.nextInt(16); // 5..20 target

    // reserve space for header/question UI at the top and input at the bottom
    const double topSafe = 80; // header/question box clearance
    const double bottomSafe = 110; // bottom input bar clearance
    final double usableHeight = max(0, height - topSafe - bottomSafe);

    // target fruit items (duplicates)
    for (int i = 0; i < _targetCount; i++) {
      final double fontSize = 30 + _rand.nextInt(2) * 6; // 30,36
      final double x = _rand.nextDouble() * max(0, width - fontSize);
      final double y = topSafe + _rand.nextDouble() * max(0, usableHeight - fontSize);
      _items.add(_EmojiItem(emoji: _target, size: fontSize, offset: Offset(x, y)));
    }

    // distractor fruit TYPES (each with multiple duplicates)
    final int distractorTypes = 3 + _rand.nextInt(3); // 3..5 types
    final Set<String> used = {_target};
    for (int t = 0; t < distractorTypes; t++) {
      String other;
      do {
        other = _fruits[_rand.nextInt(_fruits.length)];
      } while (used.contains(other));
      used.add(other);

      final int duplicates = 6 + _rand.nextInt(10); // 6..15 each
      for (int i = 0; i < duplicates; i++) {
        final double fontSize = 30 + _rand.nextInt(2) * 6;
        final double x = _rand.nextDouble() * max(0, width - fontSize);
        final double y = topSafe + _rand.nextDouble() * max(0, usableHeight - fontSize);
        _items.add(_EmojiItem(emoji: other, size: fontSize, offset: Offset(x, y)));
      }
    }

    // randomize positions for a natural scatter
    _items.shuffle(_rand);
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      _showSnack('enter a number');
      return;
    }
    if (value == _targetCount) {
      widget.onComplete(true);
    } else {
      _showSnack('wrong number');
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) widget.onComplete(false);
      });
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: NunuColors.errorMain,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _generate(Size(constraints.maxWidth, constraints.maxHeight));
        return Container(
          color: NunuColors.backgroundDefault,
          child: Stack(
            children: [
              // scattered fruits
              for (final e in _items)
                Positioned(
                  left: e.offset.dx,
                  top: e.offset.dy,
                  child: Text(
                    e.emoji,
                    style: TextStyle(fontSize: e.size, height: 1.0),
                  ),
                ),

              // top-left target indicator
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NunuColors.primaryMain.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('how many of this fruit?', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(_target, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),

              // bottom input bar
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: NunuColors.primaryMain.withOpacity(0.6)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'enter the number of target fruit',
                          ),
                          style: const TextStyle(color: NunuColors.textPrimary),
                          onSubmitted: (_) => _submit(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _submit,
                        child: const Text('submit'),
                      ),
                    ],
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

  _EmojiItem copyWith({String? emoji, double? size, Offset? offset}) =>
      _EmojiItem(
        emoji: emoji ?? this.emoji,
        size: size ?? this.size,
        offset: offset ?? this.offset,
      );
}
