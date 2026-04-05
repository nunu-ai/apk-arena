import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelClickGridCoordinate extends LevelWidget {
  const LevelClickGridCoordinate({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelClickGridCoordinate> createState() =>
      _LevelClickGridCoordinateState();
}

class _LevelClickGridCoordinateState extends State<LevelClickGridCoordinate> {
  static const int _initialSize = 5; // At least width 5
  static const int _requiredStreak = 3;

  final Random _random = Random();

  int _currentRound = 0; // 0-based; completes at 3
  late int _gridSize; // NxN for simplicity
  late int _targetRow1; // 1-indexed
  late int _targetCol1; // 1-indexed

  @override
  void initState() {
    super.initState();
    _gridSize = _initialSize;
    _rollNewTarget();
  }

  void _rollNewTarget() {
    // 1-indexed coordinates for the instruction
    _targetRow1 = _random.nextInt(_gridSize) + 1;
    _targetCol1 = _random.nextInt(_gridSize) + 1;
  }

  void _handleTap(int index) {
    final int row0 = index ~/ _gridSize;
    final int col0 = index % _gridSize;
    // Convert to 1-indexed with origin (1,1) at bottom-left
    final int row1 = _gridSize - row0;
    final int col1 = col0 + 1;

    if (row1 == _targetRow1 && col1 == _targetCol1) {
      // Correct
      if (_currentRound + 1 >= _requiredStreak) {
        widget.onComplete(LevelOutcome(score: 1));
        return;
      }
      setState(() {
        _currentRound += 1;
        _gridSize += 1; // increase difficulty each success
        _rollNewTarget();
      });
    } else {
      // Wrong selection resets progress and grid size
      setState(() {
        _currentRound = 0;
        _gridSize = _initialSize;
        _rollNewTarget();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final String instruction = 'column: ${_targetCol1}, row: ${_targetRow1}';

    return Container(
      color: NunuColors.backgroundDefault,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                instruction,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NunuColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'streak: ${_currentRound} / $_requiredStreak',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Keep a reasonable max size square grid area
                    final double gridSizePx =
                        min(constraints.maxWidth, constraints.maxHeight) * 0.9;
                    return SizedBox(
                      width: gridSizePx,
                      height: gridSizePx,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                        itemCount: _gridSize * _gridSize,
                        itemBuilder: (context, index) {
                          return _GridCell(onTap: () => _handleTap(index));
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _GridCell extends StatelessWidget {
  final VoidCallback onTap;
  const _GridCell({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.circle,
            color: NunuColors.primaryMain.withValues(alpha: 0.75),
            size: 18,
          ),
        ),
      ),
    );
  }
}
