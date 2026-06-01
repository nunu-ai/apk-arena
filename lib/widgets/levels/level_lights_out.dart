import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelLightsOut extends LevelWidget {
  const LevelLightsOut({super.key, required super.onComplete});

  @override
  State<LevelLightsOut> createState() => _LevelLightsOutState();
}

class _LevelLightsOutState extends State<LevelLightsOut> {
  static const int _size = 5;
  final _rng = Random(42);
  late List<List<bool>> _grid; // true = lit
  int _moves = 0;
  int _litCount = 0;
  int _optimalMoves = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
    _optimalMoves = _solveOptimalCells(_grid, _size).length;
  }

  void _generatePuzzle() {
    _grid = List.generate(_size, (_) => List.filled(_size, false));
    final taps = 6 + _rng.nextInt(5); // 6-10 random taps
    for (int i = 0; i < taps; i++) {
      final r = _rng.nextInt(_size);
      final c = _rng.nextInt(_size);
      _toggle(r, c, countMove: false);
    }
    _litCount = 0;
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_grid[r][c]) _litCount++;
      }
    }
    if (_litCount < 5) {
      _generatePuzzle(); // retry with advanced RNG state
    }
  }

  /// Gaussian elimination over GF(2) — returns the cell indices to tap
  /// in the minimum-move solution (row-major order).
  static List<int> _solveOptimalCells(List<List<bool>> grid, int size) {
    final n = size * size;

    final aug = List.generate(n, (_) => List.filled(n + 1, 0));
    for (int j = 0; j < n; j++) {
      final jr = j ~/ size, jc = j % size;
      for (final d in [
        [0, 0],
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ]) {
        final nr = jr + d[0], nc = jc + d[1];
        if (nr >= 0 && nr < size && nc >= 0 && nc < size) {
          aug[nr * size + nc][j] = 1;
        }
      }
    }
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        aug[r * size + c][n] = grid[r][c] ? 1 : 0;
      }
    }

    final pivotCol = List.filled(n, -1);
    int rank = 0;
    for (int col = 0; col < n && rank < n; col++) {
      int pivotRow = -1;
      for (int row = rank; row < n; row++) {
        if (aug[row][col] == 1) {
          pivotRow = row;
          break;
        }
      }
      if (pivotRow == -1) continue;
      final tmp = aug[rank];
      aug[rank] = aug[pivotRow];
      aug[pivotRow] = tmp;
      pivotCol[rank] = col;
      for (int row = 0; row < n; row++) {
        if (row != rank && aug[row][col] == 1) {
          for (int k = 0; k <= n; k++) aug[row][k] ^= aug[rank][k];
        }
      }
      rank++;
    }

    final x = List.filled(n, 0);
    for (int i = 0; i < rank; i++) {
      if (pivotCol[i] != -1) x[pivotCol[i]] = aug[i][n];
    }

    final pivotCols = {for (int i = 0; i < rank; i++) pivotCol[i]};
    final freeVars = [
      for (int c = 0; c < n; c++)
        if (!pivotCols.contains(c)) c,
    ];
    final nullBasis = <List<int>>[];
    for (final fv in freeVars) {
      final nv = List.filled(n, 0);
      nv[fv] = 1;
      for (int i = 0; i < rank; i++) {
        if (pivotCol[i] != -1 && aug[i][fv] == 1) nv[pivotCol[i]] = 1;
      }
      nullBasis.add(nv);
    }

    final nullity = nullBasis.length;
    List<int> bestCandidate = x;
    int bestWeight = n + 1;
    for (int mask = 0; mask < (1 << nullity); mask++) {
      final candidate = List.of(x);
      for (int k = 0; k < nullity; k++) {
        if (mask & (1 << k) != 0) {
          for (int i = 0; i < n; i++) candidate[i] ^= nullBasis[k][i];
        }
      }
      final weight = candidate.where((v) => v == 1).length;
      if (weight < bestWeight) {
        bestWeight = weight;
        bestCandidate = candidate;
      }
    }
    return [
      for (int i = 0; i < n; i++)
        if (bestCandidate[i] == 1) i,
    ];
  }

  void _toggle(int r, int c, {bool countMove = true}) {
    // Toggle center + adjacent
    final targets = [
      [r, c],
      [r - 1, c],
      [r + 1, c],
      [r, c - 1],
      [r, c + 1],
    ];
    for (final t in targets) {
      if (t[0] >= 0 && t[0] < _size && t[1] >= 0 && t[1] < _size) {
        _grid[t[0]][t[1]] = !_grid[t[0]][t[1]];
      }
    }
    if (countMove) _moves++;
  }

  void _onTap(int r, int c) {
    if (_done) return;
    setState(() {
      _toggle(r, c);
      _litCount = 0;
      for (int rr = 0; rr < _size; rr++) {
        for (int cc = 0; cc < _size; cc++) {
          if (_grid[rr][cc]) _litCount++;
        }
      }
      HapticFeedback.lightImpact();

      if (_litCount == 0) {
        _done = true;
        HapticFeedback.mediumImpact();
        final score = _moves <= _optimalMoves
            ? 1.0
            : (_optimalMoves / _moves).clamp(0.0, 1.0);
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onComplete(
            LevelOutcome(
              score: score,
              metrics: {'moves': _moves, 'optimal_moves': _optimalMoves},
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF050510),
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(
              trailing: Text(
                'moves $_moves',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              infoTitle: 'blackout',
              infoItems: const [
                LevelHudBullet('💡', 'tap a light to toggle it and its four orthogonal neighbors'),
                LevelHudBullet('🎯', 'turn off every light to clear the board'),
                LevelHudBullet('⭐', 'fewer moves = better score'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'lights remaining $_litCount',
                style: TextStyle(
                  color: _litCount == 0
                      ? NunuColors.successMain
                      : NunuColors.warningMain,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Expanded(child: Center(child: _buildGrid())),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          (constraints.maxWidth - 48) / _size,
          (constraints.maxHeight - 16) / _size,
        );

        return SizedBox(
          width: cellSize * _size + 16,
          height: cellSize * _size + 16,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _size,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
            ),
            itemCount: _size * _size,
            itemBuilder: (_, i) {
              final r = i ~/ _size, c = i % _size;
              return _buildCell(r, c, cellSize);
            },
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final lit = _grid[r][c];

    return GestureDetector(
      onTap: () => _onTap(r, c),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: lit ? NunuColors.warningMain : const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: lit
                ? NunuColors.warningLight.withOpacity(0.6)
                : NunuColors.primaryDark.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: lit
              ? [
                  BoxShadow(
                    color: NunuColors.warningMain.withOpacity(0.6),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Icon(
            lit ? Icons.lightbulb : Icons.lightbulb_outline,
            color: lit ? Colors.white : Colors.white.withOpacity(0.2),
            size: size * 0.35,
          ),
        ),
      ),
    );
  }
}
