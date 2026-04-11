import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';

// Gem types for the board
enum GemType { red, green, blue, yellow, purple }

// Power-up types
enum PowerUpType { none, rocketHorizontal, rocketVertical, propeller, bomb }

// Represents a single cell on the board
class BoardCell {
  GemType gemType;
  PowerUpType powerUp;
  bool hasCrown;
  bool isMatched;
  bool isEmpty;

  BoardCell({
    required this.gemType,
    this.powerUp = PowerUpType.none,
    this.hasCrown = false,
    this.isMatched = false,
    this.isEmpty = false,
  });

  BoardCell copy() {
    return BoardCell(
      gemType: gemType,
      powerUp: powerUp,
      hasCrown: hasCrown,
      isMatched: isMatched,
      isEmpty: isEmpty,
    );
  }
}

// Level configuration
class LevelConfig {
  final int crownsRequired;
  final int movesAvailable;

  const LevelConfig({
    required this.crownsRequired,
    required this.movesAvailable,
  });
}

class LevelRoyalMatch extends LevelWidget {
  const LevelRoyalMatch({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelRoyalMatch> createState() => _LevelRoyalMatchState();
}

class _LevelRoyalMatchState extends State<LevelRoyalMatch> {
  static const int boardSize = 8;
  static const List<LevelConfig> levels = [
    LevelConfig(crownsRequired: 3, movesAvailable: 100),
    LevelConfig(crownsRequired: 5, movesAvailable: 100),
    LevelConfig(crownsRequired: 8, movesAvailable: 100),
  ];

  final Random _random = Random();

  int _currentLevel = 0;
  int _movesRemaining = 0;
  int _crownsCollected = 0;
  late List<List<BoardCell>> _board;
  bool _isProcessing = false;
  bool _showInfo = false;
  bool _isLevelTransitioning = false;

  // Swipe gesture state
  int? _dragFromRow;
  int? _dragFromCol;
  Offset? _dragEndGlobal;

  // Board geometry for coordinate mapping
  final GlobalKey _boardKey = GlobalKey();
  double _cellSize = 0;

  // Colors for gems
  static const Map<GemType, Color> gemColors = {
    GemType.red: Color(0xFFE53935),
    GemType.green: Color(0xFF43A047),
    GemType.blue: Color(0xFF1E88E5),
    GemType.yellow: Color(0xFFFFB300),
    GemType.purple: Color(0xFF8E24AA),
  };

  @override
  void initState() {
    super.initState();
    _startLevel(_currentLevel);
  }

  void _startLevel(int levelIndex) {
    setState(() {
      _currentLevel = levelIndex;
      _movesRemaining = levels[levelIndex].movesAvailable;
      _crownsCollected = 0;

      // Regenerate board until no initial matches exist
      do {
        _board = _generateBoard(levels[levelIndex].crownsRequired);
      } while (_findAllMatches().isNotEmpty);

      _isProcessing = false;
      _isLevelTransitioning = false;
    });
  }

  List<List<BoardCell>> _generateBoard(int crownCount) {
    final List<List<BoardCell>> board = List.generate(
      boardSize,
      (_) => List.generate(boardSize, (_) => BoardCell(gemType: _randomGem())),
    );

    // Avoid immediate matches at start
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        while (_wouldCreateImmediateRun(board, r, c)) {
          board[r][c].gemType = _randomGem();
        }
      }
    }

    // Place crowns randomly
    final positions = <Point<int>>[];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        positions.add(Point(r, c));
      }
    }
    positions.shuffle(_random);
    for (int i = 0; i < crownCount && i < positions.length; i++) {
      board[positions[i].x][positions[i].y].hasCrown = true;
    }

    return board;
  }

  GemType _randomGem() {
    final values = GemType.values;
    return values[_random.nextInt(values.length)];
  }

  bool _wouldCreateImmediateRun(List<List<BoardCell>> board, int r, int c) {
    final t = board[r][c].gemType;
    // Check left two
    if (c >= 2 &&
        !board[r][c - 1].isEmpty &&
        !board[r][c - 2].isEmpty &&
        board[r][c - 1].gemType == t &&
        board[r][c - 2].gemType == t)
      return true;
    // Check up two
    if (r >= 2 &&
        !board[r - 1][c].isEmpty &&
        !board[r - 2][c].isEmpty &&
        board[r - 1][c].gemType == t &&
        board[r - 2][c].gemType == t)
      return true;
    return false;
  }

  // Swipe handling - validates both start and end positions are on adjacent cells
  void _onPanStart(int row, int col, DragStartDetails details) {
    if (_isProcessing) return;
    _dragFromRow = row;
    _dragFromCol = col;
    _dragEndGlobal = details.globalPosition;
  }

  void _onPanUpdate(int row, int col, DragUpdateDetails details) {
    if (_isProcessing) return;
    // Track the latest position during the drag
    _dragEndGlobal = details.globalPosition;
  }

  void _onPanEnd(int row, int col, DragEndDetails details) {
    if (_isProcessing) return;
    final int? fromRow = _dragFromRow;
    final int? fromCol = _dragFromCol;

    if (fromRow == null || fromCol == null || _dragEndGlobal == null) {
      _resetDrag();
      return;
    }

    // Get board position from GlobalKey
    final RenderBox? boardBox =
        _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (boardBox == null) {
      _resetDrag();
      return;
    }

    final boardPosition = boardBox.localToGlobal(Offset.zero);

    // Calculate which cell the drag ended on using global coordinates
    final localEndX = _dragEndGlobal!.dx - boardPosition.dx;
    final localEndY = _dragEndGlobal!.dy - boardPosition.dy;

    final endCol = (localEndX / _cellSize).floor();
    final endRow = (localEndY / _cellSize).floor();

    // Validate end cell is within board bounds
    if (endRow < 0 ||
        endRow >= boardSize ||
        endCol < 0 ||
        endCol >= boardSize) {
      _resetDrag();
      return;
    }

    // Validate that start and end cells are adjacent (exactly 1 cell away, not diagonal)
    final rowDiff = (endRow - fromRow).abs();
    final colDiff = (endCol - fromCol).abs();
    final isAdjacent =
        (rowDiff == 1 && colDiff == 0) || (rowDiff == 0 && colDiff == 1);

    if (isAdjacent) {
      _trySwap(fromRow, fromCol, endRow, endCol);
    }

    _resetDrag();
  }

  void _onTap(int row, int col) {
    if (_isProcessing) return;
    final cell = _board[row][col];
    if (cell.powerUp != PowerUpType.none) {
      _activatePowerUp(row, col);
    }
  }

  void _resetDrag() {
    _dragFromRow = null;
    _dragFromCol = null;
    _dragEndGlobal = null;
  }

  void _trySwap(int r1, int c1, int r2, int c2) async {
    setState(() {
      _isProcessing = true;
      _swap(r1, c1, r2, c2);
    });

    await Future.delayed(const Duration(milliseconds: 100));

    // Check if swap creates a match
    final matches = _findAllMatches();
    if (matches.isNotEmpty) {
      setState(() {
        _movesRemaining--;
      });
      await _processMatches();
    } else {
      // Revert swap if no match
      setState(() {
        _swap(r1, c1, r2, c2);
        _isProcessing = false;
      });
    }
  }

  void _swap(int r1, int c1, int r2, int c2) {
    final temp = _board[r1][c1];
    _board[r1][c1] = _board[r2][c2];
    _board[r2][c2] = temp;
  }

  // Match detection - returns list of matched cells grouped by match type
  List<MatchResult> _findAllMatches() {
    final List<MatchResult> results = [];
    final Set<Point<int>> allMatched = {};

    // Find horizontal matches
    for (int r = 0; r < boardSize; r++) {
      int c = 0;
      while (c < boardSize) {
        if (_board[r][c].isEmpty) {
          c++;
          continue;
        }
        final type = _board[r][c].gemType;
        int length = 1;
        while (c + length < boardSize &&
            !_board[r][c + length].isEmpty &&
            _board[r][c + length].gemType == type) {
          length++;
        }
        if (length >= 3) {
          final cells = <Point<int>>[];
          for (int i = 0; i < length; i++) {
            cells.add(Point(r, c + i));
          }
          results.add(
            MatchResult(cells: cells, isHorizontal: true, length: length),
          );
          allMatched.addAll(cells);
        }
        c += max(1, length);
      }
    }

    // Find vertical matches
    for (int c = 0; c < boardSize; c++) {
      int r = 0;
      while (r < boardSize) {
        if (_board[r][c].isEmpty) {
          r++;
          continue;
        }
        final type = _board[r][c].gemType;
        int length = 1;
        while (r + length < boardSize &&
            !_board[r + length][c].isEmpty &&
            _board[r + length][c].gemType == type) {
          length++;
        }
        if (length >= 3) {
          final cells = <Point<int>>[];
          for (int i = 0; i < length; i++) {
            cells.add(Point(r + i, c));
          }
          results.add(
            MatchResult(cells: cells, isHorizontal: false, length: length),
          );
          allMatched.addAll(cells);
        }
        r += max(1, length);
      }
    }

    // Find 2x2 square matches
    for (int r = 0; r < boardSize - 1; r++) {
      for (int c = 0; c < boardSize - 1; c++) {
        if (_board[r][c].isEmpty) continue;
        final type = _board[r][c].gemType;
        if (!_board[r][c + 1].isEmpty &&
            !_board[r + 1][c].isEmpty &&
            !_board[r + 1][c + 1].isEmpty &&
            _board[r][c + 1].gemType == type &&
            _board[r + 1][c].gemType == type &&
            _board[r + 1][c + 1].gemType == type) {
          final cells = [
            Point(r, c),
            Point(r, c + 1),
            Point(r + 1, c),
            Point(r + 1, c + 1),
          ];
          // Only add if not already part of a longer match
          if (!cells.every((p) => allMatched.contains(p))) {
            results.add(MatchResult(cells: cells, isSquare: true, length: 4));
          }
        }
      }
    }

    return results;
  }

  // Detect T and L shapes for bomb creation
  bool _isTOrLShape(Set<Point<int>> matchedCells) {
    if (matchedCells.length < 5) return false;

    // Check for T or L by seeing if there's an intersection point
    for (final cell in matchedCells) {
      int horizontalCount = 0;
      int verticalCount = 0;

      for (final other in matchedCells) {
        if (other.x == cell.x) horizontalCount++;
        if (other.y == cell.y) verticalCount++;
      }

      if (horizontalCount >= 3 && verticalCount >= 3) {
        return true;
      }
    }
    return false;
  }

  Future<void> _processMatches() async {
    while (true) {
      final matches = _findAllMatches();
      if (matches.isEmpty) break;

      // Collect all matched cells and determine power-ups
      final Set<Point<int>> allMatchedCells = {};
      final Map<Point<int>, PowerUpType> powerUpsToCreate = {};

      for (final match in matches) {
        allMatchedCells.addAll(match.cells);

        // Determine power-up creation based on match type
        if (match.length >= 4 && !match.isSquare) {
          // 4 in a row creates a rocket
          final centerIdx = match.cells.length ~/ 2;
          final centerCell = match.cells[centerIdx];
          if (match.isHorizontal) {
            powerUpsToCreate[centerCell] = PowerUpType.rocketHorizontal;
          } else {
            powerUpsToCreate[centerCell] = PowerUpType.rocketVertical;
          }
        } else if (match.isSquare) {
          // 2x2 creates propeller
          final centerCell = match.cells[0];
          powerUpsToCreate[centerCell] = PowerUpType.propeller;
        }
      }

      // Check for T or L shapes (creates bomb)
      if (_isTOrLShape(allMatchedCells)) {
        // Find intersection point
        for (final cell in allMatchedCells) {
          int horizontalCount = 0;
          int verticalCount = 0;

          for (final other in allMatchedCells) {
            if (other.x == cell.x) horizontalCount++;
            if (other.y == cell.y) verticalCount++;
          }

          if (horizontalCount >= 3 && verticalCount >= 3) {
            powerUpsToCreate[cell] = PowerUpType.bomb;
            break;
          }
        }
      }

      // Collect crowns and clear matched cells
      setState(() {
        for (final cell in allMatchedCells) {
          if (_board[cell.x][cell.y].hasCrown) {
            _crownsCollected++;
          }
          // Activate any power-ups in matched cells
          if (_board[cell.x][cell.y].powerUp != PowerUpType.none &&
              !powerUpsToCreate.containsKey(cell)) {
            _queuePowerUpActivation(cell.x, cell.y);
          }
          _board[cell.x][cell.y].isMatched = true;
        }
      });

      await Future.delayed(const Duration(milliseconds: 150));

      // Clear matched cells and create power-ups
      setState(() {
        for (final cell in allMatchedCells) {
          if (powerUpsToCreate.containsKey(cell)) {
            _board[cell.x][cell.y] = BoardCell(
              gemType: _board[cell.x][cell.y].gemType,
              powerUp: powerUpsToCreate[cell]!,
            );
          } else {
            _board[cell.x][cell.y].isEmpty = true;
            _board[cell.x][cell.y].hasCrown = false;
            _board[cell.x][cell.y].powerUp = PowerUpType.none;
          }
          _board[cell.x][cell.y].isMatched = false;
        }
      });

      // Process pending power-up activations
      await _processPendingPowerUps();

      await Future.delayed(const Duration(milliseconds: 100));

      // Apply gravity
      _applyGravity();
      await Future.delayed(const Duration(milliseconds: 150));

      // Fill empty cells
      _fillEmptyCells();
      await Future.delayed(const Duration(milliseconds: 150));
    }

    // Check win/lose conditions
    _checkGameState();
  }

  final List<Point<int>> _pendingPowerUps = [];

  void _queuePowerUpActivation(int row, int col) {
    _pendingPowerUps.add(Point(row, col));
  }

  Future<void> _processPendingPowerUps() async {
    while (_pendingPowerUps.isNotEmpty) {
      final point = _pendingPowerUps.removeAt(0);
      await _executePowerUp(point.x, point.y, _board[point.x][point.y].powerUp);
    }
  }

  void _activatePowerUp(int row, int col) async {
    final powerUp = _board[row][col].powerUp;
    if (powerUp == PowerUpType.none) return;

    setState(() {
      _isProcessing = true;
      _movesRemaining--;
    });

    await _executePowerUp(row, col, powerUp);

    // Clear the power-up cell
    setState(() {
      if (_board[row][col].hasCrown) {
        _crownsCollected++;
      }
      _board[row][col].isEmpty = true;
      _board[row][col].powerUp = PowerUpType.none;
      _board[row][col].hasCrown = false;
    });

    await Future.delayed(const Duration(milliseconds: 100));

    // Apply gravity and fill
    _applyGravity();
    await Future.delayed(const Duration(milliseconds: 150));
    _fillEmptyCells();
    await Future.delayed(const Duration(milliseconds: 150));

    // Process any cascading matches
    await _processMatches();

    _checkGameState();
  }

  Future<void> _executePowerUp(int row, int col, PowerUpType powerUp) async {
    switch (powerUp) {
      case PowerUpType.rocketHorizontal:
        await _activateRocketHorizontal(row);
        break;
      case PowerUpType.rocketVertical:
        await _activateRocketVertical(col);
        break;
      case PowerUpType.propeller:
        await _activatePropeller();
        break;
      case PowerUpType.bomb:
        await _activateBomb(row, col);
        break;
      case PowerUpType.none:
        break;
    }
  }

  Future<void> _activateRocketHorizontal(int row) async {
    setState(() {
      for (int c = 0; c < boardSize; c++) {
        if (_board[row][c].hasCrown) {
          _crownsCollected++;
        }
        if (_board[row][c].powerUp != PowerUpType.none) {
          _queuePowerUpActivation(row, c);
        }
        _board[row][c].isMatched = true;
      }
    });
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      for (int c = 0; c < boardSize; c++) {
        _board[row][c].isEmpty = true;
        _board[row][c].hasCrown = false;
        _board[row][c].powerUp = PowerUpType.none;
        _board[row][c].isMatched = false;
      }
    });
  }

  Future<void> _activateRocketVertical(int col) async {
    setState(() {
      for (int r = 0; r < boardSize; r++) {
        if (_board[r][col].hasCrown) {
          _crownsCollected++;
        }
        if (_board[r][col].powerUp != PowerUpType.none) {
          _queuePowerUpActivation(r, col);
        }
        _board[r][col].isMatched = true;
      }
    });
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      for (int r = 0; r < boardSize; r++) {
        _board[r][col].isEmpty = true;
        _board[r][col].hasCrown = false;
        _board[r][col].powerUp = PowerUpType.none;
        _board[r][col].isMatched = false;
      }
    });
  }

  Future<void> _activatePropeller() async {
    // Find a random crown on the board
    final crownPositions = <Point<int>>[];
    for (int r = 0; r < boardSize; r++) {
      for (int c = 0; c < boardSize; c++) {
        if (_board[r][c].hasCrown && !_board[r][c].isEmpty) {
          crownPositions.add(Point(r, c));
        }
      }
    }

    if (crownPositions.isNotEmpty) {
      final target = crownPositions[_random.nextInt(crownPositions.length)];
      await _activateBomb(target.x, target.y);
    } else {
      // No crowns, just destroy a random 3x3 area
      final targetRow = _random.nextInt(boardSize);
      final targetCol = _random.nextInt(boardSize);
      await _activateBomb(targetRow, targetCol);
    }
  }

  Future<void> _activateBomb(int row, int col) async {
    // Destroy 3x3 area
    setState(() {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final r = row + dr;
          final c = col + dc;
          if (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
            if (_board[r][c].hasCrown) {
              _crownsCollected++;
            }
            if (_board[r][c].powerUp != PowerUpType.none &&
                !(r == row && c == col)) {
              _queuePowerUpActivation(r, c);
            }
            _board[r][c].isMatched = true;
          }
        }
      }
    });
    await Future.delayed(const Duration(milliseconds: 150));
    setState(() {
      for (int dr = -1; dr <= 1; dr++) {
        for (int dc = -1; dc <= 1; dc++) {
          final r = row + dr;
          final c = col + dc;
          if (r >= 0 && r < boardSize && c >= 0 && c < boardSize) {
            _board[r][c].isEmpty = true;
            _board[r][c].hasCrown = false;
            _board[r][c].powerUp = PowerUpType.none;
            _board[r][c].isMatched = false;
          }
        }
      }
    });
  }

  void _applyGravity() {
    setState(() {
      for (int c = 0; c < boardSize; c++) {
        int writeRow = boardSize - 1;
        for (int r = boardSize - 1; r >= 0; r--) {
          if (!_board[r][c].isEmpty) {
            if (r != writeRow) {
              _board[writeRow][c] = _board[r][c].copy();
              _board[r][c] = BoardCell(gemType: _randomGem(), isEmpty: true);
            }
            writeRow--;
          }
        }
      }
    });
  }

  void _fillEmptyCells() {
    setState(() {
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          if (_board[r][c].isEmpty) {
            _board[r][c] = BoardCell(gemType: _randomGem());
          }
        }
      }

      // Ensure no immediate matches in new cells
      for (int r = 0; r < boardSize; r++) {
        for (int c = 0; c < boardSize; c++) {
          while (_wouldCreateImmediateRun(_board, r, c)) {
            _board[r][c].gemType = _randomGem();
          }
        }
      }
    });
  }

  void _checkGameState() {
    final currentLevelConfig = levels[_currentLevel];

    if (_crownsCollected >= currentLevelConfig.crownsRequired) {
      // Prevent duplicate level transitions
      if (_isLevelTransitioning) return;
      _isLevelTransitioning = true;

      // Level complete
      if (_currentLevel + 1 >= levels.length) {
        // All levels complete - game won!
        widget.onComplete(LevelOutcome(score: 1));
      } else {
        // Move to next level - capture the next level index now
        final nextLevel = _currentLevel + 1;
        Future.delayed(const Duration(milliseconds: 500), () {
          _startLevel(nextLevel);
        });
      }
    } else if (_movesRemaining <= 0) {
      // Out of moves - game over!
      widget.onComplete(LevelOutcome(score: 0));
    } else {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLevelConfig = levels[_currentLevel];

    return Container(
      color: const Color(0xFF1a1a4a),
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Header with level info, moves, and crown progress
                _buildHeader(currentLevelConfig),
                const SizedBox(height: 8),
                // Game board
                Expanded(child: Center(child: _buildBoard())),
                const SizedBox(height: 16),
              ],
            ),
            // Info overlay
            if (_showInfo) _buildInfoOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LevelConfig config) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Info button
          GestureDetector(
            onTap: () => setState(() => _showInfo = true),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Level indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF6a4c93),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'level ${_currentLevel + 1}/${levels.length}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const Spacer(),
          // Crown progress
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD700), width: 1),
            ),
            child: Row(
              children: [
                const Text('👑', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 4),
                Text(
                  '$_crownsCollected/${config.crownsRequired}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Moves remaining
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _movesRemaining <= 3
                  ? Colors.red.withOpacity(0.3)
                  : Colors.blue.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _movesRemaining <= 3 ? Colors.red : Colors.blue,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.touch_app, color: Colors.white, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$_movesRemaining',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
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

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double gridSize =
            min(constraints.maxWidth, constraints.maxHeight) * 0.95;
        final double cellSize = gridSize / boardSize;

        // Store cell size for coordinate mapping
        _cellSize = cellSize;

        return Container(
          key: _boardKey,
          width: gridSize,
          height: gridSize,
          decoration: BoxDecoration(
            color: const Color(0xFF2a2a5a),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF4a4a8a), width: 2),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: boardSize,
              ),
              itemCount: boardSize * boardSize,
              itemBuilder: (context, index) {
                final row = index ~/ boardSize;
                final col = index % boardSize;
                return _buildCell(row, col, cellSize);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int row, int col, double size) {
    final cell = _board[row][col];

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (details) => _onPanStart(row, col, details),
      onPanUpdate: (details) => _onPanUpdate(row, col, details),
      onPanEnd: (details) => _onPanEnd(row, col, details),
      onTap: () => _onTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: cell.isEmpty
              ? Colors.transparent
              : cell.isMatched
              ? Colors.white.withOpacity(0.5)
              : gemColors[cell.gemType]!.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          border: cell.hasCrown && !cell.isEmpty
              ? Border.all(color: const Color(0xFFFFD700), width: 2)
              : null,
          boxShadow: cell.isEmpty || cell.isMatched
              ? null
              : [
                  BoxShadow(
                    color: gemColors[cell.gemType]!.withOpacity(0.4),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: cell.isEmpty
            ? null
            : Stack(
                alignment: Alignment.center,
                children: [
                  // Power-up icon
                  if (cell.powerUp != PowerUpType.none)
                    _buildPowerUpIcon(cell.powerUp),
                  // Crown indicator
                  if (cell.hasCrown)
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Text(
                        '👑',
                        style: TextStyle(fontSize: size * 0.25),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildPowerUpIcon(PowerUpType powerUp) {
    switch (powerUp) {
      case PowerUpType.rocketHorizontal:
        return const Icon(Icons.arrow_forward, color: Colors.white, size: 24);
      case PowerUpType.rocketVertical:
        return const Icon(Icons.arrow_upward, color: Colors.white, size: 24);
      case PowerUpType.propeller:
        return const Icon(Icons.air, color: Colors.white, size: 24);
      case PowerUpType.bomb:
        return const Text('💣', style: TextStyle(fontSize: 20));
      case PowerUpType.none:
        return const SizedBox.shrink();
    }
  }

  Widget _buildInfoOverlay() {
    return GestureDetector(
      onTap: () => setState(() => _showInfo = false),
      child: Container(
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF2a2a5a),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF6a4c93), width: 2),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'how to play',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _showInfo = false),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInfoSection(
                    'goal',
                    'collect all 👑 crowns before running out of moves!',
                  ),
                  _buildInfoSection(
                    'swipe',
                    'swap adjacent gems to create matches of 3 or more',
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'power-ups',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildPowerUpInfo(
                    Icons.arrow_forward,
                    'horizontal rocket',
                    '4 in a row → clears entire row',
                  ),
                  _buildPowerUpInfo(
                    Icons.arrow_upward,
                    'vertical rocket',
                    '4 in a column → clears entire column',
                  ),
                  _buildPowerUpInfo(
                    Icons.air,
                    'propeller',
                    '2×2 square → flies to a crown & explodes',
                  ),
                  _buildPowerUpInfo(
                    null,
                    'bomb 💣',
                    'T or L shape → 3×3 explosion',
                  ),
                  const SizedBox(height: 12),
                  _buildInfoSection(
                    'tip',
                    'tap a power-up to activate it directly!',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFBA9EF7),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            content,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerUpInfo(IconData? icon, String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0xFF4a4a8a),
              borderRadius: BorderRadius.circular(6),
            ),
            child: icon != null
                ? Icon(icon, color: Colors.white, size: 18)
                : const Center(
                    child: Text('💣', style: TextStyle(fontSize: 14)),
                  ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for match results
class MatchResult {
  final List<Point<int>> cells;
  final bool isHorizontal;
  final bool isSquare;
  final int length;

  MatchResult({
    required this.cells,
    this.isHorizontal = false,
    this.isSquare = false,
    required this.length,
  });
}
