import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelEstimation extends LevelWidget {
  const LevelEstimation({super.key, required super.onComplete});

  @override
  State<LevelEstimation> createState() => _LevelEstimationState();
}

class _LevelEstimationState extends State<LevelEstimation> {
  static const int _totalRounds = 8;
  static const Duration _showDuration = Duration(seconds: 3);

  final _rng = Random();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  int _currentRound = 0;
  int _dotCount = 0;
  List<_Dot> _dots = [];
  bool _showingDots = true;
  bool _done = false;
  Timer? _hideTimer;

  double _totalAccuracy = 0;
  int _perfectGuesses = 0; // within 10%
  final List<_RoundResult> _results = [];

  @override
  void initState() {
    super.initState();
    _startRound();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startRound() {
    _dotCount = _rng.nextInt(41) + 10; // 10-50
    _dots = List.generate(_dotCount, (_) {
      final hue = _rng.nextDouble() * 60 + 260; // purple-pink range
      return _Dot(
        x: _rng.nextDouble() * 0.88 + 0.06,
        y: _rng.nextDouble() * 0.88 + 0.06,
        size: _rng.nextDouble() * 6 + 8,
        color: HSLColor.fromAHSL(1, hue, 0.8, 0.65).toColor(),
      );
    });
    _showingDots = true;
    _controller.clear();
    setState(() {});

    _hideTimer?.cancel();
    _hideTimer = Timer(_showDuration, () {
      if (mounted) {
        setState(() => _showingDots = false);
      }
    });
  }

  void _submitGuess() {
    final guess = int.tryParse(_controller.text.trim());
    if (guess == null || guess < 0) return;

    final error = (_dotCount == 0) ? 0.0 : (guess - _dotCount).abs() / _dotCount;
    final accuracy = ((1 - error) * 100).clamp(0.0, 100.0);
    _totalAccuracy += accuracy;
    if (error <= 0.10) _perfectGuesses++;

    _results.add(_RoundResult(actual: _dotCount, guess: guess, accuracy: accuracy));
    HapticFeedback.lightImpact();

    setState(() {
      _currentRound++;
    });

    if (_currentRound >= _totalRounds) {
      _finish();
    } else {
      _startRound();
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;

    final avgAccuracy = _totalAccuracy / _totalRounds;

    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onComplete(LevelOutcome(score: 1, metrics: {
        'avg_accuracy': '${avgAccuracy.toStringAsFixed(1)}%',
        'perfect': '$_perfectGuesses / $_totalRounds',
        'best_round': '${_results.map((r) => r.accuracy).reduce(max).toStringAsFixed(0)}%',
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildRoundDots(),
            const SizedBox(height: 12),
            Expanded(child: _buildDotsArea()),
            const SizedBox(height: 12),
            if (!_showingDots && !_done) ...[
              _buildInput(),
              const SizedBox(height: 12),
              _buildSubmitButton(),
            ],
            if (_showingDots && !_done)
              const Text(
                'count carefully...',
                style: TextStyle(
                  color: NunuColors.warningMain,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('round',
                style: TextStyle(
                    color: NunuColors.textSecondary, fontSize: 12)),
            Text(
              '${_currentRound + 1} / $_totalRounds',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: NunuColors.primaryMain,
              ),
            ),
          ],
        ),
        if (_results.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text('last round',
                  style: TextStyle(
                      color: NunuColors.textSecondary, fontSize: 12)),
              Text(
                '${_results.last.accuracy.toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: _results.last.accuracy > 80
                      ? NunuColors.successMain
                      : _results.last.accuracy > 50
                          ? NunuColors.warningMain
                          : NunuColors.errorMain,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRoundDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalRounds, (i) {
        Color color;
        if (i < _results.length) {
          final acc = _results[i].accuracy;
          color = acc > 80
              ? NunuColors.successMain
              : acc > 50
                  ? NunuColors.warningMain
                  : NunuColors.errorMain;
        } else if (i == _currentRound) {
          color = NunuColors.primaryMain;
        } else {
          color = NunuColors.backgroundPaper;
        }
        return Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }

  Widget _buildDotsArea() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showingDots
              ? NunuColors.primaryMain.withOpacity(0.5)
              : NunuColors.primaryDark.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: _showingDots
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return Stack(
                    children: _dots.map((dot) {
                      return Positioned(
                        left: dot.x * constraints.maxWidth - dot.size / 2,
                        top: dot.y * constraints.maxHeight - dot.size / 2,
                        child: Container(
                          width: dot.size,
                          height: dot.size,
                          decoration: BoxDecoration(
                            color: dot.color,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: dot.color.withOpacity(0.4),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              )
            : const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.visibility_off,
                        color: NunuColors.textSecondary, size: 48),
                    SizedBox(height: 12),
                    Text(
                      'how many dots did you see?',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInput() {
    return SizedBox(
      width: 160,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
        onSubmitted: (_) => _submitGuess(),
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
      width: 160,
      child: FilledButton(
        onPressed: _submitGuess,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          backgroundColor: NunuColors.primaryMain,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'GUESS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}

class _Dot {
  final double x, y, size;
  final Color color;
  const _Dot({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
  });
}

class _RoundResult {
  final int actual, guess;
  final double accuracy;
  const _RoundResult({
    required this.actual,
    required this.guess,
    required this.accuracy,
  });
}
