import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSudoku extends LevelWidget {
  const LevelSudoku({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelSudoku> createState() => _LevelSudokuState();
}

class _LevelSudokuState extends State<LevelSudoku> {
  // Fixed 9x9 Sudoku puzzle (0 = empty)
  // Source: simple valid puzzle with a single solution
  static const List<List<int>> _puzzle = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ];

  // Known correct solution for the above puzzle
  static const List<List<int>> _solution = [
    [5, 3, 4, 6, 7, 8, 9, 1, 2],
    [6, 7, 2, 1, 9, 5, 3, 4, 8],
    [1, 9, 8, 3, 4, 2, 5, 6, 7],
    [8, 5, 9, 7, 6, 1, 4, 2, 3],
    [4, 2, 6, 8, 5, 3, 7, 9, 1],
    [7, 1, 3, 9, 2, 4, 8, 5, 6],
    [9, 6, 1, 5, 3, 7, 2, 8, 4],
    [2, 8, 7, 4, 1, 9, 6, 3, 5],
    [3, 4, 5, 2, 8, 6, 1, 7, 9],
  ];

  // Current user inputs as strings for TextFields
  late final List<List<String>> _values;

  @override
  void initState() {
    super.initState();
    _values = List.generate(9, (r) {
      return List.generate(9, (c) {
        final inMiddleBlock = r >= 3 && r <= 5 && c >= 3 && c <= 5;
        if (inMiddleBlock) {
          return _puzzle[r][c] == 0 ? '' : _puzzle[r][c].toString();
        }
        // Outside middle block we prefill with the solution to speed up the level
        return _solution[r][c].toString();
      });
    });
  }

  void _onChanged(int row, int col, String input) {
    // Accept only digits 1-9 and at most one char
    String sanitized = input.replaceAll(RegExp(r'[^1-9]'), '');
    if (sanitized.length > 1) {
      sanitized = sanitized.substring(0, 1);
    }
    setState(() {
      _values[row][col] = sanitized;
    });
  }

  void _submit() {
    // Validate only the center 3x3 block (rows 3..5, cols 3..5)
    for (int r = 3; r <= 5; r++) {
      for (int c = 3; c <= 5; c++) {
        final expected = _solution[r][c].toString();
        if (_values[r][c] != expected) {
          widget.onComplete(false);
          return;
        }
      }
    }
    widget.onComplete(true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGrid(context),
              const SizedBox(height: 12),
              Center(
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.all(4),
        child: Column(
          children: List.generate(9, (r) {
            return Expanded(
              child: Row(
                children: List.generate(9, (c) {
                  final inMiddleBlock = r >= 3 && r <= 5 && c >= 3 && c <= 5;
                  final given = inMiddleBlock
                      ? _puzzle[r][c] != 0
                      : true; // lock everything outside middle
                  final isThickRight = (c % 3 == 2) && c != 8;
                  final isThickBottom = (r % 3 == 2) && r != 8;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(
                            color: isThickRight
                                ? NunuColors.primaryDark
                                : NunuColors.primaryDark.withOpacity(0.3),
                            width: isThickRight ? 2 : 1,
                          ),
                          bottom: BorderSide(
                            color: isThickBottom
                                ? NunuColors.primaryDark
                                : NunuColors.primaryDark.withOpacity(0.3),
                            width: isThickBottom ? 2 : 1,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(2),
                        child: given
                            ? _GivenCell(value: _values[r][c])
                            : _InputCell(
                                value: _values[r][c],
                                onChanged: (v) => _onChanged(r, c, v),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _GivenCell extends StatelessWidget {
  final String value;
  const _GivenCell({required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: NunuColors.secondaryDark.withOpacity(0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        value,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InputCell extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;
  const _InputCell({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      maxLength: 1,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        color: NunuColors.primaryLight,
        fontWeight: FontWeight.w600,
      ),
      decoration: const InputDecoration(
        counterText: '',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(vertical: 8),
        border: InputBorder.none,
      ),
      onChanged: onChanged,
      controller: TextEditingController(text: value)
        ..selection = TextSelection.collapsed(offset: value.length),
    );
  }
}
