import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelWordle extends LevelWidget {
  const LevelWordle({super.key, required super.onComplete});

  @override
  State<LevelWordle> createState() => _LevelWordleState();
}

class _LevelWordleState extends State<LevelWordle> {
  static const int _maxGuesses = 6;
  static const int _wordLength = 5;

  // Curated list of common 5-letter words
  static const List<String> _wordList = [
    'CRANE', 'SLATE', 'TRACE', 'CRATE', 'STARE',
    'SNARE', 'HEART', 'ABOUT', 'SUGAR', 'LIGHT',
    'PLANE', 'BRAIN', 'CHAIR', 'DANCE', 'EARTH',
    'FLAME', 'GHOST', 'HOUSE', 'JUICE', 'KNIFE',
    'LEMON', 'MANGO', 'NIGHT', 'OCEAN', 'PIANO',
    'QUEEN', 'ROBOT', 'STONE', 'TIGER', 'ULTRA',
    'VOICE', 'WATER', 'XENON', 'YACHT', 'ZEBRA',
    'APPLE', 'BLAZE', 'CLIMB', 'DREAM', 'EAGLE',
    'FRAME', 'GLOBE', 'HOVER', 'INPUT', 'JOLLY',
    'PIXEL', 'QUILT', 'RIVER', 'STORM', 'TOWER',
  ];

  late String _targetWord;
  final List<String> _guesses = [];
  String _currentGuess = '';
  bool _done = false;
  final Map<String, int> _letterStates = {}; // 0=absent, 1=present, 2=correct

  @override
  void initState() {
    super.initState();
    _targetWord = _wordList[Random().nextInt(_wordList.length)];
  }

  // Returns list of states: 0=absent, 1=wrong position, 2=correct
  List<int> _evaluateGuess(String guess) {
    final result = List.filled(_wordLength, 0);
    final targetChars = _targetWord.split('');
    final guessChars = guess.split('');
    final used = List.filled(_wordLength, false);

    // First pass: exact matches
    for (int i = 0; i < _wordLength; i++) {
      if (guessChars[i] == targetChars[i]) {
        result[i] = 2;
        used[i] = true;
      }
    }

    // Second pass: wrong position
    for (int i = 0; i < _wordLength; i++) {
      if (result[i] == 2) continue;
      for (int j = 0; j < _wordLength; j++) {
        if (!used[j] && guessChars[i] == targetChars[j]) {
          result[i] = 1;
          used[j] = true;
          break;
        }
      }
    }

    return result;
  }

  void _addLetter(String letter) {
    if (_done || _currentGuess.length >= _wordLength) return;
    setState(() {
      _currentGuess += letter;
      HapticFeedback.selectionClick();
    });
  }

  void _removeLetter() {
    if (_done || _currentGuess.isEmpty) return;
    setState(() {
      _currentGuess = _currentGuess.substring(0, _currentGuess.length - 1);
    });
  }

  void _submitGuess() {
    if (_done || _currentGuess.length != _wordLength) return;

    setState(() {
      final guess = _currentGuess.toUpperCase();
      _guesses.add(guess);
      final eval = _evaluateGuess(guess);

      // Update letter states for keyboard coloring
      for (int i = 0; i < _wordLength; i++) {
        final letter = guess[i];
        final current = _letterStates[letter] ?? -1;
        if (eval[i] > current) {
          _letterStates[letter] = eval[i];
        }
      }

      _currentGuess = '';

      if (guess == _targetWord) {
        _done = true;
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onComplete(LevelOutcome(score: 1, metrics: {'guesses': _guesses.length, 'maxGuesses': _maxGuesses}));
        });
      } else if (_guesses.length >= _maxGuesses) {
        _done = true;
        HapticFeedback.heavyImpact();
        Future.delayed(const Duration(milliseconds: 600), () {
          widget.onComplete(LevelOutcome(score: 0, metrics: {'guesses': _guesses.length, 'maxGuesses': _maxGuesses}));
        });
      } else {
        HapticFeedback.lightImpact();
      }
    });
  }

  Color _cellColor(int state) {
    switch (state) {
      case 2: return NunuColors.successMain;
      case 1: return NunuColors.warningMain;
      case 0: return const Color(0xFF2A2040);
      default: return Colors.transparent;
    }
  }

  Color _keyColor(String letter) {
    final state = _letterStates[letter];
    if (state == null) return NunuColors.backgroundPaper;
    return _cellColor(state);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            if (_done && _guesses.last != _targetWord)
              Text(
                _targetWord,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.errorMain,
                  letterSpacing: 4,
                ),
              ),
            const SizedBox(height: 8),
            Expanded(child: _buildGrid()),
            _buildKeyboard(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(_maxGuesses, (row) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_wordLength, (col) {
                String letter = '';
                int state = -1;

                if (row < _guesses.length) {
                  letter = _guesses[row][col];
                  state = _evaluateGuess(_guesses[row])[col];
                } else if (row == _guesses.length && col < _currentGuess.length) {
                  letter = _currentGuess[col];
                }

                final hasLetter = letter.isNotEmpty;
                final isRevealed = row < _guesses.length;

                return AnimatedContainer(
                  duration: Duration(milliseconds: 200 + col * 100),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: isRevealed ? _cellColor(state) : Colors.transparent,
                    border: Border.all(
                      color: isRevealed
                          ? _cellColor(state)
                          : hasLetter
                              ? NunuColors.primaryDark
                              : NunuColors.primaryDark.withOpacity(0.4),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      letter,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildKeyboard() {
    const rows = [
      ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
      ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
      ['ENTER', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '⌫'],
    ];

    return Column(
      children: rows.map((row) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map((key) {
              final isSpecial = key == 'ENTER' || key == '⌫';
              final width = isSpecial ? 56.0 : 32.0;

              return GestureDetector(
                onTap: () {
                  if (key == 'ENTER') {
                    _submitGuess();
                  } else if (key == '⌫') {
                    _removeLetter();
                  } else {
                    _addLetter(key);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: width,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isSpecial ? NunuColors.primaryDark : _keyColor(key),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(
                    child: Text(
                      key,
                      style: TextStyle(
                        fontSize: isSpecial ? 11 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
