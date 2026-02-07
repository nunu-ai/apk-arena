import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// ARC color palette  (0 = empty, 1-5 = colors, 9 = refill pickup)
// Merge chain: 1+1→2, 2+2→3, 3+3→4, 4+4→5
// ---------------------------------------------------------------------------

const Map<int, Color> _arcColors = {
  0: Color(0xFF16122F), // empty
  1: Color(0xFF1E93FF), // blue
  2: Color(0xFFFF5630), // red
  3: Color(0xFF22C55E), // green
  4: Color(0xFFFFAB00), // yellow
  5: Color(0xFF805CE5), // purple
};

const int _refillValue = 9;
const int _wallValue = 8;

// ---------------------------------------------------------------------------
// Round data
// ---------------------------------------------------------------------------

class _RoundDef {
  final List<List<int>> grid;
  final int playerRow;
  final int playerCol;
  final int targetRow;
  final int targetCol;
  final int targetColor;

  const _RoundDef({
    required this.grid,
    required this.playerRow,
    required this.playerCol,
    required this.targetRow,
    required this.targetCol,
    required this.targetColor,
  });
}

// Round 1: 2 blue blocks, target = red. Teach push + merge.
const _round1 = _RoundDef(
  grid: [
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 1, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 9],
    [0, 0, 0, 0, 0, 0, 0],
  ],
  playerRow: 2,
  playerCol: 0,
  targetRow: 2,
  targetCol: 6,
  targetColor: 2, // red
);

// Round 2: 4 blue blocks, target = green. Chain merges.
const _round2 = _RoundDef(
  grid: [
    [0, 0, 0, 0, 0, 0, 0],
    [0, 1, 0, 0, 0, 1, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 1, 0, 0, 0, 1, 0],
    [9, 0, 0, 0, 0, 0, 0],
  ],
  playerRow: 3,
  playerCol: 3,
  targetRow: 3,
  targetCol: 0,
  targetColor: 3, // green
);

// Round 3: 4 blue + 2 red, target = yellow. Walls block paths.
// All movable blocks are away from edges so the player can push from any side.
const _round3 = _RoundDef(
  grid: [
    [0, 0, 0, 0, 0, 0, 0],
    [0, 0, 1, 0, 1, 0, 0],
    [0, 0, 0, 0, 0, 0, 0],
    [0, 8, 0, 0, 0, 8, 0],
    [0, 0, 2, 0, 2, 0, 0],
    [0, 0, 1, 0, 1, 0, 0],
    [0, 0, 0, 9, 0, 0, 0],
  ],
  playerRow: 3,
  playerCol: 3,
  targetRow: 3,
  targetCol: 3,
  targetColor: 4, // yellow
);

const List<_RoundDef> _rounds = [_round1, _round2, _round3];

// ---------------------------------------------------------------------------
// Round state
// ---------------------------------------------------------------------------

class _RoundState {
  static const int maxActions = 30;

  List<List<int>> grid;
  int playerRow;
  int playerCol;
  int actionsRemaining;
  final List<_Snapshot> history;
  final _RoundDef def;

  _RoundState(this.def)
    : grid = _cloneGrid(def.grid),
      playerRow = def.playerRow,
      playerCol = def.playerCol,
      actionsRemaining = maxActions,
      history = [];

  void saveSnapshot() {
    history.add(
      _Snapshot(
        grid: _cloneGrid(grid),
        playerRow: playerRow,
        playerCol: playerCol,
        actionsRemaining: actionsRemaining,
      ),
    );
  }

  bool undo() {
    if (history.isEmpty) return false;
    final snap = history.removeLast();
    grid = snap.grid;
    playerRow = snap.playerRow;
    playerCol = snap.playerCol;
    actionsRemaining = snap.actionsRemaining;
    return true;
  }

  void reset() {
    grid = _cloneGrid(def.grid);
    playerRow = def.playerRow;
    playerCol = def.playerCol;
    actionsRemaining = maxActions;
    history.clear();
  }
}

class _Snapshot {
  final List<List<int>> grid;
  final int playerRow;
  final int playerCol;
  final int actionsRemaining;
  const _Snapshot({
    required this.grid,
    required this.playerRow,
    required this.playerCol,
    required this.actionsRemaining,
  });
}

List<List<int>> _cloneGrid(List<List<int>> g) =>
    g.map((r) => List<int>.from(r)).toList();

// ---------------------------------------------------------------------------
// Level widget
// ---------------------------------------------------------------------------

class LevelArcAgi3 extends LevelWidget {
  const LevelArcAgi3({super.key, required super.onComplete});

  @override
  State<LevelArcAgi3> createState() => _LevelArcAgi3State();
}

class _LevelArcAgi3State extends State<LevelArcAgi3>
    with TickerProviderStateMixin {
  static const int _gridSize = 7;

  static const int _maxLives = 3;

  int _currentRound = 0;
  int _lives = _maxLives;
  late _RoundState _state;

  // round-complete overlay
  bool _showRoundComplete = false;

  // life-lost overlay
  bool _showLifeLost = false;

  // merge animation
  bool _merging = false;
  int _mergeRow = -1;
  int _mergeCol = -1;
  late AnimationController _mergeCtrl;
  late Animation<double> _mergeScale;

  // player pulse
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  // target pulse
  late AnimationController _targetCtrl;
  late Animation<double> _targetAnim;

  // refill dot pulse
  late AnimationController _refillCtrl;
  late Animation<double> _refillAnim;

  // round complete scale
  late AnimationController _flashCtrl;
  late Animation<double> _flashScale;
  late Animation<double> _flashOpacity;

  @override
  void initState() {
    super.initState();
    _state = _RoundState(_rounds[_currentRound]);

    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _flashScale = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _flashCtrl, curve: Curves.elasticOut),
    );
    _flashOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _flashCtrl,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _mergeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _mergeScale = Tween<double>(
      begin: 1.0,
      end: 1.4,
    ).animate(CurvedAnimation(parent: _mergeCtrl, curve: Curves.easeOutBack));
    _mergeCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        _mergeCtrl.reverse();
      } else if (s == AnimationStatus.dismissed && _merging) {
        setState(() => _merging = false);
      }
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _targetCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _targetAnim = Tween<double>(
      begin: 0.2,
      end: 0.45,
    ).animate(CurvedAnimation(parent: _targetCtrl, curve: Curves.easeInOut));

    _refillCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _refillAnim = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _refillCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    _mergeCtrl.dispose();
    _pulseCtrl.dispose();
    _targetCtrl.dispose();
    _refillCtrl.dispose();
    super.dispose();
  }

  // ---- round management ----

  void _advanceRound() {
    if (_currentRound >= _rounds.length - 1) {
      // final round — show flash then complete
      setState(() => _showRoundComplete = true);
      _flashCtrl.forward(from: 0);
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        widget.onComplete(true);
      });
      return;
    }
    // show round-complete overlay then advance
    setState(() => _showRoundComplete = true);
    _flashCtrl.forward(from: 0);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _showRoundComplete = false;
        _currentRound++;
        _lives = _maxLives; // refresh lives for new round
        _state = _RoundState(_rounds[_currentRound]);
      });
    });
  }

  void _loseLife() {
    setState(() {
      _lives--;
      _showLifeLost = true;
    });
    if (_lives <= 0) {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        widget.onComplete(false);
      });
    } else {
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _showLifeLost = false;
          _state.reset();
        });
      });
    }
  }

  // ---- action handling ----

  void _move(int dr, int dc) {
    if (_showRoundComplete || _showLifeLost) return;
    if (_state.actionsRemaining <= 0) return;

    final newR = _state.playerRow + dr;
    final newC = _state.playerCol + dc;

    if (newR < 0 || newR >= _gridSize || newC < 0 || newC >= _gridSize) return;

    final destCell = _state.grid[newR][newC];

    if (destCell == _wallValue) {
      // wall — can't move here
      return;
    } else if (destCell == 0) {
      // empty cell — just move
      _state.saveSnapshot();
      setState(() {
        _state.playerRow = newR;
        _state.playerCol = newC;
        _state.actionsRemaining--;
      });
      _postAction();
    } else if (destCell == _refillValue) {
      // refill pickup
      _state.saveSnapshot();
      setState(() {
        _state.grid[newR][newC] = 0;
        _state.playerRow = newR;
        _state.playerCol = newC;
        _state.actionsRemaining = _RoundState.maxActions;
      });
      // refill doesn't cost an action
    } else if (destCell >= 1 && destCell <= 5) {
      // colored block — try push
      _push(newR, newC, dr, dc);
    }
  }

  void _push(int blockR, int blockC, int dr, int dc) {
    final destR = blockR + dr;
    final destC = blockC + dc;

    if (destR < 0 || destR >= _gridSize || destC < 0 || destC >= _gridSize) {
      return;
    }

    final blockColor = _state.grid[blockR][blockC];
    final destCell = _state.grid[destR][destC];

    // can't push into a wall
    if (destCell == _wallValue) return;

    if (destCell == 0 || destCell == _refillValue) {
      // push into empty (or onto refill — block lands, refill consumed)
      final hitRefill = destCell == _refillValue;
      _state.saveSnapshot();
      setState(() {
        _state.grid[blockR][blockC] = 0;
        _state.grid[destR][destC] = blockColor;
        _state.playerRow = blockR;
        _state.playerCol = blockC;
        _state.actionsRemaining--;
        if (hitRefill) {
          _state.actionsRemaining = _RoundState.maxActions;
        }
      });
      _postAction();
    } else if (destCell == blockColor && blockColor < 5) {
      // same color — merge
      final newColor = blockColor + 1;
      _state.saveSnapshot();
      setState(() {
        _state.grid[blockR][blockC] = 0;
        _state.grid[destR][destC] = newColor;
        _state.playerRow = blockR;
        _state.playerCol = blockC;
        _state.actionsRemaining--;
        _merging = true;
        _mergeRow = destR;
        _mergeCol = destC;
      });
      _mergeCtrl.forward(from: 0);
      _postAction();
    }
    // different color or max color — push fails
  }

  void _postAction() {
    // check win
    final def = _rounds[_currentRound];
    if (_state.grid[def.targetRow][def.targetCol] == def.targetColor) {
      _advanceRound();
      return;
    }
    // check actions depleted → lose a life
    if (_state.actionsRemaining <= 0) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        _loseLife();
      });
    }
  }

  void _onUndo() {
    if (_showRoundComplete || _showLifeLost) return;
    if (_state.undo()) setState(() {});
  }

  void _onReset() {
    if (_showRoundComplete || _showLifeLost) return;
    _loseLife();
  }

  // ---- build ----

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                const SizedBox(height: 10),
                _buildTopBar(),
                const SizedBox(height: 10),
                Expanded(child: _buildGrid()),
                const SizedBox(height: 8),
                _buildActionBar(),
                const SizedBox(height: 12),
                _buildDPad(),
                const SizedBox(height: 12),
                _buildUtilityButtons(),
                const SizedBox(height: 16),
              ],
            ),
            if (_showRoundComplete) _buildRoundCompleteOverlay(),
            if (_showLifeLost) _buildLifeLostOverlay(),
          ],
        ),
      ),
    );
  }

  // ---- top bar (round dots + lives) ----

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // round dots
          Row(
            children: List.generate(3, (i) {
              final done = i < _currentRound;
              final active = i == _currentRound;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: active ? 32 : 10,
                  height: 10,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color: done
                        ? NunuColors.successMain
                        : active
                            ? NunuColors.primaryMain
                            : NunuColors.backgroundPaper,
                    border: Border.all(
                      color: done
                          ? NunuColors.successMain
                          : active
                              ? NunuColors.primaryMain
                              : NunuColors.primaryDark.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
          // lives
          Row(
            children: List.generate(_maxLives, (i) {
              final alive = i < _lives;
              return Padding(
                padding: const EdgeInsets.only(left: 4),
                child: AnimatedScale(
                  scale: alive ? 1.0 : 0.7,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    alive ? Icons.favorite : Icons.favorite_border,
                    size: 20,
                    color: alive
                        ? NunuColors.errorMain
                        : NunuColors.errorMain.withValues(alpha: 0.3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ---- round complete overlay ----

  Widget _buildRoundCompleteOverlay() {
    return AnimatedBuilder(
      animation: _flashCtrl,
      builder: (context, _) {
        return Container(
          color: NunuColors.backgroundDefault
              .withValues(alpha: 0.88 * _flashOpacity.value),
          child: Center(
            child: Transform.scale(
              scale: _flashScale.value,
              child: Opacity(
                opacity: _flashOpacity.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: NunuColors.successMain.withValues(alpha: 0.2),
                        border: Border.all(
                          color: NunuColors.successMain,
                          width: 3,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color:
                                NunuColors.successMain.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 40,
                        color: NunuColors.successMain,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _currentRound >= _rounds.length - 1
                          ? 'level complete'
                          : 'round ${_currentRound + 1} complete',
                      style: const TextStyle(
                        color: NunuColors.successMain,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- life lost overlay ----

  Widget _buildLifeLostOverlay() {
    return AnimatedOpacity(
      opacity: _showLifeLost ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        color: NunuColors.backgroundDefault.withValues(alpha: 0.85),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.heart_broken,
                size: 48,
                color: NunuColors.errorMain.withValues(alpha: 0.9),
              ),
              const SizedBox(height: 12),
              Text(
                _lives <= 0 ? 'no lives left' : 'life lost',
                style: const TextStyle(
                  color: NunuColors.errorMain,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              if (_lives > 0)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(_maxLives, (i) {
                    final alive = i < _lives;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Icon(
                        alive ? Icons.favorite : Icons.favorite_border,
                        size: 18,
                        color: alive
                            ? NunuColors.errorMain
                            : NunuColors.errorMain.withValues(alpha: 0.3),
                      ),
                    );
                  }),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- grid ----

  Widget _buildGrid() {
    final def = _rounds[_currentRound];

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final gridSide = side - 32;
        final cellSize = (gridSide / _gridSize).floorToDouble();
        final totalSide = cellSize * _gridSize;

        return Center(
          child: SizedBox(
            width: totalSide,
            height: totalSide,
            child: Stack(
              children: [
                for (int r = 0; r < _gridSize; r++)
                  for (int c = 0; c < _gridSize; c++)
                    Positioned(
                      left: c * cellSize,
                      top: r * cellSize,
                      width: cellSize,
                      height: cellSize,
                      child: _buildCell(r, c, cellSize, def),
                    ),
                // player cursor
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOut,
                  left: _state.playerCol * cellSize,
                  top: _state.playerRow * cellSize,
                  width: cellSize,
                  height: cellSize,
                  child: _buildPlayer(cellSize),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double cellSize, _RoundDef def) {
    final colorId = _state.grid[r][c];
    final isTarget = def.targetRow == r && def.targetCol == c;
    final isRefill = colorId == _refillValue;
    final isWall = colorId == _wallValue;

    // base empty color
    final cellColor = (isRefill || isWall)
        ? const Color(0xFF16122F)
        : (_arcColors[colorId] ?? const Color(0xFF16122F));

    final isMergeCell = _merging && _mergeRow == r && _mergeCol == c;

    return AnimatedBuilder(
      animation: isMergeCell ? _mergeScale : const AlwaysStoppedAnimation(1.0),
      builder: (context, child) {
        final scale = isMergeCell ? _mergeScale.value : 1.0;
        return Stack(
          children: [
            // target cell indicator (always visible, behind everything)
            if (isTarget)
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _targetAnim,
                  builder: (context, _) {
                    final tColor = _arcColors[def.targetColor] ?? Colors.white;
                    final a = _targetAnim.value;
                    return Stack(
                      children: [
                        // pulsing colored fill
                        Container(
                          margin: EdgeInsets.all(cellSize * 0.04),
                          decoration: BoxDecoration(
                            color: tColor.withValues(alpha: a * 0.9),
                            borderRadius:
                                BorderRadius.circular(cellSize * 0.15),
                            border: Border.all(
                              color: tColor.withValues(alpha: a + 0.35),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: tColor.withValues(alpha: a * 0.7),
                                blurRadius: 18,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        // corner brackets — top-left
                        Positioned(
                          left: 0,
                          top: 0,
                          child: _cornerBracket(cellSize, tColor, a, 0),
                        ),
                        // corner brackets — top-right
                        Positioned(
                          right: 0,
                          top: 0,
                          child: _cornerBracket(cellSize, tColor, a, 1),
                        ),
                        // corner brackets — bottom-right
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: _cornerBracket(cellSize, tColor, a, 2),
                        ),
                        // corner brackets — bottom-left
                        Positioned(
                          left: 0,
                          bottom: 0,
                          child: _cornerBracket(cellSize, tColor, a, 3),
                        ),
                        // crosshair icon
                        Center(
                          child: Icon(
                            Icons.gps_fixed,
                            size: cellSize * 0.45,
                            color: Colors.white.withValues(alpha: a + 0.4),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            // wall cell
            if (isWall)
              Center(
                child: Container(
                  width: cellSize - 4,
                  height: cellSize - 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2444),
                    borderRadius: BorderRadius.circular(cellSize * 0.15),
                    border: Border.all(
                      color: const Color(0xFF3D3558),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            // actual colored block
            if (!isRefill && !isWall)
              Center(
                child: Transform.scale(
                  scale: scale,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: cellSize - 4,
                    height: cellSize - 4,
                    decoration: BoxDecoration(
                      color: cellColor,
                      borderRadius: BorderRadius.circular(cellSize * 0.15),
                      border: Border.all(
                        color: colorId != 0
                            ? Colors.white.withValues(alpha: 0.15)
                            : NunuColors.primaryDark.withValues(alpha: 0.18),
                        width: 1,
                      ),
                      boxShadow: isMergeCell
                          ? [
                              BoxShadow(
                                color: cellColor.withValues(alpha: 0.7),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                  ),
                ),
              ),
            // refill dot
            if (isRefill) Positioned.fill(child: _buildRefillDot(cellSize)),
          ],
        );
      },
    );
  }

  Widget _buildRefillDot(double cellSize) {
    // Same background as an empty cell, with a yellow reload icon on top
    return AnimatedBuilder(
      animation: _refillAnim,
      builder: (context, _) {
        return Stack(
          children: [
            // empty cell background (identical to colorId == 0)
            Center(
              child: Container(
                width: cellSize - 4,
                height: cellSize - 4,
                decoration: BoxDecoration(
                  color: _arcColors[0],
                  borderRadius: BorderRadius.circular(cellSize * 0.15),
                  border: Border.all(
                    color: NunuColors.primaryDark.withValues(alpha: 0.18),
                    width: 1,
                  ),
                ),
              ),
            ),
            // yellow recharge icon
            Center(
              child: Icon(
                Icons.electric_bolt,
                size: cellSize * 0.38,
                color: NunuColors.warningMain.withValues(
                  alpha: _refillAnim.value,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Draws an L-shaped corner bracket. [corner]: 0=TL, 1=TR, 2=BR, 3=BL.
  Widget _cornerBracket(double cellSize, Color color, double alpha, int corner) {
    final len = cellSize * 0.28;
    final thick = 2.5;
    final c = color.withValues(alpha: alpha + 0.5);

    // Each bracket is two thin rectangles forming an L
    final hBar = Container(width: len, height: thick, color: c);
    final vBar = Container(width: thick, height: len, color: c);

    switch (corner) {
      case 0: // top-left
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [hBar, vBar],
        );
      case 1: // top-right
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [hBar, Align(alignment: Alignment.centerRight, child: vBar)],
        );
      case 2: // bottom-right
        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [Align(alignment: Alignment.centerRight, child: vBar), hBar],
        );
      case 3: // bottom-left
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [vBar, hBar],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildPlayer(double cellSize) {
    return AnimatedBuilder(
      animation: _pulseAnim,
      builder: (context, _) {
        return Center(
          child: Container(
            width: cellSize * 0.45,
            height: cellSize * 0.45,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: _pulseAnim.value),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: _pulseAnim.value * 0.5),
                  blurRadius: 10,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- action bar ----

  Widget _buildActionBar() {
    final fraction = _state.actionsRemaining / _RoundState.maxActions;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(
            height: 22,
            child: Stack(
              children: [
                // background track
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: NunuColors.warningDark.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),
                // filled portion
                FractionallySizedBox(
                  widthFactor: fraction.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      gradient: const LinearGradient(
                        colors: [
                          NunuColors.warningMain,
                          NunuColors.warningDark,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: NunuColors.warningMain.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ),
                // label
                Center(
                  child: Text(
                    '${_state.actionsRemaining} / ${_RoundState.maxActions}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---- d-pad ----

  Widget _buildDPad() {
    const double btnSize = 56;

    Widget dirBtn(IconData icon, int dr, int dc) {
      return SizedBox(
        width: btnSize,
        height: btnSize,
        child: Material(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _move(dr, dc),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        dirBtn(Icons.arrow_drop_up, -1, 0),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            dirBtn(Icons.arrow_left, 0, -1),
            const SizedBox(width: 4),
            SizedBox(
              width: btnSize,
              height: btnSize,
              child: Container(
                decoration: BoxDecoration(
                  color: NunuColors.backgroundPaper.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
            const SizedBox(width: 4),
            dirBtn(Icons.arrow_right, 0, 1),
          ],
        ),
        const SizedBox(height: 4),
        dirBtn(Icons.arrow_drop_down, 1, 0),
      ],
    );
  }

  // ---- utility buttons ----

  Widget _buildUtilityButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _onUndo,
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('undo'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: NunuColors.textSecondary,
                  width: 1,
                ),
                foregroundColor: NunuColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _onReset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('reset'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(
                  color: NunuColors.textSecondary,
                  width: 1,
                ),
                foregroundColor: NunuColors.textSecondary,
                padding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
