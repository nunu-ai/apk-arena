import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelGemSocket extends LevelWidget {
  const LevelGemSocket({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelGemSocket> createState() => _LevelGemSocketState();
}

class _LevelGemSocketState extends State<LevelGemSocket>
    with TickerProviderStateMixin {
  static const Offset _fingerOffset = Offset(0, -110);
  static const double _gemSize = 64.0;
  static const double _targetSize = 80.0;
  static const double _hitRadius = 40.0;
  static const double _scorePerStage = 0.15;
  static const double _scorePerLife = 0.04;

  static const int _totalStages = 4;
  static const int _maxLives = 10;

  int _socketStage = 0;
  int _stagesCleared = 0;
  int _lives = _maxLives;
  bool _layoutReady = false;
  bool _levelFinished = false;
  final Random _rng = SeedService.instance.createRandom();

  bool _isDragging = false;
  bool _isPlaced = false;
  Offset _fingerPosition = Offset.zero;
  Offset _dragStartPosition = Offset.zero;
  Offset _gemRestPosition = Offset.zero;
  Offset _targetCenter = Offset.zero;
  Size _layoutSize = Size.zero;

  double _driftDirection = 1.0;

  /// Stage 0: generous tolerance, no drift
  /// Stage 1: tight tolerance, vertical drift
  /// Stage 2: generous tolerance, lateral drift
  /// Stage 3: tight tolerance + lateral drift
  double get _snapTolerance {
    switch (_socketStage) {
      case 1:
      case 3:
        return _targetSize * 0.30;
      default:
        return _targetSize / 2 + _gemSize / 4;
    }
  }

  double get _lateralDriftFactor {
    switch (_socketStage) {
      case 2:
        return 0.55;
      case 3:
        return 0.8;
      default:
        return 0.0;
    }
  }

  double get _verticalDriftFactor {
    switch (_socketStage) {
      case 1:
        return 0.45;
      default:
        return 0.0;
    }
  }

  late AnimationController _snapBackController;
  late Animation<Offset> _snapBackAnimation;
  late AnimationController _liftController;
  late AnimationController _pulseController;
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: _calculateScore().clamp(0.0, 1.0),
          metrics: {'stages_cleared': _stagesCleared},
        ));

    _snapBackController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _snapBackAnimation = Tween<Offset>(begin: Offset.zero, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _snapBackController,
            curve: Curves.elasticOut,
          ),
        );
    _snapBackController.addListener(() => setState(() {}));

    _liftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _liftController.addListener(() => setState(() {}));

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseController.addListener(() => setState(() {}));

    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _successController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _snapBackController.dispose();
    _liftController.dispose();
    _pulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  Offset get _gemDisplayPosition {
    if (_isPlaced) return _targetCenter;

    if (_isDragging) {
      final liftProgress = _liftController.value;
      final currentOffset = Offset(
        _fingerOffset.dx * liftProgress,
        _fingerOffset.dy * liftProgress,
      );
      var pos = _fingerPosition + currentOffset;

      final verticalDelta = _dragStartPosition.dy - _fingerPosition.dy;
      if (verticalDelta > 0) {
        if (_lateralDriftFactor > 0) {
          pos = Offset(
            pos.dx + verticalDelta * _lateralDriftFactor * _driftDirection,
            pos.dy,
          );
        }
        if (_verticalDriftFactor > 0) {
          pos = Offset(pos.dx, pos.dy - verticalDelta * _verticalDriftFactor);
        }
      }

      return pos;
    }

    if (_snapBackController.isAnimating) return _snapBackAnimation.value;

    return _gemRestPosition;
  }

  double _calculateScore() {
    return (_stagesCleared * _scorePerStage) + (_lives * _scorePerLife);
  }

  void _finishLevel() {
    if (_levelFinished) return;
    _levelFinished = true;
    widget.onComplete(
      LevelOutcome(
        score: _calculateScore(),
        metrics: {
          'stages_cleared': _stagesCleared,
          'lives_remaining': _lives,
          'max_lives': _maxLives,
        },
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_isPlaced || _levelFinished) return;

    final touchPos = details.localPosition;
    if ((touchPos - _gemRestPosition).distance <= _hitRadius) {
      setState(() {
        _isDragging = true;
        _fingerPosition = touchPos;
        _dragStartPosition = touchPos;
        _snapBackController.reset();
      });
      _liftController.forward();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isPlaced || _levelFinished) return;
    setState(() {
      _fingerPosition = details.localPosition;
    });
  }

  void _randomizeLayout(Size size) {
    final w = size.width;
    final h = size.height;
    const pad = 56.0;
    final topSpan = (h * 0.36 - 2 * pad).clamp(40.0, h);
    final bottomTop = h * 0.52;
    final bottomSpan = (h - bottomTop - pad - 72).clamp(48.0, h);

    _driftDirection = _rng.nextBool() ? 1.0 : -1.0;

    final hasLateralDrift = _socketStage >= 2;
    double targetX;
    if (hasLateralDrift) {
      // Drift left → target on left half, drift right → target on right half.
      // Prevents impossible scenarios where the finger would need to leave
      // the screen to compensate for the drift.
      if (_driftDirection < 0) {
        targetX = pad + _rng.nextDouble() * ((w * 0.45) - pad).clamp(40.0, w);
      } else {
        targetX =
            (w * 0.55) +
            _rng.nextDouble() * (w - (w * 0.55) - pad).clamp(40.0, w);
      }
    } else {
      targetX = pad + _rng.nextDouble() * (w - 2 * pad).clamp(40.0, w);
    }

    _targetCenter = Offset(targetX, pad + _rng.nextDouble() * topSpan);
    _gemRestPosition = Offset(
      pad + _rng.nextDouble() * (w - 2 * pad).clamp(40.0, w),
      bottomTop + _rng.nextDouble() * bottomSpan,
    );
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _isPlaced || _levelFinished) return;

    final displayPos = _gemDisplayPosition;
    final distanceToTarget = (displayPos - _targetCenter).distance;

    setState(() {
      _isDragging = false;
    });
    _liftController.reset();

    if (distanceToTarget <= _snapTolerance) {
      setState(() {
        _isPlaced = true;
      });
      _successController.forward().then((_) {
        if (!mounted) return;
        _stagesCleared++;
        if (_stagesCleared >= _totalStages) {
          _finishLevel();
        } else {
          setState(() {
            _socketStage = _stagesCleared;
            _isPlaced = false;
            _successController.reset();
            _snapBackController.reset();
            _randomizeLayout(_layoutSize);
          });
        }
      });
    } else {
      setState(() {
        _lives = max(0, _lives - 1);
      });

      _snapBackAnimation =
          Tween<Offset>(begin: displayPos, end: _gemRestPosition).animate(
            CurvedAnimation(
              parent: _snapBackController,
              curve: Curves.elasticOut,
            ),
          );
      _snapBackController.forward(from: 0);

      if (_lives == 0) {
        _finishLevel();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NunuColors.backgroundDefault,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;
          _layoutSize = size;

          if (size.shortestSide > 0 && !_layoutReady) {
            _layoutReady = true;
            _randomizeLayout(size);
          }

          return GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: _BackgroundPainter(),
              child: Stack(
                children: [
                  _buildTargetSocket(),
                  if (_isDragging) _buildConnectorLine(),
                  if (!_isPlaced) _buildGem(),
                  if (_isPlaced) _buildPlacedGem(),
                  if (_isDragging) _buildFingerIndicator(),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    child: AbsorbPointer(
                      child: LevelHud(
                        stageText: '${_socketStage + 1}/$_totalStages',
                        lives: LevelHud.emojiLives(_lives, _maxLives),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTargetSocket() {
    final pulseValue = _pulseController.value;
    final glowOpacity = _isPlaced ? 0.8 : 0.15 + pulseValue * 0.2;
    final glowColor = _isPlaced
        ? NunuColors.successMain
        : NunuColors.secondaryMain;

    return Positioned(
      left: _targetCenter.dx - _targetSize / 2,
      top: _targetCenter.dy - _targetSize / 2,
      child: Container(
        width: _targetSize,
        height: _targetSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF2A2040),
          border: Border.all(
            color: glowColor.withOpacity(0.6 + pulseValue * 0.4),
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: glowColor.withOpacity(glowOpacity),
              blurRadius: 20 + pulseValue * 10,
              spreadRadius: 2 + pulseValue * 4,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: _targetSize * 0.5,
            height: _targetSize * 0.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1030),
              border: Border.all(color: glowColor.withOpacity(0.3), width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGem() {
    final pos = _gemDisplayPosition;
    final scale = _isDragging ? 1.0 + 0.2 * _liftController.value : 1.0;
    final glowIntensity = _isDragging ? 0.6 : 0.3;

    return Positioned(
      left: pos.dx - _gemSize / 2,
      top: pos.dy - _gemSize / 2,
      child: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: _gemSize,
            height: _gemSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NunuColors.primaryMain.withOpacity(glowIntensity),
                  blurRadius: _isDragging ? 24 : 12,
                  spreadRadius: _isDragging ? 6 : 2,
                ),
              ],
            ),
            child: Icon(
              Icons.diamond,
              size: _gemSize,
              color: NunuColors.primaryLight,
              shadows: [
                Shadow(
                  color: NunuColors.primaryMain.withOpacity(0.8),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacedGem() {
    final progress = _successController.value;
    final scale = 1.0 + 0.3 * sin(progress * pi);
    final pos = _targetCenter;

    return Positioned(
      left: pos.dx - _gemSize / 2,
      top: pos.dy - _gemSize / 2,
      child: IgnorePointer(
        child: Transform.scale(
          scale: scale,
          child: Container(
            width: _gemSize,
            height: _gemSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: NunuColors.successMain.withOpacity(
                    0.6 + 0.4 * progress,
                  ),
                  blurRadius: 24 + 16 * progress,
                  spreadRadius: 6 + 8 * progress,
                ),
              ],
            ),
            child: Icon(
              Icons.diamond,
              size: _gemSize,
              color: NunuColors.successLight,
              shadows: [
                Shadow(
                  color: NunuColors.successMain.withOpacity(0.8),
                  blurRadius: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectorLine() {
    final gemPos = _gemDisplayPosition;
    return Positioned.fill(
      child: IgnorePointer(
        child: CustomPaint(
          painter: _ConnectorPainter(from: _fingerPosition, to: gemPos),
        ),
      ),
    );
  }

  Widget _buildFingerIndicator() {
    return Positioned(
      left: _fingerPosition.dx - 12,
      top: _fingerPosition.dy - 12,
      child: IgnorePointer(
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withOpacity(0.15),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NunuColors.secondaryDarker.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height * 0.25);
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, 50.0 + i * 30.0, paint);
    }

    final dashPaint = Paint()
      ..color = NunuColors.secondaryDarker.withOpacity(0.08)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const dashLength = 8.0;
    const gapLength = 12.0;
    double y = size.height * 0.35;
    while (y < size.height * 0.65) {
      canvas.drawLine(
        Offset(size.width / 2, y),
        Offset(size.width / 2, y + dashLength),
        dashPaint,
      );
      y += dashLength + gapLength;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ConnectorPainter extends CustomPainter {
  final Offset from;
  final Offset to;

  _ConnectorPainter({required this.from, required this.to});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawLine(from, to, paint);

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(from, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      from != oldDelegate.from || to != oldDelegate.to;
}
