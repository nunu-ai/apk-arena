import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

/// Shrinking logo taps — 20 rounds, 10 hearts; a miss costs one.
class LevelClickAccuracy extends LevelWidget {
  const LevelClickAccuracy({super.key, required super.onComplete});

  @override
  State<LevelClickAccuracy> createState() => _LevelClickAccuracyState();
}

class _LevelClickAccuracyState extends State<LevelClickAccuracy> {
  static const int roundCount = 20;
  static const int maxLives = 10;

  // Hardcoded hitbox sizes for each round, computed using previous curve settings.
  // These values should be updated if the original curve is changed.
  // They represent logical pixels (width & height), indexed by round index (0..19).
  static const List<double> _hitboxSizes = [
    120, // round 1
    80, // round 2
    65, // round 3
    52, // round 4
    44, // round 5
    37, // round 6
    31, // round 7
    26, // round 8
    22, // round 9
    18, // round 10
    15, // round 11
    12, // round 12
    10, // round 13
    8, // round 14
    6, // round 15
    5, // round 16
    4, // round 17
    3, // round 18
    2, // round 19
    1, // round 20
  ];

  final Random _rng = SeedService.instance.createRandom();

  /// Successful hits so far (0 … roundCount); size uses this index clamped to roundCount - 1.
  int _roundIndex = 0;
  int _lives = maxLives;
  Alignment _targetAlign = Alignment.center;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: scoreForRun(roundsCleared: _roundIndex, livesRemaining: _lives, clearedAllRounds: false)));
    _targetAlign = _randomAlign();
  }

  Alignment _randomAlign() {
    final x = (_rng.nextDouble() * 2 - 1) * 0.85;
    final y = (_rng.nextDouble() * 2 - 1) * 0.75;
    return Alignment(x, y);
  }

  /// 90% of the score from clearing rounds (linear up to 20); the last 10% only
  /// after all rounds, from lives remaining / maxLives.
  static const double _scoreWeightStages = 0.9;
  static const double _scoreWeightLives = 0.1;

  static double scoreForRun({
    required int roundsCleared,
    required int livesRemaining,
    required bool clearedAllRounds,
  }) {
    final stageFraction = (roundsCleared / roundCount).clamp(0.0, 1.0);
    if (!clearedAllRounds || roundsCleared < roundCount) {
      return (_scoreWeightStages * stageFraction).clamp(0.0, 1.0);
    }
    final livesFraction = (livesRemaining / maxLives).clamp(0.0, 1.0);
    return (_scoreWeightStages + _scoreWeightLives * livesFraction).clamp(
      0.0,
      1.0,
    );
  }

  void _fail() {
    final roundsCleared = _roundIndex;
    final s = scoreForRun(
      roundsCleared: roundsCleared,
      livesRemaining: _lives,
      clearedAllRounds: false,
    );
    widget.onComplete(LevelOutcome(score: s));
  }

  void _onTargetHit() {
    if (_roundIndex >= roundCount - 1) {
      final s = scoreForRun(
        roundsCleared: roundCount,
        livesRemaining: _lives,
        clearedAllRounds: true,
      );
      widget.onComplete(LevelOutcome(score: s));
      return;
    }
    setState(() {
      _roundIndex++;
      _targetAlign = _randomAlign();
    });
  }

  void _onMiss() {
    if (_lives <= 1) {
      _lives = 0;
      _fail();
      return;
    }
    setState(() {
      _lives--;
      _targetAlign = _randomAlign();
    });
  }

  double get _currentHitboxSize {
    int idx = _roundIndex.clamp(0, _hitboxSizes.length - 1);
    return _hitboxSizes[idx];
  }

  static const String _nunuLogoAsset =
      'assets/icon/nunu-icon-transparent@4x.png';

  @override
  Widget build(BuildContext context) {
    final side = _currentHitboxSize;
    final logoPad = (side * 0.1).clamp(1.0, 12.0);

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _onMiss,
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          right: 0,
          child: AbsorbPointer(
            child: LevelHud(
              stageText: '${_roundIndex + 1}/$roundCount',
              lives: LevelHud.emojiLives(_lives, maxLives),
            ),
          ),
        ),
        Align(
          alignment: _targetAlign,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _onTargetHit,
            child: Container(
              width: side,
              height: side,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(
                  alpha: side <= 4 ? 1.0 : 0.55,
                ),
                borderRadius: BorderRadius.circular(side > 8 ? 8 : 0),
              ),
              child: Padding(
                padding: EdgeInsets.all(logoPad),
                child: Image.asset(
                  _nunuLogoAsset,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.touch_app,
                    size: (side * 0.45).clamp(4.0, 28.0),
                    color: NunuColors.primaryLight,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
