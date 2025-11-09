import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelWireTask extends LevelWidget {
  const LevelWireTask({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelWireTask> createState() => _LevelWireTaskState();
}

class _LevelWireTaskState extends State<LevelWireTask> {
  final List<Color> _wireColors = [
    Colors.red,
    Colors.blue,
    Colors.yellow,
    Colors.pink,
  ];

  late List<Color> _leftWires;
  late List<Color> _rightWires;
  final Map<int, int> _connections = {}; // left index -> right index

  int? _draggingFromLeft;
  Offset? _dragPosition;
  final GlobalKey _stackKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _leftWires = List.from(_wireColors);
    _rightWires = List.from(_wireColors)..shuffle();
  }

  Offset? _getLocalPosition(Offset globalPosition) {
    final RenderBox? box = _stackKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return box.globalToLocal(globalPosition);
  }

  void _onPanStart(DragStartDetails details, int leftIndex) {
    final localPos = _getLocalPosition(details.globalPosition);
    if (localPos == null) return;

    setState(() {
      _draggingFromLeft = leftIndex;
      _dragPosition = localPos;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    final localPos = _getLocalPosition(details.globalPosition);
    if (localPos == null) return;

    setState(() {
      _dragPosition = localPos;
    });
  }

  void _onPanEnd(DragEndDetails details, Size screenSize) {
    if (_draggingFromLeft == null || _dragPosition == null) return;

    // Check if dropped on a right wire
    final rightIndex = _getRightWireAtPosition(_dragPosition!, screenSize);

    if (rightIndex != null) {
      // Check if colors match
      if (_leftWires[_draggingFromLeft!] == _rightWires[rightIndex]) {
        setState(() {
          _connections[_draggingFromLeft!] = rightIndex;
        });

        // Check if all wires connected
        if (_connections.length == _wireColors.length) {
          Future.delayed(const Duration(milliseconds: 500), () {
            widget.onComplete(true);
          });
        }
      }
    }

    setState(() {
      _draggingFromLeft = null;
      _dragPosition = null;
    });
  }

  int? _getRightWireAtPosition(Offset position, Size screenSize) {
    final rightX = screenSize.width - 60; // Center of right box
    final startY = (screenSize.height - (_wireColors.length * 80)) / 2;

    for (int i = 0; i < _rightWires.length; i++) {
      final wireY = startY + (i * 80) + 40; // Center of box
      final wireCenterPos = Offset(rightX, wireY);
      final distance = (position - wireCenterPos).distance;

      if (distance < 50) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
          color: Colors.transparent,
          child: Stack(
            key: _stackKey,
            children: [
              // Progress indicator
              Positioned(
                top: 20,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '${_connections.length} / ${_wireColors.length}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: NunuColors.textSecondary,
                    ),
                  ),
                ),
              ),
              // Wires and connections
              CustomPaint(
                size: size,
                painter: WirePainter(
                  leftWires: _leftWires,
                  rightWires: _rightWires,
                  connections: _connections,
                  draggingFromLeft: _draggingFromLeft,
                  dragPosition: _dragPosition,
                ),
              ),
              // Left wire endpoints (draggable)
              ..._buildLeftWires(size),
              // Right wire endpoints
              ..._buildRightWires(size),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildLeftWires(Size size) {
    final List<Widget> widgets = [];
    final startY = (size.height - (_wireColors.length * 80)) / 2;

    for (int i = 0; i < _leftWires.length; i++) {
      final isConnected = _connections.containsKey(i);
      final isBeingDragged = _draggingFromLeft == i;

      widgets.add(
        Positioned(
          left: 20,
          top: startY + (i * 80),
          child: GestureDetector(
            onPanStart: (details) => _onPanStart(details, i),
            onPanUpdate: _onPanUpdate,
            onPanEnd: (details) => _onPanEnd(details, size),
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isBeingDragged
                      ? _leftWires[i]
                      : (isConnected ? Colors.green : Colors.grey.shade700),
                  width: 3,
                ),
              ),
              child: Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _leftWires[i],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _leftWires[i].withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }

  List<Widget> _buildRightWires(Size size) {
    final List<Widget> widgets = [];
    final startY = (size.height - (_wireColors.length * 80)) / 2;
    final connectedRightIndices = _connections.values.toSet();

    for (int i = 0; i < _rightWires.length; i++) {
      final isConnected = connectedRightIndices.contains(i);

      widgets.add(
        Positioned(
          right: 20,
          top: startY + (i * 80),
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isConnected ? Colors.green : Colors.grey.shade700,
                width: 3,
              ),
            ),
            child: Center(
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _rightWires[i],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _rightWires[i].withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return widgets;
  }
}

class WirePainter extends CustomPainter {
  final List<Color> leftWires;
  final List<Color> rightWires;
  final Map<int, int> connections;
  final int? draggingFromLeft;
  final Offset? dragPosition;

  WirePainter({
    required this.leftWires,
    required this.rightWires,
    required this.connections,
    this.draggingFromLeft,
    this.dragPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final startY = (size.height - (leftWires.length * 80)) / 2;

    // Draw completed connections
    connections.forEach((leftIndex, rightIndex) {
      final leftY = startY + (leftIndex * 80) + 40;
      final rightY = startY + (rightIndex * 80) + 40;
      final leftX = 60.0; // Center of left box
      final rightX = size.width - 60.0; // Center of right box

      final paint = Paint()
        ..color = leftWires[leftIndex]
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(leftX, leftY);

      // Bezier curve for nice wire effect
      final controlPoint1 = Offset(size.width * 0.3, leftY);
      final controlPoint2 = Offset(size.width * 0.7, rightY);
      final endPoint = Offset(rightX, rightY);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        endPoint.dx, endPoint.dy,
      );

      canvas.drawPath(path, paint);
    });

    // Draw wire being dragged
    if (draggingFromLeft != null && dragPosition != null) {
      final leftY = startY + (draggingFromLeft! * 80) + 40;
      final leftX = 60.0;

      final paint = Paint()
        ..color = leftWires[draggingFromLeft!].withValues(alpha: 0.7)
        ..strokeWidth = 6
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(leftX, leftY);

      final controlPoint1 = Offset((leftX + dragPosition!.dx) / 2, leftY);
      final controlPoint2 = Offset((leftX + dragPosition!.dx) / 2, dragPosition!.dy);

      path.cubicTo(
        controlPoint1.dx, controlPoint1.dy,
        controlPoint2.dx, controlPoint2.dy,
        dragPosition!.dx, dragPosition!.dy,
      );

      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(WirePainter oldDelegate) => true;
}