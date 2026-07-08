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

class _ButtonDef {
  // cycle: ops applied in rotation on each press (length=1 → fixed op)
  final List<int Function(int)> cycle;
  final int? maxUses; // null = unlimited

  _ButtonDef(this.cycle, {this.maxUses});

  bool get isAlternating => cycle.length > 1;
  bool get hasLimit => maxUses != null;
}

class _Stage {
  final String name;
  final int startValue;
  final int target;
  final List<_ButtonDef> buttons;
  final int? modulus;

  _Stage({
    required this.name,
    required this.startValue,
    required this.target,
    required this.buttons,
    this.modulus,
  });
}

class _LevelButtonAlchemyState extends State<LevelButtonAlchemy> {
  static const int _maxVal = 9999;
  static const _buttonLabels = ['a', 'b', 'c'];
  static const _buttonColors = [
    NunuColors.primaryMain,
    NunuColors.secondaryMain,
    NunuColors.infoMain,
  ];

  late final List<_Stage> _stages;

  int _stageIndex = 0;
  int _value = 1;
  int _moveCount = 0;
  int _resetCount = 0; // resets this stage; first one is free
  bool _stageComplete = false;
  bool _finished = false;
  final List<double> _stageScores = [];
  final Map<String, dynamic> _metrics = {};

  // [stageIndex][buttonIndex] = total press count for that button this stage.
  // NOT reset when the user resets value — intentional, keeps cycling/limited tricky.
  late List<List<int>> _buttonPressCounts;

  @override
  void initState() {
    super.initState();
    _stages = _buildStages();
    _buttonPressCounts =
        _stages.map((s) => List<int>.filled(s.buttons.length, 0)).toList();
    _value = _stages.first.startValue;

    widget.registerPartialScoreGetter(
      () => LevelOutcome(
        score: _stageScores.isEmpty
            ? 0
            : _stageScores.fold(0.0, (s, v) => s + v) / _stages.length,
        metrics: {'stage_reached': _stageIndex + 1},
      ),
    );
  }

  List<_Stage> _buildStages() => [
    // ── Stage 1: fixed ops, non-trivial target ────────────────────────────
    // Optimal path is 8 moves: ×3, +7, ×3, ×3, +7, +7, ×3, +7 = 319.
    // The C button (−2) is a red herring — not needed for optimal.
    _Stage(
      name: 'basics',
      startValue: 1,
      target: 319,
      buttons: [
        _ButtonDef([(v) => v * 3]),
        _ButtonDef([(v) => v + 7]),
        _ButtonDef([(v) => v - 2]),
      ],
    ),

    // ── Stage 2: modular arithmetic ───────────────────────────────────────
    // Values wrap at 128. Overflowing intentionally is key.
    _Stage(
      name: 'modular',
      startValue: 1,
      target: 77,
      modulus: 128,
      buttons: [
        _ButtonDef([(v) => v * 3]),
        _ButtonDef([(v) => v * 2]),
        _ButtonDef([(v) => v + 11]),
      ],
    ),

    // ── Stage 3: alternating button ───────────────────────────────────────
    // Button A cycles ×2 / ×3 on alternate presses. Parity is NOT reset
    // when you reset the value — so you must track A's press count globally.
    _Stage(
      name: 'flip-flop',
      startValue: 2,
      target: 96,
      buttons: [
        _ButtonDef([(v) => v * 2, (v) => v * 3]),
        _ButtonDef([(v) => v + 5]),
        _ButtonDef([(v) => v - 1]),
      ],
    ),

    // ── Stage 4: conditional (Collatz) ───────────────────────────────────
    // Button A halves even values and does ×3+1 on odd. Both branches must
    // be observed — which means engineering an odd value first via B or C.
    _Stage(
      name: 'collatz',
      startValue: 12,
      target: 1,
      buttons: [
        _ButtonDef([(v) => v.isEven ? v ~/ 2 : v * 3 + 1]),
        _ButtonDef([(v) => v + 1]),
        _ButtonDef([(v) => v + 8]),
      ],
    ),

    // ── Stage 5: demon tier ───────────────────────────────────────────────
    // A runs a 4-cycle: ×2 → +11 → ×3 → −17 → repeat. You need 4 presses
    // to see the full pattern — and presses are rationed. Button B looks like
    // it always subtracts 4, but jumps +31 when value is divisible by 5.
    // The optimal path lands on 255 (÷5=0) and uses B's secret branch once.
    // Every press is permanent — reset restores value but not uses.
    _Stage(
      name: 'demon',
      startValue: 1,
      target: 286,
      buttons: [
        _ButtonDef([(v) => v * 2, (v) => v + 11, (v) => v * 3, (v) => v - 17],
            maxUses: 8),
        _ButtonDef([(v) => v % 5 == 0 ? v + 31 : v - 4], maxUses: 6),
        _ButtonDef([(v) => v * 2], maxUses: 3),
      ],
    ),
  ];

  // ── game logic ────────────────────────────────────────────────────────────

  void _pressOp(int btnIdx) {
    if (_stageComplete || _finished) return;
    final stage = _stages[_stageIndex];
    final btn = stage.buttons[btnIdx];
    final counts = _buttonPressCounts[_stageIndex];

    if (btn.maxUses != null && counts[btnIdx] >= btn.maxUses!) return;

    final opIdx = counts[btnIdx] % btn.cycle.length;
    int result = btn.cycle[opIdx](_value);
    if (stage.modulus != null) result = result % stage.modulus!;
    result = result.clamp(0, stage.modulus ?? _maxVal);

    setState(() {
      _buttonPressCounts[_stageIndex][btnIdx]++;
      _value = result;
      _moveCount++;
    });

    if (_value == stage.target) _onStageCleared();
  }

  void _reset() {
    if (_stageComplete || _finished) return;
    HapticFeedback.selectionClick();
    // Resets value only — button press counts and remaining uses stay.
    setState(() {
      _value = _stages[_stageIndex].startValue;
      _resetCount++;
    });
  }

  void _onStageCleared() {
    HapticFeedback.mediumImpact();
    final score = _scoreForResets(_resetCount);
    _stageScores.add(score);
    _recordStageMetrics();
    setState(() => _stageComplete = true);
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;
      _advanceOrFinish();
    });
  }

  // First reset is free. Each additional reset costs 0.25.
  // 0–1 resets → 1.0, 2 → 0.75, 3 → 0.50, 4 → 0.25, 5+ → 0.0
  double _scoreForResets(int resets) {
    return (1.0 - 0.25 * (resets - 1).clamp(0, 4)).clamp(0.0, 1.0);
  }

  void _skipStage() {
    if (_stageComplete || _finished) return;
    _stageScores.add(0.0);
    _recordStageMetrics();
    _advanceOrFinish();
  }

  void _recordStageMetrics() {
    final i = _stageIndex + 1;
    _metrics['stage_${i}_resets'] = _resetCount;
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
        _resetCount = 0;
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
      _stageScores.add(0.0);
    }
    final avgScore =
        _stageScores.fold(0.0, (a, b) => a + b) / _stages.length;
    widget.onComplete(
      LevelOutcome(
        score: avgScore,
        metrics: {
          for (int i = 1; i <= _stages.length; i++)
            'stage_${i}_score': _metrics['stage_${i}_score'] ?? 0,
          'total_resets': [
            for (int i = 1; i <= _stages.length; i++)
              (_metrics['stage_${i}_resets'] as int?) ?? 0,
          ].fold<int>(0, (sum, r) => sum + r),
        },
        visibleMetricKeys: [
          for (int i = 1; i <= _stages.length; i++) 'stage_${i}_score',
        ],
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

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
                          stage.buttons.length,
                          (i) => _buildOpButton(i, stage),
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
                            label: Text(
                              _resetCount == 0
                                  ? 'reset value'
                                  : 'reset value  ($_resetCount)',
                              style:
                                  const TextStyle(color: NunuColors.errorLight),
                            ),
                          ),
                          TextButton(
                            onPressed: _stageComplete ? null : _skipStage,
                            child: const Text(
                              'skip stage',
                              style: TextStyle(
                                color: NunuColors.textSecondary,
                              ),
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
    final resets = _resetCount;
    final score = _stageScores.last;
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
          resets == 0
              ? 'no resets — perfect'
              : resets == 1
                  ? '1 reset (free)'
                  : '$resets resets  ·  score ${(score * 100).round()}%',
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
                style: textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                ),
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

  Widget _buildOpButton(int idx, _Stage stage) {
    final btn = stage.buttons[idx];
    final counts = _buttonPressCounts[_stageIndex];
    final usesLeft =
        btn.maxUses != null ? btn.maxUses! - counts[idx] : null;
    final exhausted = usesLeft != null && usesLeft <= 0;
    final color = _buttonColors[idx % _buttonColors.length];
    final enabled = !_stageComplete && !exhausted;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton(
          onPressed: enabled ? () => _pressOp(idx) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: color.withValues(alpha: enabled ? 0.7 : 0.2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_buttonLabels[idx]),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  usesLeft != null ? '×$usesLeft left' : '',
                  style: TextStyle(
                    fontSize: 10,
                    color: usesLeft != null
                        ? (usesLeft <= 1
                            ? NunuColors.errorLight
                            : NunuColors.textSecondary)
                        : Colors.transparent,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
