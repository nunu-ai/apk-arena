import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelTicTacToe extends LevelWidget {
  const LevelTicTacToe({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelTicTacToe> createState() => _LevelTicTacToeState();
}

class _LevelTicTacToeState extends State<LevelTicTacToe>
    with SingleTickerProviderStateMixin {
  // 0 = empty, 1 = player (X), 2 = AI (O)
  late List<int> _board;
  bool _playerTurn = true;
  int _winner = 0; // 0 = none, 1 = player, 2 = AI, 3 = draw
  bool _isComplete = false;
  int _moveCount = 0;
  int _gamesPlayed = 1;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _board = List.filled(9, 0);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap(int index) {
    if (_board[index] != 0 || !_playerTurn || _winner != 0) return;

    setState(() {
      _board[index] = 1;
      _moveCount++;
      _playerTurn = false;
    });

    _checkWinner();

    if (_winner == 0) {
      // AI moves after a short delay
      Future.delayed(const Duration(milliseconds: 400), () {
        if (!mounted || _winner != 0) return;
        _aiMove();
      });
    }
  }

  void _aiMove() {
    // simple AI: try to win, then block, then take center, then random
    final move = _findBestMove();
    if (move == -1) return;

    setState(() {
      _board[move] = 2;
      _moveCount++;
      _playerTurn = true;
    });

    _checkWinner();
  }

  int _findBestMove() {
    // 1. try to win
    for (int i = 0; i < 9; i++) {
      if (_board[i] == 0) {
        _board[i] = 2;
        if (_checkWinFor(2)) {
          _board[i] = 0;
          return i;
        }
        _board[i] = 0;
      }
    }

    // 2. block player win
    for (int i = 0; i < 9; i++) {
      if (_board[i] == 0) {
        _board[i] = 1;
        if (_checkWinFor(1)) {
          _board[i] = 0;
          return i;
        }
        _board[i] = 0;
      }
    }

    // 3. take center
    if (_board[4] == 0) return 4;

    // 4. take a corner
    final corners = [0, 2, 6, 8]..shuffle(Random());
    for (final c in corners) {
      if (_board[c] == 0) return c;
    }

    // 5. take any available
    final available = <int>[];
    for (int i = 0; i < 9; i++) {
      if (_board[i] == 0) available.add(i);
    }
    if (available.isEmpty) return -1;
    return available[Random().nextInt(available.length)];
  }

  static const List<List<int>> _winLines = [
    [0, 1, 2], [3, 4, 5], [6, 7, 8], // rows
    [0, 3, 6], [1, 4, 7], [2, 5, 8], // cols
    [0, 4, 8], [2, 4, 6], // diagonals
  ];

  bool _checkWinFor(int player) {
    for (final line in _winLines) {
      if (_board[line[0]] == player &&
          _board[line[1]] == player &&
          _board[line[2]] == player) {
        return true;
      }
    }
    return false;
  }

  List<int>? _getWinLine(int player) {
    for (final line in _winLines) {
      if (_board[line[0]] == player &&
          _board[line[1]] == player &&
          _board[line[2]] == player) {
        return line;
      }
    }
    return null;
  }

  void _checkWinner() {
    if (_checkWinFor(1)) {
      setState(() => _winner = 1);
      _handleGameEnd();
    } else if (_checkWinFor(2)) {
      setState(() => _winner = 2);
      _handleGameEnd();
    } else if (!_board.contains(0)) {
      setState(() => _winner = 3);
      _handleGameEnd();
    }
  }

  void _handleGameEnd() {
    if (_isComplete) return;

    if (_winner == 1) {
      // player won — complete the level
      setState(() => _isComplete = true);
      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onComplete(true, metrics: {
          'moves': _moveCount,
          'games_played': _gamesPlayed,
        });
      });
    } else {
      // draw or loss — just let them play again, no failure reported
      _gamesPlayed++;
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) _resetGame();
      });
    }
  }

  void _resetGame() {
    setState(() {
      _board = List.filled(9, 0);
      _playerTurn = true;
      _winner = 0;
      _isComplete = false;
      _moveCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final winLine = _winner == 1
        ? _getWinLine(1)
        : _winner == 2
            ? _getWinLine(2)
            : null;

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // status
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Text(
                      _statusText(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: _statusColor(),
                            fontWeight: FontWeight.bold,
                          ),
                    );
                  },
                ),

                const SizedBox(height: 8),
                Text(
                  'you are X · AI is O · game $_gamesPlayed',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: NunuColors.textSecondary,
                      ),
                ),

                const SizedBox(height: 24),

                // board
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              NunuColors.primaryMain.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: GridView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                        ),
                        itemCount: 9,
                        itemBuilder: (context, index) {
                          return _buildCell(index, winLine);
                        },
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // auto-restarting message on loss/draw
                if ((_winner == 2 || _winner == 3) && !_isComplete)
                  Text(
                    'restarting...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NunuColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusText() {
    switch (_winner) {
      case 1:
        return 'you win!';
      case 2:
        return 'AI wins. try again!';
      case 3:
        return 'draw. try again!';
      default:
        return _playerTurn ? 'your turn' : 'AI thinking...';
    }
  }

  Color _statusColor() {
    switch (_winner) {
      case 1:
        return NunuColors.successMain;
      case 2:
        return NunuColors.errorMain;
      case 3:
        return NunuColors.warningMain;
      default:
        return _playerTurn ? NunuColors.primaryLight : NunuColors.textSecondary;
    }
  }

  Widget _buildCell(int index, List<int>? winLine) {
    final value = _board[index];
    final isWinCell = winLine != null && winLine.contains(index);
    final isClickable = value == 0 && _playerTurn && _winner == 0;

    return GestureDetector(
      onTap: isClickable ? () => _handleTap(index) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isWinCell
              ? (_winner == 1
                  ? NunuColors.successMain.withValues(alpha: 0.3)
                  : NunuColors.errorMain.withValues(alpha: 0.3))
              : value == 0
                  ? NunuColors.backgroundDefault.withValues(alpha: 0.5)
                  : NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isWinCell
                ? (_winner == 1
                    ? NunuColors.successMain
                    : NunuColors.errorMain)
                : isClickable
                    ? NunuColors.primaryMain.withValues(alpha: 0.4)
                    : Colors.white.withValues(alpha: 0.1),
            width: isWinCell ? 2 : 1,
          ),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: value == 0
                ? const SizedBox.shrink()
                : Text(
                    value == 1 ? 'X' : 'O',
                    key: ValueKey('cell_${index}_$value'),
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      color: value == 1
                          ? NunuColors.primaryLight
                          : NunuColors.secondaryLight,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
