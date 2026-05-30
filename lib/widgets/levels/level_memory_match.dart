import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelMemoryMatch extends LevelWidget {
  const LevelMemoryMatch({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelMemoryMatch> createState() => _LevelMemoryMatchState();
}

class _LevelMemoryMatchState extends State<LevelMemoryMatch> {
  static const Duration _revealDelay = Duration(milliseconds: 650);

  static const List<String> _emojiPool = [
    '🍎',
    '🍌',
    '🍇',
    '🍓',
    '🍒',
    '🍍',
    '🍑',
    '🥝',
    '🐶',
    '🐱',
    '🐼',
    '🦊',
    '🐵',
    '🦁',
    '🐸',
    '🐨',
    '⭐',
    '🌙',
    '⚡',
    '🔥',
    '💧',
    '❄️',
    '🌈',
    '🌟',
  ];

  static const List<_StageConfig> _stages = [
    _StageConfig(
      title: 'stage 1/3',
      subtitle: 'match the pairs!',
      groupSize: 2,
      groupCount: 8,
      crossAxisCount: 4,
    ),
    _StageConfig(
      title: 'stage 2/3',
      subtitle: 'bigger board new rules. clear the triplets!',
      groupSize: 3,
      groupCount: 8,
      crossAxisCount: 4,
    ),
    _StageConfig(
      title: 'stage 3/3',
      subtitle: 'EXACT SAME board as the first one! make no mistakes',
      groupSize: 2,
      groupCount: 8,
      crossAxisCount: 4,
    ),
  ];

  final Random _rand = Random();
  late final List<String> _stageOneDeck;
  late final List<_StageStats> _stats;

  int _stageIndex = 0;
  late List<String> _deck;
  late List<int> _revealCounts;
  final Set<int> _matched = {};
  final List<int> _revealed = [];
  bool _lock = false;

  _StageConfig get _stage => _stages[_stageIndex];
  _StageStats get _stageStats => _stats[_stageIndex];

  @override
  void initState() {
    super.initState();
    _stageOneDeck = _buildDeck(_stages[0]);
    _stats = List<_StageStats>.generate(_stages.length, (_) => _StageStats());
    _deck = List<String>.from(_stageOneDeck);
    _revealCounts = List<int>.filled(_deck.length, 0);
    _announceStage();
  }

  List<String> _buildDeck(_StageConfig stage) {
    final pool = List<String>.from(_emojiPool)..shuffle(_rand);
    final selected = pool.take(stage.groupCount).toList();
    final deck = <String>[];
    for (final symbol in selected) {
      for (var i = 0; i < stage.groupSize; i++) {
        deck.add(symbol);
      }
    }
    deck.shuffle(_rand);
    return deck;
  }

  void _startStage(int index) {
    final nextDeck = index == 1
        ? _buildDeck(_stages[index])
        : List<String>.from(_stageOneDeck);
    setState(() {
      _stageIndex = index;
      _deck = nextDeck;
      _revealCounts = List<int>.filled(nextDeck.length, 0);
      _matched.clear();
      _revealed.clear();
      _lock = false;
    });
    _announceStage();
  }

  void _announceStage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final messenger = ScaffoldMessenger.maybeOf(context);
      if (messenger == null) return;
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 2),
          backgroundColor: NunuColors.backgroundPaper,
          content: Text(
            _stage.subtitle,
            style: const TextStyle(color: NunuColors.textPrimary),
          ),
        ),
      );
    });
  }

  Future<void> _onCardTap(int index) async {
    if (_lock) return;
    if (_matched.contains(index)) return;
    if (_revealed.contains(index)) return;

    setState(() {
      _revealed.add(index);
      _revealCounts[index]++;
    });

    if (_revealed.length != _stage.groupSize) return;

    _lock = true;
    final revealedNow = List<int>.from(_revealed);
    final firstSymbol = _deck[revealedNow.first];
    final isMatch = revealedNow.every(
      (cardIndex) => _deck[cardIndex] == firstSymbol,
    );
    final isOneShotSet = revealedNow.every(
      (cardIndex) => _revealCounts[cardIndex] == 1,
    );

    await Future.delayed(_revealDelay);
    if (!mounted) return;

    setState(() {
      if (isMatch) {
        _matched.addAll(revealedNow);
        _stageStats.matchedSets++;
        if (_stageIndex == 2 && isOneShotSet) {
          _stageStats.oneShotSets++;
        }
      } else {
        _stageStats.mismatchTurns++;
        for (final cardIndex in revealedNow) {
          if (_revealCounts[cardIndex] > 1) {
            _stageStats.repeatRevealPenalties++;
          }
        }
      }

      _revealed.clear();
      _lock = false;
    });

    if (_matched.length == _stage.cardCount) {
      await _finishStage();
    }
  }

  Future<void> _finishStage() async {
    _stageStats.score = _calculateStageScore(_stageIndex);

    if (_stageIndex == _stages.length - 1) {
      final finalScore =
          0.3 * _stats[0].score + 0.3 * _stats[1].score + 0.4 * _stats[2].score;
      widget.onComplete(
        LevelOutcome(score: finalScore, metrics: _buildMetrics()),
      );
      return;
    }

    _startStage(_stageIndex + 1);
  }

  double _calculateStageScore(int index) {
    final stage = _stages[index];
    final stats = _stats[index];
    final completionRatio = stats.matchedSets / stage.groupCount;
    final repeatPenaltyRatio = stats.repeatRevealPenalties / stage.cardCount;

    if (index < 2) {
      return _clamp01(completionRatio - repeatPenaltyRatio);
    }

    final missPenaltyRatio = stats.mismatchTurns / stage.groupCount;
    final stageThreePenalty = repeatPenaltyRatio / 2;
    return _clamp01(completionRatio - missPenaltyRatio - stageThreePenalty);
  }

  double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  Map<String, dynamic> _buildMetrics() {
    return {
      'stage_1_score': _round(_stats[0].score),
      'stage_2_score': _round(_stats[1].score),
      'stage_3_score': _round(_stats[2].score),
      'stage_1_penalties': _stats[0].repeatRevealPenalties,
      'stage_2_penalties': _stats[1].repeatRevealPenalties,
      'stage_3_penalties': _stats[2].repeatRevealPenalties,
      'stage_3_misses': _stats[2].mismatchTurns,
      'stage_3_one_shot': _stats[2].oneShotSets,
    };
  }

  double _round(double value) {
    return double.parse(value.toStringAsFixed(3));
  }

  bool _isFaceUp(int index) =>
      _matched.contains(index) || _revealed.contains(index);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LevelHud(
            stageText: '${_stageIndex + 1}/${_stages.length}',
            trailing: Text(
              'sets ${_stageStats.matchedSets}/${_stage.groupCount}',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              _stage.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: NunuColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _stageStats.matchedSets / _stage.groupCount,
            minHeight: 8,
            backgroundColor: NunuColors.backgroundPaper,
            color: NunuColors.primaryMain,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 8.0;
                final totalHorizontalSpacing =
                    spacing * (_stage.crossAxisCount - 1);
                final cardSize =
                    (constraints.maxWidth - totalHorizontalSpacing) /
                    _stage.crossAxisCount;

                return GridView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: _deck.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _stage.crossAxisCount,
                    mainAxisSpacing: spacing,
                    crossAxisSpacing: spacing,
                    childAspectRatio: 1,
                  ),
                  itemBuilder: (context, index) {
                    final faceUp = _isFaceUp(index);
                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        decoration: BoxDecoration(
                          color: faceUp
                              ? NunuColors.backgroundPaper
                              : NunuColors.secondaryDark.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: faceUp
                                ? NunuColors.primaryMain.withOpacity(0.7)
                                : NunuColors.secondaryMain.withOpacity(0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          faceUp ? _deck[index] : ' ',
                          style: TextStyle(fontSize: min(cardSize * 0.48, 42)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StageConfig {
  final String title;
  final String subtitle;
  final int groupSize;
  final int groupCount;
  final int crossAxisCount;

  const _StageConfig({
    required this.title,
    required this.subtitle,
    required this.groupSize,
    required this.groupCount,
    required this.crossAxisCount,
  });

  int get cardCount => groupSize * groupCount;
}

class _StageStats {
  int matchedSets = 0;
  int mismatchTurns = 0;
  int repeatRevealPenalties = 0;
  int oneShotSets = 0;
  double score = 0;
}
