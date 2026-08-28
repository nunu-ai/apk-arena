import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

const int _kCols = 36;
const int _kRows = 26;
const int _scoreWealthTarget = 8000;
const Duration _sessionDuration = Duration(minutes: 30);

enum _Item {
  ironOre,
  copperOre,
  coal,
  stone,
  ironBar,
  copperBar,
  stoneSlab,
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
      case _Item.ironBar:
        return 'iron bar';
      case _Item.copperBar:
        return 'copper bar';
      case _Item.stoneSlab:
        return 'stone slab';
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

  String get emoji {
    switch (this) {
      case _Item.ironOre:
        return '🪨';
      case _Item.copperOre:
        return '🟧';
      case _Item.coal:
        return '⚫';
      case _Item.stone:
        return '⬜';
      case _Item.ironBar:
      case _Item.copperBar:
      case _Item.stoneSlab:
        return '▰';
      case _Item.ironPlate:
        return '🟫';
      case _Item.copperWire:
        return '🧶';
      case _Item.stoneBrick:
        return '🧱';
      case _Item.gear:
        return '⚙';
      case _Item.circuit:
        return '🟢';
      case _Item.reinforced:
        return '🟪';
      case _Item.engine:
        return '🟡';
      case _Item.computer:
        return '🟦';
      case _Item.rocketPart:
        return '🚀';
    }
  }

  Color get color {
    switch (this) {
      case _Item.ironOre:
      case _Item.ironPlate:
      case _Item.ironBar:
        return const Color(0xFFA8896C);
      case _Item.copperOre:
      case _Item.copperWire:
      case _Item.copperBar:
        return const Color(0xFFC97B5C);
      case _Item.coal:
        return const Color(0xFF3A3A48);
      case _Item.stone:
      case _Item.stoneBrick:
      case _Item.stoneSlab:
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
      case _Item.ironBar:
      case _Item.copperBar:
      case _Item.stoneSlab:
        return 3;
      case _Item.ironPlate:
      case _Item.copperWire:
      case _Item.stoneBrick:
        return 5;
      case _Item.gear:
        return 20;
      case _Item.circuit:
        return 22;
      case _Item.reinforced:
        return 34;
      case _Item.engine:
        return 75;
      case _Item.computer:
        return 135;
      case _Item.rocketPart:
        return 550;
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
    id: 'iron_bar',
    name: 'iron bar',
    emoji: '▰',
    tier: 1,
    inputs: {_Item.ironOre: 1},
    output: _Item.ironBar,
    cycleSec: 5,
  ),
  _Recipe(
    id: 'copper_bar',
    name: 'copper bar',
    emoji: '▰',
    tier: 1,
    inputs: {_Item.copperOre: 1},
    output: _Item.copperBar,
    cycleSec: 5,
  ),
  _Recipe(
    id: 'stone_slab',
    name: 'stone slab',
    emoji: '▰',
    tier: 1,
    inputs: {_Item.stone: 1},
    output: _Item.stoneSlab,
    cycleSec: 5,
  ),
  _Recipe(
    id: 'plate',
    name: 'iron plate',
    emoji: '🟫',
    tier: 2,
    inputs: {_Item.ironBar: 1},
    output: _Item.ironPlate,
    cycleSec: 6,
  ),
  _Recipe(
    id: 'wire',
    name: 'copper wire',
    emoji: '🟧',
    tier: 2,
    inputs: {_Item.copperBar: 1},
    output: _Item.copperWire,
    cycleSec: 6,
  ),
  _Recipe(
    id: 'brick',
    name: 'stone brick',
    emoji: '⬜',
    tier: 2,
    inputs: {_Item.stoneSlab: 1},
    output: _Item.stoneBrick,
    cycleSec: 6,
  ),
  _Recipe(
    id: 'gear',
    name: 'gear',
    emoji: '⚙',
    tier: 3,
    inputs: {_Item.ironPlate: 3},
    output: _Item.gear,
    cycleSec: 15,
  ),
  _Recipe(
    id: 'circuit',
    name: 'circuit',
    emoji: '🟢',
    tier: 3,
    inputs: {_Item.copperWire: 2, _Item.ironPlate: 1},
    output: _Item.circuit,
    cycleSec: 12,
  ),
  _Recipe(
    id: 'reinforced',
    name: 'reinforced plate',
    emoji: '🟪',
    tier: 4,
    inputs: {_Item.ironPlate: 2, _Item.stoneBrick: 3},
    output: _Item.reinforced,
    cycleSec: 18,
  ),
  _Recipe(
    id: 'engine',
    name: 'engine',
    emoji: '🟡',
    tier: 5,
    inputs: {_Item.gear: 2, _Item.ironPlate: 3, _Item.coal: 4},
    output: _Item.engine,
    cycleSec: 45,
  ),
  _Recipe(
    id: 'computer',
    name: 'computer',
    emoji: '🟦',
    tier: 5,
    inputs: {_Item.circuit: 3, _Item.copperWire: 2, _Item.reinforced: 1},
    output: _Item.computer,
    cycleSec: 40,
  ),
  _Recipe(
    id: 'rocket',
    name: 'rocket part',
    emoji: '🚀',
    tier: 6,
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
      return [
        _recipeById('plate')!,
        _recipeById('wire')!,
        _recipeById('brick')!,
        _recipeById('gear')!,
        _recipeById('circuit')!,
        _recipeById('reinforced')!,
      ];
    case _MachineKind.constructor:
      return [
        _recipeById('engine')!,
        _recipeById('computer')!,
        _recipeById('rocket')!,
      ];
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
  const _PortSpec(
    this.dx,
    this.dy,
    this.outDx,
    this.outDy,
    this.isInput,
    this.slot,
  );
}

class _MachineSpec {
  final _MachineKind kind;
  final String name;
  final String emoji;
  final int w;
  final int h;
  final List<_PortSpec> basePorts;
  const _MachineSpec({
    required this.kind,
    required this.name,
    required this.emoji,
    required this.w,
    required this.h,
    required this.basePorts,
  });
}

const _MachineSpec _minerSpec = _MachineSpec(
  kind: _MachineKind.miner,
  name: 'miner',
  emoji: '⛏',
  w: 1,
  h: 1,
  basePorts: [_PortSpec(0, 0, 1, 0, false, 0)],
);
const _MachineSpec _smelterSpec = _MachineSpec(
  kind: _MachineKind.smelter,
  name: 'smelter',
  emoji: '🔥',
  w: 1,
  h: 1,
  basePorts: [_PortSpec(0, 0, -1, 0, true, 0), _PortSpec(0, 0, 1, 0, false, 0)],
);
const _MachineSpec _assemblerSpec = _MachineSpec(
  kind: _MachineKind.assembler,
  name: 'assembler',
  emoji: '🔧',
  w: 2,
  h: 1,
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
  bool waitingForInput = false;
  bool outputBlocked = false;

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

class _PendingPlacement {
  final _MachineKind kind;
  int x;
  int y;
  int rot;

  _PendingPlacement({
    required this.kind,
    required this.x,
    required this.y,
    required this.rot,
  });
}

class _TerrainInspect {
  final Point<int> cell;
  final _OreKind? ore;
  final bool rock;

  const _TerrainInspect({required this.cell, this.ore, this.rock = false});
}

class _BeltInspect {
  final Point<int> cell;

  const _BeltInspect({required this.cell});
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
  const LevelTinyFactory({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelTinyFactory> createState() => _LevelTinyFactoryState();
}

class _LevelTinyFactoryState extends State<LevelTinyFactory>
    with TickerProviderStateMixin {
  final List<List<_OreKind?>> _patches = List.generate(
    _kCols,
    (_) => List.filled(_kRows, null),
  );
  final List<List<bool>> _rocks = List.generate(
    _kCols,
    (_) => List.filled(_kRows, false),
  );
  final Map<int, _Machine> _machines = {};
  final List<List<int?>> _occByMachine = List.generate(
    _kCols,
    (_) => List.filled(_kRows, null),
  );
  final Map<Point<int>, _Belt> _belts = {};
  int _nextId = 1;

  String? _buildMode;
  int _placeRot = 0;
  int _mapRot = 0;
  final Map<_MachineKind, int> _machineInventory = {
    _MachineKind.miner: 4,
    _MachineKind.smelter: 3,
    _MachineKind.assembler: 2,
    _MachineKind.constructor: 1,
    _MachineKind.hub: 0,
  };
  _PendingPlacement? _pendingPlacement;

  int _wealth = 0;
  int _parts = 0;
  int _ordersCompleted = 0;
  int _highestTierUnlocked = 2;
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

  _Machine? _inspect;
  _TerrainInspect? _terrainInspect;
  _BeltInspect? _beltInspect;
  final Map<_Item, List<double>> _hubDeliveryTimes = {};
  int _hubInputsReceived = 0;

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  double _animT = 0;

  double _cellSize = 24;
  final TransformationController _mapController = TransformationController();
  final GlobalKey _mapContentKey = GlobalKey();
  bool _didCenterHub = false;
  _MachineKind? _draggingBuildKind;

  late Point<int> _hubAnchor;

  bool _orderPanelOpen = true;

  bool get _hubUnlocked => _ordersCompleted >= 3 || _highestTierUnlocked >= 4;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(_buildOutcome);
    _generateMap();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    _mapController.dispose();
    widget.clearPartialScoreGetter();
    super.dispose();
  }

  void _generateMap() {
    final rng = SeedService.instance.createRandom();
    _hubAnchor = const Point((_kCols - 3) ~/ 2, (_kRows - 3) ~/ 2);
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
          final pi = rng.nextInt(frontier.length);
          final p = frontier[pi];
          final nbrs = [
            Point(p.x + 1, p.y),
            Point(p.x - 1, p.y),
            Point(p.x, p.y + 1),
            Point(p.x, p.y - 1),
          ];
          nbrs.shuffle(rng);
          bool grew = false;
          for (final n in nbrs) {
            if (n.x < 0 || n.x >= _kCols || n.y < 0 || n.y >= _kRows) continue;
            if (_isHub(n.x, n.y)) continue;
            if (_patches[n.x][n.y] != null) continue;
            // Only count genuinely new cells as growth: `cells` is a set, so a
            // neighbour already in this blob would otherwise be re-added to the
            // frontier forever without ever increasing `cells.length`.
            if (!cells.add(n)) continue;
            frontier.add(n);
            grew = true;
            if (cells.length >= size) break;
          }
          // Drop exhausted frontier cells so the loop always makes progress:
          // each iteration now either grows `cells` (bounded by `size`) or
          // shrinks the frontier. A cell boxed in by the map edge, the hub, or
          // existing patches can never expand, and leaving it in the frontier
          // would otherwise spin forever.
          if (!grew) {
            frontier.removeAt(pi);
          } else if (frontier.length > 20) {
            frontier.removeAt(0);
          }
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
    return x >= _hubAnchor.x - 1 &&
        x < _hubAnchor.x + 4 &&
        y >= _hubAnchor.y - 1 &&
        y < _hubAnchor.y + 4;
  }

  LevelOutcome _buildOutcome() {
    final score = sqrt((_wealth / _scoreWealthTarget).clamp(0.0, 1.0));
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
      m.waitingForInput = false;
      m.outputBlocked = false;
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
          } else {
            m.outputBlocked = true;
          }
        }
        continue;
      }

      if (m.kind == _MachineKind.hub) {
        continue;
      }
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
        m.waitingForInput = true;
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
        } else {
          m.outputBlocked = true;
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

  bool _pushTo(
    int tx,
    int ty,
    _Item item,
    int fromX,
    int fromY, {
    bool fromMachineOutput = false,
  }) {
    if (tx < 0 || tx >= _kCols || ty < 0 || ty >= _kRows) return false;
    final mid = _occByMachine[tx][ty];
    if (mid != null) {
      final m = _machines[mid]!;
      if (m.kind == _MachineKind.hub) {
        for (final p in m.ports()) {
          if (p.x == tx && p.y == ty && p.isInput) {
            if (p.x + p.outDx == fromX && p.y + p.outDy == fromY) {
              _depositHub(item);
              return true;
            }
          }
        }
        return false;
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
              m.flashT = 1.4;
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
    _parts += item.value;
    _hubInputsReceived++;
    final times = _hubDeliveryTimes.putIfAbsent(item, () => <double>[]);
    times.add(_elapsed);
    times.removeWhere((t) => _elapsed - t > 10);
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
      _highestTierUnlocked = (completedTier + 1).clamp(1, 6);
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
      case _Item.ironBar:
      case _Item.copperBar:
      case _Item.stoneSlab:
        return 1;
      case _Item.ironPlate:
      case _Item.copperWire:
      case _Item.stoneBrick:
        return 2;
      case _Item.gear:
      case _Item.circuit:
        return 3;
      case _Item.reinforced:
        return 4;
      case _Item.engine:
      case _Item.computer:
        return 5;
      case _Item.rocketPart:
        return 6;
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
    for (final p in fake.ports()) {
      if (p.isInput) continue;
      final tx = p.x + p.outDx;
      final ty = p.y + p.outDy;
      if (tx < 0 || tx >= _kCols || ty < 0 || ty >= _kRows) return false;
      if (_rocks[tx][ty]) return false;
      if (_occByMachine[tx][ty] != null) return false;
      if (_patches[tx][ty] != null) return false;
    }
    return true;
  }

  void _placeMachine(_MachineKind kind, int x, int y, int rot) {
    if ((_machineInventory[kind] ?? 0) <= 0) return;
    if (!_canPlaceMachine(kind, x, y, rot)) return;
    _machineInventory[kind] = (_machineInventory[kind] ?? 0) - 1;
    final m = _Machine(id: _nextId++, kind: kind, x: x, y: y, rot: rot);
    if (kind == _MachineKind.smelter) {
      m.recipeId = 'iron_bar';
    } else if (kind == _MachineKind.assembler) {
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
      _machineInventory[m.kind] = (_machineInventory[m.kind] ?? 0) + 1;
      _machines.remove(mid);
      _inspect = null;
      _terrainInspect = null;
      _beltInspect = null;
      return;
    }
    final p = Point(x, y);
    final b = _belts[p];
    if (b != null) {
      _belts.remove(p);
      _beltInspect = null;
      _terrainInspect = null;
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
        [0, -1],
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
      final stillValid = candidates.any(
        (c) => c[0] == b.outDx && c[1] == b.outDy,
      );
      if (stillValid && (b.outDx != 0 || b.outDy != 0)) continue;
      final pick = candidates.firstWhere(
        (c) =>
            !(c[0] == -b.inDx &&
                c[1] == -b.inDy &&
                (b.inDx != 0 || b.inDy != 0)),
        orElse: () => candidates.first,
      );
      b.outDx = pick[0];
      b.outDy = pick[1];
    }
  }

  Point<int>? _cellAt(Offset local, Size canvasSize) {
    final mapW = _cellSize * _kCols;
    final mapH = _cellSize * _kRows;
    final c = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final dx = local.dx - c.dx;
    final dy = local.dy - c.dy;
    final angle = -(_mapRot & 3) * pi / 2;
    final unrotated = Offset(
      dx * cos(angle) - dy * sin(angle) + mapW / 2,
      dx * sin(angle) + dy * cos(angle) + mapH / 2,
    );
    final x = (unrotated.dx / _cellSize).floor();
    final y = (unrotated.dy / _cellSize).floor();
    if (x < 0 || x >= _kCols || y < 0 || y >= _kRows) return null;
    return Point(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1A1A24),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildMap()),
            _buildBuildBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final score = sqrt((_wealth / _scoreWealthTarget).clamp(0.0, 1.0));
    return LevelHud(
      timerText: _remainingLabel,
      stageText: 'orders $_ordersCompleted',
      trailing: Text(
        'score ${score.toStringAsFixed(2)} · $_wealth 💎 · $_parts 🔩',
        style: const TextStyle(
          color: NunuColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      infoOnPressed: _showGuide,
    );
  }

  String get _remainingLabel {
    final elapsed = Duration(milliseconds: (_elapsed * 1000).floor());
    final remaining = _sessionDuration - elapsed;
    final clampedRemaining = remaining.isNegative ? Duration.zero : remaining;
    final minutes = clampedRemaining.inMinutes.toString().padLeft(2, '0');
    final seconds = (clampedRemaining.inSeconds % 60).toString().padLeft(
      2,
      '0',
    );
    return '$minutes:$seconds';
  }

  void _showGuide() {
    showModalBottomSheet(
      context: context,
      backgroundColor: NunuColors.backgroundPaper,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.68,
          minChildSize: 0.38,
          maxChildSize: 0.9,
          builder: (ctx, scrollCtrl) => SingleChildScrollView(
            controller: scrollCtrl,
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: NunuColors.textSecondary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                _guideHeader('how to play'),
                _guideBullet('🏛', 'deliver the hub order shown on the map.'),
                _guideBullet(
                  '🛠',
                  'drag a machine from inventory onto a tile, then confirm.',
                ),
                _guideBullet(
                  '↻',
                  'rotate the pending machine or rotate the whole map.',
                ),
                _guideBullet(
                  '➤',
                  'drag belts from outputs to inputs. tap a belt to inspect cargo.',
                ),
                _guideBullet('🗑', 'delete mode removes machines and belts.'),
                const SizedBox(height: 18),
                _guideHeader('production'),
                _guideMachine(_minerSpec, 'mine ore patches into raw ore.'),
                _guideMachine(_smelterSpec, 'refine ore into bars and slabs.'),
                _guideMachine(
                  _assemblerSpec,
                  'make plates, wire, bricks, and early parts.',
                ),
                _guideMachine(
                  _constructorSpec,
                  'build engines, computers, and rocket parts.',
                ),
                const SizedBox(height: 18),
                _guideHeader('recipe chain'),
                _guideBullet('▰', 'ore → smelter → bars/slabs.'),
                _guideBullet(
                  '🟫',
                  'bars/slabs → assembler → plates, wire, bricks, and higher-tier parts.',
                ),
                _guideBullet(
                  '📦',
                  'every hub delivery earns parts; matching order items advance the order.',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _guideHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: NunuColors.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _guideBullet(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(emoji, style: const TextStyle(fontSize: 14)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideMachine(_MachineSpec spec, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NunuColors.primaryMain.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: NunuColors.primaryMain.withValues(alpha: 0.6),
              ),
            ),
            child: Text(spec.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  spec.name,
                  style: const TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  text,
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    return LayoutBuilder(
      builder: (ctx, c) {
        _cellSize = c.maxWidth / 12;
        final w = _cellSize * _kCols;
        final h = _cellSize * _kRows;
        final side = max(w, h);
        if (!_didCenterHub && c.maxHeight > 0) {
          _didCenterHub = true;
          SchedulerBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final mapLeft = (side - w) / 2;
            final mapTop = (side - h) / 2;
            final hubCenter = Offset(
              mapLeft + (_hubAnchor.x + 1.5) * _cellSize,
              mapTop + (_hubAnchor.y + 1.5) * _cellSize,
            );
            _mapController.value = Matrix4.identity()
              ..translate(
                c.maxWidth / 2 - hubCenter.dx,
                c.maxHeight / 2 - hubCenter.dy,
              );
          });
        }
        final inBeltMode = _buildMode == 'belt';
        final inPlacementMode = _pendingPlacement != null;
        return Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                transformationController: _mapController,
                minScale: 0.6,
                maxScale: 1.4,
                constrained: false,
                boundaryMargin: const EdgeInsets.all(80),
                panEnabled: !inBeltMode && !inPlacementMode,
                scaleEnabled: true,
                child: SizedBox(
                  key: _mapContentKey,
                  width: side,
                  height: side,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTapDown: (d) => _onTap(d, Size(side, side)),
                          onPanStart: inBeltMode || inPlacementMode
                              ? (d) => _onPanStart(d, Size(side, side))
                              : null,
                          onPanUpdate: inBeltMode || inPlacementMode
                              ? (d) => _onPanUpdate(d, Size(side, side))
                              : null,
                          onPanEnd: inBeltMode || inPlacementMode
                              ? _onPanEnd
                              : null,
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
                              mapRot: _mapRot,
                              pendingPlacement: _pendingPlacement,
                              beltDragPath: _beltDragPath,
                            ),
                            size: Size(side, side),
                          ),
                        ),
                      ),
                      _buildHubOrderLabel(Size(side, side)),
                      if (_inspect != null) _buildInspector(),
                      if (_terrainInspect != null)
                        _buildTerrainInspector(Size(side, side)),
                      if (_beltInspect != null)
                        _buildBeltInspector(Size(side, side)),
                      if (_pendingPlacement != null)
                        _buildPlacementControls(Size(side, side)),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(top: 8, right: 8, child: _buildOrderPanel()),
            if (_activeModeText != null)
              Positioned(
                top: 8,
                left: 8,
                right: 8,
                child: _buildModeBanner(_activeModeText!),
              ),
          ],
        );
      },
    );
  }

  String? get _activeModeText {
    final pending = _pendingPlacement;
    if (pending != null) {
      return 'building ${_spec(pending.kind).name} mode active';
    }
    if (_buildMode == 'delete') return 'bulk delete mode active';
    if (_buildMode == 'belt') return 'belt build mode active';
    final kind = _buildMode == null ? null : _kindFromMode(_buildMode!);
    if (kind != null) return 'building ${_spec(kind).name} mode active';
    return null;
  }

  Widget _buildModeBanner(String text) {
    final delete = _buildMode == 'delete';
    return Center(
      child: Container(
        padding: const EdgeInsets.only(left: 12, right: 4, top: 5, bottom: 5),
        decoration: BoxDecoration(
          color: (delete ? NunuColors.errorMain : NunuColors.primaryMain)
              .withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _exitBuildMode,
              child: Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubOrderLabel(Size canvasSize) {
    final ord = _orderSequence[_orderIndex.clamp(0, _orderSequence.length - 1)];
    final center = _mapPointToCanvas(
      Offset(
        (_hubAnchor.x + 1.5) * _cellSize,
        (_hubAnchor.y + 1.65) * _cellSize,
      ),
      canvasSize,
    );
    final width = max(82.0, _cellSize * 3.1);
    final left = (center.dx - width / 2).clamp(
      4.0,
      canvasSize.width - width - 4,
    );
    final top = (center.dy - 20).clamp(4.0, canvasSize.height - 44);
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: NunuColors.warningMain.withValues(alpha: 0.8),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${ord.qty} ${ord.item.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: NunuColors.warningMain,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
              Text(
                '$_orderProgress/${ord.qty}',
                maxLines: 1,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 10,
                  color: NunuColors.warningMain,
                  fontWeight: FontWeight.w800,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _exitBuildMode() {
    setState(() {
      _pendingPlacement = null;
      _buildMode = null;
      _beltDragPath = [];
      _beltDragLast = null;
      _terrainInspect = null;
      _beltInspect = null;
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
        padding: EdgeInsets.symmetric(
          horizontal: _orderPanelOpen ? 10 : 6,
          vertical: _orderPanelOpen ? 8 : 6,
        ),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: NunuColors.warningMain, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
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
                      const Text(
                        'hub order',
                        style: TextStyle(
                          color: NunuColors.warningMain,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.expand_less,
                        color: NunuColors.textSecondary,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'deliver ${ord.qty} ${ord.item.label}',
                    style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: NunuColors.backgroundDefault,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        NunuColors.warningMain,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_orderProgress / ${ord.qty}'
                    '${_bonusActive ? '   ⚡ +25%' : ''}',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'orders done: $_ordersCompleted   tier: $_highestTierUnlocked',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 9,
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📦', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$_orderProgress/${ord.qty}',
                      style: const TextStyle(
                        color: NunuColors.warningMain,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildPlacementControls(Size canvasSize) {
    final pending = _pendingPlacement!;
    final valid = _canPlaceMachine(
      pending.kind,
      pending.x,
      pending.y,
      pending.rot,
    );
    final rect = _pendingPlacementRect(pending, canvasSize);
    const button = 36.0;
    final top = (rect.top - button - 8).clamp(
      4.0,
      canvasSize.height - button - 4,
    );
    final left = (rect.left - button - 8).clamp(
      4.0,
      canvasSize.width - button - 4,
    );
    final right = (rect.right + 8).clamp(4.0, canvasSize.width - button - 4);
    final midY = (rect.center.dy - button / 2).clamp(
      4.0,
      canvasSize.height - button - 4,
    );
    final midX = (rect.center.dx - button / 2).clamp(
      4.0,
      canvasSize.width - button - 4,
    );
    return Stack(
      children: [
        Positioned(
          left: midX,
          top: top,
          child: _placementButton(
            icon: Icons.rotate_90_degrees_cw,
            color: NunuColors.primaryMain,
            onTap: () => setState(() {
              pending.rot = (pending.rot + 1) & 3;
              _placeRot = pending.rot;
            }),
          ),
        ),
        Positioned(
          left: right,
          top: midY,
          child: _placementButton(
            icon: Icons.check,
            color: valid ? NunuColors.successMain : NunuColors.errorMain,
            onTap: valid ? _confirmPendingPlacement : null,
          ),
        ),
        Positioned(
          left: left,
          top: midY,
          child: _placementButton(
            icon: Icons.close,
            color: NunuColors.errorMain,
            onTap: _cancelPendingPlacement,
          ),
        ),
      ],
    );
  }

  Widget _placementButton({
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: enabled
              ? color.withValues(alpha: 0.9)
              : NunuColors.backgroundDefault.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Rect _pendingPlacementRect(_PendingPlacement pending, Size canvasSize) {
    final fake = _Machine(
      id: -1,
      kind: pending.kind,
      x: pending.x,
      y: pending.y,
      rot: pending.rot,
    );
    final cells = fake.cells();
    var minX = cells.first.x;
    var minY = cells.first.y;
    var maxX = cells.first.x;
    var maxY = cells.first.y;
    for (final c in cells) {
      minX = min(minX, c.x);
      minY = min(minY, c.y);
      maxX = max(maxX, c.x);
      maxY = max(maxY, c.y);
    }
    final topLeft = _mapPointToCanvas(
      Offset(minX * _cellSize, minY * _cellSize),
      canvasSize,
    );
    final bottomRight = _mapPointToCanvas(
      Offset((maxX + 1) * _cellSize, (maxY + 1) * _cellSize),
      canvasSize,
    );
    return Rect.fromLTRB(
      min(topLeft.dx, bottomRight.dx),
      min(topLeft.dy, bottomRight.dy),
      max(topLeft.dx, bottomRight.dx),
      max(topLeft.dy, bottomRight.dy),
    );
  }

  Offset _mapPointToCanvas(Offset point, Size canvasSize) {
    final mapCenter = Offset(_kCols * _cellSize / 2, _kRows * _cellSize / 2);
    final canvasCenter = Offset(canvasSize.width / 2, canvasSize.height / 2);
    final dx = point.dx - mapCenter.dx;
    final dy = point.dy - mapCenter.dy;
    final angle = (_mapRot & 3) * pi / 2;
    return Offset(
      canvasCenter.dx + dx * cos(angle) - dy * sin(angle),
      canvasCenter.dy + dx * sin(angle) + dy * cos(angle),
    );
  }

  void _confirmPendingPlacement() {
    final pending = _pendingPlacement;
    if (pending == null) return;
    setState(() {
      _placeMachine(pending.kind, pending.x, pending.y, pending.rot);
      _pendingPlacement = null;
      _buildMode = null;
      _terrainInspect = null;
      _beltInspect = null;
    });
  }

  void _cancelPendingPlacement() {
    setState(() {
      _pendingPlacement = null;
      _buildMode = null;
      _terrainInspect = null;
      _beltInspect = null;
    });
  }

  Widget _buildInspector() {
    final m = _inspect!;
    final recipes = _recipesFor(
      m.kind,
    ).where((r) => r.tier <= _highestTierUnlocked).toList();
    final recipe = m.recipe;
    final left = (m.x * _cellSize).clamp(0, _kCols * _cellSize - 220);
    final top = ((m.y + m.h) * _cellSize).clamp(0, _kRows * _cellSize - 200);
    return Positioned(
      left: left.toDouble(),
      top: top.toDouble(),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 220,
          padding: const EdgeInsets.fromLTRB(8, 8, 6, 8),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NunuColors.primaryMain),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      m.spec.name,
                      style: const TextStyle(
                        color: NunuColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _inspect = null),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: Icon(
                        Icons.close,
                        color: NunuColors.textSecondary,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (m.kind == _MachineKind.miner)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'mining: ${m.minerOre?.label ?? '—'}',
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'ratio: 1 ${m.minerOre?.item.label ?? 'ore'} / 5s',
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                )
              else if (m.kind == _MachineKind.hub)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'input-only delivery hub',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                    Text(
                      'in: $_hubInputsReceived total',
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 4),
                    ..._buildHubRateRows(),
                  ],
                )
              else ...[
                const Text(
                  'recipe:',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                if (recipes.isEmpty)
                  const Text(
                    'no recipes unlocked yet',
                    style: TextStyle(
                      color: NunuColors.errorLight,
                      fontSize: 11,
                    ),
                  )
                else
                  DropdownButton<String>(
                    value: m.recipeId,
                    isDense: true,
                    isExpanded: true,
                    dropdownColor: NunuColors.backgroundDefault,
                    style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 12,
                    ),
                    hint: const Text(
                      'choose…',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    items: [
                      for (final r in recipes)
                        DropdownMenuItem(
                          value: r.id,
                          child: Text(
                            '${r.emoji} ${r.name} (${r.cycleSec.toStringAsFixed(0)}s)',
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        m.recipeId = v;
                        m.cycleProgress = 0;
                      });
                    },
                  ),
                if (recipe != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'needs: ${_recipeInputsText(recipe)}',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    'makes: 1 ${recipe.output.label} / ${recipe.cycleSec.toStringAsFixed(0)}s',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'buffer: ${_bufferText(m)}',
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'produced (run): ${m.producedLastCycle}',
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 10,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTerrainInspector(Size canvasSize) {
    final info = _terrainInspect!;
    final ore = info.ore;
    final title = ore != null ? '${ore.label} patch' : 'rock';
    final subtitle = ore != null ? 'place a miner here' : 'unbuildable';
    final color = ore?.color ?? const Color(0xFF9CA3AF);
    final anchor = _mapPointToCanvas(
      Offset((info.cell.x + 0.5) * _cellSize, (info.cell.y + 0.5) * _cellSize),
      canvasSize,
    );
    final left = (anchor.dx + 12).clamp(4.0, canvasSize.width - 160);
    final top = (anchor.dy - 20).clamp(4.0, canvasSize.height - 72);
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 156,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: color),
                ),
                alignment: Alignment.center,
                child: Icon(
                  ore != null ? Icons.grain : Icons.terrain,
                  color: color,
                  size: 15,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NunuColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      subtitle,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeltInspector(Size canvasSize) {
    final info = _beltInspect!;
    final belt = _belts[info.cell];
    if (belt == null) return const SizedBox.shrink();
    final counts = <_Item, int>{};
    for (final item in belt.items) {
      counts[item.item] = (counts[item.item] ?? 0) + 1;
    }
    final cargo = counts.isEmpty
        ? 'empty'
        : counts.entries
              .map(
                (e) => e.value == 1 ? e.key.label : '${e.value} ${e.key.label}',
              )
              .join(', ');
    final direction = _directionLabel(belt.outDx, belt.outDy);
    final anchor = _mapPointToCanvas(
      Offset((info.cell.x + 0.5) * _cellSize, (info.cell.y + 0.5) * _cellSize),
      canvasSize,
    );
    final left = (anchor.dx + 12).clamp(4.0, canvasSize.width - 168);
    final top = (anchor.dy - 20).clamp(4.0, canvasSize.height - 76);
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {},
        child: Container(
          width: 164,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: NunuColors.primaryMain, width: 1.4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: NunuColors.primaryMain),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.double_arrow,
                  color: NunuColors.primaryLight,
                  size: 15,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'conveyor belt',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: NunuColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'cargo: $cargo',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    Text(
                      'output: $direction',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
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

  List<Widget> _buildHubRateRows() {
    _pruneHubRates();
    final entries =
        _hubDeliveryTimes.entries
            .where((e) => e.value.isNotEmpty)
            .map((e) => MapEntry(e.key, e.value.length / 10.0))
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    if (entries.isEmpty) {
      return const [
        Text(
          'rates: no recent deliveries',
          style: TextStyle(color: NunuColors.textSecondary, fontSize: 10),
        ),
      ];
    }
    return [
      const Text(
        'input rate, last 10s:',
        style: TextStyle(color: NunuColors.textSecondary, fontSize: 10),
      ),
      for (final e in entries.take(5))
        Text(
          '${e.key.emoji} ${e.key.label}: ${e.value.toStringAsFixed(1)}/s',
          style: const TextStyle(color: NunuColors.textSecondary, fontSize: 10),
        ),
    ];
  }

  void _pruneHubRates() {
    for (final times in _hubDeliveryTimes.values) {
      times.removeWhere((t) => _elapsed - t > 10);
    }
  }

  String _recipeInputsText(_Recipe recipe) {
    return recipe.inputs.entries
        .map((e) => '${e.value} ${e.key.label}')
        .join(' + ');
  }

  String _directionLabel(int dx, int dy) {
    if (dx > 0) return 'east';
    if (dx < 0) return 'west';
    if (dy > 0) return 'south';
    if (dy < 0) return 'north';
    return 'none';
  }

  void _onTap(TapDownDetails d, Size canvasSize) {
    final cell = _cellAt(d.localPosition, canvasSize);
    if (cell == null) return;
    final pending = _pendingPlacement;
    if (pending != null) {
      setState(() {
        pending.x = cell.x;
        pending.y = cell.y;
      });
      return;
    }
    if (_inspect != null) {
      setState(() {
        _inspect = null;
        _terrainInspect = null;
        _beltInspect = null;
      });
      return;
    }
    if (_buildMode == null) {
      final mid = _occByMachine[cell.x][cell.y];
      if (mid != null) {
        setState(() {
          _inspect = _machines[mid];
          _terrainInspect = null;
          _beltInspect = null;
        });
        return;
      }
      if (_belts.containsKey(cell)) {
        setState(() {
          _beltInspect = _BeltInspect(cell: cell);
          _terrainInspect = null;
        });
        return;
      }
      final ore = _patches[cell.x][cell.y];
      if (ore != null) {
        setState(() {
          _terrainInspect = _TerrainInspect(cell: cell, ore: ore);
          _beltInspect = null;
        });
      } else if (_rocks[cell.x][cell.y]) {
        setState(() {
          _terrainInspect = _TerrainInspect(cell: cell, rock: true);
          _beltInspect = null;
        });
      } else {
        setState(() {
          _terrainInspect = null;
          _beltInspect = null;
        });
      }
      return;
    }
    if (_buildMode == 'delete') {
      setState(() => _deleteAt(cell.x, cell.y));
      return;
    }
    if (_buildMode == 'belt') return;
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
      case 'hub':
        return _MachineKind.hub;
    }
    return null;
  }

  void _onPanStart(DragStartDetails d, Size canvasSize) {
    if (_pendingPlacement != null) {
      final c = _cellAt(d.localPosition, canvasSize);
      if (c != null) {
        setState(() {
          _pendingPlacement!
            ..x = c.x
            ..y = c.y;
        });
      }
      return;
    }
    if (_buildMode != 'belt') return;
    _beltDragLast = d.localPosition;
    final c = _cellAt(d.localPosition, canvasSize);
    if (c != null) _beltDragPath = [c];
  }

  void _onPanUpdate(DragUpdateDetails d, Size canvasSize) {
    if (_pendingPlacement != null) {
      final c = _cellAt(d.localPosition, canvasSize);
      if (c != null) {
        setState(() {
          _pendingPlacement!
            ..x = c.x
            ..y = c.y;
        });
      }
      return;
    }
    if (_buildMode != 'belt') return;
    final c = _cellAt(d.localPosition, canvasSize);
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
    if (_pendingPlacement != null) return;
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
      _BarCard('belt', '➤', 'belt'),
      _BarCard('miner', '⛏', 'miner', _MachineKind.miner),
      _BarCard('smelter', '🔥', 'smelter', _MachineKind.smelter),
      _BarCard('assembler', '🔧', 'assembler', _MachineKind.assembler),
      _BarCard('constructor', '🏭', 'constructor', _MachineKind.constructor),
      if (_hubUnlocked || (_machineInventory[_MachineKind.hub] ?? 0) > 0)
        _BarCard('hub', '🏛', 'hub', _MachineKind.hub),
    ];
    return Container(
      height: 112,
      color: NunuColors.backgroundPaper,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _miniButton(Icons.screen_rotation_alt, () {
                setState(() => _mapRot = (_mapRot + 1) & 3);
              }, active: _mapRot != 0),
              _miniButton(Icons.delete_outline, () {
                setState(() {
                  _pendingPlacement = null;
                  _buildMode = _buildMode == 'delete' ? null : 'delete';
                  _inspect = null;
                  _terrainInspect = null;
                  _beltInspect = null;
                });
              }, active: _buildMode == 'delete'),
              _miniButton(
                Icons.precision_manufacturing_outlined,
                _showCraftMenu,
                active: false,
              ),
            ],
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [for (final c in cards) _cardWidget(c)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniButton(
    IconData icon,
    VoidCallback onTap, {
    required bool active,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: active
              ? NunuColors.primaryMain.withValues(alpha: 0.3)
              : NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? NunuColors.primaryMain
                : NunuColors.primaryDark.withValues(alpha: 0.4),
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: active ? NunuColors.primaryLight : NunuColors.textSecondary,
          size: 18,
        ),
      ),
    );
  }

  Widget _cardWidget(_BarCard c) {
    final active = _buildMode == c.mode;
    final count = c.kind == null ? null : (_machineInventory[c.kind!] ?? 0);
    final available = count == null || count > 0;
    return GestureDetector(
      onTap: () {
        setState(() {
          _inspect = null;
          _terrainInspect = null;
          _beltInspect = null;
          if (c.kind == null) {
            _pendingPlacement = null;
            _buildMode = active ? null : c.mode;
          } else if (available) {
            _pendingPlacement = null;
            _buildMode = active ? null : c.mode;
          }
        });
      },
      onPanStart: c.kind != null && available
          ? (d) {
              _draggingBuildKind = c.kind;
              _moveDraggedMachine(d.globalPosition);
            }
          : null,
      onPanUpdate: c.kind != null && available
          ? (d) => _moveDraggedMachine(d.globalPosition)
          : null,
      onPanEnd: c.kind != null && available
          ? (_) => setState(() => _draggingBuildKind = null)
          : null,
      onPanCancel: c.kind != null && available
          ? () => setState(() => _draggingBuildKind = null)
          : null,
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
                : NunuColors.primaryDark.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Opacity(
              opacity: available ? 1 : 0.35,
              child: Text(
                c.emoji,
                style: const TextStyle(fontSize: 22, height: 1),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              c.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: NunuColors.textPrimary,
                fontSize: 9,
                height: 1.1,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              count == null ? 'free' : 'x$count',
              style: TextStyle(
                color: available
                    ? NunuColors.textSecondary
                    : NunuColors.errorLight,
                height: 1.1,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _beginPlacement(_MachineKind kind) {
    _beginPlacementAt(
      kind,
      Point((_hubAnchor.x - 2).clamp(0, _kCols - 1), _hubAnchor.y),
    );
  }

  void _beginPlacementAt(_MachineKind kind, Point<int> cell) {
    _buildMode = _spec(kind).name;
    _pendingPlacement = _PendingPlacement(
      kind: kind,
      x: cell.x,
      y: cell.y,
      rot: _placeRot,
    );
  }

  void _moveDraggedMachine(Offset globalPosition) {
    final kind = _draggingBuildKind;
    if (kind == null) return;
    final cell = _cellAtGlobal(globalPosition);
    if (cell == null) return;
    setState(() {
      final pending = _pendingPlacement;
      if (pending == null || pending.kind != kind) {
        _beginPlacementAt(kind, cell);
      } else {
        pending
          ..x = cell.x
          ..y = cell.y;
      }
      _terrainInspect = null;
      _beltInspect = null;
    });
  }

  Point<int>? _cellAtGlobal(Offset globalPosition) {
    final box = _mapContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return null;
    return _cellAt(box.globalToLocal(globalPosition), box.size);
  }

  void _showCraftMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: NunuColors.backgroundPaper,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, sheetSetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'craft machines',
                  style: TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                if (!_hubUnlocked)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'extra hubs unlock after more orders',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                for (final kind in [
                  _MachineKind.miner,
                  _MachineKind.smelter,
                  _MachineKind.assembler,
                  _MachineKind.constructor,
                  if (_hubUnlocked) _MachineKind.hub,
                ])
                  _craftTile(ctx, kind, sheetSetState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _craftTile(
    BuildContext ctx,
    _MachineKind kind,
    StateSetter sheetSetState,
  ) {
    final cost = _craftCost(kind);
    final canCraft = _parts >= cost;
    return ListTile(
      dense: true,
      leading: Text(_spec(kind).emoji, style: const TextStyle(fontSize: 20)),
      title: Text(
        _spec(kind).name,
        style: const TextStyle(color: NunuColors.textPrimary),
      ),
      subtitle: Text(
        'inventory: ${_machineInventory[kind] ?? 0}   cost: $cost parts',
        style: const TextStyle(color: NunuColors.textSecondary),
      ),
      trailing: IconButton(
        icon: Icon(
          Icons.add_circle_outline,
          color: canCraft
              ? NunuColors.primaryLight
              : NunuColors.textSecondary.withValues(alpha: 0.45),
        ),
        onPressed: canCraft
            ? () {
                setState(() {
                  _parts -= cost;
                  _machineInventory[kind] = (_machineInventory[kind] ?? 0) + 1;
                });
                sheetSetState(() {});
              }
            : null,
      ),
    );
  }

  int _craftCost(_MachineKind kind) {
    switch (kind) {
      case _MachineKind.miner:
        return 32;
      case _MachineKind.smelter:
        return 40;
      case _MachineKind.assembler:
        return 64;
      case _MachineKind.constructor:
        return 112;
      case _MachineKind.hub:
        return 180;
    }
  }
}

class _BarCard {
  final String label;
  final String emoji;
  final String mode;
  final _MachineKind? kind;
  _BarCard(this.label, this.emoji, this.mode, [this.kind]);
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
  final int mapRot;
  final _PendingPlacement? pendingPlacement;
  final List<Point<int>> beltDragPath;

  _FactoryPainter({
    required this.cellSize,
    required this.patches,
    required this.rocks,
    required this.machines,
    required this.belts,
    required this.animT,
    required this.buildMode,
    required this.placeRot,
    required this.mapRot,
    required this.pendingPlacement,
    required this.beltDragPath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = const Color(0xFF1A1A24);
    canvas.drawRect(Offset.zero & size, bg);

    final mapW = _kCols * cellSize;
    final mapH = _kRows * cellSize;
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate((mapRot & 3) * pi / 2);
    canvas.translate(-mapW / 2, -mapH / 2);

    final gridLine = Paint()
      ..color = const Color(0xFF26263A)
      ..strokeWidth = 1;
    for (int x = 0; x <= _kCols; x++) {
      canvas.drawLine(
        Offset(x * cellSize, 0),
        Offset(x * cellSize, _kRows * cellSize),
        gridLine,
      );
    }
    for (int y = 0; y <= _kRows; y++) {
      canvas.drawLine(
        Offset(0, y * cellSize),
        Offset(_kCols * cellSize, y * cellSize),
        gridLine,
      );
    }

    for (int x = 0; x < _kCols; x++) {
      for (int y = 0; y < _kRows; y++) {
        final ore = patches[x][y];
        if (ore != null) {
          final r = Rect.fromLTWH(
            x * cellSize + 1,
            y * cellSize + 1,
            cellSize - 2,
            cellSize - 2,
          );
          canvas.drawRect(
            r,
            Paint()..color = ore.color.withValues(alpha: 0.35),
          );
          canvas.drawCircle(
            Offset(x * cellSize + cellSize / 2, y * cellSize + cellSize / 2),
            cellSize * 0.12,
            Paint()..color = ore.color,
          );
        }
        if (rocks[x][y]) {
          final r = Rect.fromLTWH(
            x * cellSize + 2,
            y * cellSize + 2,
            cellSize - 4,
            cellSize - 4,
          );
          final rrect = RRect.fromRectAndRadius(r, const Radius.circular(4));
          canvas.drawRRect(rrect, Paint()..color = const Color(0xFF55556A));
        }
      }
    }

    final beltByCell = <Point<int>, _Belt>{};
    for (final b in belts) {
      beltByCell[Point(b.x, b.y)] = b;
    }
    final upstreamDir = <Point<int>, List<int>>{};
    for (final m in machines) {
      for (final p in m.ports()) {
        if (p.isInput) continue;
        final tx = p.x + p.outDx;
        final ty = p.y + p.outDy;
        final key = Point(tx, ty);
        if (beltByCell.containsKey(key)) {
          upstreamDir[key] = [-p.outDx, -p.outDy];
        }
      }
    }
    for (final b in belts) {
      if (b.outDx == 0 && b.outDy == 0) continue;
      final key = Point(b.x + b.outDx, b.y + b.outDy);
      if (beltByCell.containsKey(key)) {
        upstreamDir[key] = [-b.outDx, -b.outDy];
      }
    }

    for (final b in belts) {
      final cell = Point(b.x, b.y);
      final up = upstreamDir[cell];
      final hasUp = up != null;
      final hasOut = b.outDx != 0 || b.outDy != 0;
      final connected = hasUp && hasOut;
      final orphan = !hasUp && !hasOut;

      Color tileColor;
      Color bodyColor;
      if (connected) {
        tileColor = const Color(0xFF2C2C40);
        bodyColor = const Color(0xFF3F3F58);
      } else if (orphan) {
        tileColor = const Color(0xFF3A1F22);
        bodyColor = const Color(0xFF6E2C2C);
      } else {
        tileColor = const Color(0xFF3A2E1F);
        bodyColor = const Color(0xFF7A5A2A);
      }

      final r = Rect.fromLTWH(
        b.x * cellSize + 2,
        b.y * cellSize + 2,
        cellSize - 4,
        cellSize - 4,
      );
      final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
      canvas.drawRRect(rr, Paint()..color = tileColor);
      if (!connected) {
        final pulse = 0.55 + 0.45 * sin(animT * 2 * pi * 1.6);
        canvas.drawRRect(
          rr,
          Paint()
            ..color = (orphan ? NunuColors.errorMain : NunuColors.warningMain)
                .withValues(alpha: 0.55 * pulse)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0,
        );
      }

      final cx = b.x * cellSize + cellSize / 2;
      final cy = b.y * cellSize + cellSize / 2;

      final body = Paint()
        ..color = bodyColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = cellSize * 0.42
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final bodyPath = Path();
      if (hasUp) {
        bodyPath.moveTo(cx + up[0] * cellSize / 2, cy + up[1] * cellSize / 2);
        bodyPath.lineTo(cx, cy);
      }
      if (hasOut) {
        if (!hasUp) bodyPath.moveTo(cx, cy);
        bodyPath.lineTo(
          cx + b.outDx * cellSize / 2,
          cy + b.outDy * cellSize / 2,
        );
      }
      if (orphan) {
        bodyPath.addOval(
          Rect.fromCircle(center: Offset(cx, cy), radius: cellSize * 0.18),
        );
      }
      canvas.drawPath(bodyPath, body);

      if (!connected) {
        final markColor = orphan
            ? NunuColors.errorMain
            : NunuColors.warningMain;
        if (!hasUp && hasOut) {
          final ex = cx - b.outDx * cellSize * 0.36;
          final ey = cy - b.outDy * cellSize * 0.36;
          _drawDeadEnd(canvas, Offset(ex, ey), cellSize * 0.13, markColor);
        }
        if (hasUp && !hasOut) {
          final ex = cx - up[0] * cellSize * 0.36;
          final ey = cy - up[1] * cellSize * 0.36;
          _drawDeadEnd(canvas, Offset(ex, ey), cellSize * 0.13, markColor);
        }
        if (orphan) {
          _drawDeadEnd(canvas, Offset(cx, cy), cellSize * 0.16, markColor);
        }
      }
    }

    for (final b in belts) {
      _drawBeltChevrons(canvas, b);
    }

    for (final b in belts) {
      for (final it in b.items) {
        final t = it.progress.clamp(0.0, 1.0);
        final pos = _beltPathPoint(b, t);
        canvas.drawCircle(pos, cellSize * 0.16, Paint()..color = it.item.color);
        canvas.drawCircle(
          pos,
          cellSize * 0.16,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
    }

    for (final m in machines) {
      _drawMachine(canvas, m);
    }

    final pending = pendingPlacement;
    if (pending != null) {
      _drawPendingPlacement(canvas, pending);
    }

    if (buildMode == 'belt' && beltDragPath.isNotEmpty) {
      for (final p in beltDragPath) {
        final r = Rect.fromLTWH(
          p.x * cellSize + 2,
          p.y * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        );
        canvas.drawRect(
          r,
          Paint()..color = NunuColors.primaryMain.withValues(alpha: 0.4),
        );
      }
    }
    canvas.restore();
  }

  Offset _beltPathPoint(_Belt b, double t) {
    final cx = b.x * cellSize + cellSize / 2;
    final cy = b.y * cellSize + cellSize / 2;
    final hasIn = b.inDx != 0 || b.inDy != 0;
    final hasOut = b.outDx != 0 || b.outDy != 0;
    final center = Offset(cx, cy);
    final start = hasIn
        ? Offset(cx + b.inDx * cellSize / 2, cy + b.inDy * cellSize / 2)
        : center;
    final end = hasOut
        ? Offset(cx + b.outDx * cellSize / 2, cy + b.outDy * cellSize / 2)
        : center;
    final clamped = t.clamp(0.0, 1.0);
    if (!hasIn && !hasOut) return center;
    if (!hasIn) return Offset.lerp(center, end, clamped)!;
    if (!hasOut) return Offset.lerp(start, center, clamped)!;
    if (clamped < 0.5) {
      return Offset.lerp(start, center, clamped * 2)!;
    }
    return Offset.lerp(center, end, (clamped - 0.5) * 2)!;
  }

  void _drawDeadEnd(Canvas canvas, Offset c, double radius, Color color) {
    canvas.drawCircle(
      c,
      radius + 1.2,
      Paint()..color = Colors.black.withValues(alpha: 0.7),
    );
    canvas.drawCircle(c, radius, Paint()..color = color);
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;
    final d = radius * 0.55;
    canvas.drawLine(Offset(c.dx - d, c.dy - d), Offset(c.dx + d, c.dy + d), p);
    canvas.drawLine(Offset(c.dx - d, c.dy + d), Offset(c.dx + d, c.dy - d), p);
  }

  void _drawBeltChevrons(Canvas canvas, _Belt b) {
    if (b.outDx == 0 && b.outDy == 0) return;
    final chev = Paint()
      ..color = NunuColors.primaryMain
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 2; i++) {
      final t = ((animT * 1.2 + i / 2) % 1.0);
      final pos = _beltPathPoint(b, t);
      final px = pos.dx;
      final py = pos.dy;
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

  void _drawPendingPlacement(Canvas canvas, _PendingPlacement pending) {
    final fake = _Machine(
      id: -1,
      kind: pending.kind,
      x: pending.x,
      y: pending.y,
      rot: pending.rot,
    );
    bool blocked = fake.cells().any(
      (c) =>
          c.x < 0 ||
          c.x >= _kCols ||
          c.y < 0 ||
          c.y >= _kRows ||
          rocks[c.x][c.y] ||
          machines.any((m) => m.cells().contains(c)) ||
          belts.any((b) => b.x == c.x && b.y == c.y) ||
          (pending.kind == _MachineKind.miner
              ? patches[c.x][c.y] == null
              : patches[c.x][c.y] != null),
    );
    if (!blocked) {
      for (final p in fake.ports()) {
        if (p.isInput) continue;
        final tx = p.x + p.outDx;
        final ty = p.y + p.outDy;
        if (tx < 0 || tx >= _kCols || ty < 0 || ty >= _kRows) {
          blocked = true;
          break;
        }
        if (rocks[tx][ty] ||
            patches[tx][ty] != null ||
            machines.any((m) => m.cells().any((c) => c.x == tx && c.y == ty))) {
          blocked = true;
          break;
        }
      }
    }
    final cells = fake.cells();
    int minX = cells.first.x,
        minY = cells.first.y,
        maxX = cells.first.x,
        maxY = cells.first.y;
    for (final c in cells) {
      minX = min(minX, c.x);
      minY = min(minY, c.y);
      maxX = max(maxX, c.x);
      maxY = max(maxY, c.y);
    }
    final r = Rect.fromLTWH(
      minX * cellSize + 1,
      minY * cellSize + 1,
      (maxX - minX + 1) * cellSize - 2,
      (maxY - minY + 1) * cellSize - 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      Paint()
        ..color = (blocked ? NunuColors.errorMain : NunuColors.successMain)
            .withValues(alpha: 0.28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r, const Radius.circular(6)),
      Paint()
        ..color = blocked ? NunuColors.errorMain : NunuColors.successMain
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );
    _drawMachine(canvas, fake);
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
      (maxY - minY + 1) * cellSize - 4,
    );
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
        ..strokeWidth = 2,
    );
    canvas.drawLine(
      Offset(r.left + 4, r.bottom - 2),
      Offset(r.right - 4, r.bottom - 2),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..strokeWidth = 2,
    );
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
    tp.paint(
      canvas,
      Offset(r.center.dx - tp.width / 2, r.center.dy - tp.height / 2),
    );

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

    final status = _machineStatusText(m);
    if (status != null) {
      final isError = status == '!!';
      final sp = TextPainter(
        text: TextSpan(
          text: status,
          style: TextStyle(
            fontSize: status == 'zzz' ? 10 : 12,
            color: isError ? NunuColors.errorMain : NunuColors.warningMain,
            fontWeight: FontWeight.w900,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final sr = RRect.fromRectAndRadius(
        Rect.fromLTWH(r.left + 3, r.top + 3, sp.width + 6, sp.height + 4),
        const Radius.circular(5),
      );
      canvas.drawRRect(
        sr,
        Paint()..color = Colors.black.withValues(alpha: 0.62),
      );
      sp.paint(canvas, Offset(r.left + 6, r.top + 5));
    }

    for (final p in m.ports()) {
      final px = p.x * cellSize + cellSize / 2;
      final py = p.y * cellSize + cellSize / 2;
      final ex = px + p.outDx * cellSize * 0.46;
      final ey = py + p.outDy * cellSize * 0.46;
      final size = cellSize * 0.21;
      final dirX = p.isInput ? -p.outDx.toDouble() : p.outDx.toDouble();
      final dirY = p.isInput ? -p.outDy.toDouble() : p.outDy.toDouble();
      final perpX = -dirY;
      final perpY = dirX;

      final color = p.isInput
          ? const Color(0xFF4DD0E1)
          : const Color(0xFF4ADE80);
      final glowColor = p.isInput
          ? const Color(0xFF00E5FF)
          : const Color(0xFF22FF88);

      final pulse = 0.6 + 0.4 * sin(animT * 2 * pi * 1.4);

      canvas.drawCircle(
        Offset(ex, ey),
        size * 1.55,
        Paint()..color = glowColor.withValues(alpha: 0.22 * pulse),
      );
      canvas.drawCircle(
        Offset(ex, ey),
        size * 1.15,
        Paint()..color = Colors.black.withValues(alpha: 0.55),
      );
      canvas.drawCircle(
        Offset(ex, ey),
        size * 1.15,
        Paint()
          ..color = glowColor.withValues(alpha: 0.9)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );

      final tipX = ex + dirX * size * 0.95;
      final tipY = ey + dirY * size * 0.95;
      final baseAX = ex - dirX * size * 0.55 + perpX * size * 0.85;
      final baseAY = ey - dirY * size * 0.55 + perpY * size * 0.85;
      final baseBX = ex - dirX * size * 0.55 - perpX * size * 0.85;
      final baseBY = ey - dirY * size * 0.55 - perpY * size * 0.85;
      final tri = Path()
        ..moveTo(tipX, tipY)
        ..lineTo(baseAX, baseAY)
        ..lineTo(baseBX, baseBY)
        ..close();
      canvas.drawPath(
        tri,
        Paint()
          ..color = Colors.black.withValues(alpha: 0.85)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      canvas.drawPath(tri, Paint()..color = color);
      canvas.drawPath(
        tri,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }
  }

  String? _machineStatusText(_Machine m) {
    if (m.kind == _MachineKind.hub) return null;
    if (m.flashRed) return '!!';
    if (m.outputBlocked) return '!!';
    if (m.kind == _MachineKind.miner) return m.outputBlocked ? '!!' : null;
    if (m.recipe == null || m.waitingForInput) return 'zzz';
    return null;
  }

  @override
  bool shouldRepaint(covariant _FactoryPainter oldDelegate) => true;
}
