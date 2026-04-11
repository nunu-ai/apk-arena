import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelMathSprint extends LevelWidget {
  const LevelMathSprint({super.key, required super.onComplete});

  @override
  State<LevelMathSprint> createState() => _LevelMathSprintState();
}

class _LevelMathSprintState extends State<LevelMathSprint>
    with SingleTickerProviderStateMixin {
  static const int _timeLimitSeconds = 60;

  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _rng = Random();

  Timer? _timer;
  int _secondsRemaining = _timeLimitSeconds;
  bool _started = false;
  bool _done = false;

  int _a = 0, _b = 0;
  String _op = '+';
  int _answer = 0;

  int _correctCount = 0;
  int _wrongCount = 0;
  int _streak = 0;
  int _maxStreak = 0;

  // Flash feedback
  Color? _flashColor;
  Timer? _flashTimer;

  @override
  void initState() {
    super.initState();
    _generateProblem();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _flashTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _generateProblem() {
    switch (_rng.nextInt(4)) {
      case 0: // Addition
        _a = _rng.nextInt(90) + 10;
        _b = _rng.nextInt(90) + 10;
        _op = '+';
        _answer = _a + _b;
        break;
      case 1: // Subtraction (positive result)
        _a = _rng.nextInt(90) + 10;
        _b = _rng.nextInt(_a) + 1;
        _op = '\u2212';
        _answer = _a - _b;
        break;
      case 2: // Multiplication
        _a = _rng.nextInt(12) + 2;
        _b = _rng.nextInt(12) + 2;
        _op = '\u00D7';
        _answer = _a * _b;
        break;
      case 3: // Division (clean result)
        _answer = _rng.nextInt(12) + 2;
        _b = _rng.nextInt(12) + 2;
        _a = _answer * _b;
        _op = '\u00F7';
        break;
    }
  }

  void _startTimer() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _finish();
        }
      });
    });
  }

  void _submitAnswer() {
    _startTimer();
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    final userAnswer = int.tryParse(text);
    if (userAnswer == null) return;

    setState(() {
      if (userAnswer == _answer) {
        _correctCount++;
        _streak++;
        if (_streak > _maxStreak) _maxStreak = _streak;
        _showFlash(NunuColors.successMain);
        HapticFeedback.lightImpact();
      } else {
        _wrongCount++;
        _streak = 0;
        _showFlash(NunuColors.errorMain);
        HapticFeedback.heavyImpact();
      }

      _controller.clear();
      _generateProblem();
    });
  }

  void _showFlash(Color color) {
    _flashColor = color;
    _flashTimer?.cancel();
    _flashTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _flashColor = null);
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timer?.cancel();

    final totalAttempts = _correctCount + _wrongCount;
    final accuracy =
        totalAttempts > 0 ? (_correctCount / totalAttempts * 100) : 0.0;

    Future.delayed(const Duration(milliseconds: 300), () {
      widget.onComplete(LevelOutcome(score: 1, metrics: {
        'score': _correctCount,
        'accuracy': '${accuracy.toStringAsFixed(1)}%',
        'attempts': totalAttempts,
        'best_streak': _maxStreak,
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      color: _flashColor?.withOpacity(0.15) ?? NunuColors.backgroundDefault,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTimerBar(),
            const Spacer(),
            _buildProblem(),
            const SizedBox(height: 32),
            _buildInput(),
            const SizedBox(height: 16),
            _buildSubmitButton(),
            const Spacer(),
            _buildStats(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_secondsRemaining}s',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: _secondsRemaining <= 10
                ? NunuColors.errorMain
                : NunuColors.primaryMain,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: NunuColors.successMain,
                  size: 18),
              const SizedBox(width: 6),
              Text(
                '$_correctCount',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimerBar() {
    final pct = _secondsRemaining / _timeLimitSeconds;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: NunuColors.backgroundPaper),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      pct < 0.2 ? NunuColors.errorMain : NunuColors.primaryMain,
                      NunuColors.secondaryMain,
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

  Widget _buildProblem() {
    return Column(
      children: [
        Text(
          '$_a $_op $_b',
          style: const TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: NunuColors.textPrimary,
            letterSpacing: 4,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          '= ?',
          style: TextStyle(
            fontSize: 28,
            color: NunuColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildInput() {
    return SizedBox(
      width: 180,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: !_done,
        keyboardType: const TextInputType.numberWithOptions(signed: true),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
        onSubmitted: (_) => _submitAnswer(),
        decoration: InputDecoration(
          hintText: '?',
          hintStyle:
              TextStyle(color: NunuColors.textSecondary.withOpacity(0.3)),
          filled: true,
          fillColor: NunuColors.backgroundPaper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: NunuColors.primaryDark),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: NunuColors.primaryDark.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                const BorderSide(color: NunuColors.primaryMain, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: 180,
      child: FilledButton(
        onPressed: _done ? null : _submitAnswer,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: NunuColors.primaryMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'SUBMIT',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }

  Widget _buildStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statChip('streak', '$_streak'),
        _statChip('best', '$_maxStreak'),
        _statChip('wrong', '$_wrongCount'),
      ],
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: NunuColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: NunuColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
