import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
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
  sliderAlign,
  rotateAlign,
}

class _LevelCaptchaState extends State<LevelCaptcha> {
  _CaptchaStep _step = _CaptchaStep.gate;
  bool _isVerifying = false;

  final Random _rng = Random();
  final Stopwatch _playSw = Stopwatch();

  // --- Text CAPTCHAs ---
  final TextEditingController _textCtrl = TextEditingController();

  // --- Image grid (taxis) ---
  // Correct tiles: top-left (0), middle-left (3), middle-center (4)
  static const Set<int> _gridCorrect = {0, 3, 4};
  final Set<int> _gridSelected = {};

  // --- Slider align ---
  double _sliderX = 0.5;

  // --- Rotate ---
  double _rotateTurns = 0;
  late double _targetTurns;

  @override
  void initState() {
    super.initState();
    _targetTurns = _rng.nextInt(3) / 4.0;
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
        setState(() => _step = _CaptchaStep.sliderAlign);
      case _CaptchaStep.sliderAlign:
        setState(() => _step = _CaptchaStep.rotateAlign);
      case _CaptchaStep.rotateAlign:
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

  void _verifyText1() {
    if (_textCtrl.text.trim().toLowerCase() == '2pfpn') {
      _nextStep();
    } else {
      _snack('text does not match');
    }
  }

  void _verifyText2() {
    if (_textCtrl.text.trim().toUpperCase() == 'HAPK3') {
      _nextStep();
    } else {
      _snack('text does not match');
    }
  }

  void _verifyGrid() {
    if (_gridSelected.length == _gridCorrect.length &&
        _gridSelected.containsAll(_gridCorrect)) {
      _nextStep();
    } else {
      setState(() => _gridSelected.clear());
      _snack('try again');
    }
  }

  void _verifySlider() {
    if ((_sliderX - 0.5).abs() <= 0.06) {
      _nextStep();
    } else {
      _snack('align the bars');
    }
  }

  void _verifyRotate() {
    final d = (_rotateTurns - _targetTurns + 10) % 1.0;
    final err = d > 0.5 ? 1.0 - d : d;
    if (err <= 0.08) {
      _playSw.stop();
      widget.onComplete(LevelOutcome(
        score: 1,
        metrics: {'duration_ms': _playSw.elapsedMilliseconds},
      ));
    } else {
      _snack('rotate to upright');
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
            child: _buildStep(),
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
      case _CaptchaStep.sliderAlign:
        return _wrapCard(_buildSlider());
      case _CaptchaStep.rotateAlign:
        return _wrapCard(_buildRotate());
    }
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

  // Fractional positions of the 3x3 grid within the 546×818 image.
  static const double _gridTopFrac = 0.160;
  static const double _gridBottomFrac = 0.860;
  static const double _gridLeftFrac = 0.004;
  static const double _gridRightFrac = 0.996;
  // VERIFY button area
  static const double _verifyTopFrac = 0.905;
  static const double _verifyBottomFrac = 0.975;
  static const double _verifyLeftFrac = 0.62;
  static const double _verifyRightFrac = 0.97;
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

  // ─── SLIDER ────────────────────────────────────────────

  Widget _buildSlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'slide until stripes line up',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: (_sliderX * 100).round().clamp(1, 99),
                    child: Container(
                      color: NunuColors.secondaryMain.withValues(alpha: 0.6),
                    ),
                  ),
                  Expanded(
                    flex: ((1 - _sliderX) * 100).round().clamp(1, 99),
                    child: Container(
                      color: NunuColors.primaryDark.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
              Container(width: 4, height: 56, color: Colors.white),
            ],
          ),
        ),
        Slider(
          value: _sliderX,
          onChanged: (v) => setState(() => _sliderX = v),
        ),
        FilledButton(
          onPressed: _verifySlider,
          child: const Text('lock in'),
        ),
      ],
    );
  }

  // ─── ROTATE ────────────────────────────────────────────

  Widget _buildRotate() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'rotate until the arrow points up',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Transform.rotate(
          angle: (_rotateTurns - _targetTurns) * 2 * pi,
          child: const Icon(
            Icons.navigation,
            size: 80,
            color: Colors.cyanAccent,
          ),
        ),
        Slider(
          value: _rotateTurns,
          min: 0,
          max: 1,
          divisions: 48,
          label: _rotateTurns.toStringAsFixed(2),
          onChanged: (v) => setState(() => _rotateTurns = v),
        ),
        FilledButton(
          onPressed: _verifyRotate,
          child: const Text('confirm rotation'),
        ),
      ],
    );
  }
}
