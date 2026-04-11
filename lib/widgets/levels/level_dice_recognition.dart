import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/dice.dart';
import 'dart:math';

class LevelDiceRecognition extends LevelWidget {
  const LevelDiceRecognition({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelDiceRecognition> createState() => _LevelDiceRecognitionState();
}

class _LevelDiceRecognitionState extends State<LevelDiceRecognition> {
  final _answerController = TextEditingController();
  late List<int> _diceValues;
  final int _numberOfDice = 5;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _generateDice();
  }

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  void _generateDice() {
    final random = Random();
    _diceValues = List.generate(_numberOfDice, (_) => random.nextInt(6) + 1);
  }

  String get _correctAnswer {
    return _diceValues.join();
  }

  Future<void> _checkAnswer() async {
    final userAnswer = _answerController.text.trim();

    if (userAnswer.isEmpty) {
      _showSnackbar('Please enter the dice numbers', Colors.orange);
      return;
    }

    setState(() {
      _isChecking = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    if (userAnswer == _correctAnswer) {
      // Correct!
      widget.onComplete(LevelOutcome(score: 1));
    } else {
      // Wrong - generate new dice
      _showSnackbar('Incorrect! Try the new dice', Colors.red);
      setState(() {
        _generateDice();
        _answerController.clear();
        _isChecking = false;
      });
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Instruction
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: NunuColors.primaryMain.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NunuColors.primaryMain.withValues(alpha: 0.5),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.casino_outlined,
                        color: NunuColors.primaryMain,
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Enter the numbers from left to right',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Dice display
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: _diceValues
                        .map((value) => DiceWidget(value: value, size: 50))
                        .toList(),
                  ),
                ),

                const SizedBox(height: 24),

                // Input field
                Container(
                  constraints: const BoxConstraints(maxWidth: 260),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _answerController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: _numberOfDice,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          hintText: '•' * _numberOfDice,
                          hintStyle: TextStyle(
                            color: Colors.grey.shade600,
                            letterSpacing: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade700),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: NunuColors.primaryMain,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 16),

                      FilledButton(
                        onPressed: _isChecking ? null : _checkAnswer,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 14,
                          ),
                          backgroundColor: NunuColors.primaryMain,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isChecking
                            ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'SUBMIT',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Hint
                Text(
                  'Example: if dice show 3, 1, 5, 2, 4 enter "31524"',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}