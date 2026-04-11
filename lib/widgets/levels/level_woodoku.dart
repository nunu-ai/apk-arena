import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Woodoku – block-puzzle on a 9x9 Sudoku grid
// ---------------------------------------------------------------------------

class LevelWoodoku extends LevelWidget {
  const LevelWoodoku({super.key, required super.onComplete});

  @override
  State<LevelWoodoku> createState() => _LevelWoodokuState();
}

class _LevelWoodokuState extends State<LevelWoodoku> {
  // ---- Constants --------------------------------------------------------
  static const int _n = 9;
  static const int _total = _n * _n;
  static const int _target = 200;

  /// Every shape is a list of [row, col] offsets from the anchor (top-left of
  /// the bounding box). 23 shapes covering dots, lines, squares, L/T/S/Z, plus,
  /// and big-L in all rotations.
  static const List<List<List<int>>> _shapes = [
    // dot
    [
      [0, 0],
    ],
    // horizontal / vertical lines
    [
      [0, 0],
      [0, 1],
    ],
    [
      [0, 0],
      [1, 0],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
    ],
    [
      [0, 0],
      [1, 0],
      [2, 0],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
    ],
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [0, 3],
      [0, 4],
    ],
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [3, 0],
      [4, 0],
    ],
    // squares
    [
      [0, 0],
      [0, 1],
      [1, 0],
      [1, 1],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [1, 0],
      [1, 1],
      [1, 2],
      [2, 0],
      [2, 1],
      [2, 2],
    ],
    // small-L (3 cells, 4 orientations)
    [
      [0, 0],
      [1, 0],
      [1, 1],
    ],
    [
      [0, 1],
      [1, 0],
      [1, 1],
    ],
    [
      [0, 0],
      [0, 1],
      [1, 0],
    ],
    [
      [0, 0],
      [0, 1],
      [1, 1],
    ],
    // T / S / Z (4 cells)
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [1, 1],
    ],
    [
      [0, 1],
      [0, 2],
      [1, 0],
      [1, 1],
    ],
    [
      [0, 0],
      [0, 1],
      [1, 1],
      [1, 2],
    ],
    // plus (5 cells)
    [
      [0, 1],
      [1, 0],
      [1, 1],
      [1, 2],
      [2, 1],
    ],
    // big-L (5 cells, 4 orientations)
    [
      [0, 0],
      [1, 0],
      [2, 0],
      [2, 1],
      [2, 2],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [1, 0],
      [2, 0],
    ],
    [
      [0, 0],
      [0, 1],
      [0, 2],
      [1, 2],
      [2, 2],
    ],
    [
      [0, 2],
      [1, 2],
      [2, 0],
      [2, 1],
      [2, 2],
    ],
  ];

  /// Blocker positions (row, col). Permanently occupied, never cleared.
  /// One per 3x3 box (7 of 9 boxes), spread across different rows/columns.
  static const List<List<int>> _blockerPositions = [
    [0, 4], // box (0,1)
    [2, 7], // box (0,2)
    [3, 1], // box (1,0)
    [4, 4], // box (1,1) – dead center
    [5, 8], // box (1,2)
    [6, 2], // box (2,0)
    [8, 6], // box (2,2)
  ];

  // ---- State ------------------------------------------------------------
  late List<List<bool>> _grid;
  late Set<int> _blockers; // flat indices of permanent blocker cells
  late List<List<List<int>>> _pieces; // current 3 shapes
  late List<bool> _placed;
  late List<Color> _colors;
  int _score = 0;
  bool _done = false;

  // hover tracking
  int? _hoverIdx; // flat anchor index
  int? _hoverPi; // piece index 0-2
  int? _hoverSourceIdx; // flat index of currently hovered board cell

  final _rng = Random();
  final Map<int, Point<int>> _grabbedCellByPiece = {};

  // ---- Lifecycle --------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _grid = List.generate(_n, (_) => List.filled(_n, false));
    // place blockers
    _blockers = {};
    for (final pos in _blockerPositions) {
      _grid[pos[0]][pos[1]] = true;
      _blockers.add(pos[0] * _n + pos[1]);
    }
    _deal();
  }

  // ---- Game logic -------------------------------------------------------

  void _deal() {
    _pieces = List.generate(3, (_) => _shapes[_rng.nextInt(_shapes.length)]);
    _placed = [false, false, false];
    _colors = List.filled(3, NunuColors.primaryMain);
  }

  /// Can [shape] be placed with its anchor at ([ar], [ac])?
  bool _fits(List<List<int>> shape, int ar, int ac) {
    for (final o in shape) {
      final r = ar + o[0], c = ac + o[1];
      if (r < 0 || r >= _n || c < 0 || c >= _n || _grid[r][c]) return false;
    }
    return true;
  }

  /// Can [shape] be placed anywhere on the board?
  bool _fitsAnywhere(List<List<int>> shape) {
    for (int r = 0; r < _n; r++) {
      for (int c = 0; c < _n; c++) {
        if (_fits(shape, r, c)) return true;
      }
    }
    return false;
  }

  /// Place piece [pi] with anchor at ([ar], [ac]).
  void _place(int pi, int ar, int ac) {
    if (_done) return;
    final shape = _pieces[pi];
    if (!_fits(shape, ar, ac)) return;

    setState(() {
      // 1. fill cells
      for (final o in shape) {
        _grid[ar + o[0]][ac + o[1]] = true;
      }
      _placed[pi] = true;
      _score += shape.length; // 1 pt per cell

      // 2. clear hover
      _hoverIdx = null;
      _hoverPi = null;
      _hoverSourceIdx = null;

      // 3. clear completed rows / cols / boxes
      _clearCompleted();

      // 4. win check (before game-over so a simultaneous score+stuck = win)
      if (_score >= _target) {
        _done = true;
        widget.onComplete(LevelOutcome(score: 1));
        return;
      }

      // 5. deal new set if all 3 placed
      if (_placed.every((p) => p)) _deal();

      // 6. game over?
      _checkGameOver();
    });
    HapticFeedback.lightImpact();
  }

  /// Clear every full row, column, and 3x3 box. Award combo bonus.
  void _clearCompleted() {
    final remove = <int>{};
    int clears = 0;

    // rows
    for (int r = 0; r < _n; r++) {
      if (_grid[r].every((v) => v)) {
        for (int c = 0; c < _n; c++) {
          remove.add(r * _n + c);
        }
        clears++;
      }
    }
    // columns
    for (int c = 0; c < _n; c++) {
      bool full = true;
      for (int r = 0; r < _n; r++) {
        if (!_grid[r][c]) {
          full = false;
          break;
        }
      }
      if (full) {
        for (int r = 0; r < _n; r++) {
          remove.add(r * _n + c);
        }
        clears++;
      }
    }
    // 3x3 boxes
    for (int br = 0; br < 3; br++) {
      for (int bc = 0; bc < 3; bc++) {
        bool full = true;
        for (int r = br * 3; r < br * 3 + 3 && full; r++) {
          for (int c = bc * 3; c < bc * 3 + 3 && full; c++) {
            if (!_grid[r][c]) full = false;
          }
        }
        if (full) {
          for (int r = br * 3; r < br * 3 + 3; r++) {
            for (int c = bc * 3; c < bc * 3 + 3; c++) {
              remove.add(r * _n + c);
            }
          }
          clears++;
        }
      }
    }

    if (remove.isNotEmpty) {
      // never clear blocker cells
      remove.removeAll(_blockers);
      for (final i in remove) {
        _grid[i ~/ _n][i % _n] = false;
      }
      // 18 per clear, combo multiplier for multi-clears
      _score += 18 * clears * (clears > 1 ? clears : 1);
      HapticFeedback.mediumImpact();
    }
  }

  void _checkGameOver() {
    if (_done) return;
    for (int i = 0; i < 3; i++) {
      if (!_placed[i] && _fitsAnywhere(_pieces[i])) return;
    }
    _done = true;
    widget.onComplete(LevelOutcome(score: 0));
  }

  // ---- Hover helpers ----------------------------------------------------

  Set<int> _footprint() {
    if (_hoverIdx == null || _hoverPi == null) return {};
    final shape = _pieces[_hoverPi!];
    final ar = _hoverIdx! ~/ _n, ac = _hoverIdx! % _n;
    return {
      for (final o in shape)
        if (ar + o[0] >= 0 &&
            ar + o[0] < _n &&
            ac + o[1] >= 0 &&
            ac + o[1] < _n)
          (ar + o[0]) * _n + (ac + o[1]),
    };
  }

  bool _hoverOk() {
    if (_hoverIdx == null || _hoverPi == null) return false;
    return _fits(_pieces[_hoverPi!], _hoverIdx! ~/ _n, _hoverIdx! % _n);
  }

  Point<int> _nearestShapeCell(
    List<List<int>> shape,
    Offset local,
    double cellSize,
  ) {
    if (shape.isEmpty) return const Point<int>(0, 0);

    List<int>? best;
    double bestDist = double.infinity;
    for (final o in shape) {
      final cx = (o[1] + 0.5) * cellSize;
      final cy = (o[0] + 0.5) * cellSize;
      final d =
          (cx - local.dx) * (cx - local.dx) + (cy - local.dy) * (cy - local.dy);
      if (d < bestDist) {
        bestDist = d;
        best = o;
      }
    }
    return Point<int>(best![0], best[1]);
  }

  Point<int> _anchorForHoveredCell(int pi, int hoveredR, int hoveredC) {
    final grabbed = _grabbedCellByPiece[pi] ?? const Point<int>(0, 0);
    return Point<int>(hoveredR - grabbed.x, hoveredC - grabbed.y);
  }

  // ---- Build ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) {
            final cs = max(
              24.0,
              min((box.maxWidth - 24) / _n, (box.maxHeight - 260) / _n),
            );
            final pcs = min(cs * 0.5, (box.maxWidth - 64) / 15);

            return Column(
              children: [
                _buildScoreBar(),
                const SizedBox(height: 4),
                _buildProgressBar(),
                const SizedBox(height: 8),
                Expanded(child: Center(child: _buildGrid(cs))),
                _buildTray(pcs, cs),
                const SizedBox(height: 8),
              ],
            );
          },
        ),
      ),
    );
  }

  // -- score bar --

  Widget _buildScoreBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'score',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_score',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'target',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_target',
                style: const TextStyle(
                  color: NunuColors.primaryMain,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // -- progress bar --

  Widget _buildProgressBar() {
    final pct = (_score / _target).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          height: 8,
          child: Stack(
            children: [
              Container(color: NunuColors.backgroundPaper),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        NunuColors.primaryMain,
                        NunuColors.secondaryMain,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -- grid --

  Widget _buildGrid(double cs) {
    final fp = _footprint();
    final ok = _hoverOk();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: NunuColors.primaryDark.withOpacity(0.6),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: SizedBox(
          width: cs * _n,
          height: cs * _n,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _n,
            ),
            itemCount: _total,
            itemBuilder: (_, i) => _buildCell(i, cs, fp, ok),
          ),
        ),
      ),
    );
  }

  Widget _buildCell(int i, double cs, Set<int> fp, bool ok) {
    final r = i ~/ _n, c = i % _n;
    final filled = _grid[r][c];
    final hover = fp.contains(i);
    final isBlocker = _blockers.contains(i);

    // cell background
    Color bg;
    if (isBlocker) {
      bg = NunuColors.errorDarker.withOpacity(0.6);
    } else if (hover) {
      bg = ok
          ? NunuColors.successMain.withOpacity(0.35)
          : NunuColors.errorMain.withOpacity(0.25);
    } else if (filled) {
      bg = NunuColors.primaryMain.withOpacity(0.15);
    } else {
      bg = NunuColors.backgroundPaper;
    }

    // sub-grid border logic (left + top only; outer edge suppressed)
    final thickColor = NunuColors.primaryDark.withOpacity(0.45);
    final thinColor = Colors.white.withOpacity(0.06);

    final double lw = c == 0 ? 0 : (c % 3 == 0 ? 1.5 : 0.5);
    final double tw = r == 0 ? 0 : (r % 3 == 0 ? 1.5 : 0.5);

    return DragTarget<int>(
      onWillAcceptWithDetails: (d) {
        if (_placed[d.data]) return false;
        final anchor = _anchorForHoveredCell(d.data, r, c);
        setState(() {
          _hoverSourceIdx = i;
          _hoverIdx = anchor.x * _n + anchor.y;
          _hoverPi = d.data;
        });
        return _fits(_pieces[d.data], anchor.x, anchor.y);
      },
      onAcceptWithDetails: (d) {
        final anchor = _anchorForHoveredCell(d.data, r, c);
        _place(d.data, anchor.x, anchor.y);
      },
      onLeave: (_) {
        if (_hoverSourceIdx == i) {
          setState(() {
            _hoverIdx = null;
            _hoverPi = null;
            _hoverSourceIdx = null;
          });
        }
      },
      builder: (_, __, ___) {
        return Container(
          decoration: BoxDecoration(
            color: bg,
            border: Border(
              left: lw > 0
                  ? BorderSide(
                      color: lw > 1 ? thickColor : thinColor,
                      width: lw,
                    )
                  : BorderSide.none,
              top: tw > 0
                  ? BorderSide(
                      color: tw > 1 ? thickColor : thinColor,
                      width: tw,
                    )
                  : BorderSide.none,
            ),
          ),
          child: isBlocker
              ? Center(
                  child: Container(
                    width: cs * 0.7,
                    height: cs * 0.7,
                    decoration: BoxDecoration(
                      color: NunuColors.errorDarker,
                      borderRadius: BorderRadius.circular(cs * 0.12),
                      border: Border.all(
                        color: NunuColors.errorMain.withOpacity(0.4),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      Icons.close,
                      color: NunuColors.errorMain.withOpacity(0.6),
                      size: cs * 0.4,
                    ),
                  ),
                )
              : filled
              ? Center(
                  child: Container(
                    width: cs * 0.6,
                    height: cs * 0.6,
                    decoration: BoxDecoration(
                      color: NunuColors.primaryMain.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(cs * 0.12),
                      boxShadow: [
                        BoxShadow(
                          color: NunuColors.primaryMain.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  // -- piece tray --

  Widget _buildTray(double pcs, double gridCs) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withOpacity(0.4),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: List.generate(3, (i) {
          return SizedBox(
            width: pcs * 5 + 8,
            height: pcs * 5 + 8,
            child: Center(
              child: _placed[i]
                  ? const SizedBox.shrink()
                  : _buildDraggable(i, pcs, gridCs),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDraggable(int pi, double pcs, double gcs) {
    final shape = _pieces[pi];
    final color = _colors[pi];

    return Draggable<int>(
      data: pi,
      maxSimultaneousDrags: _done ? 0 : 1,
      dragAnchorStrategy: (draggable, context, position) {
        final ro = context.findRenderObject();
        if (ro is! RenderBox) {
          return const Offset(0, 0);
        }
        final local = ro.globalToLocal(position);
        final grabbed = _nearestShapeCell(shape, local, pcs);
        _grabbedCellByPiece[pi] = grabbed;

        // Feedback is rendered with gcs-sized cells, so anchor pointer to the
        // grabbed feedback-cell center to avoid snap/offset artifacts.
        return Offset((grabbed.y + 0.5) * gcs, (grabbed.x + 0.5) * gcs);
      },
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.75, child: _buildShape(shape, color, gcs)),
      ),
      childWhenDragging: Opacity(
        opacity: 0.15,
        child: _buildShape(shape, color, pcs),
      ),
      onDragEnd: (_) {
        setState(() {
          _hoverIdx = null;
          _hoverPi = null;
          _hoverSourceIdx = null;
        });
      },
      child: _buildShape(shape, color, pcs),
    );
  }

  /// Renders a piece shape as a small coloured grid.
  Widget _buildShape(List<List<int>> shape, Color color, double cs) {
    int maxR = 0, maxC = 0;
    final filled = <int>{};
    for (final o in shape) {
      if (o[0] > maxR) maxR = o[0];
      if (o[1] > maxC) maxC = o[1];
      filled.add(o[0] * 100 + o[1]);
    }
    final rows = maxR + 1;
    final cols = maxC + 1;

    return SizedBox(
      width: cs * cols,
      height: cs * rows,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
        ),
        itemCount: rows * cols,
        itemBuilder: (_, idx) {
          final on = filled.contains((idx ~/ cols) * 100 + idx % cols);
          return Container(
            margin: EdgeInsets.all(cs * 0.08),
            decoration: BoxDecoration(
              color: on ? color : Colors.transparent,
              borderRadius: BorderRadius.circular(cs * 0.15),
              boxShadow: on
                  ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)]
                  : null,
            ),
          );
        },
      ),
    );
  }
}
