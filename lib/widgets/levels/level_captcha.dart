import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../level_widget.dart';

class LevelCaptcha extends LevelWidget {
  const LevelCaptcha({super.key, required super.onComplete});

  @override
  State<LevelCaptcha> createState() => _LevelCaptchaState();
}

enum _CaptchaStep {
  gate,
  textCaptcha1,
  imageGrid,
  textCaptcha2,
  matchFacing,
}

class _LevelCaptchaState extends State<LevelCaptcha> {
  _CaptchaStep _step = _CaptchaStep.gate;
  bool _isVerifying = false;

  final Random _rng = Random();
  final Stopwatch _playSw = Stopwatch();

  /// Wrong answers cost one life; at 0 the run ends.
  int _lives = 10;

  // --- Text CAPTCHAs ---
  final TextEditingController _textCtrl = TextEditingController();

  // --- Image grid (taxis) ---
  // Correct tiles: top-left (0), middle-left (3), middle-center (4)
  static const Set<int> _gridCorrect = {0, 3, 4};
  final Set<int> _gridSelected = {};

  // --- Match facing (hand vs animal), 8 compass steps clockwise from east ---
  late int _targetFacing;
  late int _animalFacing;

  @override
  void initState() {
    super.initState();
    _rollFacingChallenge();
  }

  void _rollFacingChallenge() {
    _targetFacing = _rng.nextInt(8);
    do {
      _animalFacing = _rng.nextInt(8);
    } while (_animalFacing == _targetFacing);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  // ─── FLOW ──────────────────────────────────────────────

  void _nextStep() {
    switch (_step) {
      case _CaptchaStep.gate:
        setState(() => _step = _CaptchaStep.textCaptcha1);
      case _CaptchaStep.textCaptcha1:
        setState(() {
          _textCtrl.clear();
          _step = _CaptchaStep.imageGrid;
        });
      case _CaptchaStep.imageGrid:
        setState(() {
          _textCtrl.clear();
          _step = _CaptchaStep.textCaptcha2;
        });
      case _CaptchaStep.textCaptcha2:
        setState(() {
          _rollFacingChallenge();
          _step = _CaptchaStep.matchFacing;
        });
      case _CaptchaStep.matchFacing:
        break;
    }
  }

  void _gateTap() {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _playSw
        ..reset()
        ..start();
      setState(() => _isVerifying = false);
      _nextStep();
    });
  }

  bool _loseLifeIfAny() {
    if (_lives <= 0 || !mounted) return false;
    setState(() => _lives -= 1);
    if (_lives <= 0) {
      _playSw.stop();
      if (!mounted) return false;
      widget.onComplete(LevelOutcome(
        score: 0,
        metrics: {'duration_ms': _playSw.elapsedMilliseconds, 'out_of_lives': true},
      ));
      return false;
    }
    return true;
  }

  void _verifyText1() {
    if (_textCtrl.text.trim().toLowerCase() == '2pfpn') {
      _nextStep();
    } else {
      if (!_loseLifeIfAny()) return;
      _snack('text does not match');
    }
  }

  void _verifyText2() {
    if (_textCtrl.text.trim().toUpperCase() == 'HAPK3') {
      _nextStep();
    } else {
      if (!_loseLifeIfAny()) return;
      _snack('text does not match');
    }
  }

  void _verifyGrid() {
    if (_gridSelected.length == _gridCorrect.length &&
        _gridSelected.containsAll(_gridCorrect)) {
      _nextStep();
    } else {
      if (!_loseLifeIfAny()) return;
      setState(() => _gridSelected.clear());
      _snack('try again');
    }
  }

  void _verifyMatchFacing() {
    if (_animalFacing == _targetFacing) {
      _playSw.stop();
      widget.onComplete(LevelOutcome(
        score: 1,
        metrics: {
          'duration_ms': _playSw.elapsedMilliseconds,
          'lives_left': _lives,
        },
      ));
    } else {
      if (!_loseLifeIfAny()) return;
      _snack('direction does not match the hand');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade900, Colors.black],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_step != _CaptchaStep.gate) _buildLivesBar(),
                if (_step != _CaptchaStep.gate) const SizedBox(height: 12),
                _buildStep(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _CaptchaStep.gate:
        return _wrapCard(_buildGate());
      case _CaptchaStep.textCaptcha1:
        return _wrapCard(_buildTextCaptcha(
          assetPath: 'assets/captcha/text_1.png',
          onVerify: _verifyText1,
        ));
      case _CaptchaStep.imageGrid:
        return _buildImageGrid();
      case _CaptchaStep.textCaptcha2:
        return _wrapCard(_buildTextCaptcha(
          assetPath: 'assets/captcha/text_2.png',
          onVerify: _verifyText2,
        ));
      case _CaptchaStep.matchFacing:
        return _wrapCard(_buildMatchFacing());
    }
  }

  Widget _buildLivesBar() {
    return Row(
      children: [
        Icon(Icons.favorite, color: Colors.red.shade400, size: 22),
        const SizedBox(width: 8),
        Text(
          '$_lives',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          _lives == 1 ? 'life left' : 'lives left',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
      ],
    );
  }

  Widget _wrapCard(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade700),
      ),
      child: child,
    );
  }

  // ─── GATE ──────────────────────────────────────────────

  Widget _buildGate() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'before you continue!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _gateTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade500, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _isVerifying
                      ? const Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                const Text(
                  "i'm not a robot",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── TEXT CAPTCHA (uses actual images) ─────────────────

  Widget _buildTextCaptcha({
    required String assetPath,
    required VoidCallback onVerify,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'type the characters you see',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade600),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textCtrl,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 2,
          ),
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'type here',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: onVerify,
            child: const Text('submit'),
          ),
        ),
      ],
    );
  }

  // ─── IMAGE GRID (reCAPTCHA overlay on actual photo) ───

  // Fractional positions of the 3x3 grid within the 546×818 image (calibrated to asset).
  static const double _gridTopFrac = 200 / 818;
  static const double _gridBottomFrac = 695 / 818;
  static const double _gridLeftFrac = 18 / 546;
  static const double _gridRightFrac = 520 / 546;
  // VERIFY button area (blue chip, lower right)
  static const double _verifyTopFrac = 728 / 818;
  static const double _verifyBottomFrac = 790 / 818;
  static const double _verifyLeftFrac = 369 / 546;
  static const double _verifyRightFrac = 518 / 546;
  static const double _imageAspect = 546 / 818;

  Widget _buildImageGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = w / _imageAspect;

        final gridTop = h * _gridTopFrac;
        final gridHeight = h * (_gridBottomFrac - _gridTopFrac);
        final gridLeft = w * _gridLeftFrac;
        final gridWidth = w * (_gridRightFrac - _gridLeftFrac);

        final cellW = gridWidth / 3;
        final cellH = gridHeight / 3;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              // Full reCAPTCHA image
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.asset(
                    'assets/captcha/grid_taxis.png',
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              // Selection overlays + tap targets for each tile
              for (var row = 0; row < 3; row++)
                for (var col = 0; col < 3; col++)
                  _buildTileTap(
                    index: row * 3 + col,
                    left: gridLeft + col * cellW,
                    top: gridTop + row * cellH,
                    width: cellW,
                    height: cellH,
                  ),
              // Transparent VERIFY tap target over the image's VERIFY button
              Positioned(
                top: h * _verifyTopFrac,
                left: w * _verifyLeftFrac,
                width: w * (_verifyRightFrac - _verifyLeftFrac),
                height: h * (_verifyBottomFrac - _verifyTopFrac),
                child: GestureDetector(
                  onTap: _gridSelected.isEmpty ? null : _verifyGrid,
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTileTap({
    required int index,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final selected = _gridSelected.contains(index);
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (selected) {
              _gridSelected.remove(index);
            } else {
              _gridSelected.add(index);
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: selected
                ? const Color(0xFF4285F4).withValues(alpha: 0.4)
                : Colors.transparent,
            border: selected
                ? Border.all(color: const Color(0xFF4285F4), width: 3)
                : null,
          ),
          child: selected
              ? const Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                )
              : null,
        ),
      ),
    );
  }

  // ─── MATCH FACING (hand reference + rotatable animal) ─

  static const Color _floorGreen = Color(0xFF1A3D2E);
  static const Color _floorGreenLight = Color(0xFF244A38);

  Widget _buildMatchFacing() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'use the arrows to rotate the animal to face the same way as the hand. (1 of 1)',
          style: TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _FacingStage(
                title: 'match this!',
                floorA: _floorGreen,
                floorB: _floorGreenLight,
                child: Transform.rotate(
                  angle: _targetFacing * (pi / 4),
                  child: CustomPaint(
                    size: const Size(88, 88),
                    painter: _HandPointerPainter(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FacingStage(
                title: 'rotate to match',
                floorA: _floorGreen,
                floorB: _floorGreenLight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.rotate(
                      angle: _animalFacing * (pi / 4),
                      child: CustomPaint(
                        size: const Size(88, 88),
                        painter: _DogFacingPainter(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filled(
                          onPressed: () {
                            setState(
                              () => _animalFacing = (_animalFacing + 7) % 8,
                            );
                          },
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () {
                            setState(
                              () => _animalFacing = (_animalFacing + 1) % 8,
                            );
                          },
                          icon: const Icon(Icons.arrow_forward),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _verifyMatchFacing,
            child: const Text('submit'),
          ),
        ),
      ],
    );
  }
}

/// Dark green “studio floor” with a light diamond grid (reference-style).
class _FacingStage extends StatelessWidget {
  const _FacingStage({
    required this.title,
    required this.floorA,
    required this.floorB,
    required this.child,
  });

  final String title;
  final Color floorA;
  final Color floorB;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _DiamondFloorPainter(
                    colorA: floorA,
                    colorB: floorB,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.15),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiamondFloorPainter extends CustomPainter {
  _DiamondFloorPainter({required this.colorA, required this.colorB});

  final Color colorA;
  final Color colorB;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(0, 0, size.width, size.height);
    final bg = Paint()..color = colorA;
    canvas.drawRect(r, bg);

    final line = Paint()
      ..color = colorB.withValues(alpha: 0.55)
      ..strokeWidth = 1.2;

    const step = 28.0;
    for (double x = -size.height; x < size.width + size.height; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), line);
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), line);
    }
  }

  @override
  bool shouldRepaint(covariant _DiamondFloorPainter oldDelegate) =>
      oldDelegate.colorA != colorA || oldDelegate.colorB != colorB;
}

/// Simple hand with index finger pointing to the right (+x); rotated by parent.
class _HandPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.45;
    final cy = size.height * 0.52;
    final skin = const Color(0xFFE8D5C4);
    final outline = Paint()
      ..color = const Color(0xFF8B7355).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final palm = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx - 6, cy + 4),
            width: size.width * 0.38,
            height: size.height * 0.22,
          ),
          const Radius.circular(6),
        ),
      );
    canvas.drawPath(
      palm,
      Paint()..color = skin,
    );
    canvas.drawPath(palm, outline);

    // Index finger (points +x)
    final finger = Path()
      ..moveTo(cx + 2, cy - 4)
      ..quadraticBezierTo(cx + 28, cy - 18, cx + 36, cy - 6)
      ..lineTo(cx + 34, cy + 2)
      ..quadraticBezierTo(cx + 22, cy - 8, cx + 4, cy + 6)
      ..close();
    canvas.drawPath(finger, Paint()..color = skin);
    canvas.drawPath(finger, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Dog silhouette facing +x (snout right); rotated by parent.
class _DogFacingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.42;
    final cy = size.height * 0.5;
    const fur = Color(0xFFC4A574);
    final outline = Paint()
      ..color = const Color(0xFF5C4A2E).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final body = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx - 4, cy + 2),
          width: size.width * 0.42,
          height: size.height * 0.28,
        ),
      );
    canvas.drawPath(body, Paint()..color = fur);
    canvas.drawPath(body, outline);

    final head = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx + 18, cy - 6),
          width: size.width * 0.32,
          height: size.height * 0.26,
        ),
      );
    canvas.drawPath(head, Paint()..color = fur);
    canvas.drawPath(head, outline);

    // Snout bump (+x)
    final snout = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx + 32, cy - 4),
          width: size.width * 0.14,
          height: size.height * 0.12,
        ),
      );
    canvas.drawPath(snout, Paint()..color = fur);
    canvas.drawPath(snout, outline);

    // Ear
    final ear = Path()
      ..moveTo(cx + 8, cy - 18)
      ..lineTo(cx + 2, cy - 28)
      ..lineTo(cx + 14, cy - 20)
      ..close();
    canvas.drawPath(ear, Paint()..color = const Color(0xFF9A7B4A));
    canvas.drawPath(ear, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
