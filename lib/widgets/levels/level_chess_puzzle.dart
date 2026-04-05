import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelChessPuzzle extends LevelWidget {
  const LevelChessPuzzle({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelChessPuzzle> createState() => _LevelChessPuzzleState();
}

class _LevelChessPuzzleState extends State<LevelChessPuzzle> {
  // Chess board state: null = empty, 'WK' = white king, 'BK' = black king, etc.
  // Puzzle: Back Rank Mate
  // White to move
  late List<List<String?>> _board;
  
  String? _selectedPiece;
  int? _selectedRow;
  int? _selectedCol;
  
  @override
  void initState() {
    super.initState();
    _board = List.generate(8, (_) => List.filled(8, null));
    
    // Setup: Back Rank Mate
    // Black King trapped on g8
    _board[0][6] = 'BK'; // g8
    _board[1][5] = 'BP'; // f7
    _board[1][6] = 'BP'; // g7
    _board[1][7] = 'BP'; // h7
    
    // White pieces
    _board[7][3] = 'WR'; // d1 - The winning piece
    _board[7][6] = 'WK'; // g1 - King safety
    
    // Distractors
    _board[4][2] = 'WB'; // c4 - Bishop (useless)
    
    // Solution: Rd8# (Rook from d1 to d8)
  }

  void _onSquareTap(int row, int col) {
    final piece = _board[row][col];
    
    // If no piece is selected yet
    if (_selectedPiece == null) {
      // Only allow selecting white pieces
      if (piece != null && piece.startsWith('W')) {
        setState(() {
          _selectedPiece = piece;
          _selectedRow = row;
          _selectedCol = col;
        });
      }
      return;
    }
    
    // If a piece is already selected, try to move it
    final fromRow = _selectedRow!;
    final fromCol = _selectedCol!;
    
    // Check if this is the winning move: Rook from d1 (7,3) to d8 (0,3)
    if (_selectedPiece == 'WR' && 
        fromRow == 7 && fromCol == 3 && 
        row == 0 && col == 3) {
      // Winning move!
      setState(() {
        _board[row][col] = _selectedPiece;
        _board[fromRow][fromCol] = null;
        _selectedPiece = null;
        _selectedRow = null;
        _selectedCol = null;
      });
      
      // Short delay to show the final position
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(LevelOutcome(score: 1));
      });
      return;
    }
    
    // Allow deselecting by tapping the same piece
    if (row == fromRow && col == fromCol) {
      setState(() {
        _selectedPiece = null;
        _selectedRow = null;
        _selectedCol = null;
      });
      return;
    }

    // Any other move is wrong
    // Visual feedback for wrong move could be added here
    setState(() {
      _selectedPiece = null;
      _selectedRow = null;
      _selectedCol = null;
    });
    
    // Show failure for wrong moves
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Wrong move! Try again.'),
        duration: Duration(milliseconds: 500),
        backgroundColor: NunuColors.errorMain,
      ),
    );
    // Don't fail the level immediately, let them retry
    // widget.onComplete(LevelOutcome(score: 0)); 
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'White to Move',
                style: TextStyle(
                  color: NunuColors.primaryLight,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Courier', // Monospace for retro feel
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Find the Mate in 1',
                style: TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 32),
              _buildChessBoard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChessBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final coordinateSize = 24.0;
        final borderWidth = 4.0;
        final boardSize = maxWidth - coordinateSize - (borderWidth * 2);
        final squareSize = boardSize / 8;
        
        return SizedBox(
          width: maxWidth,
          height: maxWidth,
          child: Stack(
            children: [
              // Main chess board
              Positioned(
                left: coordinateSize,
                top: 0,
                child: Container(
                  width: boardSize + (borderWidth * 2),
                  height: boardSize + (borderWidth * 2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFF403A3A), // Darker border
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.5),
                        blurRadius: 10,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: List.generate(8, (row) {
                      return Row(
                        children: List.generate(8, (col) {
                          final isLight = (row + col) % 2 == 0;
                          final piece = _board[row][col];
                          final isSelected = 
                              _selectedRow == row && _selectedCol == col;
                          
                          // Classic wood-style colors
                          final squareColor = isLight
                              ? const Color(0xFFF0D9B5) // Light wood
                              : const Color(0xFFB58863); // Dark wood
                              
                          return GestureDetector(
                            onTap: () => _onSquareTap(row, col),
                            child: Container(
                              width: squareSize,
                              height: squareSize,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? NunuColors.primaryMain.withOpacity(0.5)
                                    : squareColor,
                              ),
                              child: piece != null
                                  ? Center(
                                      child: Text(
                                        _getPieceSymbol(piece),
                                        style: TextStyle(
                                          fontSize: squareSize * (piece.endsWith('P') ? 0.7 : (piece.endsWith('K') || piece.endsWith('Q') ? 1.0 : 0.85)),
                                          height: 1.0,
                                          color: piece.startsWith('W') 
                                              ? Colors.white 
                                              : Colors.black,
                                          shadows: [
                                            Shadow(
                                              offset: const Offset(0, 1),
                                              blurRadius: 4,
                                              color: piece.startsWith('W') 
                                                  ? Colors.black.withOpacity(0.8)
                                                  : Colors.white.withOpacity(0.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
              // Rank numbers (1-8) on the left
              ...List.generate(8, (row) {
                final rank = 8 - row; // 8 at top, 1 at bottom
                return Positioned(
                  left: 0,
                  top: borderWidth + (row * squareSize),
                  height: squareSize,
                  width: coordinateSize,
                  child: Center(
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
              // File letters (a-h) on the bottom
              ...List.generate(8, (col) {
                final file = String.fromCharCode(97 + col); // a-h
                return Positioned(
                  left: coordinateSize + borderWidth + (col * squareSize),
                  bottom: 0,
                  width: squareSize,
                  height: coordinateSize,
                  child: Center(
                    child: Text(
                      file,
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _getPieceSymbol(String piece) {
    // Use filled symbols for both sides, color distinguishes them
    switch (piece) {
      case 'WK': return '♚';
      case 'WQ': return '♛';
      case 'WR': return '♜';
      case 'WB': return '♝';
      case 'WN': return '♞';
      case 'WP': return '♟';
      case 'BK': return '♚';
      case 'BQ': return '♛';
      case 'BR': return '♜';
      case 'BB': return '♝';
      case 'BN': return '♞';
      case 'BP': return '♟';
      default: return '';
    }
  }
}
