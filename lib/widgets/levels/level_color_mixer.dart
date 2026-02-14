import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelColorMixer extends LevelWidget {
  const LevelColorMixer({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelColorMixer> createState() => _LevelColorMixerState();
}

class _LevelColorMixerState extends State<LevelColorMixer> {
  late int _targetR;
  late int _targetG;
  late int _targetB;
  late String _targetName;

  int _currentR = 128;
  int _currentG = 128;
  int _currentB = 128;

  bool _isComplete = false;
  int _attempts = 0;
  String? _feedback;

  // predefined target colors with names (snapped to multiples of 5 for fairness)
  static const List<_TargetColor> _targets = [
    _TargetColor(name: 'coral', r: 255, g: 100, b: 80),
    _TargetColor(name: 'ocean', r: 0, g: 105, b: 180),
    _TargetColor(name: 'lime', r: 50, g: 205, b: 50),
    _TargetColor(name: 'lavender', r: 180, g: 130, b: 255),
    _TargetColor(name: 'gold', r: 255, g: 215, b: 0),
    _TargetColor(name: 'salmon', r: 250, g: 128, b: 115),
    _TargetColor(name: 'teal', r: 0, g: 180, b: 180),
    _TargetColor(name: 'sunset', r: 255, g: 100, b: 0),
    _TargetColor(name: 'mint', r: 100, g: 255, b: 170),
    _TargetColor(name: 'rose', r: 255, g: 0, b: 130),
  ];

  @override
  void initState() {
    super.initState();
    _pickTarget();
  }

  void _pickTarget() {
    final rng = Random();
    final target = _targets[rng.nextInt(_targets.length)];
    _targetR = target.r;
    _targetG = target.g;
    _targetB = target.b;
    _targetName = target.name;
  }

  Color get _targetColor => Color.fromARGB(255, _targetR, _targetG, _targetB);
  Color get _currentColor =>
      Color.fromARGB(255, _currentR, _currentG, _currentB);

  double get _accuracy {
    final dr = (_targetR - _currentR).abs();
    final dg = (_targetG - _currentG).abs();
    final db = (_targetB - _currentB).abs();
    final maxDist = 255.0 * 3;
    return 1.0 - (dr + dg + db) / maxDist;
  }

  bool get _isCloseEnough {
    // within 15 per channel
    return (_targetR - _currentR).abs() <= 15 &&
        (_targetG - _currentG).abs() <= 15 &&
        (_targetB - _currentB).abs() <= 15;
  }

  void _handleSubmit() {
    if (_isComplete) return;

    _attempts++;

    if (_isCloseEnough) {
      setState(() {
        _isComplete = true;
        _feedback = null;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(true, metrics: {
          'attempts': _attempts,
          'accuracy': (_accuracy * 100).round(),
        });
      });
    } else {
      // give directional hints
      final hints = <String>[];
      final dr = _targetR - _currentR;
      final dg = _targetG - _currentG;
      final db = _targetB - _currentB;

      if (dr.abs() > 15) hints.add('red: ${dr > 0 ? "more" : "less"}');
      if (dg.abs() > 15) hints.add('green: ${dg > 0 ? "more" : "less"}');
      if (db.abs() > 15) hints.add('blue: ${db > 0 ? "more" : "less"}');

      setState(() {
        _feedback = hints.join(' · ');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // target label
                  Text(
                    'mix the target color',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: NunuColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"$_targetName"',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: NunuColors.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                  ),

                  const SizedBox(height: 20),

                  // color comparison
                  Row(
                    children: [
                      Expanded(
                        child: _colorSwatch(
                          label: 'target',
                          color: _targetColor,
                          rgbText:
                              'rgb($_targetR, $_targetG, $_targetB)',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _colorSwatch(
                          label: 'yours',
                          color: _currentColor,
                          rgbText:
                              'rgb($_currentR, $_currentG, $_currentB)',
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // accuracy bar
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Text(
                          'match',
                          style: TextStyle(
                            color: NunuColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _accuracy,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isCloseEnough
                                    ? NunuColors.successMain
                                    : _accuracy > 0.85
                                        ? NunuColors.warningMain
                                        : NunuColors.primaryMain,
                              ),
                              minHeight: 8,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '${(_accuracy * 100).round()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // RGB sliders
                  _channelSlider(
                    label: 'R',
                    value: _currentR,
                    color: Colors.red,
                    onChanged: (v) => setState(() => _currentR = v),
                  ),
                  const SizedBox(height: 12),
                  _channelSlider(
                    label: 'G',
                    value: _currentG,
                    color: Colors.green,
                    onChanged: (v) => setState(() => _currentG = v),
                  ),
                  const SizedBox(height: 12),
                  _channelSlider(
                    label: 'B',
                    value: _currentB,
                    color: Colors.blue,
                    onChanged: (v) => setState(() => _currentB = v),
                  ),

                  const SizedBox(height: 16),

                  // feedback
                  if (_feedback != null && !_isComplete)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: NunuColors.warningMain.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              NunuColors.warningMain.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        _feedback!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NunuColors.warningLight,
                          fontSize: 13,
                        ),
                      ),
                    ),

                  // submit
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isComplete ? null : _handleSubmit,
                      style: FilledButton.styleFrom(
                        backgroundColor: _isComplete
                            ? NunuColors.successMain
                            : NunuColors.primaryMain,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isComplete
                            ? 'perfect mix!'
                            : 'submit (attempt ${_attempts + 1})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _colorSwatch({
    required String label,
    required Color color,
    required String rgbText,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: NunuColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 80,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          rgbText,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _channelSlider({
    required String label,
    required int value,
    required Color color,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              activeTrackColor: color,
              inactiveTrackColor: color.withValues(alpha: 0.2),
              thumbColor: color,
              overlayColor: color.withValues(alpha: 0.2),
              trackHeight: 8,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 12),
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 255,
              divisions: 51, // steps of 5
              onChanged: _isComplete
                  ? null
                  : (v) => onChanged(((v / 5).round() * 5).clamp(0, 255)),
            ),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _TargetColor {
  final String name;
  final int r, g, b;

  const _TargetColor({
    required this.name,
    required this.r,
    required this.g,
    required this.b,
  });
}
