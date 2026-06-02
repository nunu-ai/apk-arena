import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

/// Each drawing pattern: a name and normalized strokes (0..1).
class _Pattern {
  final String name;
  final List<List<Offset>> strokes;
  final bool
  useFullCanvas; // true = stretch to full rect (good for wide shapes)
  const _Pattern(this.name, this.strokes, {this.useFullCanvas = false});
}

final List<_Pattern> _patterns = [
  // 1) Square – 4 strokes
  _Pattern('square', [
    [const Offset(0.30, 0.30), const Offset(0.70, 0.30)],
    [const Offset(0.70, 0.30), const Offset(0.70, 0.70)],
    [const Offset(0.70, 0.70), const Offset(0.30, 0.70)],
    [const Offset(0.30, 0.70), const Offset(0.30, 0.30)],
  ]),

  // 2) Star – 5 strokes (regular 5-pointed star)
  _Pattern('star', [
    [const Offset(0.50, 0.18), const Offset(0.66, 0.67)],
    [const Offset(0.66, 0.67), const Offset(0.24, 0.37)],
    [const Offset(0.24, 0.37), const Offset(0.76, 0.37)],
    [const Offset(0.76, 0.37), const Offset(0.34, 0.67)],
    [const Offset(0.34, 0.67), const Offset(0.50, 0.18)],
  ]),

  // 3) House – 6 strokes (walls, roof, chimney)
  _Pattern('house', [
    [const Offset(0.25, 0.75), const Offset(0.75, 0.75)], // floor
    [const Offset(0.75, 0.75), const Offset(0.75, 0.45)], // right wall
    [const Offset(0.25, 0.75), const Offset(0.25, 0.45)], // left wall
    [const Offset(0.25, 0.45), const Offset(0.50, 0.25)], // left roof
    [const Offset(0.50, 0.25), const Offset(0.75, 0.45)], // right roof
    // chimney
    [
      const Offset(0.62, 0.36),
      const Offset(0.62, 0.20),
      const Offset(0.70, 0.20),
      const Offset(0.70, 0.40),
    ],
  ]),

  // 4) Smiley with cowboy hat – 7 strokes (curves, harder)
  _Pattern('smiley', [
    // top arc of face
    [
      const Offset(0.20, 0.50),
      const Offset(0.22, 0.37),
      const Offset(0.30, 0.27),
      const Offset(0.42, 0.22),
      const Offset(0.50, 0.21),
      const Offset(0.58, 0.22),
      const Offset(0.70, 0.27),
      const Offset(0.78, 0.37),
      const Offset(0.80, 0.50),
    ],
    // bottom arc of face
    [
      const Offset(0.80, 0.50),
      const Offset(0.78, 0.65),
      const Offset(0.70, 0.77),
      const Offset(0.58, 0.82),
      const Offset(0.50, 0.83),
      const Offset(0.42, 0.82),
      const Offset(0.30, 0.77),
      const Offset(0.22, 0.65),
      const Offset(0.20, 0.50),
    ],
    // left eye
    [const Offset(0.38, 0.40), const Offset(0.38, 0.48)],
    // right eye
    [const Offset(0.62, 0.40), const Offset(0.62, 0.48)],
    // smile arc
    [
      const Offset(0.35, 0.60),
      const Offset(0.40, 0.68),
      const Offset(0.50, 0.72),
      const Offset(0.60, 0.68),
      const Offset(0.65, 0.60),
    ],
    // hat brim
    [
      const Offset(0.12, 0.23),
      const Offset(0.25, 0.25),
      const Offset(0.40, 0.22),
      const Offset(0.50, 0.21),
      const Offset(0.60, 0.22),
      const Offset(0.75, 0.25),
      const Offset(0.88, 0.23),
    ],
    // hat crown
    [
      const Offset(0.30, 0.22),
      const Offset(0.32, 0.10),
      const Offset(0.40, 0.05),
      const Offset(0.50, 0.08),
      const Offset(0.60, 0.05),
      const Offset(0.68, 0.10),
      const Offset(0.70, 0.22),
    ],
  ]),

  // 5) Sailboat – 13 strokes (the original + sun)
  _Pattern('sailboat', [
    // sun circle (open, compressed y so it doesn't look tall on portrait)
    [
      const Offset(0.09, 0.17),
      const Offset(0.08, 0.14),
      const Offset(0.11, 0.12),
      const Offset(0.16, 0.11),
      const Offset(0.20, 0.12),
      const Offset(0.22, 0.15),
      const Offset(0.21, 0.18),
      const Offset(0.16, 0.20),
      const Offset(0.11, 0.19),
    ],
    // ray: right and slightly down
    [const Offset(0.25, 0.14), const Offset(0.37, 0.13)],
    // ray: down-right
    [const Offset(0.24, 0.18), const Offset(0.33, 0.21)],
    // ray: almost down, slightly right
    [const Offset(0.18, 0.21), const Offset(0.21, 0.27)],
    // ray: all left
    [const Offset(0.1, 0.21), const Offset(0.07, 0.26)],
    // hull
    [
      const Offset(0.18, 0.72),
      const Offset(0.22, 0.76),
      const Offset(0.32, 0.79),
      const Offset(0.50, 0.80),
      const Offset(0.68, 0.79),
      const Offset(0.78, 0.76),
      const Offset(0.82, 0.72),
    ],
    // deck
    [
      const Offset(0.20, 0.72),
      const Offset(0.35, 0.70),
      const Offset(0.50, 0.69),
      const Offset(0.65, 0.70),
      const Offset(0.80, 0.72),
    ],
    // mast
    [const Offset(0.45, 0.24), const Offset(0.45, 0.69)],
    // main sail
    [
      const Offset(0.45, 0.28),
      const Offset(0.48, 0.38),
      const Offset(0.54, 0.48),
      const Offset(0.62, 0.56),
      const Offset(0.72, 0.64),
      const Offset(0.45, 0.66),
    ],
    // jib sail
    [
      const Offset(0.45, 0.32),
      const Offset(0.38, 0.42),
      const Offset(0.29, 0.52),
      const Offset(0.25, 0.62),
      const Offset(0.45, 0.66),
    ],
    // pennant
    [
      const Offset(0.45, 0.24),
      const Offset(0.52, 0.22),
      const Offset(0.62, 0.25),
      const Offset(0.54, 0.28),
      const Offset(0.45, 0.27),
    ],
    // boom
    [const Offset(0.45, 0.66), const Offset(0.75, 0.65)],
    // waves
    [
      const Offset(0.10, 0.86),
      const Offset(0.20, 0.82),
      const Offset(0.30, 0.87),
      const Offset(0.40, 0.82),
      const Offset(0.50, 0.87),
      const Offset(0.60, 0.82),
      const Offset(0.70, 0.87),
      const Offset(0.80, 0.82),
      const Offset(0.90, 0.86),
    ],
  ], useFullCanvas: true),
];

class LevelTraceDrawing extends LevelWidget {
  const LevelTraceDrawing({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelTraceDrawing> createState() => _LevelTraceDrawingState();
}

class _LevelTraceDrawingState extends State<LevelTraceDrawing> {
  int _patternIndex = 0;
  int _currentStroke = 0;
  int _lives = 3;
  int _strokesCompletedThisPattern = 0;

  // Accumulated score across all patterns (each pattern worth 0.2)
  double _totalScore = 0.0;

  final List<Offset> _userStroke = [];
  List<List<Offset>> _scaledStrokes = [];
  Size _canvasSize = Size.zero;
  bool _done = false;

  static const double _pad = 13.0;
  static const double _tolerance = 12.0;
  static const double _safeAreaRadius = 4.0;
  static const double _startTolerance = 18.0;
  static const double _minCoverageRatio = 0.78;
  static const double _minLengthRatio = 0.70;

  _Pattern get _pattern => _patterns[_patternIndex];
  int get _totalStrokes => _pattern.strokes.length;

  void _rescale(Size size) {
    _canvasSize = size;
    if (_pattern.useFullCanvas) {
      // Full rectangle — lets the sailboat use the tall portrait space
      final w = max(0.0, size.width - 2 * _pad);
      final h = max(0.0, size.height - 2 * _pad);
      _scaledStrokes = _pattern.strokes
          .map(
            (stroke) => stroke
                .map((p) => Offset(_pad + p.dx * w, _pad + p.dy * h))
                .toList(),
          )
          .toList();
    } else {
      // Square region centered — keeps shapes proportional
      final side = max(0.0, min(size.width, size.height) - 2 * _pad);
      final ox = (size.width - side) / 2;
      final oy = (size.height - side) / 2;
      _scaledStrokes = _pattern.strokes
          .map(
            (stroke) => stroke
                .map((p) => Offset(ox + p.dx * side, oy + p.dy * side))
                .toList(),
          )
          .toList();
    }
  }

  void _onPanStart(DragStartDetails d) {
    if (_done || _currentStroke >= _scaledStrokes.length) return;
    _userStroke.clear();
    _userStroke.add(d.localPosition);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_done || _currentStroke >= _scaledStrokes.length) return;
    _userStroke.add(d.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    if (_done || _currentStroke >= _scaledStrokes.length) return;
    if (_userStroke.length < 2) {
      _failStroke();
      return;
    }

    final target = _scaledStrokes[_currentStroke];
    final start = _userStroke.first;
    final nearStart = (start - target.first).distance <= _startTolerance;
    final nearEnd = (start - target.last).distance <= _startTolerance;
    if (!nearStart && !nearEnd) {
      _failStroke();
      return;
    }

    // Coverage
    final int step = max(1, (_userStroke.length / 200).floor());
    int inTol = 0;
    for (int i = 0; i < _userStroke.length; i += step) {
      if (_distToPolyline(_userStroke[i], target) <=
          _tolerance + _safeAreaRadius)
        inTol++;
    }
    final coverage = inTol / max(1, (_userStroke.length / step).round());

    // Length
    final drawnLen = _polyLen(_userStroke);
    final targetLen = _polyLen(target);
    final lengthRatio = drawnLen / max(1e-3, targetLen);

    if (coverage < _minCoverageRatio || lengthRatio < _minLengthRatio) {
      _failStroke();
      return;
    }

    // Stroke success
    setState(() {
      _currentStroke++;
      _strokesCompletedThisPattern++;
      _userStroke.clear();
    });

    if (_currentStroke >= _totalStrokes) {
      _finishPattern();
    }
  }

  void _failStroke() {
    setState(() {
      _lives--;
      _totalScore = max(0.0, _totalScore - 0.01);
      _userStroke.clear();
    });

    if (_lives <= 0) {
      _finishPattern();
    }
  }

  void _finishPattern() {
    // Award partial score: (strokes completed / total strokes) * 0.2
    final patternScore = (_strokesCompletedThisPattern / _totalStrokes) * 0.2;
    _totalScore += patternScore;

    if (_patternIndex >= _patterns.length - 1) {
      // All patterns done
      setState(() => _done = true);
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onComplete(LevelOutcome(score: _totalScore.clamp(0.0, 1.0)));
      });
      return;
    }

    // Move to next pattern
    setState(() {
      _patternIndex++;
      _currentStroke = 0;
      _lives = 3;
      _strokesCompletedThisPattern = 0;
      _userStroke.clear();
      _rescale(_canvasSize);
    });
  }

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: _totalScore.clamp(0.0, 1.0)));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        if (size != _canvasSize) _rescale(size);

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Container(
            color: Colors.transparent,
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: LevelHud(
                    stageText: '${_patternIndex + 1}/${_patterns.length}',
                    lives: LevelHud.emojiLives(_lives, 3),
                    trailing: Text(
                      '✏️ ${_strokesCompletedThisPattern}/$_totalStrokes',
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // Canvas
                CustomPaint(
                  size: size,
                  painter: _GlyphPainter(
                    strokes: _scaledStrokes,
                    currentStroke: _currentStroke,
                    userStroke: _userStroke,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  double _distToPolyline(Offset p, List<Offset> poly) {
    double best = double.infinity;
    for (int i = 0; i < poly.length - 1; i++) {
      best = min(best, _ptSegDist(p, poly[i], poly[i + 1]));
    }
    return best;
  }

  double _ptSegDist(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (ab2 == 0) return (p - a).distance;
    double t = ((ap.dx * ab.dx + ap.dy * ab.dy) / ab2).clamp(0.0, 1.0);
    return (p - Offset(a.dx + ab.dx * t, a.dy + ab.dy * t)).distance;
  }

  double _polyLen(List<Offset> poly) {
    double len = 0;
    for (int i = 0; i < poly.length - 1; i++) {
      len += (poly[i + 1] - poly[i]).distance;
    }
    return len;
  }
}

class _GlyphPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final int currentStroke;
  final List<Offset> userStroke;

  _GlyphPainter({
    required this.strokes,
    required this.currentStroke,
    required this.userStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final isComplete = i < currentStroke;
      final isCurrent = i == currentStroke;

      final glowColor = isComplete
          ? NunuColors.successMain
          : isCurrent
          ? NunuColors.primaryMain
          : NunuColors.secondaryMain;

      final glow = Paint()
        ..color = glowColor.withValues(alpha: isCurrent ? 0.4 : 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 22 : 16
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawPath(_smooth(stroke), glow);

      final mainColor = isComplete
          ? NunuColors.successMain
          : isCurrent
          ? NunuColors.primaryLight
          : NunuColors.secondaryLight.withValues(alpha: 0.6);

      final main = Paint()
        ..color = mainColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = isCurrent ? 10 : 7
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_smooth(stroke), main);

      // Stroke number
      if (!isComplete) {
        final label = TextPainter(
          text: TextSpan(
            text: '${i + 1}',
            style: TextStyle(
              color: isCurrent ? Colors.white : Colors.white70,
              fontSize: isCurrent ? 14 : 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        label.paint(
          canvas,
          stroke.first - Offset(label.width + 8, label.height + 8),
        );
      }
    }

    // User stroke
    if (userStroke.length > 1) {
      final glow = Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(_smooth(userStroke), glow);

      final main = Paint()
        ..color = NunuColors.primaryMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_smooth(userStroke), main);
    }
  }

  Path _smooth(List<Offset> pts) {
    final path = Path();
    if (pts.isEmpty) return path;
    if (pts.length == 1) {
      path.addOval(Rect.fromCircle(center: pts.first, radius: 0.5));
      return path;
    }
    if (pts.length == 2) {
      path.moveTo(pts.first.dx, pts.first.dy);
      path.lineTo(pts.last.dx, pts.last.dy);
      return path;
    }
    path.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length - 1; i++) {
      final mid = Offset(
        (pts[i].dx + pts[i + 1].dx) / 2,
        (pts[i].dy + pts[i + 1].dy) / 2,
      );
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
    }
    path.quadraticBezierTo(
      pts[pts.length - 2].dx,
      pts[pts.length - 2].dy,
      pts.last.dx,
      pts.last.dy,
    );
    return path;
  }

  @override
  bool shouldRepaint(covariant _GlyphPainter old) =>
      old.currentStroke != currentStroke ||
      old.userStroke != userStroke ||
      old.strokes != strokes;
}
