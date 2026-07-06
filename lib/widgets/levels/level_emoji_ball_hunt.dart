import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class _StageConfig {
  final String hint; // what to look for
  final List<String> targets;
  final List<String> distractors;
  final int distractorCount;
  final double targetSize;
  final List<double> distractorSizes; // possible font sizes for distractors

  const _StageConfig({
    required this.hint,
    required this.targets,
    required this.distractors,
    required this.distractorCount,
    this.targetSize = 18,
    this.distractorSizes = const [24, 32, 40, 48],
  });
}

class LevelEmojiBallHunt extends LevelWidget {
  const LevelEmojiBallHunt({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelEmojiBallHunt> createState() => _LevelEmojiBallHuntState();
}

class _LevelEmojiBallHuntState extends State<LevelEmojiBallHunt> {
  final Random _rand = SeedService.instance.createRandom();

  // stage 1: balls among faces — high contrast
  // stage 2: balls among colorful round emojis — medium contrast
  // stage 3: red circles among red/orange shapes — low contrast
  // stage 4: geometric shapes among near-identical shapes — minimal contrast
  static final List<_StageConfig> _stages = [
    // 1: balls among faces — obvious contrast
    _StageConfig(
      hint: 'tap the 3 balls 🏀⚽🏈',
      targets: ['🏀', '⚽', '🏈'],
      distractors: [
        '😀',
        '😃',
        '😄',
        '😁',
        '😆',
        '😅',
        '😂',
        '🙂',
        '😉',
        '😜',
        '🤪',
        '🤗',
        '😏',
        '😎',
        '😴',
        '😡',
        '😱',
        '😭',
        '🤔',
        '😬',
      ],
      distractorCount: 80,
    ),
    // 2: basketballs among round colorful things
    _StageConfig(
      hint: 'tap the 3 basketballs 🏀',
      targets: ['🏀', '🏀', '🏀'],
      distractors: ['🍊', '🍎', '🍑', '🟠', '🟤', '🥯', '🫓', '🥮', '😡'],
      distractorCount: 90,
      distractorSizes: [24, 32, 40, 48],
      targetSize: 16,
    ),
    // 3: red circle among red shapes
    _StageConfig(
      hint: 'tap the 3 red circles 🔴',
      targets: ['🔴', '🔴', '🔴'],
      distractors: [
        '⭕',
        '⭕',
        '🟥',
        '🟥',
        '🟥',
        '♥️',
        '♥️',
        '♥️',
        '😡',
        '😡',
        '🔘',
        '⚪',
        '🪬',
        '🧿',
        '🍎',
        '🍎',
      ],
      distractorCount: 120,
      targetSize: 16,
      distractorSizes: [16, 20, 24, 32, 40, 40, 48, 56],
    ),
    // 4: broken hearts among hearts
    _StageConfig(
      hint: 'tap the 3 broken hearts 💔',
      targets: ['💔', '💔', '💔'],
      distractors: [
        '❤️',
        '❤️',
        '❤️',
        '❤️',
        '❤️',
        '❤️',
        '♥️',
        '♥️',
        '♥️',
        '♥️',
        '🩷',
      ],
      distractorSizes: [14, 16, 18, 20, 30, 36, 36, 40, 40, 48, 48],
      distractorCount: 140,
      targetSize: 16,
    ),
    // 5: 🙂 among similar smileys — micro expression differences
    _StageConfig(
      hint: 'tap the 3 slightly smiling faces 🙂',
      targets: ['🙂', '🙂', '🙂'],
      distractors: [
        '😀',
        '😀',
        '😀',
        '😃',
        '😃',
        '😃',
        '😄',
        '😄',
        '😊',
        '😊',
        '🙃',
        '🙃',
        '🙃',
        '😶',
        '😶',
        '😐',
        '😐',
        '😑',
        '😑',
        '🫠',
      ],
      distractorCount: 150,
      targetSize: 24,
      distractorSizes: [16, 20, 24, 28, 32],
    ),
    // 6: 😈 among angry/red faces — subtle expression difference
    _StageConfig(
      hint: 'tap the 3 devil faces 😈',
      targets: ['😈', '😈', '😈'],
      distractors: [
        '😡',
        '😡',
        '😡',
        '😠',
        '😠',
        '😠',
        '🤬',
        '🤬',
        '👿',
        '😤',
        '😤',
        '😤',
        '🥵',
        '🥵',
        '😾',
        '😾',
        '👹',
        '👹',
        '👺',
      ],
      distractorCount: 160,
      targetSize: 14,
      distractorSizes: [12, 14, 16, 20, 24, 32, 37, 48],
    ),
  ];

  int _stageIndex = 0;
  double _scoreAccum = 0;
  bool _generated = false;
  bool _stageEnded = false;

  final List<_EmojiItem> _distractors = [];
  final List<_EmojiItem> _targets = [];
  final Set<int> _foundTargets = {};
  int _misses = 0;
  static const int _maxMisses = 3;

  String? _feedbackText;
  Color? _feedbackColor;

  void _generateItems(Size size) {
    if (_generated) return;
    _generated = true;

    final cfg = _stages[_stageIndex];
    final width = size.width;
    final height = size.height;

    const double topSafe = 50; // below hint bar
    const double bottomSafe = 50; // above status bar
    final double usableHeight = max(0, height - topSafe - bottomSafe);

    // distractors
    for (int i = 0; i < cfg.distractorCount; i++) {
      final emoji = cfg.distractors[_rand.nextInt(cfg.distractors.length)];
      final double fontSize =
          cfg.distractorSizes[_rand.nextInt(cfg.distractorSizes.length)];
      final double x = _rand.nextDouble() * max(0, width - fontSize);
      final double y =
          topSafe + _rand.nextDouble() * max(0, usableHeight - fontSize);
      _distractors.add(
        _EmojiItem(emoji: emoji, size: fontSize, offset: Offset(x, y)),
      );
    }

    // targets
    for (final emoji in cfg.targets) {
      final double fontSize = cfg.targetSize;
      final double x = _rand.nextDouble() * max(0, width - fontSize);
      final double y =
          topSafe + _rand.nextDouble() * max(0, usableHeight - fontSize);
      _targets.add(
        _EmojiItem(emoji: emoji, size: fontSize, offset: Offset(x, y)),
      );
    }
  }

  void _handleWrongTap() {
    if (_stageEnded) return;
    _misses++;
    if (_misses >= _maxMisses) {
      _endStage();
    } else {
      setState(() {});
    }
  }

  void _handleTargetTap(int index) {
    if (_stageEnded || _foundTargets.contains(index)) return;
    setState(() {
      _foundTargets.add(index);
    });
    if (_foundTargets.length == _targets.length) {
      _endStage();
    }
  }

  void _endStage() {
    _stageEnded = true;
    final cfg = _stages[_stageIndex];
    final hits = _foundTargets.length;
    final stageScore = (hits * (1.0 / cfg.targets.length) - _misses * 0.1)
        .clamp(0.0, 1.0);
    _scoreAccum += stageScore / _stages.length;

    late final String feedback;
    late final Color feedbackCol;
    if (hits == cfg.targets.length && _misses == 0) {
      feedback = 'perfect!';
      feedbackCol = NunuColors.successMain;
    } else if (hits > 0) {
      feedback = '$hits/${cfg.targets.length} found, $_misses misses';
      feedbackCol = NunuColors.warningMain;
    } else {
      feedback = 'missed all — $_misses wrong taps';
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
        _stageIndex++;
        _distractors.clear();
        _targets.clear();
        _foundTargets.clear();
        _misses = 0;
        _generated = false;
        _stageEnded = false;
        _feedbackText = null;
        _feedbackColor = null;
        setState(() {});
      }
    });
  }

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: _scoreAccum.clamp(0.0, 1.0),
          metrics: {'stages_scored': _stageIndex},
        ));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _generateItems(Size(constraints.maxWidth, constraints.maxHeight));
        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: _handleWrongTap, // tapping void = miss
          child: Container(
            color: NunuColors.backgroundDefault,
            child: Stack(
              children: [
                // distractors (wrong tap)
                for (final f in _distractors)
                  Positioned(
                    left: f.offset.dx,
                    top: f.offset.dy,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _handleWrongTap,
                      child: Text(
                        f.emoji,
                        style: TextStyle(fontSize: f.size, height: 1.0),
                      ),
                    ),
                  ),

                // targets
                for (int i = 0; i < _targets.length; i++)
                  Positioned(
                    left: _targets[i].offset.dx,
                    top: _targets[i].offset.dy,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _handleTargetTap(i),
                      child: Opacity(
                        opacity: _foundTargets.contains(i) ? 0.35 : 1.0,
                        child: Text(
                          _targets[i].emoji,
                          style: TextStyle(
                            fontSize: _targets[i].size,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),

                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: LevelHud(
                    stageText: '${_stageIndex + 1}/${_stages.length}',
                    lives: LevelHud.emojiLives(_maxMisses - _misses, _maxMisses),
                    trailing: Text(
                      'tap on: ${_stages[_stageIndex].targets.join()}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                // feedback overlay
                if (_feedbackText != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
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
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmojiItem {
  final String emoji;
  final double size;
  final Offset offset;
  _EmojiItem({required this.emoji, required this.size, required this.offset});
}
