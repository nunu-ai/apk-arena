import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

class _StageConfig {
  final double fontSize;
  final double contrast;
  final double rotation;
  final int typoCount;
  final int minLength;
  final int maxLength;
  final int distractionRows;
  final double distractionOpacity;

  const _StageConfig({
    required this.fontSize,
    required this.contrast,
    required this.rotation,
    required this.typoCount,
    required this.minLength,
    required this.maxLength,
    required this.distractionRows,
    required this.distractionOpacity,
  });
}

class _DisplayRow {
  final String text;
  final bool isTarget;
  final double verticalOffset;
  final double opacity;
  final double rotation;

  const _DisplayRow({
    required this.text,
    required this.isTarget,
    required this.verticalOffset,
    required this.opacity,
    required this.rotation,
  });
}

class LevelEyeChart extends LevelWidget {
  const LevelEyeChart({super.key, required super.onComplete});

  @override
  State<LevelEyeChart> createState() => _LevelEyeChartState();
}

class _LevelEyeChartState extends State<LevelEyeChart> {
  final _rand = Random();
  final _controller = TextEditingController();

  static const List<_StageConfig> _stages = [
    _StageConfig(
      fontSize: 15,
      contrast: 0.58,
      rotation: 0.08,
      typoCount: 2,
      minLength: 5,
      maxLength: 6,
      distractionRows: 3,
      distractionOpacity: 0.36,
    ),
    _StageConfig(
      fontSize: 13,
      contrast: 0.48,
      rotation: 0.12,
      typoCount: 2,
      minLength: 6,
      maxLength: 7,
      distractionRows: 3,
      distractionOpacity: 0.42,
    ),
    _StageConfig(
      fontSize: 12,
      contrast: 0.41,
      rotation: 0.15,
      typoCount: 2,
      minLength: 7,
      maxLength: 8,
      distractionRows: 4,
      distractionOpacity: 0.47,
    ),
    _StageConfig(
      fontSize: 11,
      contrast: 0.35,
      rotation: 0.20,
      typoCount: 2,
      minLength: 8,
      maxLength: 9,
      distractionRows: 4,
      distractionOpacity: 0.52,
    ),
    _StageConfig(
      fontSize: 10,
      contrast: 0.30,
      rotation: 0.24,
      typoCount: 3,
      minLength: 8,
      maxLength: 10,
      distractionRows: 5,
      distractionOpacity: 0.57,
    ),
    _StageConfig(
      fontSize: 9,
      contrast: 0.26,
      rotation: 0.29,
      typoCount: 3,
      minLength: 9,
      maxLength: 10,
      distractionRows: 5,
      distractionOpacity: 0.62,
    ),
    _StageConfig(
      fontSize: 8,
      contrast: 0.22,
      rotation: 0.34,
      typoCount: 3,
      minLength: 10,
      maxLength: 11,
      distractionRows: 6,
      distractionOpacity: 0.67,
    ),
    _StageConfig(
      fontSize: 7,
      contrast: 0.19,
      rotation: 0.39,
      typoCount: 4,
      minLength: 10,
      maxLength: 12,
      distractionRows: 6,
      distractionOpacity: 0.72,
    ),
    _StageConfig(
      fontSize: 6,
      contrast: 0.16,
      rotation: 0.44,
      typoCount: 4,
      minLength: 11,
      maxLength: 12,
      distractionRows: 7,
      distractionOpacity: 0.76,
    ),
    _StageConfig(
      fontSize: 5,
      contrast: 0.14,
      rotation: 0.52,
      typoCount: 5,
      minLength: 11,
      maxLength: 13,
      distractionRows: 8,
      distractionOpacity: 0.82,
    ),
  ];

  static const List<String> _words = [
    'ANCHOR',
    'ASTEROID',
    'BALLOON',
    'BLOSSOM',
    'CABINET',
    'CANYON',
    'CIRCUIT',
    'COMPASS',
    'CRYSTAL',
    'DOLPHIN',
    'FALCON',
    'GARDEN',
    'GLACIER',
    'HAMMER',
    'HARBOR',
    'KINGDOM',
    'LANTERN',
    'MAGNET',
    'MONITOR',
    'MOUNTAIN',
    'ORBITAL',
    'PYRAMID',
    'RAINBOW',
    'ROCKET',
    'SAPPHIRE',
    'SHELTER',
    'SIGNAL',
    'SPARROW',
    'STATION',
    'SUNRISE',
    'THUNDER',
    'TRACTOR',
    'TURBINE',
    'VOLCANO',
    'WHISPER',
    'WINDOW',
    'AFTERMATH',
    'BLUEPRINT',
    'CROSSFIRE',
    'DREAMSCAPE',
    'EVERGREEN',
    'FROSTBITE',
    'GOLIATH',
    'HEADLIGHT',
    'IRONCLAD',
    'JELLYFISH',
    'LABYRINTH',
    'MOONLIGHT',
    'NIGHTFALL',
    'OBSIDIAN',
    'PINEAPPLE',
    'QUICKSAND',
    'RIVERBANK',
    'STARLIGHT',
    'TREASURE',
    'UNDERPASS',
    'VALKYRIE',
    'WATERFALL',
    'WILDFLAME',
    'YESTERDAY',
    'ZEPHYRING',
    'ATMOSPHERE',
    'BLACKTHORN',
    'CANDLESTICK',
    'DRAGONFLY',
    'EVERGLADES',
    'FLASHLIGHT',
    'GRANITEWAY',
    'HARMONIC',
    'INTERLOCK',
    'JETSTREAM',
    'KNIGHTFALL',
    'LIFELINES',
    'MOONSTONE',
    'NORTHBOUND',
    'OVERGROWN',
    'PATHFINDER',
    'RAZORWING',
    'SHATTERING',
    'TIMBERLINE',
    'UNDERCURRENT',
    'WAVELENGTH',
  ];

  late List<String> _wordPool;
  late String _targetText;
  late List<_DisplayRow> _rows;
  int _stageIndex = 0;
  int _perfectStages = 0;
  double _scoreAccum = 0;

  String? _feedbackText;
  Color? _feedbackColor;

  @override
  void initState() {
    super.initState();
    _wordPool = List.of(_words)..shuffle(_rand);
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
    final baseWord = _nextWord(cfg.minLength, cfg.maxLength);
    _targetText = cfg.typoCount == 0
        ? baseWord
        : _applyTypos(baseWord, cfg.typoCount);
    _rows = _buildRows(cfg);
  }

  String _nextWord(int minLength, int maxLength) {
    if (_wordPool.isEmpty) {
      _wordPool = List.of(_words)..shuffle(_rand);
    }

    final matching = _wordPool
        .where((word) => word.length >= minLength && word.length <= maxLength)
        .toList();

    if (matching.isNotEmpty) {
      final choice = matching[_rand.nextInt(matching.length)];
      _wordPool.remove(choice);
      return choice;
    }

    final fallback =
        _words
            .where(
              (word) => word.length >= minLength && word.length <= maxLength,
            )
            .toList()
          ..shuffle(_rand);
    return fallback.first;
  }

  List<_DisplayRow> _buildRows(_StageConfig cfg) {
    final rows = <_DisplayRow>[
      _DisplayRow(
        text: _targetText,
        isTarget: true,
        verticalOffset: 0,
        opacity: 1,
        rotation: _signed(cfg.rotation),
      ),
    ];

    final rowGap = max(8.0, cfg.fontSize * 0.55);
    for (int i = 0; i < cfg.distractionRows; i++) {
      final direction = i.isEven ? -1.0 : 1.0;
      final band = (i ~/ 2) + 1;
      final distraction = _buildDistractionText(_targetText, cfg);
      rows.add(
        _DisplayRow(
          text: distraction,
          isTarget: false,
          verticalOffset: rowGap * band * direction,
          opacity: cfg.distractionOpacity + (_rand.nextDouble() * 0.08),
          rotation: _signed(cfg.rotation + 0.04),
        ),
      );
    }
    return rows;
  }

  String _buildDistractionText(String target, _StageConfig cfg) {
    final source = _nextWord(
      max(4, cfg.minLength - 1),
      min(13, cfg.maxLength + 1),
    );
    if (source == target) {
      return _applyTypos(source, max(1, cfg.typoCount));
    }
    return _rand.nextBool()
        ? source
        : _applyTypos(source, max(1, cfg.typoCount));
  }

  String _applyTypos(String word, int typoCount) {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
    final letters = word.split('');
    final indices = List.generate(letters.length, (i) => i)..shuffle(_rand);
    final replacements = min(typoCount, letters.length);

    for (int i = 0; i < replacements; i++) {
      final idx = indices[i];
      String replacement;
      do {
        replacement = String.fromCharCode(
          chars.codeUnitAt(_rand.nextInt(chars.length)),
        );
      } while (replacement == letters[idx]);
      letters[idx] = replacement;
    }

    return letters.join();
  }

  double _signed(double value) {
    if (value == 0) return 0;
    return value * (_rand.nextBool() ? 1 : -1);
  }

  void _submit() {
    if (_feedbackText != null) return;

    final answer = _normalize(_controller.text);
    if (answer.isEmpty) {
      _showSnack('type what you see');
      return;
    }

    final target = _normalize(_targetText);
    int matched = 0;
    for (int i = 0; i < min(answer.length, target.length); i++) {
      if (answer[i] == target[i]) matched++;
    }

    final maxLen = max(answer.length, target.length);
    final stageScore = maxLen == 0 ? 0.0 : matched / maxLen;
    _scoreAccum += stageScore / _stages.length;
    if (stageScore == 1.0) _perfectStages++;

    late final String feedback;
    late final Color feedbackColor;
    if (stageScore == 1.0) {
      feedback = 'perfect!';
      feedbackColor = NunuColors.successMain;
    } else if (stageScore >= 0.5) {
      feedback = '$matched/${target.length} correct (was $target)';
      feedbackColor = NunuColors.warningMain;
    } else {
      feedback = 'wrong - was $target';
      feedbackColor = NunuColors.errorMain;
    }

    setState(() {
      _feedbackText = feedback;
      _feedbackColor = feedbackColor;
    });

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_stageIndex + 1 >= _stages.length) {
        widget.onComplete(
          LevelOutcome(
            score: _scoreAccum.clamp(0.0, 1.0),
            metrics: {
              'perfect_stages': _perfectStages,
              'total_stages': _stages.length,
            },
          ),
        );
        return;
      }

      FocusManager.instance.primaryFocus?.unfocus();
      try {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      } catch (_) {}

      setState(() {
        _stageIndex++;
        _controller.clear();
        _feedbackText = null;
        _feedbackColor = null;
        _generateStage();
      });
    });
  }

  String _normalize(String value) =>
      value.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');

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
    final textColor = Colors.white.withOpacity(cfg.contrast);

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(stageText: '${_stageIndex + 1}/${_stages.length}'),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Text(
                'type the center word exactly',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
            ),
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) => Stack(
                    alignment: Alignment.center,
                    children: [
                      for (final row in _rows)
                        Transform.translate(
                          offset: Offset(0, row.verticalOffset),
                          child: Transform.rotate(
                            angle: row.rotation,
                            child: Opacity(
                              opacity: row.opacity,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: constraints.maxWidth * 0.92,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    row.text,
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: cfg.fontSize,
                                      fontWeight: row.isTarget
                                          ? FontWeight.w900
                                          : FontWeight.w700,
                                      color: row.isTarget
                                          ? textColor
                                          : Colors.white.withOpacity(
                                              row.opacity,
                                            ),
                                      letterSpacing: cfg.fontSize * 0.05,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      if (_feedbackText != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: _feedbackColor!.withOpacity(0.92),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: NunuColors.backgroundPaper.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: NunuColors.primaryMain.withOpacity(0.6),
                  ),
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
                        style: const TextStyle(color: NunuColors.textPrimary),
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
