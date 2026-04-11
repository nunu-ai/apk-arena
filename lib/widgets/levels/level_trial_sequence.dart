import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Trial & Error Sequence
//
// 7 steps. Each step shows 5 emoji items. One is correct.
// Pick the wrong one → reset to step 1 (same sequence).
// Through trial and error, discover and memorize the full sequence.
// ---------------------------------------------------------------------------

class LevelTrialSequence extends LevelWidget {
  const LevelTrialSequence({super.key, required super.onComplete});

  @override
  State<LevelTrialSequence> createState() => _LevelTrialSequenceState();
}

class _LevelTrialSequenceState extends State<LevelTrialSequence>
    with SingleTickerProviderStateMixin {
  // -- data -------------------------------------------------------------------

  /// Each step: 5 emoji options to display.
  static const List<List<String>> _stepOptions = [
    ['🎹', '⭐', '🎫', '🎻', '🚗'],
    ['🔮', '🎯', '🍕', '🎸', '💎'],
    ['🌙', '🎲', '🚀', '🎧', '🌈'],
    ['🎨', '🕹️', '🧩', '🎭', '🔥'],
    ['🍩', '🎮', '💧', '🏆', '🎤'],
    ['🛸', '🎪', '🎈', '🎀', '📷'],
    ['🌊', '🎂', '📱', '🗝️', '🎰'],
  ];

  /// The ONE correct emoji at each step.
  static const List<String> _correctEmojis = [
    '⭐',
    '🍕',
    '🚀',
    '🧩',
    '🏆',
    '🎈',
    '🗝️',
  ];

  static const int _totalSteps = 7;

  // -- state ------------------------------------------------------------------

  int _currentStep = 0;
  int _attempts = 1;
  bool _isAnimating = false;
  int? _tappedIndex;
  bool? _lastTapCorrect;

  /// Shuffled order for every step (regenerated on reset).
  late List<List<String>> _shuffledOptions;
  final Random _random = Random();

  late AnimationController _shakeController;
  late Animation<double> _shakeOffset;

  // -- lifecycle --------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _shuffleAllOptions();

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _shakeOffset = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0, end: 12), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 12, end: -10), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -10, end: 8), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 8, end: -4), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -4, end: 0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  // -- helpers ----------------------------------------------------------------

  void _shuffleAllOptions() {
    _shuffledOptions = _stepOptions.map((options) {
      final shuffled = List<String>.from(options);
      shuffled.shuffle(_random);
      return shuffled;
    }).toList();
  }

  // -- actions ----------------------------------------------------------------

  void _onItemTapped(int index) {
    if (_isAnimating) return;

    final tappedEmoji = _shuffledOptions[_currentStep][index];
    final isCorrect = tappedEmoji == _correctEmojis[_currentStep];

    setState(() {
      _tappedIndex = index;
      _lastTapCorrect = isCorrect;
      _isAnimating = true;
    });

    if (!isCorrect) {
      _shakeController.forward(from: 0);
    }

    final delay = isCorrect
        ? const Duration(milliseconds: 500)
        : const Duration(milliseconds: 750);

    Future.delayed(delay, () {
      if (!mounted) return;

      if (isCorrect) {
        if (_currentStep == _totalSteps - 1) {
          widget.onComplete(LevelOutcome(score: 1, metrics: {'attempts': _attempts, 'steps': _totalSteps}));
        } else {
          setState(() {
            _currentStep++;
            _tappedIndex = null;
            _lastTapCorrect = null;
            _isAnimating = false;
          });
        }
      } else {
        setState(() {
          _attempts++;
          _currentStep = 0;
          _tappedIndex = null;
          _lastTapCorrect = null;
          _isAnimating = false;
          _shuffleAllOptions();
        });
      }
    });
  }

  // -- build ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              _buildProgressBar(),
              const SizedBox(height: 20),
              _buildStepLabel(),
              const SizedBox(height: 6),
              _buildAttemptLabel(),
              const Spacer(flex: 2),
              _buildFeedback(),
              const SizedBox(height: 20),
              AnimatedBuilder(
                animation: _shakeOffset,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(_shakeOffset.value, 0),
                    child: child,
                  );
                },
                child: _buildOptions(),
              ),
              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
    );
  }

  // -- progress bar -----------------------------------------------------------

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_totalSteps, (i) {
        final isCompleted = i < _currentStep;
        final isCurrent = i == _currentStep;

        Color color;
        if (isCompleted) {
          color = NunuColors.successMain;
        } else if (isCurrent && _lastTapCorrect == true) {
          color = NunuColors.successMain;
        } else if (isCurrent) {
          color = NunuColors.primaryMain;
        } else {
          color = NunuColors.backgroundPaper;
        }

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: EdgeInsets.only(right: i < _totalSteps - 1 ? 4 : 0),
            height: 6,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(3),
              color: color,
            ),
          ),
        );
      }),
    );
  }

  // -- labels -----------------------------------------------------------------

  Widget _buildStepLabel() {
    return Text(
      'step ${_currentStep + 1} of $_totalSteps',
      style: const TextStyle(
        color: NunuColors.textSecondary,
        fontSize: 14,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildAttemptLabel() {
    return Text(
      'attempt #$_attempts',
      style: TextStyle(
        color: NunuColors.primaryLight.withValues(alpha: 0.5),
        fontSize: 12,
      ),
    );
  }

  // -- feedback ---------------------------------------------------------------

  Widget _buildFeedback() {
    if (_lastTapCorrect == false) {
      return const Text(
        'wrong — back to start',
        style: TextStyle(
          color: NunuColors.errorMain,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      );
    }
    if (_lastTapCorrect == true) {
      return const Text(
        '✓',
        style: TextStyle(
          color: NunuColors.successMain,
          fontSize: 28,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return const Text(
      'pick one',
      style: TextStyle(color: NunuColors.textSecondary, fontSize: 14),
    );
  }

  // -- option tiles -----------------------------------------------------------

  Widget _buildOptions() {
    final options = _shuffledOptions[_currentStep];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // row 1: items 0, 1, 2
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: 16),
              _buildOptionTile(i, options[i]),
            ],
          ],
        ),
        const SizedBox(height: 16),
        // row 2: items 3, 4
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildOptionTile(3, options[3]),
            const SizedBox(width: 16),
            _buildOptionTile(4, options[4]),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionTile(int index, String emoji) {
    final bool isTapped = _tappedIndex == index;
    final bool isCorrectTap = isTapped && _lastTapCorrect == true;
    final bool isWrongTap = isTapped && _lastTapCorrect == false;

    Color borderColor = NunuColors.primaryDark.withValues(alpha: 0.5);
    Color bgColor = NunuColors.backgroundPaper;

    if (isCorrectTap) {
      borderColor = NunuColors.successMain;
      bgColor = NunuColors.successMain.withValues(alpha: 0.15);
    } else if (isWrongTap) {
      borderColor = NunuColors.errorMain;
      bgColor = NunuColors.errorMain.withValues(alpha: 0.15);
    }

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          boxShadow: isTapped
              ? [
                  BoxShadow(
                    color: borderColor.withValues(alpha: 0.4),
                    blurRadius: 14,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(child: Text(emoji, style: const TextStyle(fontSize: 40))),
      ),
    );
  }
}
