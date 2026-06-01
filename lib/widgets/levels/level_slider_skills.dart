import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

/// Five stages: age range, exact age, two decimals, then reactor stabilization.
/// Ten lives; score = 16%/stage + 2%/life on a full clear.
class LevelSliderSkills extends LevelWidget {
  const LevelSliderSkills({super.key, required super.onComplete});

  @override
  State<LevelSliderSkills> createState() => _LevelSliderSkillsState();
}

class _LevelSliderSkillsState extends State<LevelSliderSkills> {
  static const int _startingLives = 10;
  static const int _totalStages = 5;
  static const double _scorePerStage = 0.16;
  static const double _scorePerLife = 0.02;
  static const Color _subtleGrey = Color(0xFF9CA3AF);
  static const double _reactorTargetMin = 0.45;
  static const double _reactorTargetMax = 0.55;
  final Random _rng = Random();

  int _stage = 0;
  int _submitAttempts = 0;
  int _lives = _startingLives;

  double _age = 21;
  late int _rangeLow;
  late int _rangeHigh;
  late int _targetAge;

  double _vDec1 = 5;
  late double _tDec1;

  double _vDec2 = 5;
  late double _tDec2;
  double _rodA = 0.0;
  double _rodB = 0.0;
  double _rodC = 0.0;
  double _stability = 0.0;
  Timer? _stabilityTimer;

  @override
  void initState() {
    super.initState();
    _randomizeTargets();
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    super.dispose();
  }

  void _randomizeTargets() {
    final width = 8 + _rng.nextInt(7);
    final maxLow = 99 - width;
    _rangeLow = 13 + _rng.nextInt(maxLow - 13 + 1);
    _rangeHigh = _rangeLow + width;

    _targetAge = 21 + _rng.nextInt(45);
    _tDec1 = (3 + _rng.nextDouble() * 50) / 10;
    _tDec1 = (_tDec1 * 10).round() / 10;
    _tDec2 = (3 + _rng.nextDouble() * 50) / 10;
    _tDec2 = (_tDec2 * 10).round() / 10;
  }

  double _scoreFromStages(int completedStages) =>
      completedStages.clamp(0, _totalStages) * _scorePerStage;

  double _scoreFromLives(int lives) =>
      lives.clamp(0, _startingLives) * _scorePerLife;

  double get _temp => (_rodA * 0.6 + _rodB * 0.4 - 0.06).clamp(0.0, 1.0);
  double get _pressure => (_rodB * 0.4 + _rodC * 0.6 + 0.12).clamp(0.0, 1.0);
  double get _output => (_rodA * 0.3 + _rodC * 0.7 - 0.09).clamp(0.0, 1.0);

  bool _isStable(double value) =>
      value >= _reactorTargetMin && value <= _reactorTargetMax;

  void _startReactorStage() {
    _stabilityTimer?.cancel();
    _stability = 0.0;
    _rodA = 0.0;
    _rodB = 0.0;
    _rodC = 0.0;
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 50), (_) {
      if (!mounted || _stage != 4) return;
      final stable =
          _isStable(_temp) && _isStable(_pressure) && _isStable(_output);

      setState(() {
        if (stable) {
          _stability += 0.02;
        } else {
          _stability -= 0.05;
        }
        _stability = _stability.clamp(0.0, 1.0);
      });

      if (_stability >= 1.0) {
        _stabilityTimer?.cancel();
        _advanceOrWin();
      }
    });
  }

  void _fail() {
    final stageScore = _scoreFromStages(_stage);
    final lifeScore = _scoreFromLives(_lives);
    widget.onComplete(
      LevelOutcome(
        score: stageScore + lifeScore,
        metrics: {
          'submit_attempts': _submitAttempts,
          'stages_cleared': _stage,
          'lives_remaining': _lives,
        },
      ),
    );
  }

  void _advanceOrWin() {
    if (_stage >= _totalStages - 1) {
      _stabilityTimer?.cancel();
      final stageScore = _scoreFromStages(_totalStages);
      final lifeScore = _scoreFromLives(_lives);
      widget.onComplete(
        LevelOutcome(
          score: stageScore + lifeScore,
          metrics: {
            'submit_attempts': _submitAttempts,
            'stages_cleared': _totalStages,
            'lives_remaining': _lives,
          },
        ),
      );
      return;
    }
    setState(() => _stage++);
    if (_stage == 4) {
      _startReactorStage();
    }
  }

  bool _closeEnough(double a, double b, double tol) => (a - b).abs() <= tol;

  void _submit() {
    _submitAttempts++;

    final r = _age.round();
    bool ok = false;
    switch (_stage) {
      case 0:
        ok = r >= _rangeLow && r <= _rangeHigh;
        break;
      case 1:
        ok = r == _targetAge;
        break;
      case 2:
        ok = _closeEnough(_vDec1, _tDec1, 0.11);
        break;
      case 3:
        ok = _closeEnough(_vDec2, _tDec2, 0.11);
        break;
    }

    if (ok) {
      _advanceOrWin();
    } else {
      _lives--;
      if (_lives <= 0) {
        _fail();
        return;
      }
      setState(() {});
    }
  }

  String get _primaryButtonLabel {
    switch (_stage) {
      case 0:
        return 'confirm range';
      case 1:
        return 'confirm age';
      case 2:
      case 3:
        return 'submit';
      default:
        return '';
    }
  }

  SliderThemeData get _ageSliderTheme => SliderThemeData(
    activeTrackColor: NunuColors.primaryMain,
    inactiveTrackColor: Colors.grey.shade700,
    thumbColor: NunuColors.primaryMain,
    overlayColor: NunuColors.primaryMain.withValues(alpha: 0.2),
    trackHeight: 5,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
  );

  SliderThemeData get _decimalSliderTheme => SliderThemeData(
    activeTrackColor: NunuColors.primaryMain,
    inactiveTrackColor: Colors.grey.shade700,
    thumbColor: NunuColors.primaryMain,
    overlayColor: NunuColors.primaryMain.withValues(alpha: 0.2),
    trackHeight: 5,
    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 16),
    showValueIndicator: ShowValueIndicator.onDrag,
  );

  Widget _hintLine(String text) {
    return Text(
      text,
      style: TextStyle(
        color: _subtleGrey.withValues(alpha: 0.95),
        fontSize: 14,
        height: 1.35,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _yourAgeCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade600, width: 1),
      ),
      child: Center(
        child: Text(
          '${_age.round()}',
          style: const TextStyle(
            color: NunuColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            height: 1,
          ),
        ),
      ),
    );
  }

  Widget _ageSliderInPanel() {
    final sliderGrey = Colors.grey.shade800;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
      decoration: BoxDecoration(
        color: sliderGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SliderTheme(
            data: _ageSliderTheme,
            child: Slider(
              value: _age.clamp(13, 99),
              min: 13,
              max: 99,
              divisions: 86,
              onChanged: (v) => setState(() => _age = v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '13',
                  style: TextStyle(
                    color: _subtleGrey.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
                Text(
                  '99',
                  style: TextStyle(
                    color: _subtleGrey.withValues(alpha: 0.85),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAgeRange() {
    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NunuColors.primaryMain, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(
              Icons.date_range_rounded,
              color: NunuColors.primaryMain,
              size: 40,
            ),
            const SizedBox(height: 12),
            Text(
              '$_rangeLow  –  $_rangeHigh',
              style: const TextStyle(
                color: NunuColors.primaryMain,
                fontSize: 40,
                fontWeight: FontWeight.w800,
                height: 1,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _yourAgeCard(),
      const SizedBox(height: 20),
      _ageSliderInPanel(),
    ];
  }

  List<Widget> _buildExactAge() {
    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NunuColors.primaryMain, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(Icons.cake_rounded, color: NunuColors.primaryMain, size: 40),
            const SizedBox(height: 12),
            Text(
              '$_targetAge',
              style: const TextStyle(
                color: NunuColors.primaryMain,
                fontSize: 52,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _yourAgeCard(),
      const SizedBox(height: 20),
      _ageSliderInPanel(),
    ];
  }

  List<Widget> _buildDecimalStage(
    double value,
    double target,
    void Function(double) onChanged, {
    String? hint,
    required IconData icon,
    String? targetLabel,
    String? scaleCaption,
    required bool showPersistentValueCard,
    String? valueCardHeading,
    SliderInteraction? allowedInteraction,
  }) {
    final sliderGrey = Colors.grey.shade800;
    return [
      if (hint != null && hint.isNotEmpty) ...[
        _hintLine(hint),
        const SizedBox(height: 20),
      ],
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NunuColors.primaryMain, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: NunuColors.primaryMain, size: 40),
            if (targetLabel != null && targetLabel.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                targetLabel,
                style: TextStyle(
                  color: _subtleGrey.withValues(alpha: 0.9),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
            ] else
              const SizedBox(height: 12),
            Text(
              target.toStringAsFixed(1),
              style: const TextStyle(
                color: NunuColors.primaryMain,
                fontSize: 52,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            if (scaleCaption != null && scaleCaption.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                scaleCaption,
                style: TextStyle(
                  color: _subtleGrey.withValues(alpha: 0.75),
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
      if (showPersistentValueCard) ...[
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade600, width: 1),
          ),
          child: Column(
            children: [
              if (valueCardHeading != null && valueCardHeading.isNotEmpty) ...[
                Text(
                  valueCardHeading,
                  style: TextStyle(
                    color: _subtleGrey.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
              ],
              Text(
                value.toStringAsFixed(1),
                style: const TextStyle(
                  color: NunuColors.textPrimary,
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ],
      const SizedBox(height: 20),
      Container(
        padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
        decoration: BoxDecoration(
          color: sliderGrey,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            SliderTheme(
              data: _decimalSliderTheme,
              child: Slider(
                value: value.clamp(0, 10),
                min: 0,
                max: 10,
                divisions: 100,
                label: value.toStringAsFixed(1),
                allowedInteraction:
                    allowedInteraction ?? SliderInteraction.tapAndSlide,
                onChanged: (v) => setState(() => onChanged(v)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '0.0',
                    style: TextStyle(
                      color: _subtleGrey.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '10.0',
                    style: TextStyle(
                      color: _subtleGrey.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _reactorGauge(String label, double value, Color color) {
    final bool isInZone = _isStable(value);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40,
          height: 160,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(
                child: Container(
                  width: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade800),
                  ),
                ),
              ),
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final h = constraints.maxHeight;
                    return Stack(
                      children: [
                        Positioned(
                          top: (1 - _reactorTargetMax) * h,
                          height: (_reactorTargetMax - _reactorTargetMin) * h,
                          left: 2,
                          right: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: NunuColors.successMain.withValues(
                                alpha: 0.26,
                              ),
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color: NunuColors.successMain.withValues(
                                    alpha: 0.8,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 18,
                            height: h * value,
                            decoration: BoxDecoration(
                              color: isInZone ? NunuColors.successMain : color,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: isInZone ? NunuColors.successMain : NunuColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _reactorRod(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 72,
          height: 220,
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 18,
                activeTrackColor: Colors.grey.shade700,
                inactiveTrackColor: Colors.black,
                thumbColor: NunuColors.primaryMain,
                overlayColor: NunuColors.primaryMain.withValues(alpha: 0.18),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 13),
              ),
              child: Slider(
                value: value,
                onChanged: (v) => setState(() => onChanged(v)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: NunuColors.textPrimary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildReactorStage() {
    return [
      _hintLine('keep all three readings in the green zone to stabilize'),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NunuColors.primaryMain, width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _reactorGauge('temp', _temp, NunuColors.errorMain),
                const SizedBox(width: 12),
                _reactorGauge('pressure', _pressure, NunuColors.warningMain),
                const SizedBox(width: 12),
                _reactorGauge('output', _output, NunuColors.secondaryMain),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'system stability',
                  style: TextStyle(
                    color: _stability > 0
                        ? NunuColors.successMain
                        : NunuColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '${(_stability * 100).toInt()}%',
                  style: TextStyle(
                    color: _stability > 0
                        ? NunuColors.successMain
                        : NunuColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _stability,
              minHeight: 10,
              backgroundColor: Colors.grey.shade900,
              color: NunuColors.successMain,
              borderRadius: BorderRadius.circular(999),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.grey.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SizedBox(
          height: 280,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _reactorRod('alpha', _rodA, (v) => _rodA = v),
              const SizedBox(width: 12),
              _reactorRod('beta', _rodB, (v) => _rodB = v),
              const SizedBox(width: 12),
              _reactorRod('gamma', _rodC, (v) => _rodC = v),
            ],
          ),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LevelHud(
          stageText: '${_stage + 1}/$_totalStages',
          lives: LevelHud.emojiLives(_lives, _startingLives),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_stage == 0) ..._buildAgeRange(),
                if (_stage == 1) ..._buildExactAge(),
                if (_stage == 2)
                  ..._buildDecimalStage(
                    _vDec1,
                    _tDec1,
                    (v) => _vDec1 = v,
                    icon: Icons.tune_rounded,
                    showPersistentValueCard: true,
                    valueCardHeading: null,
                    allowedInteraction: SliderInteraction.slideOnly,
                  ),
                if (_stage == 3)
                  ..._buildDecimalStage(
                    _vDec2,
                    _tDec2,
                    (v) => _vDec2 = v,
                    icon: Icons.linear_scale_rounded,
                    showPersistentValueCard: false,
                  ),
                if (_stage == 4) ..._buildReactorStage(),
                if (_stage != 4) ...[
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: NunuColors.primaryMain,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _primaryButtonLabel,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
