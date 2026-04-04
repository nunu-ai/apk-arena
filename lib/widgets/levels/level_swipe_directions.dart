import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Cardinals, then pac-man gap swipes only; gap shrinks each round.
class LevelSwipeDirections extends LevelWidget {
  const LevelSwipeDirections({super.key, required super.onComplete});

  @override
  State<LevelSwipeDirections> createState() => _LevelSwipeDirectionsState();
}

enum _Phase { cardinal, pacman }

class _LevelSwipeDirectionsState extends State<LevelSwipeDirections> {
  static const int maxWrongSwipes = 15;

  _Phase _phase = _Phase.cardinal;
  int _idxInStage = 0;
  int _pacRound = 0; // 0.._pacMouthHalf.length-1
  int _totalSwipes = 0;
  int _correctSwipes = 0;
  int _wrongSwipes = 0;
  Offset? _dragStart;

  final Random _rng = Random();

  late List<String> _cardinalSeq;
  /// Mouth half-angle (radians); smaller = narrower gap, harder.
  static const List<double> _pacMouthHalf = [0.5, 0.38, 0.28, 0.2, 0.14];
  late double _pacOpeningRad;

  @override
  void initState() {
    super.initState();
    _buildSequences();
    _pacOpeningRad = _rng.nextDouble() * 2 * pi;
  }

  void _buildSequences() {
    const dirs = ['UP', 'DOWN', 'LEFT', 'RIGHT'];
    _cardinalSeq = List<String>.from(dirs)..shuffle(_rng);
  }

  int get _cardinalLen => _cardinalSeq.length;
  int get _pacLen => _pacMouthHalf.length;

  void _fail() {
    widget.onComplete(
      false,
      metrics: {
        'total_swipes': _totalSwipes,
        'accuracy_pct': _accuracyPct,
        'stages_cleared': _phase == _Phase.cardinal ? 0 : 1,
      },
    );
  }

  int get _accuracyPct {
    if (_totalSwipes == 0) return 0;
    return ((_correctSwipes / _totalSwipes) * 100).round();
  }

  void _registerSwipe(bool ok) {
    _totalSwipes++;
    if (ok) {
      _correctSwipes++;
      _idxInStage++;
      if (_phase == _Phase.cardinal) {
        if (_idxInStage >= _cardinalLen) {
          _phase = _Phase.pacman;
          _idxInStage = 0;
          _pacRound = 0;
          _pacOpeningRad = _rng.nextDouble() * 2 * pi;
        }
      } else {
        if (_idxInStage >= 1) {
          _idxInStage = 0;
          _pacRound++;
          if (_pacRound >= _pacLen) {
            widget.onComplete(
              true,
              metrics: {
                'total_swipes': _totalSwipes,
                'accuracy_pct': _accuracyPct,
                'stages_cleared': 2,
              },
            );
            return;
          }
          _pacOpeningRad = _rng.nextDouble() * 2 * pi;
        }
      }
    } else {
      _wrongSwipes++;
      if (_wrongSwipes >= maxWrongSwipes) {
        _fail();
        return;
      }
      if (_phase == _Phase.cardinal) {
        _idxInStage = 0;
        _cardinalSeq.shuffle(_rng);
      } else {
        _idxInStage = 0;
        _pacOpeningRad = _rng.nextDouble() * 2 * pi;
      }
    }
    setState(() {});
  }

  double _normAngleDiff(double a, double b) {
    var d = a - b;
    while (d > pi) {
      d -= 2 * pi;
    }
    while (d < -pi) {
      d += 2 * pi;
    }
    return d.abs();
  }

  bool _checkPacmanSwipe(double dx, double dy, double dist) {
    if (dist < 40) return false;
    final theta = atan2(dy, dx);
    final half = _pacMouthHalf[_pacRound];
    return _normAngleDiff(theta, _pacOpeningRad) <= half;
  }

  String _cardinalFromVector(double dx, double dy) {
    if (dx.abs() > dy.abs()) {
      return dx > 0 ? 'RIGHT' : 'LEFT';
    }
    return dy > 0 ? 'DOWN' : 'UP';
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragStart == null) return;
    final end = details.globalPosition;
    final dx = end.dx - _dragStart!.dx;
    final dy = end.dy - _dragStart!.dy;
    final dist = sqrt(dx * dx + dy * dy);
    if (dist < 20) {
      _dragStart = null;
      return;
    }

    if (_phase == _Phase.cardinal) {
      final got = _cardinalFromVector(dx, dy);
      _registerSwipe(got == _cardinalSeq[_idxInStage]);
    } else {
      _registerSwipe(_checkPacmanSwipe(dx, dy, dist));
    }
    _dragStart = null;
  }

  String get _prompt {
    if (_phase == _Phase.cardinal) {
      return 'swipe ${_cardinalSeq[_idxInStage]}';
    }
    return 'swipe out through the gap (${_pacRound + 1}/$_pacLen)';
  }

  double get _currentMouthHalf => _pacMouthHalf[_pacRound];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (d) => _dragStart = d.globalPosition,
      onPanEnd: _onPanEnd,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              color: NunuColors.backgroundPaper,
              child: Text(
                _prompt,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.25,
                  color: NunuColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Expanded(
              child: _phase == _Phase.pacman
                  ? Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: CustomPaint(
                        painter: _PacmanPainter(
                          openingRad: _pacOpeningRad,
                          mouthHalf: _currentMouthHalf,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    )
                  : ColoredBox(
                      color: Colors.transparent,
                      child: SizedBox.expand(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Wedge + larger center hub; matches primary control colors (no eye).
class _PacmanPainter extends CustomPainter {
  _PacmanPainter({
    required this.openingRad,
    required this.mouthHalf,
  });

  final double openingRad;
  final double mouthHalf;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = min(size.width, size.height) * 0.36;

    final start = openingRad + mouthHalf;
    final sweep = 2 * pi - 2 * mouthHalf;

    final wedge = Paint()
      ..color = NunuColors.primaryMain.withValues(alpha: 0.88)
      ..style = PaintingStyle.fill;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      start,
      sweep,
      true,
      wedge,
    );

    final hubR = r * 0.32;
    canvas.drawCircle(
      c,
      hubR,
      Paint()
        ..color = NunuColors.primaryLight.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      c,
      hubR * 0.92,
      Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _PacmanPainter oldDelegate) =>
      openingRad != oldDelegate.openingRad ||
      mouthHalf != oldDelegate.mouthHalf;
}
