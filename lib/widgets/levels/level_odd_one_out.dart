import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelOddOneOut extends LevelWidget {
  const LevelOddOneOut({super.key, required super.onComplete});

  @override
  State<LevelOddOneOut> createState() => _LevelOddOneOutState();
}

class _LevelOddOneOutState extends State<LevelOddOneOut> {
  int _currentRound = 0;
  static const _totalRounds = 3;
  bool _processingTap = false;
  int? _selectedIndex;
  bool? _selectedCorrect;

  // ── round state ──────────────────────────────────────────────
  // Round 1 – fish (odd = mirrored)
  late final int _r1OddIdx;

  // Round 2 – shields: pair A (horizontal), pair B (vertical), odd (grid)
  // variant: 0 = horizontal stripes, 1 = vertical stripes, 2 = grid (odd)
  late final int _r2OddIdx;
  late final List<int> _r2Variants;

  // Round 3 – stacked shapes: each normal has one unique shape type, odd has none
  // shape types: 0=circle  1=triangle  2=diamond  3=star  4=square  5=hexagon
  late final int _r3OddIdx;
  late final List<List<int>> _r3Shapes;

  // 4 configs where each contains exactly one shape type no other config has
  static const _r3Normals = [
    [1, 2, 0], // triangle, diamond, circle  → diamond unique
    [0, 0, 3], // circle, circle, star       → star unique
    [1, 0, 4], // triangle, circle, square   → square unique
    [5, 0, 0], // hexagon, circle, circle    → hexagon unique
  ];
  // odd config: triangle + circle only — both appear in normals above
  static const _r3Odd = [1, 0, 0];

  @override
  void initState() {
    super.initState();
    final rng = Random();

    // Round 1
    _r1OddIdx = rng.nextInt(5);

    // Round 2 — two pairs + odd
    _r2OddIdx = rng.nextInt(5);
    _r2Variants = List.filled(5, 0);
    _r2Variants[_r2OddIdx] = 2;
    final rem = [
      for (var i = 0; i < 5; i++)
        if (i != _r2OddIdx) i,
    ]..shuffle(rng);
    _r2Variants[rem[0]] = 0;
    _r2Variants[rem[1]] = 0;
    _r2Variants[rem[2]] = 1;
    _r2Variants[rem[3]] = 1;

    // Round 3 — unique-feature puzzle
    _r3OddIdx = rng.nextInt(5);
    final normals = List<List<int>>.of(_r3Normals)..shuffle(rng);
    var ni = 0;
    _r3Shapes = List.generate(
      5,
      (i) => i == _r3OddIdx ? _r3Odd : normals[ni++],
    );
  }

  int get _oddIdx {
    switch (_currentRound) {
      case 0:
        return _r1OddIdx;
      case 1:
        return _r2OddIdx;
      case 2:
        return _r3OddIdx;
      default:
        return 0;
    }
  }

  void _onOptionTap(int index) {
    if (_processingTap) return;
    final isCorrect = index == _oddIdx;

    setState(() {
      _selectedIndex = index;
      _selectedCorrect = isCorrect;
      _processingTap = true;
    });

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      if (isCorrect) {
        if (_currentRound + 1 >= _totalRounds) {
          widget.onComplete(LevelOutcome(score: 1));
        } else {
          setState(() {
            _currentRound++;
            _processingTap = false;
            _selectedIndex = null;
            _selectedCorrect = null;
          });
        }
      } else {
        widget.onComplete(LevelOutcome(score: 0));
      }
    });
  }

  // ── build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    const labels = ['A', 'B', 'C', 'D', 'E'];

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'round ${_currentRound + 1} of $_totalRounds',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'which is the odd one out?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),
                _buildGrid(labels),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<String> labels) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = ((constraints.maxWidth - 48) / 3).clamp(80.0, 110.0);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => _buildCard(i, labels[i], cardW),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                2,
                (i) => _buildCard(i + 3, labels[i + 3], cardW),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCard(int index, String label, double width) {
    final height = width * 1.15;
    final isOddCard = index == _oddIdx;

    Color borderColor = Colors.white.withValues(alpha: 0.08);
    double borderWidth = 1;

    if (_processingTap && _selectedIndex == index) {
      borderColor = _selectedCorrect!
          ? NunuColors.successMain
          : NunuColors.errorMain;
      borderWidth = 3;
    }
    // reveal the correct answer when user picked wrong
    if (_processingTap && _selectedCorrect == false && isOddCard) {
      borderColor = NunuColors.successMain;
      borderWidth = 3;
    }

    return GestureDetector(
      onTap: () => _onOptionTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 5),
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              left: 10,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: SizedBox(
                  width: width * 0.68,
                  height: width * 0.68,
                  child: CustomPaint(painter: _painterFor(index)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  CustomPainter _painterFor(int index) {
    switch (_currentRound) {
      case 0:
        return _FishPainter(mirrored: index == _r1OddIdx);
      case 1:
        return _ShieldPainter(variant: _r2Variants[index]);
      case 2:
        return _StackPainter(shapes: _r3Shapes[index]);
      default:
        return _FishPainter(mirrored: false);
    }
  }
}

// ====================================================================
//  Round 1 — Fish  (odd = horizontally mirrored)
// ====================================================================
class _FishPainter extends CustomPainter {
  final bool mirrored;
  const _FishPainter({required this.mirrored});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    canvas.save();
    if (mirrored) {
      canvas.translate(w, 0);
      canvas.scale(-1, 1);
    }

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final fill = Paint()
      ..color = NunuColors.primaryMain
      ..style = PaintingStyle.fill;

    final cy = h * 0.55;

    // body
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, cy),
        width: w * 0.6,
        height: h * 0.4,
      ),
      stroke,
    );

    // tail
    canvas.drawLine(Offset(w * 0.22, cy), Offset(w * 0.05, h * 0.30), stroke);
    canvas.drawLine(Offset(w * 0.22, cy), Offset(w * 0.05, h * 0.80), stroke);
    canvas.drawLine(
      Offset(w * 0.05, h * 0.30),
      Offset(w * 0.05, h * 0.80),
      stroke,
    );

    // dorsal fin (filled accent)
    final fin = Path()
      ..moveTo(w * 0.40, h * 0.36)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.60, h * 0.36);
    canvas.drawPath(fin, fill);

    // eye
    canvas.drawCircle(Offset(w * 0.67, h * 0.49), w * 0.05, fill);
    canvas.drawCircle(
      Offset(w * 0.665, h * 0.485),
      w * 0.02,
      Paint()..color = Colors.white,
    );

    // body stripes
    for (var i = 0; i < 3; i++) {
      final x = w * (0.40 + i * 0.07);
      canvas.drawLine(Offset(x, h * 0.40), Offset(x, h * 0.70), stroke);
    }

    // pectoral fin
    final pectoral = Path()
      ..moveTo(w * 0.48, h * 0.74)
      ..quadraticBezierTo(w * 0.38, h * 0.86, w * 0.28, h * 0.74);
    canvas.drawPath(pectoral, stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FishPainter old) => old.mirrored != mirrored;
}

// ====================================================================
//  Round 2 — Shield  (pair A = horizontal, pair B = vertical, odd = grid)
// ====================================================================
class _ShieldPainter extends CustomPainter {
  /// 0 = horizontal stripes, 1 = vertical stripes, 2 = grid (odd)
  final int variant;
  const _ShieldPainter({required this.variant});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final outline = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    final linePaint = Paint()
      ..color = NunuColors.primaryMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    // shield path
    final shield = Path()
      ..moveTo(w * 0.5, h * 0.05)
      ..lineTo(w * 0.92, h * 0.22)
      ..lineTo(w * 0.88, h * 0.60)
      ..quadraticBezierTo(w * 0.5, h * 1.02, w * 0.12, h * 0.60)
      ..lineTo(w * 0.08, h * 0.22)
      ..close();

    // clip inner lines to shield shape
    canvas.save();
    canvas.clipPath(shield);

    // horizontal stripes (group 1 and odd)
    if (variant == 0 || variant == 2) {
      for (var i = 0; i < 6; i++) {
        final y = h * (0.15 + i * 0.14);
        canvas.drawLine(Offset(0, y), Offset(w, y), linePaint);
      }
    }

    // vertical stripes (group 2 and odd)
    if (variant == 1 || variant == 2) {
      for (var i = 0; i < 6; i++) {
        final x = w * (0.15 + i * 0.14);
        canvas.drawLine(Offset(x, 0), Offset(x, h), linePaint);
      }
    }

    canvas.restore();

    // shield outline on top
    canvas.drawPath(shield, outline);
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.variant != variant;
}

// ====================================================================
//  Round 3 — Stacked shapes  (odd = no unique shape type)
//
//  Normal configs each contain one shape type that no other has:
//    [triangle, diamond, circle]  → diamond unique
//    [circle, circle, star]       → star unique
//    [triangle, circle, square]   → square unique
//    [hexagon, circle, circle]    → hexagon unique
//
//  Odd config [triangle, circle, circle] — every shape also exists
//  in at least one other config.
// ====================================================================
class _StackPainter extends CustomPainter {
  final List<int> shapes; // [top, middle, bottom]
  const _StackPainter({required this.shapes});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w * 0.5;
    final r = w * 0.14;

    final fill = Paint()
      ..color = NunuColors.primaryMain
      ..style = PaintingStyle.fill;

    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // subtle connector
    canvas.drawLine(
      Offset(cx, h * 0.18 + r),
      Offset(cx, h * 0.82 - r),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..strokeWidth = 1,
    );

    final yPositions = [h * 0.18, h * 0.50, h * 0.82];
    for (var i = 0; i < 3; i++) {
      _drawShape(canvas, shapes[i], Offset(cx, yPositions[i]), r, fill, stroke);
    }
  }

  void _drawShape(
    Canvas canvas,
    int type,
    Offset c,
    double r,
    Paint fill,
    Paint stroke,
  ) {
    switch (type) {
      case 0: // circle
        canvas.drawCircle(c, r, fill);
        canvas.drawCircle(c, r, stroke);
        break;
      case 1: // triangle (up)
        final p = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx - r, c.dy + r * 0.7)
          ..lineTo(c.dx + r, c.dy + r * 0.7)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawPath(p, stroke);
        break;
      case 2: // diamond
        final p = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r, c.dy)
          ..close();
        canvas.drawPath(p, fill);
        canvas.drawPath(p, stroke);
        break;
      case 3: // 5-pointed star
        _drawStar(canvas, c, r, fill, stroke);
        break;
      case 4: // square
        final rect = Rect.fromCenter(
          center: c,
          width: r * 1.6,
          height: r * 1.6,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
        break;
      case 5: // hexagon
        _drawPolygon(canvas, c, r, 6, fill, stroke);
        break;
    }
  }

  void _drawStar(
    Canvas canvas,
    Offset c,
    double outerR,
    Paint fill,
    Paint stroke,
  ) {
    final innerR = outerR * 0.42;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final rad = i.isEven ? outerR : innerR;
      final angle = -pi / 2 + i * pi / 5;
      final pt = Offset(c.dx + rad * cos(angle), c.dy + rad * sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  void _drawPolygon(
    Canvas canvas,
    Offset c,
    double r,
    int sides,
    Paint fill,
    Paint stroke,
  ) {
    final path = Path();
    for (var i = 0; i < sides; i++) {
      final angle = -pi / 2 + i * 2 * pi / sides;
      final pt = Offset(c.dx + r * cos(angle), c.dy + r * sin(angle));
      i == 0 ? path.moveTo(pt.dx, pt.dy) : path.lineTo(pt.dx, pt.dy);
    }
    path.close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(_StackPainter old) => old.shapes != shapes;
}
