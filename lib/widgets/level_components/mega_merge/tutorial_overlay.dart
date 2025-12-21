import 'dart:math';
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

    // Get overlay's render box to convert global coordinates to local
    final RenderBox? overlayBox = context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    setState(() {
      if (targetKey?.currentContext != null) {
        final RenderBox box =
            targetKey!.currentContext!.findRenderObject() as RenderBox;
        final globalPos = box.localToGlobal(Offset.zero);
        final localPos = overlayBox.globalToLocal(globalPos);
        _targetRect = Rect.fromLTWH(
          localPos.dx,
          localPos.dy,
          box.size.width,
          box.size.height,
        );
      }

      if (sourceKey?.currentContext != null) {
        final RenderBox box =
            sourceKey!.currentContext!.findRenderObject() as RenderBox;
        final globalPos = box.localToGlobal(Offset.zero);
        final localPos = overlayBox.globalToLocal(globalPos);
        _sourcePos = Offset(
          localPos.dx + box.size.width / 2,
          localPos.dy + box.size.height / 2,
        );
      }

      if (destKey?.currentContext != null) {
        final RenderBox box =
            destKey!.currentContext!.findRenderObject() as RenderBox;
        final globalPos = box.localToGlobal(Offset.zero);
        final localPos = overlayBox.globalToLocal(globalPos);
        _destPos = Offset(
          localPos.dx + box.size.width / 2,
          localPos.dy + box.size.height / 2,
        );
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
                  widget: widget,
                  sourcePos: _sourcePos,
                  destPos: _destPos,
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
              final progress = Curves.easeInOut.transform(
                _animController.value,
              );

              // For tap: Show hand and "tap" text
              if (widget.step.requiresTap && _sourcePos == null) {
                // Bobbing animation for the hand
                final offset = sin(progress * pi * 2) * 5;

                return Positioned(
                  left: _targetRect!.center.dx - 20, // Center horizontally
                  top:
                      _targetRect!.center.dy +
                      (_targetRect!.height / 2) +
                      10 +
                      offset,
                  child: IgnorePointer(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 48,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: NunuColors.primaryMain,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TAP',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // For drag: animate from source to dest
              if (widget.step.requiresDrag &&
                  _sourcePos != null &&
                  _destPos != null) {
                final currentPos = Offset.lerp(
                  _sourcePos!,
                  _destPos!,
                  progress,
                )!;

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
  final TutorialOverlay widget;
  final Offset? _sourcePos;
  final Offset? _destPos;
  final double padding;

  _SpotlightPainter({
    required this.targetRect,
    required this.widget,
    Offset? sourcePos,
    Offset? destPos,
    this.padding = 8.0,
  }) : _sourcePos = sourcePos,
       _destPos = destPos;

  @override
  void paint(Canvas canvas, Size size) {
    // Save layer to allow clearing pixels (creating a cutout)
    canvas.saveLayer(Offset.zero & size, Paint());

    final paint = Paint()..color = Colors.black.withOpacity(0.45);

    // Draw full dark overlay
    canvas.drawRect(Offset.zero & size, paint);

    // Cut out the spotlight area
    final center = targetRect.center;
    final isOval = widget.step.requiresDrag && widget.step.sourceKey != null;

    final clearPaint = Paint()..blendMode = BlendMode.clear;

    if (isOval && _sourcePos != null && _destPos != null) {
      // Calculate oval containing both source and dest
      final sourceRect = Rect.fromCenter(
        center: _sourcePos!,
        width: targetRect.width,
        height: targetRect.height,
      );
      final destRect = Rect.fromCenter(
        center: _destPos!,
        width: targetRect.width,
        height: targetRect.height,
      );

      final boundingBox = sourceRect.expandToInclude(destRect).inflate(padding);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          boundingBox,
          Radius.circular(boundingBox.shortestSide / 2),
        ),
        clearPaint,
      );

      // Draw glow border
      final glowPaint = Paint()
        ..color = NunuColors.primaryMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          boundingBox,
          Radius.circular(boundingBox.shortestSide / 2),
        ),
        glowPaint,
      );
    } else {
      // Use diagonal for radius to ensure corners are visible, plus padding
      final radius =
          (sqrt(
                targetRect.width * targetRect.width +
                    targetRect.height * targetRect.height,
              ) /
              2) +
          padding;

      canvas.drawCircle(center, radius, clearPaint);

      // Draw glow border around spotlight
      final glowPaint = Paint()
        ..color = NunuColors.primaryMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      canvas.drawCircle(center, radius, glowPaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(_SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect;
  }
}
