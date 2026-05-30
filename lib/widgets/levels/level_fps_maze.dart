import 'dart:async';
import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelFpsMaze extends LevelWidget {
  const LevelFpsMaze({super.key, required super.onComplete});

  @override
  State<LevelFpsMaze> createState() => _LevelFpsMazeState();
}

class _LevelFpsMazeState extends State<LevelFpsMaze>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Player state
  double _playerX = 1.5;
  double _playerY = 1.5;
  double _playerAngle = 0.0; // radians

  // Movement state
  bool _movingForward = false;
  bool _movingBackward = false;
  bool _turningLeft = false;
  bool _turningRight = false;
  bool _strafingLeft = false;
  bool _strafingRight = false;

  // Constants
  static const Duration _runLimit = Duration(minutes: 30);
  static const double _moveSpeed = 3.0; // cells per second
  static const double _turnSpeed = 2.5; // radians per second
  static const double _fov = pi / 3; // 60 degree field of view
  static const double _collisionRadius = 0.25;

  // Exit position
  late int _exitX;
  late int _exitY;

  bool _completed = false;
  DateTime _lastFrame = DateTime.now();
  Timer? _runTimer;
  late final int _startDistanceToExit;
  int? _bestDistanceToExit;

  // 15x15 maze (1 = wall, 0 = open, 2 = exit)
  // Hand-crafted to be navigable but not trivial
  final List<List<int>> _maze = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 1, 0, 1, 0, 1, 1, 1, 0, 1, 0, 1, 0, 1],
    [1, 0, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1],
    [1, 1, 1, 0, 1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 0, 1, 1, 1, 1, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 0, 1, 1, 1, 0, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 1],
    [1, 0, 1, 1, 1, 1, 1, 1, 1, 0, 1, 0, 1, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 2, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  @override
  void initState() {
    super.initState();
    widget.registerTimeoutBuilder(_buildTimeoutOutcome);

    // Find exit position
    for (int y = 0; y < _maze.length; y++) {
      for (int x = 0; x < _maze[y].length; x++) {
        if (_maze[y][x] == 2) {
          _exitX = x;
          _exitY = y;
        }
      }
    }
    _startDistanceToExit = max(
      1,
      _distanceToExit(_playerX.floor(), _playerY.floor()) ?? 1,
    );
    _bestDistanceToExit = _startDistanceToExit;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_gameLoop);
    _controller.repeat();
    _lastFrame = DateTime.now();
    _runTimer = Timer(_runLimit, _finishTimedOut);
  }

  @override
  void dispose() {
    _runTimer?.cancel();
    widget.clearTimeoutBuilder();
    _controller.dispose();
    super.dispose();
  }

  void _gameLoop() {
    if (_completed) return;

    final now = DateTime.now();
    final dt = (now.difference(_lastFrame).inMicroseconds) / 1000000.0;
    _lastFrame = now;

    // Clamp dt to avoid huge jumps
    final clampedDt = dt.clamp(0.0, 0.05);

    // Turning
    if (_turningLeft) {
      _playerAngle -= _turnSpeed * clampedDt;
    }
    if (_turningRight) {
      _playerAngle += _turnSpeed * clampedDt;
    }

    // Normalize angle
    _playerAngle = _playerAngle % (2 * pi);
    if (_playerAngle < 0) _playerAngle += 2 * pi;

    // Movement
    double dx = 0;
    double dy = 0;

    if (_movingForward) {
      dx += cos(_playerAngle) * _moveSpeed * clampedDt;
      dy += sin(_playerAngle) * _moveSpeed * clampedDt;
    }
    if (_movingBackward) {
      dx -= cos(_playerAngle) * _moveSpeed * clampedDt;
      dy -= sin(_playerAngle) * _moveSpeed * clampedDt;
    }
    if (_strafingLeft) {
      dx += cos(_playerAngle - pi / 2) * _moveSpeed * clampedDt;
      dy += sin(_playerAngle - pi / 2) * _moveSpeed * clampedDt;
    }
    if (_strafingRight) {
      dx += cos(_playerAngle + pi / 2) * _moveSpeed * clampedDt;
      dy += sin(_playerAngle + pi / 2) * _moveSpeed * clampedDt;
    }

    // Collision detection - try X and Y independently
    final newX = _playerX + dx;
    final newY = _playerY + dy;

    if (!_isWall(newX, _playerY)) {
      _playerX = newX;
    }
    if (!_isWall(_playerX, newY)) {
      _playerY = newY;
    }

    _recordProgress();

    // Check exit
    final playerGridX = _playerX.floor();
    final playerGridY = _playerY.floor();
    if (playerGridX == _exitX && playerGridY == _exitY && !_completed) {
      _completeMaze();
    }

    setState(() {});
  }

  void _recordProgress() {
    final distance = _distanceToExit(_playerX.floor(), _playerY.floor());
    if (distance == null) return;
    final best = _bestDistanceToExit;
    if (best == null || distance < best) {
      _bestDistanceToExit = distance;
    }
  }

  double _progressScore() {
    final best = _bestDistanceToExit ?? _startDistanceToExit;
    final progress = (_startDistanceToExit - best) / _startDistanceToExit;
    return progress.clamp(0.0, 0.95).toDouble();
  }

  Map<String, dynamic> _progressMetrics({
    required bool timedOut,
    bool gaveUp = false,
  }) {
    final currentDistance =
        _distanceToExit(_playerX.floor(), _playerY.floor()) ??
        _startDistanceToExit;
    final progressPct = (_progressScore() * 100).round();
    return {
      'timed_out': timedOut,
      'gave_up': gaveUp,
      'progress_pct': progressPct,
      'distance_remaining': currentDistance,
      'best_distance_remaining': _bestDistanceToExit ?? currentDistance,
    };
  }

  LevelOutcome _buildTimeoutOutcome() {
    return LevelOutcome(
      score: _progressScore(),
      metrics: _progressMetrics(timedOut: true),
      visibleMetricKeys: const ['progress_pct', 'distance_remaining'],
    );
  }

  void _completeMaze() {
    if (_completed) return;
    _completed = true;
    _runTimer?.cancel();
    _controller.stop();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.onComplete(
        LevelOutcome(
          score: 1,
          metrics: _progressMetrics(timedOut: false),
          visibleMetricKeys: const ['progress_pct', 'distance_remaining'],
        ),
      );
    });
  }

  void _finishTimedOut() {
    if (_completed) return;
    _completed = true;
    _controller.stop();
    widget.onComplete(_buildTimeoutOutcome());
  }

  void _finishGivenUp() {
    if (_completed) return;
    _completed = true;
    _runTimer?.cancel();
    _controller.stop();
    widget.onComplete(
      LevelOutcome(
        score: _progressScore(),
        metrics: _progressMetrics(timedOut: false, gaveUp: true),
        visibleMetricKeys: const ['progress_pct', 'distance_remaining'],
      ),
    );
  }

  bool _isWall(double x, double y) {
    // Check collision with a small radius around the player
    for (final offset in [
      Offset(x - _collisionRadius, y - _collisionRadius),
      Offset(x + _collisionRadius, y - _collisionRadius),
      Offset(x - _collisionRadius, y + _collisionRadius),
      Offset(x + _collisionRadius, y + _collisionRadius),
    ]) {
      final gx = offset.dx.floor();
      final gy = offset.dy.floor();
      if (gy < 0 || gy >= _maze.length || gx < 0 || gx >= _maze[0].length) {
        return true;
      }
      if (_maze[gy][gx] == 1) return true;
    }
    return false;
  }

  int? _distanceToExit(int startX, int startY) {
    if (startY < 0 ||
        startY >= _maze.length ||
        startX < 0 ||
        startX >= _maze[0].length ||
        _maze[startY][startX] == 1) {
      return null;
    }

    final visited = List.generate(
      _maze.length,
      (_) => List<bool>.filled(_maze[0].length, false),
    );
    final queue = <_MazeNode>[_MazeNode(startX, startY, 0)];
    visited[startY][startX] = true;

    const directions = [
      _GridStep(1, 0),
      _GridStep(-1, 0),
      _GridStep(0, 1),
      _GridStep(0, -1),
    ];

    for (var i = 0; i < queue.length; i++) {
      final node = queue[i];
      if (node.x == _exitX && node.y == _exitY) return node.distance;

      for (final direction in directions) {
        final nx = node.x + direction.dx;
        final ny = node.y + direction.dy;
        if (ny < 0 ||
            ny >= _maze.length ||
            nx < 0 ||
            nx >= _maze[0].length ||
            visited[ny][nx] ||
            _maze[ny][nx] == 1) {
          continue;
        }
        visited[ny][nx] = true;
        queue.add(_MazeNode(nx, ny, node.distance + 1));
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final viewportHeight = size.height * 0.65;

        return Container(
          color: NunuColors.backgroundDefault,
          child: Stack(
            children: [
              // 3D viewport
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: viewportHeight,
                child: ClipRect(
                  child: CustomPaint(
                    size: Size(size.width, viewportHeight),
                    painter: _RaycastPainter(
                      maze: _maze,
                      playerX: _playerX,
                      playerY: _playerY,
                      playerAngle: _playerAngle,
                      fov: _fov,
                      exitX: _exitX,
                      exitY: _exitY,
                    ),
                  ),
                ),
              ),

              // Minimap
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NunuColors.primaryMain.withValues(alpha: 0.5),
                      width: 1,
                    ),
                  ),
                  padding: const EdgeInsets.all(4),
                  child: CustomPaint(
                    size: const Size(100, 100),
                    painter: _MinimapPainter(
                      maze: _maze,
                      playerX: _playerX,
                      playerY: _playerY,
                      playerAngle: _playerAngle,
                      exitX: _exitX,
                      exitY: _exitY,
                    ),
                  ),
                ),
              ),
              Positioned(top: 12, left: 12, child: _buildGiveUpButton()),

              // Controls area
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: size.height - viewportHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper,
                    border: Border(
                      top: BorderSide(
                        color: NunuColors.primaryDark.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  child: _buildControls(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: movement d-pad
          _buildMovementPad(),
          // Right side: turn buttons
          _buildTurnPad(),
        ],
      ),
    );
  }

  Widget _buildGiveUpButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: NunuColors.errorMain.withValues(alpha: 0.55),
          width: 1,
        ),
      ),
      child: TextButton(
        onPressed: _finishGivenUp,
        style: TextButton.styleFrom(
          foregroundColor: NunuColors.errorMain,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text(
          'give up',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildMovementPad() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Forward
          Positioned(
            top: 0,
            child: _buildControlButton(
              icon: Icons.arrow_upward,
              label: 'fwd',
              onDown: () => setState(() => _movingForward = true),
              onUp: () => setState(() => _movingForward = false),
            ),
          ),
          // Backward
          Positioned(
            bottom: 0,
            child: _buildControlButton(
              icon: Icons.arrow_downward,
              label: 'back',
              onDown: () => setState(() => _movingBackward = true),
              onUp: () => setState(() => _movingBackward = false),
            ),
          ),
          // Strafe left
          Positioned(
            left: 0,
            child: _buildControlButton(
              icon: Icons.arrow_back,
              label: 'left',
              onDown: () => setState(() => _strafingLeft = true),
              onUp: () => setState(() => _strafingLeft = false),
            ),
          ),
          // Strafe right
          Positioned(
            right: 0,
            child: _buildControlButton(
              icon: Icons.arrow_forward,
              label: 'right',
              onDown: () => setState(() => _strafingRight = true),
              onUp: () => setState(() => _strafingRight = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnPad() {
    return SizedBox(
      width: 150,
      height: 150,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Turn left
          Positioned(
            left: 0,
            child: _buildControlButton(
              icon: Icons.rotate_left,
              label: 'turn L',
              onDown: () => setState(() => _turningLeft = true),
              onUp: () => setState(() => _turningLeft = false),
            ),
          ),
          // Turn right
          Positioned(
            right: 0,
            child: _buildControlButton(
              icon: Icons.rotate_right,
              label: 'turn R',
              onDown: () => setState(() => _turningRight = true),
              onUp: () => setState(() => _turningRight = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onDown,
    required VoidCallback onUp,
  }) {
    return GestureDetector(
      onTapDown: (_) => onDown(),
      onTapUp: (_) => onUp(),
      onTapCancel: onUp,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: NunuColors.primaryMain.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withValues(alpha: 0.15),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: NunuColors.primaryLight, size: 20),
            Text(
              label,
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MazeNode {
  final int x;
  final int y;
  final int distance;

  const _MazeNode(this.x, this.y, this.distance);
}

class _GridStep {
  final int dx;
  final int dy;

  const _GridStep(this.dx, this.dy);
}

// ---------- Raycasting Renderer ----------

class _RaycastPainter extends CustomPainter {
  final List<List<int>> maze;
  final double playerX;
  final double playerY;
  final double playerAngle;
  final double fov;
  final int exitX;
  final int exitY;

  _RaycastPainter({
    required this.maze,
    required this.playerX,
    required this.playerY,
    required this.playerAngle,
    required this.fov,
    required this.exitX,
    required this.exitY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.toInt();
    final height = size.height;
    final halfHeight = height / 2;

    // Draw ceiling
    final ceilingPaint = Paint();
    for (int y = 0; y < halfHeight.toInt(); y++) {
      final t = y / halfHeight;
      final color = Color.lerp(
        const Color(0xFF050510),
        const Color(0xFF1a1040),
        t,
      )!;
      ceilingPaint.color = color;
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(size.width, y.toDouble()),
        ceilingPaint,
      );
    }

    // Draw floor
    final floorPaint = Paint();
    for (int y = halfHeight.toInt(); y < height.toInt(); y++) {
      final t = (y - halfHeight) / halfHeight;
      final color = Color.lerp(
        const Color(0xFF1a0a20),
        const Color(0xFF0a0510),
        t,
      )!;
      floorPaint.color = color;
      canvas.drawLine(
        Offset(0, y.toDouble()),
        Offset(size.width, y.toDouble()),
        floorPaint,
      );
    }

    // Cast rays
    for (int x = 0; x < width; x++) {
      final rayAngle = playerAngle - fov / 2 + (x / width) * fov;

      final result = _castRay(rayAngle);
      final distance = result.distance;
      final wallType = result.wallType;
      final hitSide = result.hitSide;

      // Fisheye correction
      final correctedDist = distance * cos(rayAngle - playerAngle);

      // Wall height
      final wallHeight = (height / correctedDist).clamp(0.0, height * 2);

      final wallTop = halfHeight - wallHeight / 2;
      final wallBottom = halfHeight + wallHeight / 2;

      // Wall color based on type and side
      Color wallColor;
      if (wallType == 2) {
        // Exit wall - bright green
        wallColor = NunuColors.successMain;
      } else {
        // Regular walls - alternate colors for visual interest
        wallColor = hitSide == 0
            ? NunuColors.primaryDark
            : NunuColors.secondaryDark;
      }

      // Distance-based darkening
      final brightness = (1.0 / (1.0 + correctedDist * 0.15)).clamp(0.2, 1.0);
      wallColor = Color.lerp(Colors.black, wallColor, brightness)!;

      // Side shading (darker on one side for depth)
      if (hitSide == 1) {
        wallColor = Color.lerp(wallColor, Colors.black, 0.3)!;
      }

      final wallPaint = Paint()..color = wallColor;
      canvas.drawLine(
        Offset(x.toDouble(), wallTop),
        Offset(x.toDouble(), wallBottom),
        wallPaint,
      );

      // Scanline effect for cyberpunk feel
      if (x % 3 == 0) {
        final scanPaint = Paint()
          ..color = NunuColors.primaryMain.withValues(alpha: 0.02);
        canvas.drawLine(
          Offset(x.toDouble(), wallTop),
          Offset(x.toDouble(), wallBottom),
          scanPaint,
        );
      }
    }

    // Crosshair
    final crosshairPaint = Paint()
      ..color = NunuColors.primaryLight.withValues(alpha: 0.6)
      ..strokeWidth = 1.5;
    final cx = size.width / 2;
    final cy = halfHeight;
    canvas.drawLine(Offset(cx - 8, cy), Offset(cx - 3, cy), crosshairPaint);
    canvas.drawLine(Offset(cx + 3, cy), Offset(cx + 8, cy), crosshairPaint);
    canvas.drawLine(Offset(cx, cy - 8), Offset(cx, cy - 3), crosshairPaint);
    canvas.drawLine(Offset(cx, cy + 3), Offset(cx, cy + 8), crosshairPaint);
  }

  _RayResult _castRay(double angle) {
    final sinA = sin(angle);
    final cosA = cos(angle);

    // DDA algorithm
    final mapX = playerX.floor();
    final mapY = playerY.floor();

    final deltaDistX = cosA == 0 ? 1e30 : (1.0 / cosA).abs();
    final deltaDistY = sinA == 0 ? 1e30 : (1.0 / sinA).abs();

    int stepX;
    int stepY;
    double sideDistX;
    double sideDistY;

    if (cosA < 0) {
      stepX = -1;
      sideDistX = (playerX - mapX) * deltaDistX;
    } else {
      stepX = 1;
      sideDistX = (mapX + 1.0 - playerX) * deltaDistX;
    }

    if (sinA < 0) {
      stepY = -1;
      sideDistY = (playerY - mapY) * deltaDistY;
    } else {
      stepY = 1;
      sideDistY = (mapY + 1.0 - playerY) * deltaDistY;
    }

    int currentX = mapX;
    int currentY = mapY;
    int side = 0;
    double distance = 0;

    // Step through grid
    for (int i = 0; i < 64; i++) {
      if (sideDistX < sideDistY) {
        sideDistX += deltaDistX;
        currentX += stepX;
        side = 0;
      } else {
        sideDistY += deltaDistY;
        currentY += stepY;
        side = 1;
      }

      if (currentY < 0 ||
          currentY >= maze.length ||
          currentX < 0 ||
          currentX >= maze[0].length) {
        break;
      }

      if (maze[currentY][currentX] != 0) {
        // Hit a wall (or exit)
        if (side == 0) {
          distance = sideDistX - deltaDistX;
        } else {
          distance = sideDistY - deltaDistY;
        }
        return _RayResult(
          distance: distance.clamp(0.01, 100.0),
          wallType: maze[currentY][currentX],
          hitSide: side,
        );
      }
    }

    return _RayResult(distance: 100.0, wallType: 1, hitSide: 0);
  }

  @override
  bool shouldRepaint(_RaycastPainter oldDelegate) {
    return oldDelegate.playerX != playerX ||
        oldDelegate.playerY != playerY ||
        oldDelegate.playerAngle != playerAngle;
  }
}

class _RayResult {
  final double distance;
  final int wallType;
  final int hitSide;

  _RayResult({
    required this.distance,
    required this.wallType,
    required this.hitSide,
  });
}

// ---------- Minimap ----------

class _MinimapPainter extends CustomPainter {
  final List<List<int>> maze;
  final double playerX;
  final double playerY;
  final double playerAngle;
  final int exitX;
  final int exitY;

  _MinimapPainter({
    required this.maze,
    required this.playerX,
    required this.playerY,
    required this.playerAngle,
    required this.exitX,
    required this.exitY,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final mazeH = maze.length;
    final mazeW = maze[0].length;
    final cellW = size.width / mazeW;
    final cellH = size.height / mazeH;

    // Draw cells
    for (int y = 0; y < mazeH; y++) {
      for (int x = 0; x < mazeW; x++) {
        final rect = Rect.fromLTWH(x * cellW, y * cellH, cellW, cellH);

        Color color;
        if (maze[y][x] == 1) {
          color = NunuColors.primaryDark.withValues(alpha: 0.6);
        } else if (maze[y][x] == 2) {
          color = NunuColors.successMain;
        } else {
          color = Colors.transparent;
        }

        canvas.drawRect(rect, Paint()..color = color);
      }
    }

    // Draw player
    final px = playerX * cellW;
    final py = playerY * cellH;

    // Direction line
    final dirLen = cellW * 2;
    final dirX = px + cos(playerAngle) * dirLen;
    final dirY = py + sin(playerAngle) * dirLen;

    canvas.drawLine(
      Offset(px, py),
      Offset(dirX, dirY),
      Paint()
        ..color = NunuColors.primaryLight
        ..strokeWidth = 1.5,
    );

    // Player dot
    canvas.drawCircle(
      Offset(px, py),
      3,
      Paint()..color = NunuColors.primaryMain,
    );
  }

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) {
    return oldDelegate.playerX != playerX ||
        oldDelegate.playerY != playerY ||
        oldDelegate.playerAngle != playerAngle;
  }
}
