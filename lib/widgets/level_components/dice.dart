import 'package:flutter/material.dart';

class DiceWidget extends StatelessWidget {
  final int value;
  final double size;

  const DiceWidget({
    Key? key,
    required this.value,
    this.size = 60,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.133), // Proportional to size
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: size * 0.1,
            offset: Offset(0, size * 0.05),
          ),
        ],
      ),
      child: _buildDots(),
    );
  }

  Widget _buildDots() {
    final dotPositions = _getDotPositions(value);

    return Stack(
      children: dotPositions.map((position) {
        return Positioned(
          left: position.dx * size,
          top: position.dy * size,
          child: Container(
            width: size * 0.167, // Proportional dot size
            height: size * 0.167,
            decoration: const BoxDecoration(
              color: Colors.black,
              shape: BoxShape.circle,
            ),
          ),
        );
      }).toList(),
    );
  }

  List<Offset> _getDotPositions(int value) {
    // Using relative positions (0.0 to 1.0) for scalability
    const double margin = 0.2;
    const double center = 0.417; // Centered position
    const double left = margin;
    const double right = 0.8 - 0.167; // 1.0 - margin - dot proportion
    const double top = margin;
    const double bottom = 0.8 - 0.167;

    switch (value) {
      case 1:
        return [const Offset(center, center)];
      case 2:
        return [
          const Offset(left, top),
          const Offset(right, bottom),
        ];
      case 3:
        return [
          const Offset(left, top),
          const Offset(center, center),
          const Offset(right, bottom),
        ];
      case 4:
        return [
          const Offset(left, top),
          const Offset(right, top),
          const Offset(left, bottom),
          const Offset(right, bottom),
        ];
      case 5:
        return [
          const Offset(left, top),
          const Offset(right, top),
          const Offset(center, center),
          const Offset(left, bottom),
          const Offset(right, bottom),
        ];
      case 6:
        return [
          const Offset(left, top),
          const Offset(right, top),
          const Offset(left, center),
          const Offset(right, center),
          const Offset(left, bottom),
          const Offset(right, bottom),
        ];
      default:
        return [];
    }
  }
}