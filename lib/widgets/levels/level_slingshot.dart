import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

/// Angry-birds-style slingshot: launch a ball through a gap in a wall.
/// 10 tries. Pass = at least one ball through.
class LevelSlingshot extends LevelWidget {
  const LevelSlingshot({super.key, required super.onComplete});

  @override
  State<LevelSlingshot> createState() => _LevelSlingshotState();
}

class _Shot {
  final List<Offset> path;
  final bool hit;
  const _Shot(this.path, this.hit);
}

class _LevelSlingshotState extends State<LevelSlingshot>
    with SingleTickerProviderStateMixin {
  static const int _maxShots = 10;
  static const double _gravity = 1400; // px/s²
  static const double _launchMul = 4.5; // drag→velocity multiplier
  static const double _ballRadius = 10;

  late AnimationController _ticker;

  // layout (computed in build)
  double _w = 0, _h = 0;
  late Offset _anchor; // slingshot position
  late double _wallX;
  late double _gapTop;
  late double _gapBot;
  late double _groundY;

  // state
  Offset? _dragPos;
  bool _isDragging = false;
  bool _isFiring = false;
  double _bx = 0, _by = 0, _vx = 0, _vy = 0;
  DateTime _lastFrame = DateTime.now();
  final List<Offset> _currentPath = [];
  final List<_Shot> _history = [];
  int _shotsUsed = 0;
  int _hits = 0;
  bool _completed = false;
  bool _wentThroughGap = false;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _computeLayout(Size size) {
    _w = size.width;
    _h = size.height;
    _anchor = Offset(_w * 0.30, _h * 0.60);
    _wallX = _w * 0.78;
    _groundY = _h * 0.85;
    // gap centred vertically at about 40% screen height, 70 px tall
    final gapCenter = _h * 0.42;
    const gapHalf = 35.0;
    _gapTop = gapCenter - gapHalf;
    _gapBot = gapCenter + gapHalf;
  }

  // ---------- gesture ----------

  void _onPanStart(DragStartDetails d) {
    if (_isFiring || _completed) return;
    final pos = d.localPosition;
    if ((pos - _anchor).distance < 60) {
      setState(() {
        _isDragging = true;
        _dragPos = pos;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (!_isDragging) return;
    setState(() => _dragPos = d.localPosition);
  }

  void _onPanEnd(DragEndDetails _) {
    if (!_isDragging || _dragPos == null) return;
    // launch
    final pull = _anchor - _dragPos!;
    _vx = pull.dx * _launchMul;
    _vy = pull.dy * _launchMul;
    _bx = _anchor.dx;
    _by = _anchor.dy;
    _currentPath
      ..clear()
      ..add(Offset(_bx, _by));
    _wentThroughGap = false;
    _isDragging = false;
    _dragPos = null;
    _isFiring = true;
    _lastFrame = DateTime.now();
    _ticker.repeat();
    setState(() {});
  }

  // ---------- physics ----------

  bool _isCenterInsideGap(double y) {
    return y >= _gapTop + _ballRadius && y <= _gapBot - _ballRadius;
  }

  bool _resolveWallInteraction({
    required double prevX,
    required double prevY,
    required double nextX,
    required double nextY,
  }) {
    if (_wentThroughGap || nextX <= prevX) {
      return true;
    }

    final left = _wallX - _ballRadius;
    final right = _wallX + 14 + _ballRadius;
    if (nextX < left || prevX > right) {
      return true;
    }

    final dx = nextX - prevX;
    if (dx == 0) {
      return true;
    }

    final enterT = ((left - prevX) / dx).clamp(0.0, 1.0);
    final exitT = ((right - prevX) / dx).clamp(0.0, 1.0);
    final tMin = enterT < exitT ? enterT : exitT;
    final tMax = enterT > exitT ? enterT : exitT;
    final yEnter = prevY + (nextY - prevY) * tMin;
    final yExit = prevY + (nextY - prevY) * tMax;

    final throughGap = _isCenterInsideGap(yEnter) && _isCenterInsideGap(yExit);
    if (!throughGap) {
      _finishShot(false);
      return false;
    }

    _wentThroughGap = true;
    return true;
  }

  void _tick() {
    if (!_isFiring) return;
    final now = DateTime.now();
    final dt = (now.difference(_lastFrame).inMicroseconds / 1e6).clamp(
      0.0,
      0.04,
    );
    _lastFrame = now;

    final prevX = _bx;
    final prevY = _by;
    _bx += _vx * dt;
    _vy += _gravity * dt;
    _by += _vy * dt;

    _currentPath.add(Offset(_bx, _by));

    if (!_resolveWallInteraction(
      prevX: prevX,
      prevY: prevY,
      nextX: _bx,
      nextY: _by,
    )) {
      return;
    }

    if (_bx > _w + 20 || _by >= _groundY || _by < -40) {
      _finishShot(_wentThroughGap);
      return;
    }

    setState(() {});
  }

  void _finishShot(bool hit) {
    _ticker.stop();
    _isFiring = false;
    _shotsUsed++;
    if (hit) _hits++;
    _history.add(_Shot(List.from(_currentPath), hit));
    _currentPath.clear();

    if (_hits >= 1 && !_completed) {
      _completed = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(
          true,
          metrics: {
            'hits': _hits,
            'shotsUsed': _shotsUsed,
            'totalShots': _maxShots,
          },
        );
      });
    } else if (_shotsUsed >= _maxShots && !_completed) {
      _completed = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(
          false,
          metrics: {
            'hits': _hits,
            'shotsUsed': _shotsUsed,
            'totalShots': _maxShots,
          },
        );
      });
    }

    setState(() {});
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _computeLayout(Size(box.maxWidth, box.maxHeight));

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          child: CustomPaint(
            size: Size(box.maxWidth, box.maxHeight),
            painter: _SlingshotPainter(
              anchor: _anchor,
              dragPos: _isDragging ? _dragPos : null,
              wallX: _wallX,
              gapTop: _gapTop,
              gapBot: _gapBot,
              groundY: _groundY,
              history: _history,
              currentPath: _isFiring ? _currentPath : null,
              ballPos: _isFiring ? Offset(_bx, _by) : null,
              ballRadius: _ballRadius,
              shotsLeft: _maxShots - _shotsUsed,
              hits: _hits,
              screenW: _w,
              screenH: _h,
            ),
          ),
        );
      },
    );
  }
}

// ---------- painter ----------

class _SlingshotPainter extends CustomPainter {
  final Offset anchor;
  final Offset? dragPos;
  final double wallX, gapTop, gapBot, groundY;
  final List<_Shot> history;
  final List<Offset>? currentPath;
  final Offset? ballPos;
  final double ballRadius;
  final int shotsLeft, hits;
  final double screenW, screenH;

  const _SlingshotPainter({
    required this.anchor,
    required this.dragPos,
    required this.wallX,
    required this.gapTop,
    required this.gapBot,
    required this.groundY,
    required this.history,
    required this.currentPath,
    required this.ballPos,
    required this.ballRadius,
    required this.shotsLeft,
    required this.hits,
    required this.screenW,
    required this.screenH,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // sky gradient
    final skyPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF050818), Color(0xFF0E1A2E)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, groundY));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, groundY), skyPaint);

    // ground
    canvas.drawRect(
      Rect.fromLTWH(0, groundY, size.width, size.height - groundY),
      Paint()..color = const Color(0xFF1A2A18),
    );
    // ground line
    canvas.drawLine(
      Offset(0, groundY),
      Offset(size.width, groundY),
      Paint()
        ..color = NunuColors.successMain.withValues(alpha: 0.25)
        ..strokeWidth = 2,
    );

    // wall
    final wallPaint = Paint()..color = const Color(0xFF3A3A5A);
    canvas.drawRect(Rect.fromLTWH(wallX, 0, 14, gapTop), wallPaint);
    canvas.drawRect(
      Rect.fromLTWH(wallX, gapBot, 14, groundY - gapBot),
      wallPaint,
    );
    // gap glow
    canvas.drawRect(
      Rect.fromLTWH(wallX - 2, gapTop, 18, gapBot - gapTop),
      Paint()
        ..color = NunuColors.successMain.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    // gap border
    canvas.drawLine(
      Offset(wallX, gapTop),
      Offset(wallX + 14, gapTop),
      Paint()
        ..color = NunuColors.successMain.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(wallX, gapBot),
      Offset(wallX + 14, gapBot),
      Paint()
        ..color = NunuColors.successMain.withValues(alpha: 0.5)
        ..strokeWidth = 2,
    );

    // slingshot fork
    final forkPaint = Paint()
      ..color = const Color(0xFF8B6914)
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      anchor + const Offset(0, 30),
      anchor + const Offset(-12, -18),
      forkPaint,
    );
    canvas.drawLine(
      anchor + const Offset(0, 30),
      anchor + const Offset(12, -18),
      forkPaint,
    );
    // base
    canvas.drawLine(
      anchor + const Offset(0, 30),
      anchor + const Offset(0, 55),
      forkPaint..strokeWidth = 6,
    );

    // elastic band + drag ball
    if (dragPos != null) {
      final bandPaint = Paint()
        ..color = NunuColors.errorMain.withValues(alpha: 0.8)
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(anchor + const Offset(-12, -18), dragPos!, bandPaint);
      canvas.drawLine(anchor + const Offset(12, -18), dragPos!, bandPaint);
      // ball preview
      canvas.drawCircle(
        dragPos!,
        ballRadius,
        Paint()..color = NunuColors.warningMain,
      );
    } else if (ballPos == null && shotsLeft > 0) {
      // resting ball
      canvas.drawCircle(
        anchor,
        ballRadius,
        Paint()..color = NunuColors.warningMain.withValues(alpha: 0.7),
      );
    }

    // previous trajectories
    for (final shot in history) {
      if (shot.path.length < 2) continue;
      final path = Path()..moveTo(shot.path.first.dx, shot.path.first.dy);
      for (int i = 1; i < shot.path.length; i += 3) {
        path.lineTo(shot.path[i].dx, shot.path[i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = (shot.hit ? NunuColors.successMain : NunuColors.errorMain)
              .withValues(alpha: 0.15)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    // current trajectory
    if (currentPath != null && currentPath!.length >= 2) {
      final path = Path()..moveTo(currentPath!.first.dx, currentPath!.first.dy);
      for (int i = 1; i < currentPath!.length; i++) {
        path.lineTo(currentPath![i].dx, currentPath![i].dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = NunuColors.warningMain.withValues(alpha: 0.5)
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke,
      );
    }

    // flying ball
    if (ballPos != null) {
      canvas.drawCircle(
        ballPos!,
        ballRadius * 1.6,
        Paint()
          ..color = NunuColors.warningMain.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawCircle(
        ballPos!,
        ballRadius,
        Paint()..color = NunuColors.warningMain,
      );
      canvas.drawCircle(
        ballPos! + Offset(-ballRadius * 0.3, -ballRadius * 0.3),
        ballRadius * 0.3,
        Paint()..color = Colors.white.withValues(alpha: 0.4),
      );
    }

    // HUD
    _drawHud(canvas, size);
  }

  void _drawHud(Canvas canvas, Size size) {
    final tp1 = TextPainter(
      text: TextSpan(
        text: 'shots: $shotsLeft',
        style: const TextStyle(color: NunuColors.textSecondary, fontSize: 14),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp1.paint(canvas, const Offset(12, 12));

    final tp2 = TextPainter(
      text: TextSpan(
        text: 'hits: $hits',
        style: TextStyle(
          color: hits > 0 ? NunuColors.successMain : NunuColors.textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp2.paint(canvas, Offset(size.width - tp2.width - 12, 12));
  }

  @override
  bool shouldRepaint(covariant _SlingshotPainter old) => true;
}
