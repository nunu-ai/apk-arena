import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

enum _TowerKind { dart, ice, boomerang, tack, sniper, ninja }

enum _BloonKind { normal, elite, camo }

class _TowerSpec {
  const _TowerSpec({
    required this.kind,
    required this.name,
    required this.emoji,
    required this.cost,
    required this.upgCost,
    required this.range,
    required this.damage,
    required this.cooldownMs,
    required this.color,
    required this.blurb,
  });

  final _TowerKind kind;
  final String name;
  final String emoji;
  final int cost;
  final int upgCost;
  final double range;
  final int damage;
  final int cooldownMs;
  final Color color;
  final String blurb;
}

const Map<_TowerKind, _TowerSpec> _towerSpecs = {
  _TowerKind.dart: _TowerSpec(
    kind: _TowerKind.dart,
    name: 'dart',
    emoji: '🎯',
    cost: 70,
    upgCost: 45,
    range: 2.2,
    damage: 11,
    cooldownMs: 460,
    color: Color(0xFFE55CD8),
    blurb: 'cheap single-target',
  ),
  _TowerKind.ice: _TowerSpec(
    kind: _TowerKind.ice,
    name: 'ice',
    emoji: '❄',
    cost: 110,
    upgCost: 70,
    range: 1.9,
    damage: 4,
    cooldownMs: 850,
    color: Color(0xFF7EE7F6),
    blurb: 'aoe slow',
  ),
  _TowerKind.boomerang: _TowerSpec(
    kind: _TowerKind.boomerang,
    name: 'boom',
    emoji: '🪃',
    cost: 130,
    upgCost: 85,
    range: 2.6,
    damage: 16,
    cooldownMs: 1100,
    color: Color(0xFFFFAB00),
    blurb: 'pierces 4 enemies',
  ),
  _TowerKind.tack: _TowerSpec(
    kind: _TowerKind.tack,
    name: 'tack',
    emoji: '✴',
    cost: 90,
    upgCost: 60,
    range: 1.5,
    damage: 7,
    cooldownMs: 380,
    color: Color(0xFFBA9EF7),
    blurb: 'short-range splash',
  ),
  _TowerKind.sniper: _TowerSpec(
    kind: _TowerKind.sniper,
    name: 'sniper',
    emoji: '🦅',
    cost: 210,
    upgCost: 140,
    range: 999,
    damage: 46,
    cooldownMs: 1300,
    color: Color(0xFF22C55E),
    blurb: 'infinite range',
  ),
  _TowerKind.ninja: _TowerSpec(
    kind: _TowerKind.ninja,
    name: 'ninja',
    emoji: '🥷',
    cost: 175,
    upgCost: 115,
    range: 2.4,
    damage: 20,
    cooldownMs: 420,
    color: Color(0xFFFF5630),
    blurb: 'camo specialist — prioritizes camouflaged bloons',
  ),
};

// per-tier upgrade descriptions (tier 1..5)
const Map<_TowerKind, List<String>> _upgradeDescs = {
  _TowerKind.dart: [
    '+50% damage',
    '−20% cooldown',
    '+0.4 range',
    '+70% damage',
    'master fletcher: +100% damage',
  ],
  _TowerKind.ice: [
    'deeper slow (50%)',
    'larger splash radius',
    'longer freeze duration',
    '+0.5 range',
    'permafrost: 2× slow duration',
  ],
  _TowerKind.boomerang: [
    '+1 pierce target',
    '−15% cooldown',
    '+1 pierce target',
    '+50% damage',
    '+2 pierce, −20% cooldown',
  ],
  _TowerKind.tack: [
    '−20% cooldown',
    '+50% damage',
    '+0.4 splash radius',
    '−25% cooldown',
    'shockwave: +0.5 splash, +40% damage',
  ],
  _TowerKind.sniper: [
    '+60% damage',
    '−20% cooldown',
    'sees & hits camo bloons',
    '+80% damage',
    'orbital: ×2 damage',
  ],
  _TowerKind.ninja: [
    '+50% damage',
    '−20% cooldown',
    'shuriken pierces 2 enemies',
    '+40% damage, +50% vs camo',
    'shadow clone: +1 pierce, −20% cooldown',
  ],
};

class _Tower {
  _Tower({required this.kind, required this.cell});

  final _TowerKind kind;
  final Point<int> cell;
  int tier = 0;
  double cooldownLeft = 0;

  _TowerSpec get spec => _towerSpecs[kind]!;

  double get range {
    switch (kind) {
      case _TowerKind.sniper:
        return spec.range;
      case _TowerKind.dart:
        return spec.range + (tier >= 3 ? 0.4 : 0);
      case _TowerKind.ice:
        return spec.range + (tier >= 4 ? 0.5 : 0);
      case _TowerKind.boomerang:
        return spec.range;
      case _TowerKind.tack:
        return spec.range;
      case _TowerKind.ninja:
        return spec.range;
    }
  }

  int get damage {
    final base = spec.damage;
    switch (kind) {
      case _TowerKind.dart:
        var d = base.toDouble();
        if (tier >= 1) d *= 1.5;
        if (tier >= 4) d *= 1.7;
        if (tier >= 5) d *= 2.0;
        return d.round();
      case _TowerKind.ice:
        return base;
      case _TowerKind.boomerang:
        var d = base.toDouble();
        if (tier >= 4) d *= 1.5;
        return d.round();
      case _TowerKind.tack:
        var d = base.toDouble();
        if (tier >= 2) d *= 1.5;
        if (tier >= 5) d *= 1.4;
        return d.round();
      case _TowerKind.sniper:
        var d = base.toDouble();
        if (tier >= 1) d *= 1.6;
        if (tier >= 4) d *= 1.8;
        if (tier >= 5) d *= 2.0;
        return d.round();
      case _TowerKind.ninja:
        var d = base.toDouble();
        if (tier >= 1) d *= 1.5;
        if (tier >= 4) d *= 1.4;
        return d.round();
    }
  }

  int get cooldownMs {
    final base = spec.cooldownMs.toDouble();
    switch (kind) {
      case _TowerKind.dart:
        return (base * (tier >= 2 ? 0.8 : 1)).round();
      case _TowerKind.ice:
        return base.round();
      case _TowerKind.boomerang:
        var c = base;
        if (tier >= 2) c *= 0.85;
        if (tier >= 5) c *= 0.8;
        return c.round();
      case _TowerKind.tack:
        var c = base;
        if (tier >= 1) c *= 0.8;
        if (tier >= 4) c *= 0.75;
        return c.round();
      case _TowerKind.sniper:
        return (base * (tier >= 2 ? 0.8 : 1)).round();
      case _TowerKind.ninja:
        var c = base;
        if (tier >= 2) c *= 0.8;
        if (tier >= 5) c *= 0.8;
        return c.round();
    }
  }

  double get splash {
    if (kind == _TowerKind.tack) {
      return 1.4 + (tier >= 3 ? 0.4 : 0) + (tier >= 5 ? 0.5 : 0);
    }
    if (kind == _TowerKind.ice) {
      return 1.6 + (tier >= 2 ? 0.4 : 0);
    }
    return 0;
  }

  int get pierce {
    if (kind == _TowerKind.boomerang) {
      return 4 +
          (tier >= 1 ? 1 : 0) +
          (tier >= 3 ? 1 : 0) +
          (tier >= 5 ? 2 : 0);
    }
    if (kind == _TowerKind.ninja) {
      var p = 1;
      if (tier >= 3) p = 2;
      if (tier >= 5) p = 3;
      return p;
    }
    return 1;
  }

  double get slowStrength {
    if (kind != _TowerKind.ice) return 1.0;
    return tier >= 1 ? 0.5 : 0.4;
  }

  double get slowDuration {
    if (kind != _TowerKind.ice) return 0;
    var d = 1.5 + (tier >= 3 ? 0.8 : 0);
    if (tier >= 5) d *= 2.0;
    return d;
  }

  String? get nextUpgradeDesc {
    if (tier >= 5) return null;
    final list = _upgradeDescs[kind];
    if (list == null) return null;
    return list[tier];
  }

  int totalSpent(int baseCost, int upgCost) {
    return baseCost + upgCost * tier;
  }

  int get refund {
    final spent = spec.cost + spec.upgCost * tier;
    return (spent * (0.55 + tier * 0.18)).round();
  }
}

class _Bloon {
  _Bloon({
    required this.kind,
    required this.maxHp,
    required this.speed,
    required this.pathIndex,
    required this.reward,
  }) : hp = maxHp;

  final _BloonKind kind;
  final int maxHp;
  final double speed; // cells per second
  final int pathIndex;
  final int reward;

  double progress = 0; // along waypoint segments (float idx)
  int hp;
  double slowLeft = 0; // seconds remaining
  double slowAmount = 0.4; // 0.4 = 40% slower
  Offset position = Offset.zero;
}

class _Shot {
  _Shot({required this.from, required this.to, required this.color});
  final Offset from;
  final Offset to;
  final Color color;
  double life = 0.13;
}

class _Burst {
  _Burst({required this.center, required this.radius, required this.color});
  final Offset center;
  final double radius;
  final Color color;
  double life = 0.25;
}

class LevelTowerDefense extends LevelWidget {
  const LevelTowerDefense({super.key, required super.onComplete});

  @override
  State<LevelTowerDefense> createState() => _LevelTowerDefenseState();
}

class _LevelTowerDefenseState extends State<LevelTowerDefense>
    with SingleTickerProviderStateMixin {
  static const int _gridCols = 11;
  static const int _gridRows = 16;
  static const int _totalWaves = 24;
  static const double _maxEnemiesBenchmark = 1064;

  // arknights-style: shared paths with entry/exit boxes, more turns.
  static const List<List<Point<int>>> _paths = [
    // path 1 — left entry, snakes through center spine, exits bottom
    [
      Point(1, 0),
      Point(1, 4),
      Point(5, 4),
      Point(5, 8),
      Point(2, 8),
      Point(2, 12),
      Point(5, 12),
      Point(5, 15),
    ],
    // path 2 — right entry, hooks west, merges then exits left
    [
      Point(9, 0),
      Point(9, 2),
      Point(7, 2),
      Point(7, 6),
      Point(5, 6),
      Point(5, 8),
      Point(8, 8),
      Point(8, 12),
      Point(5, 12),
      Point(5, 15),
    ],
    // path 3 — center entry, weaves left, joins central spine
    [
      Point(5, 0),
      Point(5, 4),
      Point(1, 4),
      Point(1, 8),
      Point(2, 8),
      Point(2, 12),
      Point(5, 12),
      Point(5, 15),
    ],
  ];

  // non-buildable terrain (visual rocks, can't place towers)
  static final Set<Point<int>> _terrain = {
    const Point(0, 6), const Point(0, 7),
    const Point(3, 0), const Point(7, 0),
    const Point(10, 4), const Point(10, 12),
    const Point(0, 13), const Point(0, 14),
    const Point(3, 9), const Point(3, 10),
  };

  final Random _random = Random();

  late DateTime _startedAt;
  Ticker? _ticker;
  Duration _lastTick = Duration.zero;

  int _wave = 0; // last completed wave; current wave-1 when running
  int _lives = 25;
  int _cash = 280;
  int _enemiesCleared = 0;
  int _leaks = 0;
  int _streak = 0;

  bool _waveActive = false;
  bool _paused = false;
  bool _fast = false;
  bool _gameOver = false;

  int _spawnsLeft = 0;
  double _spawnTimer = 0;
  double _spawnInterval = 0.7;

  final List<_Tower> _towers = [];
  final List<_Bloon> _bloons = [];
  final List<_Shot> _shots = [];
  final List<_Burst> _bursts = [];

  _Tower? _selected;
  _TowerKind? _dragKind;
  Offset? _dragPos;

  String _status = 'place towers, press ▶ to start wave 1';
  double _animT = 0;

  int get _stage {
    if (_wave + 1 <= 3) return 1;
    if (_wave + 1 <= 7) return 2;
    if (_wave + 1 <= 12) return 3;
    if (_wave + 1 <= 18) return 4;
    return 5;
  }

  int get _activePathCount {
    final s = _stage;
    if (s == 1) return 1;
    if (s == 2) return 2;
    return 3;
  }

  @override
  void initState() {
    super.initState();
    widget.registerTimeoutBuilder(_buildOutcome);
    _startedAt = DateTime.now();
    _ticker = createTicker(_onTick)..start();
  }

  @override
  void dispose() {
    _ticker?.dispose();
    widget.clearTimeoutBuilder();
    super.dispose();
  }

  LevelOutcome _buildOutcome() {
    final score =
        sqrt((_enemiesCleared / _maxEnemiesBenchmark).clamp(0.0, 1.0));
    return LevelOutcome(
      score: score,
      metrics: {
        'enemies_cleared': _enemiesCleared,
        'wave_reached': _wave,
        'leaks': _leaks,
        'lives_left': _lives,
      },
    );
  }

  void _onTick(Duration elapsed) {
    final dtSec = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    _animT = (_animT + dtSec * 0.4) % 1.0;
    if (_gameOver || _paused || !_waveActive) {
      if (mounted) setState(() {}); // keep UI animating
      return;
    }
    final dt = (_fast ? 2.0 : 1.0) * dtSec.clamp(0, 0.05);
    _simulate(dt);
    if (mounted) setState(() {});
  }

  void _simulate(double dt) {
    // spawning
    if (_spawnsLeft > 0) {
      _spawnTimer -= dt;
      while (_spawnTimer <= 0 && _spawnsLeft > 0) {
        _spawnBloon();
        _spawnTimer += _spawnInterval;
        _spawnsLeft--;
      }
    }

    // bloons
    for (final b in _bloons) {
      final speedMul = b.slowLeft > 0 ? (1.0 - b.slowAmount) : 1.0;
      b.slowLeft = max(0, b.slowLeft - dt);
      final path = _paths[b.pathIndex];
      // advance along waypoint segments by world distance
      double remaining = b.speed * speedMul * dt;
      while (remaining > 0 && b.progress < path.length - 1) {
        final i = b.progress.floor();
        final t = b.progress - i;
        final a = path[i];
        final c = (i + 1 < path.length) ? path[i + 1] : path[i];
        final segLen =
            sqrt(pow(c.x - a.x, 2) + pow(c.y - a.y, 2)).toDouble();
        final segLeft = segLen * (1 - t);
        if (remaining >= segLeft) {
          remaining -= segLeft;
          b.progress = (i + 1).toDouble();
        } else {
          b.progress += (remaining / segLen);
          remaining = 0;
        }
      }
      b.position = _bloonWorldCell(b);
      if (b.progress >= path.length - 1) {
        // leak
      }
    }

    // leaks
    final leaked = _bloons.where((b) {
      final path = _paths[b.pathIndex];
      return b.progress >= path.length - 1;
    }).toList();
    for (final b in leaked) {
      _bloons.remove(b);
      _lives--;
      _leaks++;
      _streak = 0;
      if (_lives <= 0) {
        _lives = 0;
        _gameOver = true;
        widget.onComplete(_buildOutcome());
        return;
      }
    }

    // towers shooting
    for (final t in _towers) {
      t.cooldownLeft = max(0, t.cooldownLeft - dt * 1000);
      if (t.cooldownLeft > 0) continue;
      final target = _findTarget(t);
      if (target == null) continue;
      _fireTower(t, target);
      t.cooldownLeft = t.cooldownMs.toDouble();
    }

    // shot/burst fade
    for (final s in _shots) {
      s.life -= dt;
    }
    _shots.removeWhere((s) => s.life <= 0);
    for (final b in _bursts) {
      b.life -= dt;
    }
    _bursts.removeWhere((b) => b.life <= 0);

    // dead bloons
    final dead = _bloons.where((b) => b.hp <= 0).toList();
    for (final b in dead) {
      _bloons.remove(b);
      _enemiesCleared++;
      _cash += b.reward;
    }

    // wave end?
    if (_spawnsLeft == 0 && _bloons.isEmpty && _waveActive) {
      _waveActive = false;
      _wave++;
      _streak++;
      final bonus = 45 + _wave * 4 + _streak * 10;
      _cash += bonus;
      _status = 'wave $_wave clear! +\$$bonus';
      if (_wave >= _totalWaves) {
        _gameOver = true;
        widget.onComplete(_buildOutcome());
      }
    }
  }

  bool _canHitCamo(_Tower t) {
    if (t.kind == _TowerKind.ninja) return true;
    if (t.kind == _TowerKind.sniper && t.tier >= 3) return true;
    return false;
  }

  _Bloon? _findTarget(_Tower t) {
    final towerCenter = _cellCenterFractional(t.cell.x + 0.5, t.cell.y + 0.5);
    final inRange = <_Bloon>[];
    for (final b in _bloons) {
      if (b.kind == _BloonKind.camo && !_canHitCamo(t)) continue;
      final d = (b.position - towerCenter).distance;
      if (d > t.range * _cellSizeCached) continue;
      inRange.add(b);
    }
    if (inRange.isEmpty) return null;

    // ninja prioritizes camo; otherwise pick furthest along path
    if (t.kind == _TowerKind.ninja) {
      final camo = inRange.where((b) => b.kind == _BloonKind.camo).toList();
      if (camo.isNotEmpty) {
        camo.sort((a, b) => b.progress.compareTo(a.progress));
        return camo.first;
      }
    }
    inRange.sort((a, b) => b.progress.compareTo(a.progress));
    return inRange.first;
  }

  int _damageVs(_Tower t, _Bloon b) {
    final base = t.damage;
    if (t.kind == _TowerKind.ninja) {
      // weak vs normal/elite, devastating vs camo
      if (b.kind == _BloonKind.camo) return (base * 2.4).round();
      return (base * 0.6).round().clamp(1, 9999);
    }
    return base;
  }

  void _fireTower(_Tower t, _Bloon target) {
    final from = _cellCenterFractional(t.cell.x + 0.5, t.cell.y + 0.5);

    if (t.kind == _TowerKind.boomerang) {
      final hits = _bloons.toList()
        ..sort((a, b) => (a.position - from)
            .distance
            .compareTo((b.position - from).distance));
      int n = 0;
      Offset prev = from;
      for (final b in hits) {
        if (n >= t.pierce) break;
        if ((b.position - from).distance > t.range * _cellSizeCached) break;
        if (b.kind == _BloonKind.camo && !_canHitCamo(t)) continue;
        _shots.add(_Shot(from: prev, to: b.position, color: t.spec.color));
        prev = b.position;
        b.hp -= _damageVs(t, b);
        n++;
      }
      if (n == 0) {
        _shots.add(
            _Shot(from: from, to: target.position, color: t.spec.color));
      }
      return;
    }

    _shots.add(_Shot(from: from, to: target.position, color: t.spec.color));

    if (t.kind == _TowerKind.ninja && t.pierce > 1) {
      // tier 3 ninja: shuriken pierces two
      final hits = _bloons.toList()
        ..sort((a, b) => (a.position - target.position)
            .distance
            .compareTo((b.position - target.position).distance));
      int n = 0;
      for (final b in hits) {
        if (n >= t.pierce) break;
        if (b.kind == _BloonKind.camo && !_canHitCamo(t)) continue;
        if ((b.position - from).distance > t.range * _cellSizeCached) continue;
        b.hp -= _damageVs(t, b);
        if (b != target) {
          _shots.add(_Shot(from: target.position, to: b.position, color: t.spec.color));
        }
        n++;
      }
      return;
    }

    if (t.splash > 0) {
      _bursts.add(_Burst(
        center: target.position,
        radius: t.splash * _cellSizeCached,
        color: t.spec.color,
      ));
      for (final b in _bloons) {
        if (b.kind == _BloonKind.camo && !_canHitCamo(t)) continue;
        if ((b.position - target.position).distance <=
            t.splash * _cellSizeCached) {
          b.hp -= _damageVs(t, b);
          if (t.kind == _TowerKind.ice) {
            b.slowLeft = max(b.slowLeft, t.slowDuration);
            b.slowAmount = max(b.slowAmount, t.slowStrength);
          }
        }
      }
      return;
    }

    target.hp -= _damageVs(t, target);
  }

  void _spawnBloon() {
    final wave = _wave + 1;
    final stage = _stage;
    final hp = (22 + pow(wave, 1.7) * 5.4 + (stage - 1) * 16).toInt();
    final speed =
        0.90 + min(0.70, wave * 0.024) + (stage - 1) * 0.04;
    final reward = max(4, 10 - wave ~/ 4);
    final pathIdx = _random.nextInt(_activePathCount);

    // index of this spawn within wave: for elite check
    final totalThisWave = _enemiesPerWave(wave);
    final spawnedSoFar = totalThisWave - _spawnsLeft; // before decrement
    bool isElite = wave >= 7 && (spawnedSoFar + 1) % 11 == 0;
    final camoChance = wave >= 8 ? min(0.55, (wave - 8) * 0.065) : 0.0;
    bool isCamo = !isElite && _random.nextDouble() < camoChance;

    _BloonKind kind = _BloonKind.normal;
    int finalHp = hp;
    double finalSpeed = speed;
    int finalReward = reward;
    if (isElite) {
      kind = _BloonKind.elite;
      finalHp = (hp * 2.4).toInt();
      finalSpeed = speed * 0.7;
      finalReward = reward * 3;
    } else if (isCamo) {
      kind = _BloonKind.camo;
    }

    _bloons.add(_Bloon(
      kind: kind,
      maxHp: finalHp,
      speed: finalSpeed,
      pathIndex: pathIdx,
      reward: finalReward,
    ));
  }

  int _enemiesPerWave(int wave) => 10 + wave * 2 + (_stage - 1) * 4;

  void _startWave() {
    if (_waveActive || _gameOver) return;
    if (_wave >= _totalWaves) return;
    final next = _wave + 1;
    _spawnsLeft = _enemiesPerWave(next);
    _spawnInterval = max(0.34, 0.76 - next * 0.015);
    _spawnTimer = 0;
    _waveActive = true;
    _status = 'wave $next';
  }

  // ---------- placement ----------
  Set<Point<int>> _pathCells(int pathIdx) {
    final path = _paths[pathIdx];
    final cells = <Point<int>>{};
    for (int i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final dx = (b.x - a.x).sign;
      final dy = (b.y - a.y).sign;
      var x = a.x;
      var y = a.y;
      while (x != b.x || y != b.y) {
        cells.add(Point(x, y));
        x += dx;
        y += dy;
      }
      cells.add(b);
    }
    return cells;
  }

  bool _isPathCell(int row, int col) {
    // path cells use (x = col-axis index, y = row-axis index)? we're using Point(col, row).
    // Choose convention: Point.x = col, Point.y = row.
    for (int p = 0; p < _paths.length; p++) {
      if (_pathCells(p).contains(Point(col, row))) return true;
    }
    return false;
  }

  bool _isActivePathCell(int row, int col) {
    for (int p = 0; p < _activePathCount; p++) {
      if (_pathCells(p).contains(Point(col, row))) return true;
    }
    return false;
  }

  Set<Point<int>> _entryCells() {
    final s = <Point<int>>{};
    for (int p = 0; p < _activePathCount; p++) {
      s.add(_paths[p].first);
    }
    return s;
  }

  Set<Point<int>> _exitCells() {
    final s = <Point<int>>{};
    for (int p = 0; p < _activePathCount; p++) {
      s.add(_paths[p].last);
    }
    return s;
  }

  // for each cell on an active path, the unit direction(s) of travel through it
  Map<Point<int>, Set<Point<int>>> _pathArrows() {
    final map = <Point<int>, Set<Point<int>>>{};
    for (int p = 0; p < _activePathCount; p++) {
      final path = _paths[p];
      for (int i = 0; i < path.length - 1; i++) {
        final a = path[i];
        final b = path[i + 1];
        final dx = (b.x - a.x).sign;
        final dy = (b.y - a.y).sign;
        var x = a.x;
        var y = a.y;
        while (x != b.x || y != b.y) {
          map.putIfAbsent(Point(x, y), () => {}).add(Point(dx, dy));
          x += dx;
          y += dy;
        }
        map.putIfAbsent(Point(x, y), () => {}).add(Point(dx, dy));
      }
    }
    return map;
  }

  bool _isBuildable(int row, int col) {
    if (row < 0 || row >= _gridRows || col < 0 || col >= _gridCols) {
      return false;
    }
    if (_isActivePathCell(row, col)) return false;
    if (_isPathCell(row, col)) return false; // future paths blocked too
    if (_terrain.contains(Point(col, row))) return false;
    for (final t in _towers) {
      if (t.cell.x == col && t.cell.y == row) return false;
    }
    return true;
  }

  // ---------- coords ----------
  double _cellSizeCached = 24;

  Offset _cellCenterFractional(double col, double row) {
    return Offset(col * _cellSizeCached, row * _cellSizeCached);
  }

  Offset _bloonWorldCell(_Bloon b) {
    final path = _paths[b.pathIndex];
    final i = b.progress.floor();
    final t = b.progress - i;
    final a = path[i];
    final c = (i + 1 < path.length) ? path[i + 1] : path[i];
    final col = a.x + (c.x - a.x) * t + 0.5;
    final row = a.y + (c.y - a.y) * t + 0.5;
    return _cellCenterFractional(col, row);
  }

  // ---------- UI ----------

  void _placeTower(_TowerKind kind, int row, int col) {
    final spec = _towerSpecs[kind]!;
    if (_cash < spec.cost) {
      _status = 'not enough cash';
      return;
    }
    if (!_isBuildable(row, col)) {
      _status = 'cannot place there';
      return;
    }
    _cash -= spec.cost;
    _towers.add(_Tower(kind: kind, cell: Point(col, row)));
    _status = '${spec.name} placed';
  }

  void _upgradeSelected() {
    final t = _selected;
    if (t == null) return;
    if (t.tier >= 5) {
      _status = 'max tier';
      return;
    }
    if (_cash < t.spec.upgCost) {
      _status = 'not enough cash';
      return;
    }
    _cash -= t.spec.upgCost;
    t.tier++;
    _status = '${t.spec.name} → tier ${t.tier}';
  }

  void _sellSelected() {
    final t = _selected;
    if (t == null) return;
    _cash += t.refund;
    _towers.remove(t);
    _selected = null;
    _status = 'sold (+\$${t.refund})';
  }

  Point<int>? _cellAt(Offset local, double cellSize) {
    final col = (local.dx / cellSize).floor();
    final row = (local.dy / cellSize).floor();
    if (row < 0 || row >= _gridRows || col < 0 || col >= _gridCols) return null;
    return Point(col, row);
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
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.4,
          builder: (ctx, scrollCtrl) {
            return SingleChildScrollView(
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
                  _guideBullet(
                      '🛠', 'drag a tower from the bar onto an empty tile.'),
                  _guideBullet(
                      '⬆', 'tap a placed tower to view & buy upgrades.'),
                  _guideBullet('▶', 'press play to start the next wave.'),
                  _guideBullet('⏱', 'game pauses between waves — plan freely.'),
                  _guideBullet('💰',
                      'cash from kills + wave-clear streak bonuses.'),
                  const SizedBox(height: 18),
                  _guideHeader('towers'),
                  ..._towerSpecs.values.map(_guideTower),
                  const SizedBox(height: 18),
                  _guideHeader('enemies'),
                  _guideEnemy(
                    color: NunuColors.errorMain,
                    name: 'bloon',
                    desc: 'standard enemy. health and speed scale each wave.',
                  ),
                  _guideEnemy(
                    color: Colors.deepOrangeAccent,
                    name: 'elite',
                    desc:
                        'every 11th spawn from wave 7+. tougher and slower, but pays out 3× cash.',
                  ),
                  _guideEnemy(
                    color: const Color(0xFF8FBC8F),
                    name: 'camo',
                    desc:
                        'invisible to most towers from wave 8+. ninjas hunt them on sight; the sniper learns to spot them at tier 3.',
                  ),
                ],
              ),
            );
          },
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
          letterSpacing: 0.4,
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
                  color: NunuColors.textSecondary, fontSize: 13, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideTower(_TowerSpec s) {
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
              color: s.color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: s.color.withValues(alpha: 0.6)),
            ),
            child: Text(s.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      s.name,
                      style: const TextStyle(
                          color: NunuColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '\$${s.cost}',
                      style: const TextStyle(
                          color: NunuColors.warningMain,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Text(
                  s.blurb,
                  style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 12,
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guideEnemy(
      {required Color color, required String name, required String desc}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 2, right: 10),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w800),
                ),
                Text(
                  desc,
                  style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 12,
                      height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderStat(String emoji, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(
              color: color ?? NunuColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  String get _elapsedLabel {
    final e = DateTime.now().difference(_startedAt);
    final m = e.inMinutes.toString().padLeft(2, '0');
    final s = (e.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Widget _buildTowerCard(_TowerKind kind) {
    final spec = _towerSpecs[kind]!;
    final canAfford = _cash >= spec.cost;
    return LongPressDraggable<_TowerKind>(
      data: kind,
      delay: const Duration(milliseconds: 60),
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: () {
        setState(() {
          _dragKind = kind;
          _selected = null;
        });
      },
      onDragEnd: (_) {
        setState(() {
          _dragKind = null;
          _dragPos = null;
        });
      },
      feedback: Material(
        color: Colors.transparent,
        child: _towerChip(spec, opacity: 0.9, scale: 1.1),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _towerChip(spec)),
      child: Opacity(
        opacity: canAfford ? 1 : 0.5,
        child: _towerChip(spec),
      ),
    );
  }

  Widget _towerChip(_TowerSpec spec,
      {double opacity = 1, double scale = 1}) {
    return Transform.scale(
      scale: scale,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: spec.color.withValues(alpha: 0.18 * opacity),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: spec.color.withValues(alpha: 0.7)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(spec.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 2),
            Text('\$${spec.cost}',
                style: const TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
          child: Column(
            children: [
              Row(
                children: [
                  _buildHeaderStat('💰', '\$$_cash'),
                  _buildHeaderStat(
                    '❤️',
                    '$_lives',
                    color: _lives <= 5 ? NunuColors.errorMain : null,
                  ),
                  _buildHeaderStat('🌊', '$_wave/$_totalWaves'),
                  _buildHeaderStat('⏱', _elapsedLabel),
                  const Spacer(),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.info_outline,
                        color: NunuColors.textSecondary, size: 22),
                    onPressed: _showGuide,
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 32, minHeight: 32),
                    icon: Icon(
                      _waveActive
                          ? (_paused ? Icons.play_arrow : Icons.pause)
                          : Icons.play_arrow,
                      color: NunuColors.primaryLight,
                      size: 24,
                    ),
                    onPressed: () {
                      if (_gameOver) return;
                      if (!_waveActive) {
                        _startWave();
                      } else {
                        _paused = !_paused;
                      }
                    },
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _fast = !_fast),
                    child: Container(
                      margin: const EdgeInsets.only(left: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: _fast
                            ? NunuColors.primaryMain.withValues(alpha: 0.3)
                            : NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('2×',
                          style: TextStyle(
                              color: NunuColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 12)),
                    ),
                  ),
                ],
              ),
              if (_status.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _status,
                    style: const TextStyle(
                        color: NunuColors.textSecondary, fontSize: 11),
                  ),
                ),
              const SizedBox(height: 4),
              Expanded(child: _buildBoard()),
              const SizedBox(height: 6),
              if (_selected != null)
                _buildTowerPanel()
              else
                SizedBox(
                  height: 72,
                  child: Row(
                    children: [
                      for (final k in _TowerKind.values)
                        Expanded(child: _buildTowerCard(k)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTowerPanel() {
    final t = _selected!;
    final desc = t.nextUpgradeDesc;
    final canAfford = _cash >= t.spec.upgCost && t.tier < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.spec.color.withValues(alpha: 0.6)),
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t.spec.emoji, style: const TextStyle(fontSize: 28)),
              Text('tier ${t.tier}/5',
                  style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (desc != null)
                  Text(
                    'next: $desc',
                    style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  const Text(
                    'fully upgraded',
                    style: TextStyle(
                        color: NunuColors.warningMain,
                        fontSize: 12,
                        fontWeight: FontWeight.w700),
                  ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 36,
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: t.tier >= 5
                                ? NunuColors.backgroundDefault
                                : NunuColors.primaryMain,
                            disabledBackgroundColor:
                                NunuColors.backgroundDefault,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onPressed: (t.tier >= 5 || !canAfford)
                              ? null
                              : _upgradeSelected,
                          child: Text(
                            t.tier >= 5
                                ? 'MAX'
                                : '⬆ UPGRADE  \$${t.spec.upgCost}',
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _sellSelected,
                        child: Container(
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color:
                                NunuColors.errorMain.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                                color: NunuColors.errorMain
                                    .withValues(alpha: 0.6)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('💸',
                                  style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 4),
                              Text(
                                '\$${t.refund}',
                                style: const TextStyle(
                                    color: NunuColors.textPrimary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(builder: (context, c) {
      final cellW = c.maxWidth / _gridCols;
      final cellH = c.maxHeight / _gridRows;
      final cellSize = min(cellW, cellH);
      _cellSizeCached = cellSize;
      final w = cellSize * _gridCols;
      final h = cellSize * _gridRows;

      return Center(
        child: SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                      onTapDown: (d) {
                        final cell = _cellAt(d.localPosition, cellSize);
                        if (cell == null) return;
                        // tap tower?
                        for (final t in _towers) {
                          if (t.cell == cell) {
                            setState(() => _selected = t);
                            return;
                          }
                        }
                        setState(() => _selected = null);
                      },
                      child: CustomPaint(
                        painter: _TDPainter(
                          cellSize: cellSize,
                          gridCols: _gridCols,
                          gridRows: _gridRows,
                          paths: _paths,
                          activePathCount: _activePathCount,
                          stage: _stage,
                          towers: _towers,
                          bloons: _bloons,
                          shots: _shots,
                          bursts: _bursts,
                          selected: _selected,
                          isPathCell: _isPathCell,
                          isActivePathCell: _isActivePathCell,
                          isBuildable: _isBuildable,
                          entries: _entryCells(),
                          exits: _exitCells(),
                          arrows: _pathArrows(),
                          activePaths: _paths.sublist(0, _activePathCount),
                          pulseT: _animT,
                          terrain: _terrain,
                          showPreview: !_waveActive,
                        ),
                        size: Size(w, h),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: _DragLayer(
                      cellSize: cellSize,
                      onDrop: (kind, local) {
                        final cell = _cellAt(local, cellSize);
                        if (cell == null) return;
                        setState(() {
                          _placeTower(kind, cell.y, cell.x);
                        });
                      },
                      onHover: (local) {
                        setState(() {
                          _dragPos = local;
                        });
                      },
                      dragKind: _dragKind,
                      dragPos: _dragPos,
                      isBuildable: _isBuildable,
                      gridCols: _gridCols,
                      gridRows: _gridRows,
                      towerSpecs: _towerSpecs,
                    ),
                  ),
            ],
          ),
        ),
      );
    });
  }
}

class _DragLayer extends StatelessWidget {
  const _DragLayer({
    required this.cellSize,
    required this.onDrop,
    required this.onHover,
    required this.dragKind,
    required this.dragPos,
    required this.isBuildable,
    required this.gridCols,
    required this.gridRows,
    required this.towerSpecs,
  });

  final double cellSize;
  final void Function(_TowerKind, Offset local) onDrop;
  final void Function(Offset local) onHover;
  final _TowerKind? dragKind;
  final Offset? dragPos;
  final bool Function(int row, int col) isBuildable;
  final int gridCols;
  final int gridRows;
  final Map<_TowerKind, _TowerSpec> towerSpecs;

  @override
  Widget build(BuildContext context) {
    return DragTarget<_TowerKind>(
      onMove: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(d.offset);
        onHover(local);
      },
      onAcceptWithDetails: (d) {
        final box = context.findRenderObject() as RenderBox?;
        if (box == null) return;
        final local = box.globalToLocal(d.offset);
        onDrop(d.data, local);
      },
      builder: (ctx, _, __) {
        final showHover = dragKind != null && dragPos != null;
        if (!showHover) return const SizedBox.shrink();
        final col = (dragPos!.dx / cellSize).floor();
        final row = (dragPos!.dy / cellSize).floor();
        if (row < 0 || row >= gridRows || col < 0 || col >= gridCols) {
          return const SizedBox.shrink();
        }
        final ok = isBuildable(row, col);
        final spec = towerSpecs[dragKind]!;
        return Stack(children: [
          Positioned(
            left: col * cellSize,
            top: row * cellSize,
            width: cellSize,
            height: cellSize,
            child: Container(
              decoration: BoxDecoration(
                color: (ok ? NunuColors.successMain : NunuColors.errorMain)
                    .withValues(alpha: 0.3),
                border: Border.all(
                  color: ok ? NunuColors.successMain : NunuColors.errorMain,
                  width: 2,
                ),
              ),
            ),
          ),
          if (ok)
            Positioned(
              left: col * cellSize + cellSize / 2 - spec.range * cellSize,
              top: row * cellSize + cellSize / 2 - spec.range * cellSize,
              width: spec.range * cellSize * 2,
              height: spec.range * cellSize * 2,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: spec.color.withValues(alpha: 0.6), width: 1),
                  ),
                ),
              ),
            ),
        ]);
      },
    );
  }
}

class _TDPainter extends CustomPainter {
  _TDPainter({
    required this.cellSize,
    required this.gridCols,
    required this.gridRows,
    required this.paths,
    required this.activePathCount,
    required this.stage,
    required this.towers,
    required this.bloons,
    required this.shots,
    required this.bursts,
    required this.selected,
    required this.isPathCell,
    required this.isActivePathCell,
    required this.isBuildable,
    required this.entries,
    required this.exits,
    required this.arrows,
    required this.activePaths,
    required this.pulseT,
    required this.terrain,
    required this.showPreview,
  });

  final double cellSize;
  final int gridCols;
  final int gridRows;
  final List<List<Point<int>>> paths;
  final int activePathCount;
  final int stage;
  final List<_Tower> towers;
  final List<_Bloon> bloons;
  final List<_Shot> shots;
  final List<_Burst> bursts;
  final _Tower? selected;
  final bool Function(int, int) isPathCell;
  final bool Function(int, int) isActivePathCell;
  final bool Function(int, int) isBuildable;
  final Set<Point<int>> entries;
  final Set<Point<int>> exits;
  final Map<Point<int>, Set<Point<int>>> arrows;
  final List<List<Point<int>>> activePaths;
  final double pulseT;
  final Set<Point<int>> terrain;
  final bool showPreview;

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()..color = NunuColors.backgroundDefault;
    canvas.drawRect(Offset.zero & size, bg);

    // cells
    for (int r = 0; r < gridRows; r++) {
      for (int c = 0; c < gridCols; c++) {
        final rect = Rect.fromLTWH(
            c * cellSize, r * cellSize, cellSize, cellSize);
        final p = Point(c, r);
        final isEntry = entries.contains(p);
        final isExit = exits.contains(p);
        final isPath = isPathCell(r, c);
        final isActive = isActivePathCell(r, c);
        Color color;
        if (isEntry) {
          color = const Color(0xFF2D5A3D);
        } else if (isExit) {
          color = const Color(0xFF5A2D3D);
        } else if (isActive) {
          color = const Color(0xFF2A274A);
        } else if (isPath) {
          color = const Color(0xFF1E1C38);
        } else if (isBuildable(r, c)) {
          color = ((r + c) % 2 == 0)
              ? NunuColors.backgroundPaper.withValues(alpha: 0.6)
              : NunuColors.backgroundPaper.withValues(alpha: 0.4);
        } else {
          color = Colors.black.withValues(alpha: 0.44);
        }
        canvas.drawRect(rect, Paint()..color = color);

        // entry/exit border + label
        if (isEntry || isExit) {
          canvas.drawRect(
            rect.deflate(1.5),
            Paint()
              ..color = isEntry
                  ? NunuColors.successMain
                  : NunuColors.errorMain
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
          final tp = TextPainter(
            text: TextSpan(
              text: isEntry ? 'IN' : 'OUT',
              style: TextStyle(
                color: Colors.white,
                fontSize: cellSize * 0.22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
            textDirection: TextDirection.ltr,
          )..layout();
          tp.paint(
            canvas,
            rect.center - Offset(tp.width / 2, tp.height / 2),
          );
        }
      }
    }

    // terrain rocks
    for (final t in terrain) {
      final rect = Rect.fromLTWH(
          t.x * cellSize, t.y * cellSize, cellSize, cellSize);
      canvas.drawRect(rect, Paint()..color = const Color(0xFF1A1828));
      final tp = TextPainter(
        text: TextSpan(
          text: '⛰',
          style: TextStyle(fontSize: cellSize * 0.55),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, rect.center - Offset(tp.width / 2, tp.height / 2));
    }

    // path lines + pulses (only between waves)
    if (!showPreview) {
      // skip preview rendering during active waves
    } else {
    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    Offset cellCenter(Point<int> p) => Offset(
        (p.x + 0.5) * cellSize, (p.y + 0.5) * cellSize);

    for (int idx = 0; idx < activePaths.length; idx++) {
      final path = activePaths[idx];
      // total length in cells
      double total = 0;
      final segLens = <double>[];
      for (int i = 0; i < path.length - 1; i++) {
        final d = sqrt(pow(path[i + 1].x - path[i].x, 2) +
            pow(path[i + 1].y - path[i].y, 2));
        segLens.add(d.toDouble());
        total += d;
      }

      // base line
      final p = Path()..moveTo(cellCenter(path[0]).dx, cellCenter(path[0]).dy);
      for (int i = 1; i < path.length; i++) {
        p.lineTo(cellCenter(path[i]).dx, cellCenter(path[i]).dy);
      }
      canvas.drawPath(p, linePaint);

      // pulses — 3 evenly spaced, animated
      const pulses = 3;
      for (int k = 0; k < pulses; k++) {
        final t = ((pulseT + k / pulses + idx * 0.13) % 1.0);
        final dist = t * total;
        // find segment
        double d = 0;
        for (int i = 0; i < segLens.length; i++) {
          if (dist <= d + segLens[i]) {
            final localT = (dist - d) / segLens[i];
            final a = cellCenter(path[i]);
            final b = cellCenter(path[i + 1]);
            final pos = Offset.lerp(a, b, localT)!;
            final fade = sin(t * pi); // peaks at middle
            canvas.drawCircle(
              pos,
              cellSize * 0.12,
              Paint()
                ..color = Colors.white
                    .withValues(alpha: 0.55 * fade.clamp(0.0, 1.0)),
            );
            break;
          }
          d += segLens[i];
        }
      }
    }
    }

    // shots
    for (final s in shots) {
      final p = Paint()
        ..color = s.color.withValues(alpha: (s.life / 0.13).clamp(0.0, 1.0))
        ..strokeWidth = 2.5;
      canvas.drawLine(s.from, s.to, p);
    }

    // bursts (splash visuals)
    for (final br in bursts) {
      final t = (br.life / 0.25).clamp(0.0, 1.0);
      final r = br.radius * (1.0 - t * 0.6);
      canvas.drawCircle(
        br.center,
        r,
        Paint()
          ..color = br.color.withValues(alpha: 0.25 * t)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
        br.center,
        r,
        Paint()
          ..color = br.color.withValues(alpha: 0.7 * t)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }

    // bloons
    for (final b in bloons) {
      final ratio = (b.hp / b.maxHp).clamp(0.0, 1.0);
      Color color = Color.lerp(
          NunuColors.errorMain, NunuColors.successMain, ratio)!;
      double radius = cellSize * 0.32;
      if (b.kind == _BloonKind.elite) {
        color = Colors.deepOrangeAccent;
        radius = cellSize * 0.42;
      } else if (b.kind == _BloonKind.camo) {
        color = const Color(0xFF8FBC8F);
      }
      canvas.drawCircle(b.position, radius, Paint()..color = color);
      if (b.kind == _BloonKind.camo) {
        final tp = TextPainter(
          text: TextSpan(
            text: '?',
            style: TextStyle(
                color: Colors.white,
                fontSize: cellSize * 0.4,
                fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, b.position - Offset(tp.width / 2, tp.height / 2));
      }
      // hp bar
      if (ratio < 1) {
        final w = cellSize * 0.7;
        final barRect = Rect.fromCenter(
            center: b.position - Offset(0, radius + 5),
            width: w,
            height: 3);
        canvas.drawRect(barRect, Paint()..color = Colors.black54);
        canvas.drawRect(
          Rect.fromLTWH(barRect.left, barRect.top, w * ratio, 3),
          Paint()..color = NunuColors.successMain,
        );
      }
      if (b.slowLeft > 0) {
        canvas.drawCircle(
          b.position,
          radius + 2,
          Paint()
            ..color = const Color(0xFF7EE7F6).withValues(alpha: 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }

    // towers
    for (final t in towers) {
      final center = Offset(
          (t.cell.x + 0.5) * cellSize, (t.cell.y + 0.5) * cellSize);
      if (t == selected) {
        // range ring
        canvas.drawCircle(
          center,
          t.range * cellSize,
          Paint()
            ..color = NunuColors.primaryLight.withValues(alpha: 0.25)
            ..style = PaintingStyle.fill,
        );
        canvas.drawCircle(
          center,
          cellSize * 0.5,
          Paint()
            ..color = NunuColors.primaryLight
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
      canvas.drawCircle(
          center, cellSize * 0.4, Paint()..color = t.spec.color);
      final tp = TextPainter(
        text: TextSpan(
          text: t.spec.emoji,
          style: TextStyle(fontSize: cellSize * 0.5),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
      if (t.tier > 0) {
        final badge = Offset(
            center.dx + cellSize * 0.28, center.dy - cellSize * 0.28);
        canvas.drawCircle(
            badge, cellSize * 0.14, Paint()..color = NunuColors.warningMain);
        final tt = TextPainter(
          text: TextSpan(
            text: '${t.tier}',
            style: TextStyle(
                color: Colors.black,
                fontSize: cellSize * 0.18,
                fontWeight: FontWeight.w900),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tt.paint(canvas, badge - Offset(tt.width / 2, tt.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _TDPainter oldDelegate) => true;
}

// custom Ticker mixin lookup helper
class _TickerHolder {
  _TickerHolder();
}
