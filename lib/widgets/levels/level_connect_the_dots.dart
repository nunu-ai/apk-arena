import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelConnectTheDots extends LevelWidget {
  const LevelConnectTheDots({super.key, required super.onComplete});

  @override
  State<LevelConnectTheDots> createState() => _LevelConnectTheDotsState();
}

class _LevelConnectTheDotsState extends State<LevelConnectTheDots> {
  static const List<int> _stageDotCounts = [5, 7, 12, 7, 9, 14];
  static const List<bool> _stageShuffled = [false, false, false, true, true, true];
  static const int _maxLives = 10;
  static const double _dotHitRadius = 40;
  static const double _minDotSpacing = _dotHitRadius * 2;

  final List<Offset> _dotPositions = [];
  final List<int> _connectedPositions = [];
  final List<Offset> _linePoints = [];

  /// Maps position index → display number (0-based).
  /// For normal stages this is identity; for the last stage it's shuffled.
  List<int> _displayNumbers = [];

  /// Reverse: maps display number → position index.
  List<int> _positionForNumber = [];

  bool _isDrawing = false;
  bool _levelFinished = false;
  int _totalDots = 0;
  Size _canvasSize = Size.zero;
  int _stageIndex = 0;
  int _stagesCleared = 0;
  int _lives = _maxLives;
  int _failedTraces = 0;
  int _nextExpectedNumber = 0;

  int get _dotsThisStage => _stageDotCounts[_stageIndex];
  bool get _isShuffledStage => _stageShuffled[_stageIndex];

  void _generateDots(Size size, {bool force = false}) {
    if (!force && _dotPositions.isNotEmpty) return;

    final random = Random();
    _dotPositions.clear();
    _connectedPositions.clear();
    _linePoints.clear();
    _isDrawing = false;
    _nextExpectedNumber = 0;

    _totalDots = _dotsThisStage;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radiusX = (size.width / 2) - 50;
    final radiusY = (size.height / 2) - 60;

    for (int i = 0; i < _totalDots; i++) {
      Offset? candidate;
      for (int attempt = 0; attempt < 200; attempt++) {
        final angle =
            (2 * pi * i) / _totalDots + (random.nextDouble() - 0.5) * 1.2;
        final rFactor = 0.35 + random.nextDouble() * 0.65;
        final x = centerX + cos(angle) * radiusX * rFactor;
        final y = centerY + sin(angle) * radiusY * rFactor;

        final clamped = Offset(
          x.clamp(40.0, size.width - 40.0),
          y.clamp(60.0, size.height - 40.0),
        );

        final tooClose = _dotPositions.any(
          (existing) => (existing - clamped).distance < _minDotSpacing,
        );

        if (!tooClose) {
          candidate = clamped;
          break;
        }
      }
      _dotPositions.add(
        candidate ??
            Offset(
              (centerX + cos(2 * pi * i / _totalDots) * radiusX * 0.8)
                  .clamp(40.0, size.width - 40.0),
              (centerY + sin(2 * pi * i / _totalDots) * radiusY * 0.8)
                  .clamp(60.0, size.height - 40.0),
            ),
      );
    }

    if (_isShuffledStage) {
      _displayNumbers = List.generate(_totalDots, (i) => i)..shuffle(random);
    } else {
      _displayNumbers = List.generate(_totalDots, (i) => i);
    }

    _positionForNumber = List.filled(_totalDots, 0);
    for (int pos = 0; pos < _totalDots; pos++) {
      _positionForNumber[_displayNumbers[pos]] = pos;
    }
  }

  int? _getDotAtPosition(Offset position) {
    int? closest;
    double closestDist = double.infinity;
    for (int i = 0; i < _dotPositions.length; i++) {
      final d = (position - _dotPositions[i]).distance;
      if (d < _dotHitRadius && d < closestDist) {
        closest = i;
        closestDist = d;
      }
    }
    return closest;
  }

  double _calculateScore() {
    return (_stagesCleared * 0.15) + (_lives * 0.02);
  }

  void _finishLevel() {
    if (_levelFinished) return;
    _levelFinished = true;
    widget.onComplete(LevelOutcome(
      score: _calculateScore(),
      metrics: {
        'stages_cleared': _stagesCleared,
        'lives_remaining': _lives,
        'max_lives': _maxLives,
        'failed_traces': _failedTraces,
      },
    ));
  }

  void _loseLife() {
    if (_levelFinished) return;

    setState(() {
      _failedTraces++;
      _lives = max(0, _lives - 1);
      _connectedPositions.clear();
      _linePoints.clear();
      _isDrawing = false;
      _nextExpectedNumber = 0;
    });

    if (_lives == 0) {
      _finishLevel();
    }
  }

  void _advanceStageOrWin() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      if (_stagesCleared >= _stageDotCounts.length) {
        _finishLevel();
        return;
      }
      setState(() {
        _stageIndex = _stagesCleared;
        _generateDots(_canvasSize, force: true);
      });
    });
  }

  void _onPanStart(DragStartDetails details) {
    if (_dotPositions.isEmpty || _levelFinished) return;

    final localPosition = details.localPosition;
    final posIndex = _getDotAtPosition(localPosition);
    if (posIndex == null) return;

    final startPosition = _positionForNumber[0];
    if (posIndex == startPosition && !_connectedPositions.contains(posIndex)) {
      setState(() {
        _isDrawing = true;
        _connectedPositions.add(posIndex);
        _linePoints.add(_dotPositions[posIndex]);
        _nextExpectedNumber = 1;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing || _levelFinished) return;

    final localPosition = details.localPosition;
    final posIndex = _getDotAtPosition(localPosition);

    if (posIndex != null && !_connectedPositions.contains(posIndex)) {
      final displayNum = _displayNumbers[posIndex];
      if (displayNum == _nextExpectedNumber) {
        setState(() {
          _linePoints.add(localPosition);
          _connectedPositions.add(posIndex);
          _linePoints.add(_dotPositions[posIndex]);
          _nextExpectedNumber++;

          if (_connectedPositions.length == _totalDots) {
            _isDrawing = false;
            _stagesCleared++;
            _advanceStageOrWin();
          }
        });
      } else {
        _loseLife();
      }
      return;
    }

    setState(() {
      _linePoints.add(localPosition);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_connectedPositions.length < _totalDots && _isDrawing) {
      _loseLife();
    }
  }

  Widget _livesRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_maxLives, (i) {
        final alive = i < _lives;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 1),
          child: Icon(
            alive ? Icons.favorite : Icons.favorite_border,
            size: 14,
            color: alive
                ? NunuColors.primaryMain
                : NunuColors.primaryLight.withValues(alpha: 0.28),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        if (_canvasSize != size) {
          _canvasSize = size;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            setState(() {
              _generateDots(size, force: true);
            });
          });
        }

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (_dotPositions.isNotEmpty)
                CustomPaint(
                  size: size,
                  painter: ConnectDotsPainter(
                    dotPositions: _dotPositions,
                    connectedPositions: _connectedPositions,
                    linePoints: _linePoints,
                    displayNumbers: _displayNumbers,
                  ),
                ),
              Positioned(
                right: 12,
                top: 8,
                child: IgnorePointer(
                  child: _livesRow(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConnectDotsPainter extends CustomPainter {
  final List<Offset> dotPositions;
  final List<int> connectedPositions;
  final List<Offset> linePoints;
  final List<int> displayNumbers;

  ConnectDotsPainter({
    required this.dotPositions,
    required this.connectedPositions,
    required this.linePoints,
    required this.displayNumbers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (linePoints.length > 1) {
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

      final linePaint = Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.8)
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      canvas.drawPath(path, linePaint);
    }

    for (int i = 0; i < dotPositions.length; i++) {
      final isConnected = connectedPositions.contains(i);
      final displayNum = i < displayNumbers.length ? displayNumbers[i] : i;

      if (i % 2 == 0) {
        _drawStar(canvas, dotPositions[i], isConnected, displayNum);
      } else {
        _drawPlanet(canvas, dotPositions[i], isConnected, displayNum);
      }
    }

    if (connectedPositions.length == dotPositions.length &&
        dotPositions.isNotEmpty) {
      final textPainter = TextPainter(
        text: const TextSpan(
          text: 'constellation complete!',
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

  void _drawStar(
    Canvas canvas,
    Offset center,
    bool isConnected,
    int displayNum,
  ) {
    final color = isConnected ? const Color(0xFFFFD700) : Colors.grey.shade600;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    _drawStarPath(canvas, center, 25, glowPaint);

    final starPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    _drawStarPath(canvas, center, 18, starPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isConnected ? 0.8 : 0.3)
      ..style = PaintingStyle.fill;
    _drawStarPath(canvas, center, 8, highlightPaint);

    _drawNumber(
      canvas,
      center,
      displayNum,
      isConnected ? Colors.black : Colors.white,
    );
  }

  void _drawStarPath(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final outerRadius = size;
    final innerRadius = size * 0.4;
    const numPoints = 5;

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

  void _drawPlanet(
    Canvas canvas,
    Offset center,
    bool isConnected,
    int displayNum,
  ) {
    final planetColors = [
      const Color(0xFF4169E1),
      const Color(0xFFFF6347),
      const Color(0xFF9370DB),
      const Color(0xFF20B2AA),
      const Color(0xFFFF8C00),
    ];

    final baseColor = planetColors[displayNum % planetColors.length];
    final color = isConnected ? baseColor : Colors.grey.shade600;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(center, 25, glowPaint);

    final planetPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18, planetPaint);

    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center + const Offset(4, 4), 16, shadowPaint);

    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: isConnected ? 0.6 : 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center - const Offset(5, 5), 6, highlightPaint);

    if (displayNum % 3 == 1) {
      _drawPlanetRings(canvas, center, color, isConnected);
    }

    _drawNumber(canvas, center, displayNum, Colors.white);
  }

  void _drawPlanetRings(
    Canvas canvas,
    Offset center,
    Color color,
    bool isConnected,
  ) {
    final ringPaint = Paint()
      ..color = color.withValues(alpha: isConnected ? 0.6 : 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final rect = Rect.fromCenter(center: center, width: 50, height: 15);
    canvas.drawOval(rect, ringPaint);

    final innerRect = Rect.fromCenter(center: center, width: 44, height: 12);
    canvas.drawOval(innerRect, ringPaint);
  }

  void _drawNumber(
    Canvas canvas,
    Offset center,
    int displayNum,
    Color textColor,
  ) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: '${displayNum + 1}',
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
  bool shouldRepaint(ConnectDotsPainter oldDelegate) => true;
}
