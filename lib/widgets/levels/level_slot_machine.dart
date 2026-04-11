import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSlotMachine extends LevelWidget {
  const LevelSlotMachine({super.key, required super.onComplete});

  @override
  State<LevelSlotMachine> createState() => _LevelSlotMachineState();
}

class _LevelSlotMachineState extends State<LevelSlotMachine>
    with TickerProviderStateMixin {
  static const int _cellCount = 8;
  static const double _cellHeight = 88.0;
  static const int _visibleCells = 3;
  static const double _viewportHeight = _cellHeight * _visibleCells;

  final _random = Random();

  /// Three reels, each with [_cellCount] random numbers in 1..9.
  late final List<List<int>> _reels;

  /// One "marker" index per reel — this cell gets a gold background so the
  /// player can tell when the reel has completed a full revolution.
  late final List<int> _markerIndices;

  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;
  final List<double> _currentOffsets = [0.0, 0.0, 0.0];

  final _answerController = TextEditingController();
  bool _isSpinning = false;
  String? _errorMessage;

  // ───────────────────────────────────────── lifecycle

  @override
  void initState() {
    super.initState();

    _reels = List.generate(
      3,
      (_) => List.generate(_cellCount, (_) => _random.nextInt(9) + 1),
    );
    _markerIndices = List.generate(3, (_) => _random.nextInt(_cellCount));

    _controllers = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 4500 + i * 600),
      ),
    );

    // Before first spin the reels sit still at offset 0.
    _animations = List.generate(
      3,
      (i) => const AlwaysStoppedAnimation<double>(0.0),
    );
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    _answerController.dispose();
    super.dispose();
  }

  // ───────────────────────────────────────── logic

  int get _correctSum {
    int sum = 0;
    for (final reel in _reels) {
      for (final n in reel) {
        sum += n;
      }
    }
    return sum;
  }

  void _spin() {
    if (_isSpinning) return;
    setState(() {
      _isSpinning = true;
      _errorMessage = null;
    });

    int completed = 0;

    for (int i = 0; i < 3; i++) {
      // 1–2 full rotations + a random cell offset so it stops at a new place.
      final rotations = 1 + _random.nextInt(2);
      final extraCells = _random.nextInt(_cellCount);
      final totalScroll = (rotations * _cellCount + extraCells) * _cellHeight;

      final start = _currentOffsets[i];
      final end = start + totalScroll;

      _animations[i] = Tween<double>(begin: start, end: end).animate(
        CurvedAnimation(parent: _controllers[i], curve: Curves.easeOutCubic),
      );

      _currentOffsets[i] = end;

      _controllers[i].reset();
      _controllers[i].forward().then((_) {
        completed++;
        if (completed == 3 && mounted) {
          setState(() => _isSpinning = false);
        }
      });
    }
  }

  void _submit() {
    final input = int.tryParse(_answerController.text.trim());
    if (input == null) {
      setState(() => _errorMessage = 'enter a number');
      return;
    }
    if (input == _correctSum) {
      widget.onComplete(LevelOutcome(score: 1));
    } else {
      setState(() => _errorMessage = 'wrong — try again');
    }
  }

  // ───────────────────────────────────────── build

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildSlotFrame(),
            _buildAnswerRow(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  // ── slot machine frame ──

  Widget _buildSlotFrame() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: NunuColors.primaryDark, width: 2),
              boxShadow: [
                BoxShadow(
                  color: NunuColors.primaryMain.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── title ──
                const Text(
                  'LUCKY NUMBERS',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: NunuColors.primaryLight,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),

                // ── three reels side-by-side ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: 10),
                      _buildReelColumn(i),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // ── spin button ──
                SizedBox(
                  width: 200,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSpinning ? null : _spin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NunuColors.primaryMain,
                      disabledBackgroundColor: NunuColors.primaryDark,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 4,
                    ),
                    child: Text(
                      _isSpinning ? 'spinning...' : 'SPIN',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── single reel column ──

  Widget _buildReelColumn(int reelIndex) {
    return AnimatedBuilder(
      animation: _controllers[reelIndex],
      builder: (context, _) {
        final offset = _animations[reelIndex].value;
        return Container(
          width: 92,
          height: _viewportHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF050510),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: NunuColors.secondaryDark.withValues(alpha: 0.6),
              width: 1.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              children: [
                // cells
                ..._buildCells(reelIndex, offset),
                // center-row highlight lines
                Positioned(
                  left: 0,
                  right: 0,
                  top: _cellHeight - 1,
                  height: _cellHeight + 2,
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.symmetric(
                          horizontal: BorderSide(
                            color: NunuColors.primaryMain.withValues(
                              alpha: 0.7,
                            ),
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── build the visible cells for one reel ──

  List<Widget> _buildCells(int reelIndex, double scrollOffset) {
    final cells = <Widget>[];
    final fractional = scrollOffset % _cellHeight;
    final topCellAbsolute = (scrollOffset / _cellHeight).floor();

    // Render _visibleCells + 1 cells so partial scroll stays seamless.
    for (int j = 0; j <= _visibleCells; j++) {
      final rawIndex = topCellAbsolute + j;
      final cellIndex = ((rawIndex % _cellCount) + _cellCount) % _cellCount;
      final yPos = j * _cellHeight - fractional;

      final isMarker = cellIndex == _markerIndices[reelIndex];

      // The center row spans from y = _cellHeight to y = 2 * _cellHeight.
      final cellCenterY = yPos + _cellHeight / 2;
      final isCenter =
          cellCenterY >= _cellHeight && cellCenterY < _cellHeight * 2;

      cells.add(
        Positioned(
          left: 0,
          right: 0,
          top: yPos,
          height: _cellHeight,
          child: _buildCell(
            _reels[reelIndex][cellIndex],
            isMarker: isMarker,
            isCenter: isCenter,
          ),
        ),
      );
    }
    return cells;
  }

  // ── individual number cell ──

  Widget _buildCell(
    int number, {
    required bool isMarker,
    required bool isCenter,
  }) {
    final bgColor = isMarker
        ? NunuColors.warningDark.withValues(alpha: 0.25)
        : Colors.transparent;

    final textColor = isCenter
        ? (isMarker ? NunuColors.warningLight : Colors.white)
        : Colors.white.withValues(alpha: 0.35);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: isMarker
            ? Border.all(
                color: NunuColors.warningMain.withValues(alpha: 0.7),
                width: 2,
              )
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        '$number',
        style: TextStyle(
          fontSize: 48,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  // ── answer input row ──

  Widget _buildAnswerRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'total sum',
                labelStyle: const TextStyle(color: NunuColors.textSecondary),
                errorText: _errorMessage,
                filled: true,
                fillColor: NunuColors.backgroundPaper,
                enabledBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: NunuColors.secondaryMain),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: NunuColors.primaryMain,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                errorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(color: NunuColors.errorMain),
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                    color: NunuColors.errorMain,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: NunuColors.successMain,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Text(
                'submit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
