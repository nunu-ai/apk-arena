import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

/// Cardinal swipes, then pac-man gaps, then banner slots.
class LevelSwipeDirections extends LevelWidget {
  const LevelSwipeDirections({super.key, required super.onComplete});

  @override
  State<LevelSwipeDirections> createState() => _LevelSwipeDirectionsState();
}

enum _Phase { banner, cardinal, pacman }

class _LevelSwipeDirectionsState extends State<LevelSwipeDirections> {
  static const int maxLives = 7;
  static const int _cardinalRoundsTotal = 4;
  static const int _pacRoundsTotal = 5;
  static const int _bannerRoundsTotal = 5;
  static const double _lifeScore = 0.02;
  static const int _totalRequiredSwipes =
      _cardinalRoundsTotal + _pacRoundsTotal + _bannerRoundsTotal;
  static const double _stepScore =
      (1.0 - (maxLives * _lifeScore)) / _totalRequiredSwipes;

  _Phase _phase = _Phase.cardinal;
  int _idxInStage = 0;
  int _bannerRound = 0;
  int _pacRound = 0;
  int _totalSwipes = 0;
  int _correctSwipes = 0;
  int _wrongSwipes = 0;
  int _stepsCompleted = 0;
  int _lives = maxLives;
  Offset? _dragStart;
  final GlobalKey _arenaKey = GlobalKey();

  /// Banner phase: track path in play-area local coords.
  Offset? _bannerLastLocal;
  bool _bannerPassedThroughGap = false;
  bool _bannerGestureDead = false;

  final Random _rng = Random();
  late List<String> _cardinalSeq;

  /// Min swipe length (px); rises each cardinal so later steps need a fuller swipe.
  static const List<double> _cardinalMinDist = [26, 34, 44, 58];

  /// Mouth half-angle (radians); smaller = narrower gap, harder.
  static const List<double> _pacMouthHalf = [0.38, 0.28, 0.2, 0.14, 0.09];

  /// Later banner rounds get a narrower slit.
  static const List<double> _bannerGapWidthScale = [
    1.0,
    0.92,
    0.84,
    0.76,
    0.68,
  ];

  late double _pacOpeningRad;

  /// Horizontal offset of banner gap center in [-1, 1] times max lateral shift.
  double _bannerGapNorm = 0;
  double _bannerTiltDir = 1;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: _scoreForOutcome()));
    _buildSequences();
    _pacOpeningRad = _rng.nextDouble() * 2 * pi;
    _rerollBannerGap();
  }

  void _buildSequences() {
    const dirs = ['UP', 'DOWN', 'LEFT', 'RIGHT'];
    _cardinalSeq = List<String>.from(dirs)..shuffle(_rng);
  }

  int get _cardinalLen => _cardinalRoundsTotal;
  int get _pacLen => _pacRoundsTotal;

  void _resetBannerGesture() {
    _bannerLastLocal = null;
    _bannerPassedThroughGap = false;
    _bannerGestureDead = false;
  }

  void _rerollBannerGap() {
    _bannerGapNorm = _rng.nextDouble() * 2 - 1;
    _bannerTiltDir = _rng.nextBool() ? 1 : -1;
  }

  double _scoreForOutcome() {
    return (_stepsCompleted * _stepScore + _lives * _lifeScore).clamp(0.0, 1.0);
  }

  void _fail() {
    widget.onComplete(
      LevelOutcome(
        score: _scoreForOutcome(),
        metrics: {
          'total_swipes': _totalSwipes,
          'accuracy_pct': _accuracyPct,
          'wrong_swipes': _wrongSwipes,
          'lives_remaining': _lives,
        },
      ),
    );
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
    if (_phase == _Phase.banner) {
      _idxInStage = 0;
      _rerollBannerGap();
      _resetBannerGesture();
    } else if (_phase == _Phase.cardinal) {
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
      if (_phase == _Phase.banner) {
        if (_idxInStage >= 1) {
          _idxInStage = 0;
          _bannerRound++;
          if (_bannerRound >= _bannerRoundsTotal) {
            widget.onComplete(
              LevelOutcome(
                score: _scoreForOutcome(),
                metrics: {
                  'total_swipes': _totalSwipes,
                  'accuracy_pct': _accuracyPct,
                  'wrong_swipes': _wrongSwipes,
                  'lives_remaining': _lives,
                },
              ),
            );
            return;
          } else {
            _rerollBannerGap();
            _resetBannerGesture();
          }
        }
      } else if (_phase == _Phase.cardinal) {
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
            _phase = _Phase.banner;
            _idxInStage = 0;
            _bannerRound = 0;
            _rerollBannerGap();
            _resetBannerGesture();
          } else {
            _pacOpeningRad = _rng.nextDouble() * 2 * pi;
          }
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
    final half = _pacMouthHalf[_pacRound.clamp(0, _pacMouthHalf.length - 1)];
    return _normAngleDiff(theta, _pacOpeningRad) <= half;
  }

  ({
    double yt,
    double yb,
    double topGapLeft,
    double topGapRight,
    double bottomGapLeft,
    double bottomGapRight,
  })
  _bannerGeom(Size size) {
    final bh = max(48.0, min(76.0, size.height * 0.12));
    final cy = size.height / 2;
    final yt = cy - bh / 2;
    final yb = cy + bh / 2;
    final gapScale =
        _bannerGapWidthScale[_bannerRound.clamp(
          0,
          _bannerGapWidthScale.length - 1,
        )];
    final gapW = max(16.0, max(20.0, min(34.0, size.width * 0.095)) * gapScale);
    final tiltDx = max(24.0, min(32.0, size.width * 0.09)) * _bannerTiltDir;
    final maxShift = max(0.0, size.width / 2 - 18 - (gapW + tiltDx.abs()) / 2);
    final gcx = size.width / 2 + _bannerGapNorm * maxShift;
    final topCenter = gcx - tiltDx / 2;
    final bottomCenter = gcx + tiltDx / 2;
    return (
      yt: yt,
      yb: yb,
      topGapLeft: topCenter - gapW / 2,
      topGapRight: topCenter + gapW / 2,
      bottomGapLeft: bottomCenter - gapW / 2,
      bottomGapRight: bottomCenter + gapW / 2,
    );
  }

  ({double gapLeft, double gapRight}) _bannerGapBoundsAtY(
    Offset p,
    ({
      double yt,
      double yb,
      double topGapLeft,
      double topGapRight,
      double bottomGapLeft,
      double bottomGapRight,
    })
    g,
  ) {
    final t = ((p.dy - g.yt) / (g.yb - g.yt)).clamp(0.0, 1.0);
    final gapLeft = g.topGapLeft + (g.bottomGapLeft - g.topGapLeft) * t;
    final gapRight = g.topGapRight + (g.bottomGapRight - g.topGapRight) * t;
    return (gapLeft: gapLeft, gapRight: gapRight);
  }

  Offset? _globalToArenaLocal(Offset global) {
    final ctx = _arenaKey.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    return box.globalToLocal(global);
  }

  /// True if the segment passes through solid banner material (not the gap).
  bool _segmentTouchesSolidBanner(
    Offset a,
    Offset b,
    ({
      double yt,
      double yb,
      double topGapLeft,
      double topGapRight,
      double bottomGapLeft,
      double bottomGapRight,
    })
    g,
  ) {
    const steps = 28;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final p = Offset(a.dx + (b.dx - a.dx) * t, a.dy + (b.dy - a.dy) * t);
      if (p.dy < g.yt || p.dy > g.yb) continue;
      final gap = _bannerGapBoundsAtY(p, g);
      if (p.dx < gap.gapLeft || p.dx > gap.gapRight) {
        return true;
      }
    }
    return false;
  }

  bool _pointInBannerGap(
    Offset p,
    ({
      double yt,
      double yb,
      double topGapLeft,
      double topGapRight,
      double bottomGapLeft,
      double bottomGapRight,
    })
    g,
  ) {
    if (p.dy < g.yt || p.dy > g.yb) return false;
    final gap = _bannerGapBoundsAtY(p, g);
    return p.dx >= gap.gapLeft && p.dx <= gap.gapRight;
  }

  void _onPanStart(DragStartDetails d) {
    _dragStart = d.globalPosition;
    if (_phase == _Phase.banner) {
      _bannerLastLocal = _globalToArenaLocal(d.globalPosition);
      _bannerPassedThroughGap = false;
      _bannerGestureDead = false;
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_phase != _Phase.banner || _bannerGestureDead) return;
    final arena = _arenaKey.currentContext?.findRenderObject() as RenderBox?;
    if (arena == null || !arena.hasSize) return;
    final g = _bannerGeom(arena.size);
    final cur = arena.globalToLocal(d.globalPosition);
    final prev = _bannerLastLocal ?? cur;
    if (_segmentTouchesSolidBanner(prev, cur, g)) {
      _bannerGestureDead = true;
      _bannerLastLocal = cur;
      return;
    }
    if (_pointInBannerGap(cur, g)) {
      _bannerPassedThroughGap = true;
    }
    _bannerLastLocal = cur;
  }

  void _onPanCancel() {
    _dragStart = null;
    _resetBannerGesture();
  }

  void _onBannerPanEnd(DragEndDetails details) {
    if (_dragStart == null) return;
    final arena = _arenaKey.currentContext?.findRenderObject() as RenderBox?;
    if (arena == null || !arena.hasSize) {
      _dragStart = null;
      _resetBannerGesture();
      return;
    }
    final bg = _bannerGeom(arena.size);
    final startL = arena.globalToLocal(_dragStart!);
    final endL = arena.globalToLocal(details.globalPosition);
    final ok =
        !_bannerGestureDead &&
        startL.dy > bg.yb &&
        endL.dy < bg.yt &&
        endL.dy < startL.dy &&
        _bannerPassedThroughGap &&
        !_segmentTouchesSolidBanner(startL, endL, bg);

    _registerSwipe(ok);
    _dragStart = null;
    _resetBannerGesture();
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
    final minD =
        _cardinalMinDist[_idxInStage.clamp(0, _cardinalMinDist.length - 1)];
    if (dist < minD) return false;
    final got = _cardinalFromVector(dx, dy);
    return got == _cardinalSeq[_idxInStage];
  }

  void _onPanEnd(DragEndDetails details) {
    if (_phase == _Phase.banner) {
      _onBannerPanEnd(details);
      return;
    }
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
    if (_phase == _Phase.banner) {
      return 'banner ${_bannerRound + 1}/$_bannerRoundsTotal';
    }
    if (_phase == _Phase.cardinal) {
      return 'round ${_idxInStage + 1}/$_cardinalLen';
    }
    if (_phase == _Phase.pacman) {
      return 'gap ${_pacRound + 1}/$_pacLen';
    }
    return '';
  }

  double get _currentMouthHalf =>
      _pacMouthHalf[_pacRound.clamp(0, _pacMouthHalf.length - 1)];

  String? get _helperText {
    if (_phase == _Phase.banner) {
      return 'thread five banner slots: below to above, gaps only';
    }
    if (_phase == _Phase.pacman) {
      return 'swipe out through the gap';
    }
    return null;
  }

  Widget _bannerPlayArea() {
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        final bg = _bannerGeom(size);
        final bandH = bg.yb - bg.yt;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _BannerPainter(
                  yt: bg.yt,
                  bandH: bandH,
                  topGapLeft: bg.topGapLeft,
                  topGapRight: bg.topGapRight,
                  bottomGapLeft: bg.bottomGapLeft,
                  bottomGapRight: bg.bottomGapRight,
                ),
              ),
            ),
          ],
        );
      },
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
    final helperText = _helperText;
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      onPanCancel: _onPanCancel,
      child: Container(
        color: Colors.transparent,
        child: Column(
          children: [
            LevelHud(
              stageText: _topHint,
              lives: LevelHud.emojiLives(_lives, maxLives),
            ),
            if (helperText != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: Text(
                  helperText,
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox.expand(
                  key: _arenaKey,
                  child: _phase == _Phase.banner
                      ? _bannerPlayArea()
                      : _phase == _Phase.pacman
                      ? CustomPaint(
                          painter: _PacmanPainter(
                            openingRad: _pacOpeningRad,
                            mouthHalf: _currentMouthHalf,
                          ),
                          child: const SizedBox.expand(),
                        )
                      : ColoredBox(
                          color: Colors.transparent,
                          child: _cardinalPanel(),
                        ),
                ),
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
  _PacmanPainter({required this.openingRad, required this.mouthHalf});

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

class _BannerPainter extends CustomPainter {
  _BannerPainter({
    required this.yt,
    required this.bandH,
    required this.topGapLeft,
    required this.topGapRight,
    required this.bottomGapLeft,
    required this.bottomGapRight,
  });

  final double yt;
  final double bandH;
  final double topGapLeft;
  final double topGapRight;
  final double bottomGapLeft;
  final double bottomGapRight;

  @override
  void paint(Canvas canvas, Size size) {
    final bandRect = Rect.fromLTWH(0, yt, size.width, bandH);
    final bandPath = Path()
      ..addRRect(RRect.fromRectAndRadius(bandRect, const Radius.circular(6)));
    final gapPath = Path()
      ..moveTo(topGapLeft, yt)
      ..lineTo(topGapRight, yt)
      ..lineTo(bottomGapRight, yt + bandH)
      ..lineTo(bottomGapLeft, yt + bandH)
      ..close();
    final bannerPath = Path.combine(
      PathOperation.difference,
      bandPath,
      gapPath,
    );

    canvas.drawShadow(
      bannerPath,
      NunuColors.primaryDark.withValues(alpha: 0.35),
      10,
      false,
    );
    canvas.drawPath(
      bannerPath,
      Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.88)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant _BannerPainter oldDelegate) =>
      yt != oldDelegate.yt ||
      bandH != oldDelegate.bandH ||
      topGapLeft != oldDelegate.topGapLeft ||
      topGapRight != oldDelegate.topGapRight ||
      bottomGapLeft != oldDelegate.bottomGapLeft ||
      bottomGapRight != oldDelegate.bottomGapRight;
}
