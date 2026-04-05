import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Three stages: target age, then two decimal sliders. No on-screen attempt stats.
class LevelSliderSkills extends LevelWidget {
  const LevelSliderSkills({super.key, required super.onComplete});

  @override
  State<LevelSliderSkills> createState() => _LevelSliderSkillsState();
}

class _LevelSliderSkillsState extends State<LevelSliderSkills> {
  static const int maxWrongSubmits = 20;
  final Random _rng = Random();

  int _stage = 0;
  int _submitAttempts = 0;

  double _age = 21;
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
    _targetAge = 21 + _rng.nextInt(45);
    _tDec1 = (3 + _rng.nextDouble() * 50) / 10;
    _tDec1 = (_tDec1 * 10).round() / 10;
    _tDec2 = (3 + _rng.nextDouble() * 50) / 10;
    _tDec2 = (_tDec2 * 10).round() / 10;
  }

  void _fail() {
    widget.onComplete(LevelOutcome(
      score: 0,
      metrics: {
        'submit_attempts': _submitAttempts,
        'stages_cleared': _stage,
      },
    ));
  }

  void _advanceOrWin() {
    if (_stage >= 2) {
      widget.onComplete(LevelOutcome(
        score: 1,
        metrics: {
          'submit_attempts': _submitAttempts,
          'stages_cleared': 3,
        },
      ));
      return;
    }
    setState(() => _stage++);
  }

  bool _closeEnough(double a, double b, double tol) => (a - b).abs() <= tol;

  void _submit() {
    _submitAttempts++;
    if (_submitAttempts > maxWrongSubmits) {
      _fail();
      return;
    }

    bool ok = false;
    switch (_stage) {
      case 0:
        ok = _age.round() == _targetAge;
        break;
      case 1:
        ok = _closeEnough(_vDec1, _tDec1, 0.11);
        break;
      case 2:
        ok = _closeEnough(_vDec2, _tDec2, 0.11);
        break;
    }

    if (ok) {
      _advanceOrWin();
    } else {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'try again',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: NunuColors.errorMain,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_stage == 0) ..._buildAge(),
          if (_stage == 1) ..._buildDec(_vDec1, _tDec1, (v) => _vDec1 = v),
          if (_stage == 2) ..._buildDec(_vDec2, _tDec2, (v) => _vDec2 = v),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _submit,
            style: FilledButton.styleFrom(
              backgroundColor: NunuColors.primaryMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'submit',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAge() {
    return [
      _targetBox('set your age to exactly $_targetAge'),
      SliderTheme(
        data: SliderThemeData(
          activeTrackColor: NunuColors.primaryMain,
          inactiveTrackColor: Colors.grey.shade700,
          thumbColor: NunuColors.primaryLight,
          overlayColor: NunuColors.primaryMain.withValues(alpha: 0.2),
          trackHeight: 6,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
        ),
        child: Slider(
          value: _age.clamp(13, 99),
          min: 13,
          max: 99,
          divisions: 86,
          label: _age.round().toString(),
          onChanged: (v) => setState(() => _age = v),
        ),
      ),
    ];
  }

  List<Widget> _buildDec(
    double value,
    double target,
    void Function(double) onChanged,
  ) {
    return [
      _targetBox('set slider to ${target.toStringAsFixed(1)} (0.0–10.0)'),
      Slider(
        value: value.clamp(0, 10),
        min: 0,
        max: 10,
        divisions: 100,
        label: value.toStringAsFixed(1),
        onChanged: (v) => setState(() => onChanged(v)),
      ),
    ];
  }

  Widget _targetBox(String text) {
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NunuColors.primaryMain.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NunuColors.primaryMain.withValues(alpha: 0.5)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: NunuColors.primaryLight,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
