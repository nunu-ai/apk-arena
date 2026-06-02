import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelSnake extends LevelWidget {
  const LevelSnake({super.key, required super.onComplete});

  @override
  State<LevelSnake> createState() => _LevelSnakeState();
}

class _StageConfig {
  final int number;
  final int gridSize;
  final int initialLength;
  final int? targetLength;
  final int maxAttempts;
  final double scoreWeight;
  final double partialScorePerLength;
  final Duration tickDuration;

  const _StageConfig({
    required this.number,
    required this.gridSize,
    required this.initialLength,
    required this.targetLength,
    required this.maxAttempts,
    required this.scoreWeight,
    required this.partialScorePerLength,
    required this.tickDuration,
  });
}

class _LevelSnakeState extends State<LevelSnake> {
  static const List<_StageConfig> _stageConfigs = [
    _StageConfig(
      number: 1,
      gridSize: 10,
      initialLength: 5,
      targetLength: 10,
      maxAttempts: 3,
      scoreWeight: 0.10,
      partialScorePerLength: 0.02,
      tickDuration: Duration(seconds: 5),
    ),
    _StageConfig(
      number: 2,
      gridSize: 10,
      initialLength: 5,
      targetLength: 10,
      maxAttempts: 3,
      scoreWeight: 0.15,
      partialScorePerLength: 0.02,
      tickDuration: Duration(milliseconds: 2500),
    ),
    _StageConfig(
      number: 3,
      gridSize: 15,
      initialLength: 10,
      targetLength: 20,
      maxAttempts: 3,
      scoreWeight: 0.15,
      partialScorePerLength: 0.01,
      tickDuration: Duration(seconds: 1),
    ),
    _StageConfig(
      number: 4,
      gridSize: 15,
      initialLength: 3,
      targetLength: null,
      maxAttempts: 2,
      scoreWeight: 0.60,
      partialScorePerLength: 0.005,
      tickDuration: Duration(milliseconds: 500),
    ),
  ];

  final List<List<int>> _snake = [];
  List<int> _food = [0, 0];
  int _dx = 1, _dy = 0;
  int _nextDx = 1, _nextDy = 0;
  Timer? _movementTimer;

  int _stageIndex = 0;
  late List<int> _attemptsByStage;
  late List<int> _bestLengthsByStage;
  late List<bool> _clearedByStage;

  bool _gameOver = false;
  bool _started = false;
  bool _finishing = false;
  final _rng = Random();

  _StageConfig get _config => _stageConfigs[_stageIndex];

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: List.generate(_stageConfigs.length, _stageScore)
              .fold(0.0, (s, v) => s + v),
          metrics: {'stage_reached': _stageIndex + 1},
        ));
    _attemptsByStage = List.filled(_stageConfigs.length, 0);
    _bestLengthsByStage = _stageConfigs
        .map((config) => config.initialLength)
        .toList();
    _clearedByStage = List.filled(_stageConfigs.length, false);
    _resetBoard();
  }

  void _resetBoard() {
    _movementTimer?.cancel();
    _movementTimer = null;
    _snake.clear();
    final row = _config.gridSize ~/ 2;
    final startColumn = min(_config.initialLength, _config.gridSize - 1);
    for (var i = 0; i < _config.initialLength; i++) {
      _snake.add([row, startColumn - i]);
    }
    _dx = 1;
    _dy = 0;
    _nextDx = 1;
    _nextDy = 0;
    _gameOver = false;
    _started = false;
    _spawnFood();
  }

  void _startAttempt() {
    if (_started || _finishing) return;
    _started = true;
    _attemptsByStage[_stageIndex]++;
    _movementTimer = Timer.periodic(_config.tickDuration, (_) => _tick());
  }

  void _spawnFood() {
    if (_snake.length >= _config.gridSize * _config.gridSize) return;

    while (true) {
      final r = _rng.nextInt(_config.gridSize);
      final c = _rng.nextInt(_config.gridSize);
      if (!_snake.any((s) => s[0] == r && s[1] == c)) {
        _food = [r, c];
        break;
      }
    }
  }

  void _tick() {
    if (_gameOver || !mounted || _finishing) return;

    var crashed = false;
    var reachedTarget = false;
    setState(() {
      _dx = _nextDx;
      _dy = _nextDy;

      final head = _snake.first;
      final newHead = [head[0] + _dy, head[1] + _dx];

      // Wall collision
      if (newHead[0] < 0 ||
          newHead[0] >= _config.gridSize ||
          newHead[1] < 0 ||
          newHead[1] >= _config.gridSize) {
        crashed = true;
        return;
      }

      // Self collision
      if (_snake.any((s) => s[0] == newHead[0] && s[1] == newHead[1])) {
        crashed = true;
        return;
      }

      _snake.insert(0, newHead);

      // Eat food?
      if (newHead[0] == _food[0] && newHead[1] == _food[1]) {
        HapticFeedback.lightImpact();
        _recordBestLength();
        reachedTarget =
            _config.targetLength != null &&
            _snake.length >= _config.targetLength!;
        if (reachedTarget) return;
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });

    if (crashed) {
      _handleCrash();
      return;
    }

    if (reachedTarget) {
      _handleStageClear();
    }
  }

  void _recordBestLength() {
    _bestLengthsByStage[_stageIndex] = max(
      _bestLengthsByStage[_stageIndex],
      _snake.length,
    );
  }

  void _handleCrash() {
    _recordBestLength();
    _gameOver = true;
    _movementTimer?.cancel();
    _movementTimer = null;
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _finishing) return;
      if (_attemptsByStage[_stageIndex] >= _config.maxAttempts) {
        _advanceStageOrFinish();
        return;
      }
      setState(_resetBoard);
    });
  }

  void _handleStageClear() {
    _recordBestLength();
    _movementTimer?.cancel();
    _movementTimer = null;
    HapticFeedback.mediumImpact();
    _clearedByStage[_stageIndex] = true;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && !_finishing) _advanceStageOrFinish();
    });
  }

  void _advanceStageOrFinish() {
    if (_stageIndex >= _stageConfigs.length - 1) {
      _finishLevel();
      return;
    }

    setState(() {
      _stageIndex++;
      _resetBoard();
    });
  }

  double _stageScore(int index) {
    final config = _stageConfigs[index];
    if (config.targetLength != null && _clearedByStage[index]) {
      return config.scoreWeight;
    }

    final extraLength = max(
      0,
      _bestLengthsByStage[index] - config.initialLength,
    );
    return min(config.scoreWeight, extraLength * config.partialScorePerLength);
  }

  void _finishLevel() {
    if (_finishing) return;
    _finishing = true;
    _movementTimer?.cancel();

    final stageScores = [
      for (var i = 0; i < _stageConfigs.length; i++) _stageScore(i),
    ];
    final totalScore = stageScores.reduce((a, b) => a + b);

    widget.onComplete(
      LevelOutcome(
        score: totalScore,
        metrics: {
          'stage1Score': stageScores[0],
          'stage2Score': stageScores[1],
          'stage3Score': stageScores[2],
          'stage4Score': stageScores[3],
        },
      ),
    );
  }

  void _setDirection(int dx, int dy) {
    if (_gameOver || _finishing) return;
    // Prevent 180-degree turns
    if (_dx == -dx && _dy == -dy) return;
    _nextDx = dx;
    _nextDy = dy;
    _startAttempt();
  }

  @override
  void dispose() {
    _movementTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(
              stageText: '${_config.number}/${_stageConfigs.length}',
              lives: LevelHud.emojiLives(
                _config.maxAttempts - (_displayAttempt - 1),
                _config.maxAttempts,
              ),
              trailing: Text(
                'length ${_snake.length} · best ${_bestLengthsByStage[_stageIndex]}',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: Center(child: _buildGrid())),
            const SizedBox(height: 8),
            _buildControls(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  int get _displayAttempt {
    final usedAttempts = _attemptsByStage[_stageIndex];
    return min(usedAttempts + (_started ? 0 : 1), _config.maxAttempts);
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = min(
          (constraints.maxWidth - 16) / _config.gridSize,
          (constraints.maxHeight - 8) / _config.gridSize,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: NunuColors.primaryDark.withValues(alpha: 0.5),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: cellSize * _config.gridSize,
              height: cellSize * _config.gridSize,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _config.gridSize,
                ),
                itemCount: _config.gridSize * _config.gridSize,
                itemBuilder: (_, i) {
                  final r = i ~/ _config.gridSize, c = i % _config.gridSize;
                  final isHead =
                      _snake.isNotEmpty &&
                      _snake.first[0] == r &&
                      _snake.first[1] == c;
                  final snakeIndex = _snake.indexWhere(
                    (s) => s[0] == r && s[1] == c,
                  );
                  final isSnake = snakeIndex >= 0;
                  final isFood = _food[0] == r && _food[1] == c;

                  Color bg;
                  if (isHead) {
                    bg = NunuColors.primaryMain;
                  } else if (isSnake) {
                    // Gradient from primary to secondary along body
                    final t = snakeIndex / max(_snake.length - 1, 1);
                    bg = Color.lerp(
                      NunuColors.primaryLight,
                      NunuColors.secondaryMain,
                      t,
                    )!;
                  } else if (isFood) {
                    bg = NunuColors.warningMain;
                  } else {
                    bg = (r + c) % 2 == 0
                        ? const Color(0xFF080817)
                        : const Color(0xFF241B4A);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: bg,
                      border: isSnake || isFood
                          ? null
                          : Border.all(
                              color: NunuColors.primaryDark.withValues(
                                alpha: 0.18,
                              ),
                              width: 0.5,
                            ),
                      borderRadius: isHead
                          ? BorderRadius.circular(cellSize * 0.3)
                          : isFood
                          ? BorderRadius.circular(cellSize * 0.5)
                          : null,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    Widget btn(IconData icon, int dx, int dy) {
      return GestureDetector(
        onTap: () => _setDirection(dx, dy),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NunuColors.primaryDark.withValues(alpha: 0.5),
            ),
          ),
          child: Icon(icon, color: NunuColors.primaryMain, size: 32),
        ),
      );
    }

    return Column(
      children: [
        btn(Icons.arrow_upward, 0, -1),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btn(Icons.arrow_back, -1, 0),
            const SizedBox(width: 68),
            btn(Icons.arrow_forward, 1, 0),
          ],
        ),
        const SizedBox(height: 4),
        btn(Icons.arrow_downward, 0, 1),
      ],
    );
  }
}
