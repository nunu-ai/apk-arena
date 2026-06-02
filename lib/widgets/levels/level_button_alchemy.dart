import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelButtonAlchemy extends LevelWidget {
  const LevelButtonAlchemy({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelButtonAlchemy> createState() => _LevelButtonAlchemyState();
}

class _Stage {
  final String name;
  final int startValue;
  final int target;
  final List<int Function(int)> ops;
  final int? modulus;

  _Stage({
    required this.name,
    required this.startValue,
    required this.target,
    required this.ops,
    this.modulus,
  });
}

class _LevelButtonAlchemyState extends State<LevelButtonAlchemy> {
  static const int _explorePerButton = 4;
  static const int _numButtons = 3;
  static const int _maxVal = 9999;
  static const _buttonLabels = ['a', 'b', 'c'];
  static const _buttonColors = [
    NunuColors.primaryMain,
    NunuColors.secondaryMain,
    NunuColors.infoMain,
  ];

  late final List<_Stage> _stages;
  late final List<int> _optimalMoves;

  int _stageIndex = 0;
  int _value = 1;
  int _moveCount = 0;
  bool _stageComplete = false;
  bool _finished = false;
  final List<double> _stageScores = [];
  final Map<String, dynamic> _metrics = {};

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: _stageScores.fold(0.0, (s, v) => s + v) / _stages.length,
          metrics: {'stage_reached': _stageIndex + 1},
        ));
    _stages = [
      _Stage(
        name: 'easy',
        startValue: 1,
        target: 100,
        ops: [(v) => v * 2, (v) => v - 5, (v) => v + 7],
      ),
      _Stage(
        name: 'medium',
        startValue: 1,
        target: 200,
        ops: [(v) => v * 3, (v) => v - 8, (v) => v + 15],
      ),
      _Stage(
        name: 'hard',
        startValue: 1,
        target: 173,
        ops: [(v) => v * 3, (v) => v + 29, (v) => v * 7],
        modulus: 256,
      ),
    ];
    _optimalMoves = _stages.map(_bfs).toList();
    _value = _stages.first.startValue;
  }

  // ── core logic ──

  int _applyOp(_Stage stage, int value, int opIndex) {
    int result = stage.ops[opIndex](value);
    if (stage.modulus != null) {
      result = result % stage.modulus!;
    }
    return result.clamp(0, stage.modulus ?? _maxVal);
  }

  int _bfs(_Stage stage) {
    final start = stage.startValue;
    final target = stage.target;
    if (start == target) return 0;

    final visited = <int>{start};
    var frontier = [start];
    int depth = 0;
    final upperBound = stage.modulus != null ? stage.modulus! - 1 : _maxVal;

    while (frontier.isNotEmpty && depth < 1000) {
      depth++;
      final next = <int>[];
      for (final v in frontier) {
        for (int i = 0; i < stage.ops.length; i++) {
          final nv = _applyOp(stage, v, i);
          if (nv == target) return depth;
          if (nv >= 0 && nv <= upperBound && visited.add(nv)) {
            next.add(nv);
          }
        }
      }
      frontier = next;
    }
    return 999;
  }

  void _pressOp(int opIndex) {
    if (_stageComplete || _finished) return;
    final stage = _stages[_stageIndex];
    setState(() {
      _value = _applyOp(stage, _value, opIndex);
      _moveCount++;
    });
    if (_value == stage.target) {
      _onStageCleared();
    }
  }

  void _reset() {
    if (_stageComplete || _finished) return;
    HapticFeedback.selectionClick();
    setState(() => _value = _stages[_stageIndex].startValue);
  }

  void _onStageCleared() {
    HapticFeedback.mediumImpact();
    final optimal = _optimalMoves[_stageIndex];
    final par = optimal + _explorePerButton * _numButtons;
    final score = _moveCount <= par ? 1.0 : par / _moveCount;
    _stageScores.add(score);
    _recordStageMetrics(skipped: false);

    setState(() => _stageComplete = true);

    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      _advanceOrFinish();
    });
  }

  void _skipStage() {
    if (_stageComplete || _finished) return;
    _stageScores.add(0);
    _recordStageMetrics(skipped: true);
    _advanceOrFinish();
  }

  void _recordStageMetrics({required bool skipped}) {
    final i = _stageIndex + 1;
    _metrics['stage_${i}_moves'] = _moveCount;
    _metrics['stage_${i}_score'] = double.parse(
      _stageScores.last.toStringAsFixed(2),
    );
  }

  void _advanceOrFinish() {
    if (_stageIndex < _stages.length - 1) {
      setState(() {
        _stageIndex++;
        _value = _stages[_stageIndex].startValue;
        _moveCount = 0;
        _stageComplete = false;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    if (_finished) return;
    _finished = true;

    while (_stageScores.length < _stages.length) {
      _stageScores.add(0);
    }

    final avgScore = _stageScores.fold(0.0, (a, b) => a + b) / _stages.length;
    widget.onComplete(
      LevelOutcome(
        score: avgScore,
        metrics: {
          for (int i = 1; i <= _stages.length; i++)
            'stage_${i}_score': _metrics['stage_${i}_score'] ?? 0,
          'total_moves': [
            for (int i = 1; i <= _stages.length; i++)
              (_metrics['stage_${i}_moves'] as int?) ?? 0,
          ].fold<int>(0, (sum, moves) => sum + moves),
        },
        visibleMetricKeys: [
          for (int i = 1; i <= _stages.length; i++) 'stage_${i}_score',
        ],
      ),
    );
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    final stage = _stages[_stageIndex];
    final textTheme = Theme.of(context).textTheme;

    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          LevelHud(
            stageText: '${_stageIndex + 1}/${_stages.length}',
            trailing: Text(
              'moves $_moveCount',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildCard(stage, textTheme),
                      const SizedBox(height: 16),
                      Row(
                        children: List.generate(
                          _numButtons,
                          (i) => _buildOpButton(
                            label: _buttonLabels[i],
                            onPressed: _stageComplete
                                ? null
                                : () => _pressOp(i),
                            color: _buttonColors[i],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: _stageComplete ? null : _reset,
                            icon: const Icon(
                              Icons.restart_alt,
                              size: 18,
                              color: NunuColors.errorLight,
                            ),
                            label: const Text(
                              'reset value',
                              style: TextStyle(color: NunuColors.errorLight),
                            ),
                          ),
                          TextButton(
                            onPressed: _stageComplete ? null : _skipStage,
                            child: const Text(
                              'skip stage',
                              style: TextStyle(color: NunuColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_Stage stage, TextTheme textTheme) {
    return Card(
      color: NunuColors.backgroundPaper,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _stageComplete
            ? _buildStageCompleteContent(textTheme)
            : _buildActiveContent(stage, textTheme),
      ),
    );
  }

  Widget _buildStageCompleteContent(TextTheme textTheme) {
    return Column(
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.check_circle, color: NunuColors.successMain, size: 48),
        const SizedBox(height: 12),
        Text(
          'stage ${_stageIndex + 1} complete',
          style: textTheme.titleMedium?.copyWith(color: NunuColors.successMain),
        ),
        const SizedBox(height: 4),
        Text(
          '$_moveCount moves',
          style: textTheme.bodyMedium?.copyWith(
            color: NunuColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildActiveContent(_Stage stage, TextTheme textTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'target',
          style: textTheme.titleSmall?.copyWith(
            color: NunuColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          stage.target.toString(),
          style: textTheme.headlineLarge?.copyWith(
            color: NunuColors.primaryLight,
          ),
        ),
        if (stage.modulus != null) ...[
          const SizedBox(height: 4),
          Text(
            'mod ${stage.modulus}',
            style: textTheme.bodySmall?.copyWith(
              color: NunuColors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Divider(color: NunuColors.primaryDark.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          'current',
          style: textTheme.titleSmall?.copyWith(
            color: NunuColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                _value.toString(),
                style: textTheme.headlineMedium?.copyWith(color: Colors.white),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: NunuColors.primaryDark.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'moves: $_moveCount',
                style: textTheme.bodySmall?.copyWith(
                  color: NunuColors.primaryLight,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildOpButton({
    required String label,
    required VoidCallback? onPressed,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(
              alpha: onPressed != null ? 0.7 : 0.25,
            ),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text(label),
        ),
      ),
    );
  }
}
