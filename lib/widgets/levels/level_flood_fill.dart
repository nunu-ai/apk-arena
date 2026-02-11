import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelFloodFill extends LevelWidget {
  const LevelFloodFill({super.key, required super.onComplete});

  @override
  State<LevelFloodFill> createState() => _LevelFloodFillState();
}

class _LevelFloodFillState extends State<LevelFloodFill> {
  static const int _size = 10;
  static const int _maxMoves = 22;
  static const int _numColors = 6;

  static const List<Color> _palette = [
    Color(0xFFFF5630), // red
    Color(0xFF22C55E), // green
    Color(0xFF4FC3F7), // blue
    Color(0xFFFFAB00), // yellow
    Color(0xFFE55CD8), // pink
    Color(0xFF805CE5), // purple
  ];

  late List<List<int>> _grid;
  int _moves = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _generateBoard();
  }

  void _generateBoard() {
    final rng = Random();
    _grid = List.generate(
      _size,
      (_) => List.generate(_size, (_) => rng.nextInt(_numColors)),
    );
  }

  void _flood(int targetColor) {
    if (_done) return;
    final currentColor = _grid[0][0];
    if (targetColor == currentColor) return;

    setState(() {
      _moves++;
      _doFlood(0, 0, currentColor, targetColor);
      HapticFeedback.lightImpact();

      // Check if all same color
      final first = _grid[0][0];
      bool allSame = true;
      for (int r = 0; r < _size && allSame; r++) {
        for (int c = 0; c < _size && allSame; c++) {
          if (_grid[r][c] != first) allSame = false;
        }
      }

      if (allSame) {
        _done = true;
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete(true, metrics: {'moves': _moves, 'maxMoves': _maxMoves});
        });
      } else if (_moves >= _maxMoves) {
        _done = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete(false, metrics: {'moves': _moves, 'maxMoves': _maxMoves});
        });
      }
    });
  }

  void _doFlood(int r, int c, int oldColor, int newColor) {
    if (r < 0 || r >= _size || c < 0 || c >= _size) return;
    if (_grid[r][c] != oldColor) return;
    _grid[r][c] = newColor;
    _doFlood(r - 1, c, oldColor, newColor);
    _doFlood(r + 1, c, oldColor, newColor);
    _doFlood(r, c - 1, oldColor, newColor);
    _doFlood(r, c + 1, oldColor, newColor);
  }

  int _countConnected() {
    final color = _grid[0][0];
    final visited = List.generate(_size, (_) => List.filled(_size, false));
    int count = 0;
    void bfs(int r, int c) {
      if (r < 0 || r >= _size || c < 0 || c >= _size) return;
      if (visited[r][c] || _grid[r][c] != color) return;
      visited[r][c] = true;
      count++;
      bfs(r - 1, c);
      bfs(r + 1, c);
      bfs(r, c - 1);
      bfs(r, c + 1);
    }
    bfs(0, 0);
    return count;
  }

  @override
  Widget build(BuildContext context) {
    final pct = _countConnected() / (_size * _size);

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 4),
            _buildProgress(pct),
            const SizedBox(height: 16),
            Expanded(child: Center(child: _buildGrid())),
            const SizedBox(height: 12),
            _buildColorPicker(),
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
                '$_moves / $_maxMoves',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _moves > _maxMoves - 5
                      ? NunuColors.errorMain
                      : Colors.white,
                ),
              ),
            ],
          ),
          const Text(
            'flood from top-left',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(double pct) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(color: NunuColors.backgroundPaper),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [NunuColors.primaryMain, NunuColors.successMain],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          (constraints.maxWidth - 32) / _size,
          (constraints.maxHeight - 16) / _size,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: NunuColors.primaryDark.withOpacity(0.4),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              width: cellSize * _size,
              height: cellSize * _size,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _size,
                ),
                itemCount: _size * _size,
                itemBuilder: (_, i) {
                  final r = i ~/ _size, c = i % _size;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: _palette[_grid[r][c]],
                      border: Border.all(
                        color: Colors.black.withOpacity(0.15),
                        width: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorPicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_numColors, (i) {
        final isCurrentColor = _grid[0][0] == i;
        return GestureDetector(
          onTap: isCurrentColor ? null : () => _flood(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 6),
            width: isCurrentColor ? 44 : 50,
            height: isCurrentColor ? 44 : 50,
            decoration: BoxDecoration(
              color: _palette[i],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrentColor ? Colors.white.withOpacity(0.3) : Colors.white,
                width: isCurrentColor ? 1 : 3,
              ),
              boxShadow: isCurrentColor
                  ? null
                  : [
                      BoxShadow(
                        color: _palette[i].withOpacity(0.5),
                        blurRadius: 8,
                      ),
                    ],
            ),
            child: isCurrentColor
                ? Center(
                    child: Icon(
                      Icons.check,
                      color: Colors.white.withOpacity(0.5),
                      size: 20,
                    ),
                  )
                : null,
          ),
        );
      }),
    );
  }
}
