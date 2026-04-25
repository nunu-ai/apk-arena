import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

enum _GemType { ember, leaf, tide, sun, orchid, frost }

enum _PowerUpType { none, rocketRow, rocketColumn, bomb, prism }

enum _ObstacleType { none, crate, ice }

class _BoardCell {
  _BoardCell({
    required this.gem,
    this.powerUp = _PowerUpType.none,
    this.obstacle = _ObstacleType.none,
    this.obstacleHits = 0,
  });

  _GemType gem;
  _PowerUpType powerUp;
  _ObstacleType obstacle;
  int obstacleHits;

  bool get isCrate => obstacle == _ObstacleType.crate;
  bool get isMovable => obstacle != _ObstacleType.crate;

  _BoardCell copy() {
    return _BoardCell(
      gem: gem,
      powerUp: powerUp,
      obstacle: obstacle,
      obstacleHits: obstacleHits,
    );
  }
}

class _StageConfig {
  const _StageConfig({
    required this.label,
    required this.threshold,
    required this.mask,
    required this.unlockedPowerUps,
    this.crates = 0,
    this.ice = 0,
  });

  final String label;
  final int threshold;
  final List<String> mask;
  final Set<_PowerUpType> unlockedPowerUps;
  final int crates;
  final int ice;

  int get rows => mask.length;
  int get cols => mask.first.length;
}

class _MatchGroup {
  const _MatchGroup({
    required this.cells,
    required this.horizontal,
  });

  final List<Point<int>> cells;
  final bool horizontal;
}

class _PowerUpSpawn {
  const _PowerUpSpawn({
    required this.row,
    required this.col,
    required this.powerUp,
  });

  final int row;
  final int col;
  final _PowerUpType powerUp;
}

class LevelCascadeProtocol extends LevelWidget {
  const LevelCascadeProtocol({super.key, required super.onComplete});

  @override
  State<LevelCascadeProtocol> createState() => _LevelCascadeProtocolState();
}

class _LevelCascadeProtocolState extends State<LevelCascadeProtocol> {
  static const Duration _settleDelay = Duration(milliseconds: 120);
  static const double _gridGap = 4;
  static const double _swipeThreshold = 18;
  static const int _maxBenchmarkScore = 240000;

  static const List<_StageConfig> _stages = [
    _StageConfig(
      label: '1',
      threshold: 0,
      mask: [
        '######',
        '######',
        '######',
        '######',
        '######',
        '######',
      ],
      unlockedPowerUps: <_PowerUpType>{},
    ),
    _StageConfig(
      label: '2',
      threshold: 2500,
      mask: [
        '#######',
        '#######',
        '#######',
        '#######',
        '#######',
        '#######',
      ],
      unlockedPowerUps: <_PowerUpType>{},
    ),
    _StageConfig(
      label: '3',
      threshold: 6500,
      mask: [
        '#######',
        '#######',
        '#######',
        '#######',
        '#######',
        '#######',
        '#######',
      ],
      unlockedPowerUps: <_PowerUpType>{},
      ice: 5,
    ),
    _StageConfig(
      label: '4',
      threshold: 12000,
      mask: [
        '########',
        '########',
        '########',
        '########',
        '########',
        '########',
        '########',
      ],
      unlockedPowerUps: {
        _PowerUpType.rocketRow,
        _PowerUpType.rocketColumn,
      },
      ice: 8,
    ),
    _StageConfig(
      label: '5',
      threshold: 19000,
      mask: [
        '########',
        '########',
        '########',
        '########',
        '########',
        '########',
        '########',
        '########',
      ],
      unlockedPowerUps: {
        _PowerUpType.rocketRow,
        _PowerUpType.rocketColumn,
      },
      crates: 5,
      ice: 8,
    ),
    _StageConfig(
      label: '6',
      threshold: 27500,
      mask: [
        '.#######.',
        '#########',
        '#########',
        '#########',
        '#########',
        '#########',
        '#########',
        '.#######.',
      ],
      unlockedPowerUps: {
        _PowerUpType.rocketRow,
        _PowerUpType.rocketColumn,
        _PowerUpType.bomb,
      },
      crates: 8,
      ice: 10,
    ),
    _StageConfig(
      label: '7',
      threshold: 38000,
      mask: [
        '.#######.',
        '#########',
        '#########',
        '###...###',
        '#########',
        '#########',
        '#########',
        '.#######.',
      ],
      unlockedPowerUps: {
        _PowerUpType.rocketRow,
        _PowerUpType.rocketColumn,
        _PowerUpType.bomb,
      },
      crates: 10,
      ice: 12,
    ),
    _StageConfig(
      label: '8',
      threshold: 50000,
      mask: [
        '..######..',
        '.########.',
        '##########',
        '####..####',
        '##########',
        '##########',
        '####..####',
        '##########',
        '.########.',
      ],
      unlockedPowerUps: {
        _PowerUpType.rocketRow,
        _PowerUpType.rocketColumn,
        _PowerUpType.bomb,
      },
      crates: 12,
      ice: 14,
    ),
    _StageConfig(
      label: '9',
      threshold: 65000,
      mask: [
        '.########.',
        '##########',
        '##########',
        '###....###',
        '##########',
        '##########',
        '###....###',
        '##########',
        '##########',
        '.########.',
      ],
      unlockedPowerUps: {
        _PowerUpType.rocketRow,
        _PowerUpType.rocketColumn,
        _PowerUpType.bomb,
        _PowerUpType.prism,
      },
      crates: 14,
      ice: 16,
    ),
    _StageConfig(
      label: '10',
      threshold: 84000,
      mask: [
        '..######..',
        '.########.',
        '##########',
        '##########',
        '###.##.###',
        '##########',
        '##########',
        '###.##.###',
        '##########',
        '.########.',
      ],
      unlockedPowerUps: {
        _PowerUpType.rocketRow,
        _PowerUpType.rocketColumn,
        _PowerUpType.bomb,
        _PowerUpType.prism,
      },
      crates: 18,
      ice: 18,
    ),
  ];

  final Random _random = Random();

  late List<List<_BoardCell?>> _board;
  late DateTime _startedAt;
  Timer? _clockTimer;

  int _stageIndex = 0;
  int _score = 0;
  int _highestStageReached = 1;
  String _statusText = 'swipe to swap';
  bool _isBusy = false;

  int? _dragStartRow;
  int? _dragStartCol;
  Offset? _dragStartOffset;
  int? _pendingTargetRow;
  int? _pendingTargetCol;

  _StageConfig get _stage => _stages[_stageIndex];

  @override
  void initState() {
    super.initState();
    widget.registerTimeoutBuilder(_buildOutcome);
    _startedAt = DateTime.now();
    _board = _generateBoardForStage(_stage);
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    widget.clearTimeoutBuilder();
    super.dispose();
  }

  LevelOutcome _buildOutcome() {
    final score = sqrt((_score / _maxBenchmarkScore).clamp(0.0, 1.0));
    return LevelOutcome(
      score: score,
      metrics: {
        'score': _score,
        'stage_reached': _highestStageReached,
      },
    );
  }

  List<List<_BoardCell?>> _generateBoardForStage(_StageConfig stage) {
    late List<List<_BoardCell?>> candidate;
    do {
      candidate = List.generate(
        stage.rows,
        (_) => List<_BoardCell?>.filled(stage.cols, null),
      );
      for (int row = 0; row < stage.rows; row++) {
        for (int col = 0; col < stage.cols; col++) {
          if (!_isActiveMask(stage, row, col)) continue;
          var gem = _randomGem();
          while (_createsImmediateMatch(
            board: candidate,
            row: row,
            col: col,
            gem: gem,
            stage: stage,
          )) {
            gem = _randomGem();
          }
          candidate[row][col] = _BoardCell(gem: gem);
        }
      }
      _seedObstacles(candidate, stage);
    } while (_findMatchGroups(candidate).isNotEmpty || !_hasAnyLegalMove(candidate, stage));
    return candidate;
  }

  void _seedObstacles(List<List<_BoardCell?>> board, _StageConfig stage) {
    final candidates = <Point<int>>[];
    for (int row = 0; row < stage.rows; row++) {
      for (int col = 0; col < stage.cols; col++) {
        if (board[row][col] != null) {
          candidates.add(Point<int>(row, col));
        }
      }
    }
    candidates.shuffle(_random);

    int cratePlaced = 0;
    int icePlaced = 0;
    for (final point in candidates) {
      if (cratePlaced < stage.crates) {
        final cell = board[point.x][point.y];
        if (cell != null) {
          cell.obstacle = _ObstacleType.crate;
          cell.obstacleHits = 1;
          cell.powerUp = _PowerUpType.none;
          cratePlaced++;
          continue;
        }
      }
      if (icePlaced < stage.ice) {
        final cell = board[point.x][point.y];
        if (cell != null && !cell.isCrate) {
          cell.obstacle = _ObstacleType.ice;
          cell.obstacleHits = 1;
          icePlaced++;
        }
      }
      if (cratePlaced >= stage.crates && icePlaced >= stage.ice) {
        break;
      }
    }
  }

  bool _createsImmediateMatch({
    required List<List<_BoardCell?>> board,
    required int row,
    required int col,
    required _GemType gem,
    required _StageConfig stage,
  }) {
    if (col >= 2 &&
        _isActiveMask(stage, row, col - 1) &&
        _isActiveMask(stage, row, col - 2) &&
        board[row][col - 1]?.gem == gem &&
        board[row][col - 2]?.gem == gem) {
      return true;
    }
    if (row >= 2 &&
        _isActiveMask(stage, row - 1, col) &&
        _isActiveMask(stage, row - 2, col) &&
        board[row - 1][col]?.gem == gem &&
        board[row - 2][col]?.gem == gem) {
      return true;
    }
    return false;
  }

  _GemType _randomGem() {
    final values = _GemType.values;
    return values[_random.nextInt(values.length)];
  }

  bool _isActiveMask(_StageConfig stage, int row, int col) {
    if (row < 0 || row >= stage.rows || col < 0 || col >= stage.cols) {
      return false;
    }
    return stage.mask[row][col] == '#';
  }

  bool _isPlayableCell(int row, int col) {
    return row >= 0 &&
        row < _board.length &&
        col >= 0 &&
        col < _board[row].length &&
        _board[row][col] != null;
  }

  void _handlePanStart(DragStartDetails details, double cellSize) {
    if (_isBusy) return;
    final cell = _cellFromOffset(details.localPosition, cellSize);
    if (cell == null) return;
    final boardCell = _board[cell.x][cell.y];
    if (boardCell == null || !boardCell.isMovable) return;

    _dragStartRow = cell.x;
    _dragStartCol = cell.y;
    _dragStartOffset = details.localPosition;
    _pendingTargetRow = null;
    _pendingTargetCol = null;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_dragStartOffset == null ||
        _dragStartRow == null ||
        _dragStartCol == null) {
      return;
    }

    final delta = details.localPosition - _dragStartOffset!;
    if (delta.distance < _swipeThreshold) {
      _pendingTargetRow = null;
      _pendingTargetCol = null;
      return;
    }

    int targetRow = _dragStartRow!;
    int targetCol = _dragStartCol!;

    if (delta.dx.abs() > delta.dy.abs()) {
      targetCol += delta.dx > 0 ? 1 : -1;
    } else {
      targetRow += delta.dy > 0 ? 1 : -1;
    }

    if (!_isPlayableCell(targetRow, targetCol)) {
      _pendingTargetRow = null;
      _pendingTargetCol = null;
      return;
    }

    final targetCell = _board[targetRow][targetCol];
    if (targetCell == null || !targetCell.isMovable) {
      _pendingTargetRow = null;
      _pendingTargetCol = null;
      return;
    }

    _pendingTargetRow = targetRow;
    _pendingTargetCol = targetCol;
  }

  void _handlePanEnd(DragEndDetails details) {
    final fromRow = _dragStartRow;
    final fromCol = _dragStartCol;
    final toRow = _pendingTargetRow;
    final toCol = _pendingTargetCol;
    _resetDrag();

    if (fromRow == null || fromCol == null || toRow == null || toCol == null) {
      return;
    }

    unawaited(_trySwap(fromRow, fromCol, toRow, toCol));
  }

  void _resetDrag() {
    _dragStartRow = null;
    _dragStartCol = null;
    _dragStartOffset = null;
    _pendingTargetRow = null;
    _pendingTargetCol = null;
  }

  Point<int>? _cellFromOffset(Offset local, double cellSize) {
    final pitch = cellSize + _gridGap;
    final col = (local.dx / pitch).floor();
    final row = (local.dy / pitch).floor();
    if (!_isPlayableCell(row, col)) return null;

    final localX = local.dx - (col * pitch);
    final localY = local.dy - (row * pitch);
    if (localX > cellSize || localY > cellSize) return null;

    return Point<int>(row, col);
  }

  Future<void> _trySwap(int rowA, int colA, int rowB, int colB) async {
    if (_isBusy) return;

    setState(() {
      _isBusy = true;
      _swap(rowA, colA, rowB, colB);
    });

    await Future.delayed(_settleDelay);

    final specialClear = _buildSpecialSwapClear(rowA, colA, rowB, colB);
    final groups = _findMatchGroups(_board);

    if (specialClear.isEmpty && groups.isEmpty) {
      setState(() {
        _swap(rowA, colA, rowB, colB);
        _isBusy = false;
        _statusText = 'no match';
      });
      return;
    }

    int cascade = 0;
    Point<int> preferredSpawn = Point<int>(rowB, colB);
    Set<Point<int>> pendingSpecialClear = specialClear;

    while (true) {
      final matchGroups = _findMatchGroups(_board);
      final matchedCells = _groupsToCellSet(matchGroups);
      if (matchedCells.isEmpty && pendingSpecialClear.isEmpty) {
        break;
      }

      cascade++;
      final spawn = _determinePowerUpSpawn(
        groups: matchGroups,
        matchedCells: matchedCells,
        preferred: preferredSpawn,
      );

      final cleared = <Point<int>>{...matchedCells, ...pendingSpecialClear};
      for (final point in cleared.toList()) {
        final cell = _board[point.x][point.y];
        if (cell == null || cell.powerUp == _PowerUpType.none) continue;
        cleared.addAll(_cellsFromPowerUp(point.x, point.y, cell.powerUp, cell.gem));
      }

      _damageAdjacentCrates(cleared);

      int removed = 0;
      for (final point in cleared) {
        final cell = _board[point.x][point.y];
        if (cell == null || cell.isCrate) continue;
        if (cell.obstacle == _ObstacleType.ice) {
          cell.obstacle = _ObstacleType.none;
          cell.obstacleHits = 0;
          continue;
        }
        _board[point.x][point.y] = null;
        removed++;
      }

      if (spawn != null && _board[spawn.row][spawn.col] == null) {
        _board[spawn.row][spawn.col] = _BoardCell(
          gem: _randomGem(),
          powerUp: spawn.powerUp,
        );
      }

      final gained = removed * 35 * cascade;
      _score += gained;

      await Future.delayed(_settleDelay);
      _collapseBoard();
      _fillBoard();
      await Future.delayed(_settleDelay);

      pendingSpecialClear = {};
      preferredSpawn = Point<int>(-1, -1);
      setState(() {
        _statusText = cascade > 1 ? 'cascade x$cascade' : '+$gained';
      });
    }

    _updateStageProgression();
    _ensureBoardHasMove();

    setState(() {
      _isBusy = false;
    });
  }

  void _swap(int rowA, int colA, int rowB, int colB) {
    final temp = _board[rowA][colA];
    _board[rowA][colA] = _board[rowB][colB];
    _board[rowB][colB] = temp;
  }

  Set<Point<int>> _buildSpecialSwapClear(
    int rowA,
    int colA,
    int rowB,
    int colB,
  ) {
    final first = _board[rowA][colA];
    final second = _board[rowB][colB];
    if (first == null || second == null) return {};

    if (first.powerUp == _PowerUpType.prism ||
        second.powerUp == _PowerUpType.prism) {
      final targetGem =
          first.powerUp == _PowerUpType.prism ? second.gem : first.gem;
      final clear = _allOfGem(targetGem);
      clear
        ..add(Point<int>(rowA, colA))
        ..add(Point<int>(rowB, colB));
      return clear;
    }

    if (first.powerUp == _PowerUpType.bomb && second.powerUp == _PowerUpType.bomb) {
      return {
        ..._squareBlast(rowA, colA, radius: 2),
        ..._squareBlast(rowB, colB, radius: 2),
      };
    }

    if (first.powerUp != _PowerUpType.none) {
      return _cellsFromPowerUp(rowA, colA, first.powerUp, first.gem)
        ..add(Point<int>(rowA, colA))
        ..add(Point<int>(rowB, colB));
    }

    if (second.powerUp != _PowerUpType.none) {
      return _cellsFromPowerUp(rowB, colB, second.powerUp, second.gem)
        ..add(Point<int>(rowA, colA))
        ..add(Point<int>(rowB, colB));
    }

    return {};
  }

  Set<Point<int>> _cellsFromPowerUp(
    int row,
    int col,
    _PowerUpType powerUp,
    _GemType gem,
  ) {
    return switch (powerUp) {
      _PowerUpType.none => <Point<int>>{},
      _PowerUpType.rocketRow => _rowClear(row),
      _PowerUpType.rocketColumn => _columnClear(col),
      _PowerUpType.bomb => _squareBlast(row, col, radius: 1),
      _PowerUpType.prism => _allOfGem(gem),
    };
  }

  Set<Point<int>> _rowClear(int row) {
    final points = <Point<int>>{};
    for (int col = 0; col < _board[row].length; col++) {
      if (_board[row][col] != null) {
        points.add(Point<int>(row, col));
      }
    }
    return points;
  }

  Set<Point<int>> _columnClear(int col) {
    final points = <Point<int>>{};
    for (int row = 0; row < _board.length; row++) {
      if (col < _board[row].length && _board[row][col] != null) {
        points.add(Point<int>(row, col));
      }
    }
    return points;
  }

  Set<Point<int>> _squareBlast(int centerRow, int centerCol, {required int radius}) {
    final points = <Point<int>>{};
    for (int row = centerRow - radius; row <= centerRow + radius; row++) {
      for (int col = centerCol - radius; col <= centerCol + radius; col++) {
        if (_isPlayableCell(row, col)) {
          points.add(Point<int>(row, col));
        }
      }
    }
    return points;
  }

  Set<Point<int>> _allOfGem(_GemType gem) {
    final points = <Point<int>>{};
    for (int row = 0; row < _board.length; row++) {
      for (int col = 0; col < _board[row].length; col++) {
        final cell = _board[row][col];
        if (cell != null && cell.gem == gem && !cell.isCrate) {
          points.add(Point<int>(row, col));
        }
      }
    }
    return points;
  }

  void _damageAdjacentCrates(Set<Point<int>> cleared) {
    for (final point in cleared) {
      const directions = [
        Point<int>(1, 0),
        Point<int>(-1, 0),
        Point<int>(0, 1),
        Point<int>(0, -1),
      ];
      for (final direction in directions) {
        final row = point.x + direction.x;
        final col = point.y + direction.y;
        if (!_isPlayableCell(row, col)) continue;
        final cell = _board[row][col];
        if (cell == null || !cell.isCrate) continue;
        cell.obstacleHits -= 1;
        if (cell.obstacleHits <= 0) {
          _board[row][col] = null;
        }
      }
    }
  }

  List<_MatchGroup> _findMatchGroups(List<List<_BoardCell?>> board) {
    final groups = <_MatchGroup>[];

    for (int row = 0; row < board.length; row++) {
      int col = 0;
      while (col < board[row].length) {
        final cell = board[row][col];
        if (cell == null || cell.isCrate) {
          col++;
          continue;
        }
        int end = col + 1;
        while (end < board[row].length &&
            board[row][end] != null &&
            !board[row][end]!.isCrate &&
            board[row][end]!.gem == cell.gem) {
          end++;
        }
        if (end - col >= 3) {
          groups.add(
            _MatchGroup(
              horizontal: true,
              cells: List.generate(
                end - col,
                (index) => Point<int>(row, col + index),
              ),
            ),
          );
        }
        col = end;
      }
    }

    final maxCols = board.fold<int>(0, (sum, row) => max(sum, row.length));
    for (int col = 0; col < maxCols; col++) {
      int row = 0;
      while (row < board.length) {
        final cell = col < board[row].length ? board[row][col] : null;
        if (cell == null || cell.isCrate) {
          row++;
          continue;
        }
        int end = row + 1;
        while (end < board.length &&
            col < board[end].length &&
            board[end][col] != null &&
            !board[end][col]!.isCrate &&
            board[end][col]!.gem == cell.gem) {
          end++;
        }
        if (end - row >= 3) {
          groups.add(
            _MatchGroup(
              horizontal: false,
              cells: List.generate(
                end - row,
                (index) => Point<int>(row + index, col),
              ),
            ),
          );
        }
        row = end;
      }
    }

    return groups;
  }

  Set<Point<int>> _groupsToCellSet(List<_MatchGroup> groups) {
    final cells = <Point<int>>{};
    for (final group in groups) {
      cells.addAll(group.cells);
    }
    return cells;
  }

  _PowerUpSpawn? _determinePowerUpSpawn({
    required List<_MatchGroup> groups,
    required Set<Point<int>> matchedCells,
    required Point<int> preferred,
  }) {
    if (groups.isEmpty || _stage.unlockedPowerUps.isEmpty) {
      return null;
    }

    final intersections = <Point<int>, int>{};
    for (final group in groups) {
      for (final cell in group.cells) {
        intersections.update(cell, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    Point<int>? spawnPoint;
    if (matchedCells.contains(preferred)) {
      spawnPoint = preferred;
    } else {
      for (final point in matchedCells) {
        final cell = _board[point.x][point.y];
        if (cell != null && cell.obstacle != _ObstacleType.ice) {
          spawnPoint = point;
          break;
        }
      }
    }
    spawnPoint ??= matchedCells.first;

    _PowerUpType? chosen;
    final hasFive = groups.any((group) => group.cells.length >= 5);
    final hasIntersection = intersections.values.any((count) => count >= 2);
    final hasHorizontalFour = groups.any(
      (group) => group.horizontal && group.cells.length == 4,
    );
    final hasVerticalFour = groups.any(
      (group) => !group.horizontal && group.cells.length == 4,
    );

    if (hasFive && _stage.unlockedPowerUps.contains(_PowerUpType.prism)) {
      chosen = _PowerUpType.prism;
    } else if (hasIntersection &&
        _stage.unlockedPowerUps.contains(_PowerUpType.bomb)) {
      chosen = _PowerUpType.bomb;
    } else if (hasHorizontalFour &&
        _stage.unlockedPowerUps.contains(_PowerUpType.rocketRow)) {
      chosen = _PowerUpType.rocketRow;
    } else if (hasVerticalFour &&
        _stage.unlockedPowerUps.contains(_PowerUpType.rocketColumn)) {
      chosen = _PowerUpType.rocketColumn;
    }

    if (chosen == null) return null;
    return _PowerUpSpawn(
      row: spawnPoint.x,
      col: spawnPoint.y,
      powerUp: chosen,
    );
  }

  void _collapseBoard() {
    final stage = _stage;
    for (int col = 0; col < stage.cols; col++) {
      int segmentTop = 0;
      while (segmentTop < stage.rows) {
        int segmentBottom = segmentTop;
        while (segmentBottom < stage.rows) {
          if (_isActiveMask(stage, segmentBottom, col) &&
              _board[segmentBottom][col]?.isCrate == true) {
            break;
          }
          segmentBottom++;
        }
        _collapseSegment(col, segmentTop, segmentBottom - 1);
        segmentTop = segmentBottom + 1;
      }
    }
  }

  void _collapseSegment(int col, int startRow, int endRow) {
    if (endRow < startRow) return;
    final activeRows = <int>[];
    final stack = <_BoardCell>[];

    for (int row = startRow; row <= endRow; row++) {
      if (!_isActiveMask(_stage, row, col)) continue;
      activeRows.add(row);
    }

    for (final row in activeRows.reversed) {
      final cell = _board[row][col];
      if (cell != null && cell.isMovable) {
        stack.add(cell);
      }
    }

    int stackIndex = 0;
    for (final row in activeRows.reversed) {
      _board[row][col] =
          stackIndex < stack.length ? stack[stackIndex++] : null;
    }
  }

  void _fillBoard() {
    for (int row = 0; row < _stage.rows; row++) {
      for (int col = 0; col < _stage.cols; col++) {
        if (!_isActiveMask(_stage, row, col)) continue;
        if (_board[row][col] != null) continue;
        _board[row][col] = _BoardCell(gem: _randomGem());
      }
    }
  }

  void _updateStageProgression() {
    int nextStage = _stageIndex;
    for (int index = _stages.length - 1; index >= 0; index--) {
      if (_score >= _stages[index].threshold) {
        nextStage = index;
        break;
      }
    }

    if (nextStage == _stageIndex) return;

    _stageIndex = nextStage;
    _highestStageReached = max(_highestStageReached, _stageIndex + 1);
    _board = _generateBoardForStage(_stage);
    setState(() {
      _statusText = 'stage ${_stage.label}';
    });
  }

  void _ensureBoardHasMove() {
    if (_hasAnyLegalMove(_board, _stage)) {
      return;
    }
    setState(() {
      _statusText = 'reshuffle';
      _board = _generateBoardForStage(_stage);
    });
  }

  bool _hasAnyLegalMove(List<List<_BoardCell?>> board, _StageConfig stage) {
    for (int row = 0; row < stage.rows; row++) {
      for (int col = 0; col < stage.cols; col++) {
        final cell = board[row][col];
        if (cell == null || !cell.isMovable) continue;
        const directions = [Point<int>(0, 1), Point<int>(1, 0)];
        for (final direction in directions) {
          final nextRow = row + direction.x;
          final nextCol = col + direction.y;
          if (!_isActiveMask(stage, nextRow, nextCol)) continue;
          final nextCell = board[nextRow][nextCol];
          if (nextCell == null || !nextCell.isMovable) continue;

          final copy = _cloneBoard(board);
          final temp = copy[row][col];
          copy[row][col] = copy[nextRow][nextCol];
          copy[nextRow][nextCol] = temp;

          if (copy[row][col]!.powerUp != _PowerUpType.none ||
              copy[nextRow][nextCol]!.powerUp != _PowerUpType.none ||
              _findMatchGroups(copy).isNotEmpty) {
            return true;
          }
        }
      }
    }
    return false;
  }

  List<List<_BoardCell?>> _cloneBoard(List<List<_BoardCell?>> source) {
    return source
        .map((row) => row.map((cell) => cell?.copy()).toList())
        .toList();
  }

  String get _elapsedLabel {
    final elapsed = DateTime.now().difference(_startedAt);
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Color _gemColor(_GemType gem) {
    return switch (gem) {
      _GemType.ember => const Color(0xFFFF6B6B),
      _GemType.leaf => const Color(0xFF6EEB83),
      _GemType.tide => const Color(0xFF55A8FF),
      _GemType.sun => const Color(0xFFFFD166),
      _GemType.orchid => const Color(0xFFF187FF),
      _GemType.frost => const Color(0xFF7EE7F6),
    };
  }

  IconData _gemIcon(_GemType gem) {
    return switch (gem) {
      _GemType.ember => Icons.local_fire_department,
      _GemType.leaf => Icons.eco,
      _GemType.tide => Icons.water_drop,
      _GemType.sun => Icons.circle,
      _GemType.orchid => Icons.change_history,
      _GemType.frost => Icons.ac_unit,
    };
  }

  Widget _buildBoardCell(_BoardCell cell, double cellSize) {
    final color = _gemColor(cell.gem);
    final label = switch (cell.powerUp) {
      _PowerUpType.none => '',
      _PowerUpType.rocketRow => 'h',
      _PowerUpType.rocketColumn => 'v',
      _PowerUpType.bomb => 'b',
      _PowerUpType.prism => '*',
    };

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: cell.isCrate
              ? const Color(0xFF5C3B25)
              : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: cell.isCrate ? const Color(0xFFC48B5A) : color,
            width: 1.4,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (cell.isCrate)
              const Icon(Icons.inventory_2, color: Color(0xFFFFD9B3))
            else
              Icon(_gemIcon(cell.gem), color: color, size: cellSize * 0.38),
            if (cell.obstacle == _ObstacleType.ice && !cell.isCrate)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ),
            if (cell.powerUp != _PowerUpType.none && !cell.isCrate)
              Positioned(
                top: 3,
                right: 3,
                child: Container(
                  width: cellSize * 0.24,
                  height: cellSize * 0.24,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: cellSize * 0.14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardWidth = min(
          constraints.maxWidth,
          constraints.maxHeight * (_stage.cols / _stage.rows),
        );
        final cellSize =
            (boardWidth - ((_stage.cols - 1) * _gridGap)) / _stage.cols;
        final boardHeight =
            (_stage.rows * cellSize) + ((_stage.rows - 1) * _gridGap);

        return GestureDetector(
          onPanStart: (details) => _handlePanStart(details, cellSize),
          onPanUpdate: _handlePanUpdate,
          onPanEnd: _handlePanEnd,
          onPanCancel: _resetDrag,
          child: SizedBox(
            width: boardWidth,
            height: boardHeight,
            child: Column(
              children: List.generate(_stage.rows, (row) {
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: row == _stage.rows - 1 ? 0 : _gridGap,
                  ),
                  child: SizedBox(
                    height: cellSize,
                    child: Row(
                      children: List.generate(_stage.cols, (col) {
                        final cell = _board[row][col];
                        return Padding(
                          padding: EdgeInsets.only(
                            right: col == _stage.cols - 1 ? 0 : _gridGap,
                          ),
                          child: SizedBox(
                            width: cellSize,
                            height: cellSize,
                            child: cell == null
                                ? const SizedBox.shrink()
                                : _buildBoardCell(cell, cellSize),
                          ),
                        );
                      }),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '$label $value',
        style: const TextStyle(
          color: NunuColors.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nextThreshold = _stageIndex == _stages.length - 1
        ? null
        : _stages[_stageIndex + 1].threshold - _score;

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildBadge('score', '$_score'),
                  _buildBadge('stage', '${_stage.label}/10'),
                  _buildBadge('time', _elapsedLabel),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                nextThreshold == null ? _statusText : '$nextThreshold to next',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: Center(child: _buildBoard()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
