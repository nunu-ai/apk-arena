import 'dart:collection';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

class LevelDoubleMaze extends LevelWidget {
  const LevelDoubleMaze({super.key, required super.onComplete});

  @override
  State<LevelDoubleMaze> createState() => _LevelDoubleMazeState();
}

class _LevelDoubleMazeState extends State<LevelDoubleMaze> {
  static const int _totalStages = 2;

  int _currentStage = 1;
  bool _showTransition = false;

  int _stage1Moves = 0;
  int _stage1Optimal = 0;

  void _onStage1Complete(int moves, int optimal) {
    if (!mounted) return;
    setState(() {
      _stage1Moves = moves;
      _stage1Optimal = optimal;
      _showTransition = true;
    });
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      setState(() {
        _currentStage = 2;
        _showTransition = false;
      });
    });
  }

  void _onStage2Complete(int moves, int optimal) {
    if (!mounted) return;
    final s1 = _stageScore(_stage1Moves, _stage1Optimal, budgetFactor: 1.0);
    final s2 = _stageScore(moves, optimal, budgetFactor: 1.5);
    widget.onComplete(
      LevelOutcome(
        score: s1 + s2,
        metrics: {
          'stage1_moves': _stage1Moves,
          'stage1_optimal': _stage1Optimal,
          'stage2_moves': moves,
          'stage2_optimal': optimal,
        },
      ),
    );
  }

  static double _stageScore(
    int moves,
    int optimal, {
    required double budgetFactor,
  }) {
    if (optimal <= 0) return 0.5;
    final budget = optimal * budgetFactor;
    final m = max(moves, 1);
    return 0.5 * min(1.0, budget / m);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Stack(
        children: [
          if (_currentStage == 1)
            _PokemonMazeStage(
              key: const ValueKey('stage1'),
              stageLabel: 'stage 1 / $_totalStages',
              onStageComplete: _onStage1Complete,
            )
          else
            _WarpMazeStage(
              key: const ValueKey('stage2'),
              stageLabel: 'stage 2 / $_totalStages',
              onStageComplete: _onStage2Complete,
            ),
          if (_showTransition) _buildTransitionOverlay(),
        ],
      ),
    );
  }

  Widget _buildTransitionOverlay() {
    return Positioned.fill(
      child: Container(
        color: NunuColors.backgroundDefault.withValues(alpha: 0.92),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: NunuColors.primaryMain, width: 2),
              boxShadow: [
                BoxShadow(
                  color: NunuColors.primaryMain.withValues(alpha: 0.3),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(
                  Icons.check_circle_rounded,
                  color: NunuColors.successMain,
                  size: 48,
                ),
                SizedBox(height: 12),
                Text(
                  'stage 1 cleared',
                  style: TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'next: warp gates',
                  style: TextStyle(
                    color: NunuColors.secondaryLight,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// stage 1: classic random maze (Wilson's algorithm) + 4-direction d-pad
// ─────────────────────────────────────────────────────────────────────────────

enum _PokeCellType { wall, path, start, end }

class _PokemonMazeStage extends StatefulWidget {
  final String stageLabel;
  final void Function(int moves, int optimal) onStageComplete;

  const _PokemonMazeStage({
    super.key,
    required this.stageLabel,
    required this.onStageComplete,
  });

  @override
  State<_PokemonMazeStage> createState() => _PokemonMazeStageState();
}

class _PokemonMazeStageState extends State<_PokemonMazeStage>
    with SingleTickerProviderStateMixin {
  static const int _mazeWidth = 17;
  static const int _mazeHeight = 17;
  static const int _seed = 1247;

  late List<List<_PokeCellType>> _maze;
  late int _playerX;
  late int _playerY;
  late int _endX;
  late int _endY;

  int _moveCount = 0;
  int _optimalMoves = 0;
  bool _isMoving = false;
  bool _completed = false;

  late final AnimationController _moveController;

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
    );
    _generateMaze();
  }

  @override
  void dispose() {
    _moveController.dispose();
    super.dispose();
  }

  void _generateMaze() {
    final random = Random(_seed);

    _maze = List.generate(
      _mazeHeight,
      (y) => List.generate(_mazeWidth, (x) => _PokeCellType.wall),
    );

    final unvisited = <Point<int>>{};
    for (int y = 1; y < _mazeHeight; y += 2) {
      for (int x = 1; x < _mazeWidth; x += 2) {
        unvisited.add(Point(x, y));
      }
    }

    if (unvisited.isEmpty) return;

    final first = unvisited.elementAt(random.nextInt(unvisited.length));
    unvisited.remove(first);
    _maze[first.y][first.x] = _PokeCellType.path;

    while (unvisited.isNotEmpty) {
      var current = unvisited.elementAt(random.nextInt(unvisited.length));
      final pathStart = current;
      final walk = <Point<int>, Point<int>>{};

      while (unvisited.contains(current)) {
        final neighbors = <Point<int>>[];
        const directions = [
          Point(0, -2),
          Point(0, 2),
          Point(-2, 0),
          Point(2, 0),
        ];

        for (final dir in directions) {
          final next = Point(current.x + dir.x, current.y + dir.y);
          if (next.x > 0 &&
              next.x < _mazeWidth - 1 &&
              next.y > 0 &&
              next.y < _mazeHeight - 1) {
            neighbors.add(next);
          }
        }

        if (neighbors.isEmpty) break;

        final next = neighbors[random.nextInt(neighbors.length)];
        walk[current] = next;
        current = next;
      }

      if (unvisited.contains(current)) continue;

      current = pathStart;
      while (unvisited.contains(current)) {
        final next = walk[current]!;
        _maze[current.y][current.x] = _PokeCellType.path;
        final wallX = (current.x + next.x) ~/ 2;
        final wallY = (current.y + next.y) ~/ 2;
        _maze[wallY][wallX] = _PokeCellType.path;
        unvisited.remove(current);
        current = next;
      }
    }

    final extraPassages = (_mazeWidth * _mazeHeight) ~/ 25;
    for (int i = 0; i < extraPassages; i++) {
      final x = 2 + random.nextInt(_mazeWidth - 4);
      final y = 2 + random.nextInt(_mazeHeight - 4);

      if (_maze[y][x] == _PokeCellType.wall) {
        final horizontalSeparator =
            x > 0 &&
            x < _mazeWidth - 1 &&
            _maze[y][x - 1] == _PokeCellType.path &&
            _maze[y][x + 1] == _PokeCellType.path;
        final verticalSeparator =
            y > 0 &&
            y < _mazeHeight - 1 &&
            _maze[y - 1][x] == _PokeCellType.path &&
            _maze[y + 1][x] == _PokeCellType.path;

        if (horizontalSeparator || verticalSeparator) {
          _maze[y][x] = _PokeCellType.path;
        }
      }
    }

    _playerX = 1;
    _playerY = 1;
    _maze[_playerY][_playerX] = _PokeCellType.start;

    _endX = _mazeWidth - 2;
    _endY = _mazeHeight - 2;

    if (_maze[_endY][_endX] != _PokeCellType.path) {
      outerLoop:
      for (int y = _mazeHeight - 2; y > 0; y--) {
        for (int x = _mazeWidth - 2; x > 0; x--) {
          if (_maze[y][x] == _PokeCellType.path) {
            _endX = x;
            _endY = y;
            break outerLoop;
          }
        }
      }
    }

    _maze[_endY][_endX] = _PokeCellType.end;
    _moveCount = 0;
    _optimalMoves = _bfsOptimal();
  }

  int _bfsOptimal() {
    final start = Point(_playerX, _playerY);
    final visited = <Point<int>>{start};
    final queue = Queue<(Point<int>, int)>()..add((start, 0));

    while (queue.isNotEmpty) {
      final (pos, dist) = queue.removeFirst();
      if (pos.x == _endX && pos.y == _endY) return dist;

      const dirs = [Point(0, -1), Point(0, 1), Point(-1, 0), Point(1, 0)];
      for (final d in dirs) {
        final nx = pos.x + d.x;
        final ny = pos.y + d.y;
        if (nx < 0 || nx >= _mazeWidth || ny < 0 || ny >= _mazeHeight) {
          continue;
        }
        if (_maze[ny][nx] == _PokeCellType.wall) continue;
        final next = Point(nx, ny);
        if (!visited.add(next)) continue;
        queue.add((next, dist + 1));
      }
    }
    return 0;
  }

  void _movePlayer(int dx, int dy) {
    if (_isMoving || _completed) return;

    final newX = _playerX + dx;
    final newY = _playerY + dy;

    if (newX < 0 || newX >= _mazeWidth || newY < 0 || newY >= _mazeHeight) {
      return;
    }
    if (_maze[newY][newX] == _PokeCellType.wall) return;

    setState(() => _isMoving = true);

    _moveController.forward(from: 0).then((_) {
      if (!mounted) return;
      setState(() {
        _playerX = newX;
        _playerY = newY;
        _moveCount++;
        _isMoving = false;

        if (_playerX == _endX && _playerY == _endY) {
          _completed = true;
          Future.delayed(const Duration(milliseconds: 250), () {
            if (!mounted) return;
            widget.onStageComplete(_moveCount, _optimalMoves);
          });
        }
      });
    });
  }

  Widget _buildCell(int x, int y, double cellSize) {
    final cellType = _maze[y][x];
    final isPlayer = x == _playerX && y == _playerY;

    Color cellColor;
    Widget? cellContent;

    switch (cellType) {
      case _PokeCellType.wall:
        cellColor = NunuColors.primaryDarker;
        cellContent = Container(
          decoration: BoxDecoration(
            color: NunuColors.primaryDarker,
            border: Border.all(
              color: NunuColors.primaryMain.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Container(
              width: cellSize * 0.4,
              height: cellSize * 0.4,
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
        break;
      case _PokeCellType.start:
      case _PokeCellType.path:
        cellColor = NunuColors.backgroundDefault;
        break;
      case _PokeCellType.end:
        cellColor = NunuColors.backgroundDefault;
        cellContent = Container(
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
        break;
    }

    if (isPlayer) {
      cellContent = Container(
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
      color: cellColor,
      child: cellContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          _StageHeader(
            stageLabel: widget.stageLabel,
            moveCount: _moveCount,
            accent: NunuColors.primaryMain,
            iconColor: NunuColors.primaryLight,
            icon: Icons.directions_walk_rounded,
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final availableSize = min(
                    constraints.maxWidth - 24,
                    constraints.maxHeight - 24,
                  );
                  final cellSize =
                      availableSize / max(_mazeWidth, _mazeHeight);

                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: NunuColors.primaryMain,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: NunuColors.primaryMain.withValues(alpha: 0.2),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
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
            padding: const EdgeInsets.only(bottom: 24),
            child: _DPad(
              onUp: () => _movePlayer(0, -1),
              onDown: () => _movePlayer(0, 1),
              onLeft: () => _movePlayer(-1, 0),
              onRight: () => _movePlayer(1, 0),
              accent: NunuColors.primaryDark,
              iconColor: NunuColors.primaryLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// stage 2: fixed warp maze
// ─────────────────────────────────────────────────────────────────────────────

enum _WarpCellType { wall, path, start, end }

class _WarpMazeStage extends StatefulWidget {
  final String stageLabel;
  final void Function(int moves, int optimal) onStageComplete;

  const _WarpMazeStage({
    super.key,
    required this.stageLabel,
    required this.onStageComplete,
  });

  @override
  State<_WarpMazeStage> createState() => _WarpMazeStageState();
}

class _WarpMazeStageState extends State<_WarpMazeStage> {
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

  late List<List<_WarpCellType>> _maze;
  late int _playerX;
  late int _playerY;
  late int _goalX;
  late int _goalY;

  int _moveCount = 0;
  int _optimalMoves = 0;
  bool _justWarped = false;
  bool _completed = false;
  String? _lastWarpUsed;

  final Map<Point<int>, String> _warpLookup = {};
  final Map<String, List<Point<int>>> _warpRoutes = {};

  @override
  void initState() {
    super.initState();
    _buildMaze();
    _optimalMoves = _bfsOptimal();
  }

  void _buildMaze() {
    _maze = List.generate(
      _mazeHeight,
      (y) => List.generate(_mazeWidth, (x) => _WarpCellType.wall),
    );

    for (int y = 0; y < _layout.length; y++) {
      final row = _layout[y];
      for (int x = 0; x < row.length; x++) {
        final char = row[x];
        switch (char) {
          case '#':
            _maze[y][x] = _WarpCellType.wall;
            break;
          case '.':
            _maze[y][x] = _WarpCellType.path;
            break;
          case 'S':
            _maze[y][x] = _WarpCellType.start;
            _playerX = x;
            _playerY = y;
            break;
          case 'E':
            _maze[y][x] = _WarpCellType.end;
            _goalX = x;
            _goalY = y;
            break;
          default:
            if (RegExp(r'[A-Z]').hasMatch(char)) {
              _maze[y][x] = _WarpCellType.path;
              final point = Point<int>(x, y);
              _warpLookup[point] = char;
              _warpRoutes.putIfAbsent(char, () => []).add(point);
            } else {
              _maze[y][x] = _WarpCellType.wall;
            }
        }
      }
    }
  }

  Point<int> _resolveDestination(int nx, int ny) {
    final warpId = _warpLookup[Point<int>(nx, ny)];
    if (warpId == null) return Point(nx, ny);
    final route = _warpRoutes[warpId];
    if (route == null || route.length < 2) return Point(nx, ny);
    final currentIndex = route.indexWhere((p) => p.x == nx && p.y == ny);
    if (currentIndex == -1) return Point(nx, ny);
    return route[(currentIndex + 1) % route.length];
  }

  int _bfsOptimal() {
    final start = Point(_playerX, _playerY);
    final visited = <Point<int>>{start};
    final queue = Queue<(Point<int>, int)>()..add((start, 0));

    while (queue.isNotEmpty) {
      final (pos, dist) = queue.removeFirst();
      if (pos.x == _goalX && pos.y == _goalY) return dist;

      const dirs = [Point(0, -1), Point(0, 1), Point(-1, 0), Point(1, 0)];
      for (final d in dirs) {
        final nx = pos.x + d.x;
        final ny = pos.y + d.y;
        if (nx < 0 || nx >= _mazeWidth || ny < 0 || ny >= _mazeHeight) {
          continue;
        }
        if (_maze[ny][nx] == _WarpCellType.wall) continue;
        final dest = _resolveDestination(nx, ny);
        if (!visited.add(dest)) continue;
        queue.add((dest, dist + 1));
      }
    }
    return 0;
  }

  void _attemptMove(int dx, int dy) {
    if (_completed) return;
    _justWarped = false;
    _lastWarpUsed = null;
    final newX = _playerX + dx;
    final newY = _playerY + dy;

    if (newX < 0 || newX >= _mazeWidth || newY < 0 || newY >= _mazeHeight) {
      return;
    }
    if (_maze[newY][newX] == _WarpCellType.wall) return;

    setState(() {
      _playerX = newX;
      _playerY = newY;
      _moveCount++;
    });

    _handleWarp();
    _checkWin();
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
      _completed = true;
      Future.delayed(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        widget.onStageComplete(_moveCount, _optimalMoves);
      });
    }
  }

  Widget _buildCell(int x, int y, double cellSize) {
    final cellType = _maze[y][x];
    final warpId = _warpLookup[Point<int>(x, y)];
    final isPlayer = x == _playerX && y == _playerY;
    final isGoal = x == _goalX && y == _goalY;

    Color baseColor = NunuColors.backgroundDefault;
    Widget? content;

    switch (cellType) {
      case _WarpCellType.wall:
        baseColor = NunuColors.primaryDarker;
        content = Container(
          decoration: BoxDecoration(
            color: NunuColors.primaryDarker,
            border: Border.all(
              color: NunuColors.primaryMain.withValues(alpha: 0.5),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Container(
              width: cellSize * 0.4,
              height: cellSize * 0.4,
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
        break;
      case _WarpCellType.start:
      case _WarpCellType.path:
      case _WarpCellType.end:
        baseColor = NunuColors.backgroundDefault;
        break;
    }

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

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _StageHeader(
              stageLabel: widget.stageLabel,
              moveCount: _moveCount,
              accent: NunuColors.primaryMain,
              iconColor: NunuColors.primaryLight,
              icon: Icons.swap_calls_rounded,
              trailing: _lastWarpUsed != null
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _warpColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _warpColor),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.blur_on_rounded,
                            color: _warpColor,
                            size: 14,
                          ),
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
                    )
                  : null,
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableSize = min(
                      constraints.maxWidth - 24,
                      constraints.maxHeight - 24,
                    );
                    final cellSize =
                        availableSize / max(_mazeWidth, _mazeHeight);

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: NunuColors.primaryMain,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: NunuColors.primaryMain.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
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
              padding: const EdgeInsets.only(bottom: 24),
              child: _DPad(
                onUp: () => _attemptMove(0, -1),
                onDown: () => _attemptMove(0, 1),
                onLeft: () => _attemptMove(-1, 0),
                onRight: () => _attemptMove(1, 0),
                accent: NunuColors.primaryDark,
                iconColor: NunuColors.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// shared widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StageHeader extends StatelessWidget {
  final String stageLabel;
  final int moveCount;
  final Color accent;
  final Color iconColor;
  final IconData icon;
  final Widget? trailing;

  const _StageHeader({
    required this.stageLabel,
    required this.moveCount,
    required this.accent,
    required this.iconColor,
    required this.icon,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.6)),
            ),
            child: Row(
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 6),
                Text(
                  '$moveCount',
                  style: const TextStyle(
                    color: NunuColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
          if (trailing != null) ...[trailing!, const SizedBox(width: 8)],
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent.withValues(alpha: 0.4)),
            ),
            child: Text(
              stageLabel,
              style: const TextStyle(
                color: NunuColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DPad extends StatelessWidget {
  final VoidCallback onUp;
  final VoidCallback onDown;
  final VoidCallback onLeft;
  final VoidCallback onRight;
  final Color accent;
  final Color iconColor;

  const _DPad({
    required this.onUp,
    required this.onDown,
    required this.onLeft,
    required this.onRight,
    required this.accent,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    const buttonSize = 52.0;

    Widget dirButton(IconData icon, VoidCallback onPressed) {
      return Material(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: buttonSize,
            height: buttonSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accent, width: 2),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.3),
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dirButton(Icons.keyboard_arrow_up_rounded, onUp),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dirButton(Icons.keyboard_arrow_left_rounded, onLeft),
              const SizedBox(width: 4),
              const SizedBox(width: buttonSize, height: buttonSize),
              const SizedBox(width: 4),
              dirButton(Icons.keyboard_arrow_right_rounded, onRight),
            ],
          ),
          const SizedBox(height: 4),
          dirButton(Icons.keyboard_arrow_down_rounded, onDown),
        ],
      ),
    );
  }
}
