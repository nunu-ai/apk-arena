import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class Platform {
  final double x; // normalized 0.0-1.0
  final double y; // normalized 0.0-1.0 (0 = top, 1 = bottom)
  final double width; // normalized width

  Platform({required this.x, required this.y, required this.width});
}

class Enemy {
  double x; // normalized position
  final double y; // normalized position (on platform)
  final double minX; // patrol left bound
  final double maxX; // patrol right bound
  double direction; // 1 = right, -1 = left

  Enemy({
    required this.x,
    required this.y,
    required this.minX,
    required this.maxX,
    this.direction = 1,
  });
}

class LevelMarioPlatformer extends LevelWidget {
  const LevelMarioPlatformer({super.key, required super.onComplete});

  @override
  State<LevelMarioPlatformer> createState() => _LevelMarioPlatformerState();
}

class _LevelMarioPlatformerState extends State<LevelMarioPlatformer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Player state
  double _playerX = 0.08;
  double _playerY = 0.84; // Start on ground (ground at 0.92 - playerHeight 0.08)
  double _velocityX = 0;
  double _velocityY = 0;
  bool _isGrounded = true; // Start grounded

  // Controls
  bool _isPressingLeft = false;
  bool _isPressingRight = false;

  // Game state
  bool _gameOver = false;

  // Physics constants
  final double _gravity = 0.0010;
  final double _jumpVelocity = -0.032; // Higher jump
  final double _moveSpeed = 0.009;
  final double _terminalVelocity = 0.022;
  final double _friction = 0.85;

  // Player dimensions (normalized)
  final double _playerWidth = 0.08;
  final double _playerHeight = 0.08;

  // Platform height (normalized)
  final double _platformHeight = 0.025;

  // Flag position (on the final platform)
  final double _flagX = 0.88;
  final double _flagY = 0.18;

  // Platforms
  late List<Platform> _platforms;

  // Enemies
  late List<Enemy> _enemies;

  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initLevel();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_gameLoop);
    _controller.repeat();
  }

  void _initLevel() {
    // Create platforms - easier ascending staircase to the flag
    _platforms = [
      // Ground - full width
      Platform(x: 0, y: 0.92, width: 1.0),
      // Easy stepping platforms - wider and closer together
      Platform(x: 0.10, y: 0.78, width: 0.22),
      Platform(x: 0.38, y: 0.66, width: 0.22),
      Platform(x: 0.15, y: 0.52, width: 0.22),
      Platform(x: 0.45, y: 0.40, width: 0.25),
      Platform(x: 0.72, y: 0.30, width: 0.25), // Flag platform
    ];

    // Just one enemy on a middle platform
    _enemies = [
      Enemy(x: 0.48, y: 0.40 - 0.06, minX: 0.46, maxX: 0.66),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _gameLoop() {
    if (!mounted || _screenSize == Size.zero || _gameOver) return;

    setState(() {
      // Horizontal movement
      if (_isPressingLeft && !_isPressingRight) {
        _velocityX = -_moveSpeed;
      } else if (_isPressingRight && !_isPressingLeft) {
        _velocityX = _moveSpeed;
      } else {
        _velocityX *= _friction;
        if (_velocityX.abs() < 0.001) _velocityX = 0;
      }

      // Apply gravity
      if (!_isGrounded) {
        _velocityY += _gravity;
        if (_velocityY > _terminalVelocity) {
          _velocityY = _terminalVelocity;
        }
      }

      // Update position
      _playerX += _velocityX;
      _playerY += _velocityY;

      // Clamp horizontal position
      _playerX = _playerX.clamp(0.0, 1.0 - _playerWidth);

      // Platform collision
      _isGrounded = false;
      for (final platform in _platforms) {
        if (_checkPlatformCollision(platform)) {
          _playerY = platform.y - _playerHeight;
          _velocityY = 0;
          _isGrounded = true;
          break;
        }
      }

      // Update enemies
      for (final enemy in _enemies) {
        enemy.x += 0.002 * enemy.direction; // Slower patrol
        if (enemy.x <= enemy.minX || enemy.x >= enemy.maxX) {
          enemy.direction *= -1;
        }

        // Check enemy collision
        if (_checkEnemyCollision(enemy)) {
          _gameOver = true;
          _controller.stop();
          widget.onComplete(false);
          return;
        }
      }

      // Check fall off screen
      if (_playerY > 1.1) {
        _gameOver = true;
        _controller.stop();
        widget.onComplete(false);
        return;
      }

      // Check win condition (touch the flag)
      if (_checkFlagCollision()) {
        _gameOver = true;
        _controller.stop();
        widget.onComplete(true);
        return;
      }
    });
  }

  bool _checkPlatformCollision(Platform platform) {
    // Only collide when falling or standing still
    if (_velocityY < 0) return false;

    final playerBottom = _playerY + _playerHeight;
    final playerLeft = _playerX;
    final playerRight = _playerX + _playerWidth;

    final platformTop = platform.y;
    final platformBottom = platform.y + _platformHeight;
    final platformLeft = platform.x;
    final platformRight = platform.x + platform.width;

    // Check horizontal overlap
    final horizontalOverlap =
        playerRight > platformLeft && playerLeft < platformRight;

    if (!horizontalOverlap) return false;

    // Check if player is landing on platform (feet near platform top)
    final feetNearPlatform = playerBottom >= platformTop && 
        playerBottom <= platformBottom + 0.02;

    return feetNearPlatform;
  }

  bool _checkEnemyCollision(Enemy enemy) {
    const enemyWidth = 0.06;
    const enemyHeight = 0.06;

    final playerLeft = _playerX;
    final playerRight = _playerX + _playerWidth;
    final playerTop = _playerY;
    final playerBottom = _playerY + _playerHeight;

    final enemyLeft = enemy.x;
    final enemyRight = enemy.x + enemyWidth;
    final enemyTop = enemy.y;
    final enemyBottom = enemy.y + enemyHeight;

    return playerLeft < enemyRight &&
        playerRight > enemyLeft &&
        playerTop < enemyBottom &&
        playerBottom > enemyTop;
  }

  bool _checkFlagCollision() {
    const flagWidth = 0.06;
    const flagHeight = 0.12;

    final playerLeft = _playerX;
    final playerRight = _playerX + _playerWidth;
    final playerTop = _playerY;
    final playerBottom = _playerY + _playerHeight;

    final flagLeft = _flagX;
    final flagRight = _flagX + flagWidth;
    final flagTop = _flagY;
    final flagBottom = _flagY + flagHeight;

    return playerLeft < flagRight &&
        playerRight > flagLeft &&
        playerTop < flagBottom &&
        playerBottom > flagTop;
  }

  void _jump() {
    if (_isGrounded && !_gameOver) {
      setState(() {
        _velocityY = _jumpVelocity;
        _isGrounded = false;
      });
    }
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
              // Background decorations
              _buildBackground(),

              // Platforms
              ..._platforms.map((p) => _buildPlatform(p)),

              // Flag
              _buildFlag(),

              // Enemies
              ..._enemies.map((e) => _buildEnemy(e)),

              // Player
              _buildPlayer(),

              // Controls
              _buildControls(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return CustomPaint(
      size: _screenSize,
      painter: BackgroundPainter(),
    );
  }

  Widget _buildPlatform(Platform platform) {
    return Positioned(
      left: platform.x * _screenSize.width,
      top: platform.y * _screenSize.height,
      child: Container(
        width: platform.width * _screenSize.width,
        height: _platformHeight * _screenSize.height,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              NunuColors.secondaryMain,
              NunuColors.secondaryDark,
            ],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: NunuColors.secondaryLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: NunuColors.secondaryMain.withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFlag() {
    const flagWidth = 0.06;
    const flagHeight = 0.12;

    return Positioned(
      left: _flagX * _screenSize.width,
      top: _flagY * _screenSize.height,
      child: SizedBox(
        width: flagWidth * _screenSize.width,
        height: flagHeight * _screenSize.height,
        child: Stack(
          children: [
            // Pole
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 4,
                decoration: BoxDecoration(
                  color: NunuColors.textPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // Flag
            Positioned(
              left: 4,
              top: 0,
              child: Container(
                width: flagWidth * _screenSize.width - 8,
                height: flagHeight * _screenSize.height * 0.5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      NunuColors.successMain,
                      NunuColors.successDark,
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NunuColors.successMain.withValues(alpha: 0.6),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Center(
                  child: Icon(
                    Icons.flag,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnemy(Enemy enemy) {
    const enemyWidth = 0.06;
    const enemyHeight = 0.06;

    return Positioned(
      left: enemy.x * _screenSize.width,
      top: enemy.y * _screenSize.height,
      child: Container(
        width: enemyWidth * _screenSize.width,
        height: enemyHeight * _screenSize.height,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [
              NunuColors.errorLight,
              NunuColors.errorMain,
              NunuColors.errorDark,
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NunuColors.errorLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: NunuColors.errorMain.withValues(alpha: 0.6),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Transform.flip(
            flipX: enemy.direction < 0,
            child: const Icon(
              Icons.bug_report,
              color: Colors.white,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    return Positioned(
      left: _playerX * _screenSize.width,
      top: _playerY * _screenSize.height,
      child: Container(
        width: _playerWidth * _screenSize.width,
        height: _playerHeight * _screenSize.height,
        decoration: BoxDecoration(
          gradient: const RadialGradient(
            colors: [
              NunuColors.primaryLighter,
              NunuColors.primaryMain,
              NunuColors.primaryDark,
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NunuColors.primaryLight, width: 2),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withValues(alpha: 0.7),
              blurRadius: 15,
              spreadRadius: 3,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person,
              color: Colors.white,
              size: _playerHeight * _screenSize.height * 0.6,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 20,
      left: 16,
      right: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left/Right controls
          Row(
            children: [
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
              const SizedBox(width: 12),
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
          // Jump button
          GestureDetector(
            onTap: _jump,
            child: _buildJumpButton(),
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
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: isPressed
            ? NunuColors.primaryMain.withValues(alpha: 0.3)
            : NunuColors.backgroundPaper.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPressed ? NunuColors.primaryMain : NunuColors.primaryDark,
          width: isPressed ? 3 : 2,
        ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: NunuColors.primaryMain.withValues(alpha: 0.5),
                  blurRadius: 12,
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
            size: 28,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color:
                  isPressed ? NunuColors.primaryLight : NunuColors.primaryMain,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJumpButton() {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          colors: [
            NunuColors.successLight,
            NunuColors.successMain,
            NunuColors.successDark,
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: NunuColors.successLight, width: 3),
        boxShadow: [
          BoxShadow(
            color: NunuColors.successMain.withValues(alpha: 0.6),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.keyboard_arrow_up,
            color: Colors.white,
            size: 36,
          ),
          Text(
            'jump',
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class BackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradient background
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFF0D0D24),
        NunuColors.backgroundDefault,
        const Color(0xFF12102A),
      ],
    );
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawRect(rect, paint);

    // Draw some stars/dots for decoration
    final starPaint = Paint()
      ..color = NunuColors.primaryDark.withValues(alpha: 0.3);

    for (int i = 0; i < 30; i++) {
      final x = (i * 37) % size.width;
      final y = (i * 23) % (size.height * 0.6);
      final radius = (i % 3) + 1.0;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
