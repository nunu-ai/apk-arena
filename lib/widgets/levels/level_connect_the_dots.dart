import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelConnectTheDots extends LevelWidget {
  const LevelConnectTheDots({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelConnectTheDots> createState() => _LevelConnectTheDotsState();
}

class _LevelConnectTheDotsState extends State<LevelConnectTheDots> {
  final List<Offset> _dotPositions = [];
  final List<int> _connectedDots = [];
  final List<Offset> _linePoints = [];
  bool _isDrawing = false;
  late int _totalDots;
  Size _canvasSize = Size.zero;

  @override
  void initState() {
    super.initState();
    // Dots will be generated after we know the canvas size
  }

  void _generateDots(Size size) {
    if (_dotPositions.isNotEmpty) return; // Already generated

    final random = Random();
    _dotPositions.clear();

    // Randomize number of dots between 4 and 8
    _totalDots = 4 + random.nextInt(5);

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Generate dots with more randomization
    for (int i = 0; i < _totalDots; i++) {
      // More random angle distribution
      final angle = (2 * pi * i) / _totalDots + (random.nextDouble() - 0.5) * 1.2;

      // More varied radius
      final radius = 60 + random.nextDouble() * 80;

      // Add some extra random offset
      final randomOffsetX = (random.nextDouble() - 0.5) * 40;
      final randomOffsetY = (random.nextDouble() - 0.5) * 40;

      final x = centerX + cos(angle) * radius + randomOffsetX;
      final y = centerY + sin(angle) * radius + randomOffsetY;

      _dotPositions.add(Offset(x, y));
    }
  }

  int? _getDotAtPosition(Offset position) {
    for (int i = 0; i < _dotPositions.length; i++) {
      final dot = _dotPositions[i];
      final distance = (position - dot).distance;
      if (distance < 40) {
        return i;
      }
    }
    return null;
  }

  void _onPanStart(DragStartDetails details) {
    if (_dotPositions.isEmpty) return;

    final localPosition = details.localPosition;
    final dotIndex = _getDotAtPosition(localPosition);

    if (dotIndex != null && !_connectedDots.contains(dotIndex)) {
      setState(() {
        _isDrawing = true;
        _connectedDots.add(dotIndex);
        _linePoints.add(_dotPositions[dotIndex]);
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    final localPosition = details.localPosition;
    final dotIndex = _getDotAtPosition(localPosition);

    setState(() {
      _linePoints.add(localPosition);

      if (dotIndex != null && !_connectedDots.contains(dotIndex)) {
        _connectedDots.add(dotIndex);
        _linePoints.add(_dotPositions[dotIndex]);

        // Check if all dots are connected
        if (_connectedDots.length == _totalDots) {
          _isDrawing = false;
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onComplete(true);
          });
        }
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_connectedDots.length < _totalDots) {
      // Reset if not all dots connected
      setState(() {
        _isDrawing = false;
        _connectedDots.clear();
        _linePoints.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        // Generate dots once we have the size
        if (_canvasSize != size) {
          _canvasSize = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _generateDots(size);
            });
          });
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
                // Progress indicator
                Positioned(
                  top: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '${_connectedDots.length} / $_totalDots',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: NunuColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                // Canvas for drawing
                if (_dotPositions.isNotEmpty)
                  CustomPaint(
                    size: size,
                    painter: ConnectDotsPainter(
                      dotPositions: _dotPositions,
                      connectedDots: _connectedDots,
                      linePoints: _linePoints,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class ConnectDotsPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<int> connectedDots;
  final List<Offset> linePoints;

  ConnectDotsPainter({
    required this.dotPositions,
    required this.connectedDots,
    required this.linePoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw the line path with a glowing effect
    if (linePoints.length > 1) {
      // Outer glow
      final glowPaint = Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.3)
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      final path = Path();
      path.moveTo(linePoints.first.dx, linePoints.first.dy);
      for (int i = 1; i < linePoints.length; i++) {
        path.lineTo(linePoints[i].dx, linePoints[i].dy);
      }
      canvas.drawPath(path, glowPaint);

      // Main line
      final linePaint = Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.8)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, linePaint);
    }

    // Draw all dots as stars or planets
    for (int i = 0; i < dotPositions.length; i++) {
      final isConnected = connectedDots.contains(i);

      // Alternate between stars and planets
      final isEven = i % 2 == 0;

      if (isEven) {
        // Draw a star
        _drawStar(canvas, dotPositions[i], isConnected, i);
      } else {
        // Draw a planet
        _drawPlanet(canvas, dotPositions[i], isConnected, i);
      }
    }

    // Draw constellation name when all connected
    if (connectedDots.length == dotPositions.length) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: '✨ Constellation Complete! ✨',
          style: TextStyle(
            color: NunuColors.primaryLight,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(size.width / 2 - textPainter.width / 2, size.height - 50),
      );
    }
  }

  void _drawStar(Canvas canvas, Offset center, bool isConnected, int index) {
    final color = isConnected ? const Color(0xFFFFD700) : Colors.grey.shade600;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    _drawStarPath(canvas, center, 25, glowPaint);

    // Main star
    final starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    _drawStarPath(canvas, center, 18, starPaint);

    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isConnected ? 0.8 : 0.3)
      ..style = PaintingStyle.fill;
    _drawStarPath(canvas, center, 8, highlightPaint);

    // Draw number
    _drawNumber(canvas, center, index, isConnected ? Colors.black : Colors.white);
  }

  void _drawStarPath(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;
    final numPoints = 5;

    for (int i = 0; i < numPoints * 2; i++) {
      final angle = (pi * i / numPoints) - pi / 2;
      final radius = i.isEven ? outerRadius : innerRadius;
      final x = center.dx + cos(angle) * radius;
      final y = center.dy + sin(angle) * radius;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawPlanet(Canvas canvas, Offset center, bool isConnected, int index) {
    // Planet colors - different for each planet
    final planetColors = [
      const Color(0xFF4169E1), // Blue
      const Color(0xFFFF6347), // Red/Mars
      const Color(0xFF9370DB), // Purple
      const Color(0xFF20B2AA), // Teal
      const Color(0xFFFF8C00), // Orange
    ];

    final baseColor = planetColors[index % planetColors.length];
    final color = isConnected ? baseColor : Colors.grey.shade600;

    // Outer glow/atmosphere
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 25, glowPaint);

    // Planet body
    final planetPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, planetPaint);

    // Shadow/dimension
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + const Offset(4, 4), 16, shadowPaint);

    // Highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isConnected ? 0.6 : 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center - const Offset(5, 5), 6, highlightPaint);

    // Planet rings (for some planets)
    if (index % 3 == 1) {
      _drawPlanetRings(canvas, center, color, isConnected);
    }

    // Draw number
    _drawNumber(canvas, center, index, Colors.white);
  }

  void _drawPlanetRings(Canvas canvas, Offset center, Color color, bool isConnected) {
    final ringPaint = Paint()
      ..color = color.withValues(alpha: isConnected ? 0.6 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    // Draw elliptical ring
    final rect = Rect.fromCenter(center: center, width: 50, height: 15);
    canvas.drawOval(rect, ringPaint);

    // Inner ring
    final innerRect = Rect.fromCenter(center: center, width: 44, height: 12);
    canvas.drawOval(innerRect, ringPaint);
  }

  void _drawNumber(Canvas canvas, Offset center, int index, Color textColor) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${index + 1}',
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(ConnectDotsPainter oldDelegate) {
    return true;
  }
}