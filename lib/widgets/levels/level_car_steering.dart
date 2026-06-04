import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import 'dart:math';

class Obstacle {
  double x; // 0.0 to 1.0 normalized horizontal position
  double y; // vertical position in pixels (starts negative, scrolls down)
  double width; // width as fraction of screen width
  final double speed; // pixels per frame

  Obstacle({
    required this.x,
    required this.y,
    required this.width,
    required this.speed,
  });
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
  final Stopwatch _survivalTimer = Stopwatch();
  final List<Obstacle> _obstacles = [];
  bool _isPressingLeft = false;
  bool _isPressingRight = false;
  bool _hasStarted = false;
  bool _gameOver = false;
  int _currentAttempt = 1;
  int _wavesSpawned = 0;
  double _bestScore = 0;
  int _bestSurvivalSeconds = 0;
  int _bestDistance = 0;
  double _bestDifficulty = 0;

  // Game parameters
  final double _carSpeed = 0.018; // lateral movement per frame
  double _framesSinceLastSpawn = double.infinity;
  final double _carWidth = 0.10; // as fraction of screen width
  final double _carHeight = 50;
  final double _obstacleHeight = 60;
  final double _initialObstaclePeekRatio = 0.32;
  static const int _maxAttempts = 3;
  static const Duration _fullScoreSurvivalTime = Duration(minutes: 10);
  static const double _framesPerSecond = 60;
  static const double _startingReactionSeconds = 34;
  static const double _minimumReactionSeconds = 0.5;
  static final double _reactionCurveDecay =
      log(_startingReactionSeconds / _minimumReactionSeconds) / 95;

  Size _screenSize = Size.zero;

  double get _survivalSeconds =>
      _survivalTimer.elapsedMilliseconds / Duration.millisecondsPerSecond;

  double get _difficulty {
    final ramp = _survivalSeconds / _fullScoreSurvivalTime.inSeconds;
    return ramp.clamp(0.0, 1.0);
  }

  double get _obstacleSpeed {
    return _speedForWave(max(0, _wavesSpawned - 1));
  }

  double get _spawnInterval {
    final previousWaveIndex = max(0, _wavesSpawned - 1);
    return _clearanceFramesForWave(previousWaveIndex);
  }

  double _reactionSecondsForWave(int waveIndex) {
    final seconds =
        _startingReactionSeconds * exp(-_reactionCurveDecay * waveIndex);
    return max(_minimumReactionSeconds, seconds);
  }

  double _speedForWave(int waveIndex) {
    final carTop = _screenSize.height - 180 - _carHeight;
    final travelDistance = max(1.0, carTop + _obstacleHeight);
    return travelDistance /
        (_reactionSecondsForWave(waveIndex) * _framesPerSecond);
  }

  double _clearanceFramesForWave(int waveIndex) {
    final carTop = _screenSize.height - 180 - _carHeight;
    final carBottom = carTop + _carHeight;
    final clearDistance = max(1.0, carBottom + _obstacleHeight);
    return clearDistance / _speedForWave(waveIndex);
  }

  double _roundDifficulty(double value) =>
      double.parse(value.toStringAsFixed(2));

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: _bestScore.clamp(0.0, 1.0)));
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_gameLoop);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _gameLoop() {
    if (!mounted || !_hasStarted || _screenSize == Size.zero || _gameOver) {
      return;
    }

    setState(() {
      // Move car based on button presses
      if (_isPressingLeft && !_isPressingRight) {
        _carX = (_carX - _carSpeed).clamp(0.0, 1.0 - _carWidth);
      } else if (_isPressingRight && !_isPressingLeft) {
        _carX = (_carX + _carSpeed).clamp(0.0, 1.0 - _carWidth);
      }

      // Move obstacles down
      for (var obstacle in _obstacles) {
        obstacle.y += obstacle.speed;
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
        _finishAttempt();
        return;
      }

      // Increment distance
      _distance += _obstacleSpeed / 30;
    });
  }

  void _startGame() {
    if (_hasStarted || _gameOver) return;

    setState(() {
      _hasStarted = true;
      _survivalTimer
        ..reset()
        ..start();
      _controller.repeat();
    });
  }

  void _finishAttempt() {
    _survivalTimer.stop();
    _controller.stop();

    final score = _difficulty;
    final survivalSeconds = _survivalSeconds.round();
    final distance = _distance.round();
    if (score > _bestScore) {
      _bestScore = score;
      _bestSurvivalSeconds = survivalSeconds;
      _bestDistance = distance;
      _bestDifficulty = score;
    }

    if (_currentAttempt >= _maxAttempts) {
      _gameOver = true;
      _controller.stop();
      widget.onComplete(
        LevelOutcome(
          score: _bestScore,
          metrics: {
            'attempts': _maxAttempts,
            'survival_seconds': _bestSurvivalSeconds,
            'distance': _bestDistance,
            'difficulty': _roundDifficulty(_bestDifficulty),
          },
        ),
      );
      return;
    }

    _currentAttempt++;
    _wavesSpawned = 0;
    _carX = 0.5;
    _distance = 0;
    _hasStarted = false;
    _framesSinceLastSpawn = double.infinity;
    _obstacles.clear();
    _isPressingLeft = false;
    _isPressingRight = false;
    _survivalTimer
      ..reset()
      ..stop();
  }

  void _spawnObstacle() {
    final waveIndex = _wavesSpawned;
    final waveSpeed = _speedForWave(waveIndex);
    _wavesSpawned++;

    final difficulty = _difficulty;
    final density = difficulty;
    final usedPositions = <double>[];

    double obstacleWidth() =>
        0.08 + _random.nextDouble() * (0.05 + difficulty * 0.07);

    void addObstacle(double x, double width) {
      final clampedX = x.clamp(0.0, 1.0 - width).toDouble();
      usedPositions.add(clampedX);
      _obstacles.add(
        Obstacle(
          x: clampedX,
          y: -_obstacleHeight * (1 - _initialObstaclePeekRatio),
          width: width,
          speed: waveSpeed,
        ),
      );
    }

    final obstacleCount =
        3 +
        (density * 10).floor() +
        (_random.nextDouble() < density * 1.5 ? 1 : 0) +
        (_random.nextDouble() < density * 0.75 ? 1 : 0);
    final minGap = (0.33 - density * 0.25).clamp(0.08, 0.33);

    final blockingWidth = obstacleWidth();
    addObstacle(_carX + (_carWidth - blockingWidth) / 2, blockingWidth);

    final anchorPositions = <double>[0.02, 0.18, 0.34, 0.50, 0.66, 0.82];
    for (var i = 1; i < 3; i++) {
      anchorPositions.sort((a, b) {
        final aDistance = usedPositions
            .map((pos) => (pos - a).abs())
            .reduce(min);
        final bDistance = usedPositions
            .map((pos) => (pos - b).abs())
            .reduce(min);
        return bDistance.compareTo(aDistance);
      });
      addObstacle(anchorPositions.removeAt(0), obstacleWidth());
    }

    for (var i = 3; i < obstacleCount; i++) {
      double x;
      int attempts = 0;
      do {
        x = _random.nextDouble() * 0.85; // leave room for obstacle width
        attempts++;
      } while (usedPositions.any((pos) => (pos - x).abs() < minGap) &&
          attempts < 18);

      if (attempts < 18) {
        addObstacle(x, obstacleWidth());
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
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          _buildHud(),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                _screenSize = Size(constraints.maxWidth, constraints.maxHeight);

                return Stack(
                  children: [
                    _buildRoad(),
                    ..._obstacles.map((o) => _buildObstacle(o)),
                    _buildCar(),
                    _buildControls(),
                    if (!_hasStarted) _buildStartOverlay(),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoad() {
    return CustomPaint(
      size: _screenSize,
      painter: RoadPainter(distance: _distance),
    );
  }

  Widget _buildHud() {
    final elapsed = _survivalTimer.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');

    return LevelHud(
      stageText: '$_currentAttempt/$_maxAttempts',
      timerText: '$minutes:$seconds',
      trailing: Text(
        'distance ${_distance.toInt()} · best $_bestDistance',
        style: const TextStyle(
          color: NunuColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
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
            Icons.directions_car_filled,
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

  Widget _buildStartOverlay() {
    return Positioned.fill(
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: NunuColors.primaryMain, width: 2),
            boxShadow: [
              BoxShadow(
                color: NunuColors.primaryMain.withValues(alpha: 0.4),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'ready?',
                style: TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 14,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NunuColors.primaryMain,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 56,
                    vertical: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 8,
                ),
                child: const Text(
                  'GO',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'traffic ramps up',
                style: TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
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
