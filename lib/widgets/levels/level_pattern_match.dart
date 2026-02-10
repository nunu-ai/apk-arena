import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelPatternMatch extends LevelWidget {
  const LevelPatternMatch({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelPatternMatch> createState() => _LevelPatternMatchState();
}

class _LevelPatternMatchState extends State<LevelPatternMatch> {
  static const int _gridSize = 8;
  final Random _random = Random();

  late List<List<bool>> _targetPattern;
  late List<List<bool>> _playerPattern;

  // Pattern definitions (8x8 grids)
  // 1 = filled, 0 = empty
  static final List<List<List<int>>> _patterns = [
    // Smiley face
    [
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 0, 0, 0, 0, 1, 0],
      [1, 0, 1, 0, 0, 1, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 1],
      [1, 0, 1, 0, 0, 1, 0, 1],
      [1, 0, 0, 1, 1, 0, 0, 1],
      [0, 1, 0, 0, 0, 0, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
    ],
    // Rocket/spaceship
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 0, 1, 1, 1, 1, 0, 1],
      [1, 0, 1, 0, 0, 1, 0, 1],
      [1, 0, 0, 0, 0, 0, 0, 1],
    ],
    // Heart
    [
      [0, 1, 1, 0, 0, 1, 1, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 0, 0, 0, 0, 0],
    ],
    // Arrow (pointing up)
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [1, 1, 0, 1, 1, 0, 1, 1],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
    ],
    // Star
    [
      [0, 0, 0, 1, 1, 0, 0, 0],
      [0, 0, 0, 1, 1, 0, 0, 0],
      [1, 1, 1, 1, 1, 1, 1, 1],
      [0, 1, 1, 1, 1, 1, 1, 0],
      [0, 0, 1, 1, 1, 1, 0, 0],
      [0, 1, 1, 0, 0, 1, 1, 0],
      [1, 1, 0, 0, 0, 0, 1, 1],
      [1, 0, 0, 0, 0, 0, 0, 1],
    ],
  ];

  @override
  void initState() {
    super.initState();
    _initializePattern();
  }

  void _initializePattern() {
    // Pick a random pattern
    final patternIndex = _random.nextInt(_patterns.length);
    final pattern = _patterns[patternIndex];

    // Convert to List<List<bool>>
    _targetPattern = pattern
        .map((row) => row.map((cell) => cell == 1).toList())
        .toList();

    // Initialize empty player pattern
    _playerPattern = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => false),
    );
  }

  void _toggleCell(int row, int col) {
    setState(() {
      _playerPattern[row][col] = !_playerPattern[row][col];
    });
  }

  bool _checkMatch() {
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        if (_targetPattern[row][col] != _playerPattern[row][col]) {
          return false;
        }
      }
    }
    return true;
  }

  void _onSubmit() {
    widget.onComplete(_checkMatch());
  }

  void _onClear() {
    setState(() {
      _playerPattern = List.generate(
        _gridSize,
        (_) => List.generate(_gridSize, (_) => false),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Reference label
              const Text(
                'reference',
                style: TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              // Reference grid (smaller, read-only)
              _buildReferenceGrid(),
              const SizedBox(height: 24),
              // Your pattern label
              const Text(
                'your pattern',
                style: TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              // Player grid (interactive)
              Expanded(
                child: _buildPlayerGrid(),
              ),
              const SizedBox(height: 16),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _onClear,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NunuColors.textSecondary),
                        foregroundColor: NunuColors.textSecondary,
                      ),
                      child: const Text('clear'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NunuColors.primaryMain,
                      ),
                      child: const Text('submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReferenceGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reference grid is smaller - about 40% of available width
        final gridSize = min(constraints.maxWidth * 0.5, 160.0);

        return SizedBox(
          width: gridSize,
          height: gridSize,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: _gridSize * _gridSize,
            itemBuilder: (context, index) {
              final row = index ~/ _gridSize;
              final col = index % _gridSize;
              final isFilled = _targetPattern[row][col];

              return Container(
                decoration: BoxDecoration(
                  color: isFilled
                      ? NunuColors.primaryMain
                      : NunuColors.backgroundPaper,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlayerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: SizedBox(
            width: gridSize,
            height: gridSize,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: _gridSize * _gridSize,
              itemBuilder: (context, index) {
                final row = index ~/ _gridSize;
                final col = index % _gridSize;
                final isFilled = _playerPattern[row][col];

                return GestureDetector(
                  onTap: () => _toggleCell(row, col),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? NunuColors.secondaryMain
                          : NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isFilled
                            ? NunuColors.secondaryLight.withOpacity(0.5)
                            : NunuColors.primaryDark.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
