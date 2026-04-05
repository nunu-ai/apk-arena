import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelScrabble extends LevelWidget {
  const LevelScrabble({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelScrabble> createState() => _LevelScrabbleState();
}

class _LevelScrabbleState extends State<LevelScrabble> {
  static const int _rows = 8;
  static const int _cols = 8;

  // Two fixed vertical words
  // Left vertical word (PLANT): column 2, rows 2..6
  static const String _leftWord = 'PLANT';
  static const int _leftWordCol = 2;
  static const int _leftWordStartRow = 2;

  // Right vertical word (LEARN): column 5, rows 1..5
  static const String _rightWord = 'LEARN';
  static const int _rightWordCol = 5;
  static const int _rightWordStartRow = 1;

  // Target: PAPER at row 4, columns 1-5
  // P(col1) - A(col2, from PLANT) - P(col3) - E(col4) - R(col5, from LEARN)
  static const int _targetRow = 4;
  static const String _targetWord = 'PAPER';

  // Tile rack letters
  final List<String> _rackLetters = ['P', 'P', 'E', 'R', 'N'];

  // Track placed letters on the board: Map<(row, col), letter>
  final Map<String, String> _placedTiles = {};

  String _cellKey(int row, int col) => '$row,$col';

  bool _isFixedCell(int row, int col) {
    // Check if cell is part of left word
    if (col == _leftWordCol &&
        row >= _leftWordStartRow &&
        row < _leftWordStartRow + _leftWord.length) {
      return true;
    }
    // Check if cell is part of right word
    if (col == _rightWordCol &&
        row >= _rightWordStartRow &&
        row < _rightWordStartRow + _rightWord.length) {
      return true;
    }
    return false;
  }

  String? _getFixedLetter(int row, int col) {
    if (col == _leftWordCol &&
        row >= _leftWordStartRow &&
        row < _leftWordStartRow + _leftWord.length) {
      return _leftWord[row - _leftWordStartRow];
    }
    if (col == _rightWordCol &&
        row >= _rightWordStartRow &&
        row < _rightWordStartRow + _rightWord.length) {
      return _rightWord[row - _rightWordStartRow];
    }
    return null;
  }

  void _resetPlaced() {
    setState(() {
      _placedTiles.clear();
    });
  }

  // Count how many times a letter is used on the board
  int _countUsed(String letter) {
    return _placedTiles.values.where((l) => l == letter).length;
  }

  // Count how many of this letter are in the rack
  int _countInRack(String letter) {
    return _rackLetters.where((l) => l == letter).length;
  }

  bool _isLetterAvailable(String letter) {
    return _countUsed(letter) < _countInRack(letter);
  }

  void _onDropLetter(int row, int col, String letter) {
    if (!_isLetterAvailable(letter)) return;
    if (_isFixedCell(row, col)) return;
    final key = _cellKey(row, col);
    if (_placedTiles.containsKey(key)) return;
    setState(() {
      _placedTiles[key] = letter;
    });
  }

  void _onTapCell(int row, int col) {
    final key = _cellKey(row, col);
    if (_placedTiles.containsKey(key)) {
      setState(() {
        _placedTiles.remove(key);
      });
    }
  }

  void _submit() {
    // Check if PAPER is formed at row 4, columns 1-5
    // P(col1) - A(col2, fixed from PLANT) - P(col3) - E(col4) - R(col5, fixed from LEARN)
    String formedWord = '';
    for (int col = 1; col <= 5; col++) {
      final fixedLetter = _getFixedLetter(_targetRow, col);
      if (fixedLetter != null) {
        formedWord += fixedLetter;
      } else {
        final key = _cellKey(_targetRow, col);
        final placed = _placedTiles[key];
        if (placed != null) {
          formedWord += placed;
        } else {
          // Empty cell in the target word
          widget.onComplete(LevelOutcome(score: 0));
          return;
        }
      }
    }

    if (formedWord == _targetWord) {
      widget.onComplete(LevelOutcome(score: 1));
    } else {
      widget.onComplete(LevelOutcome(score: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      width: double.infinity,
      height: double.infinity,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'make the word "paper"',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NunuColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: NunuColors.primaryDark.withOpacity(0.5),
                      ),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Column(
                      children: List.generate(_rows, (r) {
                        return Expanded(
                          child: Row(
                            children: List.generate(_cols, (c) {
                              // Check if this is a fixed cell (part of vertical words)
                              final fixedLetter = _getFixedLetter(r, c);
                              if (fixedLetter != null) {
                                return Expanded(
                                  child: _FixedTile(letter: fixedLetter),
                                );
                              }

                              // Check if there's a placed tile here
                              final key = _cellKey(r, c);
                              final placedLetter = _placedTiles[key];

                              // All other cells are droppable
                              return Expanded(
                                child: _DroppableCell(
                                  letter: placedLetter,
                                  onDrop: (l) => _onDropLetter(r, c, l),
                                  onTap: () => _onTapCell(r, c),
                                ),
                              );
                            }),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildRack(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(onPressed: _submit, child: const Text('submit')),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: _resetPlaced,
                  child: const Text('reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRack() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 10,
        children: _rackLetters.asMap().entries.map((entry) {
          final letter = entry.value;
          final isAvailable = _isLetterAvailable(letter);

          return Draggable<String>(
            data: letter,
            feedback: _RackTile(letter: letter, dragging: true, enabled: true),
            childWhenDragging: _RackTile(
              letter: letter,
              dragging: false,
              enabled: false,
            ),
            maxSimultaneousDrags: isAvailable ? 1 : 0,
            child: _RackTile(
              letter: letter,
              dragging: false,
              enabled: isAvailable,
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FixedTile extends StatelessWidget {
  final String letter;
  const _FixedTile({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: NunuColors.secondaryDark.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NunuColors.secondaryDark),
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DroppableCell extends StatelessWidget {
  final String? letter;
  final void Function(String) onDrop;
  final VoidCallback onTap;
  const _DroppableCell({
    required this.letter,
    required this.onDrop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) => letter == null,
      onAcceptWithDetails: (details) => onDrop(details.data),
      builder: (context, candidateData, rejectedData) {
        final bool isActive = candidateData.isNotEmpty;
        final bool hasLetter = letter != null;
        return InkWell(
          onTap: hasLetter ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: hasLetter
                  ? NunuColors.primaryDark.withOpacity(0.25)
                  : (isActive
                        ? NunuColors.primaryDark.withOpacity(0.15)
                        : NunuColors.backgroundDefault.withOpacity(0.25)),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isActive
                    ? NunuColors.primaryMain
                    : NunuColors.primaryDark.withOpacity(0.2),
                width: isActive ? 2 : 1,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              letter ?? '',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: NunuColors.primaryLight,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _RackTile extends StatelessWidget {
  final String letter;
  final bool dragging;
  final bool enabled;
  const _RackTile({
    required this.letter,
    required this.dragging,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.35,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: dragging
              ? NunuColors.primaryMain.withOpacity(0.9)
              : NunuColors.primaryMain.withOpacity(0.7),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
