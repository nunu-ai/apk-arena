import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSequenceMemory extends LevelWidget {
  const LevelSequenceMemory({super.key, required super.onComplete});

  @override
  State<LevelSequenceMemory> createState() => _LevelSequenceMemoryState();
}

class _LevelSequenceMemoryState extends State<LevelSequenceMemory>
    with SingleTickerProviderStateMixin {
  static const int _gridSize = 9; // 3x3 grid
  static const int _sequencesToWin = 3;
  static const int _startingLength = 4;

  final Random _random = Random();

  List<int> _sequence = [];
  int _currentInputIndex = 0;
  int _completedSequences = 0;
  bool _isShowingSequence = true;
  bool _isComplete = false;
  bool _showingError = false;
  int _highlightedButton = -1;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));
    _startNewSequence();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _startNewSequence() {
    final length = _startingLength + _completedSequences;
    _sequence = List.generate(length, (_) => _random.nextInt(_gridSize));
    _currentInputIndex = 0;
    _isShowingSequence = true;
    _showSequence();
  }

  Future<void> _showSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));

    for (int i = 0; i < _sequence.length && mounted; i++) {
      if (!mounted) return;
      setState(() => _highlightedButton = _sequence[i]);
      _pulseController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted) return;
      setState(() => _highlightedButton = -1);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (mounted) {
      setState(() {
        _isShowingSequence = false;
        _highlightedButton = -1;
      });
    }
  }

  void _onButtonPressed(int index) {
    if (_isShowingSequence || _isComplete || _showingError) return;

    setState(() => _highlightedButton = index);
    _pulseController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _highlightedButton = -1);
    });

    if (_sequence[_currentInputIndex] == index) {
      // Correct input
      _currentInputIndex++;

      if (_currentInputIndex >= _sequence.length) {
        // Completed this sequence
        _completedSequences++;

        if (_completedSequences >= _sequencesToWin) {
          // Won the level
          setState(() => _isComplete = true);
          widget.onComplete(true);
        } else {
          // Start next sequence
          _startNewSequence();
        }
      }
    } else {
      // Wrong input - show error and restart
      setState(() => _showingError = true);

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted) {
          setState(() {
            _showingError = false;
            _currentInputIndex = 0;
            _isShowingSequence = true;
          });
          _showSequence();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Progress indicators
            _buildProgressIndicators(),
            const SizedBox(height: 24),
            // Status text
            _buildStatusText(),
            // Main button grid
            Expanded(child: _buildButtonGrid()),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicators() {
    return Column(
      children: [
        Text(
          "SEQUENCE ${_completedSequences + 1} OF $_sequencesToWin",
          style: const TextStyle(
            color: NunuColors.textSecondary,
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_sequencesToWin, (index) {
            final isCompleted = index < _completedSequences;
            final isCurrent = index == _completedSequences && !_isComplete;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted
                    ? NunuColors.successMain
                    : isCurrent
                    ? NunuColors.primaryMain.withValues(alpha: 0.2)
                    : NunuColors.backgroundPaper,
                border: Border.all(
                  color: isCompleted
                      ? NunuColors.successMain
                      : isCurrent
                      ? NunuColors.primaryMain
                      : NunuColors.primaryDark.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, color: Colors.white, size: 20)
                    : Text(
                        "${index + 1}",
                        style: TextStyle(
                          color: isCurrent
                              ? NunuColors.primaryMain
                              : NunuColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildStatusText() {
    String statusText;
    Color statusColor;

    if (_showingError) {
      statusText = "WRONG! TRY AGAIN";
      statusColor = NunuColors.errorMain;
    } else if (_isShowingSequence) {
      statusText = "WATCH THE SEQUENCE";
      statusColor = NunuColors.infoMain;
    } else {
      statusText = "YOUR TURN";
      statusColor = NunuColors.successMain;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          statusText,
          key: ValueKey(statusText),
          style: TextStyle(
            color: statusColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showingError
                  ? NunuColors.errorMain.withValues(alpha: 0.6)
                  : NunuColors.primaryDark.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: NunuColors.primaryDarker.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _gridSize,
            itemBuilder: (context, index) => _buildButton(index),
          ),
        ),
      ),
    );
  }

  Widget _buildButton(int index) {
    final isHighlighted = _highlightedButton == index;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isHighlighted ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => _onButtonPressed(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? NunuColors.primaryMain
                    : NunuColors.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted
                      ? NunuColors.primaryLight
                      : NunuColors.primaryDark,
                  width: 2,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: NunuColors.primaryMain.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
