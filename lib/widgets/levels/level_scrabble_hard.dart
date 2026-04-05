import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
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
  // P, R, F, U, L are needed for POWERFUL (O, W, E already on board)
  // E is a distractor
  final List<String> _rackLetters = ['E', 'F', 'L', 'P', 'R', 'U'];

  // Track placed letters on the board: Map<(row, col), letter>
  final Map<String, String> _placedTiles = {};

  // Target word: POWERFUL in column 2, rows 6-13
  // Fixed letters: O at (7,2) from AGOG, W at (8,2) from WITTOLS, E at (9,2) from MEG
  // Player places: P at (6,2), R at (10,2), F at (11,2), U at (12,2), L at (13,2)
  static const String _targetWord = 'POWERFUL';
  static const int _targetCol = 2;
  static const int _targetStartRow = 6;

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

  void _onDropLetter(int row, int col, String letter, {String? sourceKey}) {
    if (_isFixedCell(row, col)) return;
    final targetKey = _cellKey(row, col);

    // If dropping on a cell that already has a tile (and it's not the source), reject
    if (_placedTiles.containsKey(targetKey) && targetKey != sourceKey) return;

    // If this is a move from another cell (sourceKey provided), remove from source
    if (sourceKey != null) {
      setState(() {
        _placedTiles.remove(sourceKey);
        _placedTiles[targetKey] = letter;
      });
      return;
    }

    // Otherwise, it's from the rack - check availability
    if (!_isLetterAvailable(letter)) return;
    setState(() {
      _placedTiles[targetKey] = letter;
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
    // Check if POWERFUL is formed vertically in column 2, rows 6-13
    // P(6,2) - O(7,2 fixed) - W(8,2 fixed) - E(9,2 fixed) - R(10,2) - F(11,2) - U(12,2) - L(13,2)
    String formedWord = '';
    for (
      int row = _targetStartRow;
      row < _targetStartRow + _targetWord.length;
      row++
    ) {
      final fixedLetter = _getFixedLetter(row, _targetCol);
      if (fixedLetter != null) {
        formedWord += fixedLetter;
      } else {
        final key = _cellKey(row, _targetCol);
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

  // Get cell background color based on special tile types - Nunu themed
  Color _getCellColor(int row, int col) {
    // Standard Scrabble board pattern
    // Triple Word Score - corners and cross pattern
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

    // Double Word Score - diagonal pattern
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

    // Triple Letter Score
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

    // Double Letter Score
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

    // Center star - bright primary pink glow
    if (row == 7 && col == 7) {
      return NunuColors.primaryMain.withOpacity(0.4);
    }

    // Triple Word - Error red (hot zones)
    for (var pos in tripleWord) {
      if (pos[0] == row && pos[1] == col) {
        return NunuColors.errorMain.withOpacity(0.35);
      }
    }

    // Double Word - Warning amber/gold
    for (var pos in doubleWord) {
      if (pos[0] == row && pos[1] == col) {
        return NunuColors.warningMain.withOpacity(0.25);
      }
    }

    // Triple Letter - Secondary purple (premium)
    for (var pos in tripleLetter) {
      if (pos[0] == row && pos[1] == col) {
        return NunuColors.secondaryMain.withOpacity(0.4);
      }
    }

    // Double Letter - Info cyan/teal
    for (var pos in doubleLetter) {
      if (pos[0] == row && pos[1] == col) {
        return NunuColors.infoMain.withOpacity(0.25);
      }
    }

    // Default cell - subtle dark
    return NunuColors.backgroundPaper.withOpacity(0.6);
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
                "hint: it's a vertical word in column 3 and starts with 'P'.",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
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
                        color: NunuColors.backgroundDefault,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: NunuColors.primaryMain.withOpacity(0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: NunuColors.primaryMain.withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: NunuColors.secondaryMain.withOpacity(0.1),
                            blurRadius: 40,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(3),
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
                                    cellKey: key,
                                    backgroundColor: cellColor,
                                    onDrop: (letter, sourceKey) =>
                                        _onDropLetter(
                                          r,
                                          c,
                                          letter,
                                          sourceKey: sourceKey,
                                        ),
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
      height: 64,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NunuColors.primaryDark.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NunuColors.primaryMain.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          itemCount: _rackLetters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final letter = _rackLetters[index];
            final isAvailable = _isLetterAvailable(letter);

            return Draggable<_DragData>(
              data: _DragData(letter, null), // null sourceKey means from rack
              feedback: _RackTile(
                letter: letter,
                dragging: true,
                enabled: true,
              ),
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
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A1F4E), // Deep purple
            Color(0xFF1A1238), // Darker purple
          ],
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: NunuColors.secondaryMain.withOpacity(0.4),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: NunuColors.secondaryMain.withOpacity(0.15),
            blurRadius: 4,
            offset: const Offset(0, 1),
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
              color: NunuColors.secondaryLight,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              shadows: [Shadow(color: NunuColors.secondaryMain, blurRadius: 4)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Data class for drag operations - carries letter and optional source position
class _DragData {
  final String letter;
  final String? sourceKey; // null if from rack, key if from board

  const _DragData(this.letter, this.sourceKey);
}

class _DroppableCell extends StatelessWidget {
  final String? letter;
  final String cellKey;
  final Color backgroundColor;
  final void Function(String letter, String? sourceKey) onDrop;
  final VoidCallback onTap;
  const _DroppableCell({
    required this.letter,
    required this.cellKey,
    required this.backgroundColor,
    required this.onDrop,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (details) {
        // Accept if cell is empty OR if it's the source cell (cancel drag)
        return letter == null || details.data.sourceKey == cellKey;
      },
      onAcceptWithDetails: (details) =>
          onDrop(details.data.letter, details.data.sourceKey),
      builder: (context, candidateData, rejectedData) {
        final bool isActive = candidateData.isNotEmpty;
        final bool hasLetter = letter != null;

        if (hasLetter) {
          // Make placed tiles draggable so user can move them
          return Draggable<_DragData>(
            data: _DragData(letter!, cellKey),
            feedback: _PlacedTileFeedback(letter: letter!),
            childWhenDragging: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: NunuColors.primaryMain.withOpacity(0.5),
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
            ),
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF5E2A6E), // Purple-pink
                      Color(0xFF3D1A4D), // Darker purple
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: NunuColors.primaryMain.withOpacity(0.7),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: NunuColors.primaryMain.withOpacity(0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 1),
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
                        color: NunuColors.primaryLight,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        shadows: [
                          Shadow(color: NunuColors.primaryMain, blurRadius: 6),
                        ],
                      ),
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
            borderRadius: BorderRadius.circular(3),
            border: Border.all(
              color: isActive
                  ? NunuColors.primaryMain
                  : NunuColors.primaryDark.withOpacity(0.2),
              width: isActive ? 2 : 0.5,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: NunuColors.primaryMain.withOpacity(0.4),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      },
    );
  }
}

class _PlacedTileFeedback extends StatelessWidget {
  final String letter;
  const _PlacedTileFeedback({required this.letter});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [NunuColors.primaryMain, NunuColors.primaryDark],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: NunuColors.primaryLight.withOpacity(0.8),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withOpacity(0.6),
              blurRadius: 16,
              spreadRadius: 2,
            ),
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
            fontSize: 18,
            fontWeight: FontWeight.w900,
            shadows: [Shadow(color: NunuColors.primaryDarker, blurRadius: 4)],
          ),
        ),
      ),
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
      opacity: enabled ? 1.0 : 0.3,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dragging
                ? [NunuColors.primaryMain, NunuColors.primaryDark]
                : [
                    const Color(0xFF4A2A5E), // Muted purple
                    const Color(0xFF2D1A3D), // Dark purple
                  ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled
                ? NunuColors.primaryMain.withOpacity(0.8)
                : NunuColors.primaryDark.withOpacity(0.4),
            width: 2,
          ),
          boxShadow: [
            if (enabled)
              BoxShadow(
                color: NunuColors.primaryMain.withOpacity(0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 4,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          letter,
          style: TextStyle(
            color: enabled
                ? NunuColors.primaryLighter
                : NunuColors.primaryLight.withOpacity(0.5),
            fontSize: 22,
            fontWeight: FontWeight.w900,
            shadows: enabled
                ? [const Shadow(color: NunuColors.primaryMain, blurRadius: 8)]
                : null,
          ),
        ),
      ),
    );
  }
}
