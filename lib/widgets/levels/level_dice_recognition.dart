import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/dice.dart';
import '../level_components/level_hud.dart';
import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

/// Per-stage config.
class _StageConfig {
  final int diceMin;
  final int diceMax;
  final int faceMin;
  final int faceMax;
  final bool mixSizes;
  final bool rotate;
  final List<int> requiredFaces;

  /// When set, the stage always uses exactly this many dice (overrides the
  /// diceMin/diceMax range). Used for the dense multi-row endgame stages.
  final int? fixedCount;

  const _StageConfig({
    this.diceMin = 0,
    this.diceMax = 0,
    this.faceMin = 1,
    this.faceMax = 6,
    this.mixSizes = false,
    this.rotate = false,
    this.requiredFaces = const [],
    this.fixedCount,
  });
}

class LevelDiceRecognition extends LevelWidget {
  const LevelDiceRecognition({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelDiceRecognition> createState() => _LevelDiceRecognitionState();
}

class _LevelDiceRecognitionState extends State<LevelDiceRecognition> {
  static const List<_StageConfig> _stages = [
    _StageConfig(diceMin: 4, diceMax: 5), // 1: warmup
    _StageConfig(diceMin: 5, diceMax: 6), // 2: more dice
    _StageConfig(diceMin: 5, diceMax: 7, mixSizes: true), // 3: mixed sizes
    _StageConfig(diceMin: 5, diceMax: 7, rotate: true), // 4: rotated
    _StageConfig(
      diceMin: 5,
      diceMax: 7,
      faceMax: 7,
      requiredFaces: [7],
    ), // 5: guaranteed 7-dot
    _StageConfig(
      diceMin: 5,
      diceMax: 8,
      faceMax: 7,
      mixSizes: true,
      rotate: true,
      requiredFaces: [7],
    ), // 6: 7-dot under chaos
    _StageConfig(
      diceMin: 5,
      diceMax: 8,
      faceMax: 9,
      mixSizes: true,
      requiredFaces: [7],
    ), // 7: 9s join the pool
    _StageConfig(
      diceMin: 6,
      diceMax: 8,
      faceMin: 4,
      faceMax: 9,
      mixSizes: true,
      rotate: true,
      requiredFaces: [7],
    ), // 8: dense endgame
    _StageConfig(fixedCount: 15), // 9: 15 dice, normal 1-6
    _StageConfig(fixedCount: 20), // 10: 20 dice, normal 1-6
    _StageConfig(
      fixedCount: 20,
      faceMax: 7,
      requiredFaces: [7],
    ), // 11: 20 dice, 1-7
    _StageConfig(fixedCount: 25), // 12: 25 dice, normal 1-6
    _StageConfig(
      fixedCount: 25,
      faceMax: 9,
      mixSizes: true,
      rotate: true,
      requiredFaces: [7, 9],
    ), // 13: 25 dice, 1-9, sizes + rotations
  ];

  final _rand = SeedService.instance.createRandom();
  final _controller = TextEditingController();

  int _stageIndex = 0;
  double _scoreAccum = 0;
  late List<_DieInfo> _dice;

  String? _feedbackText;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
      () => LevelOutcome(
        score: _scoreAccum.clamp(0.0, 1.0),
        metrics: {'stages_scored': _stageIndex},
      ),
    );
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
    final count =
        cfg.fixedCount ??
        (cfg.diceMin + _rand.nextInt(cfg.diceMax - cfg.diceMin + 1));

    // sizes are computed later in build based on available width;
    // store a relative scale factor per die (1.0 = base, mixed varies)
    _dice = List.generate(count, (_) {
      var value = cfg.faceMin + _rand.nextInt(cfg.faceMax - cfg.faceMin + 1);
      // there is no 8-dot die; the high face is the clean 3x3 nine.
      if (value == 8) value = 9;
      final scale = cfg.mixSizes
          ? ([0.65, 0.8, 1.0, 1.3]..shuffle(_rand)).first
          : 1.0;
      final angle = cfg.rotate
          ? (_rand.nextDouble() - 0.5) *
                1.2 // up to ~34°
          : 0.0;
      return _DieInfo(value: value, scale: scale, angle: angle);
    });

    _ensureRequiredFaces(cfg.requiredFaces);
  }

  void _ensureRequiredFaces(List<int> requiredFaces) {
    if (requiredFaces.isEmpty || _dice.isEmpty) return;

    final replaceableIndices = List.generate(_dice.length, (i) => i)
      ..shuffle(_rand);

    for (final face in requiredFaces) {
      final alreadyPresent = _dice.any((die) => die.value == face);
      if (alreadyPresent || replaceableIndices.isEmpty) continue;

      final index = replaceableIndices.removeLast();
      final die = _dice[index];
      _dice[index] = _DieInfo(value: face, scale: die.scale, angle: die.angle);
    }
  }

  String get _correctAnswer => _dice.map((d) => d.value).join();

  /// Number of dice per row. Small stages stay on a single row; dense stages
  /// flow into a clean grid that reads left-to-right, top-to-bottom.
  int get _columns {
    final n = _dice.length;
    if (n <= 8) return n;
    return 5;
  }

  void _submit() {
    if (_feedbackText != null) return;
    final answer = _controller.text.trim();
    if (answer.isEmpty) {
      _showSnack('enter the dice numbers');
      return;
    }

    // score: fraction of dice digits correct left-to-right
    final correct = _correctAnswer;
    int matched = 0;
    for (int i = 0; i < min(answer.length, correct.length); i++) {
      if (answer[i] == correct[i]) matched++;
    }
    final accuracy = correct.isEmpty ? 0.0 : matched / correct.length;
    final stageScore = accuracy * accuracy;
    _scoreAccum += stageScore / _stages.length;

    late final String feedback;
    late final Color feedbackCol;
    if (stageScore == 1.0) {
      feedback = 'exact!';
      feedbackCol = NunuColors.successMain;
    } else if (stageScore >= 0.5) {
      feedback = '$matched/${correct.length} correct (was $correct)';
      feedbackCol = NunuColors.warningMain;
    } else {
      feedback = 'wrong — was $correct';
      feedbackCol = NunuColors.errorMain;
    }

    setState(() {
      _feedbackText = feedback;
      _feedbackColor = feedbackCol;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_stageIndex + 1 >= _stages.length) {
        widget.onComplete(
          LevelOutcome(
            score: _scoreAccum.clamp(0, 1).toDouble(),
            metrics: {'total_stages': _stages.length},
          ),
        );
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
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(stageText: '${_stageIndex + 1}/${_stages.length}'),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // instruction
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: NunuColors.primaryMain.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: NunuColors.primaryMain.withOpacity(0.5),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.casino_outlined,
                              color: NunuColors.primaryMain,
                              size: 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'enter the numbers left to right, top to bottom',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // dice display — laid out left-to-right, top-to-bottom
                      LayoutBuilder(
                        builder: (context, constraints) {
                          const padding = 12.0 * 2;
                          const spacing = 8.0;
                          final cols = _columns;
                          final availableWidth = constraints.maxWidth - padding;
                          // rotation makes a square of side s take up s*sqrt(2) at 45°;
                          // approximate max expansion factor from the largest scale + angle
                          final maxScale = _dice.fold<double>(
                            1.0,
                            (m, d) => max(m, d.scale),
                          );
                          final maxAngle = _dice.fold<double>(
                            0.0,
                            (m, d) => max(m, d.angle.abs()),
                          );
                          // rotated bounding box width for a square: s*(cos+sin)
                          final rotExpand = cos(maxAngle) + sin(maxAngle);
                          final effectiveSlots = cols * maxScale * rotExpand;
                          final baseSize =
                              ((availableWidth - spacing * (cols - 1)) /
                                      effectiveSlots)
                                  .clamp(20.0, 70.0);

                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade800.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: spacing,
                              runSpacing: spacing,
                              children: [
                                for (int i = 0; i < _dice.length; i++)
                                  Builder(
                                    builder: (_) {
                                      final d = _dice[i];
                                      final size = (baseSize * d.scale).clamp(
                                        20.0,
                                        80.0,
                                      );
                                      Widget die = DiceWidget(
                                        value: d.value,
                                        size: size,
                                      );
                                      if (d.angle != 0) {
                                        die = Transform.rotate(
                                          angle: d.angle,
                                          child: die,
                                        );
                                      }
                                      // give the rotated die enough space
                                      final expand =
                                          cos(d.angle.abs()) +
                                          sin(d.angle.abs());
                                      final boxSize = size * expand;
                                      return SizedBox(
                                        width: boxSize,
                                        height: boxSize,
                                        child: Center(child: die),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // feedback overlay
                      if (_feedbackText != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: _feedbackColor!.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _feedbackText!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // input
                      Builder(
                        builder: (_) {
                          final manyDigits = _dice.length > 9;
                          final inputFontSize = manyDigits ? 16.0 : 24.0;
                          final inputSpacing = manyDigits ? 3.0 : 10.0;
                          return Container(
                            constraints: BoxConstraints(
                              maxWidth: manyDigits ? 340 : 260,
                            ),
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _controller,
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  maxLength: _dice.length,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: inputFontSize,
                                    letterSpacing: inputSpacing,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    counterText: '',
                                    hintText: '•' * _dice.length,
                                    hintStyle: TextStyle(
                                      color: Colors.grey.shade600,
                                      letterSpacing: inputSpacing,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide(
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(
                                        color: NunuColors.primaryMain,
                                        width: 2,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                  ),
                                  onFieldSubmitted: (_) => _submit(),
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: _feedbackText != null
                                      ? null
                                      : _submit,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 40,
                                      vertical: 14,
                                    ),
                                    backgroundColor: NunuColors.primaryMain,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    'submit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      Text(
                        'example: if dice show 3, 1, 5 enter "315"',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DieInfo {
  final int value;
  final double scale; // relative to computed base size
  final double angle;
  const _DieInfo({
    required this.value,
    required this.scale,
    required this.angle,
  });
}
