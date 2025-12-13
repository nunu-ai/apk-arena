import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelTraceDrawing extends LevelWidget {
  const LevelTraceDrawing({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelTraceDrawing> createState() => _LevelTraceDrawingState();
}

class _LevelTraceDrawingState extends State<LevelTraceDrawing> {
  // Cool stylized sailboat - elegant and modern
  // Normalized coordinates (0..1)
  final List<List<Offset>> _glyphStrokesNormalized = [
    // 1) Hull - sleek curved bottom
    [
      const Offset(0.18, 0.72),
      const Offset(0.22, 0.76),
      const Offset(0.32, 0.79),
      const Offset(0.50, 0.80),
      const Offset(0.68, 0.79),
      const Offset(0.78, 0.76),
      const Offset(0.82, 0.72),
    ],
    // 2) Deck line with slight curve
    [
      const Offset(0.20, 0.72),
      const Offset(0.35, 0.70),
      const Offset(0.50, 0.69),
      const Offset(0.65, 0.70),
      const Offset(0.80, 0.72),
    ],
    // 3) Mast - tall and proud
    [
      const Offset(0.45, 0.24),
      const Offset(0.45, 0.69),
    ],
    // 4) Main sail - large billowing triangle
    [
      const Offset(0.45, 0.28),
      const Offset(0.48, 0.38),
      const Offset(0.54, 0.48),
      const Offset(0.62, 0.56),
      const Offset(0.72, 0.64),
      const Offset(0.45, 0.66),
    ],
    // 5) Jib sail - front sail with nice curve
    [
      const Offset(0.45, 0.32),
      const Offset(0.38, 0.42),
      const Offset(0.29, 0.52),
      const Offset(0.25, 0.62),
      const Offset(0.45, 0.66),
    ],
    // 6) Pennant flag - flowing in the wind
    [
      const Offset(0.45, 0.24),
      const Offset(0.52, 0.22),
      const Offset(0.62, 0.25),
      const Offset(0.54, 0.28),
      const Offset(0.45, 0.27),
    ],
    // 7) Boom (horizontal sail support)
    [
      const Offset(0.45, 0.66),
      const Offset(0.75, 0.65),
    ],
    // 8) Waves - gentle ocean swell
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
  ];

  // Scaled strokes for current canvas size
  List<List<Offset>> _glyphStrokes = [];

  // User drawing for current stroke
  final List<Offset> _userStroke = [];
  int _currentStroke = 0;
  Size _canvasSize = Size.zero;

  static const double _pad = 13.0;
  static const double _tolerance = 10.0; // tighter tolerance
  static const double _minCoverageRatio = 0.85; // require closer adherence
  static const double _minLengthRatio = 0.85; // prevent straight-line shortcuts

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        if (size != _canvasSize) {
          _canvasSize = size;
          _glyphStrokes = _scaleGlyph(size);
        }

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
                // Header / instructions
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      const Text(
                        'trace the sailboat in order. stay inside the glow.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'stroke ${_currentStroke + 1} / ${_glyphStrokesNormalized.length}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: NunuColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Drawing canvas
                CustomPaint(
                  size: size,
                  painter: _GlyphPainter(
                    strokes: _glyphStrokes,
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

  List<List<Offset>> _scaleGlyph(Size size) {
    final usableW = max(0.0, size.width - 2 * _pad);
    final usableH = max(0.0, size.height - 2 * _pad);

    return _glyphStrokesNormalized
        .map((stroke) => stroke
        .map((p) => Offset(_pad + p.dx * usableW, _pad + p.dy * usableH))
        .toList())
        .toList();
  }

  void _onPanStart(DragStartDetails d) {
    if (_currentStroke >= _glyphStrokes.length) return;
    _userStroke.clear();
    _userStroke.add(d.localPosition);
    setState(() {});
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_currentStroke >= _glyphStrokes.length) return;
    _userStroke.add(d.localPosition);
    setState(() {});
  }

  void _onPanEnd(DragEndDetails d) {
    if (_currentStroke >= _glyphStrokes.length) return;
    if (_userStroke.length < 2) {
      _failStroke();
      return;
    }

    final target = _glyphStrokes[_currentStroke];

    // Check start near an endpoint (either direction)
    final start = _userStroke.first;
    final nearStart = (start - target.first).distance <= _tolerance;
    final nearEnd = (start - target.last).distance <= _tolerance;
    if (!nearStart && !nearEnd) {
      _failStroke();
      return;
    }

    // Coverage check
    final int step = max(1, (_userStroke.length / 200).floor());
    int inTol = 0;
    for (int i = 0; i < _userStroke.length; i += step) {
      final dist = _distanceToPolyline(_userStroke[i], target);
      if (dist <= _tolerance) inTol++;
    }
    final coverageRatio = inTol / (max(1, (_userStroke.length / step).round()));

    // Length check
    final drawnLen = _polylineLength(_userStroke);
    final targetLen = _polylineLength(target);
    final lengthRatio = drawnLen / max(1e-3, targetLen);

    final ok = coverageRatio >= _minCoverageRatio && lengthRatio >= _minLengthRatio;
    if (!ok) {
      _failStroke();
      return;
    }

    // Success
    setState(() {
      _currentStroke += 1;
      _userStroke.clear();
    });

    if (_currentStroke >= _glyphStrokes.length) {
      Future.delayed(const Duration(milliseconds: 350), () {
        widget.onComplete(true);
      });
    }
  }

  void _failStroke() {
    widget.onComplete(false);
    setState(() {
      _userStroke.clear();
    });
  }

  double _distanceToPolyline(Offset p, List<Offset> poly) {
    double best = double.infinity;
    for (int i = 0; i < poly.length - 1; i++) {
      best = min(best, _pointToSegmentDistance(p, poly[i], poly[i + 1]));
    }
    return best;
  }

  double _pointToSegmentDistance(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final ab2 = ab.dx * ab.dx + ab.dy * ab.dy;
    if (ab2 == 0) return (p - a).distance;
    double t = (ap.dx * ab.dx + ap.dy * ab.dy) / ab2;
    t = t.clamp(0.0, 1.0);
    final proj = Offset(a.dx + ab.dx * t, a.dy + ab.dy * t);
    return (p - proj).distance;
  }

  double _polylineLength(List<Offset> poly) {
    double len = 0.0;
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
    // Draw completed strokes with a filled effect
    for (int i = 0; i < strokes.length; i++) {
      final stroke = strokes[i];
      final isComplete = i < currentStroke;
      final isCurrent = i == currentStroke;

      // Glow underlay
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
      canvas.drawPath(_smoothPathFromPoints(stroke), glow);

      // Main stroke
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
      canvas.drawPath(_smoothPathFromPoints(stroke), main);

      // Stroke number label
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
        final start = stroke.first;
        label.paint(canvas, start - Offset(label.width + 8, label.height + 8));
      }
    }

    // User's current stroke
    if (userStroke.length > 1) {
      final glow = Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawPath(_smoothPathFromPoints(userStroke), glow);

      final main = Paint()
        ..color = NunuColors.primaryMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_smoothPathFromPoints(userStroke), main);
    }
  }

  Path _smoothPathFromPoints(List<Offset> pts) {
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
  bool shouldRepaint(covariant _GlyphPainter oldDelegate) {
    return oldDelegate.currentStroke != currentStroke ||
        oldDelegate.userStroke != userStroke ||
        oldDelegate.strokes != strokes;
  }
}
