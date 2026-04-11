import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Cardinals (lives + ramping min distance), then pac-man gap swipes.
class LevelSwipeDirections extends LevelWidget {
  const LevelSwipeDirections({super.key, required super.onComplete});

  @override
  State<LevelSwipeDirections> createState() => _LevelSwipeDirectionsState();
}

enum _Phase { cardinal, pacman }

class _LevelSwipeDirectionsState extends State<LevelSwipeDirections> {
  static const int maxLives = 5;
  static const int totalSteps = 4 + 5; // cardinals + pac rounds

  _Phase _phase = _Phase.cardinal;
  int _idxInStage = 0;
  int _pacRound = 0;
  int _totalSwipes = 0;
  int _correctSwipes = 0;
  int _wrongSwipes = 0;
  int _stepsCompleted = 0;
  int _lives = maxLives;
  Offset? _dragStart;

  final Random _rng = Random();
  late List<String> _cardinalSeq;

  /// Min swipe length (px); rises each cardinal so later steps need a fuller swipe.
  static const List<double> _cardinalMinDist = [26, 34, 44, 58];

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

  double _failScore() {
    if (totalSteps <= 0) return 0;
    return ((_stepsCompleted / totalSteps) * 0.92).clamp(0.0, 1.0);
  }

  void _fail() {
    widget.onComplete(LevelOutcome(
      score: _failScore(),
      metrics: {
        'total_swipes': _totalSwipes,
        'accuracy_pct': _accuracyPct,
        'wrong_swipes': _wrongSwipes,
        'lives_remaining': _lives,
        'steps_completed': _stepsCompleted,
        'phase': _phase.name,
      },
    ));
  }

  int get _accuracyPct {
    if (_totalSwipes == 0) return 0;
    return ((_correctSwipes / _totalSwipes) * 100).round();
  }

  void _onWrong() {
    _wrongSwipes++;
    _lives--;
    if (_lives <= 0) {
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
    setState(() {});
  }

  void _registerSwipe(bool ok) {
    _totalSwipes++;
    if (ok) {
      _correctSwipes++;
      _idxInStage++;
      _stepsCompleted++;
      if (_phase == _Phase.cardinal) {
        if (_idxInStage >= _cardinalLen) {
          _phase = _Phase.pacman;
          _idxInStage = 0;
          _pacRound = 0;
          _pacOpeningRad = _rng.nextDouble() * 2 * pi;
        }
      } else if (_phase == _Phase.pacman) {
        if (_idxInStage >= 1) {
          _idxInStage = 0;
          _pacRound++;
          if (_pacRound >= _pacLen) {
            widget.onComplete(LevelOutcome(
              score: 1,
              metrics: {
                'total_swipes': _totalSwipes,
                'accuracy_pct': _accuracyPct,
                'wrong_swipes': _wrongSwipes,
                'lives_remaining': _lives,
                'steps_completed': _stepsCompleted,
              },
            ));
            return;
          }
          _pacOpeningRad = _rng.nextDouble() * 2 * pi;
        }
      }
    } else {
      _onWrong();
      return;
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

  String _dirToWord(String dir) {
    switch (dir) {
      case 'UP':
        return 'up';
      case 'DOWN':
        return 'down';
      case 'LEFT':
        return 'left';
      case 'RIGHT':
        return 'right';
      default:
        return dir.toLowerCase();
    }
  }

  bool _checkCardinalSwipe(double dx, double dy, double dist) {
    final minD = _cardinalMinDist[_idxInStage.clamp(0, _cardinalMinDist.length - 1)];
    if (dist < minD) return false;
    final got = _cardinalFromVector(dx, dy);
    return got == _cardinalSeq[_idxInStage];
  }

  void _onPanEnd(DragEndDetails details) {
    if (_dragStart == null) return;
    final end = details.globalPosition;
    final dx = end.dx - _dragStart!.dx;
    final dy = end.dy - _dragStart!.dy;
    final dist = sqrt(dx * dx + dy * dy);

    if (_phase == _Phase.cardinal) {
      if (dist < 12) {
        _dragStart = null;
        return;
      }
      _registerSwipe(_checkCardinalSwipe(dx, dy, dist));
    } else if (_phase == _Phase.pacman) {
      if (dist < 20) {
        _dragStart = null;
        return;
      }
      _registerSwipe(_checkPacmanSwipe(dx, dy, dist));
    }
    _dragStart = null;
  }

  String get _topHint {
    if (_phase == _Phase.cardinal) {
      return 'round ${_idxInStage + 1}/$_cardinalLen';
    }
    if (_phase == _Phase.pacman) {
      return 'gap ${_pacRound + 1}/$_pacLen';
    }
    return '';
  }

  double get _currentMouthHalf => _pacMouthHalf[_pacRound];

  Widget _livesHeartsRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
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

  Widget _cardinalPanel() {
    final dir = _cardinalSeq[_idxInStage];
    final word = _dirToWord(dir);
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: NunuColors.primaryMain.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryDark.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          'swipe $word',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            height: 1.2,
            color: NunuColors.textPrimary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

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
              child: Row(
                children: [
                  Text(
                    _topHint,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.25,
                      color: NunuColors.primaryLight.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  _livesHeartsRow(),
                ],
              ),
            ),
            if (_phase == _Phase.pacman)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  'swipe out through the gap',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.25,
                    color: NunuColors.textSecondary.withValues(alpha: 0.95),
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
                      child: _cardinalPanel(),
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
