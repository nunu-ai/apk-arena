import 'dart:async';
import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// chain reaction — 30-minute score-based gauntlet
//
// drag through adjacent matching gems; chain length = points (linear).
// every 100 points the board reshapes: bigger grid, more colors, voids,
// and power-up gems.
//
// power-ups (each chained power-up clears extra cells; each cleared cell
// awards 1 point):
//   • row clear   — wipes the entire row of the gem
//   • col clear   — wipes the entire column of the gem
//   • bomb        — wipes the 3×3 area around the gem
//
// scoring → score = clamp(_score / _targetScore, 0, 1)
//   _targetScore == 1.5 × estimated human baseline.
// ---------------------------------------------------------------------------

class LevelLinkChain extends LevelWidget {
  const LevelLinkChain({super.key, required super.onComplete});

  @override
  State<LevelLinkChain> createState() => _LevelLinkChainState();
}

// ---------------------------------------------------------------------------
// stage configuration
// ---------------------------------------------------------------------------

class _StageConfig {
  final String name;
  final int rows;
  final int cols;
  final int colorCount; // 4..6
  final int voidCount; // permanently blocked cells
  final double powerRate; // 0..1 chance new gems spawn as a power-up

  const _StageConfig({
    required this.name,
    required this.rows,
    required this.cols,
    required this.colorCount,
    required this.voidCount,
    required this.powerRate,
  });
}

// every 100 points → next stage. last stage repeats indefinitely.
const List<_StageConfig> _stages = [
  _StageConfig(
    name: 'genesis',
    rows: 5,
    cols: 5,
    colorCount: 4,
    voidCount: 0,
    powerRate: 0.0,
  ),
  _StageConfig(
    name: 'expansion',
    rows: 6,
    cols: 6,
    colorCount: 4,
    voidCount: 0,
    powerRate: 0.0,
  ),
  _StageConfig(
    name: 'spectrum',
    rows: 6,
    cols: 6,
    colorCount: 5,
    voidCount: 0,
    powerRate: 0.05,
  ),
  _StageConfig(
    name: 'power surge',
    rows: 7,
    cols: 7,
    colorCount: 5,
    voidCount: 0,
    powerRate: 0.07,
  ),
  _StageConfig(
    name: 'voidfall',
    rows: 7,
    cols: 7,
    colorCount: 5,
    voidCount: 4,
    powerRate: 0.07,
  ),
  _StageConfig(
    name: 'octant',
    rows: 8,
    cols: 8,
    colorCount: 5,
    voidCount: 6,
    powerRate: 0.07,
  ),
  _StageConfig(
    name: 'prismatic',
    rows: 8,
    cols: 8,
    colorCount: 6,
    voidCount: 8,
    powerRate: 0.08,
  ),
  _StageConfig(
    name: 'chaos',
    rows: 8,
    cols: 8,
    colorCount: 6,
    voidCount: 12,
    powerRate: 0.10,
  ),
];

int _stageIndexForScore(int score) {
  final idx = score ~/ 100;
  return idx < _stages.length ? idx : _stages.length - 1;
}

// ---------------------------------------------------------------------------
// cell model
// ---------------------------------------------------------------------------

enum _PowerType { none, rowClear, colClear, bomb }

class _Cell {
  final int color; // 0..5; -1 means void (permanent block)
  final _PowerType power;

  const _Cell({required this.color, this.power = _PowerType.none});

  bool get isVoid => color < 0;
  bool get isPower => power != _PowerType.none;

  static const _Cell voidCell = _Cell(color: -1);
}

// ---------------------------------------------------------------------------
// effects
// ---------------------------------------------------------------------------

enum _FxType { rowSweep, colSweep, bombBlast, megaShockwave }

class _Fx {
  final _FxType type;
  final Offset center;
  final double startTime; // seconds, from _animClock
  final double duration; // seconds
  final int? row;
  final int? col;

  _Fx({
    required this.type,
    required this.center,
    required this.startTime,
    required this.duration,
    this.row,
    this.col,
  });

  double progress(double now) => ((now - startTime) / duration).clamp(0.0, 1.0);

  bool isExpired(double now) => now - startTime >= duration;
}

class _DropAnim {
  final double startTime;
  final double duration;
  final double fromRowOffset; // rows above final position at startTime

  const _DropAnim({
    required this.startTime,
    required this.duration,
    required this.fromRowOffset,
  });

  /// current vertical offset in cell-units (0 means at final position).
  /// uses gravity-like easing (slow start, fast end).
  double currentOffset(double now) {
    final p = ((now - startTime) / duration).clamp(0.0, 1.0);
    if (p >= 1.0) return 0;
    return fromRowOffset * (1 - p * p);
  }

  bool isDone(double now) => now - startTime >= duration;
}

// ---------------------------------------------------------------------------
// state
// ---------------------------------------------------------------------------

class _LevelLinkChainState extends State<LevelLinkChain>
    with TickerProviderStateMixin {
  // --- run config ---
  // hidden internal threshold — score >= _targetScore yields 100%.
  // intentionally not surfaced in the HUD or completion metrics.
  static const int _targetScore = 4000;
  static const Duration _runDuration = Duration(minutes: 30);
  static const int _megaChainThreshold = 7; // chain length for banner
  static const double _dropDurationSec = 0.32;

  // --- gameplay state ---
  final Random _rng = Random();
  late List<List<_Cell>> _board;
  late List<List<_DropAnim?>> _drops;
  final List<List<int>> _chain = []; // [row, col] pairs
  int _score = 0;
  int _stageIdx = 0;
  bool _isDragging = false;
  bool _completed = false;

  // --- timing ---
  Timer? _ticker;
  Duration _timeLeft = _runDuration;

  // --- transition banner ---
  String? _bannerText;
  Timer? _bannerTimer;

  // --- effects / animation ---
  final List<_Fx> _effects = [];
  late final Ticker _animTicker;
  final Stopwatch _animClock = Stopwatch()..start();
  String? _megaChainText;
  Timer? _megaChainTimer;

  // --- layout ---
  double _cellSize = 0;
  Offset _gridOrigin = Offset.zero;

  _StageConfig get _cfg => _stages[_stageIdx];
  int get _rows => _cfg.rows;
  int get _cols => _cfg.cols;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(_buildOutcome);
    _board = _buildBoard(_cfg);
    _drops = _emptyDrops(_cfg);

    // animation ticker — runs only when there are active fx or drops.
    // must be created BEFORE _scheduleBoardFallIn (which kicks the ticker).
    _animTicker = createTicker((_) {
      if (!mounted) return;
      final now = _animClock.elapsedMicroseconds / 1e6;

      bool stillAnimating = false;

      _effects.removeWhere((fx) => fx.isExpired(now));
      if (_effects.isNotEmpty) stillAnimating = true;

      for (int r = 0; r < _drops.length; r++) {
        for (int c = 0; c < _drops[r].length; c++) {
          final d = _drops[r][c];
          if (d == null) continue;
          if (d.isDone(now)) {
            _drops[r][c] = null;
          } else {
            stillAnimating = true;
          }
        }
      }

      if (!stillAnimating) {
        _animTicker.stop();
      }
      setState(() {});
    });

    // animate the initial board falling in.
    _scheduleBoardFallIn();

    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _completed) return;
      setState(() {
        _timeLeft -= const Duration(seconds: 1);
        if (_timeLeft <= Duration.zero) {
          _timeLeft = Duration.zero;
          _finish();
        }
      });
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _bannerTimer?.cancel();
    _megaChainTimer?.cancel();
    widget.clearPartialScoreGetter();
    _animTicker.dispose();
    super.dispose();
  }

  // ---------- board generation ----------

  List<List<_Cell>> _buildBoard(_StageConfig cfg) {
    final board = List.generate(
      cfg.rows,
      (_) =>
          List<_Cell>.filled(cfg.cols, const _Cell(color: 0), growable: false),
    );

    final placed = <int>{};
    while (placed.length < cfg.voidCount) {
      final r = _rng.nextInt(cfg.rows);
      final c = _rng.nextInt(cfg.cols);
      final key = r * cfg.cols + c;
      if (placed.add(key)) {
        board[r][c] = _Cell.voidCell;
      }
    }

    for (int r = 0; r < cfg.rows; r++) {
      for (int c = 0; c < cfg.cols; c++) {
        if (board[r][c].isVoid) continue;
        board[r][c] = _spawnGem(cfg);
      }
    }
    return board;
  }

  List<List<_DropAnim?>> _emptyDrops(_StageConfig cfg) =>
      List.generate(cfg.rows, (_) => List<_DropAnim?>.filled(cfg.cols, null));

  _Cell _spawnGem(_StageConfig cfg) {
    final color = _rng.nextInt(cfg.colorCount);
    final isPower = cfg.powerRate > 0 && _rng.nextDouble() < cfg.powerRate;
    if (!isPower) return _Cell(color: color);

    // distribute power types: ~40% row, ~40% col, ~20% bomb (bombs are strong).
    final r = _rng.nextDouble();
    final type = r < 0.4
        ? _PowerType.rowClear
        : r < 0.8
        ? _PowerType.colClear
        : _PowerType.bomb;
    return _Cell(color: color, power: type);
  }

  /// populate drops so the entire board appears to cascade in from above.
  void _scheduleBoardFallIn() {
    final now = _animClock.elapsedMicroseconds / 1e6;
    for (int c = 0; c < _cols; c++) {
      int idx = 0;
      for (int r = _rows - 1; r >= 0; r--) {
        if (_board[r][c].isVoid) continue;
        _drops[r][c] = _DropAnim(
          startTime: now,
          duration: _dropDurationSec + idx * 0.02,
          fromRowOffset: (r + idx + 1).toDouble(),
        );
        idx++;
      }
    }
    _kickAnimTicker();
  }

  void _kickAnimTicker() {
    if (!_animTicker.isActive) _animTicker.start();
  }

  // ---------- stage progression ----------

  void _checkStageAdvance() {
    final newIdx = _stageIndexForScore(_score);
    if (newIdx == _stageIdx) return;
    _stageIdx = newIdx;
    _board = _buildBoard(_cfg);
    _drops = _emptyDrops(_cfg);
    _scheduleBoardFallIn();
    _showBanner('stage ${_stageIdx + 1}: ${_cfg.name}');
  }

  void _showBanner(String text) {
    _bannerText = text;
    _bannerTimer?.cancel();
    _bannerTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _bannerText = null);
    });
  }

  // ---------- gesture helpers ----------

  bool get _hasActiveDrops {
    for (final row in _drops) {
      for (final d in row) {
        if (d != null) return true;
      }
    }
    return false;
  }

  List<int>? _cellAt(Offset local) {
    final x = local.dx - _gridOrigin.dx;
    final y = local.dy - _gridOrigin.dy;
    if (_cellSize <= 0) return null;
    final c = (x / _cellSize).floor();
    final r = (y / _cellSize).floor();
    if (r >= 0 && r < _rows && c >= 0 && c < _cols) return [r, c];
    return null;
  }

  bool _adjacent(List<int> a, List<int> b) {
    final dr = (a[0] - b[0]).abs();
    final dc = (a[1] - b[1]).abs();
    return dr <= 1 && dc <= 1 && !(dr == 0 && dc == 0);
  }

  bool _inChain(int r, int c) => _chain.any((e) => e[0] == r && e[1] == c);

  void _panStart(DragStartDetails d) {
    if (_completed || _hasActiveDrops) return;
    final cell = _cellAt(d.localPosition);
    if (cell == null) return;
    if (_board[cell[0]][cell[1]].isVoid) return;
    setState(() {
      _isDragging = true;
      _chain
        ..clear()
        ..add(cell);
    });
  }

  void _panUpdate(DragUpdateDetails d) {
    if (!_isDragging || _chain.isEmpty || _completed) return;
    final cell = _cellAt(d.localPosition);
    if (cell == null) return;

    if (_chain.length >= 2) {
      final prev = _chain[_chain.length - 2];
      if (prev[0] == cell[0] && prev[1] == cell[1]) {
        setState(() => _chain.removeLast());
        return;
      }
    }

    if (_inChain(cell[0], cell[1])) return;
    if (!_adjacent(_chain.last, cell)) return;

    final candidate = _board[cell[0]][cell[1]];
    if (candidate.isVoid) return;

    final headType = _board[_chain.first[0]][_chain.first[1]].color;
    if (candidate.color != headType) return;

    setState(() => _chain.add(cell));
  }

  void _panEnd(DragEndDetails _) {
    if (!_isDragging) return;
    if (_chain.length < 2) {
      setState(() {
        _isDragging = false;
        _chain.clear();
      });
      return;
    }

    final len = _chain.length;
    final now = _animClock.elapsedMicroseconds / 1e6;

    // build set of all cleared cells (chain + power-up areas).
    final cleared = <int>{};
    final powerFx = <_Fx>[];

    for (final c in _chain) {
      cleared.add(c[0] * _cols + c[1]);
    }

    for (final c in _chain) {
      final cell = _board[c[0]][c[1]];
      switch (cell.power) {
        case _PowerType.rowClear:
          for (int cc = 0; cc < _cols; cc++) {
            if (!_board[c[0]][cc].isVoid) cleared.add(c[0] * _cols + cc);
          }
          powerFx.add(
            _Fx(
              type: _FxType.rowSweep,
              center: _cellCenter(c[0], c[1]),
              startTime: now,
              duration: 0.42,
              row: c[0],
            ),
          );
          break;
        case _PowerType.colClear:
          for (int rr = 0; rr < _rows; rr++) {
            if (!_board[rr][c[1]].isVoid) cleared.add(rr * _cols + c[1]);
          }
          powerFx.add(
            _Fx(
              type: _FxType.colSweep,
              center: _cellCenter(c[0], c[1]),
              startTime: now,
              duration: 0.42,
              col: c[1],
            ),
          );
          break;
        case _PowerType.bomb:
          for (int dr = -1; dr <= 1; dr++) {
            for (int dc = -1; dc <= 1; dc++) {
              final nr = c[0] + dr;
              final nc = c[1] + dc;
              if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) continue;
              if (_board[nr][nc].isVoid) continue;
              cleared.add(nr * _cols + nc);
            }
          }
          powerFx.add(
            _Fx(
              type: _FxType.bombBlast,
              center: _cellCenter(c[0], c[1]),
              startTime: now,
              duration: 0.6,
            ),
          );
          break;
        case _PowerType.none:
          break;
      }
    }

    final gained = cleared.length;
    final lastCell = _chain.last;
    final lastCenter = _cellCenter(lastCell[0], lastCell[1]);

    setState(() {
      _isDragging = false;
      _score += gained;
      _resolveCollapse(cleared, now);
      _chain.clear();
      _checkStageAdvance();

      _effects.addAll(powerFx);
      if (len >= _megaChainThreshold) {
        _effects.add(
          _Fx(
            type: _FxType.megaShockwave,
            center: lastCenter,
            startTime: now,
            duration: 0.9,
          ),
        );
      }
      if (_effects.isNotEmpty) _kickAnimTicker();
    });

    if (len >= _megaChainThreshold) {
      _showMegaChain(len, gained);
    }
  }

  Offset _cellCenter(int r, int c) => Offset(
    _gridOrigin.dx + c * _cellSize + _cellSize / 2,
    _gridOrigin.dy + r * _cellSize + _cellSize / 2,
  );

  void _showMegaChain(int len, int gain) {
    setState(() => _megaChainText = 'MEGA CHAIN ×$len  +$gain');
    _megaChainTimer?.cancel();
    _megaChainTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _megaChainText = null);
    });
  }

  /// remove cleared cells from the board and let surviving / new gems
  /// fall in with drop animations.
  void _resolveCollapse(Set<int> cleared, double now) {
    for (int col = 0; col < _cols; col++) {
      // collect surviving non-void gems (top-down preserves vertical order).
      final survivors = <_Cell>[];
      final survivorOldRows = <int>[];
      for (int r = 0; r < _rows; r++) {
        if (_board[r][col].isVoid) continue;
        if (cleared.contains(r * _cols + col)) continue;
        survivors.add(_board[r][col]);
        survivorOldRows.add(r);
      }

      // non-void slots, bottom-up.
      final slots = <int>[];
      for (int r = _rows - 1; r >= 0; r--) {
        if (!_board[r][col].isVoid) slots.add(r);
      }

      int newGemIdx = 0;
      for (int i = 0; i < slots.length; i++) {
        final r = slots[i];
        if (i < survivors.length) {
          // bottom-most survivor (highest oldRow) lands in bottom-most slot.
          final survIdx = survivors.length - 1 - i;
          final oldRow = survivorOldRows[survIdx];
          _board[r][col] = survivors[survIdx];
          if (oldRow != r) {
            _drops[r][col] = _DropAnim(
              startTime: now,
              duration: _dropDurationSec,
              fromRowOffset: (r - oldRow).toDouble(),
            );
          } else {
            _drops[r][col] = null;
          }
        } else {
          // brand new gem — falls in from above the visible board.
          _board[r][col] = _spawnGem(_cfg);
          _drops[r][col] = _DropAnim(
            startTime: now,
            duration: _dropDurationSec,
            fromRowOffset: (r + newGemIdx + 1).toDouble(),
          );
          newGemIdx++;
        }
      }
    }
    _kickAnimTicker();
  }

  // ---------- finish ----------

  LevelOutcome _buildOutcome() {
    final normalized = (_score / _targetScore).clamp(0.0, 1.0);
    return LevelOutcome(
      score: normalized,
      metrics: {'score': _score, 'stage_reached': _stageIdx + 1},
    );
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    _ticker?.cancel();
    _bannerTimer?.cancel();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      widget.onComplete(_buildOutcome());
    });
  }

  // ---------- HUD helpers ----------

  String _formatTime(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, box) {
                  const hudHeight = 56.0;
                  final maxW = box.maxWidth - 24;
                  final maxH = box.maxHeight - hudHeight - 12;
                  _cellSize = min(maxW / _cols, maxH / _rows);
                  final gridW = _cellSize * _cols;
                  final gridH = _cellSize * _rows;
                  _gridOrigin = Offset(
                    (box.maxWidth - gridW) / 2,
                    hudHeight + (box.maxHeight - hudHeight - gridH) / 2,
                  );

                  final now = _animClock.elapsedMicroseconds / 1e6;

                  return GestureDetector(
                    onPanStart: _panStart,
                    onPanUpdate: _panUpdate,
                    onPanEnd: _panEnd,
                    child: CustomPaint(
                      size: Size(box.maxWidth, box.maxHeight),
                      painter: _GridPainter(
                        board: _board,
                        drops: _drops,
                        chain: _chain,
                        cellSize: _cellSize,
                        origin: _gridOrigin,
                        rows: _rows,
                        cols: _cols,
                        now: now,
                      ),
                      foregroundPainter: _EffectsPainter(
                        effects: _effects,
                        now: now,
                        cellSize: _cellSize,
                        origin: _gridOrigin,
                        rows: _rows,
                        cols: _cols,
                      ),
                    ),
                  );
                },
              ),
            ),

            // standardized HUD: time + score + stage + info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LevelHud(
                timerText: _formatTime(_timeLeft),
                stageText: '${_stageIdx + 1}/${_stages.length}',
                trailing: Text(
                  'score $_score',
                  style: const TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                infoTitle: 'chain reaction',
                infoItems: [
                  const LevelHudBullet('💎', 'drag through adjacent matching gems — 1 point per cleared cell'),
                  const LevelHudBullet('⚡', 'longer chains trigger power gems: row clears, column clears, and bombs'),
                  const LevelHudBullet('📈', 'reach 100 points to advance to the next stage'),
                  LevelHudBullet('🎯', 'hit $_targetScore total points before the 30-minute timer runs out'),
                ],
              ),
            ),

            // mega chain banner
            if (_megaChainText != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey(_megaChainText),
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.elasticOut,
                      tween: Tween(begin: 0.5, end: 1.0),
                      builder: (_, scale, child) =>
                          Transform.scale(scale: scale, child: child),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFAB00), Color(0xFFE55CD8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: NunuColors.primaryMain.withValues(
                                alpha: 0.55,
                              ),
                              blurRadius: 32,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          _megaChainText!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // stage transition banner
            if (_bannerText != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedOpacity(
                      opacity: 1,
                      duration: const Duration(milliseconds: 200),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: NunuColors.backgroundPaper.withValues(
                            alpha: 0.92,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: NunuColors.primaryMain,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: NunuColors.primaryMain.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 24,
                            ),
                          ],
                        ),
                        child: Text(
                          _bannerText!.toUpperCase(),
                          style: const TextStyle(
                            color: NunuColors.primaryLight,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// grid painter
// ---------------------------------------------------------------------------

const List<Color> _gemColors = [
  Color(0xFFE53935), // red
  Color(0xFF1E88E5), // blue
  Color(0xFF43A047), // green
  Color(0xFFFFB300), // gold
  Color(0xFF8E24AA), // purple
  Color(0xFFEC407A), // pink
];

class _GridPainter extends CustomPainter {
  final List<List<_Cell>> board;
  final List<List<_DropAnim?>> drops;
  final List<List<int>> chain;
  final double cellSize;
  final Offset origin;
  final int rows, cols;
  final double now;

  _GridPainter({
    required this.board,
    required this.drops,
    required this.chain,
    required this.cellSize,
    required this.origin,
    required this.rows,
    required this.cols,
    required this.now,
  });

  Offset _gemCenter(int r, int c) {
    final dropOffset = drops[r][c]?.currentOffset(now) ?? 0;
    return Offset(
      origin.dx + c * cellSize + cellSize / 2,
      origin.dy + (r - dropOffset) * cellSize + cellSize / 2,
    );
  }

  Offset _slotCenter(int r, int c) => Offset(
    origin.dx + c * cellSize + cellSize / 2,
    origin.dy + r * cellSize + cellSize / 2,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final gap = cellSize * 0.06;
    final gemR = (cellSize - gap * 2) / 2 * 0.72;

    // cell backgrounds (and voids)
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = board[r][c];
        final rect = Rect.fromLTWH(
          origin.dx + c * cellSize + gap,
          origin.dy + r * cellSize + gap,
          cellSize - gap * 2,
          cellSize - gap * 2,
        );
        if (cell.isVoid) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            Paint()..color = Colors.black.withValues(alpha: 0.55),
          );
          final hatch = Paint()
            ..color = Colors.white.withValues(alpha: 0.06)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;
          for (double t = -rect.width; t < rect.width; t += 6) {
            canvas.drawLine(
              Offset(rect.left + t, rect.top),
              Offset(rect.left + t + rect.height, rect.bottom),
              hatch,
            );
          }
        } else {
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, const Radius.circular(8)),
            Paint()..color = NunuColors.backgroundPaper,
          );
        }
      }
    }

    // chain line — uses live (drop-aware) gem centers so it follows falling gems.
    if (chain.length >= 2) {
      final path = Path();
      for (int i = 0; i < chain.length; i++) {
        final p = _gemCenter(chain[i][0], chain[i][1]);
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = NunuColors.primaryMain.withValues(alpha: 0.35)
          ..strokeWidth = gemR * 0.9
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = NunuColors.primaryMain.withValues(alpha: 0.85)
          ..strokeWidth = 3.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    // gems — render falling gems clipped to the grid bounds so off-board
    // pre-fall positions stay invisible.
    final gridRect = Rect.fromLTWH(
      origin.dx,
      origin.dy,
      cellSize * cols,
      cellSize * rows,
    );
    canvas.save();
    canvas.clipRect(gridRect);

    final linked = <String>{};
    for (final c in chain) {
      linked.add('${c[0]},${c[1]}');
    }

    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final cell = board[r][c];
        if (cell.isVoid) continue;
        final ctr = _gemCenter(r, c);
        final color = _gemColors[cell.color % _gemColors.length];
        final isLinked = linked.contains('$r,$c');

        if (isLinked) {
          canvas.drawCircle(
            ctr,
            gemR * 1.3,
            Paint()
              ..color = color.withValues(alpha: 0.3)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
          );
        }

        // power-up aura
        if (cell.isPower) {
          canvas.drawCircle(
            ctr,
            gemR * 1.45,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.18)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
          );
        }

        // gem body
        canvas.drawCircle(
          ctr,
          gemR,
          Paint()..color = isLinked ? color : color.withValues(alpha: 0.7),
        );

        // gem inner shape (small icon for color identity)
        _drawGemShape(canvas, ctr, gemR * 0.5, cell.color, isLinked);

        // power-up overlay
        if (cell.isPower) {
          _drawPowerOverlay(canvas, ctr, gemR, cell.power);
        }

        // specular highlight
        canvas.drawCircle(
          ctr + Offset(-gemR * 0.22, -gemR * 0.28),
          gemR * 0.28,
          Paint()
            ..color = Colors.white.withValues(alpha: isLinked ? 0.45 : 0.2),
        );
      }
    }

    canvas.restore();
    // touch _slotCenter to keep it referenced (used for future UI hooks).
    _slotCenter(0, 0);
  }

  void _drawPowerOverlay(
    Canvas canvas,
    Offset ctr,
    double gemR,
    _PowerType type,
  ) {
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(ctr, gemR * 0.95, ringPaint);

    final iconPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.95)
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (type) {
      case _PowerType.rowClear:
        // horizontal double-arrow
        final w = gemR * 0.85;
        final y = ctr.dy;
        canvas.drawLine(
          Offset(ctr.dx - w, y),
          Offset(ctr.dx + w, y),
          iconPaint,
        );
        // arrowheads
        canvas.drawLine(
          Offset(ctr.dx - w, y),
          Offset(ctr.dx - w + 6, y - 5),
          iconPaint,
        );
        canvas.drawLine(
          Offset(ctr.dx - w, y),
          Offset(ctr.dx - w + 6, y + 5),
          iconPaint,
        );
        canvas.drawLine(
          Offset(ctr.dx + w, y),
          Offset(ctr.dx + w - 6, y - 5),
          iconPaint,
        );
        canvas.drawLine(
          Offset(ctr.dx + w, y),
          Offset(ctr.dx + w - 6, y + 5),
          iconPaint,
        );
        break;
      case _PowerType.colClear:
        // vertical double-arrow
        final h = gemR * 0.85;
        final x = ctr.dx;
        canvas.drawLine(
          Offset(x, ctr.dy - h),
          Offset(x, ctr.dy + h),
          iconPaint,
        );
        canvas.drawLine(
          Offset(x, ctr.dy - h),
          Offset(x - 5, ctr.dy - h + 6),
          iconPaint,
        );
        canvas.drawLine(
          Offset(x, ctr.dy - h),
          Offset(x + 5, ctr.dy - h + 6),
          iconPaint,
        );
        canvas.drawLine(
          Offset(x, ctr.dy + h),
          Offset(x - 5, ctr.dy + h - 6),
          iconPaint,
        );
        canvas.drawLine(
          Offset(x, ctr.dy + h),
          Offset(x + 5, ctr.dy + h - 6),
          iconPaint,
        );
        break;
      case _PowerType.bomb:
        // filled disc with a fuse spark
        canvas.drawCircle(
          ctr,
          gemR * 0.46,
          Paint()..color = Colors.white.withValues(alpha: 0.95),
        );
        canvas.drawCircle(
          ctr + Offset(gemR * 0.3, -gemR * 0.5),
          gemR * 0.13,
          Paint()..color = const Color(0xFFFFAB00),
        );
        break;
      case _PowerType.none:
        break;
    }
  }

  void _drawGemShape(
    Canvas canvas,
    Offset ctr,
    double r,
    int colorIdx,
    bool lit,
  ) {
    final alpha = lit ? 0.6 : 0.3;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    switch (colorIdx % 6) {
      case 0:
        final path = Path()
          ..moveTo(ctr.dx, ctr.dy - r)
          ..lineTo(ctr.dx - r * 0.87, ctr.dy + r * 0.5)
          ..lineTo(ctr.dx + r * 0.87, ctr.dy + r * 0.5)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 1:
        final path = Path()
          ..moveTo(ctr.dx, ctr.dy - r)
          ..lineTo(ctr.dx + r, ctr.dy)
          ..lineTo(ctr.dx, ctr.dy + r)
          ..lineTo(ctr.dx - r, ctr.dy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 2:
        canvas.drawRect(
          Rect.fromCenter(center: ctr, width: r * 1.5, height: r * 1.5),
          paint,
        );
        break;
      case 3:
        _drawStar(canvas, ctr, r, paint);
        break;
      case 4:
        canvas.drawCircle(ctr, r * 0.7, paint);
        break;
      case 5:
        final path = Path();
        for (int i = 0; i < 6; i++) {
          final a = pi / 3 * i - pi / 2;
          final p = Offset(ctr.dx + cos(a) * r, ctr.dy + sin(a) * r);
          if (i == 0) {
            path.moveTo(p.dx, p.dy);
          } else {
            path.lineTo(p.dx, p.dy);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
    }
  }

  void _drawStar(Canvas canvas, Offset ctr, double r, Paint paint) {
    final path = Path();
    for (int i = 0; i < 10; i++) {
      final a = pi / 5 * i - pi / 2;
      final rad = i.isEven ? r : r * 0.4;
      final p = Offset(ctr.dx + cos(a) * rad, ctr.dy + sin(a) * rad);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => true;
}

// ---------------------------------------------------------------------------
// effects painter
// ---------------------------------------------------------------------------

class _EffectsPainter extends CustomPainter {
  final List<_Fx> effects;
  final double now;
  final double cellSize;
  final Offset origin;
  final int rows, cols;

  _EffectsPainter({
    required this.effects,
    required this.now,
    required this.cellSize,
    required this.origin,
    required this.rows,
    required this.cols,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (cellSize <= 0) return;
    for (final fx in effects) {
      final p = fx.progress(now);
      switch (fx.type) {
        case _FxType.rowSweep:
          _paintRowSweep(canvas, fx, p);
          break;
        case _FxType.colSweep:
          _paintColSweep(canvas, fx, p);
          break;
        case _FxType.bombBlast:
          _paintBombBlast(canvas, fx.center, p);
          break;
        case _FxType.megaShockwave:
          _paintShockwave(canvas, fx.center, p);
          break;
      }
    }
  }

  void _paintRowSweep(Canvas canvas, _Fx fx, double p) {
    final r = fx.row ?? 0;
    final y = origin.dy + r * cellSize;
    final left = origin.dx;
    final width = cellSize * cols;
    final alpha = (1 - p).clamp(0.0, 1.0);

    // soft band fade
    canvas.drawRect(
      Rect.fromLTWH(left, y, width, cellSize),
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // moving leading edge
    final leadX = left + p * width;
    canvas.drawRect(
      Rect.fromLTWH(leadX - 4, y, 8, cellSize),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    // glow trail
    canvas.drawRect(
      Rect.fromLTWH(left, y, leadX - left, cellSize),
      Paint()..color = NunuColors.primaryLight.withValues(alpha: alpha * 0.35),
    );
  }

  void _paintColSweep(Canvas canvas, _Fx fx, double p) {
    final c = fx.col ?? 0;
    final x = origin.dx + c * cellSize;
    final top = origin.dy;
    final height = cellSize * rows;
    final alpha = (1 - p).clamp(0.0, 1.0);

    canvas.drawRect(
      Rect.fromLTWH(x, top, cellSize, height),
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    final leadY = top + p * height;
    canvas.drawRect(
      Rect.fromLTWH(x, leadY - 4, cellSize, 8),
      Paint()..color = Colors.white.withValues(alpha: 0.95),
    );
    canvas.drawRect(
      Rect.fromLTWH(x, top, cellSize, leadY - top),
      Paint()..color = NunuColors.secondaryMain.withValues(alpha: alpha * 0.35),
    );
  }

  void _paintBombBlast(Canvas canvas, Offset center, double p) {
    final r = cellSize * (0.5 + p * 2.6);
    final alpha = (1 - p).clamp(0.0, 1.0);

    // hot core
    canvas.drawCircle(
      center,
      r * 0.45,
      Paint()..color = Colors.white.withValues(alpha: alpha * 0.85),
    );
    // orange flash
    canvas.drawCircle(
      center,
      r * 1.0,
      Paint()
        ..color = const Color(0xFFFF7043).withValues(alpha: alpha * 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );
    // bright ring
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = const Color(0xFFFFAB00).withValues(alpha: alpha * 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1 - p) * 6 + 2,
    );
    // shrapnel
    const shards = 10;
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: alpha * 0.75)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.2;
    for (int i = 0; i < shards; i++) {
      final angle = 2 * pi * i / shards + p * 0.8;
      final dir = Offset(cos(angle), sin(angle));
      canvas.drawLine(
        center + dir * (cellSize * 0.4),
        center + dir * (cellSize * (0.7 + p * 1.4)),
        paint,
      );
    }
  }

  void _paintShockwave(Canvas canvas, Offset center, double p) {
    final r = cellSize * (0.6 + p * 6.5);
    final alpha = (1 - p).clamp(0.0, 1.0);
    const ringColor = Color(0xFFE55CD8);

    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = ringColor.withValues(alpha: alpha * 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1 - p) * 8 + 2
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    canvas.drawCircle(
      center,
      r,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = (1 - p) * 3 + 1,
    );
  }

  @override
  bool shouldRepaint(covariant _EffectsPainter old) => true;
}
