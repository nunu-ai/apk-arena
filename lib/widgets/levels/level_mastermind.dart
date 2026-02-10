import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelMastermind extends LevelWidget {
  const LevelMastermind({super.key, required super.onComplete});

  @override
  State<LevelMastermind> createState() => _LevelMastermindState();
}

class _LevelMastermindState extends State<LevelMastermind> {
  static const int _codeLength = 4;
  static const int _maxGuesses = 10;
  static const int _numColors = 6;

  static const List<Color> _palette = [
    Color(0xFFFF5630), // red
    Color(0xFF22C55E), // green
    Color(0xFF4FC3F7), // blue
    Color(0xFFFFAB00), // yellow
    Color(0xFFE55CD8), // pink
    Color(0xFF805CE5), // purple
  ];

  static const List<String> _colorNames = ['R', 'G', 'B', 'Y', 'P', 'V'];

  late List<int> _secretCode;
  final List<List<int>> _guesses = [];
  final List<List<int>> _feedback = []; // [exact, misplaced] per guess
  List<int> _currentGuess = [];
  bool _done = false;
  bool _won = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    // Use unique colors only – no duplicates, so white-peg feedback is unambiguous
    final available = List.generate(_numColors, (i) => i);
    available.shuffle(rng);
    _secretCode = available.sublist(0, _codeLength);
  }

  List<int> _evaluate(List<int> guess) {
    int exact = 0;
    int misplaced = 0;
    final codeUsed = List.filled(_codeLength, false);
    final guessUsed = List.filled(_codeLength, false);

    // First pass: exact matches
    for (int i = 0; i < _codeLength; i++) {
      if (guess[i] == _secretCode[i]) {
        exact++;
        codeUsed[i] = true;
        guessUsed[i] = true;
      }
    }

    // Second pass: misplaced
    for (int i = 0; i < _codeLength; i++) {
      if (guessUsed[i]) continue;
      for (int j = 0; j < _codeLength; j++) {
        if (codeUsed[j]) continue;
        if (guess[i] == _secretCode[j]) {
          misplaced++;
          codeUsed[j] = true;
          break;
        }
      }
    }

    return [exact, misplaced];
  }

  void _addColor(int colorIdx) {
    if (_done || _currentGuess.length >= _codeLength) return;
    setState(() {
      _currentGuess.add(colorIdx);
      HapticFeedback.selectionClick();
    });
  }

  void _removeLastColor() {
    if (_done || _currentGuess.isEmpty) return;
    setState(() {
      _currentGuess.removeLast();
    });
  }

  void _submitGuess() {
    if (_done || _currentGuess.length != _codeLength) return;

    setState(() {
      final result = _evaluate(_currentGuess);
      _guesses.add(List.of(_currentGuess));
      _feedback.add(result);
      _currentGuess = [];

      if (result[0] == _codeLength) {
        _won = true;
        _done = true;
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onComplete(true);
        });
      } else if (_guesses.length >= _maxGuesses) {
        _done = true;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onComplete(false);
        });
      } else {
        HapticFeedback.lightImpact();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildGuessHistory()),
            _buildCurrentGuessRow(),
            const SizedBox(height: 8),
            _buildColorPicker(),
            const SizedBox(height: 8),
            _buildLegend(),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'guess ${_guesses.length + 1} / $_maxGuesses',
            style: const TextStyle(color: NunuColors.textSecondary, fontSize: 14),
          ),
          if (_done && !_won)
            Row(
              children: [
                const Text('answer: ', style: TextStyle(color: NunuColors.textSecondary, fontSize: 14)),
                ..._secretCode.map((c) => Container(
                      margin: const EdgeInsets.only(left: 3),
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _palette[c],
                        shape: BoxShape.circle,
                      ),
                    )),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildGuessHistory() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      itemCount: _guesses.length,
      itemBuilder: (_, i) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              // Guess number
              SizedBox(
                width: 28,
                child: Text(
                  '${i + 1}',
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // Color pegs
              ...List.generate(_codeLength, (j) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _palette[_guesses[i][j]],
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _palette[_guesses[i][j]].withOpacity(0.4),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(width: 16),
              // Feedback pegs
              _buildFeedbackPegs(_feedback[i]),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFeedbackPegs(List<int> feedback) {
    final exact = feedback[0];
    final misplaced = feedback[1];
    final empty = _codeLength - exact - misplaced;

    return Row(
      children: [
        ...List.generate(exact, (_) => _feedbackPeg(NunuColors.errorMain)),
        ...List.generate(misplaced, (_) => _feedbackPeg(Colors.white)),
        ...List.generate(empty, (_) => _feedbackPeg(NunuColors.backgroundPaper)),
      ],
    );
  }

  Widget _feedbackPeg(Color color) {
    return Container(
      margin: const EdgeInsets.all(2),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
    );
  }

  Widget _buildCurrentGuessRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 28),
          // Current guess slots
          ...List.generate(_codeLength, (j) {
            final hasColor = j < _currentGuess.length;
            return GestureDetector(
              onTap: hasColor && j == _currentGuess.length - 1 ? _removeLastColor : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasColor ? _palette[_currentGuess[j]] : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: hasColor
                        ? _palette[_currentGuess[j]]
                        : NunuColors.primaryDark.withOpacity(0.5),
                    width: 2,
                  ),
                ),
              ),
            );
          }),
          const Spacer(),
          // Submit button
          GestureDetector(
            onTap: _currentGuess.length == _codeLength ? _submitGuess : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: _currentGuess.length == _codeLength
                    ? NunuColors.primaryMain
                    : NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'check',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPicker() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(_numColors, (i) {
          return GestureDetector(
            onTap: () => _addColor(i),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _palette[i],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _palette[i].withOpacity(0.5),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  _colorNames[i],
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildLegend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _feedbackPeg(NunuColors.errorMain),
          const SizedBox(width: 4),
          Flexible(
            child: Text('exact match',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: NunuColors.textSecondary, fontSize: 11)),
          ),
          const SizedBox(width: 12),
          _feedbackPeg(Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text('wrong position',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: NunuColors.textSecondary, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
