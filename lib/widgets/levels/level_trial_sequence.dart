import 'dart:async';
import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelTrialSequence extends LevelWidget {
  const LevelTrialSequence({super.key, required super.onComplete});

  @override
  State<LevelTrialSequence> createState() => _LevelTrialSequenceState();
}

class _LevelTrialSequenceState extends State<LevelTrialSequence>
    with SingleTickerProviderStateMixin {
  static const Duration _sessionDuration = Duration(minutes: 30);
  static const int _targetMaxLength = 100;
  static const int _optionsPerStep = 5;
  static const int _startingSequenceLength = 7;
  static const int _maxSequenceLength = 20;
  static const List<String> _emojiPool = [
    '⭐',
    '🍕',
    '🚀',
    '🧩',
    '🏆',
    '🎈',
    '🗝️',
    '🎯',
    '🎮',
    '🔥',
    '🌙',
    '💎',
    '🎧',
    '🎨',
    '🍩',
    '🛸',
    '📷',
    '🌊',
    '🎂',
    '📱',
    '🎭',
    '🎪',
    '🎤',
    '🎲',
    '💧',
    '🕹️',
    '🎀',
    '🚗',
    '🎸',
    '🌈',
  ];

  final Random _random = SeedService.instance.createRandom();

  late final AnimationController _shakeController;
  late final Animation<double> _shakeOffset;
  late final DateTime _endsAt;

  Timer? _countdownTimer;

  late int _sequenceLength;
  late List<String> _correctSequence;
  late List<List<String>> _shuffledOptions;

  int _currentStep = 0;
  int _attempts = 1;
  int _maxLengthAchieved = 0;
  bool _isAnimating = false;
  bool _sessionComplete = false;
  int? _tappedIndex;
  bool? _lastTapCorrect;
  Duration _timeRemaining = _sessionDuration;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: (_maxLengthAchieved / _targetMaxLength).clamp(0.0, 1.0),
          metrics: {'max_sequence_length': _maxLengthAchieved},
        ));
    _endsAt = DateTime.now().add(_sessionDuration);
    _sequenceLength = _startingSequenceLength;
    _startSequence(resetAttempts: true);
    _startCountdown();

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
    _countdownTimer?.cancel();
    _shakeController.dispose();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _sessionComplete) return;

      final remaining = _endsAt.difference(DateTime.now());
      if (remaining <= Duration.zero) {
        _finishSession();
        return;
      }

      setState(() {
        _timeRemaining = remaining;
      });
    });
  }

  void _startSequence({required bool resetAttempts}) {
    _correctSequence = List.generate(
      _sequenceLength,
      (_) => _emojiPool[_random.nextInt(_emojiPool.length)],
    );
    _shuffledOptions = List.generate(
      _sequenceLength,
      (step) => _buildStepOptions(_correctSequence[step]),
    );
    _currentStep = 0;
    _tappedIndex = null;
    _lastTapCorrect = null;
    _isAnimating = false;

    if (resetAttempts) {
      _attempts = 1;
    }
  }

  void _extendSequence() {
    final nextEmoji = _emojiPool[_random.nextInt(_emojiPool.length)];
    _correctSequence.add(nextEmoji);
    _shuffledOptions.add(_buildStepOptions(nextEmoji));
    _sequenceLength = _correctSequence.length;
  }

  List<String> _buildStepOptions(String correctEmoji) {
    final options = <String>{correctEmoji};
    while (options.length < _optionsPerStep) {
      options.add(_emojiPool[_random.nextInt(_emojiPool.length)]);
    }
    final shuffled = options.toList()..shuffle(_random);
    return shuffled;
  }

  void _handleWrongTap() {
    _shakeController.forward(from: 0);

    setState(() {
      _attempts++;
      _currentStep = 0;
      _tappedIndex = null;
      _lastTapCorrect = null;
      _isAnimating = false;
      _shuffledOptions = List.generate(
        _sequenceLength,
        (step) => _buildStepOptions(_correctSequence[step]),
      );
    });
  }

  void _finishSession() {
    if (_sessionComplete) return;
    _sessionComplete = true;
    _countdownTimer?.cancel();

    final cappedMaxLength = min(_maxLengthAchieved, _targetMaxLength);
    widget.onComplete(
      LevelOutcome(
        score: cappedMaxLength / _targetMaxLength,
        metrics: {'max_sequence_length': _maxLengthAchieved},
      ),
    );
  }

  void _onItemTapped(int index) {
    if (_isAnimating || _sessionComplete) return;

    final tappedEmoji = _shuffledOptions[_currentStep][index];
    final isCorrect = tappedEmoji == _correctSequence[_currentStep];

    setState(() {
      _tappedIndex = index;
      _lastTapCorrect = isCorrect;
      _isAnimating = true;
    });

    final delay = isCorrect
        ? const Duration(milliseconds: 350)
        : const Duration(milliseconds: 750);

    Future.delayed(delay, () {
      if (!mounted || _sessionComplete) return;

      if (isCorrect) {
        final reachedLength = _currentStep + 1;
        _maxLengthAchieved = max(_maxLengthAchieved, reachedLength);

        if (_currentStep == _sequenceLength - 1) {
          setState(() {
            _extendSequence();
            _currentStep++;
            _tappedIndex = null;
            _lastTapCorrect = null;
            _isAnimating = false;
          });
        } else {
          setState(() {
            _currentStep++;
            _tappedIndex = null;
            _lastTapCorrect = null;
            _isAnimating = false;
          });
        }
      } else {
        _handleWrongTap();
      }
    });
  }

  String get _timeLabel {
    final minutes = _timeRemaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = _timeRemaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(
              timerText: _timeLabel,
              trailing: Text(
                'attempt $_attempts · max $_maxLengthAchieved',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  children: [
                    _buildProgressBar(),
                    const SizedBox(height: 20),
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
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      children: List.generate(_sequenceLength, (i) {
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
            margin: EdgeInsets.only(right: i < _sequenceLength - 1 ? 4 : 0),
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

  Widget _buildAttemptLabel() {
    return Text(
      'attempt #$_attempts',
      style: TextStyle(
        color: NunuColors.primaryLight.withValues(alpha: 0.65),
        fontSize: 12,
      ),
    );
  }

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
        'correct',
        style: TextStyle(
          color: NunuColors.successMain,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return const Text(
      'find the next symbol',
      style: TextStyle(color: NunuColors.textSecondary, fontSize: 14),
    );
  }

  Widget _buildOptions() {
    final options = _shuffledOptions[_currentStep];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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
    final isTapped = _tappedIndex == index;
    final isCorrectTap = isTapped && _lastTapCorrect == true;
    final isWrongTap = isTapped && _lastTapCorrect == false;

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
