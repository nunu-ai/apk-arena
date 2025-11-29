import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelScrabbleHard extends LevelWidget {
  const LevelScrabbleHard({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelScrabbleHard> createState() => _LevelScrabbleHardState();
}

class _LevelScrabbleHardState extends State<LevelScrabbleHard> {
  static const int _rows = 15;
  static const int _cols = 15;

  // Pre-placed words on the board
  // Format: Map of "row,col" -> letter
  final Map<String, String> _fixedTiles = {};

  // Tile rack letters - the player will use these
  final List<String> _rackLetters = ['F', 'L', 'N', 'P', 'R', 'S', 'U'];

  // Track placed letters on the board: Map<(row, col), letter>
  final Map<String, String> _placedTiles = {};

  @override
  void initState() {
    super.initState();
    _initializeBoard();
  }

  void _initializeBoard() {
    // Recreated from real Scrabble game screenshot
    // Complex interconnected board with many words
    //
    // Main words visible:
    // - REPOINT (horizontal)
    // - JO (vertical, connects to REPOINT's O)
    // - INK (horizontal)
    // - CHIAO (horizontal)
    // - ODA (horizontal)
    // - BARF (horizontal)
    // - AIYEE (horizontal)
    // - WITTOLS (horizontal)
    // - TUI (horizontal)
    // - WOVEN (vertical, right side)
    // - MAIMED (vertical, left side)
    // And more connecting words

    // Helper to place a word
    void placeWord(String word, int startRow, int startCol, bool horizontal) {
      for (int i = 0; i < word.length; i++) {
        final row = horizontal ? startRow : startRow + i;
        final col = horizontal ? startCol + i : startCol;
        _fixedTiles[_cellKey(row, col)] = word[i];
      }
    }

    // Helper to place single tile
    void placeTile(String letter, int row, int col) {
      _fixedTiles[_cellKey(row, col)] = letter;
    }

    // === TOP SECTION ===
    placeWord('JO', 0, 7, true);

    // REPOINT horizontal at row 2
    placeWord('REPOINT', 1, 4, true);

    // INK horizontal at row 3
    placeWord('INK', 2, 10, true);
    // OH horizontal at row 4
    placeWord('OH', 3, 11, true);

    // W on far right (part of WOVEN)
    placeTile('W', 3, 14);
    placeTile('V', 5, 14);
    placeTile('E', 6, 14);
    placeTile('N', 7, 14);

    // VUG
    placeTile('V', 5, 1);
    placeTile('U', 6, 1);

    // CHIAO horizontal at row 5
    placeWord('CHIAO', 4, 10, true);
    placeWord('ODA', 5, 8, true);
    placeWord('BARF', 6, 8, true);
    placeWord('AIYEE', 7, 7, true);
    placeWord('AGOG', 7, 0, true);

    // === ROW 9 - WITTOLS ===
    placeWord('WITTOLS', 8, 2, true);
    placeWord('TUI', 8, 10, true);
    placeWord('MEG', 9, 1, true);

    placeTile('A', 10, 1);
    placeTile('I', 11, 1);
    placeTile('M', 12, 1);
    placeTile('E', 13, 1);
    placeTile('D', 14, 1);
  }

  String _cellKey(int row, int col) => '$row,$col';

  bool _isFixedCell(int row, int col) {
    return _fixedTiles.containsKey(_cellKey(row, col));
  }

  String? _getFixedLetter(int row, int col) {
    return _fixedTiles[_cellKey(row, col)];
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
    // TODO: Add completion logic once more words are specified
    // For now, just check if any tiles are placed
    if (_placedTiles.isNotEmpty) {
      widget.onComplete(true);
    } else {
      widget.onComplete(false);
    }
  }

  // Get cell background color based on special tile types
  Color _getCellColor(int row, int col) {
    // Standard Scrabble board pattern
    // Triple Word Score (red) - corners and cross pattern
    final tripleWord = [
      [0, 0],
      [0, 7],
      [0, 14],
      [7, 0],
      [7, 14],
      [14, 0],
      [14, 7],
      [14, 14],
    ];

    // Double Word Score (pink) - diagonal pattern
    final doubleWord = [
      [1, 1],
      [2, 2],
      [3, 3],
      [4, 4],
      [1, 13],
      [2, 12],
      [3, 11],
      [4, 10],
      [13, 1],
      [12, 2],
      [11, 3],
      [10, 4],
      [13, 13],
      [12, 12],
      [11, 11],
      [10, 10],
    ];

    // Triple Letter Score (dark blue)
    final tripleLetter = [
      [1, 5],
      [1, 9],
      [5, 1],
      [5, 5],
      [5, 9],
      [5, 13],
      [9, 1],
      [9, 5],
      [9, 9],
      [9, 13],
      [13, 5],
      [13, 9],
    ];

    // Double Letter Score (light blue)
    final doubleLetter = [
      [0, 3],
      [0, 11],
      [2, 6],
      [2, 8],
      [3, 0],
      [3, 7],
      [3, 14],
      [6, 2],
      [6, 6],
      [6, 8],
      [6, 12],
      [7, 3],
      [7, 11],
      [8, 2],
      [8, 6],
      [8, 8],
      [8, 12],
      [11, 0],
      [11, 7],
      [11, 14],
      [12, 6],
      [12, 8],
      [14, 3],
      [14, 11],
    ];

    // Center star
    if (row == 7 && col == 7) {
      return const Color(0xFFE55CD8).withOpacity(0.3); // Pink for center
    }

    for (var pos in tripleWord) {
      if (pos[0] == row && pos[1] == col) {
        return const Color(0xFFFF5630).withOpacity(0.25); // Red
      }
    }

    for (var pos in doubleWord) {
      if (pos[0] == row && pos[1] == col) {
        return const Color(0xFFFFAB00).withOpacity(0.2); // Orange/pink
      }
    }

    for (var pos in tripleLetter) {
      if (pos[0] == row && pos[1] == col) {
        return const Color(0xFF1E90FF).withOpacity(0.3); // Blue
      }
    }

    for (var pos in doubleLetter) {
      if (pos[0] == row && pos[1] == col) {
        return const Color(0xFF87CEEB).withOpacity(0.25); // Light blue
      }
    }

    return NunuColors.backgroundDefault.withOpacity(0.25);
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'place your tiles',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NunuColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1F3D),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: NunuColors.primaryDark.withOpacity(0.5),
                          width: 2,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: Column(
                        children: List.generate(_rows, (r) {
                          return Expanded(
                            child: Row(
                              children: List.generate(_cols, (c) {
                                final fixedLetter = _getFixedLetter(r, c);
                                if (fixedLetter != null) {
                                  return Expanded(
                                    child: _FixedTile(letter: fixedLetter),
                                  );
                                }

                                final key = _cellKey(r, c);
                                final placedLetter = _placedTiles[key];
                                final cellColor = _getCellColor(r, c);

                                return Expanded(
                                  child: _DroppableCell(
                                    letter: placedLetter,
                                    backgroundColor: cellColor,
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
            ),
            const SizedBox(height: 8),
            _buildRack(),
            const SizedBox(height: 8),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildRack() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _rackLetters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final letter = _rackLetters[index];
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
        },
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
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: const Color(0xFFDEB887), // Classic Scrabble tile color
        borderRadius: BorderRadius.circular(3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            offset: const Offset(1, 1),
            blurRadius: 1,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            letter,
            style: const TextStyle(
              color: Color(0xFF1A1A1A),
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}

class _DroppableCell extends StatelessWidget {
  final String? letter;
  final Color backgroundColor;
  final void Function(String) onDrop;
  final VoidCallback onTap;
  const _DroppableCell({
    required this.letter,
    required this.backgroundColor,
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

        if (hasLetter) {
          return InkWell(
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: const Color(0xFFDEB887),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    offset: const Offset(1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(2),
                  child: Text(
                    letter!,
                    style: const TextStyle(
                      color: Color(0xFF1A1A1A),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(2),
            border: Border.all(
              color: isActive
                  ? NunuColors.primaryMain
                  : NunuColors.primaryDark.withOpacity(0.15),
              width: isActive ? 1.5 : 0.5,
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
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: dragging
              ? const Color(0xFFDEB887)
              : const Color(0xFFDEB887).withOpacity(0.95),
          borderRadius: BorderRadius.circular(6),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: const TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
