import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Four stages: age range, exact age, two decimals (last: value only while dragging). Ten lives; score = 20%/stage + 2%/life (win).
class LevelSliderSkills extends LevelWidget {
  const LevelSliderSkills({super.key, required super.onComplete});

  @override
  State<LevelSliderSkills> createState() => _LevelSliderSkillsState();
}

class _LevelSliderSkillsState extends State<LevelSliderSkills> {
  static const int _startingLives = 10;
  static const int _totalStages = 4;
  static const double _scorePerStage = 0.2;
  static const double _scorePerLife = 0.02;
  static const Color _subtleGrey = Color(0xFF9CA3AF);
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

  @override
  void initState() {
    super.initState();
    _randomizeTargets();
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

  void _fail() {
    final stageScore = _scoreFromStages(_stage);
    final lifeScore = _scoreFromLives(_lives);
    widget.onComplete(LevelOutcome(
      score: stageScore + lifeScore,
      metrics: {
        'submit_attempts': _submitAttempts,
        'stages_cleared': _stage,
        'lives_remaining': _lives,
        'score_from_stages': stageScore,
        'score_from_lives': lifeScore,
      },
    ));
  }

  void _advanceOrWin() {
    if (_stage >= 3) {
      final stageScore = _scoreFromStages(_totalStages);
      final lifeScore = _scoreFromLives(_lives);
      widget.onComplete(LevelOutcome(
        score: stageScore + lifeScore,
        metrics: {
          'submit_attempts': _submitAttempts,
          'stages_cleared': _totalStages,
          'lives_remaining': _lives,
          'score_from_stages': stageScore,
          'score_from_lives': lifeScore,
        },
      ));
      return;
    }
    setState(() => _stage++);
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
      default:
        return 'submit';
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

  Widget _livesRow() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 3,
      runSpacing: 4,
      children: List.generate(_startingLives, (i) {
        final alive = i < _lives;
        return Icon(
          alive ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 20,
          color: alive
              ? NunuColors.errorMain
              : _subtleGrey.withValues(alpha: 0.45),
        );
      }),
    );
  }

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
            Icon(
              Icons.cake_rounded,
              color: NunuColors.primaryMain,
              size: 40,
            ),
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
            Icon(
              icon,
              color: NunuColors.primaryMain,
              size: 40,
            ),
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _livesRow(),
          const SizedBox(height: 16),
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
      ),
    );
  }
}
