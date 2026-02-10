import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// Pipe types and their connections at each rotation
// Connections: 0=top, 1=right, 2=bottom, 3=left
enum PipeType {
  straight, // connects 2 opposite sides
  elbow,    // connects 2 adjacent sides
  tee,      // connects 3 sides
  cross,    // connects all 4 sides
  end,      // connects 1 side (dead-end/cap)
}

class PipeCell {
  PipeType type;
  int rotation; // 0-3 (number of 90° clockwise rotations)
  bool connected = false;

  PipeCell(this.type, this.rotation);

  Set<int> get openSides {
    Set<int> base;
    switch (type) {
      case PipeType.straight:
        base = {0, 2};
        break;
      case PipeType.elbow:
        base = {0, 1};
        break;
      case PipeType.tee:
        base = {0, 1, 3};
        break;
      case PipeType.cross:
        base = {0, 1, 2, 3};
        break;
      case PipeType.end:
        base = {0};
        break;
    }
    return base.map((s) => (s + rotation) % 4).toSet();
  }

  void rotate() {
    rotation = (rotation + 1) % 4;
  }
}

class LevelPipePuzzle extends LevelWidget {
  const LevelPipePuzzle({super.key, required super.onComplete});

  @override
  State<LevelPipePuzzle> createState() => _LevelPipePuzzleState();
}

class _LevelPipePuzzleState extends State<LevelPipePuzzle> {
  static const int _rows = 6;
  static const int _cols = 6;

  late List<List<PipeCell>> _grid;
  late int _sourceRow, _sourceCol;
  late int _drainRow, _drainCol;
  int _moves = 0;
  bool _done = false;

  static const _dr = [-1, 0, 1, 0]; // top, right, bottom, left
  static const _dc = [0, 1, 0, -1];

  @override
  void initState() {
    super.initState();
    _generatePuzzle();
  }

  void _generatePuzzle() {
    final rng = Random();
    _sourceRow = 0;
    _sourceCol = 0;
    _drainRow = _rows - 1;
    _drainCol = _cols - 1;

    // Build a solvable path from source to drain using random walk
    // First create a solution grid, then scramble rotations
    _grid = List.generate(
      _rows,
      (_) => List.generate(_cols, (_) => PipeCell(PipeType.end, 0)),
    );

    // Random walk from source to drain
    final visited = <String>{};
    final path = <List<int>>[];
    _buildPath(_sourceRow, _sourceCol, _drainRow, _drainCol, visited, path, rng);

    // For each cell in path, determine pipe type based on connections
    for (int i = 0; i < path.length; i++) {
      final r = path[i][0], c = path[i][1];
      final connections = <int>{};

      if (i > 0) {
        final pr = path[i - 1][0], pc = path[i - 1][1];
        connections.add(_directionTo(r, c, pr, pc));
      }
      if (i < path.length - 1) {
        final nr = path[i + 1][0], nc = path[i + 1][1];
        connections.add(_directionTo(r, c, nr, nc));
      }

      _setPipeFromConnections(r, c, connections);
    }

    // Fill remaining cells with random pipes
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (!path.any((p) => p[0] == r && p[1] == c)) {
          final types = [PipeType.straight, PipeType.elbow, PipeType.tee, PipeType.end];
          _grid[r][c] = PipeCell(types[rng.nextInt(types.length)], rng.nextInt(4));
        }
      }
    }

    // Save correct rotations then scramble
    final correctRotations = List.generate(
      _rows,
      (r) => List.generate(_cols, (c) => _grid[r][c].rotation),
    );

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final scramble = rng.nextInt(3) + 1; // 1-3 extra rotations
        _grid[r][c].rotation = (correctRotations[r][c] + scramble) % 4;
      }
    }

    _updateConnected();
  }

  bool _buildPath(int r, int c, int dr, int dc, Set<String> visited, List<List<int>> path, Random rng) {
    if (r < 0 || r >= _rows || c < 0 || c >= _cols) return false;
    if (visited.contains('$r,$c')) return false;

    visited.add('$r,$c');
    path.add([r, c]);

    if (r == dr && c == dc) return true;

    // Try directions in random order, biased toward drain
    final dirs = [0, 1, 2, 3];
    dirs.sort((a, b) {
      final ar = r + _dr[a], ac = c + _dc[a];
      final br = r + _dr[b], bc = c + _dc[b];
      final da = (ar - dr).abs() + (ac - dc).abs();
      final db = (br - dr).abs() + (bc - dc).abs();
      return da.compareTo(db) + rng.nextInt(3) - 1;
    });

    for (final d in dirs) {
      final nr = r + _dr[d], nc = c + _dc[d];
      if (_buildPath(nr, nc, dr, dc, visited, path, rng)) return true;
    }

    path.removeLast();
    visited.remove('$r,$c');
    return false;
  }

  int _directionTo(int fromR, int fromC, int toR, int toC) {
    if (toR < fromR) return 0; // top
    if (toC > fromC) return 1; // right
    if (toR > fromR) return 2; // bottom
    return 3; // left
  }

  void _setPipeFromConnections(int r, int c, Set<int> connections) {
    if (connections.length == 1) {
      _grid[r][c] = PipeCell(PipeType.end, connections.first);
    } else if (connections.length == 2) {
      final sorted = connections.toList()..sort();
      if ((sorted[1] - sorted[0]) == 2) {
        // Opposite sides -> straight
        _grid[r][c] = PipeCell(PipeType.straight, sorted[0]);
      } else {
        // Adjacent sides -> elbow
        // Find rotation: base elbow connects 0,1 (top,right)
        // We need to find rotation so that base+rot = our connections
        for (int rot = 0; rot < 4; rot++) {
          final test = {rot % 4, (1 + rot) % 4};
          if (test.containsAll(connections)) {
            _grid[r][c] = PipeCell(PipeType.elbow, rot);
            break;
          }
        }
      }
    } else if (connections.length == 3) {
      // Tee: base connects 0,1,3 (top,right,left)
      final missing = {0, 1, 2, 3}.difference(connections).first;
      // base tee is missing side 2 (bottom), rotation = missing - 2
      _grid[r][c] = PipeCell(PipeType.tee, (missing + 2) % 4);
    } else {
      _grid[r][c] = PipeCell(PipeType.cross, 0);
    }
  }

  void _updateConnected() {
    // BFS from source
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        _grid[r][c].connected = false;
      }
    }

    final queue = <List<int>>[];
    _grid[_sourceRow][_sourceCol].connected = true;
    queue.add([_sourceRow, _sourceCol]);

    while (queue.isNotEmpty) {
      final cur = queue.removeAt(0);
      final r = cur[0], c = cur[1];
      final cell = _grid[r][c];

      for (final side in cell.openSides) {
        final nr = r + _dr[side], nc = c + _dc[side];
        if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
        final neighbor = _grid[nr][nc];
        if (neighbor.connected) continue;
        final oppositeSide = (side + 2) % 4;
        if (neighbor.openSides.contains(oppositeSide)) {
          neighbor.connected = true;
          queue.add([nr, nc]);
        }
      }
    }
  }

  void _onTap(int r, int c) {
    if (_done) return;
    setState(() {
      _grid[r][c].rotate();
      _moves++;
      _updateConnected();
      HapticFeedback.lightImpact();

      if (_grid[_drainRow][_drainCol].connected) {
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
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
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
          const Text(
            'tap to rotate',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
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
            border: Border.all(color: NunuColors.primaryDark.withOpacity(0.4), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_rows, (r) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_cols, (c) {
                    return SizedBox(
                      width: cellSize,
                      height: cellSize,
                      child: _buildCell(r, c, cellSize),
                    );
                  }),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final cell = _grid[r][c];
    final isSource = r == _sourceRow && c == _sourceCol;
    final isDrain = r == _drainRow && c == _drainCol;
    final color = cell.connected ? NunuColors.infoMain : NunuColors.primaryDark.withOpacity(0.5);

    return GestureDetector(
      onTap: () => _onTap(r, c),
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: isSource
              ? NunuColors.successMain.withOpacity(0.15)
              : isDrain
                  ? NunuColors.errorMain.withOpacity(0.15)
                  : NunuColors.backgroundPaper.withOpacity(0.3),
          border: Border.all(
            color: NunuColors.primaryDark.withOpacity(0.2),
            width: 0.5,
          ),
        ),
        child: CustomPaint(
          painter: _PipePainter(cell, color, isSource, isDrain),
        ),
      ),
    );
  }
}

class _PipePainter extends CustomPainter {
  final PipeCell cell;
  final Color color;
  final bool isSource;
  final bool isDrain;

  _PipePainter(this.cell, this.color, this.isSource, this.isDrain);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = size.width * 0.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final sides = cell.openSides;

    // Draw pipes from center to each open side
    for (final side in sides) {
      late Offset end;
      switch (side) {
        case 0: end = Offset(center.dx, 0); break;
        case 1: end = Offset(size.width, center.dy); break;
        case 2: end = Offset(center.dx, size.height); break;
        case 3: end = Offset(0, center.dy); break;
      }
      canvas.drawLine(center, end, paint);
    }

    // Draw center dot
    final dotPaint = Paint()..color = color..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.12, dotPaint);

    // Draw source/drain markers
    if (isSource || isDrain) {
      final markerPaint = Paint()
        ..color = isSource ? NunuColors.successMain : NunuColors.errorMain
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, size.width * 0.18, markerPaint);

      final innerPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;
      canvas.drawCircle(center, size.width * 0.08, innerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PipePainter old) =>
      old.cell.rotation != cell.rotation || old.cell.connected != cell.connected;
}
