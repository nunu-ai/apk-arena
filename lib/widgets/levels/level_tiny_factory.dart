import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

const int _kCols = 36;
const int _kRows = 26;

enum _Item {
  ironOre,
  copperOre,
  coal,
  stone,
  ironPlate,
  copperWire,
  stoneBrick,
  gear,
  circuit,
  reinforced,
  engine,
  computer,
  rocketPart,
}

extension _ItemX on _Item {
  String get label {
    switch (this) {
      case _Item.ironOre:
        return 'iron ore';
      case _Item.copperOre:
        return 'copper ore';
      case _Item.coal:
        return 'coal';
      case _Item.stone:
        return 'stone';
      case _Item.ironPlate:
        return 'plate';
      case _Item.copperWire:
        return 'wire';
      case _Item.stoneBrick:
        return 'brick';
      case _Item.gear:
        return 'gear';
      case _Item.circuit:
        return 'circuit';
      case _Item.reinforced:
        return 'reinforced';
      case _Item.engine:
        return 'engine';
      case _Item.computer:
        return 'computer';
      case _Item.rocketPart:
        return 'rocket part';
    }
  }

  Color get color {
    switch (this) {
      case _Item.ironOre:
      case _Item.ironPlate:
        return const Color(0xFFA8896C);
      case _Item.copperOre:
      case _Item.copperWire:
        return const Color(0xFFC97B5C);
      case _Item.coal:
        return const Color(0xFF3A3A48);
      case _Item.stone:
      case _Item.stoneBrick:
        return const Color(0xFF9CA3AF);
      case _Item.gear:
        return const Color(0xFFD1B07A);
      case _Item.circuit:
        return const Color(0xFF77ED8B);
      case _Item.reinforced:
        return const Color(0xFFBA9EF7);
      case _Item.engine:
        return const Color(0xFFFFAB00);
      case _Item.computer:
        return const Color(0xFF61F3F3);
      case _Item.rocketPart:
        return const Color(0xFFE55CD8);
    }
  }

  int get value {
    switch (this) {
      case _Item.ironOre:
      case _Item.copperOre:
      case _Item.coal:
      case _Item.stone:
        return 1;
      case _Item.ironPlate:
      case _Item.copperWire:
      case _Item.stoneBrick:
        return 2;
      case _Item.gear:
        return 8;
      case _Item.circuit:
        return 10;
      case _Item.reinforced:
        return 18;
      case _Item.engine:
        return 60;
      case _Item.computer:
        return 70;
      case _Item.rocketPart:
        return 250;
    }
  }
}

enum _OreKind { iron, copper, coal, stone }

extension _OreX on _OreKind {
  Color get color {
    switch (this) {
      case _OreKind.iron:
        return const Color(0xFFA8896C);
      case _OreKind.copper:
        return const Color(0xFFC97B5C);
      case _OreKind.coal:
        return const Color(0xFF3A3A48);
      case _OreKind.stone:
        return const Color(0xFF9CA3AF);
    }
  }

  _Item get item {
    switch (this) {
      case _OreKind.iron:
        return _Item.ironOre;
      case _OreKind.copper:
        return _Item.copperOre;
      case _OreKind.coal:
        return _Item.coal;
      case _OreKind.stone:
        return _Item.stone;
    }
  }

  String get label {
    switch (this) {
      case _OreKind.iron:
        return 'iron';
      case _OreKind.copper:
        return 'copper';
      case _OreKind.coal:
        return 'coal';
      case _OreKind.stone:
        return 'stone';
    }
  }
}

enum _MachineKind { miner, smelter, assembler, constructor, hub }

class _Recipe {
  final String id;
  final String name;
  final String emoji;
  final int tier;
  final Map<_Item, int> inputs;
  final _Item output;
  final double cycleSec;

  const _Recipe({
    required this.id,
    required this.name,
    required this.emoji,
    required this.tier,
    required this.inputs,
    required this.output,
    required this.cycleSec,
  });
}

const List<_Recipe> _allRecipes = [
  _Recipe(
    id: 'plate',
    name: 'iron plate',
    emoji: '🟫',
    tier: 1,
    inputs: {_Item.ironOre: 1},
    output: _Item.ironPlate,
    cycleSec: 5,
  ),
  _Recipe(
    id: 'wire',
    name: 'copper wire',
    emoji: '🟧',
    tier: 1,
    inputs: {_Item.copperOre: 1},
    output: _Item.copperWire,
    cycleSec: 5,
  ),
  _Recipe(
    id: 'brick',
    name: 'stone brick',
    emoji: '⬜',
    tier: 1,
    inputs: {_Item.stone: 1},
    output: _Item.stoneBrick,
    cycleSec: 5,
  ),
  _Recipe(
    id: 'gear',
    name: 'gear',
    emoji: '⚙',
    tier: 2,
    inputs: {_Item.ironPlate: 3},
    output: _Item.gear,
    cycleSec: 15,
  ),
  _Recipe(
    id: 'circuit',
    name: 'circuit',
    emoji: '🟢',
    tier: 2,
    inputs: {_Item.copperWire: 2, _Item.ironPlate: 1},
    output: _Item.circuit,
    cycleSec: 12,
  ),
  _Recipe(
    id: 'reinforced',
    name: 'reinforced plate',
    emoji: '🟪',
    tier: 3,
    inputs: {_Item.ironPlate: 2, _Item.stoneBrick: 3},
    output: _Item.reinforced,
    cycleSec: 18,
  ),
  _Recipe(
    id: 'engine',
    name: 'engine',
    emoji: '🟡',
    tier: 4,
    inputs: {_Item.gear: 2, _Item.ironPlate: 3, _Item.coal: 4},
    output: _Item.engine,
    cycleSec: 45,
  ),
  _Recipe(
    id: 'computer',
    name: 'computer',
    emoji: '🟦',
    tier: 4,
    inputs: {_Item.circuit: 3, _Item.copperWire: 2, _Item.reinforced: 1},
    output: _Item.computer,
    cycleSec: 40,
  ),
  _Recipe(
    id: 'rocket',
    name: 'rocket part',
    emoji: '🚀',
    tier: 5,
    inputs: {_Item.engine: 2, _Item.computer: 1, _Item.reinforced: 5},
    output: _Item.rocketPart,
    cycleSec: 90,
  ),
];

_Recipe? _recipeById(String id) {
  for (final r in _allRecipes) {
    if (r.id == id) return r;
  }
  return null;
}

List<_Recipe> _recipesFor(_MachineKind kind) {
  switch (kind) {
    case _MachineKind.smelter:
      return _allRecipes.where((r) => r.tier == 1).toList();
    case _MachineKind.assembler:
      return [_recipeById('gear')!, _recipeById('circuit')!, _recipeById('reinforced')!];
    case _MachineKind.constructor:
      return [_recipeById('engine')!, _recipeById('computer')!, _recipeById('rocket')!];
    default:
      return const [];
  }
}

int _rotateDx(int dx, int dy, int rot) {
  switch (rot & 3) {
    case 0:
      return dx;
    case 1:
      return -dy;
    case 2:
      return -dx;
    case 3:
      return dy;
  }
  return dx;
}

int _rotateDy(int dx, int dy, int rot) {
  switch (rot & 3) {
    case 0:
      return dy;
    case 1:
      return dx;
    case 2:
      return -dy;
    case 3:
      return -dx;
  }
  return dy;
}

class _PortSpec {
  final int dx;
  final int dy;
  final int outDx;
  final int outDy;
  final bool isInput;
  final int slot;
  const _PortSpec(this.dx, this.dy, this.outDx, this.outDy, this.isInput, this.slot);
}

class _MachineSpec {
  final _MachineKind kind;
  final String name;
  final String emoji;
  final int w;
  final int h;
  final int cost;
  final List<_PortSpec> basePorts;
  const _MachineSpec({
    required this.kind,
    required this.name,
    required this.emoji,
    required this.w,
    required this.h,
    required this.cost,
    required this.basePorts,
  });
}

const _MachineSpec _minerSpec = _MachineSpec(
  kind: _MachineKind.miner,
  name: 'miner',
  emoji: '⛏',
  w: 1,
  h: 1,
  cost: 5,
  basePorts: [_PortSpec(0, 0, 1, 0, false, 0)],
);
const _MachineSpec _smelterSpec = _MachineSpec(
  kind: _MachineKind.smelter,
  name: 'smelter',
  emoji: '🔥',
  w: 1,
  h: 1,
  cost: 5,
  basePorts: [
    _PortSpec(0, 0, -1, 0, true, 0),
    _PortSpec(0, 0, 1, 0, false, 0),
  ],
);
const _MachineSpec _assemblerSpec = _MachineSpec(
  kind: _MachineKind.assembler,
  name: 'assembler',
  emoji: '🔧',
  w: 2,
  h: 1,
  cost: 10,
  basePorts: [
    _PortSpec(0, 0, -1, 0, true, 0),
    _PortSpec(0, 0, 0, -1, true, 1),
    _PortSpec(1, 0, 1, 0, false, 0),
  ],
);
const _MachineSpec _constructorSpec = _MachineSpec(
  kind: _MachineKind.constructor,
  name: 'constructor',
  emoji: '🏭',
  w: 2,
  h: 2,
  cost: 20,
  basePorts: [
    _PortSpec(0, 0, -1, 0, true, 0),
    _PortSpec(0, 1, -1, 0, true, 1),
    _PortSpec(0, 0, 0, -1, true, 2),
    _PortSpec(1, 1, 1, 0, false, 0),
  ],
);
const _MachineSpec _hubSpec = _MachineSpec(
  kind: _MachineKind.hub,
  name: 'hub',
  emoji: '🏛',
  w: 3,
  h: 3,
  cost: 0,
  basePorts: [
    _PortSpec(0, 0, -1, 0, true, 0),
    _PortSpec(0, 1, -1, 0, true, 1),
    _PortSpec(0, 2, -1, 0, true, 2),
    _PortSpec(1, 0, 0, -1, true, 3),
    _PortSpec(1, 2, 0, 1, true, 4),
  ],
);

_MachineSpec _spec(_MachineKind k) {
  switch (k) {
    case _MachineKind.miner:
      return _minerSpec;
    case _MachineKind.smelter:
      return _smelterSpec;
    case _MachineKind.assembler:
      return _assemblerSpec;
    case _MachineKind.constructor:
      return _constructorSpec;
    case _MachineKind.hub:
      return _hubSpec;
  }
}

class _Port {
  final int x;
  final int y;
  final int outDx;
  final int outDy;
  final bool isInput;
  final int slot;
  _Port(this.x, this.y, this.outDx, this.outDy, this.isInput, this.slot);
}

class _Machine {
  final int id;
  final _MachineKind kind;
  int x;
  int y;
  int rot;
  String? recipeId;
  final Map<_Item, int> buffers = {};
  double cycleProgress = 0;
  bool flashRed = false;
  double flashT = 0;
  int producedLastCycle = 0;
  double recentRate = 0;
  _OreKind? minerOre;

  _Machine({
    required this.id,
    required this.kind,
    required this.x,
    required this.y,
    required this.rot,
  });

  _MachineSpec get spec => _spec(kind);

  int get w {
    final s = spec;
    return (rot & 1) == 0 ? s.w : s.h;
  }

  int get h {
    final s = spec;
    return (rot & 1) == 0 ? s.h : s.w;
  }

  _Recipe? get recipe {
    if (recipeId == null) return null;
    return _recipeById(recipeId!);
  }

  List<_Port> ports() {
    final out = <_Port>[];
    final s = spec;
    for (final p in s.basePorts) {
      final rdx = _rotateDx(p.dx, p.dy, rot);
      final rdy = _rotateDy(p.dx, p.dy, rot);
      final ox = (rot == 1) ? (s.h - 1) : ((rot == 2) ? (s.w - 1) : 0);
      final oy = (rot == 2) ? (s.h - 1) : ((rot == 3) ? (s.w - 1) : 0);
      final cx = x + rdx + ox;
      final cy = y + rdy + oy;
      final odx = _rotateDx(p.outDx, p.outDy, rot);
      final ody = _rotateDy(p.outDx, p.outDy, rot);
      out.add(_Port(cx, cy, odx, ody, p.isInput, p.slot));
    }
    return out;
  }

  List<Point<int>> cells() {
    final s = spec;
    final out = <Point<int>>[];
    final ox = (rot == 1) ? (s.h - 1) : ((rot == 2) ? (s.w - 1) : 0);
    final oy = (rot == 2) ? (s.h - 1) : ((rot == 3) ? (s.w - 1) : 0);
    for (int dx = 0; dx < s.w; dx++) {
      for (int dy = 0; dy < s.h; dy++) {
        final rdx = _rotateDx(dx, dy, rot);
        final rdy = _rotateDy(dx, dy, rot);
        out.add(Point(x + rdx + ox, y + rdy + oy));
      }
    }
    return out;
  }
}

class _Belt {
  final int x;
  final int y;
  int inDx = 0;
  int inDy = 0;
  int outDx = 0;
  int outDy = 0;
  final List<_BeltItem> items = [];
  double cooldown = 0;
  int rrPickIndex = 0;
  _Belt(this.x, this.y);
}

class _BeltItem {
  final _Item item;
  double progress;
  _BeltItem(this.item, this.progress);
}

class _Order {
  final _Item item;
  final int qty;
  const _Order(this.item, this.qty);
}

const List<_Order> _orderSequence = [
  _Order(_Item.ironPlate, 5),
  _Order(_Item.copperWire, 5),
  _Order(_Item.stoneBrick, 5),
  _Order(_Item.gear, 4),
  _Order(_Item.circuit, 6),
  _Order(_Item.reinforced, 4),
  _Order(_Item.engine, 2),
  _Order(_Item.computer, 2),
  _Order(_Item.rocketPart, 1),
];

class LevelTinyFactory extends LevelWidget {
  const LevelTinyFactory({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelTinyFactory> createState() => _LevelTinyFactoryState();
}

class _LevelTinyFactoryState extends State<LevelTinyFactory>
    with TickerProviderStateMixin {
  final List<List<_OreKind?>> _patches =
      List.generate(_kCols, (_) => List.filled(_kRows, null));
  final List<List<bool>> _rocks =
      List.generate(_kCols, (_) => List.filled(_kRows, false));
  final Map<int, _Machine> _machines = {};
  final List<List<int?>> _occByMachine =
      List.generate(_kCols, (_) => List.filled(_kRows, null));
  final Map<Point<int>, _Belt> _belts = {};
  int _nextId = 1;

  String? _buildMode;
  int _placeRot = 0;
  int _credits = 30;

  int _wealth = 0;
  int _ordersCompleted = 0;
  int _highestTierUnlocked = 1;
  int _beltsPlaced = 0;
  int _orderIndex = 0;
  int _orderProgress = 0;
  double _orderStartT = 0;
  double _bonusTimer = 0;
  bool _bonusActive = false;
  double _elapsed = 0;
  bool _gameOver = false;

  Offset? _beltDragLast;
  List<Point<int>> _beltDragPath = [];
  Offset? _machineDragPos;

  _Machine? _inspect;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _animT = 0;

  double _cellSize = 24;

  late Point<int> _hubAnchor;

  bool _orderPanelOpen = true;

  @override
  void initState() {
    super.initState();
    widget.registerTimeoutBuilder(_buildOutcome);
    _generateMap();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    widget.clearTimeoutBuilder();
    super.dispose();
  }

  void _generateMap() {
    final rng = Random();
    _hubAnchor = const Point(28, 11);
    final hub = _Machine(
      id: _nextId++,
      kind: _MachineKind.hub,
      x: _hubAnchor.x,
      y: _hubAnchor.y,
      rot: 0,
    );
    _machines[hub.id] = hub;
    for (final c in hub.cells()) {
      _occByMachine[c.x][c.y] = hub.id;
    }

    void scatter(_OreKind kind, int patchCount) {
      int placed = 0;
      int tries = 0;
      while (placed < patchCount && tries < 5000) {
        tries++;
        final cx = rng.nextInt(_kCols);
        final cy = rng.nextInt(_kRows);
        if (_isHub(cx, cy)) continue;
        final size = 4 + rng.nextInt(6);
        final cells = <Point<int>>{Point(cx, cy)};
        final frontier = <Point<int>>[Point(cx, cy)];
        while (cells.length < size && frontier.isNotEmpty) {
          final p = frontier[rng.nextInt(frontier.length)];
          final nbrs = [
            Point(p.x + 1, p.y),
            Point(p.x - 1, p.y),
            Point(p.x, p.y + 1),
            Point(p.x, p.y - 1),
          ];
          nbrs.shuffle(rng);
          for (final n in nbrs) {
            if (n.x < 0 || n.x >= _kCols || n.y < 0 || n.y >= _kRows) continue;
            if (_isHub(n.x, n.y)) continue;
            if (_patches[n.x][n.y] != null) continue;
            cells.add(n);
            frontier.add(n);
            if (cells.length >= size) break;
          }
          if (frontier.length > 20) frontier.removeAt(0);
        }
        bool collide = false;
        for (final c in cells) {
          if (_patches[c.x][c.y] != null) {
            collide = true;
            break;
          }
        }
        if (collide) continue;
        for (final c in cells) {
          _patches[c.x][c.y] = kind;
        }
        placed++;
      }
    }

    scatter(_OreKind.iron, 5);
    scatter(_OreKind.copper, 4);
    scatter(_OreKind.coal, 3);
    scatter(_OreKind.stone, 4);

    int rocksPlaced = 0;
    int tries = 0;
    while (rocksPlaced < 36 && tries < 4000) {
      tries++;
      final cx = rng.nextInt(_kCols);
      final cy = rng.nextInt(_kRows);
      if (_isHub(cx, cy)) continue;
      if (_patches[cx][cy] != null) continue;
      if (_rocks[cx][cy]) continue;
      _rocks[cx][cy] = true;
      rocksPlaced++;
    }
  }

  bool _isHub(int x, int y) {
    return x >= _hubAnchor.x &&
        x < _hubAnchor.x + 3 &&
        y >= _hubAnchor.y &&
        y < _hubAnchor.y + 3;
  }

  LevelOutcome _buildOutcome() {
    final score = sqrt((_wealth / 2500).clamp(0.0, 1.0));
    return LevelOutcome(
      score: score,
      metrics: {
        'wealth': _wealth,
        'orders_completed': _ordersCompleted,
        'highest_tier_unlocked': _highestTierUnlocked,
        'belts_placed': _beltsPlaced,
      },
    );
  }

  void _onTick(Duration elapsed) {
    final dtRaw = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _animT = (_animT + dtRaw) % 1000;
    if (_gameOver) {
      if (mounted) setState(() {});
      return;
    }
    final dt = dtRaw.clamp(0.0, 0.05);
    _elapsed += dt;
    _orderStartT += dt;
    if (_bonusActive) {
      _bonusTimer -= dt;
      if (_bonusTimer <= 0) {
        _bonusActive = false;
      }
    }
    _simulate(dt);
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    final cycleMul = _bonusActive ? 0.8 : 1.0;
    const beltStep = 0.7;

    for (final m in _machines.values) {
      if (m.flashT > 0) {
        m.flashT -= dt;
        if (m.flashT <= 0) m.flashRed = false;
      }

      if (m.kind == _MachineKind.miner) {
        if (m.minerOre == null) {
          final cell = m.cells().first;
          final ore = _patches[cell.x][cell.y];
          if (ore == null) continue;
          m.minerOre = ore;
        }
        m.cycleProgress += dt;
        final cycle = 5.0 * cycleMul;
        if (m.cycleProgress >= cycle) {
          m.cycleProgress -= cycle;
          final emitted = m.minerOre!.item;
          if (_emitFromMachine(m, emitted)) {
            m.producedLastCycle++;
          }
        }
        continue;
      }

      if (m.kind == _MachineKind.hub) continue;
      final r = m.recipe;
      if (r == null) continue;
      bool can = true;
      for (final e in r.inputs.entries) {
        if ((m.buffers[e.key] ?? 0) < e.value) {
          can = false;
          break;
        }
      }
      if (!can) {
        m.cycleProgress = 0;
        continue;
      }
      m.cycleProgress += dt;
      final cycle = r.cycleSec * cycleMul;
      if (m.cycleProgress >= cycle) {
        m.cycleProgress -= cycle;
        for (final e in r.inputs.entries) {
          m.buffers[e.key] = (m.buffers[e.key] ?? 0) - e.value;
        }
        if (_emitFromMachine(m, r.output)) {
          m.producedLastCycle++;
        }
      }
    }

    final beltList = _belts.values.toList();
    beltList.shuffle();
    for (final b in beltList) {
      if (b.cooldown > 0) b.cooldown -= dt;
      for (final it in b.items) {
        it.progress += dt / beltStep;
        if (it.progress > 1) it.progress = 1;
      }
      final out = b.items.where((i) => i.progress >= 1).toList();
      for (final it in out) {
        final tx = b.x + b.outDx;
        final ty = b.y + b.outDy;
        if (b.outDx == 0 && b.outDy == 0) continue;
        if (_pushTo(tx, ty, it.item, b.x, b.y)) {
          b.items.remove(it);
        }
      }
      b.items.sort((a, c) => c.progress.compareTo(a.progress));
      for (int i = 1; i < b.items.length; i++) {
        final ahead = b.items[i - 1];
        final me = b.items[i];
        const minGap = 0.34;
        if (ahead.progress - me.progress < minGap) {
          me.progress = ahead.progress - minGap;
          if (me.progress < 0) me.progress = 0;
        }
      }
    }
  }

  bool _emitFromMachine(_Machine m, _Item item) {
    final outs = m.ports().where((p) => !p.isInput).toList();
    if (outs.isEmpty) return false;
    for (int k = 0; k < outs.length; k++) {
      final p = outs[(m.producedLastCycle + k) % outs.length];
      final tx = p.x + p.outDx;
      final ty = p.y + p.outDy;
      if (_pushTo(tx, ty, item, p.x, p.y, fromMachineOutput: true)) {
        return true;
      }
    }
    return false;
  }

  bool _pushTo(int tx, int ty, _Item item, int fromX, int fromY,
      {bool fromMachineOutput = false}) {
    if (tx < 0 || tx >= _kCols || ty < 0 || ty >= _kRows) return false;
    final mid = _occByMachine[tx][ty];
    if (mid != null) {
      final m = _machines[mid]!;
      if (m.kind == _MachineKind.hub) {
        _depositHub(item);
        return true;
      }
      for (final p in m.ports()) {
        if (p.x == tx && p.y == ty && p.isInput) {
          if (p.x + p.outDx == fromX && p.y + p.outDy == fromY) {
            final r = m.recipe;
            if (r != null && r.inputs.containsKey(item)) {
              m.buffers[item] = (m.buffers[item] ?? 0) + 1;
              return true;
            } else {
              m.flashRed = true;
              m.flashT = 0.4;
              return true;
            }
          }
        }
      }
      return false;
    }
    final belt = _belts[Point(tx, ty)];
    if (belt != null) {
      if (belt.items.length >= 3) return false;
      for (final it in belt.items) {
        if (it.progress < 0.34) return false;
      }
      belt.items.add(_BeltItem(item, 0));
      return true;
    }
    return false;
  }

  void _depositHub(_Item item) {
    _wealth += item.value;
    _credits += (item.value / 2).floor();
    final ord = _orderSequence[_orderIndex.clamp(0, _orderSequence.length - 1)];
    if (item == ord.item) {
      _orderProgress++;
      if (_orderProgress >= ord.qty) {
        _completeOrder();
      }
    }
  }

  void _completeOrder() {
    _ordersCompleted++;
    final fast = _orderStartT < 90;
    if (fast) {
      _bonusActive = true;
      _bonusTimer = 600;
    } else {
      _bonusActive = false;
    }
    final ord = _orderSequence[_orderIndex.clamp(0, _orderSequence.length - 1)];
    final completedTier = _tierOf(ord.item);
    if (completedTier + 1 > _highestTierUnlocked) {
      _highestTierUnlocked = (completedTier + 1).clamp(1, 5);
    }
    if (_orderIndex < _orderSequence.length - 1) {
      _orderIndex++;
    }
    _orderProgress = 0;
    _orderStartT = 0;
  }

  int _tierOf(_Item item) {
    switch (item) {
      case _Item.ironOre:
      case _Item.copperOre:
      case _Item.coal:
      case _Item.stone:
        return 0;
      case _Item.ironPlate:
      case _Item.copperWire:
      case _Item.stoneBrick:
        return 1;
      case _Item.gear:
      case _Item.circuit:
        return 2;
      case _Item.reinforced:
        return 3;
      case _Item.engine:
      case _Item.computer:
        return 4;
      case _Item.rocketPart:
        return 5;
    }
  }

  bool _canPlaceMachine(_MachineKind kind, int x, int y, int rot) {
    final fake = _Machine(id: -1, kind: kind, x: x, y: y, rot: rot);
    for (final c in fake.cells()) {
      if (c.x < 0 || c.x >= _kCols || c.y < 0 || c.y >= _kRows) return false;
      if (_rocks[c.x][c.y]) return false;
      if (_occByMachine[c.x][c.y] != null) return false;
      if (_belts.containsKey(c)) return false;
      if (kind == _MachineKind.miner) {
        if (_patches[c.x][c.y] == null) return false;
      } else {
        if (_patches[c.x][c.y] != null) return false;
      }
    }
    return true;
  }

  void _placeMachine(_MachineKind kind, int x, int y, int rot) {
    final spec = _spec(kind);
    if (_credits < spec.cost) return;
    if (!_canPlaceMachine(kind, x, y, rot)) return;
    _credits -= spec.cost;
    final m = _Machine(id: _nextId++, kind: kind, x: x, y: y, rot: rot);
    if (kind == _MachineKind.smelter) {
      m.recipeId = 'plate';
    }
    _machines[m.id] = m;
    for (final c in m.cells()) {
      _occByMachine[c.x][c.y] = m.id;
    }
  }

  void _deleteAt(int x, int y) {
    final mid = _occByMachine[x][y];
    if (mid != null) {
      final m = _machines[mid]!;
      if (m.kind == _MachineKind.hub) return;
      for (final c in m.cells()) {
        _occByMachine[c.x][c.y] = null;
      }
      _machines.remove(mid);
      return;
    }
    final p = Point(x, y);
    final b = _belts[p];
    if (b != null) {
      _belts.remove(p);
      _recomputeBeltOutgoing();
    }
  }

  void _addBelt(int x, int y) {
    final p = Point(x, y);
    if (_belts.containsKey(p)) return;
    if (x < 0 || x >= _kCols || y < 0 || y >= _kRows) return;
    if (_rocks[x][y]) return;
    if (_occByMachine[x][y] != null) return;
    if (_patches[x][y] != null) return;
    _belts[p] = _Belt(x, y);
    _beltsPlaced++;
  }

  void _recomputeBeltOutgoing() {
    for (final b in _belts.values) {
      final candidates = <List<int>>[];
      for (final d in const [
        [1, 0],
        [-1, 0],
        [0, 1],
        [0, -1]
      ]) {
        final nx = b.x + d[0];
        final ny = b.y + d[1];
        if (nx < 0 || nx >= _kCols || ny < 0 || ny >= _kRows) continue;
        if (_belts.containsKey(Point(nx, ny))) {
          candidates.add(d);
          continue;
        }
        final mid = _occByMachine[nx][ny];
        if (mid != null) {
          final m = _machines[mid]!;
          if (m.kind == _MachineKind.hub) {
            candidates.add(d);
            continue;
          }
          for (final p in m.ports()) {
            if (p.x == nx && p.y == ny && p.isInput) {
              if (p.x + p.outDx == b.x && p.y + p.outDy == b.y) {
                candidates.add(d);
                break;
              }
            }
          }
        }
      }
      if (candidates.isEmpty) {
        b.outDx = 0;
        b.outDy = 0;
        continue;
      }
      final stillValid =
          candidates.any((c) => c[0] == b.outDx && c[1] == b.outDy);
      if (stillValid && (b.outDx != 0 || b.outDy != 0)) continue;
      final pick = candidates.firstWhere(
        (c) => !(c[0] == -b.inDx && c[1] == -b.inDy && (b.inDx != 0 || b.inDy != 0)),
        orElse: () => candidates.first,
      );
      b.outDx = pick[0];
      b.outDy = pick[1];
    }
  }

  Point<int>? _cellAt(Offset local) {
    final x = (local.dx / _cellSize).floor();
    final y = (local.dy / _cellSize).floor();
    if (x < 0 || x >= _kCols || y < 0 || y >= _kRows) return null;
    return Point(x, y);
  }

  @override
  Widget build(BuildContext context) {
    final ord = _orderSequence[_orderIndex.clamp(0, _orderSequence.length - 1)];
    return Container(
      color: const Color(0xFF1A1A24),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(ord),
            Expanded(child: _buildMap()),
            _buildBuildBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(_Order ord) {
    final score = sqrt((_wealth / 2500).clamp(0.0, 1.0));
    final hint = _buildMode == null
        ? 'tap a card → tap a tile to place. drag for belts.'
        : _buildMode == 'belt'
            ? 'drag across tiles to lay belts'
            : _buildMode == 'delete'
                ? 'tap a machine or belt to remove'
                : 'tap a tile to place ${_buildMode!} (↻ to rotate)';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: NunuColors.backgroundPaper,
      child: Row(
        children: [
          _stat('💯', score.toStringAsFixed(2)),
          _stat('💰', '$_credits'),
          _stat('💎', '$_wealth'),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              hint,
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 11,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.info_outline,
                color: NunuColors.textSecondary, size: 20),
            onPressed: _showGuide,
          ),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 3),
          Text(value,
              style: const TextStyle(
                  color: NunuColors.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  void _showGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        title: const Text('tiny factory',
            style: TextStyle(color: NunuColors.textPrimary)),
        content: const SingleChildScrollView(
          child: Text(
            'place miners on ore patches. drag belts from output ▶ to input ◀. '
            'tap a card in the build bar to enter placement mode; tap again to exit. '
            'use ↻ to rotate before placing. tap a placed machine to set its recipe. '
            'fill the hub\'s order. higher tier orders unlock as you complete each one.',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('ok')),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return LayoutBuilder(builder: (ctx, c) {
      _cellSize = c.maxWidth / 12;
      final w = _cellSize * _kCols;
      final h = _cellSize * _kRows;
      final inBeltMode = _buildMode == 'belt';
      return Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.6,
              maxScale: 1.4,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(80),
              panEnabled: !inBeltMode,
              scaleEnabled: true,
              child: SizedBox(
                width: w,
                height: h,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapDown: _onTap,
                        onPanStart: inBeltMode ? _onPanStart : null,
                        onPanUpdate: inBeltMode ? _onPanUpdate : null,
                        onPanEnd: inBeltMode ? _onPanEnd : null,
                        child: CustomPaint(
                          painter: _FactoryPainter(
                            cellSize: _cellSize,
                            patches: _patches,
                            rocks: _rocks,
                            machines: _machines.values.toList(),
                            belts: _belts.values.toList(),
                            animT: _animT,
                            buildMode: _buildMode,
                            placeRot: _placeRot,
                            hoverPos: _machineDragPos,
                            beltDragPath: _beltDragPath,
                            order: _orderSequence[
                                _orderIndex.clamp(0, _orderSequence.length - 1)],
                            orderProgress: _orderProgress,
                            hubAnchor: _hubAnchor,
                          ),
                          size: Size(w, h),
                        ),
                      ),
                    ),
                    if (_inspect != null) _buildInspector(),
                  ],
                ),
              ),
            ),
          ),
          Positioned(top: 8, right: 8, child: _buildOrderPanel()),
          if (_buildMode != null && _buildMode != 'belt' && _buildMode != 'delete')
            Positioned(top: 8, left: 8, child: _buildPlacementHud()),
        ],
      );
    });
  }

  Widget _buildOrderPanel() {
    final ord = _orderSequence[_orderIndex.clamp(0, _orderSequence.length - 1)];
    final progress = (_orderProgress / ord.qty).clamp(0.0, 1.0);
    return GestureDetector(
      onTap: () => setState(() => _orderPanelOpen = !_orderPanelOpen),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: _orderPanelOpen ? 200 : 56,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NunuColors.warningMain, width: 1.5),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: _orderPanelOpen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 14)),
                      const SizedBox(width: 6),
                      const Text('hub order',
                          style: TextStyle(
                              color: NunuColors.warningMain,
                              fontSize: 11,
                              fontWeight: FontWeight.w800)),
                      const Spacer(),
                      const Icon(Icons.expand_less,
                          color: NunuColors.textSecondary, size: 16),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'deliver ${ord.qty} ${ord.item.label}',
                    style: const TextStyle(
                        color: NunuColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: NunuColors.backgroundDefault,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                          NunuColors.warningMain),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text('$_orderProgress / ${ord.qty}'
                      '${_bonusActive ? '   ⚡ +25%' : ''}',
                      style: const TextStyle(
                          color: NunuColors.textSecondary, fontSize: 10)),
                  const SizedBox(height: 4),
                  Text('orders done: $_ordersCompleted   tier: $_highestTierUnlocked',
                      style: const TextStyle(
                          color: NunuColors.textSecondary, fontSize: 9)),
                ],
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📦', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text('$_orderProgress/${ord.qty}',
                      style: const TextStyle(
                          color: NunuColors.warningMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w800)),
                ],
              ),
      ),
    );
  }

  Widget _buildPlacementHud() {
    final kind = _kindFromMode(_buildMode!);
    final spec = kind == null ? null : _spec(kind);
    final dirArrow = ['▶', '▼', '◀', '▲'][_placeRot & 3];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: NunuColors.primaryMain),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(spec?.emoji ?? '', style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(spec?.name ?? '',
                  style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800)),
              Text('output ▶ $dirArrow',
                  style: const TextStyle(
                      color: NunuColors.successLight, fontSize: 10)),
            ],
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => _placeRot = (_placeRot + 1) & 3),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryMain),
              ),
              alignment: Alignment.center,
              child: const Text('↻',
                  style: TextStyle(
                      color: NunuColors.primaryLight,
                      fontSize: 22,
                      fontWeight: FontWeight.w800)),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _buildMode = null),
            child: Container(
              width: 30,
              height: 38,
              alignment: Alignment.center,
              child: const Icon(Icons.close,
                  color: NunuColors.textSecondary, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInspector() {
    final m = _inspect!;
    final recipes = _recipesFor(m.kind)
        .where((r) => r.tier <= _highestTierUnlocked)
        .toList();
    final left = (m.x * _cellSize).clamp(0, _kCols * _cellSize - 220);
    final top =
        ((m.y + m.h) * _cellSize).clamp(0, _kRows * _cellSize - 200);
    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NunuColors.primaryMain),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(m.spec.name,
                  style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              if (m.kind == _MachineKind.miner)
                Text('mining: ${m.minerOre?.label ?? '—'}',
                    style: const TextStyle(
                        color: NunuColors.textSecondary, fontSize: 11))
              else if (m.kind == _MachineKind.hub)
                const Text('hub accepts everything',
                    style: TextStyle(
                        color: NunuColors.textSecondary, fontSize: 11))
              else ...[
                const Text('recipe:',
                    style: TextStyle(
                        color: NunuColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 2),
                if (recipes.isEmpty)
                  const Text('no recipes unlocked yet',
                      style: TextStyle(
                          color: NunuColors.errorLight, fontSize: 11))
                else
                  DropdownButton<String>(
                    value: m.recipeId,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: NunuColors.backgroundDefault,
                    style: const TextStyle(
                        color: NunuColors.textPrimary, fontSize: 12),
                    hint: const Text('choose…',
                        style: TextStyle(
                            color: NunuColors.textSecondary, fontSize: 12)),
                    items: [
                      for (final r in recipes)
                        DropdownMenuItem(
                          value: r.id,
                          child: Text(
                              '${r.emoji} ${r.name} (${r.cycleSec.toStringAsFixed(0)}s)'),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        m.recipeId = v;
                        m.cycleProgress = 0;
                      });
                    },
                  ),
                const SizedBox(height: 4),
                Text('buffer: ${_bufferText(m)}',
                    style: const TextStyle(
                        color: NunuColors.textSecondary, fontSize: 10)),
                Text('produced (run): ${m.producedLastCycle}',
                    style: const TextStyle(
                        color: NunuColors.textSecondary, fontSize: 10)),
              ],
              const SizedBox(height: 4),
              Row(children: [
                TextButton(
                  onPressed: () => setState(() => _inspect = null),
                  child: const Text('close'),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  String _bufferText(_Machine m) {
    if (m.buffers.isEmpty) return 'empty';
    return m.buffers.entries
        .where((e) => e.value > 0)
        .map((e) => '${e.key.label}:${e.value}')
        .join(', ');
  }

  void _onTap(TapDownDetails d) {
    final cell = _cellAt(d.localPosition);
    if (cell == null) return;
    if (_inspect != null) {
      setState(() => _inspect = null);
      return;
    }
    if (_buildMode == null) {
      final mid = _occByMachine[cell.x][cell.y];
      if (mid != null) {
        setState(() => _inspect = _machines[mid]);
        return;
      }
      final ore = _patches[cell.x][cell.y];
      if (ore != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${ore.label} patch — place a miner here'),
            duration: const Duration(seconds: 2),
            backgroundColor: NunuColors.backgroundPaper,
          ),
        );
      } else if (_rocks[cell.x][cell.y]) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('rock — unbuildable'),
            duration: Duration(seconds: 1),
            backgroundColor: NunuColors.backgroundPaper,
          ),
        );
      }
      return;
    }
    if (_buildMode == 'delete') {
      setState(() => _deleteAt(cell.x, cell.y));
      return;
    }
    if (_buildMode == 'belt') return;
    final kind = _kindFromMode(_buildMode!);
    if (kind != null) {
      setState(() => _placeMachine(kind, cell.x, cell.y, _placeRot));
    }
  }

  _MachineKind? _kindFromMode(String mode) {
    switch (mode) {
      case 'miner':
        return _MachineKind.miner;
      case 'smelter':
        return _MachineKind.smelter;
      case 'assembler':
        return _MachineKind.assembler;
      case 'constructor':
        return _MachineKind.constructor;
    }
    return null;
  }

  void _onPanStart(DragStartDetails d) {
    if (_buildMode != 'belt') return;
    _beltDragLast = d.localPosition;
    final c = _cellAt(d.localPosition);
    if (c != null) _beltDragPath = [c];
  }

  void _onPanUpdate(DragUpdateDetails d) {
    if (_buildMode != 'belt') return;
    final c = _cellAt(d.localPosition);
    if (c == null) return;
    if (_beltDragPath.isEmpty || _beltDragPath.last != c) {
      final last = _beltDragPath.isEmpty ? c : _beltDragPath.last;
      var cx = last.x;
      var cy = last.y;
      while (cx != c.x) {
        cx += (c.x > cx) ? 1 : -1;
        _beltDragPath.add(Point(cx, cy));
      }
      while (cy != c.y) {
        cy += (c.y > cy) ? 1 : -1;
        _beltDragPath.add(Point(cx, cy));
      }
      setState(() {});
    }
    _beltDragLast = d.localPosition;
  }

  void _onPanEnd(DragEndDetails d) {
    if (_buildMode != 'belt') return;
    for (int i = 0; i < _beltDragPath.length; i++) {
      final p = _beltDragPath[i];
      _addBelt(p.x, p.y);
    }
    for (int i = 0; i < _beltDragPath.length; i++) {
      final p = _beltDragPath[i];
      final b = _belts[p];
      if (b == null) continue;
      if (i + 1 < _beltDragPath.length) {
        final n = _beltDragPath[i + 1];
        b.outDx = n.x - p.x;
        b.outDy = n.y - p.y;
      }
      if (i > 0) {
        final prev = _beltDragPath[i - 1];
        b.inDx = prev.x - p.x;
        b.inDy = prev.y - p.y;
      }
    }
    _beltDragPath = [];
    _beltDragLast = null;
    _recomputeBeltOutgoing();
    setState(() {});
  }

  Widget _buildBuildBar() {
    final cards = [
      _BarCard('belt', '➤', 'belt', 0),
      _BarCard('miner', '⛏', 'miner', _minerSpec.cost),
      _BarCard('smelter', '🔥', 'smelter', _smelterSpec.cost),
      _BarCard('assembler', '🔧', 'assembler', _assemblerSpec.cost),
      _BarCard('constructor', '🏭', 'constructor', _constructorSpec.cost),
    ];
    return Container(
      height: 96,
      color: NunuColors.backgroundPaper,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final c in cards) _cardWidget(c),
              ],
            ),
          ),
          _miniButton('↻', () {
            setState(() => _placeRot = (_placeRot + 1) & 3);
          }, active: false),
          _miniButton('🗑', () {
            setState(() {
              _buildMode = _buildMode == 'delete' ? null : 'delete';
              _inspect = null;
            });
          }, active: _buildMode == 'delete'),
        ],
      ),
    );
  }

  Widget _miniButton(String label, VoidCallback onTap, {required bool active}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? NunuColors.primaryMain.withValues(alpha: 0.3)
              : NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active
                  ? NunuColors.primaryMain
                  : NunuColors.primaryDark.withValues(alpha: 0.4)),
        ),
        alignment: Alignment.center,
        child: Text(label, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _cardWidget(_BarCard c) {
    final active = _buildMode == c.mode;
    final canAfford = _credits >= c.cost;
    return GestureDetector(
      onTap: () {
        setState(() {
          _buildMode = active ? null : c.mode;
          _inspect = null;
        });
      },
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: active
              ? NunuColors.primaryMain.withValues(alpha: 0.25)
              : NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: active
                  ? NunuColors.primaryMain
                  : NunuColors.primaryDark.withValues(alpha: 0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
                opacity: canAfford ? 1 : 0.4,
                child: Text(c.emoji,
                    style: const TextStyle(fontSize: 22, height: 1))),
            const SizedBox(height: 2),
            Text(c.label,
                style: const TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 10,
                    height: 1.1,
                    fontWeight: FontWeight.w700)),
            Text(c.cost == 0 ? 'free' : '\$${c.cost}',
                style: TextStyle(
                    color: canAfford
                        ? NunuColors.textSecondary
                        : NunuColors.errorLight,
                    height: 1.1,
                    fontSize: 9)),
          ],
        ),
      ),
    );
  }
}

class _BarCard {
  final String label;
  final String emoji;
  final String mode;
  final int cost;
  _BarCard(this.label, this.emoji, this.mode, this.cost);
}

class _FactoryPainter extends CustomPainter {
  final double cellSize;
  final List<List<_OreKind?>> patches;
  final List<List<bool>> rocks;
  final List<_Machine> machines;
  final List<_Belt> belts;
  final double animT;
  final String? buildMode;
  final int placeRot;
  final Offset? hoverPos;
  final List<Point<int>> beltDragPath;
  final _Order order;
  final int orderProgress;
  final Point<int> hubAnchor;

  _FactoryPainter({
    required this.cellSize,
    required this.patches,
    required this.rocks,
    required this.machines,
    required this.belts,
    required this.animT,
    required this.buildMode,
    required this.placeRot,
    required this.hoverPos,
    required this.beltDragPath,
    required this.order,
    required this.orderProgress,
    required this.hubAnchor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1A1A24);
    canvas.drawRect(Offset.zero & size, bg);

    final gridLine = Paint()
      ..color = const Color(0xFF26263A)
      ..strokeWidth = 1;
    for (int x = 0; x <= _kCols; x++) {
      canvas.drawLine(Offset(x * cellSize, 0),
          Offset(x * cellSize, _kRows * cellSize), gridLine);
    }
    for (int y = 0; y <= _kRows; y++) {
      canvas.drawLine(Offset(0, y * cellSize),
          Offset(_kCols * cellSize, y * cellSize), gridLine);
    }

    for (int x = 0; x < _kCols; x++) {
      for (int y = 0; y < _kRows; y++) {
        final ore = patches[x][y];
        if (ore != null) {
          final r = Rect.fromLTWH(
              x * cellSize + 1, y * cellSize + 1, cellSize - 2, cellSize - 2);
          canvas.drawRect(
              r, Paint()..color = ore.color.withValues(alpha: 0.35));
          canvas.drawCircle(
              Offset(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2),
              cellSize * 0.12,
              Paint()..color = ore.color);
        }
        if (rocks[x][y]) {
          final r = Rect.fromLTWH(
              x * cellSize + 2, y * cellSize + 2, cellSize - 4, cellSize - 4);
          final rrect = RRect.fromRectAndRadius(r, const Radius.circular(4));
          canvas.drawRRect(
              rrect, Paint()..color = const Color(0xFF55556A));
        }
      }
    }

    for (final b in belts) {
      final r = Rect.fromLTWH(
          b.x * cellSize + 2, b.y * cellSize + 2, cellSize - 4, cellSize - 4);
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      canvas.drawRRect(rr, Paint()..color = const Color(0xFF2C2C40));

      final cx = b.x * cellSize + cellSize / 2;
      final cy = b.y * cellSize + cellSize / 2;
      final hasIn = b.inDx != 0 || b.inDy != 0;
      final hasOut = b.outDx != 0 || b.outDy != 0;

      final body = Paint()
        ..color = const Color(0xFF3F3F58)
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.42
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final bodyPath = Path();
      if (hasIn) {
        bodyPath.moveTo(cx - b.inDx * cellSize / 2, cy - b.inDy * cellSize / 2);
        bodyPath.lineTo(cx, cy);
      }
      if (hasOut) {
        if (!hasIn) bodyPath.moveTo(cx, cy);
        bodyPath.lineTo(cx + b.outDx * cellSize / 2, cy + b.outDy * cellSize / 2);
      }
      if (!hasIn && !hasOut) {
        bodyPath.addOval(
            Rect.fromCircle(center: Offset(cx, cy), radius: cellSize * 0.18));
      }
      canvas.drawPath(bodyPath, body);

      if (hasOut) {
        final chev = Paint()
          ..color = NunuColors.primaryMain
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..strokeCap = StrokeCap.round;
        for (int i = 0; i < 2; i++) {
          final t = ((animT * 1.2 + i / 2) % 1.0);
          double px, py;
          if (t < 0.5 && hasIn) {
            final s = t * 2;
            px = cx - b.inDx * cellSize / 2 * (1 - s);
            py = cy - b.inDy * cellSize / 2 * (1 - s);
          } else {
            final s = hasIn ? (t - 0.5) * 2 : t;
            px = cx + b.outDx * cellSize / 2 * s;
            py = cy + b.outDy * cellSize / 2 * s;
          }
          final dx = b.outDx.toDouble();
          final dy = b.outDy.toDouble();
          final csz = cellSize * 0.14;
          final p = Path();
          if (dx != 0) {
            p.moveTo(px - dx * csz, py - csz);
            p.lineTo(px, py);
            p.lineTo(px - dx * csz, py + csz);
          } else if (dy != 0) {
            p.moveTo(px - csz, py - dy * csz);
            p.lineTo(px, py);
            p.lineTo(px + csz, py - dy * csz);
          }
          canvas.drawPath(p, chev);
        }
      }

      for (final it in b.items) {
        final t = it.progress.clamp(0.0, 1.0);
        double px, py;
        if (t < 0.5 && hasIn) {
          final s = t * 2;
          px = cx - b.inDx * cellSize / 2 * (1 - s);
          py = cy - b.inDy * cellSize / 2 * (1 - s);
        } else if (hasOut) {
          final s = hasIn ? (t - 0.5) * 2 : t;
          px = cx + b.outDx * cellSize / 2 * s;
          py = cy + b.outDy * cellSize / 2 * s;
        } else {
          px = cx;
          py = cy;
        }
        canvas.drawCircle(
            Offset(px, py), cellSize * 0.16, Paint()..color = it.item.color);
        canvas.drawCircle(
            Offset(px, py),
            cellSize * 0.16,
            Paint()
              ..color = Colors.white.withValues(alpha: 0.5)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.2);
      }
    }

    for (final m in machines) {
      _drawMachine(canvas, m);
    }

    if (buildMode == 'belt' && beltDragPath.isNotEmpty) {
      for (final p in beltDragPath) {
        final r = Rect.fromLTWH(p.x * cellSize + 2, p.y * cellSize + 2,
            cellSize - 4, cellSize - 4);
        canvas.drawRect(
            r,
            Paint()
              ..color = NunuColors.primaryMain.withValues(alpha: 0.4));
      }
    }
  }

  void _drawMachine(Canvas canvas, _Machine m) {
    final cells = m.cells();
    int minX = 999, minY = 999, maxX = -1, maxY = -1;
    for (final c in cells) {
      if (c.x < minX) minX = c.x;
      if (c.y < minY) minY = c.y;
      if (c.x > maxX) maxX = c.x;
      if (c.y > maxY) maxY = c.y;
    }
    final r = Rect.fromLTWH(
        minX * cellSize + 2,
        minY * cellSize + 2,
        (maxX - minX + 1) * cellSize - 4,
        (maxY - minY + 1) * cellSize - 4);
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(6));
    Color base;
    if (m.kind == _MachineKind.hub) {
      base = const Color(0xFF3A2D1A);
    } else if (m.kind == _MachineKind.miner) {
      base = const Color(0xFF35384A);
    } else if (m.kind == _MachineKind.smelter) {
      base = const Color(0xFF4A2F2F);
    } else if (m.kind == _MachineKind.assembler) {
      base = const Color(0xFF2F3A4A);
    } else {
      base = const Color(0xFF3A2F4A);
    }
    if (m.flashRed) base = NunuColors.errorMain;
    canvas.drawRRect(rr, Paint()..color = base);
    canvas.drawLine(
        Offset(r.left + 4, r.top + 2),
        Offset(r.right - 4, r.top + 2),
        Paint()
          ..color = Colors.white.withValues(alpha: 0.18)
          ..strokeWidth = 2);
    canvas.drawLine(
        Offset(r.left + 4, r.bottom - 2),
        Offset(r.right - 4, r.bottom - 2),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.4)
          ..strokeWidth = 2);
    if (m.kind == _MachineKind.hub) {
      final pulse = 0.5 + 0.5 * sin(animT * 2 * pi * 1.2);
      final pen = Paint()
        ..color = NunuColors.warningMain.withValues(alpha: 0.5 + 0.5 * pulse)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;
      canvas.drawRRect(rr, pen);
    }
    final tp = TextPainter(
      text: TextSpan(
        text: m.spec.emoji,
        style: TextStyle(fontSize: cellSize * 0.55),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas,
        Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2));

    if (m.recipe != null && m.kind != _MachineKind.miner) {
      final bp = TextPainter(
        text: TextSpan(
          text: m.recipe!.emoji,
          style: const TextStyle(fontSize: 14),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      bp.paint(canvas, Offset(r.right - 16, r.top + 2));
    }

    if (m.kind == _MachineKind.hub) {
      final ot = TextPainter(
        text: TextSpan(
          text: '${order.qty} ${order.item.label}\n$orderProgress/${order.qty}',
          style: const TextStyle(
              fontSize: 10,
              color: NunuColors.warningMain,
              fontWeight: FontWeight.w800,
              height: 1.1),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout(maxWidth: r.width - 4);
      ot.paint(canvas,
          Offset(r.center.dx - ot.width / 2, r.bottom - ot.height - 4));
    }

    for (final p in m.ports()) {
      final px = p.x * cellSize + cellSize / 2;
      final py = p.y * cellSize + cellSize / 2;
      final ex = px + p.outDx * cellSize * 0.42;
      final ey = py + p.outDy * cellSize * 0.42;
      final size = cellSize * 0.16;
      final dirX = p.isInput ? -p.outDx.toDouble() : p.outDx.toDouble();
      final dirY = p.isInput ? -p.outDy.toDouble() : p.outDy.toDouble();
      final perpX = -dirY;
      final perpY = dirX;
      final tipX = ex + dirX * size;
      final tipY = ey + dirY * size;
      final baseAX = ex - dirX * size * 0.4 + perpX * size * 0.8;
      final baseAY = ey - dirY * size * 0.4 + perpY * size * 0.8;
      final baseBX = ex - dirX * size * 0.4 - perpX * size * 0.8;
      final baseBY = ey - dirY * size * 0.4 - perpY * size * 0.8;
      final tri = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(baseAX, baseAY)
        ..lineTo(baseBX, baseBY)
        ..close();
      final color = p.isInput ? NunuColors.infoMain : NunuColors.successMain;
      canvas.drawPath(tri, Paint()..color = color);
      canvas.drawPath(
          tri,
          Paint()
            ..color = Colors.black.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1);
    }
  }

  @override
  bool shouldRepaint(covariant _FactoryPainter oldDelegate) => true;
}
