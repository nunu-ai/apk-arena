import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

class LevelActionCounter extends LevelWidget {
  const LevelActionCounter({super.key, required super.onComplete});

  @override
  State<LevelActionCounter> createState() => _LevelActionCounterState();
}

class _ButtonSpec {
  _ButtonSpec({required this.color, required this.label});
  final Color color;
  final String label;
}

class _LevelActionCounterState extends State<LevelActionCounter> {
  final Random _rng = Random();
  static const _swapChance = 0.35;

  final List<_ButtonSpec> _allSpecs = [
    _ButtonSpec(color: const Color(0xFFE53935), label: 'red'),
    _ButtonSpec(color: const Color(0xFF1E88E5), label: 'blue'),
    _ButtonSpec(color: const Color(0xFF43A047), label: 'green'),
    _ButtonSpec(color: const Color(0xFFF9A825), label: 'yellow'),
    _ButtonSpec(color: const Color(0xFFFF6D00), label: 'orange'),
    _ButtonSpec(color: const Color(0xFF8E24AA), label: 'purple'),
  ];

  int _stage = 0;
  int _stagesCorrect = 0;
  bool _transitioning = false;
  bool _lastCorrect = false;

  // Stage 0: 4 fixed buttons
  late List<int> _s0Order;
  late int _s0Target, _s0Idx;
  int _s0Pressed = 0;

  // Stage 1: 4 visible + 2 benched
  late List<int> _s1Visible, _s1Bench;
  late int _s1TargetA, _s1TargetB, _s1IdxA, _s1IdxB;
  int _s1PressedA = 0, _s1PressedB = 0;

  // Stage 2: free press + quiz
  late List<int> _s2Visible, _s2Bench;
  late int _s2MinPresses;
  final Map<int, int> _s2Counts = {};
  int _s2Total = 0;
  bool _s2Quiz = false;
  final Map<int, TextEditingController> _s2Controllers = {};

  @override
  void initState() {
    super.initState();
    _initStage0();
    _initStage1();
    _initStage2();
  }

  void _initStage0() {
    _s0Order = [0, 1, 2, 3]..shuffle(_rng);
    _s0Target = 4 + _rng.nextInt(6);
    _s0Idx = _rng.nextInt(4);
  }

  void _initStage1() {
    _s1IdxA = _rng.nextInt(6);
    do {
      _s1IdxB = _rng.nextInt(6);
    } while (_s1IdxB == _s1IdxA);
    _s1TargetA = 3 + _rng.nextInt(5);
    _s1TargetB = 3 + _rng.nextInt(5);
    final others = List.generate(6, (i) => i)
      ..remove(_s1IdxA)
      ..remove(_s1IdxB)
      ..shuffle(_rng);
    _s1Visible = [_s1IdxA, _s1IdxB, others[0], others[1]]..shuffle(_rng);
    _s1Bench = [others[2], others[3]];
  }

  void _initStage2() {
    _s2MinPresses = 12 + _rng.nextInt(7);
    for (var i = 0; i < 6; i++) {
      _s2Counts[i] = 0;
      _s2Controllers[i] = TextEditingController();
    }
    final all = List.generate(6, (i) => i)..shuffle(_rng);
    _s2Visible = all.sublist(0, 4);
    _s2Bench = all.sublist(4);
  }

  @override
  void dispose() {
    for (final c in _s2Controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _swapAndShuffle(List<int> visible, List<int> bench) {
    if (_rng.nextDouble() < _swapChance && bench.isNotEmpty) {
      final vi = _rng.nextInt(visible.length);
      final bi = _rng.nextInt(bench.length);
      final tmp = visible[vi];
      visible[vi] = bench[bi];
      bench[bi] = tmp;
    }
    visible.shuffle(_rng);
  }

  void _forceSwap(List<int> visible, List<int> bench) {
    if (bench.isNotEmpty) {
      final vi = _rng.nextInt(visible.length);
      final bi = _rng.nextInt(bench.length);
      final tmp = visible[vi];
      visible[vi] = bench[bi];
      bench[bi] = tmp;
    }
    visible.shuffle(_rng);
  }

  // --- Stage 0 ---
  void _onTapS0(int idx) {
    if (idx == _s0Idx) _s0Pressed++;
    setState(() => _s0Order.shuffle(_rng));
  }

  void _submitS0() => _advance(_s0Pressed == _s0Target);

  // --- Stage 1 ---
  void _onTapS1(int idx) {
    if (idx == _s1IdxA) _s1PressedA++;
    if (idx == _s1IdxB) _s1PressedB++;
    setState(() => _swapAndShuffle(_s1Visible, _s1Bench));
  }

  void _nextS1() => setState(() => _forceSwap(_s1Visible, _s1Bench));

  void _submitS1() =>
      _advance(_s1PressedA == _s1TargetA && _s1PressedB == _s1TargetB);

  // --- Stage 2 ---
  void _onTapS2(int idx) {
    setState(() {
      _s2Counts[idx] = (_s2Counts[idx] ?? 0) + 1;
      _s2Total++;
      _swapAndShuffle(_s2Visible, _s2Bench);
    });
  }

  void _donePressing() => setState(() => _s2Quiz = true);

  void _submitS2() {
    int correctCount = 0;
    for (var i = 0; i < 6; i++) {
      final entered = int.tryParse(_s2Controllers[i]!.text.trim()) ?? -1;
      if (entered == (_s2Counts[i] ?? 0)) correctCount++;
    }
    _advanceFinal(correctCount);
  }

  void _advance(bool correct) {
    if (correct) _stagesCorrect++;
    setState(() {
      _lastCorrect = correct;
      _transitioning = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _stage++;
        _transitioning = false;
      });
    });
  }

  void _advanceFinal(int s2Correct) {
    final s2Fraction = s2Correct / 6;
    setState(() {
      _lastCorrect = s2Correct == 6;
      _transitioning = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final score = (_stagesCorrect + s2Fraction) / 3;
      widget.onComplete(LevelOutcome(
        score: score,
        metrics: {
          'stages_passed': _stagesCorrect,
          's2_colors_correct': s2Correct,
          'total_stages': 3,
        },
      ));
    });
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            _progressDots(),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_transitioning) return _buildTransition();
    switch (_stage) {
      case 0:
        return _buildStage0();
      case 1:
        return _buildStage1();
      case 2:
        return _s2Quiz ? _buildS2Quiz() : _buildS2Press();
      default:
        return const SizedBox.shrink();
    }
  }

  // ---- progress ----

  Widget _progressDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final past = i < _stage;
        final active = i == _stage;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: past
                ? NunuColors.primaryMain
                : active
                    ? NunuColors.primaryLight
                    : NunuColors.primaryDark.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }

  // ---- transition ----

  Widget _buildTransition() {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (_lastCorrect ? NunuColors.successMain : NunuColors.errorMain)
              .withValues(alpha: 0.12),
        ),
        child: Icon(
          _lastCorrect ? Icons.check_rounded : Icons.close_rounded,
          color:
              _lastCorrect ? NunuColors.successMain : NunuColors.errorMain,
          size: 48,
        ),
      ),
    );
  }

  // ---- stage 0 ----

  Widget _buildStage0() {
    final label = _allSpecs[_s0Idx].label;
    return _stageShell(
      instruction: 'press $label exactly $_s0Target times.',
      grid: _colorGrid(_s0Order, _onTapS0),
      actions: [_actionBtn(onPressed: _submitS0)],
    );
  }

  // ---- stage 1 ----

  Widget _buildStage1() {
    final a = _allSpecs[_s1IdxA].label;
    final b = _allSpecs[_s1IdxB].label;
    return _stageShell(
      instruction:
          'press $a exactly $_s1TargetA times and $b exactly $_s1TargetB times.',
      grid: _colorGrid(_s1Visible, _onTapS1),
      actions: [
        _nextBtn(onPressed: _nextS1),
        const SizedBox(width: 12),
        _actionBtn(onPressed: _submitS1),
      ],
    );
  }

  // ---- stage 2 press ----

  Widget _buildS2Press() {
    final canDone = _s2Total >= _s2MinPresses;
    return _stageShell(
      instruction: 'press at least $_s2MinPresses buttons.',
      grid: _colorGrid(_s2Visible, _onTapS2),
      actions: [
        _actionBtn(
          label: 'done',
          icon: Icons.done_all_rounded,
          onPressed: canDone ? _donePressing : null,
        ),
      ],
    );
  }

  // ---- stage 2 quiz ----

  Widget _buildS2Quiz() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard('how many times did you press each color?'),
          const SizedBox(height: 28),
          for (var row = 0; row < 3; row++) ...[
            Row(
              children: [
                Expanded(child: _quizCell(row * 2)),
                const SizedBox(width: 14),
                Expanded(child: _quizCell(row * 2 + 1)),
              ],
            ),
            if (row < 2) const SizedBox(height: 14),
          ],
          const SizedBox(height: 28),
          _actionBtn(
            label: 'submit answers',
            onPressed: _submitS2,
            expand: true,
          ),
        ],
      ),
    );
  }

  // ===================== SHARED WIDGETS =====================

  Widget _stageShell({
    required String instruction,
    required Widget grid,
    required List<Widget> actions,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 28),
          _instructionCard(instruction),
          const Spacer(),
          grid,
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: actions,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _instructionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: NunuColors.primaryDark.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: NunuColors.primaryLight,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.45,
        ),
      ),
    );
  }

  // ---- color grid (2x2) ----

  Widget _colorGrid(List<int> visible, void Function(int) onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _colorChip(visible[0], onTap)),
            const SizedBox(width: 14),
            Expanded(child: _colorChip(visible[1], onTap)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _colorChip(visible[2], onTap)),
            const SizedBox(width: 14),
            Expanded(child: _colorChip(visible[3], onTap)),
          ],
        ),
      ],
    );
  }

  Widget _colorChip(int specIdx, void Function(int) onTap) {
    final spec = _allSpecs[specIdx];
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: spec.color.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: spec.color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => onTap(specIdx),
          borderRadius: BorderRadius.circular(16),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: SizedBox(
            height: 76,
            child: Center(
              child: Text(
                spec.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---- quiz cell ----

  Widget _quizCell(int colorIdx) {
    final spec = _allSpecs[colorIdx];
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: spec.color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            height: 5,
            decoration: BoxDecoration(
              color: spec.color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            spec.label,
            style: TextStyle(
              color: spec.color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _s2Controllers[colorIdx],
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(
                color: Colors.white.withValues(alpha: 0.15),
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 10,
              ),
              filled: true,
              fillColor: NunuColors.backgroundDefault,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: spec.color.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: spec.color.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: spec.color, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- action buttons ----

  Widget _actionBtn({
    VoidCallback? onPressed,
    String label = 'submit',
    IconData icon = Icons.check_rounded,
    bool expand = false,
  }) {
    final enabled = onPressed != null;
    final btn = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        backgroundColor: enabled
            ? NunuColors.successMain
            : NunuColors.successMain.withValues(alpha: 0.2),
        foregroundColor: enabled ? Colors.white : Colors.white38,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
    return expand
        ? SizedBox(width: double.infinity, height: 50, child: btn)
        : btn;
  }

  Widget _nextBtn({required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.shuffle_rounded, size: 18),
      label: const Text(
        'next',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: NunuColors.primaryLight,
        side: BorderSide(
          color: NunuColors.primaryMain.withValues(alpha: 0.4),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }
}
