import 'dart:async';
import 'dart:math' as math;

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../level_widget.dart';

/// Fake-IG post for @nunu_ai: double-tap to like, then triple-tap, then 10-tap burst. Three hearts.
/// Burst taps must stay within strict gaps; a blown burst costs ≤1 life per “attempt” until 2s idle.
/// Score: 30% per stage cleared (max 90%) + 10% from lives (1/3 of 10% per life remaining).
class LevelTapMastery extends LevelWidget {
  const LevelTapMastery({super.key, required super.onComplete});

  @override
  State<LevelTapMastery> createState() => _LevelTapMasteryState();
}

class _LevelTapMasteryState extends State<LevelTapMastery> {
  static const int maxLives = 3;
  static const int _stageCount = 3;

  /// Stage 1 = triple, stage 2 = ten (stage 0 = double-tap via `onDoubleTap`).
  static const List<int> _burstNeed = [0, 3, 10];

  /// Max gap between consecutive taps inside one burst (strict).
  static const List<Duration> _burstGap = [
    Duration.zero,
    Duration(milliseconds: 280),
    Duration(milliseconds: 220),
  ];

  /// After this much idle time, the next burst tap starts a new “attempt” (can cost a life again).
  static const Duration _attemptIdleBoundary = Duration(seconds: 2);

  int _lives = maxLives;
  int _stageIndex = 0;
  int _tapCountInWindow = 0;
  int _totalTaps = 0;
  Timer? _resetTimer;
  Timer? _heartPopTimer;

  DateTime? _lastBurstTapAt;

  /// One failed burst timeout per attempt; fumbling many slow taps only costs one life until 2s idle.
  bool _burstLifeChargedThisAttempt = false;

  bool _liked = false;
  bool _showHeartPop = false;

  static const double _scorePerStage = 0.3;
  static const double _scoreLifePool = 0.1;

  @override
  void dispose() {
    _resetTimer?.cancel();
    _heartPopTimer?.cancel();
    super.dispose();
  }

  int get _needBurst => _burstNeed[_stageIndex];

  /// 30% per completed stage (max 90%) + 10% pool split across 3 lives (~3.333% each).
  double _scoreForRun({required bool won}) {
    final stagesDone = won ? _stageCount : _stageIndex.clamp(0, _stageCount);
    final stagePart = stagesDone * _scorePerStage;
    final lifePart = (_lives / maxLives) * _scoreLifePool;
    return stagePart + lifePart;
  }

  void _fail() {
    _resetTimer?.cancel();
    _heartPopTimer?.cancel();
    final s = _scoreForRun(won: false);
    widget.onComplete(
      LevelOutcome(
        score: s,
        metrics: {
          'total_taps': _totalTaps,
          'stages_cleared': _stageIndex,
          'lives_remaining': _lives,
        },
      ),
    );
  }

  void _win() {
    _resetTimer?.cancel();
    _heartPopTimer?.cancel();
    final s = _scoreForRun(won: true);
    widget.onComplete(
      LevelOutcome(
        score: s,
        metrics: {
          'total_taps': _totalTaps,
          'stages_cleared': _stageCount,
          'lives_remaining': _lives,
        },
      ),
    );
  }

  void _loseLife() {
    _resetTimer?.cancel();
    setState(() {
      _lives = math.max(0, _lives - 1);
      _tapCountInWindow = 0;
    });
    if (_lives <= 0) {
      _fail();
    }
  }

  void _scheduleBurstReset() {
    if (_stageIndex < 1) return;
    _resetTimer?.cancel();
    _resetTimer = Timer(_burstGap[_stageIndex], () {
      if (!mounted) return;
      if (_tapCountInWindow <= 0 || _tapCountInWindow >= _needBurst) return;
      if (!_burstLifeChargedThisAttempt) {
        _burstLifeChargedThisAttempt = true;
        _loseLife();
      } else {
        setState(() => _tapCountInWindow = 0);
      }
    });
  }

  void _flashHeartPop() {
    _heartPopTimer?.cancel();
    setState(() => _showHeartPop = true);
    _heartPopTimer = Timer(const Duration(milliseconds: 700), () {
      if (mounted) setState(() => _showHeartPop = false);
    });
  }

  /// Stage 0: system double-tap (like on a photo).
  void _onPhotoDoubleTap() {
    if (_stageIndex != 0) return;
    _resetTimer?.cancel();
    _totalTaps += 2;
    setState(() {
      _liked = true;
      _stageIndex = 1;
      _tapCountInWindow = 0;
      _lastBurstTapAt = null;
      _burstLifeChargedThisAttempt = false;
    });
    _flashHeartPop();
  }

  /// Stage 0: single tap only — double-tap never formed.
  void _onPhotoSingleWhenNeedDouble() {
    if (_stageIndex != 0) return;
    _loseLife();
  }

  void _onBurstTap() {
    if (_stageIndex < 1) return;
    final now = DateTime.now();
    if (_lastBurstTapAt == null ||
        now.difference(_lastBurstTapAt!) > _attemptIdleBoundary) {
      _burstLifeChargedThisAttempt = false;
    }
    _lastBurstTapAt = now;

    _totalTaps++;
    _resetTimer?.cancel();
    setState(() {
      _tapCountInWindow++;
    });
    if (_tapCountInWindow == _needBurst) {
      _resetTimer?.cancel();
      if (_stageIndex >= _stageCount - 1) {
        _win();
      } else {
        setState(() {
          _stageIndex++;
          _tapCountInWindow = 0;
          _lastBurstTapAt = null;
          _burstLifeChargedThisAttempt = false;
        });
      }
    } else {
      _scheduleBurstReset();
    }
  }

  String get _hint {
    switch (_stageIndex) {
      case 0:
        return 'like the post';
      case 1:
        return 'triple-tap the post';
      case 2:
        return 'fast ten-tap the post';
      default:
        return '';
    }
  }

  Widget _livesHearts() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxLives, (i) {
        final alive = i < _lives;
        return Padding(
          padding: EdgeInsets.only(left: i == 0 ? 0 : 2),
          child: Icon(
            alive ? Icons.favorite : Icons.favorite_border,
            size: 18,
            color: alive
                ? const Color(0xFFFF3040)
                : Colors.white.withValues(alpha: 0.35),
          ),
        );
      }),
    );
  }

  /// IG-style story ring + default silhouette avatar.
  Widget _buildStoryAvatar() {
    const double outer = 40;
    const double ring = 2.8;
    return SizedBox(
      width: outer,
      height: outer,
      child: Container(
        padding: const EdgeInsets.all(ring),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: SweepGradient(
            startAngle: 0,
            colors: [
              Color(0xFFF58529),
              Color(0xFFFEDA77),
              Color(0xFFDD2A7B),
              Color(0xFF8134AF),
              Color(0xFF515BD4),
              Color(0xFFF58529),
            ],
          ),
        ),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF262626),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.person,
            color: Colors.white.withValues(alpha: 0.55),
            size: 26,
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard() {
    const igText = Color(0xFFF5F5F5);
    const igMuted = Color(0xFFA8A8A8);
    const igPhotoBg = Color(0xFF2C2C2C);

    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      color: Colors.black,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildStoryAvatar(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'nunu_ai',
                        style: TextStyle(
                          color: igText,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Zurich, Switzerland',
                        style: TextStyle(
                          color: igMuted,
                          fontSize: 12,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.more_vert,
                  color: igText.withValues(alpha: 0.92),
                  size: 22,
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(
                  color: igPhotoBg,
                  child: const CustomPaint(painter: _FeedSailboatPainter()),
                ),
                if (_showHeartPop)
                  IgnorePointer(
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.6, end: 1.15),
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutBack,
                        builder: (context, scale, child) =>
                            Transform.scale(scale: scale, child: child),
                        child: Icon(
                          Icons.favorite,
                          size: 112,
                          color: Colors.white.withValues(alpha: 0.95),
                          shadows: const [
                            Shadow(blurRadius: 24, color: Colors.black54),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
            child: Row(
              children: [
                Icon(
                  _liked ? Icons.favorite : Icons.favorite_border,
                  color: _liked ? const Color(0xFFFF3040) : igText,
                  size: 28,
                ),
                const SizedBox(width: 18),
                Icon(Icons.chat_bubble_outline, color: igText, size: 26),
                const SizedBox(width: 18),
                Transform.rotate(
                  angle: -0.12,
                  child: Icon(Icons.send_outlined, color: igText, size: 24),
                ),
                const Spacer(),
                Icon(Icons.bookmark_border, color: igText, size: 26),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _liked ? '1,337 likes' : '1,336 likes',
              style: const TextStyle(
                color: igText,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                  color: igText,
                  fontSize: 14,
                  height: 1.35,
                ),
                children: const [
                  TextSpan(
                    text: 'nunu_ai ',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  TextSpan(
                    text: 'building AGI for games 🎮 🤖',
                    style: TextStyle(fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Text(
              '2 hours ago',
              style: TextStyle(
                color: igMuted.withValues(alpha: 0.95),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        _hint,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: 15,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _livesHearts(),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _stageIndex == 0
                        ? _onPhotoSingleWhenNeedDouble
                        : _onBurstTap,
                    onDoubleTap: _stageIndex == 0 ? _onPhotoDoubleTap : null,
                    child: _buildPostCard(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flat sailboat (orange–red striped sails, light hull) on dark grey — matches reference feed art.
class _FeedSailboatPainter extends CustomPainter {
  const _FeedSailboatPainter();

  static const _hull = Color(0xFF7EC8D4);
  static const _hullShadow = Color(0xFF5BA8B8);
  static const _mast = Color(0xFF6D4C41);
  static const _stripeA = Color(0xFFE85D4C);
  static const _stripeB = Color(0xFFFF7A5C);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;

    final mastTop = Offset(cx, cy - size.height * 0.26);
    final mastBottom = Offset(cx, cy + size.height * 0.14);
    final mastPaint = Paint()
      ..color = _mast
      ..strokeWidth = math.max(2.0, size.width * 0.008)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(mastTop, mastBottom, mastPaint);

    // Main sail (triangle), striped
    final mainSailPath = Path()
      ..moveTo(cx, cy - size.height * 0.24)
      ..lineTo(cx + size.width * 0.22, cy + size.height * 0.06)
      ..lineTo(cx, cy + size.height * 0.04)
      ..close();
    canvas.save();
    canvas.clipPath(mainSailPath);
    final stripeH = size.height * 0.045;
    var stripeIdx = 0;
    for (
      var y = cy - size.height * 0.26;
      y < cy + size.height * 0.1;
      y += stripeH
    ) {
      final paint = Paint()..color = stripeIdx.isEven ? _stripeA : _stripeB;
      stripeIdx++;
      canvas.drawRect(
        Rect.fromLTWH(cx - size.width * 0.02, y, size.width * 0.28, stripeH),
        paint,
      );
    }
    canvas.restore();
    canvas.drawPath(
      mainSailPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.12),
    );

    // Jib (front sail)
    final jibPath = Path()
      ..moveTo(cx, cy - size.height * 0.18)
      ..lineTo(cx - size.width * 0.14, cy + size.height * 0.05)
      ..lineTo(cx, cy + size.height * 0.02)
      ..close();
    canvas.save();
    canvas.clipPath(jibPath);
    final jibStripe = stripeH * 0.85;
    stripeIdx = 0;
    for (
      var y = cy - size.height * 0.2;
      y < cy + size.height * 0.08;
      y += jibStripe
    ) {
      final paint = Paint()..color = stripeIdx.isEven ? _stripeB : _stripeA;
      stripeIdx++;
      canvas.drawRect(
        Rect.fromLTWH(cx - size.width * 0.18, y, size.width * 0.2, jibStripe),
        paint,
      );
    }
    canvas.restore();
    canvas.drawPath(
      jibPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.1),
    );

    // Hull
    final hullPath = Path()
      ..moveTo(cx - size.width * 0.2, cy + size.height * 0.12)
      ..quadraticBezierTo(
        cx - size.width * 0.22,
        cy + size.height * 0.2,
        cx,
        cy + size.height * 0.2,
      )
      ..quadraticBezierTo(
        cx + size.width * 0.22,
        cy + size.height * 0.2,
        cx + size.width * 0.2,
        cy + size.height * 0.12,
      )
      ..lineTo(cx - size.width * 0.2, cy + size.height * 0.12)
      ..close();

    canvas.drawPath(hullPath, Paint()..color = _hullShadow);
    canvas.save();
    canvas.translate(0, -2);
    canvas.drawPath(hullPath, Paint()..color = _hull);
    canvas.drawPath(
      hullPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = Colors.black.withValues(alpha: 0.15),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
