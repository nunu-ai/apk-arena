import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelBingo extends LevelWidget {
  const LevelBingo({super.key, required super.onComplete});

  @override
  State<LevelBingo> createState() => _LevelBingoState();
}

class _LevelBingoState extends State<LevelBingo>
    with TickerProviderStateMixin {
  static const int _gridSize = 5;
  static const int _maxMistakes = 3;
  static const Duration _callInterval = Duration(milliseconds: 5500);
  static const Duration _markWindow = Duration(milliseconds: 5000);

  final Random _random = Random();

  // Bingo card: 5x5 grid with numbers
  // B(1-15), I(16-30), N(31-45), G(46-60), O(61-75)
  late List<List<int>> _card;
  late List<List<bool>> _marked;
  late Set<int> _calledNumbers;

  int? _currentCall;
  int _mistakes = 0;
  bool _isComplete = false;
  bool _hasWon = false;
  Timer? _callTimer;
  Timer? _markTimer;
  bool _callExpired = false;
  int? _wrongTapRow;
  int? _wrongTapCol;

  // Animation controllers
  late AnimationController _callAnimController;
  late Animation<double> _callScaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _timerBarController;

  // Track which cells were just correctly marked for animation
  int? _justMarkedRow;
  int? _justMarkedCol;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _generateCard();
    _calledNumbers = {};
    _marked = List.generate(
      _gridSize,
      (_) => List.generate(_gridSize, (_) => false),
    );
    // Free space in center
    _marked[2][2] = true;

    // Start calling numbers after a brief delay
    Future.delayed(const Duration(milliseconds: 1200), _callNextNumber);
  }

  void _initAnimations() {
    _callAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _callScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _callAnimController, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _timerBarController = AnimationController(
      duration: _markWindow,
      vsync: this,
    );
  }

  void _generateCard() {
    _card = List.generate(_gridSize, (_) => List.filled(_gridSize, 0));

    for (int col = 0; col < _gridSize; col++) {
      final minVal = col * 15 + 1;
      final available = List.generate(15, (i) => minVal + i);
      available.shuffle(_random);

      for (int row = 0; row < _gridSize; row++) {
        if (row == 2 && col == 2) {
          _card[row][col] = 0; // Free space
        } else {
          _card[row][col] = available.removeLast();
        }
      }
    }
  }

  void _callNextNumber() {
    if (_isComplete || !mounted) return;

    // Generate available numbers that haven't been called
    final available = <int>[];
    for (int i = 1; i <= 75; i++) {
      if (!_calledNumbers.contains(i)) {
        available.add(i);
      }
    }

    if (available.isEmpty) {
      // All numbers called, player loses
      _endGame(false);
      return;
    }

    // Prefer numbers on the card that haven't been marked
    final onCardUnmarked = <int>[];
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        final num = _card[row][col];
        if (num != 0 && !_marked[row][col] && !_calledNumbers.contains(num)) {
          onCardUnmarked.add(num);
        }
      }
    }

    // 70% chance to call a number that's on the card
    int nextCall;
    if (onCardUnmarked.isNotEmpty && _random.nextDouble() < 0.7) {
      nextCall = onCardUnmarked[_random.nextInt(onCardUnmarked.length)];
    } else {
      nextCall = available[_random.nextInt(available.length)];
    }

    setState(() {
      _currentCall = nextCall;
      _calledNumbers.add(nextCall);
      _callExpired = false;
    });

    _callAnimController.forward(from: 0);
    _timerBarController.forward(from: 0);

    // Check if number is on card - if so, start mark timer
    bool isOnCard = false;
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        if (_card[row][col] == nextCall && !_marked[row][col]) {
          isOnCard = true;
          break;
        }
      }
      if (isOnCard) break;
    }

    if (isOnCard) {
      _markTimer?.cancel();
      _markTimer = Timer(_markWindow, () {
        if (!mounted || _isComplete) return;
        // Player missed marking this number
        setState(() {
          _mistakes++;
          _callExpired = true;
        });
        if (_mistakes >= _maxMistakes) {
          _endGame(false);
        }
      });
    }

    // Schedule next call
    _callTimer?.cancel();
    _callTimer = Timer(_callInterval, _callNextNumber);
  }

  void _onCellTap(int row, int col) {
    if (_isComplete || _marked[row][col] || _card[row][col] == 0) return;

    final cellNumber = _card[row][col];

    if (cellNumber == _currentCall) {
      // Correct mark!
      _markTimer?.cancel();
      setState(() {
        _marked[row][col] = true;
        _justMarkedRow = row;
        _justMarkedCol = col;
      });

      // Clear the "just marked" highlight after animation
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _justMarkedRow = null;
            _justMarkedCol = null;
          });
        }
      });

      // Check for bingo
      if (_checkBingo()) {
        _endGame(true);
      }
    } else {
      // Wrong tap - but only penalize if the number has been called
      if (_calledNumbers.contains(cellNumber)) {
        // This number was already called and player didn't mark it - allow late mark
        setState(() {
          _marked[row][col] = true;
          _justMarkedRow = row;
          _justMarkedCol = col;
        });
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            setState(() {
              _justMarkedRow = null;
              _justMarkedCol = null;
            });
          }
        });
        if (_checkBingo()) {
          _endGame(true);
        }
      } else {
        // Tapped a number that hasn't been called - mistake!
        setState(() {
          _mistakes++;
          _wrongTapRow = row;
          _wrongTapCol = col;
        });
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            setState(() {
              _wrongTapRow = null;
              _wrongTapCol = null;
            });
          }
        });
        if (_mistakes >= _maxMistakes) {
          _endGame(false);
        }
      }
    }
  }

  bool _checkBingo() {
    // Check rows
    for (int row = 0; row < _gridSize; row++) {
      if (_marked[row].every((m) => m)) return true;
    }

    // Check columns
    for (int col = 0; col < _gridSize; col++) {
      bool complete = true;
      for (int row = 0; row < _gridSize; row++) {
        if (!_marked[row][col]) {
          complete = false;
          break;
        }
      }
      if (complete) return true;
    }

    // Check diagonals
    bool diag1 = true, diag2 = true;
    for (int i = 0; i < _gridSize; i++) {
      if (!_marked[i][i]) diag1 = false;
      if (!_marked[i][_gridSize - 1 - i]) diag2 = false;
    }
    if (diag1 || diag2) return true;

    return false;
  }

  void _endGame(bool won) {
    _callTimer?.cancel();
    _markTimer?.cancel();
    setState(() {
      _isComplete = true;
      _hasWon = won;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      widget.onComplete(LevelOutcome(score: won ? 1 : 0));
    });
  }

  String _getColumnLetter(int col) {
    return 'BINGO'[col];
  }

  Color _getColumnColor(int col) {
    final colors = [
      const Color(0xFFFF6B6B), // B - Red
      const Color(0xFFFFE66D), // I - Yellow
      const Color(0xFF4ECDC4), // N - Teal
      const Color(0xFF95E1D3), // G - Mint
      const Color(0xFFA78BFA), // O - Purple
    ];
    return colors[col];
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _markTimer?.cancel();
    _callAnimController.dispose();
    _pulseController.dispose();
    _timerBarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1A0A2E),
            NunuColors.backgroundDefault,
            Color(0xFF0D1B2A),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildCurrentCall(),
            const SizedBox(height: 8),
            _buildTimerBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildBingoCard()),
            _buildMistakesIndicator(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentCall() {
    if (_currentCall == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        child: const Text(
          'GET READY...',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: NunuColors.textSecondary,
            letterSpacing: 2,
          ),
        ),
      );
    }

    final col = (_currentCall! - 1) ~/ 15;
    final letter = _getColumnLetter(col);
    final color = _getColumnColor(col);

    return AnimatedBuilder(
      animation: _callScaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _callScaleAnimation.value,
          child: AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _callExpired ? 1.0 : _pulseAnimation.value,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: _callExpired ? 0.1 : 0.3),
                        color.withValues(alpha: _callExpired ? 0.05 : 0.15),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _callExpired
                          ? NunuColors.errorMain.withValues(alpha: 0.5)
                          : color,
                      width: 3,
                    ),
                    boxShadow: _callExpired
                        ? null
                        : [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        letter,
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: _callExpired
                              ? NunuColors.textSecondary
                              : color,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_currentCall',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _callExpired ? NunuColors.textSecondary : Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildTimerBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AnimatedBuilder(
        animation: _timerBarController,
        builder: (context, child) {
          final progress = 1.0 - _timerBarController.value;
          Color barColor;
          if (progress > 0.5) {
            barColor = NunuColors.successMain;
          } else if (progress > 0.25) {
            barColor = NunuColors.warningMain;
          } else {
            barColor = NunuColors.errorMain;
          }

          return Container(
            height: 6,
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: barColor.withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBingoCard() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Column headers B-I-N-G-O
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: List.generate(_gridSize, (col) {
                  return Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(3),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _getColumnColor(col).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _getColumnColor(col).withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'BINGO'[col],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _getColumnColor(col),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4),
            // Bingo grid
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: NunuColors.backgroundPaper.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _isComplete
                        ? (_hasWon
                            ? NunuColors.successMain
                            : NunuColors.errorMain)
                        : NunuColors.primaryDark,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _isComplete
                          ? (_hasWon
                              ? NunuColors.successMain.withValues(alpha: 0.3)
                              : NunuColors.errorMain.withValues(alpha: 0.3))
                          : NunuColors.primaryDarker.withValues(alpha: 0.5),
                      blurRadius: 20,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: List.generate(_gridSize, (row) {
                    return Expanded(
                      child: Row(
                        children: List.generate(_gridSize, (col) {
                          return Expanded(child: _buildCell(row, col));
                        }),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final number = _card[row][col];
    final isMarked = _marked[row][col];
    final isFreeSpace = number == 0;
    final isJustMarked = row == _justMarkedRow && col == _justMarkedCol;
    final isWrongTap = row == _wrongTapRow && col == _wrongTapCol;
    final color = _getColumnColor(col);

    return GestureDetector(
      onTap: () => _onCellTap(row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          gradient: isMarked
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withValues(alpha: 0.8),
                    color.withValues(alpha: 0.5),
                  ],
                )
              : null,
          color: isMarked
              ? null
              : (isWrongTap
                  ? NunuColors.errorMain.withValues(alpha: 0.4)
                  : NunuColors.backgroundDefault.withValues(alpha: 0.6)),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isJustMarked
                ? NunuColors.successLight
                : (isWrongTap
                    ? NunuColors.errorMain
                    : (isMarked
                        ? color.withValues(alpha: 0.8)
                        : NunuColors.primaryDark.withValues(alpha: 0.4))),
            width: 1.5,
          ),
          boxShadow: isJustMarked
              ? [
                  BoxShadow(
                    color: NunuColors.successMain.withValues(alpha: 0.6),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isFreeSpace
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.star,
                      color: NunuColors.warningMain,
                      size: 20,
                    ),
                    const Text(
                      'FREE',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: NunuColors.warningMain,
                      ),
                    ),
                  ],
                )
              : Stack(
                  alignment: Alignment.center,
                  children: [
                    Text(
                      '$number',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isMarked ? Colors.white : NunuColors.textSecondary,
                      ),
                    ),
                    if (isMarked)
                      Icon(
                        Icons.check_circle,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: 32,
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildMistakesIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'LIVES: ',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: NunuColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          ...List.generate(_maxMistakes, (i) {
            final isLost = i < _mistakes;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                isLost ? Icons.favorite_border : Icons.favorite,
                color: isLost
                    ? NunuColors.errorDark.withValues(alpha: 0.4)
                    : NunuColors.errorMain,
                size: 28,
              ),
            );
          }),
        ],
      ),
    );
  }
}

