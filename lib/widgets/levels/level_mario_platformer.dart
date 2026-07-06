import 'dart:async';
import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

class _Platform {
  _Platform({
    required this.x,
    required this.y,
    required this.width,
    required this.altitude,
    required this.speed,
    required this.minX,
    required this.maxX,
    required this.brittle,
  }) : direction = 1,
       previousX = x;

  double x;
  final double y;
  final double width;
  final int altitude;
  final double speed;
  final double minX;
  final double maxX;
  final bool brittle;
  double direction;
  double previousX;

  double get deltaX => x - previousX;
}

class LevelMarioPlatformer extends LevelWidget {
  const LevelMarioPlatformer({super.key, required super.onComplete});

  @override
  State<LevelMarioPlatformer> createState() => _LevelMarioPlatformerState();
}

class _LevelMarioPlatformerState extends State<LevelMarioPlatformer>
    with SingleTickerProviderStateMixin {
  static const _winAltitude = 200;
  static const _startingLives = 3;
  static const _sessionDuration = Duration(minutes: 30);

  static const _groundY = 0.92;
  static const _rowGap = 0.14;
  static const _platformHeight = 0.025;
  static const _playerWidth = 0.08;
  static const _playerHeight = 0.08;

  static const _gravity = 0.0010;
  static const _jumpVelocity = -0.032;
  static const _moveSpeed = 0.009;
  static const _terminalVelocity = 0.022;
  static const _friction = 0.85;

  static const _cameraPlayerY = 0.58;
  static const _cameraLerp = 0.18;
  static const _retainRowsBelowPeak = 5;
  static const _spawnRowsAhead = 36;
  static const _fallPastLowestRow = 0.10;

  late final AnimationController _ticker;
  Timer? _sessionTimer;
  late DateTime _sessionEndsAt;
  final _rng = SeedService.instance.createRandom();

  final List<_Platform> _platforms = [];

  double _playerX = 0;
  double _playerY = 0;
  double _previousPlayerY = 0;
  double _velocityX = 0;
  double _velocityY = 0;
  bool _grounded = true;

  bool _pressingLeft = false;
  bool _pressingRight = false;
  bool _chargingJump = false;
  DateTime? _chargeStartedAt;
  double _chargePercent = 0;

  double _cameraY = 0;
  int _altitude = 0;
  int _peakAltitude = 0;
  int _bestAltitude = 0;
  int _lives = _startingLives;
  int _highestSpawned = 0;
  double _previousSpawnCenter = 0.5;
  bool _finished = false;

  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(_buildTimeoutOutcome);
    _startSession();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_tick);
    _ticker.repeat();
    _sessionEndsAt = DateTime.now().add(_sessionDuration);
    _sessionTimer = Timer(_sessionDuration, _onSessionTimer);
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
    widget.clearPartialScoreGetter();
    _ticker.dispose();
    super.dispose();
  }

  void _startSession() {
    _finished = false;
    _lives = _startingLives;
    _bestAltitude = 0;
    _startLife();
  }

  void _startLife() {
    _platforms
      ..clear()
      ..add(
        _Platform(
          x: 0,
          y: _worldY(0),
          width: 1,
          altitude: 0,
          speed: 0,
          minX: 0,
          maxX: 0,
          brittle: false,
        ),
      );

    _playerX = 0.08;
    _playerY = _worldY(0) - _playerHeight;
    _previousPlayerY = _playerY;
    _velocityX = 0;
    _velocityY = 0;
    _grounded = true;

    _cameraY = _playerY - _cameraPlayerY;
    _altitude = 0;
    _peakAltitude = 0;
    _highestSpawned = 0;
    _previousSpawnCenter = 0.5;
    _chargingJump = false;
    _chargeStartedAt = null;
    _chargePercent = 0;

    _ensurePlatformsAhead();
  }

  double _worldY(int altitude) => _groundY - altitude * _rowGap;

  void _ensurePlatformsAhead() {
    final target = min(
      _winAltitude + _spawnRowsAhead,
      _peakAltitude + _spawnRowsAhead,
    );
    while (_highestSpawned < target) {
      _spawnPlatform(_highestSpawned + 1);
    }
  }

  void _spawnPlatform(int altitude) {
    final width = altitude < 20
        ? 0.22
        : altitude < 50
        ? 0.20
        : altitude < 80
        ? 0.16
        : 0.12;
    final moveChance = altitude < 20
        ? 0.0
        : altitude < 50
        ? 0.4
        : altitude < 80
        ? 0.7
        : 0.95;
    final baseSpeed = altitude < 20
        ? 0.0
        : altitude < 50
        ? 0.0015
        : altitude < 80
        ? 0.0025
        : 0.0035;
    final speed = baseSpeed * (1 + (altitude / 250).clamp(0.0, 8.0));
    final brittleChance = altitude < 6
        ? 0.0
        : (0.06 + altitude / 2500).clamp(0.06, 0.32);
    final brittle = _rng.nextDouble() < brittleChance;

    const minX = 0.05;
    final maxX = 0.95 - width;
    final minCenter = minX + width / 2;
    final maxCenter = maxX + width / 2;
    final drift = (_rng.nextDouble() * 2 - 1) * 0.14;
    final centerPull = (0.5 - _previousSpawnCenter) * 0.12;
    final center = (_previousSpawnCenter + drift + centerPull).clamp(
      minCenter,
      maxCenter,
    );
    final x = center - width / 2;

    _platforms.add(
      _Platform(
        x: x,
        y: _worldY(altitude),
        width: width,
        altitude: altitude,
        speed: !brittle && _rng.nextDouble() < moveChance ? speed : 0,
        minX: minX,
        maxX: maxX,
        brittle: brittle,
      ),
    );
    _previousSpawnCenter = center;
    _highestSpawned = altitude;
  }

  void _tick() {
    if (!mounted || _size == Size.zero || _finished) return;

    var finishNow = false;
    var perfect = false;

    setState(() {
      _updateCharge();
      _movePlatforms();
      _applyInput();
      _applyPhysics();
      _landIfNeeded();
      _updateCamera();
      _cullOldPlatforms();

      if (_fellPastRetainedPlatforms()) {
        _loseLife();
        finishNow = _finished;
        return;
      }

      if (_peakAltitude >= _winAltitude) {
        _bestAltitude = _winAltitude;
        _finished = true;
        finishNow = true;
        perfect = true;
      }
    });

    if (finishNow) {
      _finishSession(perfect: perfect);
    }
  }

  void _updateCharge() {
    final started = _chargeStartedAt;
    if (!_chargingJump || started == null) return;
    _chargePercent = (DateTime.now().difference(started).inMilliseconds / 500)
        .clamp(0, 1);
  }

  void _movePlatforms() {
    for (final p in _platforms) {
      p.previousX = p.x;
      if (p.speed == 0) continue;

      p.x += p.speed * p.direction;
      if (p.x < p.minX) {
        p.x = p.minX;
        p.direction = 1;
      } else if (p.x > p.maxX) {
        p.x = p.maxX;
        p.direction = -1;
      }
    }
  }

  void _applyInput() {
    if (_pressingLeft && !_pressingRight) {
      _velocityX = -_moveSpeed;
    } else if (_pressingRight && !_pressingLeft) {
      _velocityX = _moveSpeed;
    } else {
      _velocityX *= _friction;
      if (_velocityX.abs() < 0.001) _velocityX = 0;
    }
  }

  void _applyPhysics() {
    _previousPlayerY = _playerY;

    _playerX = (_playerX + _velocityX).clamp(0.0, 1.0 - _playerWidth);

    if (_grounded && _velocityY == 0) {
      final support = _supportingPlatform();
      if (support != null) {
        _playerX = (_playerX + support.deltaX).clamp(0.0, 1.0 - _playerWidth);
        _playerY = support.y - _playerHeight;
        return;
      }
      _grounded = false;
    }

    _velocityY = min(_velocityY + _gravity, _terminalVelocity);
    _playerY += _velocityY;
  }

  _Platform? _supportingPlatform() {
    final playerBottom = _playerY + _playerHeight;
    for (final p in _platforms) {
      if (!_isRetained(p) || p.brittle) continue;
      if (_playerX + _playerWidth <= p.x || _playerX >= p.x + p.width) continue;
      if ((playerBottom - p.y).abs() <= 0.02) return p;
    }
    return null;
  }

  void _landIfNeeded() {
    if (_velocityY <= 0) return;

    final previousBottom = _previousPlayerY + _playerHeight;
    final currentBottom = _playerY + _playerHeight;
    _Platform? landing;

    for (final p in _platforms) {
      if (!_isRetained(p)) continue;
      if (_playerX + _playerWidth <= p.x || _playerX >= p.x + p.width) continue;
      if (previousBottom > p.y + 0.012) continue;
      if (currentBottom < p.y || currentBottom > p.y + 0.055) continue;

      // Pick the first surface crossed while falling.
      if (landing == null || p.y > landing.y) {
        landing = p;
      }
    }

    if (landing == null) return;

    if (landing.brittle) {
      _platforms.remove(landing);
      _velocityY = max(_velocityY, 0.012);
      return;
    }

    _playerY = landing.y - _playerHeight;
    _velocityY = 0;
    _grounded = true;
    _playerX = (_playerX + landing.deltaX).clamp(0.0, 1.0 - _playerWidth);

    _altitude = max(_altitude, landing.altitude);
    if (landing.altitude > _peakAltitude) {
      _peakAltitude = landing.altitude;
      _bestAltitude = max(_bestAltitude, _peakAltitude);
      _ensurePlatformsAhead();
    }
  }

  void _updateCamera() {
    final target = _playerY - _cameraPlayerY;
    _cameraY += (target - _cameraY) * _cameraLerp;
  }

  bool _isRetained(_Platform p) {
    return p.altitude >= _peakAltitude - _retainRowsBelowPeak;
  }

  void _cullOldPlatforms() {
    _platforms.removeWhere((p) => !_isRetained(p));
  }

  bool _fellPastRetainedPlatforms() {
    var lowestBottom = double.negativeInfinity;
    for (final p in _platforms) {
      if (!_isRetained(p)) continue;
      lowestBottom = max(lowestBottom, p.y + _platformHeight);
    }

    if (lowestBottom == double.negativeInfinity) return true;
    return _playerY + _playerHeight > lowestBottom + _fallPastLowestRow;
  }

  void _loseLife() {
    _bestAltitude = max(_bestAltitude, _peakAltitude);
    _lives--;
    if (_lives <= 0) {
      _finished = true;
      return;
    }
    _startLife();
  }

  void _onSessionTimer() {
    if (_finished || !mounted) return;
    _bestAltitude = max(_bestAltitude, _peakAltitude);
    _finished = true;
    _finishSession();
  }

  LevelOutcome _buildTimeoutOutcome() {
    final bestAltitude = max(_bestAltitude, _peakAltitude);
    return LevelOutcome(
      score: (bestAltitude / _winAltitude).clamp(0.0, 1.0),
      metrics: {
        'altitude': bestAltitude,
        'lives_used': _startingLives - _lives,
      },
      visibleMetricKeys: const {'altitude'},
    );
  }

  void _finishSession({bool perfect = false}) {
    if (!_finished) _finished = true;
    _sessionTimer?.cancel();
    _ticker.stop();

    final bestAltitude = perfect ? _winAltitude : _bestAltitude;
    final score = perfect ? 1.0 : (bestAltitude / _winAltitude).clamp(0.0, 1.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onComplete(
        LevelOutcome(
          score: score,
          metrics: {
            'altitude': bestAltitude,
            'lives_used': _startingLives - _lives,
          },
          visibleMetricKeys: const {'altitude'},
        ),
      );
    });
  }

  Duration get _timeRemaining {
    final remaining = _sessionEndsAt.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _onJumpPressed() {
    if (!_grounded || _finished) return;
    _chargingJump = true;
    _chargeStartedAt = DateTime.now();
  }

  void _onJumpReleased() {
    if (_chargingJump && !_finished) {
      final charge = _chargePercent.clamp(0.2, 1.0);
      setState(() {
        _velocityY = _jumpVelocity * charge;
        _grounded = false;
      });
    }
    _chargingJump = false;
    _chargeStartedAt = null;
    _chargePercent = 0;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = Size(constraints.maxWidth, constraints.maxHeight);

        return ClipRect(
          child: ColoredBox(
            color: NunuColors.backgroundDefault,
            child: Stack(
              children: [
                CustomPaint(
                  size: _size,
                  painter: _JumpKingPainter(
                    platforms: _platforms,
                    cameraY: _cameraY,
                    playerX: _playerX,
                    playerY: _playerY,
                    playerWidth: _playerWidth,
                    playerHeight: _playerHeight,
                    platformHeight: _platformHeight,
                    chargePercent: _chargingJump ? _chargePercent : 0,
                  ),
                ),
                _buildHud(),
                _buildControls(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHud() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: LevelHud(
          timerText: _formatDuration(_timeRemaining),
          stageText: 'altitude $_altitude/$_winAltitude',
          lives: LevelHud.emojiLives(_lives, _startingLives),
          infoTitle: 'jump man',
          infoItems: [
            const LevelHudBullet('🕹', 'hold jump to charge power, release to leap'),
            const LevelHudBullet('↔️', 'steer left and right while in the air'),
            LevelHudBullet('🏔', 'reach altitude $_winAltitude for a perfect score — your best height counts as partial credit'),
            const LevelHudBullet('❤️', 'falling off the platform costs a life'),
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
                onTapDown: (_) => setState(() => _pressingLeft = true),
                onTapUp: (_) => setState(() => _pressingLeft = false),
                onTapCancel: () => setState(() => _pressingLeft = false),
                child: _controlButton(
                  icon: Icons.arrow_back,
                  label: 'left',
                  pressed: _pressingLeft,
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTapDown: (_) => setState(() => _pressingRight = true),
                onTapUp: (_) => setState(() => _pressingRight = false),
                onTapCancel: () => setState(() => _pressingRight = false),
                child: _controlButton(
                  icon: Icons.arrow_forward,
                  label: 'right',
                  pressed: _pressingRight,
                ),
              ),
            ],
          ),
          GestureDetector(
            onTapDown: (_) => _onJumpPressed(),
            onTapUp: (_) => _onJumpReleased(),
            onTapCancel: () => _onJumpReleased(),
            child: _jumpButton(),
          ),
        ],
      ),
    );
  }

  Widget _controlButton({
    required IconData icon,
    required String label,
    required bool pressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 80),
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: pressed
            ? NunuColors.primaryMain.withValues(alpha: 0.3)
            : NunuColors.backgroundPaper.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: pressed ? NunuColors.primaryMain : NunuColors.primaryDark,
          width: pressed ? 3 : 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: pressed ? NunuColors.primaryLight : NunuColors.primaryMain,
            size: 28,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: pressed ? NunuColors.primaryLight : NunuColors.primaryMain,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _jumpButton() {
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
            color: NunuColors.successMain.withValues(alpha: 0.5),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.keyboard_arrow_up, color: Colors.white, size: 36),
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

class _JumpKingPainter extends CustomPainter {
  const _JumpKingPainter({
    required this.platforms,
    required this.cameraY,
    required this.playerX,
    required this.playerY,
    required this.playerWidth,
    required this.playerHeight,
    required this.platformHeight,
    required this.chargePercent,
  });

  final List<_Platform> platforms;
  final double cameraY;
  final double playerX;
  final double playerY;
  final double playerWidth;
  final double playerHeight;
  final double platformHeight;
  final double chargePercent;

  @override
  void paint(Canvas canvas, Size size) {
    _paintBackground(canvas, size);
    _paintPlatforms(canvas, size);
    _paintPlayer(canvas, size);
  }

  void _paintBackground(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Color(0xFF0D0D24),
          NunuColors.backgroundDefault,
          Color(0xFF12102A),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, paint);

    final starPaint = Paint()
      ..color = NunuColors.primaryDark.withValues(alpha: 0.28);
    for (var i = 0; i < 40; i++) {
      final x = (i * 37 + cameraY * size.width * 0.3) % size.width;
      final y = (i * 23 + cameraY * size.height * 0.5) % (size.height * 0.7);
      canvas.drawCircle(Offset(x, y), (i % 3) + 1.0, starPaint);
    }
  }

  void _paintPlatforms(Canvas canvas, Size size) {
    for (final p in platforms) {
      final top = (p.y - cameraY) * size.height;
      final height = platformHeight * size.height;
      if (top + height < -8 || top > size.height + 8) continue;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(p.x * size.width, top, p.width * size.width, height),
        const Radius.circular(4),
      );
      final fill = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: p.brittle
              ? const [
                  NunuColors.warningMain,
                  Color(0xFFB45309),
                  NunuColors.warningDark,
                ]
              : const [NunuColors.secondaryMain, NunuColors.secondaryDark],
        ).createShader(rect.outerRect);
      final border = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = p.brittle
            ? NunuColors.warningLight
            : NunuColors.secondaryLight;

      canvas.drawRRect(rect, fill);
      canvas.drawRRect(rect, border);
    }
  }

  void _paintPlayer(Canvas canvas, Size size) {
    final width = playerWidth * size.width;
    final height = playerHeight * size.height;
    final left = playerX * size.width;
    final top = (playerY - cameraY) * size.height;

    if (chargePercent > 0) {
      final chargeRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top - 12, width, 8),
        const Radius.circular(4),
      );
      canvas.drawRRect(chargeRect, Paint()..color = NunuColors.backgroundPaper);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top - 12, width * chargePercent, 8),
          const Radius.circular(4),
        ),
        Paint()
          ..color = chargePercent >= 1
              ? NunuColors.warningMain
              : NunuColors.successMain,
      );
    }

    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, width, height),
      const Radius.circular(8),
    );
    final fill = Paint()
      ..shader = RadialGradient(
        colors: chargePercent > 0
            ? const [
                NunuColors.successLight,
                NunuColors.primaryMain,
                NunuColors.primaryDark,
              ]
            : const [
                NunuColors.primaryLighter,
                NunuColors.primaryMain,
                NunuColors.primaryDark,
              ],
      ).createShader(rect.outerRect);
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = chargePercent > 0
          ? NunuColors.successLight
          : NunuColors.primaryLight;

    canvas.drawRRect(rect, fill);
    canvas.drawRRect(rect, border);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(Icons.person.codePoint),
        style: TextStyle(
          fontFamily: Icons.person.fontFamily,
          package: Icons.person.fontPackage,
          color: Colors.white,
          fontSize: height * 0.55,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    iconPainter.paint(
      canvas,
      Offset(
        left + (width - iconPainter.width) / 2,
        top + (height - iconPainter.height) / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _JumpKingPainter oldDelegate) => true;
}
