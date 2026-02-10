import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelGemSocket extends LevelWidget {
  const LevelGemSocket({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelGemSocket> createState() => _LevelGemSocketState();
}

class _LevelGemSocketState extends State<LevelGemSocket>
    with TickerProviderStateMixin {
  // The core mechanic: item renders this far above the finger
  static const Offset _fingerOffset = Offset(0, -110);

  // Gem size and target size
  static const double _gemSize = 64.0;
  static const double _targetSize = 80.0;
  static const double _hitRadius = 40.0; // how close finger must be to pick up

  // State
  bool _isDragging = false;
  bool _isPlaced = false;
  Offset _fingerPosition = Offset.zero;
  Offset _gemRestPosition = Offset.zero;
  Offset _targetCenter = Offset.zero;

  // Snap-back animation
  late AnimationController _snapBackController;
  late Animation<Offset> _snapBackAnimation;

  // Lift animation (gem rises from finger to offset position)
  late AnimationController _liftController;

  // Pulse animation for the target socket
  late AnimationController _pulseController;

  // Success animation
  late AnimationController _successController;

  @override
  void initState() {
    super.initState();

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

  /// The displayed position of the gem (accounting for offset when dragging)
  Offset get _gemDisplayPosition {
    if (_isPlaced) {
      return _targetCenter;
    }

    if (_isDragging) {
      final liftProgress = _liftController.value;
      final currentOffset = Offset(
        _fingerOffset.dx * liftProgress,
        _fingerOffset.dy * liftProgress,
      );
      return _fingerPosition + currentOffset;
    }

    // Snap-back in progress
    if (_snapBackController.isAnimating) {
      return _snapBackAnimation.value;
    }

    return _gemRestPosition;
  }

  void _onPanStart(DragStartDetails details) {
    if (_isPlaced) return;

    final touchPos = details.localPosition;
    final gemCenter = _gemRestPosition;

    // Check if touch is near the gem
    if ((touchPos - gemCenter).distance <= _hitRadius) {
      setState(() {
        _isDragging = true;
        _fingerPosition = touchPos;
        _snapBackController.reset();
      });
      _liftController.forward();
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDragging || _isPlaced) return;

    setState(() {
      _fingerPosition = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDragging || _isPlaced) return;

    final displayPos = _gemDisplayPosition;
    final distanceToTarget = (displayPos - _targetCenter).distance;

    setState(() {
      _isDragging = false;
    });
    _liftController.reset();

    // Check if the displayed gem (not the finger!) overlaps the target
    if (distanceToTarget <= _targetSize / 2 + _gemSize / 4) {
      // Success!
      setState(() {
        _isPlaced = true;
      });
      _successController.forward().then((_) {
        widget.onComplete(true);
      });
    } else {
      // Snap back to rest position
      _snapBackAnimation =
          Tween<Offset>(begin: displayPos, end: _gemRestPosition).animate(
            CurvedAnimation(
              parent: _snapBackController,
              curve: Curves.elasticOut,
            ),
          );
      _snapBackController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NunuColors.backgroundDefault,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final size = constraints.biggest;

          // Position gem at bottom-center, target at top-center
          _gemRestPosition = Offset(size.width / 2, size.height * 0.75);
          _targetCenter = Offset(size.width / 2, size.height * 0.25);

          return GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            behavior: HitTestBehavior.opaque,
            child: CustomPaint(
              painter: _BackgroundPainter(),
              child: Stack(
                children: [
                  // Target socket
                  _buildTargetSocket(),

                  // Ghost connector line (finger to gem) while dragging
                  if (_isDragging) _buildConnectorLine(),

                  // The gem
                  if (!_isPlaced) _buildGem(),

                  // Placed gem (with success animation)
                  if (_isPlaced) _buildPlacedGem(),

                  // Finger indicator while dragging
                  if (_isDragging) _buildFingerIndicator(),

                  // Hint text
                  if (!_isDragging && !_isPlaced) _buildHint(),
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

  Widget _buildHint() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'drag the gem to the socket above',
          style: TextStyle(
            color: NunuColors.textSecondary.withOpacity(0.5),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

/// Draws subtle background runes / arcane circles
class _BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = NunuColors.secondaryDarker.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Draw a few concentric arcane circles around the target area
    final center = Offset(size.width / 2, size.height * 0.25);
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, 50.0 + i * 30.0, paint);
    }

    // Draw subtle guide line from bottom to top
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

/// Draws the faint line from finger position to the offset gem position
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

    // Small dot at the finger position
    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(from, 3, dotPaint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter oldDelegate) =>
      from != oldDelegate.from || to != oldDelegate.to;
}
