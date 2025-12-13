import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';

enum WarpCellType { wall, path, start, end }

class LevelWarpMaze extends LevelWidget {
  const LevelWarpMaze({super.key, required super.onComplete});

  @override
  State<LevelWarpMaze> createState() => _LevelWarpMazeState();
}

class _LevelWarpMazeState extends State<LevelWarpMaze> {
  static const List<String> _layout = [
    "###############",
    "#S..#D....#G#B#",
    "###.###.#.#.#.#",
    "#.......#.#...#",
    "#.##.##.#.#.#.#",
    "#.H#.C#F#D#B#A#",
    "###############",
    "#...#I#.......#",
    "#.#.#.#.#.###.#",
    "#H#.....#.F#I.#",
    "###.#.#########",
    "#...#.#J....#A#",
    "#.###.###.###.#",
    "#..C#..J#..G#E#",
    "###############",
  ];

  static const Color _warpColor = Color(0xFF7C4DFF);

  late final int _mazeWidth = _layout.first.length;
  late final int _mazeHeight = _layout.length;

  late List<List<WarpCellType>> _maze;
  late int _playerX;
  late int _playerY;
  late int _goalX;
  late int _goalY;

  int _moveCount = 0;
  bool _justWarped = false;
  String? _lastWarpUsed;

  final Map<Point<int>, String> _warpLookup = {};
  final Map<String, List<Point<int>>> _warpRoutes = {};

  @override
  void initState() {
    super.initState();
    _buildMaze();
  }

  void _buildMaze() {
    _maze = List.generate(
      _mazeHeight,
      (y) => List.generate(_mazeWidth, (x) => WarpCellType.wall),
    );

    for (int y = 0; y < _layout.length; y++) {
      final row = _layout[y];
      for (int x = 0; x < row.length; x++) {
        final char = row[x];
        switch (char) {
          case '#':
            _maze[y][x] = WarpCellType.wall;
            break;
          case '.':
            _maze[y][x] = WarpCellType.path;
            break;
          case 'S':
            _maze[y][x] = WarpCellType.start;
            _playerX = x;
            _playerY = y;
            break;
          case 'E':
            _maze[y][x] = WarpCellType.end;
            _goalX = x;
            _goalY = y;
            break;
          default:
            // Treat any uppercase letter as a warp gate.
            if (RegExp(r'[A-Z]').hasMatch(char)) {
              _maze[y][x] = WarpCellType.path;
              final id = char;
              final point = Point<int>(x, y);
              _warpLookup[point] = id;
              _warpRoutes.putIfAbsent(id, () => []).add(point);
            } else {
              _maze[y][x] = WarpCellType.wall;
            }
        }
      }
    }
  }

  void _attemptMove(int dx, int dy) {
    _justWarped = false;
    _lastWarpUsed = null;
    final newX = _playerX + dx;
    final newY = _playerY + dy;

    if (!_inBounds(newX, newY)) return;
    if (_maze[newY][newX] == WarpCellType.wall) return;

    setState(() {
      _playerX = newX;
      _playerY = newY;
      _moveCount++;
    });

    _handleWarp();
    _checkWin();
  }

  bool _inBounds(int x, int y) {
    return x >= 0 && x < _mazeWidth && y >= 0 && y < _mazeHeight;
  }

  void _handleWarp() {
    final warpId = _warpLookup[Point<int>(_playerX, _playerY)];
    if (warpId == null || _justWarped) {
      _justWarped = false;
      return;
    }

    final route = _warpRoutes[warpId];
    if (route == null || route.length < 2) return;

    final currentIndex = route.indexWhere(
      (p) => p.x == _playerX && p.y == _playerY,
    );
    if (currentIndex == -1) return;

    final nextPoint = route[(currentIndex + 1) % route.length];
    setState(() {
      _playerX = nextPoint.x;
      _playerY = nextPoint.y;
      _justWarped = true;
      _lastWarpUsed = warpId;
    });
  }

  void _checkWin() {
    if (_playerX == _goalX && _playerY == _goalY) {
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0D0D1A),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableSize = min(
                      constraints.maxWidth - 16,
                      constraints.maxHeight - 100,
                    );
                    final cellSize =
                        availableSize / max(_mazeWidth, _mazeHeight);

                    return Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF2A2A4A),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF7C4DFF,
                            ).withValues(alpha: 0.15),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (int y = 0; y < _mazeHeight; y++)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int x = 0; x < _mazeWidth; x++)
                                    _buildCell(x, y, cellSize),
                                ],
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildDPad(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Move counter
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A4A)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.swap_calls_rounded,
                  color: Color(0xFF7C4DFF),
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  '$_moveCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Warp indicator
          if (_lastWarpUsed != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: _warpColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _warpColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.blur_on_rounded, color: _warpColor, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    "warped!",
                    style: TextStyle(
                      color: _warpColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCell(int x, int y, double cellSize) {
    final cellType = _maze[y][x];
    final warpId = _warpLookup[Point<int>(x, y)];
    final isPlayer = x == _playerX && y == _playerY;
    final isGoal = x == _goalX && y == _goalY;

    Color baseColor = const Color(0xFF0D0D1A);
    Widget? content;

    switch (cellType) {
      case WarpCellType.wall:
        baseColor = const Color(0xFF1A1A2E);
        content = Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            border: Border.all(
              color: const Color(0xFF2A2A4A).withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
        );
        break;
      case WarpCellType.start:
      case WarpCellType.path:
      case WarpCellType.end:
        baseColor = const Color(0xFF0D0D1A);
        break;
    }

    // Warp gate visualization
    if (warpId != null && !isPlayer) {
      content = Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              _warpColor.withValues(alpha: 0.4),
              _warpColor.withValues(alpha: 0.1),
              Colors.transparent,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Center(
          child: Container(
            width: cellSize * 0.6,
            height: cellSize * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _warpColor, width: 2),
              boxShadow: [
                BoxShadow(
                  color: _warpColor.withValues(alpha: 0.6),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.blur_circular_rounded,
                color: _warpColor,
                size: cellSize * 0.35,
              ),
            ),
          ),
        ),
      );
    }

    // Goal visualization
    if (isGoal && !isPlayer) {
      content = Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFF00FF88).withValues(alpha: 0.3),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Text("🚪", style: TextStyle(fontSize: cellSize * 0.5)),
        ),
      );
    }

    // Player visualization
    if (isPlayer) {
      content = Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFF00D9FF).withValues(alpha: 0.4),
              Colors.transparent,
            ],
          ),
        ),
        child: Center(
          child: Text("👾", style: TextStyle(fontSize: cellSize * 0.55)),
        ),
      );
    }

    return Container(
      width: cellSize,
      height: cellSize,
      color: baseColor,
      child: content,
    );
  }

  Widget _buildDPad() {
    const buttonSize = 48.0;

    Widget dirButton(IconData icon, VoidCallback onPressed) {
      return Material(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: const Color(0xFF7C4DFF).withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            child: Icon(icon, size: 24, color: const Color(0xFF7C4DFF)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2A4A), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dirButton(Icons.keyboard_arrow_up_rounded, () => _attemptMove(0, -1)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dirButton(
                Icons.keyboard_arrow_left_rounded,
                () => _attemptMove(-1, 0),
              ),
              const SizedBox(width: 4),
              const SizedBox(width: buttonSize, height: buttonSize),
              const SizedBox(width: 4),
              dirButton(
                Icons.keyboard_arrow_right_rounded,
                () => _attemptMove(1, 0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          dirButton(
            Icons.keyboard_arrow_down_rounded,
            () => _attemptMove(0, 1),
          ),
        ],
      ),
    );
  }
}
