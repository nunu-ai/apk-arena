import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class Platform {
  double x;
  final double y;
  final double width;
  final int altitude;
  final double speed;
  final double minX;
  final double maxX;
  double direction;
  double prevX;
  /// Doodle-jump style: breaks on contact; does not support the player.
  final bool brittle;

  Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.altitude,
    this.speed = 0,
    double? minX,
    double? maxX,
    this.direction = 1,
    this.brittle = false,
  })  : minX = minX ?? 0.05,
        maxX = maxX ?? 0.95 - width,
        prevX = x;

  void capturePrev() {
    prevX = x;
  }

  double get deltaX => x - prevX;
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
  double _playerY = 0.84;
  double _velocityX = 0;
  double _velocityY = 0;
  bool _isGrounded = true;

  // Controls
  bool _isPressingLeft = false;
  bool _isPressingRight = false;
  bool _isChargingJump = false;
  DateTime? _jumpChargeStart;
  double _jumpChargePercent = 0.0;

  // Game state
  bool _sessionEnded = false;
  double _cameraY = 0;
  int _altitude = 0;
  int _bestAltitude = 0;
  int _lives = 3;
  int _highestSpawnedAltitude = 0;
  Timer? _sessionTimer;
  /// Horizontal center (0–1) of the last spawned row; used after lower platforms are culled.
  double _prevSpawnCenter = 0.5;
  /// Solid platform the player last stood on (launch anchor for jump grace).
  Platform? _lastGroundedPlatform;
  /// Preserved until solid landing or fall below the launch platform.
  Platform? _jumpStartPlatform;
  final Random _rng = Random();

  // Physics constants
  final double _gravity = 0.0010;
  final double _jumpVelocity = -0.032;
  final double _moveSpeed = 0.009;
  final double _terminalVelocity = 0.022;
  final double _friction = 0.85;

  final double _playerWidth = 0.08;
  final double _playerHeight = 0.08;

  final double _platformHeight = 0.025;
  static const double _groundY = 0.92;
  static const double _verticalSpacing = 0.14;
  static const int _winAltitude = 200;
  static const int _spawnBufferAhead = 36;
  static const double _cameraFollowLerp = 0.12;
  static const double _playerViewportY = 0.58;
  /// Screen-space Y (playerY - cameraY) above this = fell off the bottom.
  static const double _fallDeathScreenY = 1.02;
  /// How far below the launch platform's bottom before a protected fall counts as death.
  static const double _fallPastStartPlatformMargin = 0.06;
  /// Keep launch platform on screen: (platformY - cameraY) must stay at or below this.
  static const double _jumpStartPlatformMaxScreenY = 0.95;
  static const int _startingLives = 3;
  static const Duration _sessionDuration = Duration(minutes: 30);

  List<Platform> _platforms = [];

  Size _screenSize = Size.zero;

  @override
  void initState() {
    super.initState();
    _initSession();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_gameLoop);
    _controller.repeat();
    _sessionTimer = Timer(_sessionDuration, _onSessionTimeUp);
  }

  void _initSession() {
    _sessionEnded = false;
    _lives = _startingLives;
    _bestAltitude = 0;
    _startRun();
  }

  /// Fresh climb from the ground (one life).
  void _startRun() {
    _platforms = [
      Platform(
        x: 0,
        y: _groundY,
        width: 1.0,
        altitude: 0,
        speed: 0,
        minX: 0,
        maxX: 0,
        brittle: false,
      ),
    ];
    _highestSpawnedAltitude = 0;
    _prevSpawnCenter = 0.5;
    _altitude = 0;
    _cameraY = 0;
    _playerX = 0.08;
    _playerY = _groundY - _playerHeight;
    _velocityX = 0;
    _velocityY = 0;
    _isGrounded = true;
    _isChargingJump = false;
    _jumpChargeStart = null;
    _jumpChargePercent = 0.0;
    _jumpStartPlatform = null;
    _lastGroundedPlatform = _platforms.first;
    _ensurePlatformsAbove();
  }

  void _recordBestAltitude() {
    if (_altitude > _bestAltitude) {
      _bestAltitude = _altitude;
    }
  }

  void _onSessionTimeUp() {
    if (_sessionEnded || !mounted) return;
    _recordBestAltitude();
    _finishSession();
  }

  void _finishSession({bool perfectWin = false}) {
    if (_sessionEnded) return;
    _sessionEnded = true;
    _sessionTimer?.cancel();
    _controller.stop();

    final score = perfectWin
        ? 1.0
        : (_bestAltitude / _winAltitude).clamp(0.0, 1.0);
    final bestAlt = perfectWin ? _winAltitude : _bestAltitude;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onComplete(
        LevelOutcome(
          score: score,
          metrics: {
            'altitude': bestAlt,
            'lives_used': _startingLives - _lives,
          },
          visibleMetricKeys: const {'altitude'},
        ),
      );
    });
  }

  double _worldYForAltitude(int a) {
    return _groundY - a * _verticalSpacing;
  }

  void _spawnPlatformAtAltitude(int a) {
    if (a <= 0) return;

    final y = _worldYForAltitude(a);
    final prevCenter = _prevSpawnCenter;

    double width;
    double moveChance;
    double spd;
    if (a < 20) {
      width = 0.22;
      moveChance = 0;
      spd = 0;
    } else if (a < 50) {
      width = 0.20;
      moveChance = 0.4;
      spd = 0.0015;
    } else if (a < 80) {
      width = 0.16;
      moveChance = 0.7;
      spd = 0.0025;
    } else {
      width = 0.12;
      moveChance = 0.95;
      spd = 0.0035;
    }

    final speedRamp = 1.0 + (a / 250.0).clamp(0.0, 8.0);
    spd *= speedRamp;

    final brittleChance = a < 6 ? 0.0 : (0.06 + a / 2500.0).clamp(0.06, 0.32);
    final brittle = _rng.nextDouble() < brittleChance;

    final bool moving = !brittle && _rng.nextDouble() < moveChance && spd > 0;
    const double minPatrol = 0.05;
    final double patrolMaxLeft = 1.0 - width - 0.05;

    const double maxStep = 0.14;
    final double minCx = minPatrol + width / 2;
    final double maxCx = patrolMaxLeft + width / 2;
    final double drift = (_rng.nextDouble() * 2 - 1) * maxStep;
    final double towardCenter = (0.5 - prevCenter) * 0.12;
    final double cx = (prevCenter + drift + towardCenter).clamp(minCx, maxCx);
    final double left = cx - width / 2;

    _platforms.add(
      Platform(
        x: left,
        y: y,
        width: width,
        altitude: a,
        speed: moving ? spd : 0,
        minX: minPatrol,
        maxX: patrolMaxLeft,
        direction: 1,
        brittle: brittle,
      ),
    );
    _prevSpawnCenter = left + width / 2;
    _highestSpawnedAltitude = a;
  }

  void _ensurePlatformsAbove() {
    final target = min(
      _winAltitude + _spawnBufferAhead,
      max(
        _highestSpawnedAltitude,
        _altitude + _spawnBufferAhead,
      ),
    );
    while (_highestSpawnedAltitude < target) {
      _spawnPlatformAtAltitude(_highestSpawnedAltitude + 1);
    }
  }

  /// Remove rows that have scrolled below the viewport so there is open air to fall through.
  static const double _cullBelowViewport = 1.06;

  void _cullPlatformsBelowViewport() {
    _platforms.removeWhere((p) {
      if (identical(p, _jumpStartPlatform)) return false;
      return (p.y - _cameraY) > _cullBelowViewport;
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _gameLoop() {
    if (!mounted || _screenSize == Size.zero || _sessionEnded) return;

    var endSession = false;
    var perfectWin = false;

    setState(() {
      for (final p in _platforms) {
        p.capturePrev();
      }

      for (final p in _platforms) {
        if (p.speed <= 0) continue;
        p.x += p.speed * p.direction;
        if (p.x < p.minX) {
          p.x = p.minX;
          p.direction = 1;
        } else if (p.x > p.maxX) {
          p.x = p.maxX;
          p.direction = -1;
        }

      }

      if (_isChargingJump && _jumpChargeStart != null) {
        final chargeDuration =
            DateTime.now().difference(_jumpChargeStart!).inMilliseconds;
        _jumpChargePercent = (chargeDuration / 500.0).clamp(0.0, 1.0);
      }

      if (_isPressingLeft && !_isPressingRight) {
        _velocityX = -_moveSpeed;
      } else if (_isPressingRight && !_isPressingLeft) {
        _velocityX = _moveSpeed;
      } else {
        _velocityX *= _friction;
        if (_velocityX.abs() < 0.001) _velocityX = 0;
      }

      if (!_isGrounded) {
        _velocityY += _gravity;
        if (_velocityY > _terminalVelocity) {
          _velocityY = _terminalVelocity;
        }
      }

      _playerX += _velocityX;
      _playerY += _velocityY;

      _playerX = _playerX.clamp(0.0, 1.0 - _playerWidth);

      _isGrounded = false;
      Platform? landed;

      for (final platform in _platforms) {
        if (_checkPlatformCollision(platform)) {
          if (landed == null || platform.y < landed.y) {
            landed = platform;
          }
        }
      }

      if (landed != null) {
        if (landed.brittle) {
          _platforms.remove(landed);
          _isGrounded = false;
          if (_velocityY < 0.012) {
            _velocityY = 0.012;
          }
        } else {
          _playerY = landed.y - _playerHeight;
          _velocityY = 0;
          _isGrounded = true;
          _playerX += landed.deltaX;
          _playerX = _playerX.clamp(0.0, 1.0 - _playerWidth);

          _lastGroundedPlatform = landed;
          _jumpStartPlatform = null;

          if (landed.altitude > _altitude) {
            _altitude = landed.altitude;
            _ensurePlatformsAbove();
          }
        }
      }

      final targetCam = _playerY - _playerViewportY;
      // Only scroll up while climbing; falling leaves the camera fixed so you can drop off-screen.
      if (targetCam < _cameraY) {
        _cameraY += (targetCam - _cameraY) * _cameraFollowLerp;
      }

      if (_jumpStartPlatform != null) {
        final maxCamY =
            _jumpStartPlatform!.y - _jumpStartPlatformMaxScreenY;
        if (_cameraY < maxCamY) {
          _cameraY = maxCamY;
        }
      }

      final startPlatform = _jumpStartPlatform;
      final fellOff = startPlatform != null
          ? _playerY >
              startPlatform.y +
                  _platformHeight +
                  _fallPastStartPlatformMargin
          : _playerY - _cameraY > _fallDeathScreenY;

      if (fellOff) {
        _jumpStartPlatform = null;
        _recordBestAltitude();
        _lives--;
        if (_lives <= 0) {
          endSession = true;
          return;
        }
        _startRun();
        return;
      }

      _cullPlatformsBelowViewport();

      if (_altitude >= _winAltitude) {
        _bestAltitude = _winAltitude;
        endSession = true;
        perfectWin = true;
      }
    });

    if (endSession) {
      _finishSession(perfectWin: perfectWin);
    }
  }

  bool _checkPlatformCollision(Platform platform) {
    if (_velocityY < 0) return false;

    final playerBottom = _playerY + _playerHeight;
    final playerLeft = _playerX;
    final playerRight = _playerX + _playerWidth;

    final platformTop = platform.y;
    final platformBottom = platform.y + _platformHeight;
    final platformLeft = platform.x;
    final platformRight = platform.x + platform.width;

    final horizontalOverlap =
        playerRight > platformLeft && playerLeft < platformRight;
    if (!horizontalOverlap) return false;

    final feetNearPlatform = playerBottom >= platformTop &&
        playerBottom <= platformBottom + 0.02;

    return feetNearPlatform;
  }

  void _onJumpPressed() {
    if (_isGrounded && !_sessionEnded) {
      _isChargingJump = true;
      _jumpChargeStart = DateTime.now();
    }
  }

  void _onJumpReleased() {
    if (_isChargingJump && _isGrounded && !_sessionEnded) {
      final chargePercent = _jumpChargePercent.clamp(0.2, 1.0);

      setState(() {
        _jumpStartPlatform = _lastGroundedPlatform;
        _velocityY = _jumpVelocity * chargePercent;
        _isGrounded = false;
      });
    }
    _isChargingJump = false;
    _jumpChargeStart = null;
    _jumpChargePercent = 0.0;
  }

  double _screenTop(Platform p) => (p.y - _cameraY) * _screenSize.height;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        return ClipRect(
          child: Container(
            color: NunuColors.backgroundDefault,
            child: Stack(
              children: [
                _buildBackground(),
                ..._platforms
                    .where((p) {
                      final t = p.y - _cameraY;
                      return t > -0.05 && t < 1.05;
                    })
                    .map((p) => _buildPlatform(p)),
                _buildPlayer(),
                _buildHud(),
                _buildControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return CustomPaint(
      size: _screenSize,
      painter: BackgroundPainter(scrollOffset: _cameraY),
    );
  }

  Widget _buildPlatform(Platform platform) {
    return Positioned(
      left: platform.x * _screenSize.width,
      top: _screenTop(platform),
      child: Container(
        width: platform.width * _screenSize.width,
        height: _platformHeight * _screenSize.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: platform.brittle
                ? [
                    NunuColors.warningMain,
                    const Color(0xFFB45309),
                    NunuColors.warningDark,
                  ]
                : const [
                    NunuColors.secondaryMain,
                    NunuColors.secondaryDark,
                  ],
          ),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: platform.brittle
                ? NunuColors.warningLight
                : NunuColors.secondaryLight,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (platform.brittle
                      ? NunuColors.warningMain
                      : NunuColors.secondaryMain)
                  .withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayer() {
    final playerWidth = _playerWidth * _screenSize.width;
    final playerHeight = _playerHeight * _screenSize.height;

    return Positioned(
      left: _playerX * _screenSize.width,
      top: (_playerY - _cameraY) * _screenSize.height -
          (_isChargingJump ? 12 : 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isChargingJump)
            Container(
              width: playerWidth,
              height: 8,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: NunuColors.successDark, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: _jumpChargePercent,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          NunuColors.successLight,
                          _jumpChargePercent >= 1.0
                              ? NunuColors.warningMain
                              : NunuColors.successMain,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NunuColors.successMain.withValues(alpha: 0.6),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          Container(
            width: playerWidth,
            height: playerHeight,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: _isChargingJump
                    ? [
                        NunuColors.successLight,
                        NunuColors.primaryMain,
                        NunuColors.primaryDark,
                      ]
                    : [
                        NunuColors.primaryLighter,
                        NunuColors.primaryMain,
                        NunuColors.primaryDark,
                      ],
                stops: const [0.0, 0.5, 1.0],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: _isChargingJump
                    ? NunuColors.successLight
                    : NunuColors.primaryLight,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_isChargingJump
                          ? NunuColors.successMain
                          : NunuColors.primaryMain)
                      .withValues(alpha: 0.7),
                  blurRadius: _isChargingJump ? 20 : 15,
                  spreadRadius: _isChargingJump ? 5 : 3,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.person,
                color: Colors.white,
                size: playerHeight * 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHud() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: NunuColors.primaryDark, width: 1),
              ),
              child: Text(
                'altitude  $_altitude',
                style: const TextStyle(
                  color: NunuColors.primaryLight,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            Row(
              children: List.generate(_startingLives, (i) {
                final filled = i < _lives;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    filled ? Icons.favorite : Icons.favorite_border,
                    color: filled
                        ? NunuColors.errorMain
                        : NunuColors.errorDark.withValues(alpha: 0.45),
                    size: 28,
                  ),
                );
              }),
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
          GestureDetector(
            onTapDown: (_) => _onJumpPressed(),
            onTapUp: (_) => _onJumpReleased(),
            onTapCancel: () => _onJumpReleased(),
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
  BackgroundPainter({required this.scrollOffset});

  final double scrollOffset;

  @override
  void paint(Canvas canvas, Size size) {
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

    final starPaint = Paint()
      ..color = NunuColors.primaryDark.withValues(alpha: 0.3);

    for (int i = 0; i < 40; i++) {
      final x = (i * 37 + scrollOffset * size.width * 0.3) % size.width;
      final y = (i * 23 + scrollOffset * size.height * 0.5) % (size.height * 0.7);
      final radius = (i % 3) + 1.0;
      canvas.drawCircle(Offset(x, y), radius, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BackgroundPainter oldDelegate) =>
      oldDelegate.scrollOffset != scrollOffset;
}
