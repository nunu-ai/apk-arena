import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

enum _RoundLayout { optionsOnly, matrix }

const _matrixLabels = ['A', 'B', 'C', 'D', 'E', 'F'];

class _IqRound {
  final String prompt;
  final List<String> labels;
  final List<CustomPainter> options;
  final int correctIndex;
  final _RoundLayout layout;
  final List<CustomPainter> matrix;

  const _IqRound.options({
    required this.prompt,
    required this.labels,
    required this.options,
    required this.correctIndex,
  }) : layout = _RoundLayout.optionsOnly,
       matrix = const [];

  const _IqRound.matrix({
    required this.prompt,
    required this.matrix,
    required this.labels,
    required this.options,
    required this.correctIndex,
  }) : layout = _RoundLayout.matrix;
}

class LevelOddOneOut extends LevelWidget {
  const LevelOddOneOut({super.key, required super.onComplete});

  @override
  State<LevelOddOneOut> createState() => _LevelOddOneOutState();
}

class _LevelOddOneOutState extends State<LevelOddOneOut> {
  late final List<_IqRound> _rounds;
  int _currentRound = 0;
  int _correctAnswers = 0;
  bool _processingTap = false;
  int? _selectedIndex;

  static const _legacyLabels = ['A', 'B', 'C', 'D', 'E'];

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: _rounds.isEmpty ? 0.0 : (_correctAnswers / _rounds.length).clamp(0.0, 1.0)));
    _rounds = _buildRounds(SeedService.instance.createRandom());
  }

  List<_IqRound> _buildRounds(Random rng) {
    final fishOdd = rng.nextInt(5);
    final stackOdd = rng.nextInt(5);
    final normals = List<List<int>>.of(_stackNormals)..shuffle(rng);
    var normalIndex = 0;

    return [
      _IqRound.options(
        prompt: 'select the mirrored specimen.',
        labels: _legacyLabels,
        correctIndex: fishOdd,
        options: List.generate(
          5,
          (index) => _FishPainter(mirrored: index == fishOdd),
        ),
      ),
      _lineMatrixRound(),
      _IqRound.options(
        prompt: 'select the stack with no unique symbol.',
        labels: _legacyLabels,
        correctIndex: stackOdd,
        options: List.generate(
          5,
          (index) => _StackPainter(
            shapes: index == stackOdd ? _stackOdd : normals[normalIndex++],
          ),
        ),
      ),
      _orbitMatrixRound(),
      _circuitMatrixRound(),
      _cornerMatrixRound(),
      _dominoMatrixRound(),
      _glyphMatrixRound(),
      _layerAlgebraRoundTwo(),
      _layerAlgebraRoundThree(),
    ];
  }

  void _onOptionTap(int index) {
    if (_processingTap) return;
    final round = _rounds[_currentRound];
    final isCorrect = index == round.correctIndex;

    setState(() {
      _selectedIndex = index;
      _processingTap = true;
    });

    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      final nextCorrectAnswers = _correctAnswers + (isCorrect ? 1 : 0);

      if (_currentRound + 1 >= _rounds.length) {
        widget.onComplete(
          LevelOutcome(score: nextCorrectAnswers / _rounds.length),
        );
        return;
      }

      setState(() {
        _correctAnswers = nextCorrectAnswers;
        _currentRound++;
        _processingTap = false;
        _selectedIndex = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentRound];

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(stageText: '${_currentRound + 1}/${_rounds.length}'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'solve all the riddles',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          round.prompt,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 13,
                            color: NunuColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 24),
                        if (round.layout == _RoundLayout.matrix) ...[
                          _buildMatrix(round.matrix),
                          const SizedBox(height: 18),
                        ],
                        _buildOptions(round),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatrix(List<CustomPainter> painters) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = (constraints.maxWidth - 32).clamp(240.0, 390.0);
        final cellSize = size / 3;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: NunuColors.secondaryLight.withValues(alpha: 0.5),
              width: 2,
            ),
          ),
          child: GridView.builder(
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final isMissing = index == 8;
              return Container(
                width: cellSize,
                height: cellSize,
                decoration: BoxDecoration(
                  border: Border(
                    right: index % 3 == 2
                        ? BorderSide.none
                        : BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                    bottom: index > 5
                        ? BorderSide.none
                        : BorderSide(
                            color: Colors.white.withValues(alpha: 0.15),
                            width: 1,
                          ),
                  ),
                ),
                child: Center(
                  child: isMissing
                      ? const Text(
                          '?',
                          style: TextStyle(
                            color: NunuColors.primaryLight,
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.all(12),
                          child: SizedBox.expand(
                            child: CustomPaint(painter: painters[index]),
                          ),
                        ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOptions(_IqRound round) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = round.options.length == 6 ? 3 : 3;
        final spacing = 10.0;
        final cardWidth =
            ((constraints.maxWidth - spacing * (columns - 1)) / columns).clamp(
              86.0,
              round.options.length == 6 ? 130.0 : 115.0,
            );

        return Wrap(
          alignment: WrapAlignment.center,
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(
            round.options.length,
            (index) => _buildCard(round, index, cardWidth),
          ),
        );
      },
    );
  }

  Widget _buildCard(_IqRound round, int index, double width) {
    final isSelected = _processingTap && _selectedIndex == index;

    return GestureDetector(
      onTap: () => _onOptionTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: width,
        height: width * 1.04,
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? NunuColors.secondaryLight
                : Colors.white.withValues(alpha: 0.08),
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 6,
              left: 10,
              child: Text(
                round.labels[index],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70,
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox.square(
                  dimension: width * 0.64,
                  child: CustomPaint(painter: round.options[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

_IqRound _lineMatrixRound() {
  return const _IqRound.options(
    prompt: 'select the line marker with no matching pair.',
    correctIndex: 3,
    labels: _LevelOddOneOutState._legacyLabels,
    options: [
      _LineBlockPainter(angleTurns: 0, blockPosition: 1),
      _LineBlockPainter(angleTurns: 0, blockPosition: -1),
      _LineBlockPainter(angleTurns: 1, blockPosition: 0),
      _LineBlockPainter(angleTurns: 2, blockPosition: 0),
      _LineBlockPainter(angleTurns: 1, blockPosition: -1),
    ],
  );
}

_IqRound _orbitMatrixRound() {
  return const _IqRound.matrix(
    prompt: 'infer the orbit count and highlighted moon.',
    correctIndex: 3,
    labels: _matrixLabels,
    matrix: [
      _OrbitPainter(moons: 2, active: 0),
      _OrbitPainter(moons: 3, active: 1),
      _OrbitPainter(moons: 4, active: 2),
      _OrbitPainter(moons: 3, active: 2),
      _OrbitPainter(moons: 4, active: 3),
      _OrbitPainter(moons: 5, active: 4),
      _OrbitPainter(moons: 4, active: 0),
      _OrbitPainter(moons: 5, active: 1),
    ],
    options: [
      _OrbitPainter(moons: 5, active: 2),
      _OrbitPainter(moons: 6, active: 1),
      _OrbitPainter(moons: 4, active: 2),
      _OrbitPainter(moons: 6, active: 2),
      _OrbitPainter(moons: 6, active: 5),
      _OrbitPainter(moons: 5, active: 4),
    ],
  );
}

_IqRound _circuitMatrixRound() {
  return const _IqRound.matrix(
    prompt: 'combine each row into the missing circuit.',
    correctIndex: 2,
    labels: _matrixLabels,
    matrix: [
      _CircuitPainter(mask: 3, node: 0),
      _CircuitPainter(mask: 5, node: 1),
      _CircuitPainter(mask: 6, node: 1),
      _CircuitPainter(mask: 10, node: 1),
      _CircuitPainter(mask: 12, node: 2),
      _CircuitPainter(mask: 6, node: 3),
      _CircuitPainter(mask: 9, node: 2),
      _CircuitPainter(mask: 10, node: 3),
    ],
    options: [
      _CircuitPainter(mask: 3, node: 2),
      _CircuitPainter(mask: 5, node: 0),
      _CircuitPainter(mask: 3, node: 1),
      _CircuitPainter(mask: 12, node: 1),
      _CircuitPainter(mask: 6, node: 0),
      _CircuitPainter(mask: 10, node: 2),
    ],
  );
}

_IqRound _cornerMatrixRound() {
  return const _IqRound.matrix(
    prompt: 'track the corner marker and inner cutout.',
    correctIndex: 1,
    labels: _matrixLabels,
    matrix: [
      _CornerTilePainter(corner: 0, notch: 2, shape: 0),
      _CornerTilePainter(corner: 1, notch: 3, shape: 1),
      _CornerTilePainter(corner: 2, notch: 0, shape: 2),
      _CornerTilePainter(corner: 1, notch: 3, shape: 1),
      _CornerTilePainter(corner: 2, notch: 0, shape: 2),
      _CornerTilePainter(corner: 3, notch: 1, shape: 0),
      _CornerTilePainter(corner: 2, notch: 0, shape: 2),
      _CornerTilePainter(corner: 3, notch: 1, shape: 0),
    ],
    options: [
      _CornerTilePainter(corner: 0, notch: 1, shape: 1),
      _CornerTilePainter(corner: 0, notch: 2, shape: 1),
      _CornerTilePainter(corner: 3, notch: 2, shape: 1),
      _CornerTilePainter(corner: 1, notch: 2, shape: 2),
      _CornerTilePainter(corner: 0, notch: 3, shape: 0),
      _CornerTilePainter(corner: 2, notch: 2, shape: 1),
    ],
  );
}

_IqRound _dominoMatrixRound() {
  return const _IqRound.matrix(
    prompt: 'solve the visual domino progression.',
    correctIndex: 0,
    labels: _matrixLabels,
    matrix: [
      _DominoPainter(left: 1, right: 3, vertical: false),
      _DominoPainter(left: 2, right: 4, vertical: true),
      _DominoPainter(left: 3, right: 5, vertical: false),
      _DominoPainter(left: 2, right: 5, vertical: true),
      _DominoPainter(left: 3, right: 6, vertical: false),
      _DominoPainter(left: 4, right: 1, vertical: true),
      _DominoPainter(left: 3, right: 1, vertical: false),
      _DominoPainter(left: 4, right: 2, vertical: true),
    ],
    options: [
      _DominoPainter(left: 5, right: 3, vertical: false),
      _DominoPainter(left: 5, right: 2, vertical: false),
      _DominoPainter(left: 4, right: 3, vertical: true),
      _DominoPainter(left: 6, right: 3, vertical: false),
      _DominoPainter(left: 5, right: 4, vertical: true),
      _DominoPainter(left: 3, right: 5, vertical: false),
    ],
  );
}

_IqRound _glyphMatrixRound() {
  return const _IqRound.matrix(
    prompt: 'complete the layered glyph rule.',
    correctIndex: 5,
    labels: _matrixLabels,
    matrix: [
      _GlyphPainter(sides: 3, bars: 1, filled: false),
      _GlyphPainter(sides: 4, bars: 2, filled: true),
      _GlyphPainter(sides: 5, bars: 3, filled: false),
      _GlyphPainter(sides: 4, bars: 3, filled: true),
      _GlyphPainter(sides: 5, bars: 1, filled: false),
      _GlyphPainter(sides: 6, bars: 2, filled: true),
      _GlyphPainter(sides: 5, bars: 2, filled: false),
      _GlyphPainter(sides: 6, bars: 3, filled: true),
    ],
    options: [
      _GlyphPainter(sides: 6, bars: 1, filled: false),
      _GlyphPainter(sides: 7, bars: 2, filled: true),
      _GlyphPainter(sides: 5, bars: 1, filled: true),
      _GlyphPainter(sides: 7, bars: 3, filled: false),
      _GlyphPainter(sides: 6, bars: 1, filled: true),
      _GlyphPainter(sides: 7, bars: 1, filled: false),
    ],
  );
}

_IqRound _layerAlgebraRoundTwo() {
  return const _IqRound.matrix(
    prompt: 'merge the visible layers, then rotate.',
    correctIndex: 5,
    labels: _matrixLabels,
    matrix: [
      _LayerTilePainter(mask: 3, rotation: 0),
      _LayerTilePainter(mask: 4, rotation: 0),
      _LayerTilePainter(mask: 7, rotation: 0),
      _LayerTilePainter(mask: 6, rotation: 1),
      _LayerTilePainter(mask: 9, rotation: 1),
      _LayerTilePainter(mask: 15, rotation: 2),
      _LayerTilePainter(mask: 12, rotation: 2),
      _LayerTilePainter(mask: 1, rotation: 2),
    ],
    options: [
      _LayerTilePainter(mask: 13, rotation: 1),
      _LayerTilePainter(mask: 5, rotation: 2),
      _LayerTilePainter(mask: 15, rotation: 3),
      _LayerTilePainter(mask: 12, rotation: 3),
      _LayerTilePainter(mask: 7, rotation: 0),
      _LayerTilePainter(mask: 13, rotation: 3),
    ],
  );
}

_IqRound _layerAlgebraRoundThree() {
  return const _IqRound.matrix(
    prompt: 'subtract repeated layers and keep the remainder.',
    correctIndex: 0,
    labels: _matrixLabels,
    matrix: [
      _LayerTilePainter(mask: 15, rotation: 0),
      _LayerTilePainter(mask: 3, rotation: 1),
      _LayerTilePainter(mask: 12, rotation: 1),
      _LayerTilePainter(mask: 11, rotation: 1),
      _LayerTilePainter(mask: 9, rotation: 2),
      _LayerTilePainter(mask: 2, rotation: 3),
      _LayerTilePainter(mask: 14, rotation: 2),
      _LayerTilePainter(mask: 6, rotation: 3),
    ],
    options: [
      _LayerTilePainter(mask: 8, rotation: 1),
      _LayerTilePainter(mask: 1, rotation: 0),
      _LayerTilePainter(mask: 10, rotation: 1),
      _LayerTilePainter(mask: 4, rotation: 0),
      _LayerTilePainter(mask: 12, rotation: 2),
      _LayerTilePainter(mask: 6, rotation: 1),
    ],
  );
}

const _stackNormals = [
  [1, 2, 0],
  [0, 0, 3],
  [1, 0, 4],
  [5, 0, 0],
];
const _stackOdd = [1, 0, 0];

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

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, cy),
        width: w * 0.6,
        height: h * 0.4,
      ),
      stroke,
    );
    canvas.drawLine(Offset(w * 0.22, cy), Offset(w * 0.05, h * 0.30), stroke);
    canvas.drawLine(Offset(w * 0.22, cy), Offset(w * 0.05, h * 0.80), stroke);
    canvas.drawLine(
      Offset(w * 0.05, h * 0.30),
      Offset(w * 0.05, h * 0.80),
      stroke,
    );

    final fin = Path()
      ..moveTo(w * 0.40, h * 0.36)
      ..lineTo(w * 0.50, h * 0.10)
      ..lineTo(w * 0.60, h * 0.36);
    canvas.drawPath(fin, fill);
    canvas.drawCircle(Offset(w * 0.67, h * 0.49), w * 0.05, fill);
    canvas.drawCircle(
      Offset(w * 0.665, h * 0.485),
      w * 0.02,
      Paint()..color = Colors.white,
    );

    for (var i = 0; i < 3; i++) {
      final x = w * (0.40 + i * 0.07);
      canvas.drawLine(Offset(x, h * 0.40), Offset(x, h * 0.70), stroke);
    }
    final pectoral = Path()
      ..moveTo(w * 0.48, h * 0.74)
      ..quadraticBezierTo(w * 0.38, h * 0.86, w * 0.28, h * 0.74);
    canvas.drawPath(pectoral, stroke);

    canvas.restore();
  }

  @override
  bool shouldRepaint(_FishPainter oldDelegate) =>
      oldDelegate.mirrored != mirrored;
}

class _StackPainter extends CustomPainter {
  final List<int> shapes;
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
      case 0:
        canvas.drawCircle(c, r, fill);
        canvas.drawCircle(c, r, stroke);
        break;
      case 1:
        final path = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx - r, c.dy + r * 0.7)
          ..lineTo(c.dx + r, c.dy + r * 0.7)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 2:
        final path = Path()
          ..moveTo(c.dx, c.dy - r)
          ..lineTo(c.dx + r, c.dy)
          ..lineTo(c.dx, c.dy + r)
          ..lineTo(c.dx - r, c.dy)
          ..close();
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
        break;
      case 3:
        _drawStar(canvas, c, r, fill, stroke);
        break;
      case 4:
        final rect = Rect.fromCenter(
          center: c,
          width: r * 1.6,
          height: r * 1.6,
        );
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
        break;
      case 5:
        _drawPolygon(canvas, c, r, 6, fill, stroke);
        break;
    }
  }

  @override
  bool shouldRepaint(_StackPainter oldDelegate) => oldDelegate.shapes != shapes;
}

class _LineBlockPainter extends CustomPainter {
  final int angleTurns;
  final int blockPosition;
  const _LineBlockPainter({
    required this.angleTurns,
    required this.blockPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final angle = angleTurns * pi / 4;
    final length = w * 0.72;
    final direction = Offset(cos(angle), sin(angle));
    final start = center - direction * length * 0.5;
    final end = center + direction * length * 0.5;
    final markerCenter =
        center + direction * blockPosition.toDouble() * length * 0.34;
    final stroke = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final fill = Paint()..color = NunuColors.primaryLight;

    canvas.drawLine(start, end, stroke);
    canvas.save();
    canvas.translate(markerCenter.dx, markerCenter.dy);
    canvas.rotate(angle);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset.zero, width: w * 0.18, height: h * 0.28),
        const Radius.circular(2),
      ),
      fill,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LineBlockPainter oldDelegate) =>
      oldDelegate.angleTurns != angleTurns ||
      oldDelegate.blockPosition != blockPosition;
}

class _OrbitPainter extends CustomPainter {
  final int moons;
  final int active;
  const _OrbitPainter({required this.moons, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.32;
    final orbit = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final moon = Paint()..color = Colors.white;
    final activeMoon = Paint()..color = NunuColors.primaryMain;

    canvas.drawCircle(center, radius, orbit);
    canvas.drawCircle(center, size.width * 0.09, activeMoon);
    for (var i = 0; i < moons; i++) {
      final angle = -pi / 2 + i * 2 * pi / moons;
      final point = center + Offset(cos(angle), sin(angle)) * radius;
      canvas.drawCircle(
        point,
        size.width * 0.045,
        i == active ? activeMoon : moon,
      );
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter oldDelegate) =>
      oldDelegate.moons != moons || oldDelegate.active != active;
}

class _CircuitPainter extends CustomPainter {
  final int mask;
  final int node;
  const _CircuitPainter({required this.mask, required this.node});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final endpoints = [
      Offset(center.dx, size.height * 0.12),
      Offset(size.width * 0.88, center.dy),
      Offset(center.dx, size.height * 0.88),
      Offset(size.width * 0.12, center.dy),
    ];
    final line = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final accent = Paint()..color = NunuColors.secondaryLight;

    for (var i = 0; i < 4; i++) {
      if ((mask & (1 << i)) != 0) {
        canvas.drawLine(center, endpoints[i], line);
      }
    }
    canvas.drawCircle(center, size.width * 0.08, accent);
    canvas.drawCircle(endpoints[node], size.width * 0.055, accent);
  }

  @override
  bool shouldRepaint(_CircuitPainter oldDelegate) =>
      oldDelegate.mask != mask || oldDelegate.node != node;
}

class _CornerTilePainter extends CustomPainter {
  final int corner;
  final int notch;
  final int shape;
  const _CornerTilePainter({
    required this.corner,
    required this.notch,
    required this.shape,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * 0.18,
      size.height * 0.18,
      size.width * 0.64,
      size.height * 0.64,
    );
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final accent = Paint()
      ..color = NunuColors.primaryMain
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      stroke,
    );
    canvas.drawCircle(_cornerPoint(rect, corner), size.width * 0.07, accent);
    canvas.drawCircle(
      _cornerPoint(rect.deflate(size.width * 0.16), notch),
      size.width * 0.055,
      Paint()..color = NunuColors.backgroundDefault,
    );
    _drawCenterShape(canvas, rect.center, size.width * 0.12, shape, accent);
  }

  @override
  bool shouldRepaint(_CornerTilePainter oldDelegate) =>
      oldDelegate.corner != corner ||
      oldDelegate.notch != notch ||
      oldDelegate.shape != shape;
}

class _DominoPainter extends CustomPainter {
  final int left;
  final int right;
  final bool vertical;
  const _DominoPainter({
    required this.left,
    required this.right,
    required this.vertical,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: vertical ? size.width * 0.42 : size.width * 0.76,
      height: vertical ? size.height * 0.76 : size.height * 0.42,
    );
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final divider = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(8)),
      stroke,
    );
    if (vertical) {
      canvas.drawLine(
        Offset(rect.left, rect.center.dy),
        Offset(rect.right, rect.center.dy),
        divider,
      );
      _drawPips(canvas, rect.topLeft & Size(rect.width, rect.height / 2), left);
      _drawPips(
        canvas,
        Offset(rect.left, rect.center.dy) & Size(rect.width, rect.height / 2),
        right,
      );
    } else {
      canvas.drawLine(
        Offset(rect.center.dx, rect.top),
        Offset(rect.center.dx, rect.bottom),
        divider,
      );
      _drawPips(canvas, rect.topLeft & Size(rect.width / 2, rect.height), left);
      _drawPips(
        canvas,
        Offset(rect.center.dx, rect.top) & Size(rect.width / 2, rect.height),
        right,
      );
    }
  }

  @override
  bool shouldRepaint(_DominoPainter oldDelegate) =>
      oldDelegate.left != left ||
      oldDelegate.right != right ||
      oldDelegate.vertical != vertical;
}

class _GlyphPainter extends CustomPainter {
  final int sides;
  final int bars;
  final bool filled;
  const _GlyphPainter({
    required this.sides,
    required this.bars,
    required this.filled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.28;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final fill = Paint()
      ..color = NunuColors.secondaryMain.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final polygon = _polygonPath(center, radius, sides);
    if (filled) canvas.drawPath(polygon, fill);
    canvas.drawPath(polygon, stroke);

    final barPaint = Paint()
      ..color = NunuColors.primaryLight
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < bars; i++) {
      final y = center.dy + (i - (bars - 1) / 2) * size.height * 0.12;
      canvas.drawLine(
        Offset(center.dx - radius * 0.75, y),
        Offset(center.dx + radius * 0.75, y),
        barPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) =>
      oldDelegate.sides != sides ||
      oldDelegate.bars != bars ||
      oldDelegate.filled != filled;
}

class _LayerTilePainter extends CustomPainter {
  final int mask;
  final int rotation;
  const _LayerTilePainter({required this.mask, required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.3;
    final stroke = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    final primaryFill = Paint()
      ..color = NunuColors.primaryMain.withValues(alpha: 0.7)
      ..style = PaintingStyle.fill;
    final secondaryFill = Paint()
      ..color = NunuColors.secondaryMain.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation * pi / 2);
    canvas.translate(-center.dx, -center.dy);

    if ((mask & 1) != 0) {
      canvas.drawCircle(center, radius, secondaryFill);
      canvas.drawCircle(center, radius, stroke);
    }

    if ((mask & 2) != 0) {
      final triangle = Path()
        ..moveTo(center.dx, center.dy - radius * 1.05)
        ..lineTo(center.dx - radius * 0.9, center.dy + radius * 0.65)
        ..lineTo(center.dx + radius * 0.9, center.dy + radius * 0.65)
        ..close();
      canvas.drawPath(triangle, primaryFill);
      canvas.drawPath(triangle, stroke);
    }

    if ((mask & 4) != 0) {
      canvas.drawLine(
        Offset(center.dx - radius, center.dy + radius),
        Offset(center.dx + radius, center.dy - radius),
        stroke,
      );
      canvas.drawLine(
        Offset(center.dx - radius * 0.55, center.dy + radius),
        Offset(center.dx + radius, center.dy - radius * 0.55),
        stroke,
      );
    }

    if ((mask & 8) != 0) {
      final dotPaint = Paint()..color = NunuColors.primaryLight;
      for (final offset in const [
        Offset(-0.55, -0.55),
        Offset(0.55, -0.55),
        Offset(-0.55, 0.55),
        Offset(0.55, 0.55),
      ]) {
        canvas.drawCircle(
          center + offset * radius,
          size.width * 0.045,
          dotPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_LayerTilePainter oldDelegate) =>
      oldDelegate.mask != mask || oldDelegate.rotation != rotation;
}

void _drawCenterShape(
  Canvas canvas,
  Offset center,
  double radius,
  int type,
  Paint fill,
) {
  if (type == 0) {
    canvas.drawCircle(center, radius, fill);
    return;
  }
  canvas.drawPath(
    _polygonPath(
      center,
      radius,
      type == 1
          ? 3
          : type == 2
          ? 4
          : 6,
    ),
    fill,
  );
}

void _drawStar(
  Canvas canvas,
  Offset center,
  double outerRadius,
  Paint fill,
  Paint stroke,
) {
  final innerRadius = outerRadius * 0.42;
  final path = Path();
  for (var i = 0; i < 10; i++) {
    final radius = i.isEven ? outerRadius : innerRadius;
    final angle = -pi / 2 + i * pi / 5;
    final point = center + Offset(cos(angle), sin(angle)) * radius;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  path.close();
  canvas.drawPath(path, fill);
  canvas.drawPath(path, stroke);
}

void _drawPolygon(
  Canvas canvas,
  Offset center,
  double radius,
  int sides,
  Paint fill,
  Paint stroke,
) {
  final path = _polygonPath(center, radius, sides);
  canvas.drawPath(path, fill);
  canvas.drawPath(path, stroke);
}

Path _polygonPath(Offset center, double radius, int sides) {
  final path = Path();
  for (var i = 0; i < sides; i++) {
    final angle = -pi / 2 + i * 2 * pi / sides;
    final point = center + Offset(cos(angle), sin(angle)) * radius;
    i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
  }
  path.close();
  return path;
}

Offset _cornerPoint(Rect rect, int corner) {
  switch (corner) {
    case 0:
      return rect.topLeft;
    case 1:
      return rect.topRight;
    case 2:
      return rect.bottomRight;
    default:
      return rect.bottomLeft;
  }
}

void _drawPips(Canvas canvas, Rect rect, int count) {
  final paint = Paint()..color = NunuColors.primaryLight;
  final points = [
    rect.center,
    Offset(rect.left + rect.width * 0.3, rect.top + rect.height * 0.3),
    Offset(rect.right - rect.width * 0.3, rect.bottom - rect.height * 0.3),
    Offset(rect.right - rect.width * 0.3, rect.top + rect.height * 0.3),
    Offset(rect.left + rect.width * 0.3, rect.bottom - rect.height * 0.3),
    Offset(rect.left + rect.width * 0.3, rect.center.dy),
    Offset(rect.right - rect.width * 0.3, rect.center.dy),
  ];
  final pipIndexes = {
    1: [0],
    2: [1, 2],
    3: [0, 1, 2],
    4: [1, 2, 3, 4],
    5: [0, 1, 2, 3, 4],
    6: [1, 2, 3, 4, 5, 6],
  }[count]!;

  for (final index in pipIndexes) {
    canvas.drawCircle(points[index], rect.shortestSide * 0.07, paint);
  }
}
