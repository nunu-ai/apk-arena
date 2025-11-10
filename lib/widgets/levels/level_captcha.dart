import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelCaptcha extends LevelWidget {
  const LevelCaptcha({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelCaptcha> createState() => _LevelCaptchaState();
}

class _LevelCaptchaState extends State<LevelCaptcha> with SingleTickerProviderStateMixin {
  bool _isChecked = false;
  bool _isVerifying = false;
  bool _showPuzzle = false;
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;

  // Puzzle state
  final List<String> _allEmojis = [
    '🚗', '🚕', '🚙', '🚌', // cars (indices 0-3)
    '🚦', '🚥', // traffic lights
    '🚲', '🛴', '🛵', // bikes
    '🌳', '🌲', '🌴', // trees
    '🏠', '🏢', '🏪', // buildings
    '🔥', '💧', '⚡', // other
  ];

  final Set<String> _carEmojis = {'🚗', '🚕', '🚙', '🚌'};
  final Set<int> _selectedIndices = {};
  late List<String> _gridItems;
  late Set<int> _correctIndices; // Indices where cars actually are in the grid

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _initializePuzzle();
  }

  void _initializePuzzle() {
    // Create a grid with some cars and some non-cars
    _gridItems = [];
    _correctIndices = {};

    // Add 3-4 cars
    final random = Random();
    final numCars = 3 + random.nextInt(2); // 3 or 4 cars

    // Get car emojis
    final carList = _carEmojis.toList()..shuffle(random);
    for (int i = 0; i < numCars; i++) {
      _gridItems.add(carList[i]);
    }

    // Add non-cars to fill up to 9 items
    final nonCars = _allEmojis.where((e) => !_carEmojis.contains(e)).toList()..shuffle(random);
    for (int i = 0; i < 9 - numCars; i++) {
      _gridItems.add(nonCars[i]);
    }

    // Shuffle the grid
    _gridItems.shuffle(random);

    // Find where the cars ended up
    for (int i = 0; i < _gridItems.length; i++) {
      if (_carEmojis.contains(_gridItems[i])) {
        _correctIndices.add(i);
      }
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  void _handleCheckboxTap() {
    if (!_isChecked && !_isVerifying) {
      setState(() {
        _isVerifying = true;
      });

      // Show the puzzle after a short delay
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          setState(() {
            _isVerifying = false;
            _showPuzzle = true;
          });
        }
      });
    }
  }

  void _handlePuzzleSubmit() {
    // Check if selected indices match the correct indices
    if (_selectedIndices.length == _correctIndices.length &&
        _selectedIndices.containsAll(_correctIndices)) {
      // Correct!
      setState(() {
        _showPuzzle = false;
        _isChecked = true;
      });
      _checkController.forward();

      Future.delayed(const Duration(milliseconds: 1000), () {
        widget.onComplete(true);
      });
    } else {
      // Wrong! Reset puzzle
      setState(() {
        _selectedIndices.clear();
        _initializePuzzle();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect! Try again.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _handleSkipPuzzle() {
    setState(() {
      _showPuzzle = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.grey.shade700,
                width: 1,
              ),
            ),
            child: _showPuzzle ? _buildPuzzle() : _buildCheckbox(),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'BEFORE YOU CONTINUE!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 32),

        // Checkbox area
        GestureDetector(
          onTap: _handleCheckboxTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Checkbox
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: _isChecked ? Colors.green : Colors.white,
                    border: Border.all(
                      color: _isChecked ? Colors.green : Colors.grey.shade400,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _isVerifying
                      ? Padding(
                    padding: const EdgeInsets.all(4),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.grey.shade600,
                      ),
                    ),
                  )
                      : _isChecked
                      ? ScaleTransition(
                    scale: _checkAnimation,
                    child: const Icon(
                      Icons.check,
                      size: 20,
                      color: Colors.white,
                    ),
                  )
                      : null,
                ),
                const SizedBox(width: 12),
                const Text(
                  "I'm not a robot",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // reCAPTCHA branding
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.refresh,
              size: 16,
              color: Colors.grey.shade500,
            ),
            const SizedBox(width: 4),
            Text(
              'reCAPTCHA',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Privacy - Terms',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPuzzle() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Select all squares with',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: _handleSkipPuzzle,
            ),
          ],
        ),
        const Text(
          'cars',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),

        // 3x3 Grid
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final isSelected = _selectedIndices.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedIndices.remove(index);
                    } else {
                      _selectedIndices.add(index);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    border: Border.all(
                      color: isSelected ? NunuColors.primaryMain : Colors.grey.shade600,
                      width: isSelected ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _gridItems[index],
                      style: const TextStyle(fontSize: 40),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedIndices.clear();
                  _initializePuzzle();
                });
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refresh'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey.shade400,
              ),
            ),
            FilledButton(
              onPressed: _selectedIndices.isEmpty ? null : _handlePuzzleSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade700,
              ),
              child: const Text('Verify'),
            ),
          ],
        ),
      ],
    );
  }
}