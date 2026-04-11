import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../level_widget.dart';

class LevelMultiTapSync extends LevelWidget {
  const LevelMultiTapSync({super.key, required super.onComplete});

  @override
  State<LevelMultiTapSync> createState() => _LevelMultiTapSyncState();
}

class _LevelMultiTapSyncState extends State<LevelMultiTapSync>
    with TickerProviderStateMixin {
  static const Duration _syncWindow = Duration(milliseconds: 260);
  static const Duration _holdWindow = Duration(milliseconds: 340);

  static const int _livesPerStage = 3;
  static const double _laneSyncSlack = 52;

  final Set<int> _pressedPads = <int>{};
  final Map<int, int> _pointerToPad = <int, int>{};
  DateTime? _firstPressAt;
  Timer? _holdTimer;
  /// 0 = hold three pads, 1 = swipe up on three lanes together, 2 = hold + swipe elsewhere
  int _phase = 0;
  int _lives = _livesPerStage;
  final List<double> _laneUpAccum = [0, 0, 0];
  bool _anchorHeld = false;
  int? _anchorPointerId;
  double _dualSwipeAccum = 0;
  late final AnimationController _pulse;
  late final AnimationController _spin;
  late final AnimationController _energyFlow;
  String _status = 'press and hold all 3 pads at once';

  // Neon colors for the reactor
  static const Color _cyanNeon = Color(0xFF00F5FF);
  static const Color _magentaNeon = Color(0xFFFF00FF);
  static const Color _coreGlow = Color(0xFF00FFAA);

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _energyFlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _pulse.dispose();
    _spin.dispose();
    _energyFlow.dispose();
    super.dispose();
  }

  void _resetCurrentStageInputs() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _pressedPads.clear();
    _pointerToPad.clear();
    _firstPressAt = null;
    _laneUpAccum[0] = _laneUpAccum[1] = _laneUpAccum[2] = 0;
    _anchorHeld = false;
    _anchorPointerId = null;
    _dualSwipeAccum = 0;
  }

  void _loseLife(String statusAfterReset) {
    _holdTimer?.cancel();
    _holdTimer = null;
    _lives--;
    if (_lives <= 0) {
      if (!mounted) return;
      widget.onComplete(
        LevelOutcome(score: 0, metrics: {'failed_stage': _phase}),
      );
      return;
    }
    _resetCurrentStageInputs();
    setState(() {
      _status = '$statusAfterReset ($_lives lives left)';
    });
  }

  static const double _laneUpNeeded = 56;
  static const double _dualSwipeNeeded = 80;

  void _startHoldCheck() {
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdWindow, () {
      if (!mounted) return;
      if (_pressedPads.length == 3) {
        _holdTimer = null;
        setState(() {
          _phase = 1;
          _lives = _livesPerStage;
          _pressedPads.clear();
          _pointerToPad.clear();
          _firstPressAt = null;
          _laneUpAccum[0] = _laneUpAccum[1] = _laneUpAccum[2] = 0;
          _status = 'swipe up on all three lanes at the same time';
        });
      }
    });
  }

  void _onLanePointerMove(int lane, Offset delta) {
    if (_phase != 1) return;
    if (delta.dy >= 0) return;
    final double nextLane = _laneUpAccum[lane] - delta.dy;
    final double n0 = lane == 0 ? nextLane : _laneUpAccum[0];
    final double n1 = lane == 1 ? nextLane : _laneUpAccum[1];
    final double n2 = lane == 2 ? nextLane : _laneUpAccum[2];
    final double nextMax = math.max(math.max(n0, n1), n2);
    final double nextMin = math.min(math.min(n0, n1), n2);
    if (nextMax - nextMin > _laneSyncSlack && nextMax > 10) {
      _loseLife('lanes desynced. lift together.');
      return;
    }
    setState(() {
      _laneUpAccum[lane] = nextLane;
    });
    if (n0 >= _laneUpNeeded &&
        n1 >= _laneUpNeeded &&
        n2 >= _laneUpNeeded) {
      setState(() {
        _phase = 2;
        _lives = _livesPerStage;
        _resetCurrentStageInputs();
        _status =
            'hold the anchor with one finger; swipe right on the conduit with another';
      });
    }
  }

  void _onDualAnchorDown(PointerDownEvent e) {
    if (_phase != 2) return;
    if (_anchorHeld) return;
    setState(() {
      _anchorHeld = true;
      _anchorPointerId = e.pointer;
      _status =
          'keep anchor down — swipe right on the conduit (${_dualSwipeAccum.toStringAsFixed(0)}/${_dualSwipeNeeded.toStringAsFixed(0)})';
    });
  }

  void _onDualAnchorUp(PointerEvent e) {
    if (_phase != 2) return;
    if (e.pointer != _anchorPointerId) return;
    final bool incomplete = _dualSwipeAccum < _dualSwipeNeeded;
    if (incomplete && (_anchorHeld || _dualSwipeAccum > 0)) {
      _loseLife('anchor dropped before conduit synced.');
      return;
    }
    setState(() {
      _anchorHeld = false;
      _anchorPointerId = null;
    });
  }

  void _onDualSwipeMove(PointerMoveEvent e) {
    if (_phase != 2) return;
    if (!_anchorHeld) return;
    if (e.delta.dx <= 0) return;
    final double nextAccum = _dualSwipeAccum + e.delta.dx;
    setState(() {
      _dualSwipeAccum = nextAccum;
      _status =
          'keep anchor — swipe right (${nextAccum.toStringAsFixed(0)}/${_dualSwipeNeeded.toStringAsFixed(0)})';
    });
    if (nextAccum >= _dualSwipeNeeded) {
      widget.onComplete(LevelOutcome(score: 1));
    }
  }

  void _onPadDown(int padId, int pointerId) {
    final DateTime now = DateTime.now();
    String? desyncMessage;
    if (_pressedPads.isEmpty) {
      _firstPressAt = now;
    } else if (!_pressedPads.contains(padId) &&
        _firstPressAt != null &&
        now.difference(_firstPressAt!) > _syncWindow) {
      _holdTimer?.cancel();
      _holdTimer = null;
      _lives--;
      if (_lives <= 0) {
        widget.onComplete(
          LevelOutcome(score: 0, metrics: {'failed_stage': _phase}),
        );
        return;
      }
      _pressedPads.clear();
      _pointerToPad.clear();
      _firstPressAt = now;
      desyncMessage = 'desynced. retry the ritual. ($_lives lives left)';
    }

    setState(() {
      _pointerToPad[pointerId] = padId;
      _pressedPads.add(padId);
      if (desyncMessage != null) {
        _status = desyncMessage;
      } else {
        _status = _pressedPads.length == 3
            ? 'perfect sync... hold...'
            : '${_pressedPads.length}/3 channels synced';
      }
    });

    if (_pressedPads.length == 3) {
      _startHoldCheck();
    }
  }

  void _onPadUp(int pointerId) {
    final int? padId = _pointerToPad.remove(pointerId);
    if (padId == null) return;

    final bool padStillPressed = _pointerToPad.containsValue(padId);
    setState(() {
      if (!padStillPressed) {
        _pressedPads.remove(padId);
      }

      if (_pressedPads.length < 3) {
        _holdTimer?.cancel();
        _holdTimer = null;
      }

      if (_pressedPads.isEmpty) {
        _firstPressAt = null;
        _status = 'press and hold all 3 pads at once';
      } else {
        _status = '${_pressedPads.length}/3 channels synced';
      }
    });
  }

  void _onCorePointerDown() {
    if (_phase != 0) return;
    _loseLife('reactor core is locked. sync the outer pads.');
  }

  Widget _livesHeader(int stageIndex) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'stage $stageIndex/3',
            style: TextStyle(
              color: _cyanNeon.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 20),
          ...List.generate(_livesPerStage, (i) {
            final alive = i < _lives;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                Icons.favorite_rounded,
                size: 22,
                color: alive
                    ? const Color(0xFFFF5080)
                    : Colors.white.withValues(alpha: 0.2),
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == 1) {
      return _buildTripleSwipePhase();
    }
    if (_phase == 2) {
      return _buildDualBindPhase();
    }

    final bool allSynced = _pressedPads.length == 3;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [
            const Color(0xFF0D1B2A),
            const Color(0xFF020810),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated grid background
          Positioned.fill(
            child: CustomPaint(
              painter: _GridPainter(animation: _spin),
            ),
          ),
          // Scanlines overlay
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _ScanlinePainter(),
              ),
            ),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _livesHeader(1),
                // Title with glow
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [_cyanNeon, _magentaNeon],
                  ).createShader(bounds),
                  child: Text(
                    'SYNC REACTOR',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 8,
                      shadows: [
                        Shadow(
                          color: _cyanNeon.withValues(alpha: 0.8),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Status text
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: allSynced ? _coreGlow : _cyanNeon.withValues(alpha: 0.7),
                    letterSpacing: 2,
                    shadows: allSynced
                        ? [Shadow(color: _coreGlow, blurRadius: 10)]
                        : [],
                  ),
                  child: Text(
                    _status.toUpperCase(),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                // Reactor core
                AnimatedBuilder(
                  animation: Listenable.merge([_pulse, _spin, _energyFlow]),
                  builder: (context, child) {
                    return SizedBox(
                      width: 340,
                      height: 340,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer spinning rings
                          ...List.generate(3, (i) {
                            return Transform.rotate(
                              angle: _spin.value * 2 * math.pi * (i.isEven ? 1 : -1),
                              child: CustomPaint(
                                size: Size(280 - i * 30, 280 - i * 30),
                                painter: _RingPainter(
                                  color: i == 0
                                      ? _cyanNeon
                                      : i == 1
                                          ? _magentaNeon
                                          : _coreGlow,
                                  dashCount: 12 + i * 4,
                                  strokeWidth: 2 - i * 0.3,
                                  opacity: 0.3 + (_pulse.value * 0.2),
                                ),
                              ),
                            );
                          }),
                          // Energy flow lines to pads
                          CustomPaint(
                            size: const Size(340, 340),
                            painter: _EnergyLinesPainter(
                              activePads: _pressedPads,
                              flowProgress: _energyFlow.value,
                              pulseValue: _pulse.value,
                            ),
                          ),
                          // Central core
                          _buildCore(allSynced),
                          // Sync pads positioned in triangle
                          Positioned(
                            top: 20,
                            child: _SyncPad(
                              label: 'A',
                              sublabel: 'ALPHA',
                              isActive: _pressedPads.contains(0),
                              color: _cyanNeon,
                              onPointerDown: (p) => _onPadDown(0, p),
                              onPointerUp: _onPadUp,
                            ),
                          ),
                          Positioned(
                            left: 20,
                            bottom: 40,
                            child: _SyncPad(
                              label: 'B',
                              sublabel: 'BETA',
                              isActive: _pressedPads.contains(1),
                              color: _magentaNeon,
                              onPointerDown: (p) => _onPadDown(1, p),
                              onPointerUp: _onPadUp,
                            ),
                          ),
                          Positioned(
                            right: 20,
                            bottom: 40,
                            child: _SyncPad(
                              label: 'G',
                              sublabel: 'GAMMA',
                              isActive: _pressedPads.contains(2),
                              color: _coreGlow,
                              onPointerDown: (p) => _onPadDown(2, p),
                              onPointerUp: _onPadUp,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTripleSwipePhase() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            const Color(0xFF0D1B2A),
            const Color(0xFF020810),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              _livesHeader(2),
              Text(
                'TRIPLE LIFT',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _cyanNeon,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _status.toUpperCase(),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: _cyanNeon.withValues(alpha: 0.85),
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: List.generate(3, (i) {
                    const labels = ['I', 'II', 'III'];
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Listener(
                          behavior: HitTestBehavior.opaque,
                          onPointerMove: (e) =>
                              _onLanePointerMove(i, e.delta),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _laneUpAccum[i] >= _laneUpNeeded
                                    ? _coreGlow
                                    : _cyanNeon.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              color: const Color(0xFF0D1B2A),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.arrow_upward_rounded,
                                  size: 40,
                                  color: _magentaNeon.withValues(alpha: 0.9),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    color: _cyanNeon.withValues(alpha: 0.7),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDualBindPhase() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.1,
          colors: [
            const Color(0xFF0D1B2A),
            const Color(0xFF020810),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _livesHeader(3),
              Text(
                'DUAL BIND',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: _magentaNeon,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: _cyanNeon.withValues(alpha: 0.85),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerDown: _onDualAnchorDown,
                        onPointerUp: _onDualAnchorUp,
                        onPointerCancel: _onDualAnchorUp,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _anchorHeld
                                  ? _coreGlow
                                  : _magentaNeon.withValues(alpha: 0.5),
                              width: _anchorHeld ? 3 : 2,
                            ),
                            color: _anchorHeld
                                ? _magentaNeon.withValues(alpha: 0.12)
                                : const Color(0xFF0D1B2A),
                            boxShadow: _anchorHeld
                                ? [
                                    BoxShadow(
                                      color: _magentaNeon.withValues(alpha: 0.35),
                                      blurRadius: 24,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.lock_rounded,
                                size: 48,
                                color: _anchorHeld
                                    ? _coreGlow
                                    : _magentaNeon.withValues(alpha: 0.7),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'anchor',
                                style: TextStyle(
                                  color: _cyanNeon.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'hold',
                                style: TextStyle(
                                  color: _cyanNeon.withValues(alpha: 0.45),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 3,
                      child: Listener(
                        behavior: HitTestBehavior.opaque,
                        onPointerMove: _onDualSwipeMove,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _dualSwipeAccum >= _dualSwipeNeeded
                                  ? _coreGlow
                                  : _cyanNeon.withValues(alpha: 0.5),
                              width: 2,
                            ),
                            color: const Color(0xFF0D1B2A),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 44,
                                color: _cyanNeon.withValues(alpha: 0.9),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'conduit',
                                style: TextStyle(
                                  color: _cyanNeon.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'swipe right (other finger)',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: _cyanNeon.withValues(alpha: 0.45),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCore(bool allSynced) {
    final double pulseScale = 1.0 + (_pulse.value * 0.15);
    final Color coreColor = allSynced ? _coreGlow : _cyanNeon;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _onCorePointerDown(),
      child: SizedBox(
        width: 140,
        height: 140,
        child: Center(
          child: Transform.scale(
            scale: pulseScale,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    coreColor.withValues(alpha: allSynced ? 0.9 : 0.5),
                    coreColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: coreColor.withValues(alpha: allSynced ? 0.8 : 0.4),
                    blurRadius: allSynced ? 40 : 20,
                    spreadRadius: allSynced ? 8 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: coreColor,
                    boxShadow: [
                      BoxShadow(
                        color: coreColor,
                        blurRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Grid background painter
class _GridPainter extends CustomPainter {
  final Animation<double> animation;

  _GridPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final offset = (animation.value * spacing) % spacing;

    // Vertical lines
    for (double x = offset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}

// Scanline effect
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.1);

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Spinning ring painter
class _RingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  final double opacity;

  _RingPainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dashAngle = (2 * math.pi) / dashCount;
    final gapAngle = dashAngle * 0.3;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle - gapAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      opacity != oldDelegate.opacity;
}

// Energy lines connecting pads to center
class _EnergyLinesPainter extends CustomPainter {
  final Set<int> activePads;
  final double flowProgress;
  final double pulseValue;

  static const Color _cyanNeon = Color(0xFF00F5FF);
  static const Color _magentaNeon = Color(0xFFFF00FF);
  static const Color _coreGlow = Color(0xFF00FFAA);

  _EnergyLinesPainter({
    required this.activePads,
    required this.flowProgress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Pad positions (approximate)
    final padPositions = [
      Offset(size.width / 2, 65), // Alpha (top)
      Offset(65, size.height - 85), // Beta (bottom left)
      Offset(size.width - 65, size.height - 85), // Gamma (bottom right)
    ];

    final colors = [_cyanNeon, _magentaNeon, _coreGlow];

    for (int i = 0; i < 3; i++) {
      final isActive = activePads.contains(i);
      final color = colors[i];
      final alpha = isActive ? 0.8 : 0.15;

      // Draw line from pad to center
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.3),
          ],
        ).createShader(Rect.fromPoints(padPositions[i], center))
        ..strokeWidth = isActive ? 3 : 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(padPositions[i], center, paint);

      // Draw flowing energy particles when active
      if (isActive) {
        final particlePaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        for (int p = 0; p < 3; p++) {
          final t = (flowProgress + p * 0.33) % 1.0;
          final pos = Offset.lerp(padPositions[i], center, t)!;
          canvas.drawCircle(pos, 3 - p * 0.5, particlePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyLinesPainter oldDelegate) => true;
}

class _SyncPad extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isActive;
  final Color color;
  final ValueChanged<int> onPointerDown;
  final ValueChanged<int> onPointerUp;

  const _SyncPad({
    required this.label,
    required this.sublabel,
    required this.isActive,
    required this.color,
    required this.onPointerDown,
    required this.onPointerUp,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => onPointerDown(event.pointer),
      onPointerUp: (event) => onPointerUp(event.pointer),
      onPointerCancel: (event) => onPointerUp(event.pointer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF0D1B2A),
          border: Border.all(
            width: isActive ? 3 : 2,
            color: isActive ? color : color.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? color.withValues(alpha: 0.6)
                  : color.withValues(alpha: 0.1),
              blurRadius: isActive ? 30 : 10,
              spreadRadius: isActive ? 4 : 0,
            ),
            if (isActive)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
                fontSize: 28,
                shadows: isActive
                    ? [Shadow(color: color, blurRadius: 15)]
                    : [],
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: isActive
                    ? color.withValues(alpha: 0.9)
                    : color.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
                fontSize: 8,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
