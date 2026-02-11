import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelNonogram extends LevelWidget {
  const LevelNonogram({super.key, required super.onComplete});

  @override
  State<LevelNonogram> createState() => _LevelNonogramState();
}

class _LevelNonogramState extends State<LevelNonogram> {
  static const int _size = 7;

  late List<List<bool>> _solution;
  late List<List<int>> _state; // 0=empty, 1=filled, 2=crossed
  late List<List<int>> _rowClues;
  late List<List<int>> _colClues;
  bool _done = false;
  int _moves = 0;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  void _generatePuzzle() {
    final rng = Random();
    // Generate a random solution with ~45% fill rate
    _solution = List.generate(
      _size,
      (_) => List.generate(_size, (_) => rng.nextDouble() < 0.45),
    );

    // Ensure at least one cell per row and column
    for (int r = 0; r < _size; r++) {
      if (!_solution[r].contains(true)) {
        _solution[r][rng.nextInt(_size)] = true;
      }
    }
    for (int c = 0; c < _size; c++) {
      bool hasOne = false;
      for (int r = 0; r < _size; r++) {
        if (_solution[r][c]) hasOne = true;
      }
      if (!hasOne) _solution[rng.nextInt(_size)][c] = true;
    }

    _state = List.generate(_size, (_) => List.filled(_size, 0));

    // Generate clues
    _rowClues = List.generate(_size, (r) => _computeClues(_solution[r]));
    _colClues = List.generate(_size, (c) {
      final col = List.generate(_size, (r) => _solution[r][c]);
      return _computeClues(col);
    });
  }

  List<int> _computeClues(List<bool> line) {
    final clues = <int>[];
    int count = 0;
    for (final cell in line) {
      if (cell) {
        count++;
      } else if (count > 0) {
        clues.add(count);
        count = 0;
      }
    }
    if (count > 0) clues.add(count);
    if (clues.isEmpty) clues.add(0);
    return clues;
  }

  void _onCellTap(int r, int c) {
    if (_done) return;
    setState(() {
      // Cycle: empty -> filled -> crossed -> empty
      _state[r][c] = (_state[r][c] + 1) % 3;
      _moves++;
      HapticFeedback.selectionClick();

      // Check solution
      bool correct = true;
      for (int rr = 0; rr < _size && correct; rr++) {
        for (int cc = 0; cc < _size && correct; cc++) {
          final filled = _state[rr][cc] == 1;
          if (filled != _solution[rr][cc]) correct = false;
        }
      }

      if (correct) {
        _done = true;
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete(true, metrics: {'moves': _moves});
        });
      }
    });
  }

  void _showRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'how to play',
          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'fill the grid so each row and column matches its clues.',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'clues tell you the lengths of consecutive filled groups in that row or column.',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'example: "2 1" means there is a group of 2 filled cells, then a gap of one or more empty cells, then 1 filled cell.',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'tap a cell to cycle: empty → filled → crossed → empty.',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 14, height: 1.5),
            ),
            SizedBox(height: 12),
            Text(
              'clues turn green when a row or column is correctly solved.',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 14, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('got it', style: TextStyle(color: NunuColors.primaryMain)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: Center(child: _buildPuzzle())),
            _buildLegend(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'moves',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_moves',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          GestureDetector(
            onTap: _showRules,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline, color: NunuColors.primaryMain, size: 18),
                  SizedBox(width: 4),
                  Text('rules', style: TextStyle(color: NunuColors.primaryMain, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPuzzle() {
    // Calculate the maximum number of clues for sizing
    final maxColClues = _colClues.map((c) => c.length).reduce(max);
    final maxRowClues = _rowClues.map((c) => c.length).reduce(max);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic clue area sizes based on actual clue counts
        final clueTextHeight = 16.0;
        final maxClueHeight = (maxColClues * clueTextHeight).clamp(30.0, constraints.maxHeight * 0.25);
        final maxClueWidth = (maxRowClues * 18.0).clamp(30.0, constraints.maxWidth * 0.22);
        final availableW = constraints.maxWidth - maxClueWidth - 12;
        final availableH = constraints.maxHeight - maxClueHeight - 12;
        final cellSize = min(availableW / _size, availableH / _size).clamp(1.0, 50.0);

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Column clues row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(width: maxClueWidth, height: maxClueHeight),
                  ...List.generate(_size, (c) {
                    return SizedBox(
                      width: cellSize,
                      height: maxClueHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: _colClues[c]
                            .map((n) => SizedBox(
                                  height: clueTextHeight,
                                  child: Center(
                                    child: Text(
                                      '$n',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: _isColSatisfied(c)
                                            ? NunuColors.successMain
                                            : Colors.white,
                                      ),
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    );
                  }),
                ],
              ),
              // Rows with clues + cells
              ...List.generate(_size, (r) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: maxClueWidth,
                      height: cellSize,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: _rowClues[r]
                            .map((n) => Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 2),
                                  child: Text(
                                    '$n',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: _isRowSatisfied(r)
                                          ? NunuColors.successMain
                                          : Colors.white,
                                    ),
                                  ),
                                ))
                            .toList(),
                      ),
                    ),
                    ...List.generate(_size, (c) {
                      return GestureDetector(
                        onTap: () => _onCellTap(r, c),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: cellSize,
                          height: cellSize,
                          decoration: BoxDecoration(
                            color: _state[r][c] == 1
                                ? NunuColors.primaryMain
                                : NunuColors.backgroundPaper.withOpacity(0.4),
                            border: Border.all(
                              color: NunuColors.primaryDark.withOpacity(0.4),
                              width: 0.5,
                            ),
                          ),
                          child: _state[r][c] == 2
                              ? Center(
                                  child: Icon(
                                    Icons.close,
                                    color: NunuColors.errorMain.withOpacity(0.6),
                                    size: cellSize * 0.5,
                                  ),
                                )
                              : null,
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  bool _isRowSatisfied(int r) {
    final filled = List.generate(_size, (c) => _state[r][c] == 1);
    return _computeClues(filled).join(',') == _rowClues[r].join(',');
  }

  bool _isColSatisfied(int c) {
    final filled = List.generate(_size, (r) => _state[r][c] == 1);
    return _computeClues(filled).join(',') == _colClues[c].join(',');
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _legendItem(NunuColors.backgroundPaper.withOpacity(0.4), 'empty'),
          const SizedBox(width: 16),
          _legendItem(NunuColors.primaryMain, 'filled'),
          const SizedBox(width: 16),
          Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: NunuColors.backgroundPaper.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: const Icon(Icons.close, color: NunuColors.errorMain, size: 14),
              ),
              const SizedBox(width: 4),
              const Text('crossed', style: TextStyle(color: NunuColors.textSecondary, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: NunuColors.textSecondary, fontSize: 11)),
      ],
    );
  }
}
