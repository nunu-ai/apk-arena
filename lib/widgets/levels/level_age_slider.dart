import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelAgeSlider extends LevelWidget {
  const LevelAgeSlider({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelAgeSlider> createState() => _LevelAgeSliderState();
}

class _LevelAgeSliderState extends State<LevelAgeSlider> {
  double _currentAge = 18.0;
  late int _targetAge;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Generate a random target age between 21 and 65
    final random = Random();
    _targetAge = 21 + random.nextInt(45); // 21 to 65
  }

  void _handleSubmit() {
    if (_currentAge.round() == _targetAge) {
      setState(() {
        _isSubmitting = true;
      });

      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(true);
      });
    } else {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Wrong age! You selected ${_currentAge.round()}, but we need $_targetAge',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Target age display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NunuColors.primaryMain.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: NunuColors.primaryMain.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.cake_outlined,
                        color: NunuColors.primaryMain,
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Required Age',
                        style: TextStyle(
                          fontSize: 16,
                          color: NunuColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_targetAge',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: NunuColors.primaryLight,
                          letterSpacing: -2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'years old',
                        style: TextStyle(
                          fontSize: 12,
                          color: NunuColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Current age display
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 28),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade700,
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Your Age',
                        style: TextStyle(
                          fontSize: 12,
                          color: NunuColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_currentAge.round()}',
                        style: const TextStyle(
                          fontSize: 44,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: -3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                // Slider
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade900,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: NunuColors.primaryMain,
                          inactiveTrackColor: Colors.grey.shade700,
                          thumbColor: NunuColors.primaryLight,
                          overlayColor: NunuColors.primaryMain.withValues(alpha: 0.2),
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 14,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 24,
                          ),
                        ),
                        child: Slider(
                          value: _currentAge,
                          min: 13,
                          max: 99,
                          divisions: 86, // 13 to 99 = 86 possible values
                          onChanged: _isSubmitting ? null : (value) {
                            setState(() {
                              _currentAge = value;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '13',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          Text(
                            '99',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Submit button
                FilledButton(
                  onPressed: _isSubmitting ? null : _handleSubmit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    backgroundColor: NunuColors.primaryMain,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: Colors.grey.shade700,
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                      : const Text(
                    'CONFIRM AGE',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}