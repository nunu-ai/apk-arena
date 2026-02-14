import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelMinesweeper extends LevelWidget {
  const LevelMinesweeper({super.key, required super.onComplete});

  @override
  State<LevelMinesweeper> createState() => _LevelMinesweeperState();
}

class _LevelMinesweeperState extends State<LevelMinesweeper> {
  static const int _rows = 9;
  static const int _cols = 9;
  static const int _mines = 12;

  late List<List<int>> _board; // -1 = mine, 0-8 = adjacent count
  late List<List<bool>> _revealed;
  late List<List<bool>> _flagged;
  bool _gameOver = false;
  bool _firstTap = true;
  int _flagCount = 0;
  int _revealedCount = 0;
  final int _safeCount = _rows * _cols - _mines;

  @override
  void initState() {
    super.initState();
    _board = List.generate(_rows, (_) => List.filled(_cols, 0));
    _revealed = List.generate(_rows, (_) => List.filled(_cols, false));
    _flagged = List.generate(_rows, (_) => List.filled(_cols, false));
  }

  void _placeMines(int safeRow, int safeCol) {
    final rng = Random();
    int placed = 0;
    while (placed < _mines) {
      final r = rng.nextInt(_rows);
      final c = rng.nextInt(_cols);
      // Don't place on first tap or adjacent to it
      if ((r - safeRow).abs() <= 1 && (c - safeCol).abs() <= 1) continue;
      if (_board[r][c] == -1) continue;
      _board[r][c] = -1;
      placed++;
    }
    // Calculate adjacent counts
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_board[r][c] == -1) continue;
        int count = 0;
        for (int dr = -1; dr <= 1; dr++) {
          for (int dc = -1; dc <= 1; dc++) {
            final nr = r + dr, nc = c + dc;
            if (nr >= 0 && nr < _rows && nc >= 0 && nc < _cols && _board[nr][nc] == -1) {
              count++;
            }
          }
        }
        _board[r][c] = count;
      }
    }
  }

  void _reveal(int r, int c) {
    if (r < 0 || r >= _rows || c < 0 || c >= _cols) return;
    if (_revealed[r][c] || _flagged[r][c]) return;

    _revealed[r][c] = true;
    _revealedCount++;

    if (_board[r][c] == 0) {
      // Flood fill for empty cells
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          if (dr == 0 && dc == 0) continue;
          _reveal(r + dr, c + dc);
        }
      }
    }
  }

  void _onTap(int r, int c) {
    if (_gameOver || _revealed[r][c] || _flagged[r][c]) return;

    if (_firstTap) {
      _firstTap = false;
      _placeMines(r, c);
    }

    setState(() {
      if (_board[r][c] == -1) {
        // Hit a mine!
        _gameOver = true;
        // Reveal all mines
        for (int rr = 0; rr < _rows; rr++) {
          for (int cc = 0; cc < _cols; cc++) {
            if (_board[rr][cc] == -1) _revealed[rr][cc] = true;
          }
        }
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 800), () {
          widget.onComplete(false, metrics: {
            'revealedCount': _revealedCount,
            'flagCount': _flagCount,
            'safeCount': _safeCount,
          });
        });
      } else {
        _reveal(r, c);
        HapticFeedback.lightImpact();
        if (_revealedCount >= _safeCount) {
          _gameOver = true;
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onComplete(true, metrics: {
              'revealedCount': _revealedCount,
              'flagCount': _flagCount,
              'safeCount': _safeCount,
            });
          });
        }
      }
    });
  }

  void _onLongPress(int r, int c) {
    if (_gameOver || _revealed[r][c]) return;
    setState(() {
      _flagged[r][c] = !_flagged[r][c];
      _flagCount += _flagged[r][c] ? 1 : -1;
    });
    HapticFeedback.selectionClick();
  }

  Color _numberColor(int n) {
    switch (n) {
      case 1: return const Color(0xFF4FC3F7);
      case 2: return NunuColors.successMain;
      case 3: return NunuColors.errorMain;
      case 4: return NunuColors.secondaryMain;
      case 5: return NunuColors.warningMain;
      case 6: return NunuColors.infoMain;
      case 7: return NunuColors.primaryMain;
      default: return Colors.white;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            Expanded(child: Center(child: _buildGrid())),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Text('💣', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                '${_mines - _flagCount}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.errorMain,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5)),
            ),
            child: Text(
              '${_revealedCount} / $_safeCount',
              style: const TextStyle(
                fontSize: 14,
                color: NunuColors.textSecondary,
              ),
            ),
          ),
          Row(
            children: [
              const Text('🚩', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 4),
              const Text(
                'long press',
                style: TextStyle(fontSize: 11, color: NunuColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          (constraints.maxWidth - 32) / _cols,
          (constraints.maxHeight - 16) / _rows,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: NunuColors.primaryDark.withOpacity(0.6), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: cellSize * _cols,
              height: cellSize * _rows,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _cols,
                ),
                itemCount: _rows * _cols,
                itemBuilder: (_, i) {
                  final r = i ~/ _cols, c = i % _cols;
                  return _buildCell(r, c, cellSize);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final revealed = _revealed[r][c];
    final flagged = _flagged[r][c];
    final val = _board[r][c];

    return GestureDetector(
      onTap: () => _onTap(r, c),
      onLongPress: () => _onLongPress(r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: revealed
              ? (val == -1
                  ? NunuColors.errorMain.withOpacity(0.3)
                  : NunuColors.backgroundPaper.withOpacity(0.5))
              : NunuColors.primaryDark.withOpacity(0.25),
          border: Border.all(
            color: revealed
                ? Colors.white.withOpacity(0.05)
                : NunuColors.primaryDark.withOpacity(0.4),
            width: 0.5,
          ),
        ),
        child: Center(
          child: revealed
              ? (val == -1
                  ? const Text('💣', style: TextStyle(fontSize: 18))
                  : val > 0
                      ? Text(
                          '$val',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _numberColor(val),
                          ),
                        )
                      : null)
              : flagged
                  ? const Text('🚩', style: TextStyle(fontSize: 16))
                  : null,
        ),
      ),
    );
  }
}
