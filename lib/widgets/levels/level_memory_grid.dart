import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelMemoryGrid extends LevelWidget {
  const LevelMemoryGrid({super.key, required super.onComplete});

  @override
  State<LevelMemoryGrid> createState() => _LevelMemoryGridState();
}

class _LevelMemoryGridState extends State<LevelMemoryGrid> {
  static const int _gridSize = 5;

  final _rng = Random();

  int _round = 1;
  int _cellsToRemember = 3;
  Set<int> _targetCells = {};
  Set<int> _selectedCells = {};
  bool _showingPattern = true;
  bool _done = false;
  int _totalCorrectCells = 0;

  Timer? _hideTimer;

  // Feedback state
  bool _showingFeedback = false;
  bool _lastRoundCorrect = false;

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _startRound() {
    final allIndices = List.generate(_gridSize * _gridSize, (i) => i);
    allIndices.shuffle(_rng);
    _targetCells = allIndices.take(_cellsToRemember).toSet();
    _selectedCells.clear();
    _showingPattern = true;
    _showingFeedback = false;

    setState(() {});

    _hideTimer?.cancel();
    _hideTimer = Timer(Duration(milliseconds: 1500 + (_round * 200)), () {
      if (mounted) {
        setState(() => _showingPattern = false);
      }
    });
  }

  void _toggleCell(int index) {
    if (_showingPattern || _done || _showingFeedback) return;

    setState(() {
      if (_selectedCells.contains(index)) {
        _selectedCells.remove(index);
      } else {
        _selectedCells.add(index);
        HapticFeedback.selectionClick();
      }
    });
  }

  void _confirmSelection() {
    if (_showingPattern || _done || _showingFeedback) return;

    final correct =
        _selectedCells.where((c) => _targetCells.contains(c)).length;
    final incorrect =
        _selectedCells.where((c) => !_targetCells.contains(c)).length;
    final perfect = correct == _targetCells.length && incorrect == 0;

    _totalCorrectCells += correct;

    setState(() {
      _showingFeedback = true;
      _lastRoundCorrect = perfect;
    });

    if (perfect) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.heavyImpact();
    }

    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (perfect) {
        setState(() {
          _round++;
          _cellsToRemember = min(_cellsToRemember + 1, _gridSize * _gridSize - 2);
        });
        _startRound();
      } else {
        _finish();
      }
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;

    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onComplete(LevelOutcome(score: 1, metrics: {
        'rounds': _round - 1,
        'max_cells': _cellsToRemember - 1,
        'correct_cells': _totalCorrectCells,
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildPhaseIndicator(),
            const SizedBox(height: 16),
            Expanded(child: Center(child: _buildGrid())),
            const SizedBox(height: 16),
            if (!_showingPattern && !_done && !_showingFeedback)
              _buildConfirmButton(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('round',
                style: TextStyle(
                    color: NunuColors.textSecondary, fontSize: 12)),
            Text(
              '$_round',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: NunuColors.primaryMain,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('cells to find',
                style: TextStyle(
                    color: NunuColors.textSecondary, fontSize: 12)),
            Text(
              '$_cellsToRemember',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: NunuColors.secondaryMain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPhaseIndicator() {
    String text;
    Color color;
    if (_showingFeedback) {
      text = _lastRoundCorrect ? 'correct!' : 'wrong...';
      color = _lastRoundCorrect ? NunuColors.successMain : NunuColors.errorMain;
    } else if (_showingPattern) {
      text = 'memorize the pattern';
      color = NunuColors.warningMain;
    } else {
      text = 'tap the cells you remember (${_selectedCells.length} / $_cellsToRemember)';
      color = NunuColors.primaryLight;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Text(
        text,
        key: ValueKey(text),
        style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
              (constraints.maxWidth - 20) / _gridSize,
              (constraints.maxHeight - 20) / _gridSize,
            ) -
            4;

        return SizedBox(
          width: (cellSize + 4) * _gridSize,
          height: (cellSize + 4) * _gridSize,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: _gridSize * _gridSize,
            itemBuilder: (_, i) {
              final isTarget = _targetCells.contains(i);
              final isSelected = _selectedCells.contains(i);

              Color bg;
              Border? border;

              if (_showingFeedback) {
                if (isTarget && isSelected) {
                  bg = NunuColors.successMain;
                } else if (isTarget && !isSelected) {
                  bg = NunuColors.warningMain.withOpacity(0.6);
                } else if (!isTarget && isSelected) {
                  bg = NunuColors.errorMain.withOpacity(0.7);
                } else {
                  bg = NunuColors.backgroundPaper;
                }
              } else if (_showingPattern) {
                bg = isTarget
                    ? NunuColors.primaryMain
                    : NunuColors.backgroundPaper;
              } else {
                bg = isSelected
                    ? NunuColors.secondaryMain
                    : NunuColors.backgroundPaper;
                border = isSelected
                    ? Border.all(color: NunuColors.secondaryLight, width: 2)
                    : null;
              }

              return GestureDetector(
                onTap: () => _toggleCell(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(8),
                    border: border ??
                        Border.all(
                          color: NunuColors.primaryDark.withOpacity(0.2),
                        ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: _selectedCells.length == _cellsToRemember
            ? _confirmSelection
            : null,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: NunuColors.primaryMain,
          disabledBackgroundColor: NunuColors.backgroundPaper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(
          _selectedCells.length == _cellsToRemember
              ? 'CONFIRM'
              : 'SELECT $_cellsToRemember CELLS',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    );
  }
}
