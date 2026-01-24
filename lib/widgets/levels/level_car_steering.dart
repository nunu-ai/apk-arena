import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class Obstacle {
  double x; // 0.0 to 1.0 normalized horizontal position
  double y; // vertical position in pixels (starts negative, scrolls down)
  double width; // width as fraction of screen width

  Obstacle({required this.x, required this.y, required this.width});
}

class LevelCarSteering extends LevelWidget {
  const LevelCarSteering({super.key, required super.onComplete});

  @override
  State<LevelCarSteering> createState() => _LevelCarSteeringState();
}

class _LevelCarSteeringState extends State<LevelCarSteering>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  // Game state
  double _carX = 0.5; // normalized 0.0 to 1.0
  double _distance = 0;
  final double _targetDistance = 150;
  final List<Obstacle> _obstacles = [];
  bool _isPressingLeft = false;
  bool _isPressingRight = false;
  bool _gameOver = false;

  // Game parameters
  final double _carSpeed = 0.018; // lateral movement per frame
  final double _obstacleSpeed = 3.0; // pixels per frame
  final double _spawnInterval = 100; // frames between spawns
  double _framesSinceLastSpawn = 0;
  final double _carWidth = 0.10; // as fraction of screen width
  final double _carHeight = 50;
  final double _obstacleHeight = 60;

  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_gameLoop);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _gameLoop() {
    if (!mounted || _screenSize == Size.zero || _gameOver) return;

    setState(() {
      // Move car based on button presses
      if (_isPressingLeft && !_isPressingRight) {
        _carX = (_carX - _carSpeed).clamp(0.0, 1.0 - _carWidth);
      } else if (_isPressingRight && !_isPressingLeft) {
        _carX = (_carX + _carSpeed).clamp(0.0, 1.0 - _carWidth);
      }

      // Move obstacles down
      for (var obstacle in _obstacles) {
        obstacle.y += _obstacleSpeed;
      }

      // Remove obstacles that have passed the bottom
      _obstacles.removeWhere((o) => o.y > _screenSize.height + _obstacleHeight);

      // Spawn new obstacles
      _framesSinceLastSpawn++;
      if (_framesSinceLastSpawn >= _spawnInterval) {
        _spawnObstacle();
        _framesSinceLastSpawn = 0;
      }

      // Check collisions
      if (_checkCollision()) {
        _gameOver = true;
        _controller.stop();
        widget.onComplete(false);
        return;
      }

      // Increment distance
      _distance += 0.1;

      // Check win condition
      if (_distance >= _targetDistance) {
        _gameOver = true;
        _controller.stop();
        widget.onComplete(true);
      }
    });
  }

  void _spawnObstacle() {
    // Spawn 1-2 obstacles per wave
    final obstacleCount = _random.nextInt(2) + 1;
    final usedPositions = <double>[];

    for (var i = 0; i < obstacleCount; i++) {
      double x;
      int attempts = 0;
      do {
        x =
            _random.nextDouble() *
            (1.0 - 0.15); // leave room for obstacle width
        attempts++;
      } while (usedPositions.any((pos) => (pos - x).abs() < 0.2) &&
          attempts < 10);

      if (attempts < 10) {
        usedPositions.add(x);
        _obstacles.add(
          Obstacle(
            x: x,
            y: -_obstacleHeight,
            width: 0.12 + _random.nextDouble() * 0.08, // 0.12 to 0.20
          ),
        );
      }
    }
  }

  bool _checkCollision() {
    final carLeft = _carX * _screenSize.width;
    final carRight = carLeft + _carWidth * _screenSize.width;
    final carTop = _screenSize.height - 180 - _carHeight;
    final carBottom = carTop + _carHeight;

    for (var obstacle in _obstacles) {
      final obsLeft = obstacle.x * _screenSize.width;
      final obsRight = obsLeft + obstacle.width * _screenSize.width;
      final obsTop = obstacle.y;
      final obsBottom = obsTop + _obstacleHeight;

      // AABB collision
      if (carLeft < obsRight &&
          carRight > obsLeft &&
          carTop < obsBottom &&
          carBottom > obsTop) {
        return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Container(
          color: NunuColors.backgroundDefault,
          child: Stack(
            children: [
              // Road background with lane lines
              _buildRoad(),

              // Progress bar at top
              _buildProgressBar(),

              // Obstacles
              ..._obstacles.map((o) => _buildObstacle(o)),

              // Player car
              _buildCar(),

              // Control buttons at bottom
              _buildControls(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRoad() {
    return CustomPaint(
      size: _screenSize,
      painter: RoadPainter(distance: _distance),
    );
  }

  Widget _buildProgressBar() {
    final progress = (_distance / _targetDistance).clamp(0.0, 1.0);
    return Positioned(
      top: 20,
      left: 20,
      right: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_distance.toInt()} / ${_targetDistance.toInt()}',
            style: const TextStyle(
              color: NunuColors.primaryLight,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: NunuColors.primaryDark, width: 1),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progress,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        NunuColors.primaryMain,
                        NunuColors.secondaryMain,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: NunuColors.primaryMain.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildObstacle(Obstacle obstacle) {
    return Positioned(
      left: obstacle.x * _screenSize.width,
      top: obstacle.y,
      child: Container(
        width: obstacle.width * _screenSize.width,
        height: _obstacleHeight,
        decoration: BoxDecoration(
          color: NunuColors.secondaryDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NunuColors.secondaryMain, width: 2),
          boxShadow: [
            BoxShadow(
              color: NunuColors.secondaryMain.withValues(alpha: 0.6),
              blurRadius: 12,
              spreadRadius: 2,
            ),
          ],
        ),
        child: const Center(
          child: Icon(
            Icons.dangerous,
            color: NunuColors.secondaryLight,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildCar() {
    final carLeft = _carX * _screenSize.width;
    final carTop = _screenSize.height - 180 - _carHeight;

    return Positioned(
      left: carLeft,
      top: carTop,
      child: Container(
        width: _carWidth * _screenSize.width,
        height: _carHeight,
        decoration: BoxDecoration(
          color: NunuColors.primaryDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NunuColors.primaryMain, width: 3),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withValues(alpha: 0.7),
              blurRadius: 20,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.directions_car,
              color: NunuColors.primaryLight,
              size: 32,
            ),
            Container(
              width: 20,
              height: 4,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: NunuColors.primaryMain,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left button
          GestureDetector(
            onTapDown: (_) => _isPressingLeft = true,
            onTapUp: (_) => _isPressingLeft = false,
            onTapCancel: () => _isPressingLeft = false,
            child: _buildControlButton(
              icon: Icons.arrow_back,
              label: 'left',
              isPressed: _isPressingLeft,
            ),
          ),
          // Right button
          GestureDetector(
            onTapDown: (_) => _isPressingRight = true,
            onTapUp: (_) => _isPressingRight = false,
            onTapCancel: () => _isPressingRight = false,
            child: _buildControlButton(
              icon: Icons.arrow_forward,
              label: 'right',
              isPressed: _isPressingRight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: isPressed
            ? NunuColors.primaryMain.withValues(alpha: 0.3)
            : NunuColors.backgroundPaper.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPressed ? NunuColors.primaryMain : NunuColors.primaryDark,
          width: isPressed ? 3 : 2,
        ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: NunuColors.primaryMain.withValues(alpha: 0.5),
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isPressed ? NunuColors.primaryLight : NunuColors.primaryMain,
            size: 32,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isPressed
                  ? NunuColors.primaryLight
                  : NunuColors.primaryMain,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class RoadPainter extends CustomPainter {
  final double distance;

  RoadPainter({required this.distance});

  @override
  void paint(Canvas canvas, Size size) {
    // Road background
    final roadPaint = Paint()..color = const Color(0xFF1A1A2E);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), roadPaint);

    // Road edges
    final edgePaint = Paint()
      ..color = NunuColors.primaryDark
      ..strokeWidth = 4;

    canvas.drawLine(
      Offset(size.width * 0.05, 0),
      Offset(size.width * 0.05, size.height),
      edgePaint,
    );
    canvas.drawLine(
      Offset(size.width * 0.95, 0),
      Offset(size.width * 0.95, size.height),
      edgePaint,
    );

    // Lane dividers (animated dashes)
    final lanePaint = Paint()
      ..color = NunuColors.secondaryDark.withValues(alpha: 0.6)
      ..strokeWidth = 3;

    final dashHeight = 40.0;
    final gapHeight = 30.0;
    final totalHeight = dashHeight + gapHeight;
    final offset = (distance * 8) % totalHeight;

    // Draw 3 lane lines
    for (var lane = 1; lane <= 2; lane++) {
      final x = size.width * (0.05 + lane * 0.3);
      var y = -dashHeight + offset;

      while (y < size.height) {
        canvas.drawLine(Offset(x, y), Offset(x, y + dashHeight), lanePaint);
        y += totalHeight;
      }
    }
  }

  @override
  bool shouldRepaint(covariant RoadPainter oldDelegate) {
    return oldDelegate.distance != distance;
  }
}
