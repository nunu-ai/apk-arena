import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelDvdLogo extends LevelWidget {
  const LevelDvdLogo({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelDvdLogo> createState() => _LevelDvdLogoState();
}

class _LevelDvdLogoState extends State<LevelDvdLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Offset _position = const Offset(100, 100);
  Offset _velocity = const Offset(2, 1.5);
  late Size _logoSize;
  Color _logoColor = Colors.red;
  Size _screenSize = Size.zero;

  final List<Color> _colors = [
    Colors.red,
    Colors.blue,
    Colors.green,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _logoSize = const Size(120, 60);

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1), // Essentially infinite
    )..addListener(_updatePosition);

    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updatePosition() {
    if (!mounted || _screenSize == Size.zero) return;

    setState(() {
      // Update position
      _position = Offset(
        _position.dx + _velocity.dx,
        _position.dy + _velocity.dy,
      );

      // Check for collisions and bounce
      bool bounced = false;

      // Right wall
      if (_position.dx + _logoSize.width >= _screenSize.width) {
        _position = Offset(_screenSize.width - _logoSize.width, _position.dy);
        _velocity = Offset(-_velocity.dx, _velocity.dy);
        bounced = true;
      }

      // Left wall
      if (_position.dx <= 0) {
        _position = Offset(0, _position.dy);
        _velocity = Offset(-_velocity.dx, _velocity.dy);
        bounced = true;
      }

      // Bottom wall
      if (_position.dy + _logoSize.height >= _screenSize.height) {
        _position = Offset(_position.dx, _screenSize.height - _logoSize.height);
        _velocity = Offset(_velocity.dx, -_velocity.dy);
        bounced = true;
      }

      // Top wall
      if (_position.dy <= 0) {
        _position = Offset(_position.dx, 0);
        _velocity = Offset(_velocity.dx, -_velocity.dy);
        bounced = true;
      }

      // Change color on bounce
      if (bounced) {
        _logoColor = _colors[Random().nextInt(_colors.length)];
      }
    });
  }

  void _handleTap(TapDownDetails details) {
    // Check if tap is within logo bounds
    final tapPosition = details.localPosition;
    final logoRect = Rect.fromLTWH(
      _position.dx,
      _position.dy,
      _logoSize.width,
      _logoSize.height,
    );

    if (logoRect.contains(tapPosition)) {
      // Success!
      _controller.stop();
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          onTapDown: _handleTap,
          child: Container(
            color: Colors.black,
            child: Stack(
              children: [
                // DVD Logo
                Positioned(
                  left: _position.dx,
                  top: _position.dy,
                  child: Container(
                    width: _logoSize.width,
                    height: _logoSize.height,
                    decoration: BoxDecoration(
                      color: _logoColor,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: _logoColor.withValues(alpha: 0.5),
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
                              fontSize: 32,
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
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
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
        );
      },
    );
  }
}