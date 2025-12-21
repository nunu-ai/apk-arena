import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Tutorial step data
class TutorialStep {
  final String instruction;
  final GlobalKey? targetKey;
  final GlobalKey? sourceKey;
  final GlobalKey? destinationKey;
  final bool requiresTap;
  final bool requiresDrag;
  final VoidCallback? onComplete;

  const TutorialStep({
    required this.instruction,
    this.targetKey,
    this.sourceKey,
    this.destinationKey,
    this.requiresTap = false,
    this.requiresDrag = false,
    this.onComplete,
  });
}

/// Spotlight overlay with animated hand indicator and text box
class TutorialOverlay extends StatefulWidget {
  final TutorialStep step;
  final VoidCallback onStepComplete;
  final Widget child;

  const TutorialOverlay({
    Key? key,
    required this.step,
    required this.onStepComplete,
    required this.child,
  }) : super(key: key);

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  Rect? _targetRect;
  Offset? _sourcePos;
  Offset? _destPos;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePositions());
  }

  @override
  void didUpdateWidget(TutorialOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updatePositions());
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _updatePositions() {
    final targetKey = widget.step.targetKey;
    final sourceKey = widget.step.sourceKey;
    final destKey = widget.step.destinationKey;

    setState(() {
      if (targetKey?.currentContext != null) {
        final RenderBox box =
            targetKey!.currentContext!.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);
        _targetRect = Rect.fromLTWH(pos.dx, pos.dy, box.size.width, box.size.height);
      }

      if (sourceKey?.currentContext != null) {
        final RenderBox box =
            sourceKey!.currentContext!.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);
        _sourcePos = Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
      }

      if (destKey?.currentContext != null) {
        final RenderBox box =
            destKey!.currentContext!.findRenderObject() as RenderBox;
        final pos = box.localToGlobal(Offset.zero);
        _destPos = Offset(pos.dx + box.size.width / 2, pos.dy + box.size.height / 2);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        // Dark overlay with spotlight cutout
        if (_targetRect != null)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _SpotlightPainter(
                  targetRect: _targetRect!,
                  padding: 8.0,
                ),
              ),
            ),
          ),
        // Animated hand/pulse indicator
        if (_targetRect != null)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final progress = Curves.easeInOut.transform(_animController.value);
              
              // For tap: pulse at target
              if (widget.step.requiresTap && _sourcePos == null) {
                final scale = 1.0 + progress * 0.3;
                final opacity = 1.0 - progress * 0.5;
                
                return Positioned(
                  left: _targetRect!.center.dx - 25,
                  top: _targetRect!.center.dy - 25,
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NunuColors.primaryMain,
                              width: 3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }
              
              // For drag: animate from source to dest
              if (widget.step.requiresDrag && _sourcePos != null && _destPos != null) {
                final currentPos = Offset.lerp(_sourcePos!, _destPos!, progress)!;
                
                return Positioned(
                  left: currentPos.dx - 20,
                  top: currentPos.dy - 20,
                  child: IgnorePointer(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NunuColors.primaryMain.withOpacity(0.5),
                        border: Border.all(
                          color: NunuColors.primaryMain,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.touch_app,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                );
              }
              
              return const SizedBox.shrink();
            },
          ),
        // Instruction text box
        Positioned(
          bottom: 100,
          left: 20,
          right: 20,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: NunuColors.primaryMain, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: NunuColors.primaryMain.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      widget.step.instruction,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: NunuColors.primaryMain.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      color: NunuColors.primaryMain,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Custom painter for spotlight effect
class _SpotlightPainter extends CustomPainter {
  final Rect targetRect;
  final double padding;

  _SpotlightPainter({
    required this.targetRect,
    this.padding = 8.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withOpacity(0.7);
    
    // Draw full dark overlay
    canvas.drawRect(Offset.zero & size, paint);
    
    // Cut out the spotlight area
    final spotlightRect = targetRect.inflate(padding);
    final clearPaint = Paint()
      ..blendMode = BlendMode.clear;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlightRect, const Radius.circular(12)),
      clearPaint,
    );
    
    // Draw glow border around spotlight
    final glowPaint = Paint()
      ..color = NunuColors.primaryMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(spotlightRect, const Radius.circular(12)),
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}

