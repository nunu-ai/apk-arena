import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelEmojiCountFruits extends LevelWidget {
  const LevelEmojiCountFruits({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelEmojiCountFruits> createState() => _LevelEmojiCountFruitsState();
}

class _LevelEmojiCountFruitsState extends State<LevelEmojiCountFruits> {
  final Random _rand = Random();

  // each stage: (targetMin, targetMax, distractorTypes, distractorPerType)
  static const List<(int, int, int, int)> _stages = [
    (3, 5, 1, 3), // easy: few targets, 1 distractor type
    (5, 8, 2, 4), // a bit more
    (6, 10, 2, 5), // more items, same variety
    (8, 12, 3, 6), // new distractor type
    (10, 15, 3, 7), // getting crowded
    (12, 18, 4, 8), // busier
    (15, 21, 4, 10), // more targets, more clutter
    (18, 25, 5, 11), // lots of variety
    (22, 30, 6, 12), // fruit chaos
    (26, 36, 7, 13), // full bowl meltdown
  ];

  static const List<String> _fruits = [
    '🍎',
    '🍏',
    '🍌',
    '🍊',
    '🍋',
    '🍐',
    '🍇',
    '🍓',
    '🍍',
    '🍑',
    '🥝',
    '🍒',
    '🫐',
    '🥭',
    '🍈',
  ];

  int _stageIndex = 0;
  double _scoreAccum = 0;
  bool _generated = false;
  final List<_EmojiItem> _items = [];
  late int _targetCount;
  late String _target;
  Size? _fullSize;

  String? _feedbackText;
  Color? _feedbackColor;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: _scoreAccum.clamp(0.0, 1.0),
          metrics: {'stages_scored': _stageIndex},
        ));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusManager.instance.primaryFocus?.unfocus();
      try {
        await SystemChannels.textInput.invokeMethod('TextInput.hide');
      } catch (_) {}
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

    _fullSize ??= size;
    final width = _fullSize!.width;
    final height = _fullSize!.height;

    final (tMin, tMax, dTypes, dPerType) = _stages[_stageIndex];
    _targetCount = tMin + _rand.nextInt(tMax - tMin + 1);

    // pick target fruit
    _target = _fruits[_rand.nextInt(_fruits.length)];

    const double topSafe = 80;
    const double bottomSafe = 110;
    final double usableHeight = max(0, height - topSafe - bottomSafe);

    // place target items
    for (int i = 0; i < _targetCount; i++) {
      _items.add(_randomItem(_target, width, topSafe, usableHeight));
    }

    // place distractors
    final Set<String> used = {_target};
    final availDistractors = _fruits.where((f) => f != _target).toList()
      ..shuffle(_rand);
    final int actualTypes = min(dTypes, availDistractors.length);
    for (int t = 0; t < actualTypes; t++) {
      final other = availDistractors[t];
      used.add(other);
      final int count = max(1, dPerType + _rand.nextInt(5) - 2); // ±2 variance
      for (int i = 0; i < count; i++) {
        _items.add(_randomItem(other, width, topSafe, usableHeight));
      }
    }

    _items.shuffle(_rand);
  }

  _EmojiItem _randomItem(
    String emoji,
    double width,
    double topSafe,
    double usableHeight,
  ) {
    final double fontSize = 30 + _rand.nextInt(2) * 6;
    final double x = _rand.nextDouble() * max(0, width - fontSize);
    final double y =
        topSafe + _rand.nextDouble() * max(0, usableHeight - fontSize);
    return _EmojiItem(emoji: emoji, size: fontSize, offset: Offset(x, y));
  }

  void _submit() {
    if (_feedbackText != null) return;
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      _showSnack('enter a number');
      return;
    }

    // tolerance: exact=1.0, ≤5%=0.3, ≤10%=0.1, else 0
    final diff = (value - _targetCount).abs();
    final tol5 = (_targetCount * 0.05).ceil();
    final tol10 = (_targetCount * 0.10).ceil();

    late final double stageMultiplier;
    late final String feedback;
    late final Color feedbackCol;

    if (diff == 0) {
      stageMultiplier = 1.0;
      feedback = 'exact!';
      feedbackCol = NunuColors.successMain;
    } else if (diff <= tol5) {
      stageMultiplier = 0.3;
      feedback = 'close — off by $diff (was $_targetCount)';
      feedbackCol = NunuColors.warningMain;
    } else if (diff <= tol10) {
      stageMultiplier = 0.1;
      feedback = 'not quite — off by $diff (was $_targetCount)';
      feedbackCol = NunuColors.warningMain;
    } else {
      stageMultiplier = 0.0;
      feedback = 'wrong — it was $_targetCount';
      feedbackCol = NunuColors.errorMain;
    }

    _scoreAccum += stageMultiplier / _stages.length;

    setState(() {
      _feedbackText = feedback;
      _feedbackColor = feedbackCol;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_stageIndex + 1 >= _stages.length) {
        widget.onComplete(
          LevelOutcome(
            score: _scoreAccum.clamp(0, 1).toDouble(),
            metrics: {'total_stages': _stages.length},
          ),
        );
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
        try {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        } catch (_) {}
        _stageIndex++;
        _controller.clear();
        _items.clear();
        _generated = false;
        _feedbackText = null;
        _feedbackColor = null;
        setState(() {});
      }
    });
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
        final media = MediaQuery.of(context);
        final effectiveHeight = constraints.maxHeight + media.viewInsets.bottom;
        _generate(Size(constraints.maxWidth, effectiveHeight));
        return Container(
          color: NunuColors.backgroundDefault,
          child: Stack(
            children: [
              for (final e in _items)
                Positioned(
                  left: e.offset.dx,
                  top: e.offset.dy,
                  child: Text(
                    e.emoji,
                    style: TextStyle(fontSize: e.size, height: 1.0),
                  ),
                ),

              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LevelHud(
                  stageText: '${_stageIndex + 1}/${_stages.length}',
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'target',
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_target, style: const TextStyle(fontSize: 18)),
                    ],
                  ),
                ),
              ),

              // feedback overlay
              if (_feedbackText != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _feedbackColor!.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _feedbackText!,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                    border: Border.all(
                      color: NunuColors.primaryMain.withOpacity(0.6),
                    ),
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
                        onPressed: _feedbackText != null ? null : _submit,
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
