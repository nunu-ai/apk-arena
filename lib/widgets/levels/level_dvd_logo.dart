import 'dart:async';
import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelDvdLogo extends LevelWidget {
  const LevelDvdLogo({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelDvdLogo> createState() => _LevelDvdLogoState();
}

class _LevelDvdLogoState extends State<LevelDvdLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Movement
  double _x = 0;
  double _y = 0;
  double _vx = 0;
  double _vy = 0;
  Size _screenSize = Size.zero;

  // Stages
  int _stage = 0;
  int _catches = 0;
  int _misses = 0;
  double _score = 0.0;
  bool _done = false;
  bool _playing = false; // false = showing interstitial
  bool _stageInitialized = false;

  // Timer
  int _secondsLeft = 300;
  Timer? _timer;

  // Visuals
  Color _color = Colors.red;
  final _rng = Random();

  static const _ballSize = 70.0; // sphere diameter for stage 3
  static const _logoW = 100.0;
  static const _logoH = 54.0;
  static const _gravity = 0.15;
  static const _bounceDamping = 0.82;

  final _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.cyan,
  ];

  static const _stageNames = ['flyby', 'dvd', 'gravity'];
  static const _stageDescriptions = [
    'cruising left and right. predictable.',
    'classic dvd bounce. two axes now.',
    'gravity pulls it down. good luck.',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
    _controller.repeat();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startStage() {
    setState(() {
      _playing = true;
      _stageInitialized = false;
      _secondsLeft = 300;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) {
        _timer?.cancel();
        // Time's up — failed this stage, move on
        if (_stage >= 2) {
          _finish();
        } else {
          setState(() {
            _stage++;
            _playing = false;
          });
        }
      }
    });
  }

  void _initStage() {
    switch (_stage) {
      case 0:
        _x = 40;
        _y = _screenSize.height / 2 - _logoH / 2;
        _vx = 2.5;
        _vy = 0;
        break;
      case 1:
        _x = _rng.nextDouble() * (_screenSize.width - _logoW);
        _y = _rng.nextDouble() * (_screenSize.height * 0.6);
        _vx = (_rng.nextBool() ? 1 : -1) * 2.5;
        _vy = (_rng.nextBool() ? 1 : -1) * 1.8;
        break;
      case 2:
        _x = _rng.nextDouble() * (_screenSize.width - _ballSize);
        _y = 40;
        _vx = (_rng.nextBool() ? 1 : -1) * (2.0 + _rng.nextDouble() * 2.0);
        _vy = 0;
        break;
    }
    _color = _colors[_rng.nextInt(_colors.length)];
  }

  void _tick() {
    if (!mounted || _screenSize == Size.zero || _done || !_playing) return;

    if (!_stageInitialized) {
      _stageInitialized = true;
      _initStage();
    }

    final w = _stage == 2 ? _ballSize : _logoW;
    final h = _stage == 2 ? _ballSize : _logoH;

    setState(() {
      if (_stage == 2) _vy += _gravity;

      _x += _vx;
      _y += _vy;

      bool bounced = false;

      if (_x + w >= _screenSize.width) {
        _x = _screenSize.width - w;
        _vx = -_vx.abs();
        if (_stage == 2) _vx *= _bounceDamping;
        bounced = true;
      }
      if (_x <= 0) {
        _x = 0;
        _vx = _vx.abs();
        if (_stage == 2) _vx *= _bounceDamping;
        bounced = true;
      }

      if (_y + h >= _screenSize.height) {
        _y = _screenSize.height - h;
        if (_stage == 2) {
          _vy = -_vy.abs() * _bounceDamping;
          if (_vy.abs() < 4.0) {
            _vy = -(12.0 + _rng.nextDouble() * 6.0);
            _vx = (_rng.nextBool() ? 1 : -1) * (4.0 + _rng.nextDouble() * 5.0);
          }
        } else {
          _vy = -_vy.abs();
        }
        bounced = true;
      }

      if (_y <= 0) {
        _y = 0;
        _vy = _vy.abs();
        bounced = true;
      }

      if (bounced) _color = _colors[_rng.nextInt(_colors.length)];
    });
  }

  void _handleTap(TapDownDetails details) {
    if (_done || !_playing) return;

    final tap = details.localPosition;
    final w = _stage == 2 ? _ballSize : _logoW;
    final h = _stage == 2 ? _ballSize : _logoH;
    final rect = Rect.fromLTWH(_x, _y, w, h);

    if (rect.contains(tap)) {
      // Hit — award 1/3 score and advance
      _timer?.cancel();
      _catches++;
      setState(() => _score += 1.0 / 3.0);
      _advanceOrFinish();
    } else {
      // Misclick — lose 5%
      setState(() {
        _misses++;
        _score = max(0.0, _score - 0.05);
      });
    }
  }

  void _skipStage() {
    if (_done || !_playing) return;
    _timer?.cancel();
    _advanceOrFinish();
  }

  void _advanceOrFinish() {
    if (_stage >= 2) {
      _finish();
    } else {
      setState(() {
        _stage++;
        _playing = false;
      });
    }
  }

  void _finish() {
    setState(() => _done = true);
    _controller.stop();
    widget.onComplete(LevelOutcome(
      score: _score.clamp(0.0, 1.0),
      metrics: {'catches': _catches, 'misses': _misses},
    ));
  }

  String get _timerText {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        if (!_playing && !_done) return _buildInterstitial();

        return GestureDetector(
          onTapDown: _handleTap,
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // HUD
                Positioned(
                  top: 16,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      Text(
                        'stage ${_stage + 1}: ${_stageNames[_stage]}',
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(
                            3,
                            (i) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i < _catches
                                      ? NunuColors.successMain
                                      : i == _stage
                                          ? Colors.white38
                                          : Colors.white12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            _timerText,
                            style: TextStyle(
                              color: _secondsLeft <= 10
                                  ? NunuColors.errorMain
                                  : Colors.white54,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Score + miss counter
                Positioned(
                  top: 70,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(_score * 100).round()}%',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 12,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (_misses > 0) ...[
                        const SizedBox(width: 12),
                        Text(
                          '✕ $_misses',
                          style: TextStyle(
                            color: NunuColors.errorMain.withValues(alpha: 0.6),
                            fontSize: 12,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // Target
                Positioned(
                  left: _x,
                  top: _y,
                  child: _buildTarget(),
                ),

                // Skip button
                Positioned(
                  bottom: 24,
                  right: 24,
                  child: GestureDetector(
                    onTap: _skipStage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white24),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'skip →',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInterstitial() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                3,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < _catches
                          ? NunuColors.successMain
                          : Colors.white12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'stage ${_stage + 1}',
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _stageNames[_stage],
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _stageDescriptions[_stage],
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 20),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Column(
                children: [
                  Text(
                    'every misclick costs 5%',
                    style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              '5:00',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _startStage,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'continue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTarget() {
    switch (_stage) {
      case 0:
        // Neon paper airplane
        final goingRight = _vx >= 0;
        return SizedBox(
          width: _logoW,
          height: _logoH,
          child: CustomPaint(
            painter: _PlanePainter(
              color: _color,
              flip: !goingRight,
            ),
          ),
        );
      case 1:
        return Container(
          width: _logoW,
          height: _logoH,
          decoration: BoxDecoration(
            color: _color,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'DVD',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(2, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                const Text(
                  'VIDEO',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        // Sphere with 3D shading
        return Container(
          width: _ballSize,
          height: _ballSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              center: const Alignment(-0.35, -0.35),
              radius: 0.7,
              colors: [
                Color.lerp(Colors.white, _color, 0.4)!,
                _color,
                Color.lerp(_color, Colors.black, 0.6)!,
              ],
              stops: const [0.0, 0.45, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: _color.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 4,
              ),
              // drop shadow for depth
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(3, 6),
              ),
            ],
          ),
        );
    }
  }
}

class _PlanePainter extends CustomPainter {
  final Color color;
  final bool flip;

  _PlanePainter({required this.color, required this.flip});

  @override
  void paint(Canvas canvas, Size size) {
    if (flip) {
      canvas.translate(size.width, 0);
      canvas.scale(-1, 1);
    }

    final w = size.width;
    final h = size.height;
    final cy = h * 0.5;

    // Glow behind everything
    final glow = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w * 0.45, cy), width: w * 0.9, height: h * 0.5),
      glow,
    );

    // Fuselage — long rounded body
    final fuselage = Path()
      ..moveTo(w * 0.95, cy) // nose
      ..quadraticBezierTo(w * 1.0, cy - h * 0.06, w * 0.88, cy - h * 0.10)
      ..lineTo(w * 0.10, cy - h * 0.08)
      ..quadraticBezierTo(w * 0.02, cy, w * 0.10, cy + h * 0.08)
      ..lineTo(w * 0.88, cy + h * 0.10)
      ..quadraticBezierTo(w * 1.0, cy + h * 0.06, w * 0.95, cy)
      ..close();

    final fuselagePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color.lerp(Colors.white, color, 0.4)!,
          color,
          Color.lerp(color, Colors.black, 0.3)!,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawPath(fuselage, fuselagePaint);

    // Main wings — swept back
    final wing = Path()
      ..moveTo(w * 0.55, cy - h * 0.08)
      ..lineTo(w * 0.35, 0) // top wing tip
      ..lineTo(w * 0.25, cy - h * 0.06)
      ..close();
    final wingBottom = Path()
      ..moveTo(w * 0.55, cy + h * 0.08)
      ..lineTo(w * 0.35, h) // bottom wing tip
      ..lineTo(w * 0.25, cy + h * 0.06)
      ..close();

    final wingPaint = Paint()..color = Color.lerp(Colors.white, color, 0.5)!;
    final wingDarkPaint = Paint()..color = Color.lerp(color, Colors.black, 0.15)!;
    canvas.drawPath(wing, wingPaint);
    canvas.drawPath(wingBottom, wingDarkPaint);

    // Tail fin — vertical stabilizer
    final tail = Path()
      ..moveTo(w * 0.12, cy - h * 0.08)
      ..lineTo(w * 0.05, cy - h * 0.40)
      ..lineTo(w * 0.02, cy - h * 0.38)
      ..lineTo(w * 0.08, cy - h * 0.06)
      ..close();
    canvas.drawPath(tail, wingPaint);

    // Tail horizontal stabilizers
    final tailWing = Path()
      ..moveTo(w * 0.14, cy - h * 0.06)
      ..lineTo(w * 0.06, cy - h * 0.28)
      ..lineTo(w * 0.04, cy - h * 0.06)
      ..close();
    final tailWingBottom = Path()
      ..moveTo(w * 0.14, cy + h * 0.06)
      ..lineTo(w * 0.06, cy + h * 0.28)
      ..lineTo(w * 0.04, cy + h * 0.06)
      ..close();
    canvas.drawPath(tailWing, wingPaint);
    canvas.drawPath(tailWingBottom, wingDarkPaint);

    // Cockpit window
    final cockpit = Paint()
      ..color = Colors.white.withValues(alpha: 0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.82, cy - h * 0.03),
        width: w * 0.08,
        height: h * 0.08,
      ),
      cockpit,
    );

    // Fuselage outline
    final outline = Paint()
      ..color = Colors.white.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawPath(fuselage, outline);
  }

  @override
  bool shouldRepaint(covariant _PlanePainter old) =>
      old.color != color || old.flip != flip;
}
