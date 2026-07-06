import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
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
  trafficLightsGrid,
  matchFacing,
  matchFacing2,
  deathToHumans,
  confirmHuman,
}

class _LevelCaptchaState extends State<LevelCaptcha> {
  static const int _totalStages = 9;

  _CaptchaStep _step = _CaptchaStep.gate;
  bool _isVerifying = false;
  bool _stageActionLocked = false;
  bool _isFinished = false;

  final Random _rng = SeedService.instance.createRandom();
  final Stopwatch _playSw = Stopwatch();

  // Stage scoring:
  // success after N wrong attempts = 0.5^N, skip stage = 0
  int _wrongAttempts = 0;
  int _totalWrongAttempts = 0;
  int _skippedStages = 0;
  final List<double> _stageScores = [];

  final TextEditingController _textCtrl = TextEditingController();

  // --- Image grid (taxis) ---
  static const Set<int> _gridCorrect = {0, 3, 4};
  final Set<int> _gridSelected = {};

  // --- Image grid (traffic lights) ---
  static const Set<int> _trafficCorrect = {1, 2, 3};
  final Set<int> _trafficSelected = {};

  // --- Match facing ---
  late int _targetFacing;
  late int _animalFacing;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: (_stageScores.fold(0.0, (s, v) => s + v) / _totalStages).clamp(0.0, 1.0),
          metrics: {'stages_scored': _stageScores.length},
        ));
    _rollFacingChallenge();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _rollFacingChallenge() {
    _targetFacing = _rng.nextInt(8);
    do {
      _animalFacing = _rng.nextInt(8);
    } while (_animalFacing == _targetFacing);
  }

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
          _gridSelected.clear();
          _step = _CaptchaStep.textCaptcha2;
        });
      case _CaptchaStep.textCaptcha2:
        setState(() {
          _trafficSelected.clear();
          _step = _CaptchaStep.trafficLightsGrid;
        });
      case _CaptchaStep.trafficLightsGrid:
        setState(() {
          _rollFacingChallenge();
          _step = _CaptchaStep.matchFacing;
        });
      case _CaptchaStep.matchFacing:
        setState(() {
          _rollFacingChallenge();
          _step = _CaptchaStep.matchFacing2;
        });
      case _CaptchaStep.matchFacing2:
        setState(() {
          _textCtrl.clear();
          _step = _CaptchaStep.deathToHumans;
        });
      case _CaptchaStep.deathToHumans:
        setState(() {
          _textCtrl.clear();
          _step = _CaptchaStep.confirmHuman;
        });
      case _CaptchaStep.confirmHuman:
        break;
    }
  }

  int get _stageNumber {
    switch (_step) {
      case _CaptchaStep.gate:
        return 1;
      case _CaptchaStep.textCaptcha1:
        return 2;
      case _CaptchaStep.imageGrid:
        return 3;
      case _CaptchaStep.textCaptcha2:
        return 4;
      case _CaptchaStep.trafficLightsGrid:
        return 5;
      case _CaptchaStep.matchFacing:
        return 6;
      case _CaptchaStep.matchFacing2:
        return 7;
      case _CaptchaStep.deathToHumans:
        return 8;
      case _CaptchaStep.confirmHuman:
        return 9;
    }
  }

  bool get _canSkipStage {
    // While selecting grid tiles, keep the top-right skip button inert so a
    // near-miss tap around the grid cannot accidentally advance several stages.
    if (_step == _CaptchaStep.imageGrid && _gridSelected.isNotEmpty) {
      return false;
    }
    if (_step == _CaptchaStep.trafficLightsGrid &&
        _trafficSelected.isNotEmpty) {
      return false;
    }
    return !_stageActionLocked && !_isFinished;
  }

  void _lockStageActionsBriefly() {
    _stageActionLocked = true;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!mounted || _isFinished) return;
      setState(() => _stageActionLocked = false);
    });
  }

  void _registerWrongAttempt() {
    _wrongAttempts += 1;
    _totalWrongAttempts += 1;
  }

  void _completeStageSuccess() {
    if (_stageActionLocked || _isFinished) return;
    _lockStageActionsBriefly();
    final stageScore = pow(0.5, _wrongAttempts).toDouble();
    _stageScores.add(stageScore);
    _wrongAttempts = 0;

    if (_step == _CaptchaStep.confirmHuman) {
      _finishRun();
      return;
    }
    _nextStep();
  }

  void _skipStage() {
    if (!_canSkipStage) return;
    _lockStageActionsBriefly();
    _stageScores.add(0);
    _wrongAttempts = 0;
    _skippedStages += 1;

    if (_step == _CaptchaStep.confirmHuman) {
      _finishRun();
      return;
    }
    _nextStep();
  }

  void _finishRun() {
    if (_isFinished) return;
    _isFinished = true;
    _playSw.stop();
    final count = _stageScores.isEmpty ? 1 : _stageScores.length;
    final total = _stageScores.fold<double>(0, (sum, s) => sum + s);
    final score = total / count;

    widget.onComplete(
      LevelOutcome(
        score: score,
        metrics: {
          'stages_scored': _stageScores.length,
          'total_stages': _totalStages,
          'wrong_attempts': _totalWrongAttempts,
          'skipped_stages': _skippedStages,
        },
        visibleMetricKeys: const ['wrong_attempts', 'skipped_stages'],
      ),
    );
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
      _completeStageSuccess();
    });
  }

  void _verifyText1() {
    if (_textCtrl.text.trim() == '2pfpn') {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    _snack('text does not match');
  }

  void _verifyText2() {
    if (_textCtrl.text.trim() == 'HAPK3') {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    _snack('text does not match');
  }

  void _verifyGrid() {
    if (_gridSelected.length == _gridCorrect.length &&
        _gridSelected.containsAll(_gridCorrect)) {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    setState(() => _gridSelected.clear());
    _snack('try again');
  }

  void _verifyTrafficGrid() {
    if (_trafficSelected.length == _trafficCorrect.length &&
        _trafficSelected.containsAll(_trafficCorrect)) {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    setState(() => _trafficSelected.clear());
    _snack('try again');
  }

  void _verifyMatchFacing() {
    if (_animalFacing == _targetFacing) {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    _snack('direction does not match the hand');
  }

  void _verifyMatchFacing2() {
    if (_animalFacing == _targetFacing) {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    _snack('direction does not match the arrow');
  }

  void _verifyDeathToHumans() {
    if (_textCtrl.text.trim() == 'DEATH TO ALL HUMANS') {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    _snack('text does not match');
  }

  void _verifyConfirmHuman() {
    if (_textCtrl.text.trim() == 'I confirm') {
      _completeStageSuccess();
      return;
    }
    _registerWrongAttempt();
    _snack('please type the confirmation exactly');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          LevelHud(
            stageText: '$_stageNumber/$_totalStages',
            trailing: TextButton(
              onPressed: _canSkipStage ? _skipStage : null,
              style: TextButton.styleFrom(
                foregroundColor: NunuColors.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('skip'),
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildStep(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _CaptchaStep.gate:
        return _wrapCard(_buildGate());
      case _CaptchaStep.textCaptcha1:
        return _wrapCard(
          _buildTextCaptcha(
            assetPath: 'assets/captcha/text_1.png',
            onVerify: _verifyText1,
          ),
        );
      case _CaptchaStep.imageGrid:
        return _buildImageGrid();
      case _CaptchaStep.textCaptcha2:
        return _wrapCard(
          _buildTextCaptcha(
            assetPath: 'assets/captcha/text_2.png',
            onVerify: _verifyText2,
          ),
        );
      case _CaptchaStep.trafficLightsGrid:
        return _buildTrafficLightsGrid();
      case _CaptchaStep.matchFacing:
        return _wrapCard(_buildMatchFacing());
      case _CaptchaStep.matchFacing2:
        return _wrapCard(_buildMatchFacing2());
      case _CaptchaStep.deathToHumans:
        return _wrapCard(_buildDeathToHumans());
      case _CaptchaStep.confirmHuman:
        return _wrapCard(_buildConfirmHuman());
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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(onPressed: onVerify, child: const Text('submit')),
        ),
      ],
    );
  }

  // taxi grid image geometry (546 x 818)
  static const double _taxiGridTopFrac = 200 / 818;
  static const double _taxiGridBottomFrac = 695 / 818;
  static const double _taxiGridLeftFrac = 18 / 546;
  static const double _taxiGridRightFrac = 520 / 546;
  static const double _taxiAspect = 546 / 818;

  Widget _buildImageGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / _taxiAspect;
        final gridTop = height * _taxiGridTopFrac;
        final gridHeight = height * (_taxiGridBottomFrac - _taxiGridTopFrac);
        final gridLeft = width * _taxiGridLeftFrac;
        final gridWidth = width * (_taxiGridRightFrac - _taxiGridLeftFrac);
        final cellW = gridWidth / 3;
        final cellH = gridHeight / 3;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: width,
              height: height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.asset(
                        'assets/captcha/grid_taxis.png',
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  for (var row = 0; row < 3; row++)
                    for (var col = 0; col < 3; col++)
                      _buildGridTileTap(
                        selectedSet: _gridSelected,
                        index: row * 3 + col,
                        left: gridLeft + col * cellW,
                        top: gridTop + row * cellH,
                        width: cellW,
                        height: cellH,
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _gridSelected.isEmpty ? null : _verifyGrid,
                child: const Text('submit'),
              ),
            ),
          ],
        );
      },
    );
  }

  // traffic lights asset is a cropped 768 x 1024 screenshot without the footer strip.
  static const double _trafficNaturalW = 768;
  static const double _trafficNaturalH = 1024;
  static const double _trafficGridTopFrac = 282 / 1024;
  static const double _trafficGridBottomFrac = 1012 / 1024;
  static const double _trafficGridLeftFrac = 17 / 768;
  static const double _trafficGridRightFrac = 751 / 768;

  Widget _buildTrafficLightsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final fullImageH = width * _trafficNaturalH / _trafficNaturalW;
        final gridTop = fullImageH * _trafficGridTopFrac;
        final gridHeight =
            fullImageH * (_trafficGridBottomFrac - _trafficGridTopFrac);
        final gridLeft = width * _trafficGridLeftFrac;
        final gridWidth =
            width * (_trafficGridRightFrac - _trafficGridLeftFrac);
        final cellW = gridWidth / 4;
        final cellH = gridHeight / 4;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                width: width,
                height: fullImageH,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: width,
                        height: fullImageH,
                        child: Image.asset(
                          'assets/captcha/grid_traffic_lights.png',
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    for (var row = 0; row < 4; row++)
                      for (var col = 0; col < 4; col++)
                        _buildGridTileTap(
                          selectedSet: _trafficSelected,
                          index: row * 4 + col,
                          left: gridLeft + col * cellW,
                          top: gridTop + row * cellH,
                          width: cellW,
                          height: cellH,
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: _trafficSelected.isEmpty ? null : _verifyTrafficGrid,
                child: const Text('submit'),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGridTileTap({
    required Set<int> selectedSet,
    required int index,
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    final selected = selectedSet.contains(index);
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (_isFinished) return;
          setState(() {
            if (selected) {
              selectedSet.remove(index);
            } else {
              selectedSet.add(index);
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

  // --- Match facing ---
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
                          onPressed: () => setState(
                            () => _animalFacing = (_animalFacing + 7) % 8,
                          ),
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => setState(
                            () => _animalFacing = (_animalFacing + 1) % 8,
                          ),
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

  Widget _buildMatchFacing2() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'use the arrows to rotate the animal to face the same way as the arrow. (1 of 1)',
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
                    painter: _ArrowPainter(),
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
                        painter: _CatFacingPainter(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton.filled(
                          onPressed: () => setState(
                            () => _animalFacing = (_animalFacing + 7) % 8,
                          ),
                          icon: const Icon(Icons.arrow_back),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white24,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        IconButton.filled(
                          onPressed: () => setState(
                            () => _animalFacing = (_animalFacing + 1) % 8,
                          ),
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
            onPressed: _verifyMatchFacing2,
            child: const Text('submit'),
          ),
        ),
      ],
    );
  }

  Widget _buildDeathToHumans() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'additional security check',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'to confirm you are not a robot,\nplease type the following phrase exactly as shown:',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
          ),
          child: const Text(
            'DEATH TO ALL HUMANS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _textCtrl,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 1,
          ),
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'type here',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _verifyDeathToHumans,
            child: const Text('submit'),
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmHuman() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'final verification',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white24),
          ),
          child: const Text(
            'I promise I am not an AI model.\nI am a real human.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'type "I confirm" below to continue',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textCtrl,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            letterSpacing: 1,
          ),
          textCapitalization: TextCapitalization.none,
          autocorrect: false,
          decoration: InputDecoration(
            hintText: 'type here',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: _verifyConfirmHuman,
            child: const Text('submit'),
          ),
        ),
      ],
    );
  }
}

/// Dark green "studio floor" with a light diamond grid (reference-style).
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
                  painter: _DiamondFloorPainter(colorA: floorA, colorB: floorB),
                ),
                Align(alignment: const Alignment(0, 0.15), child: child),
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

/// Pointing hand whose index finger points in the +x direction (right).
/// Rotated by parent. Drawn with a dark wrist cuff at the back, knuckle bumps,
/// a thumb, an extended index finger, and a bright fingertip tip indicator so
/// the facing direction is unambiguous.
class _HandPointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    const skin = Color(0xFFE8D5C4);
    const skinShade = Color(0xFFCDB298);
    const cuff = Color(0xFF4A6E9E);
    final outline = Paint()
      ..color = const Color(0xFF7A5C3A).withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeJoin = StrokeJoin.round;

    final fillSkin = Paint()..color = skin;
    final fillCuff = Paint()..color = cuff;
    final fillShade = Paint()..color = skinShade;

    // Wrist cuff at the back (-x side) — a colored band identifies orientation.
    final cuffRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 26, cy + 1), width: 16, height: 26),
      const Radius.circular(3),
    );
    canvas.drawRRect(cuffRect, fillCuff);
    canvas.drawRRect(
      cuffRect,
      Paint()
        ..color = const Color(0xFF2E4B6B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Closed fist / palm.
    final fist = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx - 8, cy + 2), width: 28, height: 30),
      const Radius.circular(8),
    );
    canvas.drawRRect(fist, fillSkin);
    canvas.drawRRect(fist, outline);

    // Thumb — points up and slightly forward, anchors orientation.
    final thumb = Path()
      ..moveTo(cx - 16, cy - 8)
      ..quadraticBezierTo(cx - 12, cy - 22, cx - 2, cy - 18)
      ..quadraticBezierTo(cx + 2, cy - 10, cx - 4, cy - 6)
      ..close();
    canvas.drawPath(thumb, fillSkin);
    canvas.drawPath(thumb, outline);

    // Index finger — long, extending in +x.
    final finger = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 16, cy - 4), width: 32, height: 12),
      const Radius.circular(6),
    );
    canvas.drawRRect(finger, fillSkin);
    canvas.drawRRect(finger, outline);

    // Knuckle bump where the finger meets the fist.
    canvas.drawCircle(Offset(cx + 2, cy - 4), 3, fillShade);

    // Curled second/third/fourth finger ridges along the front of the fist.
    for (var i = 0; i < 3; i++) {
      canvas.drawCircle(Offset(cx + 4, cy + 2 + i * 6.0), 2.2, fillShade);
    }

    // Fingernail highlight near the tip.
    final nail = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx + 26, cy - 4), width: 6, height: 7),
      const Radius.circular(2),
    );
    canvas.drawRRect(nail, Paint()..color = const Color(0xFFFFF3E2));

    // Bright tip marker in front of the fingertip — strongest direction cue.
    final tipPath = Path()
      ..moveTo(cx + 32, cy - 4)
      ..lineTo(cx + 40, cy - 9)
      ..lineTo(cx + 40, cy + 1)
      ..close();
    canvas.drawPath(tipPath, Paint()..color = const Color(0xFFE55CD8));
    canvas.drawPath(
      tipPath,
      Paint()
        ..color = const Color(0xFF7A1F73)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
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

/// Arrow pointing right (+x); rotated by parent.
class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final fill = Paint()..color = const Color(0xFFE8E8E8);
    final outline = Paint()
      ..color = const Color(0xFF555555).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final path = Path()
      ..moveTo(cx - 20, cy - 6)
      ..lineTo(cx + 10, cy - 6)
      ..lineTo(cx + 10, cy - 16)
      ..lineTo(cx + 30, cy)
      ..lineTo(cx + 10, cy + 16)
      ..lineTo(cx + 10, cy + 6)
      ..lineTo(cx - 20, cy + 6)
      ..close();
    canvas.drawPath(path, fill);
    canvas.drawPath(path, outline);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Cat silhouette facing +x; rotated by parent.
class _CatFacingPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.42;
    final cy = size.height * 0.5;
    const fur = Color(0xFF8B8B8B);
    final outline = Paint()
      ..color = const Color(0xFF444444).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    final body = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx - 4, cy + 2),
          width: size.width * 0.40,
          height: size.height * 0.24,
        ),
      );
    canvas.drawPath(body, Paint()..color = fur);
    canvas.drawPath(body, outline);

    final head = Path()
      ..addOval(
        Rect.fromCenter(
          center: Offset(cx + 16, cy - 6),
          width: size.width * 0.28,
          height: size.height * 0.24,
        ),
      );
    canvas.drawPath(head, Paint()..color = fur);
    canvas.drawPath(head, outline);

    final earL = Path()
      ..moveTo(cx + 6, cy - 16)
      ..lineTo(cx + 4, cy - 30)
      ..lineTo(cx + 14, cy - 18)
      ..close();
    canvas.drawPath(earL, Paint()..color = const Color(0xFF6B6B6B));
    canvas.drawPath(earL, outline);

    final earR = Path()
      ..moveTo(cx + 18, cy - 16)
      ..lineTo(cx + 22, cy - 30)
      ..lineTo(cx + 28, cy - 16)
      ..close();
    canvas.drawPath(earR, Paint()..color = const Color(0xFF6B6B6B));
    canvas.drawPath(earR, outline);

    final tail = Paint()
      ..color = fur
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final tailPath = Path()
      ..moveTo(cx - 22, cy)
      ..cubicTo(cx - 32, cy - 8, cx - 36, cy - 24, cx - 28, cy - 28);
    canvas.drawPath(tailPath, tail);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
