import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

/// A 3D first-person coin hunt.
/// Navigate an open arena and collect all gold coins by walking over them.
/// Uses raycasting + billboard sprite rendering with z-buffer clipping.
class LevelFpsCollector extends LevelWidget {
  const LevelFpsCollector({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelFpsCollector> createState() => _LevelFpsCollectorState();
}

class _Coin {
  final double x;
  final double y;
  bool collected = false;

  _Coin({required this.x, required this.y});
}

class _LevelFpsCollectorState extends State<LevelFpsCollector>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Player state
  double _playerX = 1.5;
  double _playerY = 1.5;
  double _playerAngle = 0.0;

  // Movement state
  bool _movingForward = false;
  bool _movingBackward = false;
  bool _turningLeft = false;
  bool _turningRight = false;
  bool _strafingLeft = false;
  bool _strafingRight = false;

  // Constants
  static const double _moveSpeed = 3.0;
  static const double _turnSpeed = 2.5;
  static const double _fov = pi / 3;
  static const double _collisionRadius = 0.25;
  static const double _collectRadius = 0.6;

  bool _completed = false;
  DateTime _lastFrame = DateTime.now();

  // Open arena with a few pillars -- easy to navigate without a minimap
  final List<List<int>> _maze = [
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 1, 0, 0, 0, 1, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
    [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
  ];

  // Coins scattered across the arena
  late final List<_Coin> _coins;

  int get _collectedCount => _coins.where((c) => c.collected).length;

  @override
  void initState() {
    super.initState();

    _coins = [
      // Corners
      _Coin(x: 1.5, y: 1.5),
      _Coin(x: 9.5, y: 1.5),
      _Coin(x: 1.5, y: 9.5),
      _Coin(x: 9.5, y: 9.5),
      // Edges
      _Coin(x: 5.5, y: 1.5),
      _Coin(x: 5.5, y: 9.5),
      _Coin(x: 1.5, y: 5.5),
      _Coin(x: 9.5, y: 5.5),
      // Near pillars
      _Coin(x: 4.5, y: 3.5),
      _Coin(x: 6.5, y: 7.5),
      // Center
      _Coin(x: 5.5, y: 5.5),
    ];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_gameLoop);
    _controller.repeat();
    _lastFrame = DateTime.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _gameLoop() {
    if (_completed) return;

    final now = DateTime.now();
    final dt = (now.difference(_lastFrame).inMicroseconds) / 1000000.0;
    _lastFrame = now;
    final clampedDt = dt.clamp(0.0, 0.05);

    // Turning
    if (_turningLeft) _playerAngle -= _turnSpeed * clampedDt;
    if (_turningRight) _playerAngle += _turnSpeed * clampedDt;
    _playerAngle = _playerAngle % (2 * pi);
    if (_playerAngle < 0) _playerAngle += 2 * pi;

    // Movement
    double dx = 0, dy = 0;
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

    final newX = _playerX + dx;
    final newY = _playerY + dy;
    if (!_isWall(newX, _playerY)) _playerX = newX;
    if (!_isWall(_playerX, newY)) _playerY = newY;

    // Check coin pickup
    for (final c in _coins) {
      if (c.collected) continue;
      final dist = sqrt(
        (c.x - _playerX) * (c.x - _playerX) +
            (c.y - _playerY) * (c.y - _playerY),
      );
      if (dist < _collectRadius) {
        c.collected = true;
      }
    }

    // Check completion
    if (_collectedCount == _coins.length && !_completed) {
      _completed = true;
      _controller.stop();
      Future.delayed(const Duration(milliseconds: 400), () {
        widget.onComplete(LevelOutcome(score: 1, metrics: {
          'coins': _coins.length,
        }));
      });
    }

    setState(() {});
  }

  bool _isWall(double x, double y) {
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);
        final viewportHeight = size.height * 0.60;

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
                    painter: _CollectorRaycastPainter(
                      maze: _maze,
                      playerX: _playerX,
                      playerY: _playerY,
                      playerAngle: _playerAngle,
                      fov: _fov,
                      coins: _coins,
                    ),
                  ),
                ),
              ),

              // HUD: collection counter
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NunuColors.infoMain.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.monetization_on,
                        color: _collectedCount == _coins.length
                            ? NunuColors.successMain
                            : const Color(0xFFFFD700),
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_collectedCount / ${_coins.length}',
                        style: TextStyle(
                          color: _collectedCount == _coins.length
                              ? NunuColors.successMain
                              : NunuColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Controls
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
                        color: NunuColors.infoDark.withValues(alpha: 0.3),
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
          _buildMovementPad(),
          _buildTurnPad(),
        ],
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
          Positioned(
            top: 0,
            child: _btn(Icons.arrow_upward, 'fwd',
                () => setState(() => _movingForward = true),
                () => setState(() => _movingForward = false)),
          ),
          Positioned(
            bottom: 0,
            child: _btn(Icons.arrow_downward, 'back',
                () => setState(() => _movingBackward = true),
                () => setState(() => _movingBackward = false)),
          ),
          Positioned(
            left: 0,
            child: _btn(Icons.arrow_back, 'left',
                () => setState(() => _strafingLeft = true),
                () => setState(() => _strafingLeft = false)),
          ),
          Positioned(
            right: 0,
            child: _btn(Icons.arrow_forward, 'right',
                () => setState(() => _strafingRight = true),
                () => setState(() => _strafingRight = false)),
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
          Positioned(
            left: 0,
            child: _btn(Icons.rotate_left, 'turn L',
                () => setState(() => _turningLeft = true),
                () => setState(() => _turningLeft = false)),
          ),
          Positioned(
            right: 0,
            child: _btn(Icons.rotate_right, 'turn R',
                () => setState(() => _turningRight = true),
                () => setState(() => _turningRight = false)),
          ),
        ],
      ),
    );
  }

  Widget _btn(
      IconData icon, String label, VoidCallback onDown, VoidCallback onUp) {
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
            color: NunuColors.infoMain.withValues(alpha: 0.5),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: NunuColors.infoMain.withValues(alpha: 0.12),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: NunuColors.infoLight, size: 20),
            Text(label,
                style: const TextStyle(
                    color: NunuColors.textSecondary, fontSize: 8)),
          ],
        ),
      ),
    );
  }
}

// ---------- Raycasting + Sprite Renderer ----------

class _CollectorRaycastPainter extends CustomPainter {
  final List<List<int>> maze;
  final double playerX, playerY, playerAngle, fov;
  final List<_Coin> coins;

  _CollectorRaycastPainter({
    required this.maze,
    required this.playerX,
    required this.playerY,
    required this.playerAngle,
    required this.fov,
    required this.coins,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width.toInt();
    final height = size.height;
    final halfHeight = height / 2;

    // Z-buffer for sprite clipping
    final zBuffer = List<double>.filled(width, 100.0);

    // -- Ceiling gradient (dark blue/teal tones) --
    final ceilPaint = Paint();
    for (int y = 0; y < halfHeight.toInt(); y++) {
      final t = y / halfHeight;
      ceilPaint.color =
          Color.lerp(const Color(0xFF020814), const Color(0xFF0a1a2a), t)!;
      canvas.drawLine(
          Offset(0, y.toDouble()), Offset(size.width, y.toDouble()), ceilPaint);
    }

    // -- Floor gradient (dark teal) --
    final floorPaint = Paint();
    for (int y = halfHeight.toInt(); y < height.toInt(); y++) {
      final t = (y - halfHeight) / halfHeight;
      floorPaint.color =
          Color.lerp(const Color(0xFF0a1520), const Color(0xFF040a10), t)!;
      canvas.drawLine(Offset(0, y.toDouble()),
          Offset(size.width, y.toDouble()), floorPaint);
    }

    // -- Grid lines on floor for depth perception --
    _drawFloorGrid(canvas, size, halfHeight);

    // -- Cast rays and fill z-buffer --
    for (int x = 0; x < width; x++) {
      final rayAngle = playerAngle - fov / 2 + (x / width) * fov;
      final result = _castRay(rayAngle);
      final correctedDist = result.distance * cos(rayAngle - playerAngle);
      zBuffer[x] = correctedDist;

      final wallHeight = (height / correctedDist).clamp(0.0, height * 2);
      final wallTop = halfHeight - wallHeight / 2;
      final wallBottom = halfHeight + wallHeight / 2;

      // Teal/blue wall palette
      Color wallColor = result.hitSide == 0
          ? const Color(0xFF1a3a4a)
          : const Color(0xFF102a38);

      final brightness =
          (1.0 / (1.0 + correctedDist * 0.12)).clamp(0.15, 1.0);
      wallColor = Color.lerp(Colors.black, wallColor, brightness)!;

      canvas.drawLine(Offset(x.toDouble(), wallTop),
          Offset(x.toDouble(), wallBottom), Paint()..color = wallColor);

      // Subtle edge highlight on wall tops
      if (wallTop > 0) {
        canvas.drawLine(
          Offset(x.toDouble(), wallTop),
          Offset(x.toDouble(), wallTop + 1),
          Paint()
            ..color = NunuColors.infoMain
                .withValues(alpha: (0.15 * brightness).clamp(0.0, 0.15)),
        );
      }
    }

    // -- Render collectible sprites --
    _renderSprites(canvas, size, halfHeight, zBuffer);

    // -- Crosshair --
    final chPaint = Paint()
      ..color = NunuColors.infoLight.withValues(alpha: 0.5)
      ..strokeWidth = 1.5;
    final cx = size.width / 2;
    final cy = halfHeight;
    canvas.drawLine(Offset(cx - 10, cy), Offset(cx - 4, cy), chPaint);
    canvas.drawLine(Offset(cx + 4, cy), Offset(cx + 10, cy), chPaint);
    canvas.drawLine(Offset(cx, cy - 10), Offset(cx, cy - 4), chPaint);
    canvas.drawLine(Offset(cx, cy + 4), Offset(cx, cy + 10), chPaint);
  }

  void _drawFloorGrid(Canvas canvas, Size size, double halfHeight) {
    // Draw perspective grid lines on the floor for a TRON-like feel
    final gridPaint = Paint()
      ..color = NunuColors.infoMain.withValues(alpha: 0.06)
      ..strokeWidth = 1;

    // Horizontal lines
    for (int i = 1; i <= 12; i++) {
      final t = i / 12.0;
      final y = halfHeight + (halfHeight * t);
      if (y < size.height) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      }
    }
  }

  static const _coinGold = Color(0xFFFFD700);
  static const _coinLight = Color(0xFFFFF0A0);
  static const _coinDark = Color(0xFFB8860B);

  void _renderSprites(
      Canvas canvas, Size size, double halfHeight, List<double> zBuffer) {
    final width = size.width.toInt();

    final visible = <_SpriteRender>[];

    for (final c in coins) {
      if (c.collected) continue;

      final relX = c.x - playerX;
      final relY = c.y - playerY;
      final dist = sqrt(relX * relX + relY * relY);
      if (dist < 0.1) continue;

      // Angle from player to coin
      final spriteAngle = atan2(relY, relX);

      // Angle relative to player view -- same space the raycaster uses
      var angleDiff = spriteAngle - playerAngle;
      while (angleDiff > pi) angleDiff -= 2 * pi;
      while (angleDiff < -pi) angleDiff += 2 * pi;

      // Outside FOV
      if (angleDiff.abs() > fov / 2 + 0.05) continue;

      // Map angle to screen column (exact inverse of the raycaster formula)
      final screenX = ((angleDiff + fov / 2) / fov) * size.width;

      // Perpendicular distance (same fisheye correction as walls)
      final perpDist = dist * cos(angleDiff);

      final spriteSize = (size.height / perpDist).clamp(8.0, size.height);

      visible.add(_SpriteRender(
        coin: c,
        distance: perpDist,
        screenX: screenX,
        spriteSize: spriteSize,
      ));
    }

    // Farthest first so closer coins paint on top
    visible.sort((a, b) => b.distance.compareTo(a.distance));

    for (final sprite in visible) {
      final halfSprite = sprite.spriteSize / 2;
      final screenY = halfHeight + sprite.spriteSize * 0.15;

      // Z-buffer visibility check
      final startCol =
          (sprite.screenX - halfSprite * 0.3).round().clamp(0, width - 1);
      final endCol =
          (sprite.screenX + halfSprite * 0.3).round().clamp(0, width - 1);

      bool anyVisible = false;
      for (int col = startCol; col <= endCol; col++) {
        if (sprite.distance < zBuffer[col]) {
          anyVisible = true;
          break;
        }
      }
      if (!anyVisible) continue;

      final radius = (sprite.spriteSize * 0.12).clamp(3.0, 22.0);
      final center = Offset(sprite.screenX, screenY);
      final alpha = (1.0 / (1.0 + sprite.distance * 0.08)).clamp(0.3, 1.0);

      // Gold glow on floor
      canvas.drawCircle(
        center,
        radius * 2.2,
        Paint()
          ..color = _coinGold.withValues(alpha: 0.10 * alpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );

      // Coin body (slightly tall oval to suggest a disc seen at an angle)
      final coinRect = Rect.fromCenter(
        center: center,
        width: radius * 2,
        height: radius * 2.4,
      );
      canvas.drawOval(
        coinRect,
        Paint()..color = _coinGold.withValues(alpha: alpha),
      );

      // Dark edge for depth
      canvas.drawOval(
        coinRect,
        Paint()
          ..color = _coinDark.withValues(alpha: 0.5 * alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );

      // Highlight on upper half
      final highlightRect = Rect.fromCenter(
        center: Offset(center.dx - radius * 0.15, center.dy - radius * 0.3),
        width: radius * 1.0,
        height: radius * 1.2,
      );
      canvas.drawOval(
        highlightRect,
        Paint()..color = _coinLight.withValues(alpha: 0.5 * alpha),
      );
    }
  }

  _RayResult _castRay(double angle) {
    final sinA = sin(angle);
    final cosA = cos(angle);
    final mapX = playerX.floor();
    final mapY = playerY.floor();

    final deltaDistX = cosA == 0 ? 1e30 : (1.0 / cosA).abs();
    final deltaDistY = sinA == 0 ? 1e30 : (1.0 / sinA).abs();

    int stepX, stepY;
    double sideDistX, sideDistY;

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

    int currentX = mapX, currentY = mapY;
    int side = 0;

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
          currentX >= maze[0].length) break;

      if (maze[currentY][currentX] == 1) {
        final dist =
            side == 0 ? sideDistX - deltaDistX : sideDistY - deltaDistY;
        return _RayResult(
          distance: dist.clamp(0.01, 100.0),
          hitSide: side,
        );
      }
    }
    return _RayResult(distance: 100.0, hitSide: 0);
  }

  @override
  bool shouldRepaint(covariant _CollectorRaycastPainter oldDelegate) => true;
}

class _RayResult {
  final double distance;
  final int hitSide;
  _RayResult({required this.distance, required this.hitSide});
}

class _SpriteRender {
  final _Coin coin;
  final double distance;
  final double screenX;
  final double spriteSize;
  _SpriteRender({
    required this.coin,
    required this.distance,
    required this.screenX,
    required this.spriteSize,
  });
}

