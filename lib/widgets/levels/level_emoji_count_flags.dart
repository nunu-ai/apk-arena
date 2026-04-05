import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelEmojiCountFlags extends LevelWidget {
  const LevelEmojiCountFlags({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelEmojiCountFlags> createState() => _LevelEmojiCountFlagsState();
}

class _LevelEmojiCountFlagsState extends State<LevelEmojiCountFlags> {
  final Random _rand = Random();

  bool _generated = false;
  final List<_EmojiItem> _items = [];
  late int _totalCount;
  late String _flag;

  int _roundIndex = 0;
  static const int _totalRounds = 3;

  final TextEditingController _controller = TextEditingController();

  // country flags (regional indicator letters)
  static const List<String> _flags = [
    '🇺🇸','🇬🇧','🇩🇪','🇫🇷','🇪🇸','🇮🇹','🇯🇵','🇨🇳','🇰🇷','🇧🇷',
    '🇨🇦','🇦🇺','🇮🇳','🇲🇽','🇿🇦','🇸🇪','🇳🇴','🇩🇰','🇫🇮','🇵🇱',
    '🇵🇹','🇳🇱','🇨🇭','🇦🇷','🇹🇷','🇺🇦','🇸🇬','🇳🇿','🇮🇩','🇸🇦',
  ];

  @override
  void initState() {
    super.initState();
    // Ensure any lingering keyboard from previous levels is closed
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusManager.instance.primaryFocus?.unfocus();
      try {
        await SystemChannels.textInput.invokeMethod('TextInput.hide');
      } catch (_) {
        // no-op: best-effort hide
      }
      if (mounted && !_generated) setState(() {});
    });
  }

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

    _flag = _flags[_rand.nextInt(_flags.length)];
    // progressive rounds: 1) 3-8, 2) 8-13, 3) 13-18
    if (_roundIndex == 0) {
      _totalCount = 3 + _rand.nextInt(6); // 3..8
    } else if (_roundIndex == 1) {
      _totalCount = 8 + _rand.nextInt(6); // 8..13
    } else {
      _totalCount = 13 + _rand.nextInt(6); // 13..18
    }

    // reserve space for header/question UI at the top and input at the bottom
    const double topSafe = 80; // header/question box clearance
    const double bottomSafe = 110; // bottom input bar clearance
    final double usableHeight = max(0, height - topSafe - bottomSafe);

    for (int i = 0; i < _totalCount; i++) {
      final double fontSize = 32 + _rand.nextInt(2) * 6; // 32,38
      final double x = _rand.nextDouble() * max(0, width - fontSize);
      final double y = topSafe + _rand.nextDouble() * max(0, usableHeight - fontSize);
      _items.add(_EmojiItem(emoji: _flag, size: fontSize, offset: Offset(x, y)));
    }
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      _showSnack('enter a number');
      return;
    }
    if (value == _totalCount) {
      // correct for this round
      if (_roundIndex + 1 >= _totalRounds) {
        widget.onComplete(LevelOutcome(score: 1));
        return;
      }
      // advance to next round
      _roundIndex += 1;
      _controller.clear();
      _items.clear();
      _generated = false;
      setState(() {});
    } else {
      _showSnack('wrong number');
      Future.delayed(const Duration(milliseconds: 900), () {
        if (mounted) widget.onComplete(LevelOutcome(score: 0));
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
        // Use a stable height that ignores current keyboard insets
        // so first spawn isn't compressed into the top half if a keyboard
        // is still open from a previous level.
        final media = MediaQuery.of(context);
        final effectiveHeight = constraints.maxHeight + media.viewInsets.bottom;
        _generate(Size(constraints.maxWidth, effectiveHeight));
        return Container(
          color: NunuColors.backgroundDefault,
          child: Stack(
            children: [
              // scattered flags
              for (final e in _items)
                Positioned(
                  left: e.offset.dx,
                  top: e.offset.dy,
                  child: Text(
                    e.emoji,
                    style: TextStyle(fontSize: e.size, height: 1.0),
                  ),
                ),

              // top-left hint
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
                      const Text('how many flags?', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(_flag, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

              // top-right round indicator
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: NunuColors.secondaryMain.withOpacity(0.6)),
                  ),
                  child: Text(
                    'round ${_roundIndex + 1}/$_totalRounds',
                    style: const TextStyle(fontSize: 12),
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
                            hintText: 'enter the total number',
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
}
