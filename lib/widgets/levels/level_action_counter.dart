import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
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
  final Random _rng = SeedService.instance.createRandom();
  static const _swapChance = 0.35;
  static const _totalStages = 5;

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
  double _scoreUnits = 0;
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
  int _s2CorrectAnswers = 0;

  // Stage 3: checksum defusal
  late List<int> _s3Visible, _s3Bench;
  late int _s3PressTarget;
  int _s3Presses = 0;
  int _s3Checksum = 0;
  bool _s3Quiz = false;
  final TextEditingController _s3Controller = TextEditingController();
  bool _s3Solved = false;

  // Stage 4: blackout reveal memory
  late int _s4RoundsTotal;
  late List<int> _s4CurrentColors;
  bool _s4Revealed = false;
  bool _s4Quiz = false;
  final List<int> _s4PressedColors = [];
  final List<int> _s4PressedSlots = [];
  final List<int?> _s4Selections = [];
  int _s4CorrectRounds = 0;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: (_scoreUnits / _totalStages).clamp(0.0, 1.0),
          metrics: {'stages_completed': _stagesCorrect},
        ));
    _initStage0();
    _initStage1();
    _initStage2();
    _initStage3();
    _initStage4();
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

  void _initStage3() {
    _s3PressTarget = 8 + _rng.nextInt(3);
    _s3Presses = 0;
    _s3Checksum = 0;
    _s3Quiz = false;
    _s3Controller.clear();
    final all = List.generate(6, (i) => i)..shuffle(_rng);
    _s3Visible = all.sublist(0, 4);
    _s3Bench = all.sublist(4);
  }

  void _initStage4() {
    _s4RoundsTotal = 5;
    _s4CurrentColors = _rollBlackoutColors();
    _s4Revealed = false;
    _s4Quiz = false;
    _s4PressedColors.clear();
    _s4PressedSlots.clear();
    _s4Selections.clear();
    for (var i = 0; i < _s4RoundsTotal; i++) {
      _s4Selections.add(null);
    }
  }

  @override
  void dispose() {
    for (final c in _s2Controllers.values) {
      c.dispose();
    }
    _s3Controller.dispose();
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

  List<int> _rollBlackoutColors() {
    final colors = List.generate(6, (i) => i)..shuffle(_rng);
    return colors.sublist(0, 4)..shuffle(_rng);
  }

  void _completeStage({
    required double scoreUnits,
    required bool fullyCorrect,
  }) {
    _scoreUnits += scoreUnits.clamp(0.0, 1.0);
    if (fullyCorrect) _stagesCorrect++;
    setState(() {
      _lastCorrect = fullyCorrect;
      _transitioning = true;
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_stage >= _totalStages - 1) {
        widget.onComplete(
          LevelOutcome(
            score: (_scoreUnits / _totalStages).clamp(0.0, 1.0),
            metrics: {
              'stages_passed': _stagesCorrect,
              's2_colors_correct': _s2CorrectAnswers,
              's4_rounds_correct': _s4CorrectRounds,
              's4_rounds_total': _s4RoundsTotal,
            },
          ),
        );
        return;
      }
      setState(() {
        _stage++;
        _transitioning = false;
      });
    });
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
    _s2CorrectAnswers = correctCount;
    _completeStage(
      scoreUnits: correctCount / 6,
      fullyCorrect: correctCount == 6,
    );
  }

  void _advance(bool correct) {
    _completeStage(scoreUnits: correct ? 1 : 0, fullyCorrect: correct);
  }

  // --- Stage 3 ---
  int _applyChecksumStep(int idx, int checksum) {
    switch (idx) {
      case 0:
        return checksum + 3;
      case 1:
        return checksum - 2;
      case 2:
        return checksum + 5;
      case 3:
        return checksum - 4;
      case 4:
        return checksum * 2;
      case 5:
        return -checksum;
      default:
        return checksum;
    }
  }

  void _onTapS3(int idx) {
    if (_s3Presses >= _s3PressTarget) return;
    setState(() {
      _s3Checksum = _applyChecksumStep(idx, _s3Checksum);
      _s3Presses++;
      _swapAndShuffle(_s3Visible, _s3Bench);
    });
  }

  void _doneS3() => setState(() => _s3Quiz = true);

  void _submitS3() {
    final entered = int.tryParse(_s3Controller.text.trim());
    _s3Solved = entered == _s3Checksum;
    _completeStage(scoreUnits: _s3Solved ? 1 : 0, fullyCorrect: _s3Solved);
  }

  // --- Stage 4 ---
  void _onTapS4(int slot) {
    if (_s4Revealed) return;
    setState(() {
      _s4PressedSlots.add(slot);
      _s4PressedColors.add(_s4CurrentColors[slot]);
      _s4Revealed = true;
    });
  }

  void _nextS4() {
    if (!_s4Revealed) return;
    setState(() {
      if (_s4PressedColors.length >= _s4RoundsTotal) {
        _s4Quiz = true;
      } else {
        _s4CurrentColors = _rollBlackoutColors();
        _s4Revealed = false;
      }
    });
  }

  void _submitS4() {
    int correct = 0;
    for (var i = 0; i < _s4RoundsTotal; i++) {
      if (_s4Selections[i] == _s4PressedColors[i]) correct++;
    }
    _s4CorrectRounds = correct;
    _completeStage(
      scoreUnits: correct / _s4RoundsTotal,
      fullyCorrect: correct == _s4RoundsTotal,
    );
  }

  void _selectS4Answer(int roundIdx, int colorIdx) {
    setState(() {
      _s4Selections[roundIdx] = colorIdx;
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
            LevelHud(stageText: '${_stage + 1}/$_totalStages'),
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
      case 3:
        return _s3Quiz ? _buildS3Quiz() : _buildS3Press();
      case 4:
        return _s4Quiz ? _buildS4Quiz() : _buildS4Press();
      default:
        return const SizedBox.shrink();
    }
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
          color: _lastCorrect ? NunuColors.successMain : NunuColors.errorMain,
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

  Widget _buildS3Press() {
    final instruction = _s3Presses == 0
        ? 'press exactly $_s3PressTarget buttons, then enter the final checksum.\n'
              'red +3, blue -2, green +5, yellow -4, orange x2, purple flips the sign.'
        : 'press exactly $_s3PressTarget buttons, then enter the final checksum.';
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard(instruction),
          const SizedBox(height: 18),
          _miniStatusCard('presses: $_s3Presses / $_s3PressTarget'),
          const SizedBox(height: 28),
          _colorGrid(_s3Visible, _onTapS3),
          const SizedBox(height: 28),
          _actionBtn(
            label: 'enter checksum',
            icon: Icons.calculate_rounded,
            onPressed: _s3Presses == _s3PressTarget ? _doneS3 : null,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildS3Quiz() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard('what is the final checksum?'),
          const SizedBox(height: 28),
          _singleAnswerField(
            controller: _s3Controller,
            label: 'final checksum',
            hintText: '0',
          ),
          const SizedBox(height: 28),
          _actionBtn(
            label: 'submit checksum',
            onPressed: _submitS3,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildS4Press() {
    final completedRounds = _s4PressedColors.length;
    final round = (completedRounds + (_s4Revealed ? 0 : 1)).clamp(
      1,
      _s4RoundsTotal,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'tap one black button. after the reveal, press next.',
          ),
          const SizedBox(height: 18),
          _miniStatusCard('round $round / $_s4RoundsTotal'),
          const SizedBox(height: 28),
          _blackoutGrid(),
          const SizedBox(height: 28),
          _actionBtn(
            label: completedRounds >= _s4RoundsTotal ? 'start quiz' : 'next',
            icon: Icons.navigate_next_rounded,
            onPressed: _s4Revealed ? _nextS4 : null,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildS4Quiz() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard('for each round, pick the button you pressed.'),
          const SizedBox(height: 28),
          for (var i = 0; i < _s4RoundsTotal; i++) ...[
            _s4RoundPicker(i),
            if (i < _s4RoundsTotal - 1) const SizedBox(height: 14),
          ],
          const SizedBox(height: 28),
          _actionBtn(
            label: 'submit answers',
            onPressed: _s4Selections.every((selection) => selection != null)
                ? _submitS4
                : null,
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
          Row(mainAxisAlignment: MainAxisAlignment.center, children: actions),
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
        border: Border.all(
          color: NunuColors.primaryDark.withValues(alpha: 0.3),
        ),
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

  Widget _miniStatusCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NunuColors.primaryMain.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
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

  Widget _blackoutGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(child: _blackoutCell(0)),
            const SizedBox(width: 14),
            Expanded(child: _blackoutCell(1)),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(child: _blackoutCell(2)),
            const SizedBox(width: 14),
            Expanded(child: _blackoutCell(3)),
          ],
        ),
      ],
    );
  }

  Widget _blackoutCell(int slot) {
    final revealed = _s4Revealed;
    final selected =
        revealed && _s4PressedSlots.isNotEmpty && _s4PressedSlots.last == slot;
    final specIdx = _s4CurrentColors[slot];
    final spec = _allSpecs[specIdx];
    final color = revealed ? spec.color : Colors.black;
    final label = revealed ? spec.label : 'black';
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (revealed ? spec.color : Colors.black).withValues(
              alpha: 0.25,
            ),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: revealed ? null : () => _onTapS4(slot),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? NunuColors.primaryLight
                    : Colors.white.withValues(alpha: 0.08),
                width: selected ? 2.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
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
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.15)),
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

  Widget _singleAnswerField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NunuColors.primaryMain.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NunuColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.18)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              filled: true,
              fillColor: NunuColors.backgroundDefault,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: NunuColors.primaryMain.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: NunuColors.primaryMain.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: NunuColors.primaryMain,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _s4RoundPicker(int roundIdx) {
    final selected = _s4Selections[roundIdx];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NunuColors.primaryMain.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'round ${roundIdx + 1}',
            style: const TextStyle(
              color: NunuColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_allSpecs.length, (colorIdx) {
              final spec = _allSpecs[colorIdx];
              final isSelected = selected == colorIdx;
              return GestureDetector(
                onTap: () => _selectS4Answer(roundIdx, colorIdx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: spec.color.withValues(
                      alpha: isSelected ? 0.95 : 0.2,
                    ),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? Colors.white
                          : spec.color.withValues(alpha: 0.5),
                      width: isSelected ? 2 : 1.2,
                    ),
                  ),
                  child: Text(
                    spec.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        side: BorderSide(color: NunuColors.primaryMain.withValues(alpha: 0.4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      ),
    );
  }
}
