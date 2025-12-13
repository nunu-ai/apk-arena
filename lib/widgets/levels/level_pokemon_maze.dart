import 'package:flutter/material.dart';
import 'dart:math';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// Cell types for the maze
enum CellType { wall, path, start, end }

class LevelPokemonMaze extends LevelWidget {
  const LevelPokemonMaze({super.key, required super.onComplete});

  @override
  State<LevelPokemonMaze> createState() => _LevelPokemonMazeState();
}

class _LevelPokemonMazeState extends State<LevelPokemonMaze>
    with SingleTickerProviderStateMixin {
  // Maze dimensions - odd numbers work best for maze generation
  static const int mazeWidth = 17;
  static const int mazeHeight = 17;

  late List<List<CellType>> _maze;
  late int _playerX;
  late int _playerY;
  late int _endX;
  late int _endY;

  bool _isMoving = false;
  int _moveCount = 0;

  late AnimationController _moveController;

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
    final random = Random();

    // Initialize maze with walls
    _maze = List.generate(
      mazeHeight,
      (y) => List.generate(mazeWidth, (x) => CellType.wall),
    );

    // Recursive Backtracker using a stack
    final stack = <Point<int>>[];

    // Start at (1, 1)
    var current = const Point(1, 1);
    _maze[current.y][current.x] = CellType.path;
    stack.add(current);

    while (stack.isNotEmpty) {
      current = stack.last;

      // Find unvisited neighbors (step 2)
      final neighbors = <Point<int>>[];
      final directions = [
        const Point(0, -2), // Up
        const Point(0, 2), // Down
        const Point(-2, 0), // Left
        const Point(2, 0), // Right
      ];

      for (final dir in directions) {
        final next = Point(current.x + dir.x, current.y + dir.y);
        // Check bounds and if unvisited (still a wall)
        if (next.x > 0 &&
            next.x < mazeWidth - 1 &&
            next.y > 0 &&
            next.y < mazeHeight - 1 &&
            _maze[next.y][next.x] == CellType.wall) {
          neighbors.add(next);
        }
      }

      if (neighbors.isNotEmpty) {
        final next = neighbors[random.nextInt(neighbors.length)];

        // Remove wall between current and next
        final wallX = current.x + (next.x - current.x) ~/ 2;
        final wallY = current.y + (next.y - current.y) ~/ 2;

        _maze[wallY][wallX] = CellType.path;
        _maze[next.y][next.x] = CellType.path;

        stack.add(next);
      } else {
        stack.removeLast();
      }
    }

    // Add some extra passages to create multiple solutions and loops
    int extraPassages = (mazeWidth * mazeHeight) ~/ 25;
    for (int i = 0; i < extraPassages; i++) {
      // Only consider interior walls
      final x = 2 + random.nextInt(mazeWidth - 4);
      final y = 2 + random.nextInt(mazeHeight - 4);

      if (_maze[y][x] == CellType.wall) {
        // Check if this wall separates two path cells
        bool horizontalSeparator =
            x > 0 &&
            x < mazeWidth - 1 &&
            _maze[y][x - 1] == CellType.path &&
            _maze[y][x + 1] == CellType.path;
        bool verticalSeparator =
            y > 0 &&
            y < mazeHeight - 1 &&
            _maze[y - 1][x] == CellType.path &&
            _maze[y + 1][x] == CellType.path;

        if (horizontalSeparator || verticalSeparator) {
          _maze[y][x] = CellType.path;
        }
      }
    }

    // Set start position (top-left)
    _playerX = 1;
    _playerY = 1;
    _maze[_playerY][_playerX] = CellType.start;

    // Set end position (bottom-right area)
    _endX = mazeWidth - 2;
    _endY = mazeHeight - 2;

    // Search for a valid end position if the default one isn't a path
    // (though with this generation, (odd, odd) should always be a path, but safety check)
    if (_maze[_endY][_endX] != CellType.path) {
      // Find nearest path cell
      // Simple scan from bottom-right
      outerLoop:
      for (int y = mazeHeight - 2; y > 0; y--) {
        for (int x = mazeWidth - 2; x > 0; x--) {
          if (_maze[y][x] == CellType.path) {
            _endX = x;
            _endY = y;
            break outerLoop;
          }
        }
      }
    }

    _maze[_endY][_endX] = CellType.end;
    _moveCount = 0;
  }

  void _movePlayer(int dx, int dy) {
    if (_isMoving) return;

    final newX = _playerX + dx;
    final newY = _playerY + dy;

    // Check bounds
    if (newX < 0 || newX >= mazeWidth || newY < 0 || newY >= mazeHeight) {
      return;
    }

    // Check if can move (not a wall)
    if (_maze[newY][newX] == CellType.wall) {
      return;
    }

    setState(() {
      _isMoving = true;
    });

    _moveController.forward(from: 0).then((_) {
      setState(() {
        _playerX = newX;
        _playerY = newY;
        _moveCount++;
        _isMoving = false;

        // Check win condition
        if (_playerX == _endX && _playerY == _endY) {
          Future.delayed(const Duration(milliseconds: 300), () {
            widget.onComplete(true);
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
      case CellType.wall:
        cellColor = NunuColors.backgroundPaper;
        cellContent = Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            border: Border.all(
              color: NunuColors.primaryDark.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
          child: Center(
            child: Container(
              width: cellSize * 0.4,
              height: cellSize * 0.4,
              decoration: BoxDecoration(
                color: NunuColors.secondaryDarker.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
        );
        break;
      case CellType.start:
      case CellType.path:
        cellColor = NunuColors.backgroundDefault;
        break;
      case CellType.end:
        cellColor = NunuColors.backgroundDefault;
        // Goal marker - glowing circle
        cellContent = Center(
          child: Container(
            width: cellSize * 0.6,
            height: cellSize * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  NunuColors.successLight,
                  NunuColors.successMain,
                  NunuColors.successDark,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: NunuColors.successMain.withValues(alpha: 0.6),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        );
        break;
    }

    if (isPlayer) {
      cellContent = _buildPlayerDot(cellSize);
    }

    return Container(
      width: cellSize,
      height: cellSize,
      color: cellColor,
      child: cellContent,
    );
  }

  Widget _buildPlayerDot(double cellSize) {
    return Center(
      child: Container(
        width: cellSize * 0.55,
        height: cellSize * 0.55,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              NunuColors.primaryLighter,
              NunuColors.primaryMain,
              NunuColors.primaryDark,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withValues(alpha: 0.6),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDPad() {
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
              border: Border.all(color: NunuColors.primaryDark, width: 2),
              boxShadow: [
                BoxShadow(
                  color: NunuColors.primaryDark.withValues(alpha: 0.3),
                  offset: const Offset(2, 2),
                ),
              ],
            ),
            child: Icon(icon, size: 26, color: NunuColors.primaryLight),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: NunuColors.primaryDark.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          dirButton(Icons.keyboard_arrow_up_rounded, () => _movePlayer(0, -1)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              dirButton(
                Icons.keyboard_arrow_left_rounded,
                () => _movePlayer(-1, 0),
              ),
              const SizedBox(width: 4),
              SizedBox(width: buttonSize, height: buttonSize),
              const SizedBox(width: 4),
              dirButton(
                Icons.keyboard_arrow_right_rounded,
                () => _movePlayer(1, 0),
              ),
            ],
          ),
          const SizedBox(height: 4),
          dirButton(Icons.keyboard_arrow_down_rounded, () => _movePlayer(0, 1)),
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
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Move counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: NunuColors.primaryDark.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.directions_walk_rounded,
                          color: NunuColors.primaryLight,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_moveCount',
                          style: const TextStyle(
                            color: NunuColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reset button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _generateMaze();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: NunuColors.secondaryDark.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            color: NunuColors.secondaryLight,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'new maze',
                            style: TextStyle(
                              color: NunuColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Maze
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableSize = min(
                      constraints.maxWidth - 24,
                      constraints.maxHeight - 24,
                    );
                    final cellSize = availableSize / max(mazeWidth, mazeHeight);

                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: NunuColors.primaryMain,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: NunuColors.primaryMain.withValues(
                              alpha: 0.2,
                            ),
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
                            for (int y = 0; y < mazeHeight; y++)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (int x = 0; x < mazeWidth; x++)
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

            // D-Pad Controls
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: _buildDPad(),
            ),
          ],
        ),
      ),
    );
  }
}
