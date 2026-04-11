import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

enum _Gem { ruby, sapphire, emerald, topaz, amethyst }

class LevelLinkChain extends LevelWidget {
  const LevelLinkChain({super.key, required super.onComplete});

  @override
  State<LevelLinkChain> createState() => _LevelLinkChainState();
}

class _LevelLinkChainState extends State<LevelLinkChain> {
  static const int _rows = 8;
  static const int _cols = 7;
  static const int _totalMoves = 10;
  static const int _minScore = 50;

  final Random _rng = Random();
  late List<List<_Gem>> _board;
  final List<List<int>> _chain = []; // [row, col] pairs
  int _movesUsed = 0;
  int _score = 0;
  bool _isDragging = false;
  bool _completed = false;

  double _cellSize = 0;
  Offset _gridOrigin = Offset.zero;

  @override
  void initState() {
    super.initState();
    _board = _makeBoard();
  }

  List<List<_Gem>> _makeBoard() =>
      List.generate(_rows, (_) => List.generate(_cols, (_) => _randomGem()));

  _Gem _randomGem() => _Gem.values[_rng.nextInt(_Gem.values.length)];

  // ---------- gesture helpers ----------

  List<int>? _cellAt(Offset local) {
    final x = local.dx - _gridOrigin.dx;
    final y = local.dy - _gridOrigin.dy;
    final c = (x / _cellSize).floor();
    final r = (y / _cellSize).floor();
    if (r >= 0 && r < _rows && c >= 0 && c < _cols) return [r, c];
    return null;
  }

  bool _adjacent(List<int> a, List<int> b) {
    final dr = (a[0] - b[0]).abs();
    final dc = (a[1] - b[1]).abs();
    return dr <= 1 && dc <= 1 && !(dr == 0 && dc == 0);
  }

  bool _inChain(int r, int c) => _chain.any((e) => e[0] == r && e[1] == c);

  void _panStart(DragStartDetails d) {
    if (_completed || _movesUsed >= _totalMoves) return;
    final cell = _cellAt(d.localPosition);
    if (cell != null) {
      setState(() {
        _isDragging = true;
        _chain
          ..clear()
          ..add(cell);
      });
    }
  }

  void _panUpdate(DragUpdateDetails d) {
    if (!_isDragging || _chain.isEmpty) return;
    final cell = _cellAt(d.localPosition);
    if (cell == null) return;

    // allow backtracking
    if (_chain.length >= 2) {
      final prev = _chain[_chain.length - 2];
      if (prev[0] == cell[0] && prev[1] == cell[1]) {
        setState(() => _chain.removeLast());
        return;
      }
    }

    if (_inChain(cell[0], cell[1])) return;
    if (!_adjacent(_chain.last, cell)) return;

    final headType = _board[_chain.first[0]][_chain.first[1]];
    if (_board[cell[0]][cell[1]] != headType) return;

    setState(() => _chain.add(cell));
  }

  void _panEnd(DragEndDetails _) {
    if (!_isDragging) return;
    setState(() {
      _isDragging = false;
      if (_chain.length >= 2) {
        final len = _chain.length;
        _score += len * len;
        _movesUsed++;

        // collapse linked gems
        for (final c in _chain) {
          // shift column down
          final col = c[1];
          final row = c[0];
          for (int r = row; r > 0; r--) {
            _board[r][col] = _board[r - 1][col];
          }
          _board[0][col] = _randomGem();
        }

        if (_movesUsed >= _totalMoves && !_completed) {
          _completed = true;
          final ok = _score >= _minScore;
          Future.delayed(const Duration(milliseconds: 400), () {
            widget.onComplete(LevelOutcome(score: ok ? 1 : 0, metrics: {
              'score': _score,
            }));
          });
        }
      }
      _chain.clear();
    });
  }

  // ---------- colors ----------

  static const _gemColors = <_Gem, Color>{
    _Gem.ruby: Color(0xFFE53935),
    _Gem.sapphire: Color(0xFF1E88E5),
    _Gem.emerald: Color(0xFF43A047),
    _Gem.topaz: Color(0xFFFFB300),
    _Gem.amethyst: Color(0xFF8E24AA),
  };

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Stack(
          children: [
            // Grid fills the entire area
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) {
                  final maxW = box.maxWidth - 24;
                  final maxH = box.maxHeight - 60; // reserve top for HUD
                  _cellSize = min(maxW / _cols, maxH / _rows);
                  final gridW = _cellSize * _cols;
                  final gridH = _cellSize * _rows;
                  _gridOrigin = Offset(
                    (box.maxWidth - gridW) / 2,
                    60 + (box.maxHeight - 60 - gridH) / 2,
                  );

                  return GestureDetector(
                    onPanStart: _panStart,
                    onPanUpdate: _panUpdate,
                    onPanEnd: _panEnd,
                    child: CustomPaint(
                      size: Size(box.maxWidth, box.maxHeight),
                      painter: _GridPainter(
                        board: _board,
                        chain: _chain,
                        cellSize: _cellSize,
                        origin: _gridOrigin,
                        rows: _rows,
                        cols: _cols,
                      ),
                    ),
                  );
                },
              ),
            ),
            // HUD overlay – fixed position, never shifts the grid
            Positioned(
              top: 8,
              left: 16,
              right: 16,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'score: $_score',
                        style: TextStyle(
                          color: _score >= _minScore
                              ? NunuColors.successMain
                              : NunuColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      // chain info (always occupies space)
                      Text(
                        _chain.length >= 2
                            ? 'chain ${_chain.length} → +${_chain.length * _chain.length}'
                            : '',
                        style: const TextStyle(
                          color: NunuColors.primaryLight,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'moves: ${_totalMoves - _movesUsed}',
                        style: const TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'need $_minScore  ·  chain² = points',
                    style: TextStyle(
                      color: NunuColors.textSecondary.withValues(alpha: 0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- painter ----------

class _GridPainter extends CustomPainter {
  final List<List<_Gem>> board;
  final List<List<int>> chain;
  final double cellSize;
  final Offset origin;
  final int rows, cols;

  _GridPainter({
    required this.board,
    required this.chain,
    required this.cellSize,
    required this.origin,
    required this.rows,
    required this.cols,
  });

  Offset _center(int r, int c) => Offset(
        origin.dx + c * cellSize + cellSize / 2,
        origin.dy + r * cellSize + cellSize / 2,
      );

  @override
  void paint(Canvas canvas, Size size) {
    final gap = cellSize * 0.06;
    final gemR = (cellSize - gap * 2) / 2 * 0.72;

    // cell backgrounds
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final rect = Rect.fromLTWH(
          origin.dx + c * cellSize + gap,
          origin.dy + r * cellSize + gap,
          cellSize - gap * 2,
          cellSize - gap * 2,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(8)),
          Paint()..color = NunuColors.backgroundPaper,
        );
      }
    }

    // chain line
    if (chain.length >= 2) {
      final path = Path();
      for (int i = 0; i < chain.length; i++) {
        final p = _center(chain[i][0], chain[i][1]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = NunuColors.primaryMain.withValues(alpha: 0.35)
          ..strokeWidth = gemR * 0.9
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = NunuColors.primaryMain.withValues(alpha: 0.85)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // gems
    final linked = <String>{};
    for (final c in chain) {
      linked.add('${c[0]},${c[1]}');
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final ctr = _center(r, c);
        final color =
            _LevelLinkChainState._gemColors[board[r][c]] ?? Colors.grey;
        final isLinked = linked.contains('$r,$c');

        if (isLinked) {
          canvas.drawCircle(
            ctr,
            gemR * 1.3,
            Paint()
              ..color = color.withValues(alpha: 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }

        // gem body
        canvas.drawCircle(
          ctr,
          gemR,
          Paint()..color = isLinked ? color : color.withValues(alpha: 0.7),
        );

        // inner shape for visual variety
        _drawGemShape(canvas, ctr, gemR * 0.5, board[r][c], isLinked);

        // specular highlight
        canvas.drawCircle(
          ctr + Offset(-gemR * 0.22, -gemR * 0.28),
          gemR * 0.28,
          Paint()
            ..color =
                Colors.white.withValues(alpha: isLinked ? 0.45 : 0.2),
        );
      }
    }
  }

  void _drawGemShape(
      Canvas canvas, Offset ctr, double r, _Gem gem, bool lit) {
    final alpha = lit ? 0.6 : 0.3;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (gem) {
      case _Gem.ruby: // small triangle
        final path = Path()
          ..moveTo(ctr.dx, ctr.dy - r)
          ..lineTo(ctr.dx - r * 0.87, ctr.dy + r * 0.5)
          ..lineTo(ctr.dx + r * 0.87, ctr.dy + r * 0.5)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case _Gem.sapphire: // diamond
        final path = Path()
          ..moveTo(ctr.dx, ctr.dy - r)
          ..lineTo(ctr.dx + r, ctr.dy)
          ..lineTo(ctr.dx, ctr.dy + r)
          ..lineTo(ctr.dx - r, ctr.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case _Gem.emerald: // square
        canvas.drawRect(
          Rect.fromCenter(center: ctr, width: r * 1.5, height: r * 1.5),
          paint,
        );
        break;
      case _Gem.topaz: // star
        _drawStar(canvas, ctr, r, paint);
        break;
      case _Gem.amethyst: // circle
        canvas.drawCircle(ctr, r * 0.7, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset ctr, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = pi / 5 * i - pi / 2;
      final rad = i.isEven ? r : r * 0.4;
      final p = Offset(ctr.dx + cos(a) * rad, ctr.dy + sin(a) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => true;
}
