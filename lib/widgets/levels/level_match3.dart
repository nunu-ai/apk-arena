import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

enum _TileType {
  redTriangle,
  greenSquare,
  yellowCircle,
  blueDiamond,
  violetPentagon,
}

class LevelMatch3 extends LevelWidget {
  const LevelMatch3({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelMatch3> createState() => _LevelMatch3State();
}

class _LevelMatch3State extends State<LevelMatch3> {
  static const int _initialSize = 5;
  static const int _requiredStreak = 3;

  final Random _random = Random();

  int _currentRound = 0;
  int _gridSize = _initialSize;
  late List<List<_TileType>> _board;

  // Swipe gesture state
  int? _dragFromRow;
  int? _dragFromCol;
  Offset? _dragStartLocal;
  Offset? _dragLastLocal;
  int? _pendingTargetRow;
  int? _pendingTargetCol;

  @override
  void initState() {
    super.initState();
    _board = _generateBoard(_gridSize);
  }

  List<List<_TileType>> _generateBoard(int size) {
    final List<List<_TileType>> board = List.generate(
      size,
      (_) => List.generate(size, (_) => _randomTile()),
    );
    // Avoid immediate matches at start by re-rolling conflicting cells
    for (int r = 0; r < size; r++) {
      for (int c = 0; c < size; c++) {
        while (_wouldCreateImmediateRun(board, r, c)) {
          board[r][c] = _randomTile();
        }
      }
    }
    return board;
  }

  _TileType _randomTile() {
    final values = _TileType.values;
    return values[_random.nextInt(values.length)];
  }

  bool _wouldCreateImmediateRun(List<List<_TileType>> board, int r, int c) {
    final t = board[r][c];
    // Check left two
    if (c >= 2 && board[r][c - 1] == t && board[r][c - 2] == t) return true;
    // Check up two
    if (r >= 2 && board[r - 1][c] == t && board[r - 2][c] == t) return true;
    return false;
  }

  // Swipe handling
  void _onPanStart(int row, int col, DragStartDetails details) {
    _dragFromRow = row;
    _dragFromCol = col;
    _dragStartLocal = details.localPosition;
    _dragLastLocal = null;
    _pendingTargetRow = null;
    _pendingTargetCol = null;
  }

  void _onPanUpdate(int row, int col, DragUpdateDetails details) {
    if (_dragFromRow != row || _dragFromCol != col) return;
    if (_dragStartLocal == null) return;

    _dragLastLocal = details.localPosition;
    final Offset delta = _dragLastLocal! - _dragStartLocal!;
    const double threshold = 18; // px threshold to trigger swap
    if (delta.distance < threshold) {
      _pendingTargetRow = null;
      _pendingTargetCol = null;
      return;
    }

    int targetRow = row;
    int targetCol = col;
    if (delta.dx.abs() > delta.dy.abs()) {
      // Horizontal
      targetCol = delta.dx > 0 ? col + 1 : col - 1;
    } else {
      // Vertical
      targetRow = delta.dy > 0 ? row + 1 : row - 1;
    }

    if (targetRow < 0 ||
        targetRow >= _gridSize ||
        targetCol < 0 ||
        targetCol >= _gridSize) {
      _pendingTargetRow = null;
      _pendingTargetCol = null;
      return;
    }

    // Store intended target; actual swap occurs on pan end
    _pendingTargetRow = targetRow;
    _pendingTargetCol = targetCol;
  }

  void _onPanEnd(int row, int col, DragEndDetails details) {
    final int? fromRow = _dragFromRow;
    final int? fromCol = _dragFromCol;
    final int? toRow = _pendingTargetRow;
    final int? toCol = _pendingTargetCol;

    if (fromRow != null && fromCol != null && toRow != null && toCol != null) {
      _trySwap(fromRow, fromCol, toRow, toCol);
    } else {
      _resetDrag();
    }
  }

  void _onPanCancel() {
    _resetDrag();
  }

  void _resetDrag() {
    _dragFromRow = null;
    _dragFromCol = null;
    _dragStartLocal = null;
    _dragLastLocal = null;
    _pendingTargetRow = null;
    _pendingTargetCol = null;
  }

  void _trySwap(int r1, int c1, int r2, int c2) {
    setState(() {
      _swap(r1, c1, r2, c2);
    });
    // Only legal if the swap creates a match that involves one of the swapped tiles
    final bool createsMatch = _isCellInMatch(r1, c1) || _isCellInMatch(r2, c2);
    if (createsMatch) {
      // Successful move: increase streak and grid size, regenerate board
      if (_currentRound + 1 >= _requiredStreak) {
        widget.onComplete(true);
        return;
      }
      setState(() {
        _currentRound += 1;
        _gridSize += 1;
        _board = _generateBoard(_gridSize);
        _resetDrag();
      });
    } else {
      // Wrong move: revert swap and reset progress to start again
      setState(() {
        _swap(r1, c1, r2, c2);
        _currentRound = 0;
        _gridSize = _initialSize;
        _board = _generateBoard(_gridSize);
        _resetDrag();
      });
    }
  }

  void _swap(int r1, int c1, int r2, int c2) {
    final t = _board[r1][c1];
    _board[r1][c1] = _board[r2][c2];
    _board[r2][c2] = t;
  }

  // Note: We keep the board-wide match scan removed for now;
  // legality relies on matches involving the swapped tiles.

  bool _isCellInMatch(int row, int col) {
    final _TileType type = _board[row][col];

    // Horizontal run length including (row, col)
    int count = 1;
    int c = col - 1;
    while (c >= 0 && _board[row][c] == type) {
      count++;
      c--;
    }
    c = col + 1;
    while (c < _gridSize && _board[row][c] == type) {
      count++;
      c++;
    }
    if (count >= 3) return true;

    // Vertical run length including (row, col)
    count = 1;
    int r = row - 1;
    while (r >= 0 && _board[r][col] == type) {
      count++;
      r--;
    }
    r = row + 1;
    while (r < _gridSize && _board[r][col] == type) {
      count++;
      r++;
    }
    return count >= 3;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Text(
                    'streak: ${_currentRound} / $_requiredStreak',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final double gridSizePx =
                        min(constraints.maxWidth, constraints.maxHeight) * 0.9;
                    return SizedBox(
                      width: gridSizePx,
                      height: gridSizePx,
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: _gridSize,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                        ),
                        itemCount: _gridSize * _gridSize,
                        itemBuilder: (context, index) {
                          final row = index ~/ _gridSize;
                          final col = index % _gridSize;
                          final tile = _board[row][col];
                          return _TileButton(
                            tile: tile,
                            onPanStart: (details) =>
                                _onPanStart(row, col, details),
                            onPanUpdate: (details) =>
                                _onPanUpdate(row, col, details),
                            onPanEnd: (details) => _onPanEnd(row, col, details),
                            onPanCancel: _onPanCancel,
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _TileButton extends StatelessWidget {
  final _TileType tile;
  final void Function(DragStartDetails) onPanStart;
  final void Function(DragUpdateDetails) onPanUpdate;
  final void Function(DragEndDetails) onPanEnd;
  final VoidCallback onPanCancel;

  const _TileButton({
    required this.tile,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanUpdate: onPanUpdate,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      child: Container(
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: _TileIcon(tile: tile, size: 26),
      ),
    );
  }
}

class _TileIcon extends StatelessWidget {
  final _TileType tile;
  final double size;
  const _TileIcon({required this.tile, required this.size});

  @override
  Widget build(BuildContext context) {
    switch (tile) {
      case _TileType.redTriangle:
        return CustomPaint(
          size: Size.square(size),
          painter: _TrianglePainter(color: Colors.redAccent),
        );
      case _TileType.greenSquare:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.greenAccent.shade400,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      case _TileType.yellowCircle:
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFFFFEB3B),
            shape: BoxShape.circle,
          ),
        );
      case _TileType.blueDiamond:
        return Transform.rotate(
          angle: pi / 4,
          child: Container(
            width: size * 0.9,
            height: size * 0.9,
            decoration: BoxDecoration(
              color: Colors.lightBlueAccent,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      case _TileType.violetPentagon:
        return CustomPaint(
          size: Size.square(size),
          painter: _PentagonPainter(color: Colors.purpleAccent),
        );
    }
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(0, size.height)
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PentagonPainter extends CustomPainter {
  final Color color;
  _PentagonPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = color;
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    // Regular-ish pentagon points
    path.moveTo(w * 0.5, 0);
    path.lineTo(w, h * 0.4);
    path.lineTo(w * 0.8, h);
    path.lineTo(w * 0.2, h);
    path.lineTo(0, h * 0.4);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
