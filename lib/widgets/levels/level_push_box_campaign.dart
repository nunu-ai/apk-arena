import 'dart:async';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

/// Sokoban-style campaign: twelve hardcoded boards, gated progression,
/// internal budget starting at 15:00 with +4:00 after each solved board.
///
/// The back half introduces pressure plates and gates: a plate opens all
/// gates of its color while a crate (or the player) stands on it. Gates
/// never crush — anything standing on a gate cell can always move out.
///
/// Every board is solvability-verified by a BFS solver against these exact
/// movement rules; do not edit a board without re-verifying it.
class LevelPushBoxCampaign extends LevelWidget {
  const LevelPushBoxCampaign({super.key, required super.onComplete});

  @override
  State<LevelPushBoxCampaign> createState() => _LevelPushBoxCampaignState();
}

class _BoardSpec {
  final String name;
  final List<String> rows;

  const _BoardSpec({required this.name, required this.rows});
}

class _LevelPushBoxCampaignState extends State<LevelPushBoxCampaign> {
  static const int _stageCount = 12;
  static const Duration _initialBudget = Duration(minutes: 15);
  static const Duration _bonusPerStage = Duration(minutes: 4);

  static const Map<String, Color> _channelColors = {
    'p': Color(0xFF22D3EE), // cyan
    'q': Color(0xFFFF7043), // orange
    'r': Color(0xFFA3E635), // lime
  };

  /// Walls `#`, floor ` `, goals `.`, player `@`/`+`, crates `B`/`*`,
  /// plates `p`/`q`/`r`, gates `P`/`Q`/`R` (gate X open while plate x pressed).
  static const List<_BoardSpec> _boards = [
    _BoardSpec(
      name: 'warm-up',
      rows: [
        ' ######',
        '##    #',
        '#  BB@#',
        '#   ###',
        '#. .#  ',
        '#   #  ',
        '#####  ',
      ],
    ),
    _BoardSpec(
      name: 'maze push',
      rows: [
        '########',
        '#      #',
        '#      #',
        '# @# # #',
        '#  # B #',
        '# B# #.#',
        '#  #  .#',
        '########',
      ],
    ),
    _BoardSpec(
      name: 'two crates',
      rows: [
        '  #### ',
        '  #+ ##',
        '  #.  #',
        '### B #',
        '# B ###',
        '# # #  ',
        '#   #  ',
        '#####  ',
      ],
    ),
    _BoardSpec(
      name: 'corner case',
      rows: [
        '#####   ',
        '# B.### ',
        '#  .. # ',
        '#  ##B##',
        '##  #  #',
        ' #B    #',
        ' # @####',
        ' ####   ',
      ],
    ),
    _BoardSpec(
      name: 'hallway',
      rows: [
        '###### ',
        '#  B.# ',
        '#.BB # ',
        '# # .# ',
        '#   ## ',
        '#   #  ',
        '# @ #  ',
        '#   #  ',
        '#####  ',
      ],
    ),
    _BoardSpec(
      name: 'warehouse',
      rows: [
        ' #####  ',
        '##.  #  ',
        '#.  B## ',
        '#     ##',
        '#. #   #',
        '####BB #',
        '  #@  ##',
        '  ##### ',
      ],
    ),
    _BoardSpec(
      name: 'airlock',
      rows: [
        '#######',
        '# p   #',
        '# B B #',
        '#  @  #',
        '###P###',
        '  #.# ',
        '  ### ',
      ],
    ),
    _BoardSpec(
      name: 'toll booth',
      rows: [
        '#########',
        '#  p    #',
        '#  B ####',
        '# BB P..#',
        '#  @ ####',
        '#########',
      ],
    ),
    _BoardSpec(
      name: 'valve lanes',
      rows: [
        '##########',
        '#@       #',
        '# B  pP.##',
        '#    B   #',
        '#.Rr  B  #',
        '#    q   #',
        '#####Q####',
        '#####.####',
        '##########',
      ],
    ),
    _BoardSpec(
      name: 'chain reaction',
      rows: [
        '############',
        '#@   #  #  #',
        '# BB Q  #  #',
        '# B  #  P .#',
        '#  q # p#  #',
        '############',
      ],
    ),
    _BoardSpec(
      name: 'packing floor',
      rows: [
        '#########',
        '#   #   #',
        '# B B B #',
        '# B @   #',
        '####  ###',
        '###.. ###',
        '###.. ###',
        '#########',
      ],
    ),
    _BoardSpec(
      name: 'vault',
      rows: [
        '##########',
        '#....P   #',
        '#####P B #',
        '#  p #BB #',
        '# BB # B #',
        '# @  #   #',
        '#  ###Q###',
        '#      q #',
        '##########',
      ],
    ),
  ];

  late List<List<int>> _walls;
  late List<List<int>> _goals;
  late List<List<int>> _boxes;
  late List<List<int>> _floor;
  late List<List<String>> _plates;
  late List<List<String>> _gates;
  late int _playerR;
  late int _playerC;
  late int _rows;
  late int _cols;

  int _stageIndex = 0;
  int _stagesCleared = 0;
  int _secondsRemaining = _initialBudget.inSeconds;
  Timer? _budgetTimer;

  int _totalMoves = 0;
  int _totalPushes = 0;
  bool _runFinished = false;
  final List<_Snapshot> _history = [];

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(_buildTimeoutOutcome);
    _loadStage(_stageIndex);
    _startBudgetTimer();
  }

  @override
  void dispose() {
    _budgetTimer?.cancel();
    widget.clearPartialScoreGetter();
    super.dispose();
  }

  LevelOutcome _buildTimeoutOutcome() {
    final score = _stagesCleared / _stageCount;
    return LevelOutcome(
      score: score,
      metrics: {
        'stages_cleared': _stagesCleared,
        'moves': _totalMoves,
        'pushes': _totalPushes,
      },
    );
  }

  String _formatTime(int seconds) {
    final safe = seconds.clamp(0, 99999);
    final m = (safe ~/ 60).toString().padLeft(2, '0');
    final s = (safe % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startBudgetTimer() {
    _budgetTimer?.cancel();
    _budgetTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _runFinished) return;
      setState(() {
        if (_secondsRemaining <= 0) return;
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _failRun(timedOut: true);
        }
      });
    });
  }

  void _loadStage(int index) {
    final spec = _boards[index];
    _rows = spec.rows.length;
    _cols = spec.rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    _walls = List.generate(_rows, (_) => List.filled(_cols, 0));
    _goals = List.generate(_rows, (_) => List.filled(_cols, 0));
    _boxes = List.generate(_rows, (_) => List.filled(_cols, 0));
    _floor = List.generate(_rows, (_) => List.filled(_cols, 0));
    _plates = List.generate(_rows, (_) => List.filled(_cols, ''));
    _gates = List.generate(_rows, (_) => List.filled(_cols, ''));

    for (int r = 0; r < _rows; r++) {
      final line = spec.rows[r];
      for (int c = 0; c < _cols; c++) {
        final ch = c < line.length ? line[c] : ' ';
        switch (ch) {
          case '#':
            _walls[r][c] = 1;
            break;
          case '.':
            _goals[r][c] = 1;
            break;
          case '@':
            _playerR = r;
            _playerC = c;
            break;
          case '+':
            _playerR = r;
            _playerC = c;
            _goals[r][c] = 1;
            break;
          case 'B':
          case r'$':
            _boxes[r][c] = 1;
            break;
          case '*':
            _boxes[r][c] = 1;
            _goals[r][c] = 1;
            break;
          case 'p':
          case 'q':
          case 'r':
            _plates[r][c] = ch;
            break;
          case 'P':
          case 'Q':
          case 'R':
            _gates[r][c] = ch.toLowerCase();
            break;
          default:
            break;
        }
      }
    }

    _history.clear();

    // Mark floor cells reachable from the player (ignoring crates and gate
    // state), so out-of-room voids in irregular boards render as background.
    final queue = <List<int>>[
      [_playerR, _playerC],
    ];
    _floor[_playerR][_playerC] = 1;
    while (queue.isNotEmpty) {
      final cell = queue.removeLast();
      const deltas = [
        [-1, 0],
        [1, 0],
        [0, -1],
        [0, 1],
      ];
      for (final d in deltas) {
        final nr = cell[0] + d[0];
        final nc = cell[1] + d[1];
        if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
        if (_walls[nr][nc] == 1) continue;
        if (_floor[nr][nc] == 1) continue;
        _floor[nr][nc] = 1;
        queue.add([nr, nc]);
      }
    }
  }

  Set<String> _pressedChannels() {
    final pressed = <String>{};
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_plates[r][c].isEmpty) continue;
        if (_boxes[r][c] == 1 || (_playerR == r && _playerC == c)) {
          pressed.add(_plates[r][c]);
        }
      }
    }
    return pressed;
  }

  bool _allGoalsFilled() {
    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        if (_goals[r][c] == 1 && _boxes[r][c] != 1) return false;
      }
    }
    return true;
  }

  void _onStageCleared() {
    _stagesCleared++;
    HapticFeedback.mediumImpact();

    if (_stageIndex >= _stageCount - 1) {
      _completeCampaign();
      return;
    }

    _secondsRemaining += _bonusPerStage.inSeconds;
    _stageIndex++;
    _loadStage(_stageIndex);
  }

  void _resetCurrentStage() {
    if (_runFinished) return;
    HapticFeedback.selectionClick();
    setState(() => _loadStage(_stageIndex));
  }

  void _completeCampaign() {
    if (_runFinished) return;
    _runFinished = true;
    _budgetTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      widget.onComplete(
        LevelOutcome(
          score: 1,
          metrics: {
            'stages': _stageCount,
            'moves': _totalMoves,
            'pushes': _totalPushes,
            'seconds_left': _secondsRemaining,
          },
        ),
      );
    });
  }

  void _failRun({required bool timedOut}) {
    if (_runFinished) return;
    _runFinished = true;
    _budgetTimer?.cancel();
    final score = _stagesCleared / _stageCount;
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.onComplete(
        LevelOutcome(
          score: score,
          metrics: {
            'stages_cleared': _stagesCleared,
            'timed_out': timedOut,
            'moves': _totalMoves,
            'pushes': _totalPushes,
          },
        ),
      );
    });
  }

  void _move(int dr, int dc) {
    if (_runFinished) return;
    final nr = _playerR + dr;
    final nc = _playerC + dc;
    if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) return;
    if (_walls[nr][nc] == 1) return;

    // Gate state is evaluated before the move: entering a gate cell requires
    // it to be open now. Anything already on a gate cell can always move out.
    final pressed = _pressedChannels();
    bool gateClosed(int r, int c) =>
        _gates[r][c].isNotEmpty && !pressed.contains(_gates[r][c]);

    setState(() {
      if (_boxes[nr][nc] == 1) {
        final br = nr + dr;
        final bc = nc + dc;
        if (br < 0 || br >= _rows || bc < 0 || bc >= _cols) return;
        if (_walls[br][bc] == 1 || _boxes[br][bc] == 1) return;
        if (gateClosed(br, bc)) return;

        _history.add(
          _Snapshot(
            _playerR,
            _playerC,
            List.generate(_rows, (r) => List<int>.from(_boxes[r])),
          ),
        );
        _boxes[nr][nc] = 0;
        _boxes[br][bc] = 1;
        _playerR = nr;
        _playerC = nc;
        _totalMoves++;
        _totalPushes++;
        HapticFeedback.lightImpact();
      } else {
        if (gateClosed(nr, nc)) return;

        _history.add(
          _Snapshot(
            _playerR,
            _playerC,
            List.generate(_rows, (r) => List<int>.from(_boxes[r])),
          ),
        );
        _playerR = nr;
        _playerC = nc;
        _totalMoves++;
        HapticFeedback.selectionClick();
      }

      if (_allGoalsFilled()) {
        _onStageCleared();
      }
    });
  }

  void _undo() {
    if (_runFinished || _history.isEmpty) return;
    setState(() {
      final prev = _history.removeLast();
      _playerR = prev.playerR;
      _playerC = prev.playerC;
      _boxes = prev.boxes;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(
              timerText: _formatTime(_secondsRemaining),
              stageText: '${_stageIndex + 1}/$_stageCount',
              infoTitle: 'push-box gauntlet',
              infoItems: const [
                LevelHudBullet('📦', 'push every crate onto a glowing goal tile to clear the stage'),
                LevelHudBullet('🔘', 'later stages: a pressure plate opens all gates of its color while a crate or you stand on it'),
                LevelHudBullet('↩️', 'undo reverts your last move, reset restarts the current board'),
                LevelHudBullet('⏱', 'you start with 15:00 and earn +4:00 for each stage cleared'),
              ],
            ),
            Expanded(child: Center(child: _buildGrid())),
            const SizedBox(height: 4),
            _buildControls(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dim = _rows > _cols ? _rows : _cols;
        final cellSize =
            ((constraints.maxWidth - 8).clamp(0.0, constraints.maxHeight)) /
            dim;

        return SizedBox(
          width: cellSize * _cols,
          height: cellSize * _rows,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _cols,
            ),
            itemCount: _rows * _cols,
            itemBuilder: (_, i) {
              final r = i ~/ _cols;
              final c = i % _cols;
              return _buildCell(r, c, cellSize);
            },
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final isWall = _walls[r][c] == 1;
    final isGoal = _goals[r][c] == 1;
    final isBox = _boxes[r][c] == 1;
    final isPlayer = _playerR == r && _playerC == c;
    final isBoxOnGoal = isBox && isGoal;
    final isVoid = !isWall && _floor[r][c] == 0;
    final plate = _plates[r][c];
    final gate = _gates[r][c];
    final pressed = _pressedChannels();

    if (isVoid) {
      return const SizedBox.shrink();
    }

    Color bg;
    if (isWall) {
      bg = NunuColors.secondaryDark;
    } else if (isGoal) {
      bg = NunuColors.primaryMain.withValues(alpha: 0.18);
    } else {
      bg = NunuColors.backgroundPaper.withValues(alpha: 0.72);
    }

    Widget? marker;
    if (isWall) {
      marker = Container(
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: NunuColors.secondaryDark,
          borderRadius: BorderRadius.circular(3),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryDark.withValues(alpha: 0.28),
              offset: const Offset(1, 2),
              blurRadius: 2,
            ),
          ],
        ),
      );
    } else if (plate.isNotEmpty) {
      final color = _channelColors[plate]!;
      final isPressed = pressed.contains(plate);
      marker = Container(
        margin: EdgeInsets.all(size * 0.16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isPressed ? 0.55 : 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.9), width: 2),
        ),
        child: Center(
          child: Icon(
            Icons.radio_button_checked,
            color: color.withValues(alpha: isPressed ? 1.0 : 0.55),
            size: size * 0.3,
          ),
        ),
      );
    } else if (gate.isNotEmpty) {
      final color = _channelColors[gate]!;
      final isOpen = pressed.contains(gate);
      marker = Container(
        margin: EdgeInsets.all(size * 0.06),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isOpen ? 0.08 : 0.30),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: color.withValues(alpha: isOpen ? 0.45 : 0.95),
            width: 2,
          ),
        ),
        child: Center(
          child: Icon(
            isOpen ? Icons.lock_open : Icons.lock,
            color: color.withValues(alpha: isOpen ? 0.5 : 1.0),
            size: size * 0.34,
          ),
        ),
      );
    } else if (isGoal && !isBox && !isPlayer) {
      marker = Center(
        child: Container(
          width: size * 0.38,
          height: size * 0.38,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: NunuColors.primaryDark.withValues(alpha: 0.35),
            border: Border.all(
              color: NunuColors.primaryLight.withValues(alpha: 0.85),
              width: 2,
            ),
          ),
        ),
      );
    }

    Widget? entity;
    if (isPlayer) {
      entity = Container(
        width: size * 0.62,
        height: size * 0.62,
        decoration: BoxDecoration(
          color: NunuColors.primaryMain,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withValues(alpha: 0.45),
              blurRadius: 6,
            ),
          ],
        ),
        child: Icon(Icons.person, color: Colors.white, size: size * 0.28),
      );
    } else if (isBox) {
      entity = Container(
        width: size * 0.72,
        height: size * 0.72,
        decoration: BoxDecoration(
          color: isBoxOnGoal ? NunuColors.successMain : NunuColors.warningMain,
          borderRadius: BorderRadius.circular(5),
          boxShadow: [
            BoxShadow(
              color:
                  (isBoxOnGoal
                          ? NunuColors.successMain
                          : NunuColors.warningMain)
                      .withValues(alpha: 0.35),
              blurRadius: 5,
            ),
          ],
        ),
        child: Icon(
          isBoxOnGoal ? Icons.check : Icons.inventory_2,
          color: Colors.white,
          size: size * 0.3,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: isWall
            ? null
            : Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 0.5,
              ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (marker != null) Positioned.fill(child: marker),
          if (entity != null) entity,
        ],
      ),
    );
  }

  Widget _buildControls() {
    const buttonSize = 56.0;
    const buttonGap = 6.0;
    const dpadWidth = buttonSize * 3 + buttonGap * 2;
    const dpadHeight = buttonSize * 3 + buttonGap * 2;

    Widget btn(IconData icon, int dr, int dc) {
      return GestureDetector(
        onTap: () => _move(dr, dc),
        child: Container(
          width: buttonSize,
          height: buttonSize,
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NunuColors.primaryDark.withValues(alpha: 0.45),
            ),
          ),
          child: Icon(icon, color: NunuColors.primaryMain, size: 26),
        ),
      );
    }

    final dpad = SizedBox(
      width: dpadWidth,
      height: dpadHeight,
      child: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: btn(Icons.arrow_upward, -1, 0),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: btn(Icons.arrow_back, 0, -1),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: btn(Icons.arrow_forward, 0, 1),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: btn(Icons.arrow_downward, 1, 0),
          ),
        ],
      ),
    );

    final resetButton = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _resetCurrentStage,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NunuColors.secondaryDark.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(
              Icons.refresh_rounded,
              color: NunuColors.secondaryLight,
              size: 26,
            ),
          ),
        ),
      ),
    );

    final undoButton = SizedBox(
      width: buttonSize,
      height: buttonSize,
      child: Material(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: _undo,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: NunuColors.secondaryDark.withValues(alpha: 0.55),
              ),
            ),
            child: Icon(
              Icons.undo_rounded,
              color: NunuColors.secondaryLight,
              size: 26,
            ),
          ),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: dpadHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.center, child: dpad),
            Align(alignment: Alignment.centerLeft, child: resetButton),
            Align(alignment: Alignment.centerRight, child: undoButton),
          ],
        ),
      ),
    );
  }
}

class _Snapshot {
  final int playerR;
  final int playerC;
  final List<List<int>> boxes;

  _Snapshot(this.playerR, this.playerC, this.boxes);
}
