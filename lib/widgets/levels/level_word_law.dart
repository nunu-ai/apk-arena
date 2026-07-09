import 'dart:async';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

/// Rule-rewriting puzzle campaign: the rules of the game are word tiles on
/// the board ("WALL IS STOP"), and word tiles are pushable — break laws and
/// write new ones to reach a win condition.
///
/// Semantics (must match wordlaw_gen.py EXACTLY):
/// - Rules are horizontal/vertical triples NOUN-IS-PROPERTY.
/// - Text is always pushable; objects are pushable iff PUSH; an entity
///   blocks iff STOP and not pushable. Push chains move whole cell-stacks,
///   blocked by edge or STOP anywhere down the chain.
/// - On input all YOU entities move, leaders-first; properties derived once
///   before the input. After moves: cells containing a SINK object plus
///   anything else destroy all their entities, then win if some cell holds
///   a YOU entity and a WIN entity.
///
/// Every board is verified via wordlaw_fast.py: solvable (by capped BFS or
/// by replaying an explicit solution for the deep boards), and unsolvable
/// when word tiles are frozen — i.e. rewriting the rules is provably
/// required. Do not edit a board without re-verifying.
///
/// Engine gotchas that shaped the boards: a rule written along a board edge
/// can never be broken (push chains jam against the edge); entities can
/// never walk onto a word tile (text always pushes or blocks); SINK objects
/// destroy everything in their cell, including words pushed into them.
class LevelWordLaw extends LevelWidget {
  const LevelWordLaw({super.key, required super.onComplete});

  @override
  State<LevelWordLaw> createState() => _LevelWordLawState();
}

class _Ent {
  final String type;
  int r;
  int c;

  _Ent(this.type, this.r, this.c);

  bool get isText => type.startsWith('t_');

  _Ent copy() => _Ent(type, r, c);
}

class _LevelWordLawState extends State<LevelWordLaw> {
  static const int _stageCount = 10;
  static const Duration _initialBudget = Duration(minutes: 15);
  static const Duration _bonusPerStage = Duration(minutes: 4);

  /// Legend: '.' empty, '#' wall, b bot, r rock, f flag, w water;
  /// B/W/R/F/A = text BOT/WALL/ROCK/FLAG/WATER, I = IS,
  /// Y/N/S/P/K = text YOU/WIN/STOP/PUSH/SINK.
  /// Verified by wordlaw_fast.py — do not hand-edit.
  static const List<List<String>> _boards = [
    // jailbreak: break WALL IS STOP from inside the cell
    // (BFS optimal 8, frozen-text unsolvable)
    [
      '#########',
      '#b......#',
      '#..WIS..#',
      '#.......#',
      '#########',
      '.........',
      '....f....',
      'BIY...FIN',
    ],
    // legislation: write FLAG IS WIN from scattered tiles
    // (BFS optimal 35, frozen-text unsolvable)
    [
      'WISBIY....',
      '..........',
      '..F.#.N...',
      '....#.....',
      '.I..#.....',
      '....#..###',
      '.b..#..#f#',
      '..........',
    ],
    // toll: sacrifice a word into the sink-moat to carve a crossing,
    // then legislate on the far side (28-move solution replay-verified,
    // frozen-text unsolvable)
    [
      'AIKBIY....',
      '.....w....',
      '.RI..w.I..',
      '.b.r.w..f.',
      '..P..w....',
      '.F...w..N.',
      '.....w....',
      'wwwwwwwwww',
    ],
    // identity theft: steal the Y from BOT IS YOU to form ROCK IS YOU —
    // one push transfers control to the rock in the sealed maze
    // (BFS solution 10, frozen-text unsolvable)
    [
      'WISFIN....',
      '.....#####',
      '.....#r#.#',
      '....R#.#.#',
      '....I#.#f#',
      '.....#...#',
      '..BIY#####',
      '.b........',
    ],
    // the doorman: a water droplet plugs the vault's only door (touching
    // it is death, no push lane reaches it). form WATER IS YOU, walk the
    // guard off his post while the bot mirrors every move, let the droplet
    // break its own rule, then enter and complete FLAG IS WIN
    // (42-move solution replay-verified, frozen-text unsolvable)
    [
      'WISAIKBIY.',
      '.....#####',
      '.AI..#...#',
      '.....#F.N#',
      '...Y.#.I.#',
      '.....#...#',
      '.....##w##',
      'b........f',
    ],
    // china shop: ROCK IS YOU is active from the start — one controller,
    // two conflicting mazes. the rock's lower lane is flooded except one
    // column (forcing a turn), the bot's pocket is water-rimmed, and the
    // safe joint sequence needs sacrificial sync moves: the bot pushes
    // FLAG IS WIN together while the rock is jammed against the top wall,
    // then retreats through a cell it just left because the rock's forced
    // left-turn drags it along. straight "natural" play drowns a unit
    // (9-move interleaved solution replay-verified, naive line verified
    // to fail, frozen-text unsolvable)
    [
      'WISBIYRIY.',
      '#r.##.....',
      '#..##....F',
      '#.w##....I',
      '#.w##.....',
      '#.w##...wN',
      '#fw##..b..',
      'AIK##...#w',
    ],
    // amendment: BOT IS YOU and WALL IS STOP share one IS at a crossing —
    // most pushes near it are suicide. extract the S perpendicular and
    // slide the N into its slot to amend WALL IS STOP into WALL IS WIN,
    // then touch a wall (26-move solution replay-verified, frozen-text
    // unsolvable)
    [
      'AIK.......',
      '....B.....',
      '...WIS....',
      '....Y.....',
      '..........',
      '......#..#',
      '.b....#N.#',
      '..........',
    ],
    // the coup: steal the Y to transfer control to the rock, then — as
    // the rock — reuse the corpse of BOT IS YOU (its B and I tiles) to
    // legislate BOT IS WIN, and walk over to tap the abandoned king
    // (14-move solution replay-verified, frozen-text unsolvable)
    [
      'AIK.......',
      '..........',
      '..BR......',
      '..II......',
      '..Y.......',
      '...w..w...',
      '....N...r.',
      '.b..w.....',
    ],
    // the budget: one sacrifice must be sunk to carve the moat, and the
    // precious-looking F tile is the expendable one — FLAG IS WIN is a
    // trap because the flag itself is water-moated and untouchable. win
    // via ROCK IS WIN on the humble rock (27-move solution
    // replay-verified, frozen-text unsolvable)
    [
      'WISBIYAIK.',
      '..........',
      '...F.w.IN.',
      '..........',
      '..R..w.www',
      '..r..w.wfw',
      '.....w.www',
      '.b...w....',
    ],
    // the demon: two theaters sealed off forever, connected only by the
    // law. steal the Y (bot -> rock), extract the same Y out of ROCK IS
    // YOU to complete WATER IS YOU in one push (rock -> droplet, across
    // the wall), unseal the vault the droplet was guarding, ferry P into
    // WALL IS PUSH, then animate the rock locked INSIDE the chamber and
    // shove the wall off the displaced flag. one Y serves three rules; K
    // and P decoys in the west theater lead nowhere (shortcut-checked:
    // the chamber rock no longer wins by walking straight up)
    [
      'WISFINAIKF..',
      '.K...##w#...',
      '.r...##P#...',
      '.P...##Y#...',
      '.....##.....',
      '...R.#...#f#',
      '...I.#...#.#',
      'AI...#...###',
      '.BIY.#RI.#r#',
      '.b...#WI.###',
    ],
  ];

  static const Map<String, String> _nounText = {
    'B': 'bot',
    'W': 'wall',
    'R': 'rock',
    'F': 'flag',
    'A': 'water',
  };
  static const Map<String, String> _propText = {
    'Y': 'you',
    'N': 'win',
    'S': 'stop',
    'P': 'push',
    'K': 'sink',
  };
  static const Map<String, String> _objChars = {
    'b': 'bot',
    '#': 'wall',
    'r': 'rock',
    'f': 'flag',
    'w': 'water',
  };

  late List<_Ent> _ents;
  late int _rows;
  late int _cols;
  int _stageIndex = 0;
  int _stagesCleared = 0;
  int _stageMoves = 0;
  int _totalMoves = 0;
  int _secondsRemaining = _initialBudget.inSeconds;
  Timer? _budgetTimer;
  bool _runFinished = false;
  bool _stageWonPause = false;
  final List<List<_Ent>> _history = [];

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(_buildPartialOutcome);
    _loadStage(_stageIndex);
    _startBudgetTimer();
  }

  @override
  void dispose() {
    _budgetTimer?.cancel();
    widget.clearPartialScoreGetter();
    super.dispose();
  }

  LevelOutcome _buildPartialOutcome() {
    return LevelOutcome(
      score: _stagesCleared / _stageCount,
      metrics: {'stages_cleared': _stagesCleared, 'moves': _totalMoves},
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
          _failRun();
        }
      });
    });
  }

  void _loadStage(int index) {
    final rows = _boards[index];
    _rows = rows.length;
    _cols = rows.map((r) => r.length).reduce((a, b) => a > b ? a : b);
    _ents = [];
    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < rows[r].length; c++) {
        final ch = rows[r][c];
        if (ch == '.') continue;
        if (_objChars.containsKey(ch)) {
          _ents.add(_Ent(_objChars[ch]!, r, c));
        } else if (_nounText.containsKey(ch)) {
          _ents.add(_Ent('t_${_nounText[ch]}', r, c));
        } else if (_propText.containsKey(ch)) {
          _ents.add(_Ent('t_${_propText[ch]}', r, c));
        } else if (ch == 'I') {
          _ents.add(_Ent('t_is', r, c));
        }
      }
    }
    _stageMoves = 0;
    _stageWonPause = false;
    _history.clear();
  }

  // ---- engine (mirror of wordlaw_gen.py) ----

  Map<String, Set<String>> _deriveProps(List<_Ent> ents) {
    const nouns = {
      't_bot': 'bot',
      't_wall': 'wall',
      't_rock': 'rock',
      't_flag': 'flag',
      't_water': 'water',
    };
    const properties = {
      't_you': 'you',
      't_win': 'win',
      't_stop': 'stop',
      't_push': 'push',
      't_sink': 'sink',
    };
    List<String> textsAt(int r, int c) => [
      for (final e in ents)
        if (e.isText && e.r == r && e.c == c) e.type,
    ];
    final props = <String, Set<String>>{};
    for (final e in ents) {
      final noun = nouns[e.type];
      if (noun == null) continue;
      for (final d in const [
        [0, 1],
        [1, 0],
      ]) {
        final mid = textsAt(e.r + d[0], e.c + d[1]);
        final end = textsAt(e.r + 2 * d[0], e.c + 2 * d[1]);
        if (!mid.contains('t_is')) continue;
        for (final t in end) {
          final p = properties[t];
          if (p != null) props.putIfAbsent(noun, () => {}).add(p);
        }
      }
    }
    return props;
  }

  bool _isPushable(String type, Map<String, Set<String>> props) {
    if (type.startsWith('t_')) return true;
    return props[type]?.contains('push') ?? false;
  }

  bool _isStop(String type, Map<String, Set<String>> props) {
    if (type.startsWith('t_')) return false;
    return props[type]?.contains('stop') ?? false;
  }

  List<_Ent> _at(int r, int c) =>
      [for (final e in _ents) if (e.r == r && e.c == c) e];

  bool _canMove(int r, int c, int dr, int dc, Map<String, Set<String>> props) {
    final nr = r + dr;
    final nc = c + dc;
    if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) return false;
    var pushers = false;
    for (final e in _at(nr, nc)) {
      if (_isPushable(e.type, props)) {
        pushers = true;
      } else if (_isStop(e.type, props)) {
        return false;
      }
    }
    if (pushers) return _canMove(nr, nc, dr, dc, props);
    return true;
  }

  void _moveStack(int r, int c, int dr, int dc, Map<String, Set<String>> props) {
    final nr = r + dr;
    final nc = c + dc;
    if (_at(nr, nc).any((e) => _isPushable(e.type, props))) {
      _moveStack(nr, nc, dr, dc, props);
    }
    for (final e in _at(r, c)) {
      if (_isPushable(e.type, props)) {
        e.r = nr;
        e.c = nc;
      }
    }
  }

  /// Applies one input; returns true if anything moved.
  bool _step(int dr, int dc) {
    final props = _deriveProps(_ents);
    final yous = [
      for (final e in _ents)
        if (!e.isText && (props[e.type]?.contains('you') ?? false)) e,
    ];
    if (dr == -1) {
      yous.sort((a, b) => a.r.compareTo(b.r));
    } else if (dr == 1) {
      yous.sort((a, b) => b.r.compareTo(a.r));
    } else if (dc == -1) {
      yous.sort((a, b) => a.c.compareTo(b.c));
    } else {
      yous.sort((a, b) => b.c.compareTo(a.c));
    }

    var movedAny = false;
    for (final you in yous) {
      if (!_canMove(you.r, you.c, dr, dc, props)) continue;
      final nr = you.r + dr;
      final nc = you.c + dc;
      if (_at(nr, nc).any((e) => _isPushable(e.type, props))) {
        _moveStack(nr, nc, dr, dc, props);
      }
      you.r = nr;
      you.c = nc;
      movedAny = true;
    }
    if (!movedAny) return false;

    // sink
    final props2 = _deriveProps(_ents);
    final byCell = <int, List<_Ent>>{};
    for (final e in _ents) {
      byCell.putIfAbsent(e.r * _cols + e.c, () => []).add(e);
    }
    final dead = <_Ent>{};
    for (final cell in byCell.values) {
      if (cell.length < 2) continue;
      final hasSink = cell.any(
        (e) => !e.isText && (props2[e.type]?.contains('sink') ?? false),
      );
      if (hasSink) dead.addAll(cell);
    }
    if (dead.isNotEmpty) {
      _ents.removeWhere(dead.contains);
    }
    return true;
  }

  bool get _won {
    final props = _deriveProps(_ents);
    final byCell = <int, Set<String>>{};
    for (final e in _ents) {
      final set = byCell.putIfAbsent(e.r * _cols + e.c, () => {});
      if (!e.isText) set.addAll(props[e.type] ?? const {});
    }
    return byCell.values.any((ps) => ps.contains('you') && ps.contains('win'));
  }

  // ---- interaction ----

  void _onInput(int dr, int dc) {
    if (_runFinished || _stageWonPause) return;
    final snapshot = [for (final e in _ents) e.copy()];
    setState(() {
      if (!_step(dr, dc)) return;
      _history.add(snapshot);
      _stageMoves++;
      _totalMoves++;
      HapticFeedback.selectionClick();
      if (_won) {
        _onStageWon();
      }
    });
  }

  void _onStageWon() {
    _stagesCleared++;
    _stageWonPause = true;
    HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted || _runFinished) return;
      if (_stageIndex >= _stageCount - 1) {
        _finishRun();
        return;
      }
      setState(() {
        _secondsRemaining += _bonusPerStage.inSeconds;
        _stageIndex++;
        _loadStage(_stageIndex);
      });
    });
  }

  void _undo() {
    if (_runFinished || _stageWonPause || _history.isEmpty) return;
    setState(() {
      _ents = _history.removeLast();
      _stageMoves--;
      _totalMoves--;
    });
  }

  void _resetCurrentStage() {
    if (_runFinished || _stageWonPause) return;
    HapticFeedback.selectionClick();
    setState(() => _loadStage(_stageIndex));
  }

  void _finishRun() {
    if (_runFinished) return;
    _runFinished = true;
    _budgetTimer?.cancel();
    widget.onComplete(
      LevelOutcome(
        score: _stagesCleared / _stageCount,
        metrics: {
          'stages_cleared': _stagesCleared,
          'moves': _totalMoves,
          'seconds_left': _secondsRemaining,
        },
      ),
    );
  }

  void _failRun() {
    if (_runFinished) return;
    _runFinished = true;
    _budgetTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      widget.onComplete(
        LevelOutcome(
          score: _stagesCleared / _stageCount,
          metrics: {
            'stages_cleared': _stagesCleared,
            'timed_out': true,
            'moves': _totalMoves,
          },
        ),
      );
    });
  }

  // ---- rendering ----

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
              infoTitle: 'syntax error',
              infoItems: const [
                LevelHudBullet('📜', 'the word tiles on the board ARE the rules: noun IS property, read left-to-right or top-to-bottom'),
                LevelHudBullet('🧱', 'word tiles can be pushed. break a law by splitting its words — or write a new law by lining words up'),
                LevelHudBullet('🕹', 'arrows move everything that is YOU. you win when something YOU touches something WIN'),
                LevelHudBullet('↩️', 'stuck, dissolved, or lost control of everything? undo and reset are free'),
                LevelHudBullet('⏱', 'you start with 15:00 and earn +4:00 for each stage cleared'),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'moves: $_stageMoves',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: Center(child: _buildBoard())),
            const SizedBox(height: 4),
            _buildControls(),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - 16) / _cols;
        final cellH = constraints.maxHeight / _rows;
        final cell = cellW < cellH ? cellW : cellH;
        final w = cell * _cols;
        final h = cell * _rows;

        // stable draw order: flat objects, then rock/bot, then text on top
        int layer(_Ent e) {
          if (e.isText) return 3;
          if (e.type == 'bot') return 2;
          if (e.type == 'rock') return 1;
          return 0;
        }
        final drawEnts = [..._ents]..sort((a, b) => layer(a) - layer(b));

        return Container(
          width: w,
          height: h,
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper.withValues(alpha: 0.72),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Stack(
            children: [
              CustomPaint(size: Size(w, h), painter: _GridPainter(_rows, _cols)),
              for (final e in drawEnts)
                AnimatedPositioned(
                  key: ObjectKey(e),
                  duration: const Duration(milliseconds: 120),
                  curve: Curves.easeOutCubic,
                  left: e.c * cell,
                  top: e.r * cell,
                  width: cell,
                  height: cell,
                  child: _entityWidget(e, cell),
                ),
              if (_stageWonPause)
                Positioned.fill(
                  child: Container(
                    color: NunuColors.successMain.withValues(alpha: 0.12),
                    child: const Center(
                      child: Text(
                        'WIN',
                        style: TextStyle(
                          color: NunuColors.successMain,
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static const Map<String, String> _objEmoji = {
    'bot': '🤖',
    'wall': '🧱',
    'rock': '🪨',
    'flag': '🚩',
    'water': '🌊',
  };
  static const Map<String, String> _textLabel = {
    't_bot': 'BOT',
    't_wall': 'WALL',
    't_rock': 'ROCK',
    't_flag': 'FLAG',
    't_water': 'WATER',
    't_is': 'IS',
    't_you': 'YOU',
    't_win': 'WIN',
    't_stop': 'STOP',
    't_push': 'PUSH',
    't_sink': 'SINK',
  };

  Widget _entityWidget(_Ent e, double cell) {
    if (!e.isText) {
      return Center(
        child: Text(
          _objEmoji[e.type]!,
          style: TextStyle(fontSize: cell * 0.62, height: 1),
        ),
      );
    }
    final isIs = e.type == 't_is';
    final isNoun = const {
      't_bot', 't_wall', 't_rock', 't_flag', 't_water',
    }.contains(e.type);
    final color = isIs
        ? Colors.white70
        : isNoun
            ? NunuColors.primaryLight
            : NunuColors.warningMain;
    return Padding(
      padding: EdgeInsets.all(cell * 0.06),
      child: Container(
        decoration: BoxDecoration(
          color: NunuColors.backgroundDefault.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(cell * 0.12),
          border: Border.all(color: color.withValues(alpha: 0.85), width: 1.5),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                _textLabel[e.type]!,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: cell * 0.3,
                  height: 1,
                ),
              ),
            ),
          ),
        ),
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
        onTap: () => _onInput(dr, dc),
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

    Widget sideButton(IconData icon, VoidCallback onTap) {
      return SizedBox(
        width: buttonSize,
        height: buttonSize,
        child: Material(
          color: NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onTap,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: NunuColors.secondaryDark.withValues(alpha: 0.55),
                ),
              ),
              child: Icon(icon, color: NunuColors.secondaryLight, size: 26),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: dpadHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(alignment: Alignment.center, child: dpad),
            Align(
              alignment: Alignment.centerLeft,
              child: sideButton(Icons.refresh_rounded, _resetCurrentStage),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: sideButton(Icons.undo_rounded, _undo),
            ),
          ],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  final int rows;
  final int cols;

  _GridPainter(this.rows, this.cols);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    final cellW = size.width / cols;
    final cellH = size.height / rows;
    for (var i = 1; i < cols; i++) {
      canvas.drawLine(
        Offset(i * cellW, 0),
        Offset(i * cellW, size.height),
        paint,
      );
    }
    for (var i = 1; i < rows; i++) {
      canvas.drawLine(
        Offset(0, i * cellH),
        Offset(size.width, i * cellH),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) =>
      old.rows != rows || old.cols != cols;
}
