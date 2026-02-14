import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

/// Classic flappy bird – tap to fly, dodge the pipes. Need 5 to pass.
class LevelFlappyBird extends LevelWidget {
  const LevelFlappyBird({super.key, required super.onComplete});

  @override
  State<LevelFlappyBird> createState() => _LevelFlappyBirdState();
}

class _Pipe {
  double x; // left edge
  final double gapCenterY; // centre of gap (0-1 normalised)
  bool scored = false;

  _Pipe({required this.x, required this.gapCenterY});
}

class _LevelFlappyBirdState extends State<LevelFlappyBird>
    with SingleTickerProviderStateMixin {
  static const int _scoreToWin = 5;
  static const double _gapHeight = 0.28; // fraction of screen height
  static const double _pipeWidth = 48;
  static const double _pipeSpacing = 270; // px between pipe pairs
  static const double _birdX = 0.2; // fraction of screen width

  late AnimationController _ticker;
  final Random _rng = Random();

  // sizes
  double _w = 0, _h = 0;

  // bird state (in pixels)
  double _birdY = 0;
  double _vy = 0;
  double _gravity = 0;
  double _flapVel = 0;
  double _birdSize = 0;

  // pipes
  final List<_Pipe> _pipes = [];
  double _pipeSpeed = 0;
  double _nextPipeX = 0;

  // game state
  bool _started = false;
  bool _gameOver = false;
  bool _completed = false;
  int _score = 0;
  DateTime _lastFrame = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(days: 1),
    )..addListener(_gameLoop);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _initGame(Size size) {
    _w = size.width;
    _h = size.height;
    _birdSize = _h * 0.038;
    _gravity = _h * 1.5;
    _flapVel = -_h * 0.42;
    _pipeSpeed = _w * 0.22;

    _birdY = _h * 0.45;
    _vy = 0;
    _score = 0;
    _gameOver = false;

    _pipes.clear();
    _nextPipeX = _w * 0.65;
    _spawnInitialPipes();
  }

  void _spawnInitialPipes() {
    for (int i = 0; i < 4; i++) {
      _pipes.add(_Pipe(
        x: _nextPipeX,
        gapCenterY: 0.28 + _rng.nextDouble() * 0.44,
      ));
      _nextPipeX += _pipeSpacing;
    }
  }

  void _flap() {
    if (_completed) return;
    if (_gameOver) {
      // restart
      setState(() {
        _started = false;
        _initGame(Size(_w, _h));
      });
      return;
    }
    if (!_started) {
      _started = true;
      _lastFrame = DateTime.now();
      _ticker.repeat();
    }
    _vy = _flapVel;
  }

  // ---------- game loop ----------

  void _gameLoop() {
    if (_gameOver || !_started) return;
    final now = DateTime.now();
    final dt =
        (now.difference(_lastFrame).inMicroseconds / 1e6).clamp(0.0, 0.04);
    _lastFrame = now;

    // bird physics
    _vy += _gravity * dt;
    _birdY += _vy * dt;

    // move pipes
    for (final pipe in _pipes) {
      pipe.x -= _pipeSpeed * dt;
    }

    // spawn new pipes
    if (_pipes.isEmpty || _pipes.last.x < _w - _pipeSpacing + 20) {
      _pipes.add(_Pipe(
        x: (_pipes.isEmpty ? _w : _pipes.last.x) + _pipeSpacing,
        gapCenterY: 0.28 + _rng.nextDouble() * 0.44,
      ));
    }

    // remove off-screen
    _pipes.removeWhere((p) => p.x + _pipeWidth < -20);

    // scoring
    final birdScreenX = _w * _birdX;
    for (final pipe in _pipes) {
      if (!pipe.scored && pipe.x + _pipeWidth < birdScreenX) {
        pipe.scored = true;
        _score++;
        if (_score >= _scoreToWin && !_completed) {
          _completed = true;
          _ticker.stop();
          Future.delayed(const Duration(milliseconds: 400), () {
            widget.onComplete(true, metrics: {'score': _score});
          });
          setState(() {});
          return;
        }
      }
    }

    // collision
    if (_checkCollision()) {
      _gameOver = true;
      _ticker.stop();
      if (_score >= _scoreToWin && !_completed) {
        _completed = true;
        Future.delayed(const Duration(milliseconds: 400), () {
          widget.onComplete(true, metrics: {'score': _score});
        });
      }
      setState(() {});
      return;
    }

    setState(() {});
  }

  bool _checkCollision() {
    final birdScreenX = _w * _birdX;
    // ceiling / floor
    if (_birdY - _birdSize < 0 || _birdY + _birdSize > _h) return true;

    // pipes
    for (final pipe in _pipes) {
      final pipeLeft = pipe.x;
      final pipeRight = pipe.x + _pipeWidth;

      // horizontal overlap?
      if (birdScreenX + _birdSize > pipeLeft &&
          birdScreenX - _birdSize < pipeRight) {
        final gapTop = pipe.gapCenterY * _h - _gapHeight * _h / 2;
        final gapBot = pipe.gapCenterY * _h + _gapHeight * _h / 2;
        if (_birdY - _birdSize < gapTop || _birdY + _birdSize > gapBot) {
          return true;
        }
      }
    }
    return false;
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = Size(box.maxWidth, box.maxHeight);

        // lazy init
        if (_w == 0) _initGame(size);

        return GestureDetector(
          onTap: _flap,
          child: CustomPaint(
            size: size,
            painter: _FlappyPainter(
              birdY: _birdY,
              birdX: size.width * _birdX,
              birdSize: _birdSize,
              pipes: _pipes,
              pipeWidth: _pipeWidth,
              gapHeight: _gapHeight,
              screenH: _h,
              screenW: _w,
              score: _score,
              scoreToWin: _scoreToWin,
              gameOver: _gameOver,
              started: _started,
              completed: _completed,
              vy: _vy,
            ),
          ),
        );
      },
    );
  }
}

// ---------- painter ----------

class _FlappyPainter extends CustomPainter {
  final double birdY, birdX, birdSize;
  final List<_Pipe> pipes;
  final double pipeWidth, gapHeight, screenH, screenW;
  final int score, scoreToWin;
  final bool gameOver, started, completed;
  final double vy;

  const _FlappyPainter({
    required this.birdY,
    required this.birdX,
    required this.birdSize,
    required this.pipes,
    required this.pipeWidth,
    required this.gapHeight,
    required this.screenH,
    required this.screenW,
    required this.score,
    required this.scoreToWin,
    required this.gameOver,
    required this.started,
    required this.completed,
    required this.vy,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF050816), Color(0xFF0A1228)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // grid lines for depth
    final gridPaint = Paint()
      ..color = NunuColors.secondaryMain.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (int i = 0; i < 20; i++) {
      final y = size.height * i / 20;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // pipes
    for (final pipe in pipes) {
      final gapTop = pipe.gapCenterY * screenH - gapHeight * screenH / 2;
      final gapBot = pipe.gapCenterY * screenH + gapHeight * screenH / 2;

      // top pipe
      final topRect =
          Rect.fromLTWH(pipe.x, 0, pipeWidth, gapTop);
      _drawPipe(canvas, topRect, false);

      // bottom pipe
      final botRect =
          Rect.fromLTWH(pipe.x, gapBot, pipeWidth, size.height - gapBot);
      _drawPipe(canvas, botRect, true);

      // gap glow
      canvas.drawRect(
        Rect.fromLTWH(pipe.x - 2, gapTop, pipeWidth + 4, gapBot - gapTop),
        Paint()
          ..color = NunuColors.infoMain.withValues(alpha: 0.04)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
      );
    }

    // bird
    _drawBird(canvas);

    // score
    final scoreText = TextPainter(
      text: TextSpan(
        text: '$score',
        style: TextStyle(
          color: NunuColors.textPrimary.withValues(alpha: 0.9),
          fontSize: 42,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    scoreText.paint(
      canvas,
      Offset(size.width / 2 - scoreText.width / 2, 36),
    );

    // messages
    if (!started && !gameOver) {
      _drawMessage(canvas, size, 'tap to start');
    } else if (gameOver && !completed) {
      _drawMessage(canvas, size, 'game over · tap to retry');
    }
  }

  void _drawPipe(Canvas canvas, Rect rect, bool isBottom) {
    // body
    final bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          const Color(0xFF0D3B3B),
          NunuColors.infoMain.withValues(alpha: 0.35),
          const Color(0xFF0D3B3B),
        ],
      ).createShader(rect);
    canvas.drawRect(rect, bodyPaint);

    // border
    canvas.drawRect(
      rect,
      Paint()
        ..color = NunuColors.infoMain.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // cap at opening end
    final capY = isBottom ? rect.top : rect.bottom;
    final capRect = Rect.fromLTWH(
      rect.left - 4,
      isBottom ? capY - 8 : capY,
      rect.width + 8,
      8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(capRect, const Radius.circular(3)),
      Paint()..color = NunuColors.infoMain.withValues(alpha: 0.5),
    );
  }

  void _drawBird(Canvas canvas) {
    final center = Offset(birdX, birdY);

    // glow
    canvas.drawCircle(
      center,
      birdSize * 2,
      Paint()
        ..color = NunuColors.primaryMain.withValues(alpha: 0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // body
    canvas.drawCircle(
      center,
      birdSize,
      Paint()..color = NunuColors.primaryMain,
    );

    // eye
    canvas.drawCircle(
      center + Offset(birdSize * 0.3, -birdSize * 0.2),
      birdSize * 0.22,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      center + Offset(birdSize * 0.35, -birdSize * 0.2),
      birdSize * 0.12,
      Paint()..color = Colors.black,
    );

    // wing (rotated by velocity)
    final wingAngle = (vy / 800).clamp(-0.5, 0.5);
    final wingPath = Path();
    final wx = center.dx - birdSize * 0.5;
    final wy = center.dy + birdSize * 0.1;
    wingPath.moveTo(wx, wy);
    wingPath.quadraticBezierTo(
      wx - birdSize * 0.8,
      wy - birdSize * 0.6 + wingAngle * birdSize,
      wx - birdSize * 0.3,
      wy - birdSize * 0.1,
    );
    canvas.drawPath(
      wingPath,
      Paint()
        ..color = NunuColors.primaryLight.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    // beak
    final beakPath = Path();
    beakPath.moveTo(
        center.dx + birdSize * 0.85, center.dy + birdSize * 0.05);
    beakPath.lineTo(
        center.dx + birdSize * 1.3, center.dy + birdSize * 0.15);
    beakPath.lineTo(center.dx + birdSize * 0.85, center.dy + birdSize * 0.3);
    beakPath.close();
    canvas.drawPath(beakPath, Paint()..color = NunuColors.warningMain);
  }

  void _drawMessage(Canvas canvas, Size size, String msg) {
    final tp = TextPainter(
      text: TextSpan(
        text: msg,
        style: TextStyle(
          color: NunuColors.textSecondary.withValues(alpha: 0.7),
          fontSize: 18,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width / 2 - tp.width / 2, size.height * 0.7),
    );
  }

  @override
  bool shouldRepaint(covariant _FlappyPainter old) => true;
}
