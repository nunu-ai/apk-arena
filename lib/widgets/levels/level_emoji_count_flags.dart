import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelEmojiCountFlags extends LevelWidget {
  const LevelEmojiCountFlags({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelEmojiCountFlags> createState() => _LevelEmojiCountFlagsState();
}

class _LevelEmojiCountFlagsState extends State<LevelEmojiCountFlags> {
  final Random _rand = Random();

  // stage definitions: (min, max) inclusive flag counts
  static const List<(int, int)> _stages = [
    (1, 3),
    (3, 6),
    (6, 10),
    (10, 15),
    (15, 20),
    (20, 30),
    (30, 40),
    (40, 50),
  ];

  int _stageIndex = 0;
  double _scoreAccum = 0; // accumulated score across stages
  bool _generated = false;
  final List<_EmojiItem> _items = [];
  late int _totalCount;
  late String _flag;

  // brief feedback overlay
  String? _feedbackText;
  Color? _feedbackColor;

  final TextEditingController _controller = TextEditingController();

  static const List<String> _flags = [
    '🇺🇸', '🇬🇧', '🇩🇪', '🇫🇷', '🇪🇸', '🇮🇹', '🇯🇵', '🇨🇳', '🇰🇷', '🇧🇷',
    '🇨🇦', '🇦🇺', '🇮🇳', '🇲🇽', '🇿🇦', '🇸🇪', '🇳🇴', '🇩🇰', '🇫🇮', '🇵🇱',
    '🇵🇹', '🇳🇱', '🇨🇭', '🇦🇷', '🇹🇷', '🇺🇦', '🇸🇬', '🇳🇿', '🇮🇩', '🇸🇦',
  ];

  @override
  void initState() {
    super.initState();
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

  Size? _fullSize; // captured once before keyboard opens

  void _generate(Size size) {
    if (_generated) return;
    _generated = true;

    // use the remembered full size so keyboard doesn't shrink the area
    _fullSize ??= size;
    final width = _fullSize!.width;
    final height = _fullSize!.height;

    final (lo, hi) = _stages[_stageIndex];
    _flag = _flags[_rand.nextInt(_flags.length)];
    _totalCount = lo + _rand.nextInt(hi - lo + 1);

    const double topSafe = 80;
    const double bottomSafe = 110;
    final double usableWidth = max(0, width - 12); // small side padding
    final double usableHeight = max(0, height - topSafe - bottomSafe);

    // grid-based placement with jitter to reduce overlaps
    const double cellBase = 48.0; // roughly emoji size
    final int cols = max(1, (usableWidth / cellBase).floor());
    final int rows = max(1, (usableHeight / cellBase).floor());
    final int totalCells = cols * rows;

    // pick _totalCount unique cells from the grid
    final cells = List.generate(totalCells, (i) => i)..shuffle(_rand);
    final chosen = cells.take(_totalCount).toList();

    final double cellW = usableWidth / cols;
    final double cellH = usableHeight / rows;

    for (final cell in chosen) {
      final int col = cell % cols;
      final int row = cell ~/ cols;
      final double fontSize = 32 + _rand.nextInt(2) * 6;
      // center in cell + random jitter within half-cell
      final double jitterX = (_rand.nextDouble() - 0.5) * (cellW - fontSize).clamp(0, cellW * 0.66);
      final double jitterY = (_rand.nextDouble() - 0.5) * (cellH - fontSize).clamp(0, cellH * 0.66);
      final double x = (col * cellW + cellW / 2 - fontSize / 2 + jitterX).clamp(0, width - fontSize);
      final double y = (topSafe + row * cellH + cellH / 2 - fontSize / 2 + jitterY).clamp(topSafe, topSafe + usableHeight - fontSize);
      _items.add(_EmojiItem(emoji: _flag, size: fontSize, offset: Offset(x, y)));
    }
  }

  void _submit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null) {
      _showSnack('enter a number');
      return;
    }

    // tolerance bands (ceil'd): exact=1.0, ≤5%=0.3, ≤10%=0.1, else 0
    final diff = (value - _totalCount).abs();
    final tol5 = (_totalCount * 0.05).ceil();
    final tol10 = (_totalCount * 0.10).ceil();

    late final double stageMultiplier;
    late final String feedback;
    late final Color feedbackCol;

    if (diff == 0) {
      stageMultiplier = 1.0;
      feedback = 'exact!';
      feedbackCol = NunuColors.successMain;
    } else if (diff <= tol5) {
      stageMultiplier = 0.3;
      feedback = 'close — off by $diff (was $_totalCount)';
      feedbackCol = NunuColors.warningMain;
    } else if (diff <= tol10) {
      stageMultiplier = 0.1;
      feedback = 'not quite — off by $diff (was $_totalCount)';
      feedbackCol = NunuColors.warningMain;
    } else {
      stageMultiplier = 0.0;
      feedback = 'wrong — it was $_totalCount';
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
        widget.onComplete(LevelOutcome(
          score: _scoreAccum.clamp(0, 1).toDouble(),
          metrics: {
            'total_stages': _stages.length,
          },
        ));
      } else {
        // dismiss keyboard before generating next stage so full screen is used
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
        final effectiveHeight =
            constraints.maxHeight + media.viewInsets.bottom;
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: NunuColors.primaryMain.withOpacity(0.6)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('how many flags?',
                          style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 8),
                      Text(_flag, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),

              // top-right stage indicator
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: NunuColors.secondaryMain.withOpacity(0.6)),
                  ),
                  child: Text(
                    'stage ${_stageIndex + 1}/${_stages.length}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),

              // feedback overlay
              if (_feedbackText != null)
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
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
                        color: NunuColors.primaryMain.withOpacity(0.6)),
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
                          style:
                              const TextStyle(color: NunuColors.textPrimary),
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
