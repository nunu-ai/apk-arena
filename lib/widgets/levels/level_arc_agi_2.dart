import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Data structures
// ---------------------------------------------------------------------------

class _ArcExample {
  final List<List<int>> input;
  final List<List<int>> output;
  const _ArcExample({required this.input, required this.output});
}

class _ArcPuzzle {
  final List<_ArcExample> examples;
  final List<List<int>> testInput;
  final List<List<int>> testOutput;
  const _ArcPuzzle({
    required this.examples,
    required this.testInput,
    required this.testOutput,
  });
}

// ---------------------------------------------------------------------------
// ARC color palette  (0 = empty, 1-5 = colors)
// ---------------------------------------------------------------------------

const Map<int, Color> _arcColors = {
  0: Color(0xFF16122F), // empty (background paper)
  1: Color(0xFF1E93FF), // blue
  2: Color(0xFFFF5630), // red
  3: Color(0xFF22C55E), // green
  4: Color(0xFFFFAB00), // yellow
  5: Color(0xFF805CE5), // purple
};

// ---------------------------------------------------------------------------
// Pre-built puzzles  (7x7 grids — object gravity)
//
// Rule:
//  1. Objects are 3×3 blocks — a center cell surrounded by up to 8 border
//     cells in a DIFFERENT color. Any color pair is valid.
//     Some border cells may be missing.
//  2. In the output the border is COMPLETED (all 8 cells filled).
//  3. Gravity pushes from the center of the grid outward: objects in the
//     left half slide LEFT to the wall, objects in the right half slide
//     RIGHT to the wall.
// ---------------------------------------------------------------------------

const List<_ArcPuzzle> _puzzles = [
  // ---- Instance 1 (blue/red, green/yellow) ----
  _ArcPuzzle(
    examples: [
      // Ex 1: center=1 border=2, complete, right half → slides right
      _ArcExample(
        input: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 2, 2, 2, 0],
          [0, 0, 0, 2, 1, 2, 0],
          [0, 0, 0, 2, 2, 2, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
        output: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 2, 2, 2],
          [0, 0, 0, 0, 2, 1, 2],
          [0, 0, 0, 0, 2, 2, 2],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
      ),
      // Ex 2: center=3 border=4, incomplete (1 missing), left half → left
      _ArcExample(
        input: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 4, 4, 0, 0, 0, 0],
          [0, 4, 3, 4, 0, 0, 0],
          [0, 4, 4, 4, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
        output: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [4, 4, 4, 0, 0, 0, 0],
          [4, 3, 4, 0, 0, 0, 0],
          [4, 4, 4, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
      ),
      // Ex 3: two objects with different colors, both partial, slide apart
      _ArcExample(
        input: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 2, 2, 0, 0, 0, 0],
          [0, 2, 1, 2, 0, 0, 0],
          [0, 0, 2, 2, 0, 0, 0],
          [0, 0, 0, 4, 4, 0, 0],
          [0, 0, 0, 4, 3, 4, 0],
          [0, 0, 0, 4, 4, 4, 0],
        ],
        output: [
          [0, 0, 0, 0, 0, 0, 0],
          [2, 2, 2, 0, 0, 0, 0],
          [2, 1, 2, 0, 0, 0, 0],
          [2, 2, 2, 0, 0, 0, 0],
          [0, 0, 0, 0, 4, 4, 4],
          [0, 0, 0, 0, 4, 3, 4],
          [0, 0, 0, 0, 4, 4, 4],
        ],
      ),
    ],
    // Test: center=5 border=1 (right) + center=3 border=4 (left)
    testInput: [
      [0, 0, 0, 1, 1, 0, 0],
      [0, 0, 0, 1, 5, 1, 0],
      [0, 0, 0, 1, 1, 1, 0],
      [0, 0, 0, 0, 0, 0, 0],
      [0, 4, 4, 4, 0, 0, 0],
      [0, 0, 3, 4, 0, 0, 0],
      [0, 4, 4, 4, 0, 0, 0],
    ],
    testOutput: [
      [0, 0, 0, 0, 1, 1, 1],
      [0, 0, 0, 0, 1, 5, 1],
      [0, 0, 0, 0, 1, 1, 1],
      [0, 0, 0, 0, 0, 0, 0],
      [4, 4, 4, 0, 0, 0, 0],
      [4, 3, 4, 0, 0, 0, 0],
      [4, 4, 4, 0, 0, 0, 0],
    ],
  ),

  // ---- Instance 2 (yellow/purple, blue/green) ----
  _ArcPuzzle(
    examples: [
      // Ex 1: center=4 border=5, complete, right half → slides right
      _ArcExample(
        input: [
          [0, 0, 0, 5, 5, 5, 0],
          [0, 0, 0, 5, 4, 5, 0],
          [0, 0, 0, 5, 5, 5, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
        output: [
          [0, 0, 0, 0, 5, 5, 5],
          [0, 0, 0, 0, 5, 4, 5],
          [0, 0, 0, 0, 5, 5, 5],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
      ),
      // Ex 2: center=1 border=3, incomplete (1 missing), left half → left
      _ArcExample(
        input: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 3, 0, 3, 0, 0, 0],
          [0, 3, 1, 3, 0, 0, 0],
          [0, 3, 3, 3, 0, 0, 0],
        ],
        output: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [3, 3, 3, 0, 0, 0, 0],
          [3, 1, 3, 0, 0, 0, 0],
          [3, 3, 3, 0, 0, 0, 0],
        ],
      ),
      // Ex 3: two objects with different colors, both partial, slide apart
      _ArcExample(
        input: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 3, 0, 3, 0, 0, 0],
          [0, 3, 1, 3, 0, 0, 0],
          [0, 3, 3, 3, 0, 0, 0],
          [0, 0, 0, 5, 5, 5, 0],
          [0, 0, 0, 5, 4, 0, 0],
          [0, 0, 0, 5, 5, 5, 0],
        ],
        output: [
          [0, 0, 0, 0, 0, 0, 0],
          [3, 3, 3, 0, 0, 0, 0],
          [3, 1, 3, 0, 0, 0, 0],
          [3, 3, 3, 0, 0, 0, 0],
          [0, 0, 0, 0, 5, 5, 5],
          [0, 0, 0, 0, 5, 4, 5],
          [0, 0, 0, 0, 5, 5, 5],
        ],
      ),
    ],
    // Test: center=2 border=4 (left) + center=5 border=3 (right)
    testInput: [
      [0, 0, 0, 0, 0, 0, 0],
      [0, 4, 4, 4, 0, 0, 0],
      [0, 4, 2, 4, 0, 0, 0],
      [0, 4, 0, 4, 0, 0, 0],
      [0, 0, 0, 3, 3, 0, 0],
      [0, 0, 0, 3, 5, 3, 0],
      [0, 0, 0, 3, 3, 3, 0],
    ],
    testOutput: [
      [0, 0, 0, 0, 0, 0, 0],
      [4, 4, 4, 0, 0, 0, 0],
      [4, 2, 4, 0, 0, 0, 0],
      [4, 4, 4, 0, 0, 0, 0],
      [0, 0, 0, 0, 3, 3, 3],
      [0, 0, 0, 0, 3, 5, 3],
      [0, 0, 0, 0, 3, 3, 3],
    ],
  ),

  // ---- Instance 3 (purple/red, green/blue) ----
  _ArcPuzzle(
    examples: [
      // Ex 1: center=5 border=2, complete, left half → slides left
      _ArcExample(
        input: [
          [0, 2, 2, 2, 0, 0, 0],
          [0, 2, 5, 2, 0, 0, 0],
          [0, 2, 2, 2, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
        output: [
          [2, 2, 2, 0, 0, 0, 0],
          [2, 5, 2, 0, 0, 0, 0],
          [2, 2, 2, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
        ],
      ),
      // Ex 2: center=3 border=1, incomplete (1 missing), right half → right
      _ArcExample(
        input: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 1, 1, 1, 0],
          [0, 0, 0, 1, 3, 1, 0],
          [0, 0, 0, 1, 0, 1, 0],
        ],
        output: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 0, 0, 0],
          [0, 0, 0, 0, 1, 1, 1],
          [0, 0, 0, 0, 1, 3, 1],
          [0, 0, 0, 0, 1, 1, 1],
        ],
      ),
      // Ex 3: two objects with different colors, both partial, slide apart
      _ArcExample(
        input: [
          [0, 0, 0, 0, 0, 0, 0],
          [0, 2, 2, 0, 0, 0, 0],
          [0, 2, 5, 2, 0, 0, 0],
          [0, 2, 2, 2, 0, 0, 0],
          [0, 0, 0, 1, 0, 1, 0],
          [0, 0, 0, 1, 3, 1, 0],
          [0, 0, 0, 1, 1, 1, 0],
        ],
        output: [
          [0, 0, 0, 0, 0, 0, 0],
          [2, 2, 2, 0, 0, 0, 0],
          [2, 5, 2, 0, 0, 0, 0],
          [2, 2, 2, 0, 0, 0, 0],
          [0, 0, 0, 0, 1, 1, 1],
          [0, 0, 0, 0, 1, 3, 1],
          [0, 0, 0, 0, 1, 1, 1],
        ],
      ),
    ],
    // Test: center=4 border=2 (right) + center=1 border=5 (left)
    testInput: [
      [0, 0, 0, 2, 2, 2, 0],
      [0, 0, 0, 2, 4, 2, 0],
      [0, 0, 0, 2, 2, 0, 0],
      [0, 0, 0, 0, 0, 0, 0],
      [0, 0, 5, 5, 0, 0, 0],
      [0, 5, 1, 5, 0, 0, 0],
      [0, 5, 0, 5, 0, 0, 0],
    ],
    testOutput: [
      [0, 0, 0, 0, 2, 2, 2],
      [0, 0, 0, 0, 2, 4, 2],
      [0, 0, 0, 0, 2, 2, 2],
      [0, 0, 0, 0, 0, 0, 0],
      [5, 5, 5, 0, 0, 0, 0],
      [5, 1, 5, 0, 0, 0, 0],
      [5, 5, 5, 0, 0, 0, 0],
    ],
  ),
];

// ---------------------------------------------------------------------------
// Level widget
// ---------------------------------------------------------------------------

class LevelArcAgi2 extends LevelWidget {
  const LevelArcAgi2({super.key, required super.onComplete});

  @override
  State<LevelArcAgi2> createState() => _LevelArcAgi2State();
}

class _LevelArcAgi2State extends State<LevelArcAgi2> {
  static const int _gridSize = 7;
  final Random _random = Random();

  late _ArcPuzzle _puzzle;
  late List<List<int>> _answer;
  int _selectedColor = 1;
  int _selectedExample = 0;

  @override
  void initState() {
    super.initState();
    _puzzle = _puzzles[_random.nextInt(_puzzles.length)];
    _answer = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => 0),
    );
  }

  // ---- actions ----

  void _paintCell(int row, int col) {
    setState(() {
      _answer[row][col] = _selectedColor;
    });
  }

  bool _checkAnswer() {
    for (int r = 0; r < _gridSize; r++) {
      for (int c = 0; c < _gridSize; c++) {
        if (_answer[r][c] != _puzzle.testOutput[r][c]) return false;
      }
    }
    return true;
  }

  void _onSubmit() => widget.onComplete(LevelOutcome(score: _checkAnswer() ? 1 : 0));

  void _onClear() {
    setState(() {
      _answer = List.generate(
        _gridSize,
        (_) => List.generate(_gridSize, (_) => 0),
      );
    });
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildExamplesSection(),
              const SizedBox(height: 12),
              Expanded(child: _buildTestSection()),
              const SizedBox(height: 12),
              _buildPalette(),
              const SizedBox(height: 12),
              _buildButtons(),
            ],
          ),
        ),
      ),
    );
  }

  // ---- examples carousel ----

  Widget _buildExamplesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'examples',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
            ),
            const Spacer(),
            for (int i = 0; i < _puzzle.examples.length; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              _buildExampleTab(i),
            ],
          ],
        ),
        const SizedBox(height: 6),
        _buildExamplePair(_puzzle.examples[_selectedExample]),
      ],
    );
  }

  Widget _buildExampleTab(int index) {
    final bool active = _selectedExample == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedExample = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: active ? NunuColors.primaryMain : NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: active
                ? NunuColors.primaryMain
                : NunuColors.primaryDark.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          '${index + 1}',
          style: TextStyle(
            color: active ? Colors.white : NunuColors.textSecondary,
            fontSize: 13,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  /// Responsive example pair — grids fill ~90 % of available width.
  Widget _buildExamplePair(_ArcExample example) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // arrow icon (18) + horizontal padding (8 × 2) = 34
        const double arrowSpace = 34;
        // container: padding 3*2 + border 1*2 = 8
        const double containerOverhead = 8;
        const double gap = 2;
        final int gapCount = _gridSize - 1;

        final double halfWidth = (constraints.maxWidth - arrowSpace) / 2;
        final double cellSize =
            ((halfWidth - containerOverhead - gapCount * gap) / _gridSize)
                .floorToDouble();

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniGrid(example.input, cellSize: cellSize),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Icon(
                Icons.arrow_forward,
                size: 18,
                color: NunuColors.textSecondary,
              ),
            ),
            _buildMiniGrid(example.output, cellSize: cellSize),
          ],
        );
      },
    );
  }

  /// Read-only grid used inside the examples carousel.
  Widget _buildMiniGrid(List<List<int>> grid, {required double cellSize}) {
    const double gap = 2;
    final int size = grid.length;

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        border: Border.all(
          color: NunuColors.primaryDark.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int r = 0; r < size; r++) ...[
            if (r > 0) const SizedBox(height: gap),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int c = 0; c < size; c++) ...[
                  if (c > 0) const SizedBox(width: gap),
                  Container(
                    width: cellSize,
                    height: cellSize,
                    decoration: BoxDecoration(
                      color: _arcColors[grid[r][c]],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ---- test input + answer grid (side by side) ----

  Widget _buildTestSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Test input (read-only)
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'test input',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: _buildGrid(_puzzle.testInput, interactive: false),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Player answer (interactive)
        Expanded(
          flex: 5,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'your answer',
                style: TextStyle(
                  color: NunuColors.primaryLight.withValues(alpha: 0.9),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(child: _buildGrid(_answer, interactive: true)),
            ],
          ),
        ),
      ],
    );
  }

  /// Renders a grid that fills available space while staying square.
  Widget _buildGrid(List<List<int>> grid, {required bool interactive}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double side = min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: SizedBox(
            width: side,
            height: side,
            child: GridView.builder(
              padding: EdgeInsets.zero,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: _gridSize * _gridSize,
              itemBuilder: (context, index) {
                final r = index ~/ _gridSize;
                final c = index % _gridSize;
                final colorId = grid[r][c];
                final color = _arcColors[colorId] ?? const Color(0xFF16122F);

                final cell = AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: interactive
                          ? (colorId != 0
                                ? Colors.white.withValues(alpha: 0.25)
                                : NunuColors.primaryDark.withValues(alpha: 0.6))
                          : NunuColors.primaryDark.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                );

                if (!interactive) return cell;

                return GestureDetector(
                  onTap: () => _paintCell(r, c),
                  child: cell,
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ---- color palette ----

  Widget _buildPalette() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i <= 5; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          _buildPaletteSwatch(i),
        ],
      ],
    );
  }

  Widget _buildPaletteSwatch(int colorId) {
    final bool selected = _selectedColor == colorId;
    final double size = selected ? 40 : 32;
    final Color color = _arcColors[colorId] ?? const Color(0xFF16122F);

    return GestureDetector(
      onTap: () => setState(() => _selectedColor = colorId),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: selected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.2),
            width: selected ? 3 : 1,
          ),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 10)]
              : null,
        ),
        child: colorId == 0
            ? Icon(
                Icons.close,
                size: selected ? 18 : 14,
                color: NunuColors.textSecondary,
              )
            : null,
      ),
    );
  }

  // ---- action buttons ----

  Widget _buildButtons() {
    return Row(
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
    );
  }
}
