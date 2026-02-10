import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelLightsOut extends LevelWidget {
  const LevelLightsOut({super.key, required super.onComplete});

  @override
  State<LevelLightsOut> createState() => _LevelLightsOutState();
}

class _LevelLightsOutState extends State<LevelLightsOut> {
  static const int _size = 5;
  late List<List<bool>> _grid; // true = lit
  int _moves = 0;
  int _litCount = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  void _generatePuzzle() {
    _grid = List.generate(_size, (_) => List.filled(_size, false));
    final rng = Random();
    // Make a solvable puzzle by applying random toggles
    final taps = 6 + rng.nextInt(5); // 6-10 random taps
    for (int i = 0; i < taps; i++) {
      final r = rng.nextInt(_size);
      final c = rng.nextInt(_size);
      _toggle(r, c, countMove: false);
    }
    // Ensure at least some lights are on
    _litCount = 0;
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_grid[r][c]) _litCount++;
      }
    }
    if (_litCount < 5) {
      _generatePuzzle(); // retry
    }
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
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onComplete(true);
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
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(child: Center(child: _buildGrid())),
            _buildHint(),
            const SizedBox(height: 24),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'lights remaining',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_litCount',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _litCount == 0 ? NunuColors.successMain : NunuColors.warningMain,
                ),
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

  Widget _buildHint() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'tapping a light toggles it and its neighbors',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: NunuColors.textSecondary,
        ),
      ),
    );
  }
}
