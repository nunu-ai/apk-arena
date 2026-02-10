import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSlidingPuzzle extends LevelWidget {
  const LevelSlidingPuzzle({super.key, required super.onComplete});

  @override
  State<LevelSlidingPuzzle> createState() => _LevelSlidingPuzzleState();
}

class _LevelSlidingPuzzleState extends State<LevelSlidingPuzzle> {
  static const int _size = 4;
  late List<int> _tiles; // 0 = empty, 1-15 = numbered tiles
  int _moves = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _shuffle();
  }

  void _shuffle() {
    // Start solved then do random valid moves to ensure solvability
    _tiles = List.generate(_size * _size, (i) => (i + 1) % (_size * _size));
    final rng = Random();
    int emptyIdx = _size * _size - 1;

    for (int i = 0; i < 200; i++) {
      final neighbors = _getNeighbors(emptyIdx);
      final pick = neighbors[rng.nextInt(neighbors.length)];
      _tiles[emptyIdx] = _tiles[pick];
      _tiles[pick] = 0;
      emptyIdx = pick;
    }
  }

  List<int> _getNeighbors(int idx) {
    final r = idx ~/ _size, c = idx % _size;
    final result = <int>[];
    if (r > 0) result.add((r - 1) * _size + c);
    if (r < _size - 1) result.add((r + 1) * _size + c);
    if (c > 0) result.add(r * _size + c - 1);
    if (c < _size - 1) result.add(r * _size + c + 1);
    return result;
  }

  void _onTileTap(int idx) {
    if (_done || _tiles[idx] == 0) return;

    final emptyIdx = _tiles.indexOf(0);
    final neighbors = _getNeighbors(emptyIdx);

    if (neighbors.contains(idx)) {
      setState(() {
        _tiles[emptyIdx] = _tiles[idx];
        _tiles[idx] = 0;
        _moves++;
        HapticFeedback.lightImpact();

        if (_isSolved()) {
          _done = true;
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onComplete(true);
          });
        }
      });
    }
  }

  bool _isSolved() {
    for (int i = 0; i < _size * _size - 1; i++) {
      if (_tiles[i] != i + 1) return false;
    }
    return _tiles[_size * _size - 1] == 0;
  }

  Color _tileColor(int value) {
    if (value == 0) return Colors.transparent;
    final hue = (value - 1) * 24.0; // spread across hue wheel
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.45).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(child: Center(child: _buildGrid())),
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            children: [
              const Text(
                'moves',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_moves',
                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
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
        final gridSize = min(constraints.maxWidth - 32, constraints.maxHeight - 16);
        final cellSize = gridSize / _size;

        return SizedBox(
          width: gridSize,
          height: gridSize,
          child: Stack(
            children: List.generate(_size * _size, (i) {
              final value = _tiles[i];
              if (value == 0) return const SizedBox.shrink();

              final r = i ~/ _size, c = i % _size;
              return AnimatedPositioned(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                left: c * cellSize,
                top: r * cellSize,
                child: GestureDetector(
                  onTap: () => _onTileTap(i),
                  child: Container(
                    width: cellSize - 4,
                    height: cellSize - 4,
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: _tileColor(value),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _tileColor(value).withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '$value',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
