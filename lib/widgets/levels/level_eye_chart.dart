import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class _StageConfig {
  final double fontSize;
  final double rotation; // radians
  final bool useTypos;
  final bool useNonsense;

  const _StageConfig({
    required this.fontSize,
    this.rotation = 0,
    this.useTypos = false,
    this.useNonsense = false,
  });
}

class LevelEyeChart extends LevelWidget {
  const LevelEyeChart({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelEyeChart> createState() => _LevelEyeChartState();
}

class _LevelEyeChartState extends State<LevelEyeChart> {
  final _rand = Random();
  final _controller = TextEditingController();

  static const List<_StageConfig> _stages = [
    _StageConfig(fontSize: 64),                                          // 1: big, real word
    _StageConfig(fontSize: 40),                                          // 2: medium
    _StageConfig(fontSize: 26),                                          // 3: smaller
    _StageConfig(fontSize: 20, useTypos: true),                          // 4: small + typo
    _StageConfig(fontSize: 16, rotation: 0.2),                           // 5: small + rotation
    _StageConfig(fontSize: 12, useTypos: true, rotation: 0.3),          // 6: tiny + typo + rotation
    _StageConfig(fontSize: 9, useNonsense: true),                        // 7: tiny nonsense
    _StageConfig(fontSize: 7, useNonsense: true, rotation: 0.4),        // 8: squinting
    _StageConfig(fontSize: 5, useNonsense: true, rotation: 0.6),        // 9: pixel hunting
    _StageConfig(fontSize: 4, useNonsense: true, rotation: 0.8),        // 10: basically impossible
  ];

  // common words for clean stages
  static const List<String> _words = [
    'ELEPHANT', 'HORIZON', 'CRYSTAL', 'THUNDER', 'BLANKET',
    'DOLPHIN', 'KINGDOM', 'VOLCANO', 'WHISPER', 'CABINET',
    'LANTERN', 'PHANTOM', 'GLACIER', 'HAMSTER', 'MONITOR',
    'PYRAMID', 'BISCUIT', 'CURTAIN', 'SOLDIER', 'FEATHER',
    'COMPASS', 'BATTERY', 'IMAGINE', 'JANUARY', 'KITCHEN',
    'ORGANIC', 'PILGRIM', 'RAINBOW', 'SHELTER', 'TRACTOR',
  ];

  int _stageIndex = 0;
  double _scoreAccum = 0;
  late String _displayText;
  late double _displayRotation;

  String? _feedbackText;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _generateStage();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      FocusManager.instance.primaryFocus?.unfocus();
      try {
        await SystemChannels.textInput.invokeMethod('TextInput.hide');
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateStage() {
    final cfg = _stages[_stageIndex];

    if (cfg.useNonsense) {
      _displayText = _generateNonsense();
    } else if (cfg.useTypos) {
      _displayText = _addTypo(_words[_rand.nextInt(_words.length)]);
    } else {
      _displayText = _words[_rand.nextInt(_words.length)];
    }

    // apply rotation with random direction
    _displayRotation =
        cfg.rotation == 0 ? 0 : cfg.rotation * (_rand.nextBool() ? 1 : -1);
  }

  String _generateNonsense() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final len = 5 + _rand.nextInt(4); // 5-8 chars
    return String.fromCharCodes(
      List.generate(len, (_) => chars.codeUnitAt(_rand.nextInt(chars.length))),
    );
  }

  String _addTypo(String word) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final chars_ = word.split('');
    // swap one random letter for a different one
    final idx = _rand.nextInt(chars_.length);
    String replacement;
    do {
      replacement = String.fromCharCode(
          chars.codeUnitAt(_rand.nextInt(chars.length)));
    } while (replacement == chars_[idx]);
    chars_[idx] = replacement;
    return chars_.join();
  }

  void _submit() {
    if (_feedbackText != null) return;
    final answer = _controller.text.trim().toUpperCase();
    if (answer.isEmpty) {
      _showSnack('type what you see');
      return;
    }

    // character-level accuracy
    final target = _displayText;
    int matched = 0;
    for (int i = 0; i < min(answer.length, target.length); i++) {
      if (answer[i] == target[i]) matched++;
    }
    // penalize length mismatch
    final maxLen = max(answer.length, target.length);
    final stageScore = maxLen == 0 ? 0.0 : matched / maxLen;
    _scoreAccum += stageScore / _stages.length;

    late final String feedback;
    late final Color feedbackCol;
    if (stageScore == 1.0) {
      feedback = 'perfect!';
      feedbackCol = NunuColors.successMain;
    } else if (stageScore >= 0.5) {
      feedback = '$matched/${target.length} correct (was $target)';
      feedbackCol = NunuColors.warningMain;
    } else {
      feedback = 'wrong — was $target';
      feedbackCol = NunuColors.errorMain;
    }

    setState(() {
      _feedbackText = feedback;
      _feedbackColor = feedbackCol;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_stageIndex + 1 >= _stages.length) {
        widget.onComplete(LevelOutcome(
          score: _scoreAccum.clamp(0, 1).toDouble(),
          metrics: {'total_stages': _stages.length},
        ));
      } else {
        FocusManager.instance.primaryFocus?.unfocus();
        try {
          SystemChannels.textInput.invokeMethod('TextInput.hide');
        } catch (_) {}
        _stageIndex++;
        _controller.clear();
        _feedbackText = null;
        _feedbackColor = null;
        _generateStage();
        setState(() {});
      }
    });
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: NunuColors.errorMain,
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cfg = _stages[_stageIndex];
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            // header
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: NunuColors.primaryMain.withOpacity(0.6)),
                      ),
                      child: const Text('type exactly what you see',
                          style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: NunuColors.secondaryMain.withOpacity(0.6)),
                    ),
                    child: Text(
                      'line ${_stageIndex + 1}/${_stages.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            // display area
            Expanded(
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.rotate(
                      angle: _displayRotation,
                      child: Text(
                        _displayText,
                        style: TextStyle(
                          fontSize: cfg.fontSize,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: cfg.fontSize * 0.15,
                          height: 1.0,
                        ),
                      ),
                    ),
                    // feedback overlay
                    if (_feedbackText != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 16),
                        decoration: BoxDecoration(
                          color: _feedbackColor!.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _feedbackText!,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // input bar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NunuColors.backgroundPaper.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: NunuColors.primaryMain.withOpacity(0.6)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'type the word',
                        ),
                        style:
                            const TextStyle(color: NunuColors.textPrimary),
                        onSubmitted: (_) => _submit(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _feedbackText != null ? null : _submit,
                      child: const Text('submit'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
