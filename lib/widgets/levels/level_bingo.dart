import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

class LevelBingo extends LevelWidget {
  const LevelBingo({super.key, required super.onComplete});

  @override
  State<LevelBingo> createState() => _LevelBingoState();
}

class _BingoStageConfig {
  final int cardCount;
  final Duration callInterval;
  final Duration markWindow;

  const _BingoStageConfig({
    required this.cardCount,
    required this.callInterval,
    required this.markWindow,
  });
}

class _BingoCardState {
  static const int gridSize = 5;

  final List<List<int>> numbers;
  final List<List<bool>> marked;

  _BingoCardState(Random random)
    : numbers = _generateNumbers(random),
      marked = List.generate(
        gridSize,
        (_) => List.generate(gridSize, (_) => false),
      ) {
    marked[2][2] = true;
  }

  static List<List<int>> _generateNumbers(Random random) {
    final card = List.generate(gridSize, (_) => List.filled(gridSize, 0));

    for (var col = 0; col < gridSize; col++) {
      final minVal = col * 15 + 1;
      final available = List.generate(15, (i) => minVal + i)..shuffle(random);

      for (var row = 0; row < gridSize; row++) {
        if (row == 2 && col == 2) {
          card[row][col] = 0;
        } else {
          card[row][col] = available.removeLast();
        }
      }
    }

    return card;
  }
}

class _CellRef {
  final int cardIndex;
  final int row;
  final int col;

  const _CellRef(this.cardIndex, this.row, this.col);
}

class _TrayCall {
  final int number;
  final int spawnedAtMs;

  const _TrayCall({required this.number, required this.spawnedAtMs});
}

class _LevelBingoState extends State<LevelBingo> with TickerProviderStateMixin {
  static const int _gridSize = _BingoCardState.gridSize;
  static const int _stageCount = 5;
  static const double _stageBingoBonus = 0.05;
  static const double _stageMistakeMaxScore = 0.15;
  static const double _trayPixelsPerSecond = 38;
  static const double _trayPillWidth = 74;
  static const List<_BingoStageConfig> _stages = [
    _BingoStageConfig(
      cardCount: 1,
      callInterval: Duration(milliseconds: 5500),
      markWindow: Duration(milliseconds: 5000),
    ),
    _BingoStageConfig(
      cardCount: 1,
      callInterval: Duration(milliseconds: 4300),
      markWindow: Duration(milliseconds: 3800),
    ),
    _BingoStageConfig(
      cardCount: 1,
      callInterval: Duration(milliseconds: 2800),
      markWindow: Duration(milliseconds: 2500),
    ),
    _BingoStageConfig(
      cardCount: 2,
      callInterval: Duration(milliseconds: 4100),
      markWindow: Duration(milliseconds: 3500),
    ),
    _BingoStageConfig(
      cardCount: 4,
      callInterval: Duration(milliseconds: 3400),
      markWindow: Duration(milliseconds: 2800),
    ),
  ];

  final Random _random = Random();
  final Stopwatch _trayStopwatch = Stopwatch();

  late List<_BingoCardState> _cards;
  Set<int> _calledNumbers = {};
  List<_TrayCall> _callTray = [];
  final List<double> _completedStageScores = [];
  double _lastTrayWidth = 420;

  int _stageIndex = 0;
  int? _currentCall;
  int _stageMissedCalls = 0;
  int _stageWrongTaps = 0;
  bool _isComplete = false;
  bool _hasWon = false;
  bool _callExpired = false;
  bool _stageTransitioning = false;
  bool _stageSolvedTransition = false;

  Timer? _callTimer;
  Timer? _markTimer;

  late AnimationController _callAnimController;
  late Animation<double> _callScaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _trayController;

  int? _justMarkedCard;
  int? _justMarkedRow;
  int? _justMarkedCol;
  int? _wrongTapCard;
  int? _wrongTapRow;
  int? _wrongTapCol;

  _BingoStageConfig get _stage => _stages[_stageIndex];
  bool get _usesMovingTray => _stageIndex >= 1;
  double get _currentScore =>
      _completedStageScores.fold<double>(0, (sum, score) => sum + score);

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
      () => LevelOutcome(
        score: _currentScore / _stageCount,
        metrics: {'stages_completed': _completedStageScores.length},
      ),
    );
    _initAnimations();
    _configureStage(0);
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

    _trayController =
        AnimationController(
            duration: const Duration(milliseconds: 1000),
            vsync: this,
          )
          ..addListener(_expireOffscreenTrayCalls)
          ..repeat();
  }

  void _configureStage(int stageIndex) {
    _callTimer?.cancel();
    _markTimer?.cancel();

    _stageIndex = stageIndex;
    _cards = List.generate(
      _stages[stageIndex].cardCount,
      (_) => _BingoCardState(_random),
    );
    _calledNumbers = {};
    _callTray = [];
    _trayStopwatch
      ..reset()
      ..start();
    _currentCall = null;
    _stageMissedCalls = 0;
    _stageWrongTaps = 0;
    _callExpired = false;
    _stageTransitioning = false;
    _stageSolvedTransition = false;
    _justMarkedCard = null;
    _justMarkedRow = null;
    _justMarkedCol = null;
    _wrongTapCard = null;
    _wrongTapRow = null;
    _wrongTapCol = null;
  }

  void _callNextNumber() {
    if (_isComplete || _stageTransitioning || !mounted) return;

    final available = <int>[
      for (var i = 1; i <= 75; i++)
        if (!_calledNumbers.contains(i)) i,
    ];

    if (available.isEmpty) {
      if (!_usesMovingTray || _callTray.isEmpty) {
        _completeStage(solvedBingo: false);
      }
      return;
    }

    final nextCall = _chooseNextCall(available);

    setState(() {
      _currentCall = nextCall;
      _calledNumbers.add(nextCall);
      _callTray.add(
        _TrayCall(
          number: nextCall,
          spawnedAtMs: _trayStopwatch.elapsedMilliseconds,
        ),
      );
      _callExpired = false;
    });

    _callAnimController.forward(from: 0);

    if (!_usesMovingTray && _unmarkedCellsForCall(nextCall).isNotEmpty) {
      _markTimer?.cancel();
      _markTimer = Timer(_stage.markWindow, () {
        if (!mounted || _isComplete || _stageTransitioning) return;
        if (_unmarkedCellsForCall(nextCall).isEmpty) return;

        setState(() {
          _stageMissedCalls++;
          _callExpired = true;
        });
      });
    } else {
      _markTimer?.cancel();
    }

    _callTimer?.cancel();
    _callTimer = Timer(_stage.callInterval, _callNextNumber);
  }

  int _chooseNextCall(List<int> available) {
    final onCardUnmarked = _getOnCardUnmarkedAvailableNumbers(available);
    if (onCardUnmarked.isEmpty) {
      return available[_random.nextInt(available.length)];
    }

    final callIndex = _calledNumbers.length + 1;
    final biasChance = _biasChanceForCallIndex(callIndex);
    if (_random.nextDouble() < biasChance) {
      return onCardUnmarked[_random.nextInt(onCardUnmarked.length)];
    }
    return available[_random.nextInt(available.length)];
  }

  List<int> _getOnCardUnmarkedAvailableNumbers(List<int> available) {
    final availableSet = available.toSet();
    final candidates = <int>{};

    for (final card in _cards) {
      for (var row = 0; row < _gridSize; row++) {
        for (var col = 0; col < _gridSize; col++) {
          final number = card.numbers[row][col];
          if (number == 0 || card.marked[row][col]) continue;
          if (availableSet.contains(number)) {
            candidates.add(number);
          }
        }
      }
    }

    return candidates.toList();
  }

  double _biasChanceForCallIndex(int callIndex) {
    if (callIndex <= 10) return 0.5;
    if (callIndex <= 25) {
      final t = (callIndex - 10) / 15;
      return 0.4 - (0.15 * t);
    }
    final t = ((callIndex - 25) / 35).clamp(0.0, 1.0);
    return 0.25 - (0.15 * t);
  }

  void _expireOffscreenTrayCalls() {
    if (!_usesMovingTray ||
        _callTray.isEmpty ||
        _isComplete ||
        _stageTransitioning ||
        !mounted) {
      return;
    }

    final nowMs = _trayStopwatch.elapsedMilliseconds;
    final expiredCalls = _callTray.where((call) {
      final x = _trayXForCall(call, nowMs: nowMs, trayWidth: _lastTrayWidth);
      return x + _trayPillWidth < 0;
    }).toList();
    if (expiredCalls.isEmpty) return;

    setState(() {
      for (final expiredCall in expiredCalls) {
        final expiredCallWasMissed = _unmarkedCellsForCall(
          expiredCall.number,
        ).isNotEmpty;
        if (expiredCallWasMissed) {
          _stageMissedCalls++;
          _callExpired = true;
        }
      }
      _callTray.removeWhere(expiredCalls.contains);
    });

    if (_calledNumbers.length >= 75 &&
        _callTray.isEmpty &&
        !_stageTransitioning) {
      _completeStage(solvedBingo: false);
    }
  }

  double _trayXForCall(
    _TrayCall call, {
    required int nowMs,
    required double trayWidth,
  }) {
    final ageSeconds = (nowMs - call.spawnedAtMs) / 1000;
    return trayWidth + 8 - (ageSeconds * _trayPixelsPerSecond);
  }

  List<_CellRef> _unmarkedCellsForCall(int number) {
    final refs = <_CellRef>[];
    for (var cardIndex = 0; cardIndex < _cards.length; cardIndex++) {
      final card = _cards[cardIndex];
      for (var row = 0; row < _gridSize; row++) {
        for (var col = 0; col < _gridSize; col++) {
          if (card.numbers[row][col] == number && !card.marked[row][col]) {
            refs.add(_CellRef(cardIndex, row, col));
          }
        }
      }
    }
    return refs;
  }

  void _onCellTap(int cardIndex, int row, int col) {
    if (_isComplete || _stageTransitioning) return;

    final card = _cards[cardIndex];
    if (card.marked[row][col] || card.numbers[row][col] == 0) return;

    final cellNumber = card.numbers[row][col];
    final isCalledNumber = _calledNumbers.contains(cellNumber);

    if (cellNumber == _currentCall || isCalledNumber) {
      _markCell(cardIndex, row, col);

      if (_currentCall != null &&
          _unmarkedCellsForCall(_currentCall!).isEmpty) {
        _markTimer?.cancel();
      }

      if (_isStageComplete()) {
        _completeStage(solvedBingo: true);
      }
      return;
    }

    setState(() {
      _stageWrongTaps++;
      _wrongTapCard = cardIndex;
      _wrongTapRow = row;
      _wrongTapCol = col;
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      setState(() {
        _wrongTapCard = null;
        _wrongTapRow = null;
        _wrongTapCol = null;
      });
    });
  }

  void _markCell(int cardIndex, int row, int col) {
    setState(() {
      _cards[cardIndex].marked[row][col] = true;
      _justMarkedCard = cardIndex;
      _justMarkedRow = row;
      _justMarkedCol = col;
    });

    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _justMarkedCard = null;
        _justMarkedRow = null;
        _justMarkedCol = null;
      });
    });
  }

  bool _isStageComplete() {
    return _cards.every(_hasBingo);
  }

  bool _hasBingo(_BingoCardState card) {
    for (var row = 0; row < _gridSize; row++) {
      if (card.marked[row].every((marked) => marked)) return true;
    }

    for (var col = 0; col < _gridSize; col++) {
      var complete = true;
      for (var row = 0; row < _gridSize; row++) {
        if (!card.marked[row][col]) {
          complete = false;
          break;
        }
      }
      if (complete) return true;
    }

    var diag1 = true;
    var diag2 = true;
    for (var i = 0; i < _gridSize; i++) {
      if (!card.marked[i][i]) diag1 = false;
      if (!card.marked[i][_gridSize - 1 - i]) diag2 = false;
    }

    return diag1 || diag2;
  }

  void _completeStage({required bool solvedBingo}) {
    _callTimer?.cancel();
    _markTimer?.cancel();

    final stageScore = _scoreForStage(solvedBingo: solvedBingo);
    _completedStageScores.add(stageScore);

    if (_stageIndex == _stageCount - 1) {
      _endGame(solvedBingo);
      return;
    }

    setState(() {
      _stageTransitioning = true;
      _stageSolvedTransition = solvedBingo;
      _currentCall = null;
      _callExpired = false;
    });

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted || _isComplete) return;
      setState(() {
        _configureStage(_stageIndex + 1);
      });
      Future.delayed(const Duration(milliseconds: 900), _callNextNumber);
    });
  }

  double _scoreForStage({required bool solvedBingo}) {
    final weightedMistakes = _weightedStageMistakes;
    final mistakeScore = _mistakeScoreForStage(weightedMistakes);
    return (solvedBingo ? _stageBingoBonus : 0) + mistakeScore;
  }

  double get _weightedStageMistakes =>
      _stageMissedCalls + (_stageWrongTaps * 0.5);

  double _mistakeScoreForStage(double mistakes) {
    if (mistakes <= 0) return _stageMistakeMaxScore;
    if (mistakes >= 31) return 0;

    const scoreTable = <int, double>{
      0: 0.15,
      1: 0.13,
      2: 0.11,
      3: 0.095,
      4: 0.08,
      5: 0.07,
      6: 0.063,
      7: 0.059,
      8: 0.055,
      9: 0.052,
      10: 0.05,
      20: 0.02,
      31: 0,
    };

    double scoreAt(int wholeMistakes) {
      final explicit = scoreTable[wholeMistakes];
      if (explicit != null) return explicit;
      if (wholeMistakes > 10 && wholeMistakes < 20) {
        return 0.05 - ((wholeMistakes - 10) * 0.002);
      }
      if (wholeMistakes > 20 && wholeMistakes < 31) {
        return 0.02 - ((wholeMistakes - 20) * (0.02 / 11));
      }
      return 0;
    }

    final lower = mistakes.floor();
    final upper = mistakes.ceil();
    if (lower == upper) return scoreAt(lower);

    final t = mistakes - lower;
    return scoreAt(lower) + ((scoreAt(upper) - scoreAt(lower)) * t);
  }

  void _endGame(bool won) {
    if (_isComplete) return;

    _callTimer?.cancel();
    _markTimer?.cancel();
    setState(() {
      _isComplete = true;
      _hasWon = won;
    });

    final score = _currentScore;
    final completedStages = _completedStageScores.length;
    final bestStageScore = _completedStageScores.isEmpty
        ? 0.0
        : _completedStageScores.reduce((a, b) => a > b ? a : b);
    final averageStageScore = completedStages == 0
        ? 0.0
        : _completedStageScores.fold<double>(0, (sum, score) => sum + score) /
              completedStages;
    Future.delayed(const Duration(milliseconds: 800), () {
      widget.onComplete(
        LevelOutcome(
          score: score,
          metrics: {
            'stages_completed': completedStages,
            'best_stage_score': (bestStageScore * 1000).round() / 10,
            'avg_stage_score': (averageStageScore * 1000).round() / 10,
          },
        ),
      );
    });
  }

  String _getColumnLetter(int col) {
    return 'BINGO'[col];
  }

  Color _getColumnColor(int col) {
    final colors = [
      const Color(0xFFFF6B6B),
      const Color(0xFFFFE66D),
      const Color(0xFF4ECDC4),
      const Color(0xFF95E1D3),
      const Color(0xFFA78BFA),
    ];
    return colors[col];
  }

  @override
  void dispose() {
    _callTimer?.cancel();
    _markTimer?.cancel();
    _callAnimController.dispose();
    _pulseController.dispose();
    _trayController.dispose();
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
            _buildStageStatus(),
            const SizedBox(height: 10),
            _buildCurrentCall(),
            const SizedBox(height: 10),
            Expanded(child: _buildBingoCards()),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStageStatus() {
    return LevelHud(
      stageText: '${_stageIndex + 1}/$_stageCount',
      trailing: Text(
        'miss ${_stageMissedCalls + _stageWrongTaps}',
        style: const TextStyle(
          color: NunuColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      infoTitle: 'bingo',
      infoItems: const [
        LevelHudBullet(
          '🔢',
          'mark called numbers on your cards — all cards are shared',
        ),
        LevelHudBullet(
          '⚡',
          'each stage gets faster; later calls scroll through the tray',
        ),
        LevelHudBullet(
          '❌',
          'missed calls and wrong taps reduce your stage score',
        ),
        LevelHudBullet('🎯', 'complete a bingo line for a stage bonus'),
      ],
    );
  }

  Widget _buildCurrentCall() {
    if (_stageTransitioning) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Text(
          _stageSolvedTransition
              ? 'STAGE ${_stageIndex + 1} CLEAR'
              : 'STAGE ${_stageIndex + 1} COMPLETE',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _stageSolvedTransition
                ? NunuColors.successMain
                : NunuColors.warningMain,
            letterSpacing: 2,
          ),
        ),
      );
    }

    if (_currentCall == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
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

    if (!_usesMovingTray) {
      return _buildCallBadge();
    }

    return SizedBox(
      width: MediaQuery.sizeOf(context).width,
      height: 68,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            _lastTrayWidth = constraints.maxWidth;
            return AnimatedBuilder(
              animation: _trayController,
              builder: (context, child) {
                final nowMs = _trayStopwatch.elapsedMilliseconds;
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    for (final call in _callTray)
                      Positioned(
                        key: ValueKey('${call.number}-${call.spawnedAtMs}'),
                        left: _trayXForCall(
                          call,
                          nowMs: nowMs,
                          trayWidth: constraints.maxWidth,
                        ),
                        top: 14,
                        width: _trayPillWidth,
                        child: _buildCallTrayPill(call.number),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildCallTrayPill(int number) {
    final col = (number - 1) ~/ 15;
    final letter = _getColumnLetter(col);
    final color = _getColumnColor(col);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        '$letter$number',
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: NunuColors.textSecondary,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  Widget _buildCallBadge() {
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 12,
                  ),
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
                          fontSize: 32,
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
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: _callExpired
                              ? NunuColors.textSecondary
                              : Colors.white,
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

  Widget _buildBingoCards() {
    if (_cards.length == 1) {
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: _buildBingoCard(0),
        ),
      );
    }

    if (_cards.length == 2) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: List.generate(_cards.length, (index) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: _buildBingoCard(index),
              ),
            );
          }),
        ),
      );
    }

    return GridView.count(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 0.92,
      children: List.generate(_cards.length, _buildBingoCard),
    );
  }

  Widget _buildBingoCard(int cardIndex) {
    final card = _cards[cardIndex];
    final cardHasBingo = _hasBingo(card);
    final compact = _cards.length > 1;
    final showColumnHeaders = _cards.length != 2 || cardIndex == 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : 520.0;
        final maxHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight
            : maxWidth;
        final labelHeight = compact ? 16.0 : 18.0;
        final headerHeight = compact ? 25.0 : 42.0;
        final reservedHeight = labelHeight + headerHeight + 9;
        final boardSide = max(
          80.0,
          min(maxWidth - (compact ? 0 : 32), maxHeight - reservedHeight),
        );

        return Center(
          child: SizedBox(
            width: boardSide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'CARD ${String.fromCharCode(65 + cardIndex)}',
                  style: TextStyle(
                    fontSize: compact ? 10 : 12,
                    fontWeight: FontWeight.bold,
                    color: cardHasBingo
                        ? NunuColors.successMain
                        : NunuColors.textSecondary,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Opacity(
                  opacity: showColumnHeaders ? 1 : 0,
                  child: _buildColumnHeaders(compact),
                ),
                const SizedBox(height: 3),
                SizedBox.square(
                  dimension: boardSide,
                  child: Container(
                    padding: EdgeInsets.all(compact ? 4 : 8),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(compact ? 12 : 16),
                      border: Border.all(
                        color: cardHasBingo
                            ? NunuColors.successMain
                            : (_isComplete
                                  ? (_hasWon
                                        ? NunuColors.successMain
                                        : NunuColors.errorMain)
                                  : NunuColors.primaryDark),
                        width: compact ? 2 : 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: cardHasBingo
                              ? NunuColors.successMain.withValues(alpha: 0.25)
                              : NunuColors.primaryDarker.withValues(
                                  alpha: 0.45,
                                ),
                          blurRadius: compact ? 10 : 20,
                          spreadRadius: compact ? 1 : 4,
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(_gridSize, (row) {
                        return Expanded(
                          child: Row(
                            children: List.generate(_gridSize, (col) {
                              return Expanded(
                                child: _buildCell(cardIndex, row, col, compact),
                              );
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
      },
    );
  }

  Widget _buildColumnHeaders(bool compact) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 3 : 8),
      child: Row(
        children: List.generate(_gridSize, (col) {
          return Expanded(
            child: Container(
              margin: EdgeInsets.all(compact ? 1.5 : 3),
              padding: EdgeInsets.symmetric(vertical: compact ? 3 : 8),
              decoration: BoxDecoration(
                color: _getColumnColor(col).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(compact ? 5 : 8),
                border: Border.all(
                  color: _getColumnColor(col).withValues(alpha: 0.5),
                  width: compact ? 1 : 2,
                ),
              ),
              child: Center(
                child: Text(
                  'BINGO'[col],
                  style: TextStyle(
                    fontSize: compact ? 11 : 20,
                    fontWeight: FontWeight.bold,
                    color: _getColumnColor(col),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int cardIndex, int row, int col, bool compact) {
    final card = _cards[cardIndex];
    final number = card.numbers[row][col];
    final isMarked = card.marked[row][col];
    final isFreeSpace = number == 0;
    final isJustMarked =
        cardIndex == _justMarkedCard &&
        row == _justMarkedRow &&
        col == _justMarkedCol;
    final isWrongTap =
        cardIndex == _wrongTapCard &&
        row == _wrongTapRow &&
        col == _wrongTapCol;
    final color = _getColumnColor(col);

    return GestureDetector(
      onTap: () => _onCellTap(cardIndex, row, col),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: EdgeInsets.all(compact ? 1.5 : 3),
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
          borderRadius: BorderRadius.circular(compact ? 5 : 8),
          border: Border.all(
            color: isJustMarked
                ? NunuColors.successLight
                : (isWrongTap
                      ? NunuColors.errorMain
                      : (isMarked
                            ? color.withValues(alpha: 0.8)
                            : NunuColors.primaryDark.withValues(alpha: 0.4))),
            width: compact ? 1 : 1.5,
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
                      size: compact ? 12 : 20,
                    ),
                    if (!compact)
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
                        fontSize: compact ? 10 : 18,
                        fontWeight: FontWeight.bold,
                        color: isMarked
                            ? Colors.white
                            : NunuColors.textSecondary,
                      ),
                    ),
                    if (isMarked)
                      Icon(
                        Icons.check_circle,
                        color: Colors.white.withValues(alpha: 0.3),
                        size: compact ? 18 : 32,
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}
