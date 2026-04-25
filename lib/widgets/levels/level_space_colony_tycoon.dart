import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

class LevelSpaceColonyTycoon extends LevelWidget {
  const LevelSpaceColonyTycoon({super.key, required super.onComplete});

  @override
  State<LevelSpaceColonyTycoon> createState() => _LevelSpaceColonyTycoonState();
}

enum _Terrain { plain, mineral, ice }

enum _BuildingType { hub, solar, coop, drill, lab }

enum _Goods { eggs, ore, algae }

enum _OverlayPanel { tutorial, build, orders }

class _TileData {
  const _TileData({
    required this.id,
    required this.row,
    required this.col,
    required this.terrain,
  });

  final int id;
  final int row;
  final int col;
  final _Terrain terrain;
}

class _PlacedBuilding {
  _PlacedBuilding({
    required this.tileId,
    required this.type,
    this.level = 1,
    this.stored = 0,
    this.progressSeconds = 0,
  });

  final int tileId;
  final _BuildingType type;
  int level;
  int stored;
  double progressSeconds;
}

class _ContractTemplate {
  const _ContractTemplate({
    required this.label,
    required this.reward,
    required this.requirements,
  });

  final String label;
  final int reward;
  final Map<_Goods, int> requirements;
}

class _ContractOffer {
  const _ContractOffer({
    required this.label,
    required this.reward,
    required this.requirements,
  });

  final String label;
  final int reward;
  final Map<_Goods, int> requirements;
}

class _HarvestSession {
  const _HarvestSession({
    required this.tileId,
    required this.goods,
    required this.amount,
  });

  final int tileId;
  final _Goods goods;
  final int amount;
}

class _LevelSpaceColonyTycoonState extends State<LevelSpaceColonyTycoon> {
  static const int _rows = 10;
  static const int _cols = 10;
  static const double _tileWidth = 104;
  static const double _tileHeight = 58;
  static const double _mapWidth = 1500;
  static const double _mapHeight = 1120;

  static const int _solarTileId = 56;
  static const int _coopTileId = 65;
  static const int _hubTileId = 55;

  static const List<_ContractTemplate> _contractTemplates = [
    _ContractTemplate(
      label: 'canteen breakfast',
      reward: 120,
      requirements: {_Goods.eggs: 2},
    ),
    _ContractTemplate(
      label: 'habitat patch kit',
      reward: 155,
      requirements: {_Goods.ore: 2},
    ),
    _ContractTemplate(
      label: 'greenhouse starter pack',
      reward: 165,
      requirements: {_Goods.algae: 2},
    ),
    _ContractTemplate(
      label: 'orbital omelette',
      reward: 210,
      requirements: {_Goods.eggs: 2, _Goods.algae: 1},
    ),
    _ContractTemplate(
      label: 'hull reinforcement',
      reward: 225,
      requirements: {_Goods.ore: 2, _Goods.eggs: 1},
    ),
    _ContractTemplate(
      label: 'terraformer feedstock',
      reward: 240,
      requirements: {_Goods.algae: 2, _Goods.ore: 1},
    ),
    _ContractTemplate(
      label: 'deep space brunch',
      reward: 280,
      requirements: {_Goods.eggs: 3, _Goods.algae: 1},
    ),
  ];

  final TransformationController _cameraController = TransformationController();
  final Random _random = Random();
  final Map<_Goods, int> _inventory = {
    _Goods.eggs: 0,
    _Goods.ore: 0,
    _Goods.algae: 0,
  };
  final List<_TileData> _tiles = [];
  final Map<int, _PlacedBuilding> _buildings = {};

  Timer? _tickTimer;
  DateTime _lastTick = DateTime.now();

  int _credits = 320;
  int _energy = 0;
  int _ordersCompleted = 0;
  int _manualCollections = 0;
  int _tutorialStep = 0;
  int? _selectedTileId;
  String _lastHint = 'boot the colony from the panel below.';
  _OverlayPanel? _overlayPanel = _OverlayPanel.tutorial;
  _HarvestSession? _harvestSession;
  int _harvestSwipesDone = 0;
  Offset _harvestTokenOffset = Offset.zero;
  int _harvestTapCount = 0;
  Offset _harvestTapTarget = const Offset(24, 22);
  bool _tutorialComplete = false;
  bool _runFinished = false;
  bool _panSatisfied = false;
  bool _zoomSatisfied = false;

  late _ContractOffer _activeContract;

  @override
  void initState() {
    super.initState();
    widget.registerTimeoutBuilder(_buildOutcome);
    _seedMap();
    _spawnStarterBuildings();
    _activeContract = _buildContract(forceTutorial: true);
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickGame());
    _lastTick = DateTime.now();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cameraController.value = Matrix4.identity()
        ..translate(-250.0, -80.0)
        ..scale(0.92);
    });
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    widget.clearTimeoutBuilder();
    _cameraController.dispose();
    super.dispose();
  }

  void _seedMap() {
    _tiles.clear();
    const mineralTiles = {
      8,
      9,
      18,
      19,
      28,
      29,
      37,
      38,
      47,
      48,
      74,
      75,
      84,
      85,
    };
    const iceTiles = {
      0,
      1,
      2,
      10,
      11,
      12,
      20,
      21,
      22,
      30,
      31,
      32,
      40,
      41,
      42,
    };

    for (int row = 0; row < _rows; row++) {
      for (int col = 0; col < _cols; col++) {
        final id = _tileId(row, col);
        final terrain = mineralTiles.contains(id)
            ? _Terrain.mineral
            : iceTiles.contains(id)
            ? _Terrain.ice
            : _Terrain.plain;
        _tiles.add(_TileData(id: id, row: row, col: col, terrain: terrain));
      }
    }
  }

  void _spawnStarterBuildings() {
    _buildings.clear();
    _buildings[_hubTileId] = _PlacedBuilding(tileId: _hubTileId, type: _BuildingType.hub);
    _selectedTileId = _hubTileId;
  }

  void _tickGame() {
    if (!mounted || _runFinished) return;

    final now = DateTime.now();
    final deltaSeconds = now.difference(_lastTick).inMilliseconds / 1000;
    _lastTick = now;

    bool changed = false;
    for (final building in _buildings.values) {
      if (building.type == _BuildingType.hub) continue;

      final capacity = _storageCap(building);
      if (building.stored >= capacity) {
        building.progressSeconds = min(building.progressSeconds, _cycleSeconds(building));
        continue;
      }

      building.progressSeconds += deltaSeconds;
      while (building.progressSeconds >= _cycleSeconds(building) &&
          building.stored < capacity) {
        if (!_canConsumeProductionInputs(building)) {
          building.progressSeconds = _cycleSeconds(building);
          break;
        }
        _consumeProductionInputs(building);
        building.progressSeconds -= _cycleSeconds(building);
        building.stored = min(capacity, building.stored + _yieldAmount(building));
        changed = true;
      }
    }

    if (changed) {
      setState(() {});
    } else if (_tutorialStep == 6 && _buildings[_coopTileId]?.stored == 0) {
      setState(() {});
    }
  }

  int _tileId(int row, int col) => row * _cols + col;

  _TileData _tileFor(int tileId) => _tiles.firstWhere((tile) => tile.id == tileId);

  double _cycleSeconds(_PlacedBuilding building) {
    final base = switch (building.type) {
      _BuildingType.hub => 9999.0,
      _BuildingType.solar => 8.0,
      _BuildingType.coop => 14.0,
      _BuildingType.drill => 18.0,
      _BuildingType.lab => 16.0,
    };
    return (base * pow(0.85, building.level - 1)).toDouble();
  }

  int _yieldAmount(_PlacedBuilding building) {
    return switch (building.type) {
      _BuildingType.hub => 0,
      _BuildingType.solar => 2 + (building.level - 1),
      _BuildingType.coop => 1,
      _BuildingType.drill => 1,
      _BuildingType.lab => 1,
    };
  }

  int _storageCap(_PlacedBuilding building) {
    final base = switch (building.type) {
      _BuildingType.hub => 0,
      _BuildingType.solar => 12,
      _BuildingType.coop => 3,
      _BuildingType.drill => 3,
      _BuildingType.lab => 3,
    };
    return base + (building.level - 1) * 2;
  }

  int _buildCost(_BuildingType type) {
    return switch (type) {
      _BuildingType.hub => 0,
      _BuildingType.solar => 70,
      _BuildingType.coop => 90,
      _BuildingType.drill => 140,
      _BuildingType.lab => 120,
    };
  }

  int _upgradeCost(_PlacedBuilding building) {
    final base = switch (building.type) {
      _BuildingType.hub => 0,
      _BuildingType.solar => 80,
      _BuildingType.coop => 100,
      _BuildingType.drill => 150,
      _BuildingType.lab => 130,
    };
    return base + (building.level - 1) * 60;
  }

  int _energyCost(_PlacedBuilding building) {
    return switch (building.type) {
      _BuildingType.hub => 0,
      _BuildingType.solar => 0,
      _BuildingType.coop => 1,
      _BuildingType.drill => 2,
      _BuildingType.lab => 1,
    };
  }

  _Goods? _goodsType(_BuildingType type) {
    return switch (type) {
      _BuildingType.coop => _Goods.eggs,
      _BuildingType.drill => _Goods.ore,
      _BuildingType.lab => _Goods.algae,
      _BuildingType.hub => null,
      _BuildingType.solar => null,
    };
  }

  bool _canBuildOn(_BuildingType type, _TileData tile) {
    if (_buildings.containsKey(tile.id)) return false;
    return switch (type) {
      _BuildingType.hub => false,
      _BuildingType.solar => tile.terrain == _Terrain.plain,
      _BuildingType.coop => tile.terrain == _Terrain.plain,
      _BuildingType.drill => tile.terrain == _Terrain.mineral,
      _BuildingType.lab => tile.terrain == _Terrain.ice,
    };
  }

  bool _canConsumeProductionInputs(_PlacedBuilding building) {
    return _energy >= _energyCost(building);
  }

  void _consumeProductionInputs(_PlacedBuilding building) {
    _energy -= _energyCost(building);
  }

  _ContractOffer _buildContract({bool forceTutorial = false}) {
    if (forceTutorial || !_tutorialComplete) {
      return const _ContractOffer(
        label: 'canteen breakfast',
        reward: 120,
        requirements: {_Goods.eggs: 2},
      );
    }

    final pool = _ordersCompleted < 2
        ? _contractTemplates.take(3).toList()
        : _contractTemplates;
    final template = pool[_random.nextInt(pool.length)];
    final reward = template.reward + (_ordersCompleted * 14);
    return _ContractOffer(
      label: template.label,
      reward: reward,
      requirements: template.requirements,
    );
  }

  String _tutorialMessage() {
    switch (_tutorialStep) {
      case 0:
        return 'press boot colony below to start the ftue.';
      case 1:
        return 'drag the camera around the plateau.';
      case 2:
        return 'pinch to zoom in on the build grid.';
      case 3:
        return 'open build and drag a solar array onto the glowing tile.';
      case 4:
        return 'wait for the solar array, then collect its charge.';
      case 5:
        return 'drag a moonhen coop onto the next glowing tile.';
      case 6:
        return 'collect two void eggs from the coop.';
      case 7:
        return 'upgrade that coop once so it stops being embarrassing.';
      case 8:
        return 'deliver the breakfast contract. after that, free play.';
      default:
        return 'maximize space money before the hour ends or cash out early.';
    }
  }

  void _advanceTutorial() {
    if (_tutorialStep >= 8) {
      _tutorialComplete = true;
      _tutorialStep = 9;
      _overlayPanel = _OverlayPanel.orders;
      return;
    }
    _tutorialStep++;
    if (_tutorialStep == 8) {
      _overlayPanel = _OverlayPanel.orders;
    } else {
      _overlayPanel = _OverlayPanel.tutorial;
    }
  }

  void _selectTile(int tileId) {
    if (_runFinished) return;

    final building = _buildings[tileId];
    final isCorrectTutorialTap = switch (_tutorialStep) {
      0 => tileId == _hubTileId,
      3 => tileId == _solarTileId,
      5 => tileId == _coopTileId,
      7 => tileId == _coopTileId,
      _ => true,
    };
    if (!isCorrectTutorialTap) {
      setState(() {
        if (_tutorialStep == 0) {
          _selectedTileId = _hubTileId;
        }
      });
      _showHint('wrong tile. the ftue wants the glowing one.');
      return;
    }

    setState(() {
      _selectedTileId = tileId;
      if (_tutorialStep == 7 && building?.type == _BuildingType.coop) {
        // Tile selection is part of the prompt here; upgrade action finishes the step.
      }
    });
  }

  void _showHint(String message) {
    setState(() {
      _lastHint = message;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 210),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
        duration: const Duration(milliseconds: 900),
        backgroundColor: NunuColors.backgroundPaper,
      ),
    );
  }

  void _bootColony() {
    if (_tutorialStep != 0) return;
    setState(() {
      _selectedTileId = _hubTileId;
      _overlayPanel = _OverlayPanel.tutorial;
      _lastHint = 'good. now drag the map a bit.';
      _advanceTutorial();
    });
  }

  void _setOverlayPanel(_OverlayPanel panel) {
    setState(() {
      _overlayPanel = _overlayPanel == panel ? null : panel;
      if (_overlayPanel == _OverlayPanel.build) {
        _lastHint = 'long-press a building card and drag it onto a valid tile.';
      }
    });
  }

  void _handleCameraUpdate() {
    if (_runFinished) return;
    final translation = _cameraController.value.getTranslation();
    final scale = _cameraController.value.getMaxScaleOnAxis();

    if (_tutorialStep == 1 &&
        !_panSatisfied &&
        (translation.x.abs() > 300 || translation.y.abs() > 160)) {
      setState(() {
        _panSatisfied = true;
        _advanceTutorial();
      });
    }

    if (_tutorialStep == 2 && !_zoomSatisfied && scale > 1.1) {
      setState(() {
        _zoomSatisfied = true;
        _advanceTutorial();
      });
    }
  }

  bool _canPlaceBuildingOnTile(int tileId, _BuildingType type, {bool strictTutorial = true}) {
    final tile = _tileFor(tileId);
    if (!_canBuildOn(type, tile)) return false;
    if (!_tutorialComplete && strictTutorial) {
      if (_tutorialStep == 3) {
        return type == _BuildingType.solar && tileId == _solarTileId;
      }
      if (_tutorialStep == 5) {
        return type == _BuildingType.coop && tileId == _coopTileId;
      }
      if (!{3, 5, 9}.contains(_tutorialStep)) {
        return false;
      }
    }
    return true;
  }

  bool _buildOnTile(int tileId, _BuildingType type) {
    final tile = _tileFor(tileId);

    if (_tutorialStep == 3 &&
        (type != _BuildingType.solar || tileId != _solarTileId)) {
      _showHint('the tutorial wants a solar array on the highlighted pad.');
      return false;
    }
    if (_tutorialStep == 5 &&
        (type != _BuildingType.coop || tileId != _coopTileId)) {
      _showHint('build the coop on the marked tile first.');
      return false;
    }
    if (!_tutorialComplete && !{3, 5, 9}.contains(_tutorialStep)) {
      _showHint('finish the current ftue step first.');
      return false;
    }
    if (!_canBuildOn(type, tile)) {
      _showHint('that building does not fit this terrain.');
      return false;
    }

    final cost = _buildCost(type);
    if (_credits < cost) {
      _showHint('not enough credits.');
      return false;
    }

    setState(() {
      _selectedTileId = tileId;
      _credits -= cost;
      _buildings[tileId] = _PlacedBuilding(tileId: tileId, type: type);
      if (_tutorialStep == 3 && type == _BuildingType.solar) {
        _overlayPanel = _OverlayPanel.tutorial;
        _advanceTutorial();
      } else if (_tutorialStep == 5 && type == _BuildingType.coop) {
        _overlayPanel = _OverlayPanel.tutorial;
        _advanceTutorial();
      }
    });
    return true;
  }

  void _collectFrom(_PlacedBuilding building) {
    if (building.stored <= 0) {
      _showHint('nothing ready yet.');
      return;
    }

    if (_tutorialStep == 4 && building.tileId != _solarTileId) {
      _showHint('collect from the new solar array first.');
      return;
    }
    if (_tutorialStep == 6 && building.tileId != _coopTileId) {
      _showHint('the tutorial wants eggs from the coop.');
      return;
    }

    setState(() {
      if (building.type == _BuildingType.solar) {
        _energy += building.stored;
        _manualCollections++;
        building.stored = 0;
        building.progressSeconds = 0;
      } else {
        _harvestSession = _HarvestSession(
          tileId: building.tileId,
          goods: _goodsType(building.type)!,
          amount: building.stored,
        );
        _harvestSwipesDone = 0;
        _harvestTapCount = 0;
        _harvestTokenOffset = Offset.zero;
        _harvestTapTarget = _nextHarvestTarget();
        _lastHint = _harvestSession!.goods == _Goods.eggs
            ? 'swipe the eggs into the basket.'
            : 'tap the drifting ${_goodsLabel(_harvestSession!.goods)} vein.';
      }
      if (_tutorialStep == 4 && building.tileId == _solarTileId) {
        _advanceTutorial();
      }
    });
  }

  void _finishHarvestMiniGame() {
    final session = _harvestSession;
    if (session == null) return;

    final building = _buildings[session.tileId];
    if (building == null) {
      setState(() {
        _harvestSession = null;
      });
      return;
    }

    setState(() {
      _inventory[session.goods] = (_inventory[session.goods] ?? 0) + session.amount;
      _manualCollections++;
      building.stored = 0;
      building.progressSeconds = 0;
      _harvestSession = null;
      _harvestSwipesDone = 0;
      _harvestTapCount = 0;
      _harvestTokenOffset = Offset.zero;
      _harvestTapTarget = const Offset(24, 22);

      if (_tutorialStep == 6 && (_inventory[_Goods.eggs] ?? 0) >= 2) {
        _advanceTutorial();
      }
    });
  }

  Offset _nextHarvestTarget() {
    return Offset(
      28 + _random.nextDouble() * 132,
      16 + _random.nextDouble() * 58,
    );
  }

  void _tapHarvestTarget() {
    final session = _harvestSession;
    if (session == null || session.goods == _Goods.eggs) return;
    final requiredTaps = max(2, session.amount * 2);
    final shouldFinish = _harvestTapCount + 1 >= requiredTaps;

    if (shouldFinish) {
      _finishHarvestMiniGame();
      return;
    }

    setState(() {
      _harvestTapCount++;
      _harvestTapTarget = _nextHarvestTarget();
    });
  }

  bool _canUseFreeSpeedup(_PlacedBuilding building) {
    if (_tutorialComplete || building.type == _BuildingType.hub) return false;
    return switch (_tutorialStep) {
      4 => building.tileId == _solarTileId,
      6 => building.tileId == _coopTileId,
      _ => false,
    };
  }

  void _useFreeSpeedup() {
    final tileId = _selectedTileId;
    final building = tileId == null ? null : _buildings[tileId];
    if (building == null || !_canUseFreeSpeedup(building)) return;
    if (building.stored >= _storageCap(building)) {
      _showHint('storage is already full.');
      return;
    }
    if (!_canConsumeProductionInputs(building)) {
      _showHint('need more energy first.');
      return;
    }

    setState(() {
      building.progressSeconds += _cycleSeconds(building);
      while (building.progressSeconds >= _cycleSeconds(building) &&
          building.stored < _storageCap(building)) {
        if (!_canConsumeProductionInputs(building)) {
          building.progressSeconds = _cycleSeconds(building);
          break;
        }
        _consumeProductionInputs(building);
        building.progressSeconds -= _cycleSeconds(building);
        building.stored =
            min(_storageCap(building), building.stored + _yieldAmount(building));
      }
      _lastHint = 'ftue speed boost applied.';
    });
  }

  void _upgradeSelected() {
    final tileId = _selectedTileId;
    final building = tileId == null ? null : _buildings[tileId];
    if (building == null || building.type == _BuildingType.hub) return;

    if (_tutorialStep == 7 && tileId != _coopTileId) {
      _showHint('upgrade the coop first.');
      return;
    }
    if (!_tutorialComplete && !{7, 9}.contains(_tutorialStep)) {
      _showHint('finish the tutorial step in front of you first.');
      return;
    }
    if (building.level >= 3) {
      _showHint('already maxed.');
      return;
    }

    final cost = _upgradeCost(building);
    if (_credits < cost) {
      _showHint('not enough credits for that upgrade.');
      return;
    }

    setState(() {
      _credits -= cost;
      building.level++;
      if (_tutorialStep == 7 && tileId == _coopTileId) {
        _advanceTutorial();
      }
    });
  }

  bool _canFulfillContract() {
    for (final entry in _activeContract.requirements.entries) {
      if ((_inventory[entry.key] ?? 0) < entry.value) return false;
    }
    return true;
  }

  void _deliverContract() {
    if (!_canFulfillContract()) {
      _showHint('contract not ready yet.');
      return;
    }
    if (_tutorialStep == 8 || _tutorialComplete) {
      setState(() {
        for (final entry in _activeContract.requirements.entries) {
          _inventory[entry.key] = (_inventory[entry.key] ?? 0) - entry.value;
        }
        _credits += _activeContract.reward;
        _ordersCompleted++;
        if (_tutorialStep == 8) {
          _advanceTutorial();
          _activeContract = _buildContract();
        } else {
          _activeContract = _buildContract();
        }
      });
      return;
    }

    _showHint('finish the tutorial before trading freestyle.');
  }

  LevelOutcome _buildOutcome() {
    final inventoryValue = (_inventory[_Goods.eggs] ?? 0) * 18 +
        (_inventory[_Goods.ore] ?? 0) * 26 +
        (_inventory[_Goods.algae] ?? 0) * 22;
    final buildingValue = _buildings.values.fold<int>(0, (sum, building) {
      if (building.type == _BuildingType.hub) return sum;
      return sum + (_buildCost(building.type) + max(0, building.level - 1) * 60);
    });
    final netWorth =
        _credits + inventoryValue + _energy * 4 + (buildingValue * 0.65).round();
    final profit = max(0, netWorth - 320);
    final score = _tutorialComplete
        ? (profit / 1800).clamp(0, 1).toDouble()
        : 0.0;

    return LevelOutcome(
      score: score,
      metrics: {
        'space_money': _credits,
        'net_worth': netWorth,
        'profit': profit,
        'orders_completed': _ordersCompleted,
        'manual_collections': _manualCollections,
      },
    );
  }

  void _finishRun() {
    if (_runFinished) return;
    _runFinished = true;
    widget.onComplete(_buildOutcome());
  }

  String _goodsLabel(_Goods goods) {
    return switch (goods) {
      _Goods.eggs => 'eggs',
      _Goods.ore => 'ore',
      _Goods.algae => 'algae',
    };
  }

  String _buildingEmoji(_BuildingType type) {
    return switch (type) {
      _BuildingType.hub => '🚀',
      _BuildingType.solar => '🔋',
      _BuildingType.coop => '🐔',
      _BuildingType.drill => '⛏️',
      _BuildingType.lab => '🧪',
    };
  }

  String _buildingName(_BuildingType type) {
    return switch (type) {
      _BuildingType.hub => 'command hub',
      _BuildingType.solar => 'solar array',
      _BuildingType.coop => 'moonhen coop',
      _BuildingType.drill => 'ore drill',
      _BuildingType.lab => 'algae lab',
    };
  }

  Color _terrainColor(_Terrain terrain) {
    return switch (terrain) {
      _Terrain.plain => const Color(0xFF4E3E7A),
      _Terrain.mineral => const Color(0xFF4B556A),
      _Terrain.ice => const Color(0xFF2C6475),
    };
  }

  Color _terrainAccent(_Terrain terrain) {
    return switch (terrain) {
      _Terrain.plain => NunuColors.secondaryLight,
      _Terrain.mineral => NunuColors.warningMain,
      _Terrain.ice => NunuColors.infoLight,
    };
  }

  Color _buildingColor(_BuildingType type) {
    return switch (type) {
      _BuildingType.hub => NunuColors.primaryMain,
      _BuildingType.solar => NunuColors.warningMain,
      _BuildingType.coop => NunuColors.successMain,
      _BuildingType.drill => NunuColors.errorLight,
      _BuildingType.lab => NunuColors.infoMain,
    };
  }

  String _terrainLabel(_Terrain terrain) {
    return switch (terrain) {
      _Terrain.plain => 'plain',
      _Terrain.mineral => 'ore',
      _Terrain.ice => 'ice',
    };
  }

  bool _isHighlightedTile(int tileId) {
    return switch (_tutorialStep) {
      0 => tileId == _hubTileId,
      3 => tileId == _solarTileId,
      5 => tileId == _coopTileId,
      6 => tileId == _coopTileId,
      7 => tileId == _coopTileId,
      _ => false,
    };
  }

  Widget _buildTopHud() {
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 6, 42, 0),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          alignment: WrapAlignment.center,
          children: [
            _statChip(Icons.savings, 'credits', '$_credits', NunuColors.warningMain),
            _statChip(Icons.bolt, 'energy', '$_energy', NunuColors.infoMain),
            _statChip(Icons.egg_alt, 'eggs', '${_inventory[_Goods.eggs]}', NunuColors.successMain),
            _statChip(Icons.hardware, 'ore', '${_inventory[_Goods.ore]}', NunuColors.errorLight),
            _statChip(Icons.local_florist, 'algae', '${_inventory[_Goods.algae]}', NunuColors.infoLight),
          ],
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 4),
          Text(
            '$label $value',
            style: const TextStyle(
              color: NunuColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContractPanel() {
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: 216,
        margin: const EdgeInsets.only(top: 112, right: 54),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NunuColors.primaryMain.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'freighter contract',
              style: TextStyle(
                color: NunuColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _activeContract.label,
              style: const TextStyle(
                color: NunuColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            ..._activeContract.requirements.entries.map((entry) {
              final have = _inventory[entry.key] ?? 0;
              final ready = have >= entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_goodsLabel(entry.key)} ${entry.value}',
                        style: const TextStyle(
                          color: NunuColors.textPrimary,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '$have/${entry.value}',
                      style: TextStyle(
                        color: ready ? NunuColors.successLight : NunuColors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 6),
            Text(
              'reward ${_activeContract.reward} credits',
              style: const TextStyle(
                color: NunuColors.warningLight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _deliverContract,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(34),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                backgroundColor: _canFulfillContract()
                    ? NunuColors.primaryMain
                    : NunuColors.primaryDark.withValues(alpha: 0.7),
                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
              ),
              child: const Text('deliver'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPanel() {
    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        width: 248,
        margin: const EdgeInsets.fromLTRB(10, 64, 12, 12),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _tutorialComplete
                ? NunuColors.successMain.withValues(alpha: 0.4)
                : NunuColors.primaryMain.withValues(alpha: 0.4),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _tutorialComplete ? 'ftue cleared' : 'ftue ${min(_tutorialStep + 1, 9)}/9',
              style: TextStyle(
                color: _tutorialComplete ? NunuColors.successLight : NunuColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _tutorialMessage(),
              style: const TextStyle(
                color: NunuColors.textPrimary,
                height: 1.35,
                fontSize: 12,
              ),
            ),
            if (_tutorialComplete) ...[
              const SizedBox(height: 6),
              const Text(
                'cash out whenever you want, or let the shell end the hour.',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
            ],
            const SizedBox(height: 6),
            Text(
              _lastHint,
              style: const TextStyle(
                color: NunuColors.warningLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightRail() {
    final hasReadyContract = _canFulfillContract();
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 64, right: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _railButton(
              icon: Icons.menu_book,
              active: _overlayPanel == _OverlayPanel.tutorial,
              onTap: () => _setOverlayPanel(_OverlayPanel.tutorial),
            ),
            const SizedBox(height: 6),
            _railButton(
              icon: Icons.handyman,
              active: _overlayPanel == _OverlayPanel.build,
              onTap: () => _setOverlayPanel(_OverlayPanel.build),
            ),
            const SizedBox(height: 6),
            _railButton(
              icon: Icons.local_shipping,
              active: _overlayPanel == _OverlayPanel.orders,
              badge: hasReadyContract,
              onTap: () => _setOverlayPanel(_OverlayPanel.orders),
            ),
          ],
        ),
      ),
    );
  }

  Widget _railButton({
    required IconData icon,
    required bool active,
    bool badge = false,
    required VoidCallback onTap,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: active
              ? NunuColors.primaryMain.withValues(alpha: 0.85)
              : NunuColors.backgroundPaper.withValues(alpha: 0.95),
          shape: const CircleBorder(),
          child: IconButton(
            onPressed: onTap,
            constraints: const BoxConstraints.tightFor(width: 36, height: 36),
            padding: EdgeInsets.zero,
            icon: Icon(icon, color: Colors.white, size: 17),
          ),
        ),
        if (badge)
          Positioned(
            right: 1,
            top: 1,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: NunuColors.errorMain,
                shape: BoxShape.circle,
                border: Border.all(color: NunuColors.backgroundDefault, width: 1.2),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBuildTray() {
    const available = [
      _BuildingType.solar,
      _BuildingType.coop,
      _BuildingType.drill,
      _BuildingType.lab,
    ];

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 118,
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(10, 12, 54, 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: NunuColors.primaryMain.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'build bay',
              style: TextStyle(
                color: NunuColors.primaryLight,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'drag onto the grid',
              style: TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: available.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) => _buildBuildCard(
                  available[index],
                  compact: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuildCard(_BuildingType type, {bool compact = false}) {
    final color = _buildingColor(type);
    final card = Container(
      width: compact ? 164 : null,
      margin: EdgeInsets.only(bottom: compact ? 0 : 6),
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 6 : 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Text(_buildingEmoji(type), style: TextStyle(fontSize: compact ? 17 : 20)),
          SizedBox(width: compact ? 6 : 8),
          Expanded(
            child: compact
                ? Text(
                    '${_buildingName(type)} • ${_buildCost(type)}c',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _buildingName(type),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: NunuColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '${_buildCost(type)} credits',
                        style: const TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
          ),
          Icon(
            Icons.open_with,
            color: color.withValues(alpha: 0.9),
            size: 16,
          ),
        ],
      ),
    );

    return LongPressDraggable<_BuildingType>(
      data: type,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: compact ? 164 : 180,
          child: Opacity(
            opacity: 0.92,
            child: card,
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }

  Widget _buildBottomPanel() {
    final tileId = _selectedTileId;
    final tile = tileId == null ? null : _tileFor(tileId);
    final building = tileId == null ? null : _buildings[tileId];

    return Align(
      alignment: Alignment.bottomLeft,
      child: Container(
        width: 232,
        margin: const EdgeInsets.fromLTRB(10, 12, 12, 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: NunuColors.primaryMain.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: tile == null
                      ? const Text(
                          'select a tile to build or manage something.',
                          style: TextStyle(
                            color: NunuColors.textSecondary,
                            fontSize: 11,
                          ),
                        )
                      : Text(
                          'tile r${tile.row + 1} c${tile.col + 1}  |  ${_terrainLabel(tile.terrain)}',
                          style: const TextStyle(
                            color: NunuColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (tile != null && building == null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'empty tile. long-press and drag a building here.',
                    style: TextStyle(color: NunuColors.textSecondary, fontSize: 11),
                  ),
                  if (_tutorialStep == 0) ...[
                    const SizedBox(height: 8),
                    _buildActionButton(
                      icon: Icons.power_settings_new,
                      label: 'boot colony',
                      enabled: true,
                      color: NunuColors.primaryMain,
                      onTap: _bootColony,
                    ),
                  ],
                ],
              ),
            if (building != null)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_buildingEmoji(building.type)} ${_buildingName(building.type)}  |  lvl ${building.level}',
                          style: const TextStyle(
                            color: NunuColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      if (building.type != _BuildingType.hub)
                        Text(
                          '${building.stored}/${_storageCap(building)} stored',
                          style: const TextStyle(color: NunuColors.textSecondary, fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Column(
                    children: [
                      if (building.type == _BuildingType.hub && _tutorialStep == 0)
                        _buildActionButton(
                          icon: Icons.power_settings_new,
                          label: 'boot colony',
                          enabled: true,
                          color: NunuColors.primaryMain,
                          onTap: _bootColony,
                        ),
                      if (building.type != _BuildingType.hub)
                        _buildActionButton(
                          icon: Icons.inventory_2,
                          label: building.type == _BuildingType.solar ? 'collect charge' : 'collect',
                          enabled: building.stored > 0,
                          color: NunuColors.successMain,
                          onTap: () => _collectFrom(building),
                        ),
                      if (building.type != _BuildingType.hub)
                        _buildActionButton(
                          icon: Icons.upgrade,
                          label: 'upgrade ${_upgradeCost(building)}',
                          enabled: building.level < 3,
                          color: NunuColors.primaryMain,
                          onTap: _upgradeSelected,
                        ),
                      if (building.type != _BuildingType.hub)
                        _buildActionButton(
                          icon: Icons.flash_on,
                          label: 'free speedup',
                          enabled: _canUseFreeSpeedup(building),
                          color: NunuColors.warningMain,
                          onTap: _useFreeSpeedup,
                        ),
                    ],
                  ),
                  if (building.type == _BuildingType.hub && _tutorialStep == 0)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'the colony starts here. build/orders live in the right rail.',
                        style: TextStyle(color: NunuColors.textSecondary, fontSize: 11),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool enabled,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.tonalIcon(
          onPressed: enabled ? onTap : null,
          style: FilledButton.styleFrom(
            alignment: Alignment.centerLeft,
            backgroundColor: enabled
                ? color.withValues(alpha: 0.2)
                : NunuColors.backgroundDefault.withValues(alpha: 0.3),
            foregroundColor: enabled ? Colors.white : NunuColors.textSecondary,
            minimumSize: const Size.fromHeight(34),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
          icon: Icon(icon, size: 15),
          label: Text(label),
        ),
      ),
    );
  }

  Widget _buildMap() {
    final sortedTiles = [..._tiles]..sort((a, b) {
      final depthCompare = (a.row + a.col).compareTo(b.row + b.col);
      if (depthCompare != 0) return depthCompare;
      return a.col.compareTo(b.col);
    });

    return InteractiveViewer(
      transformationController: _cameraController,
      boundaryMargin: const EdgeInsets.all(240),
      minScale: 0.55,
      maxScale: 2.2,
      constrained: false,
      onInteractionUpdate: (_) => _handleCameraUpdate(),
      child: SizedBox(
        width: _mapWidth,
        height: _mapHeight,
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF090B23),
                      NunuColors.backgroundDefault,
                      const Color(0xFF120E2D),
                    ],
                  ),
                ),
              ),
            ),
            ...List.generate(55, (index) {
              final dx = 80 + (index * 117 % 1300).toDouble();
              final dy = 40 + (index * 79 % 900).toDouble();
              final size = 1.5 + (index % 3).toDouble();
              return Positioned(
                left: dx,
                top: dy,
                child: Container(
                  width: size,
                  height: size,
                  decoration: const BoxDecoration(
                    color: Colors.white70,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }),
            Positioned(
              left: 1100,
              top: 90,
              child: _sectorMarker('ice shelf'),
            ),
            Positioned(
              left: 180,
              top: 150,
              child: _sectorMarker('aux flats'),
            ),
            Positioned(
              left: 1160,
              top: 720,
              child: _sectorMarker('ore ridge'),
            ),
            ...sortedTiles.map(_buildTileWidget),
          ],
        ),
      ),
    );
  }

  Widget _sectorMarker(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NunuColors.primaryMain.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: NunuColors.textSecondary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildTileWidget(_TileData tile) {
    final position = _tilePosition(tile.row, tile.col);
    final building = _buildings[tile.id];
    final selected = _selectedTileId == tile.id;
    final highlighted = _isHighlightedTile(tile.id);
    final isFull = building != null &&
        building.type != _BuildingType.hub &&
        building.stored >= _storageCap(building);
    final storageLabel = building == null || building.type == _BuildingType.hub
        ? null
        : '${building.stored}/${_storageCap(building)}';

    return Positioned(
      left: position.dx - (_tileWidth / 2),
      top: position.dy - 74,
      child: SizedBox(
        width: _tileWidth,
        height: 100,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            if (building != null)
              Positioned(
                bottom: 26,
                child: IgnorePointer(
                  child: _BuildingVisual(
                    emoji: _buildingEmoji(building.type),
                    color: _buildingColor(building.type),
                    selected: selected,
                    label: building.type == _BuildingType.hub
                        ? 'hq'
                        : 'l${building.level}',
                    pulse: building.stored > 0,
                    showLabel: selected,
                    isFull: isFull,
                  ),
                ),
              ),
            if (storageLabel != null)
              Positioned(
                bottom: 68,
                child: IgnorePointer(
                  child: _buildStorageBadge(storageLabel, isFull),
                ),
              ),
            Positioned(
              bottom: 16,
              child: IgnorePointer(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: selected ? 88 : 78,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: highlighted
                            ? NunuColors.primaryMain.withValues(alpha: 0.25)
                            : Colors.transparent,
                        blurRadius: 16,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              child: DragTarget<_BuildingType>(
                onWillAcceptWithDetails: (details) =>
                    _canPlaceBuildingOnTile(tile.id, details.data, strictTutorial: false),
                onAcceptWithDetails: (details) => _buildOnTile(tile.id, details.data),
                builder: (context, candidateData, rejectedData) {
                  final dragHover = candidateData.isNotEmpty;
                  return _DiamondTapRegion(
                    onTap: () => _selectTile(tile.id),
                    child: CustomPaint(
                      size: const Size(_tileWidth, _tileHeight),
                      painter: _TilePainter(
                        fill: _terrainColor(tile.terrain),
                        accent: _terrainAccent(tile.terrain),
                        selected: selected,
                        highlighted: highlighted || dragHover,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageBadge(String label, bool isFull) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: isFull
            ? NunuColors.errorMain.withValues(alpha: 0.96)
            : NunuColors.backgroundDefault,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFull
              ? NunuColors.errorLight.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.12),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Offset _tilePosition(int row, int col) {
    final x = (_mapWidth / 2) + (col - row) * (_tileWidth / 2);
    final y = 210 + (col + row) * (_tileHeight / 2);
    return Offset(x, y);
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF080816),
            Color(0xFF110F28),
            Color(0xFF090B20),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildMap()),
          _buildTopHud(),
          _buildRightRail(),
          if (_overlayPanel == _OverlayPanel.orders) _buildContractPanel(),
          if (_overlayPanel == _OverlayPanel.tutorial) _buildTutorialPanel(),
          _buildBottomPanel(),
          if (_overlayPanel == _OverlayPanel.build) _buildBuildTray(),
          if (_harvestSession != null) _buildHarvestOverlay(),
        ],
      ),
    );
  }

  Widget _buildHarvestOverlay() {
    final session = _harvestSession!;
    final isEggRun = session.goods == _Goods.eggs;
    final requiredSwipes = min(3, max(1, session.amount));
    final requiredTaps = max(2, session.amount * 2);

    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: Container(
            width: 260,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: NunuColors.primaryMain.withValues(alpha: 0.4)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'harvest ${_goodsLabel(session.goods)}',
                  style: const TextStyle(
                    color: NunuColors.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isEggRun
                      ? 'swipe into the basket $requiredSwipes time${requiredSwipes == 1 ? '' : 's'}'
                      : 'tap the drifting ${_goodsLabel(session.goods)} vein $requiredTaps times',
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 12),
                isEggRun
                    ? SizedBox(
                        height: 120,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final basketRect = Rect.fromLTWH(
                              constraints.maxWidth - 94,
                              34,
                              72,
                              52,
                            );
                            return Stack(
                              children: [
                                Positioned(
                                  left: basketRect.left,
                                  top: basketRect.top,
                                  child: Container(
                                    width: basketRect.width,
                                    height: basketRect.height,
                                    decoration: BoxDecoration(
                                      color: NunuColors.warningMain.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: NunuColors.warningLight.withValues(alpha: 0.7),
                                      ),
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '🧺',
                                        style: TextStyle(fontSize: 28),
                                      ),
                                    ),
                                  ),
                                ),
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 120),
                                  left: 18 + _harvestTokenOffset.dx,
                                  top: 38 + _harvestTokenOffset.dy,
                                  child: GestureDetector(
                                    onPanUpdate: (details) {
                                      setState(() {
                                        _harvestTokenOffset = Offset(
                                          (_harvestTokenOffset.dx + details.delta.dx)
                                              .clamp(0.0, constraints.maxWidth - 86),
                                          (_harvestTokenOffset.dy + details.delta.dy)
                                              .clamp(-14.0, 48.0),
                                        );
                                      });
                                    },
                                    onPanEnd: (_) {
                                      final tokenRect = Rect.fromLTWH(
                                        18 + _harvestTokenOffset.dx,
                                        38 + _harvestTokenOffset.dy,
                                        42,
                                        42,
                                      );
                                      final hitBasket = tokenRect.overlaps(basketRect);
                                      final shouldFinish =
                                          hitBasket && _harvestSwipesDone + 1 >= requiredSwipes;
                                      if (shouldFinish) {
                                        _finishHarvestMiniGame();
                                        return;
                                      }
                                      setState(() {
                                        _harvestTokenOffset = Offset.zero;
                                        if (hitBasket) {
                                          _harvestSwipesDone++;
                                        }
                                      });
                                    },
                                    child: _harvestToken(
                                      emoji: '🥚',
                                      color: _buildingColor(_BuildingType.coop),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      )
                    : SizedBox(
                        height: 120,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      NunuColors.backgroundDefault,
                                      NunuColors.backgroundPaper,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                            AnimatedPositioned(
                              duration: const Duration(milliseconds: 140),
                              left: _harvestTapTarget.dx,
                              top: _harvestTapTarget.dy,
                              child: GestureDetector(
                                onTap: _tapHarvestTarget,
                                child: _harvestToken(
                                  emoji: session.goods == _Goods.ore ? '🪨' : '🫧',
                                  color: _buildingColor(
                                    session.goods == _Goods.ore
                                        ? _BuildingType.drill
                                        : _BuildingType.lab,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                const SizedBox(height: 10),
                Text(
                  isEggRun
                      ? 'done $_harvestSwipesDone/$requiredSwipes'
                      : 'done $_harvestTapCount/$requiredTaps',
                  style: const TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _harvestToken({
    required String emoji,
    required Color color,
  }) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: NunuColors.backgroundDefault,
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}

class _TilePainter extends CustomPainter {
  const _TilePainter({
    required this.fill,
    required this.accent,
    required this.selected,
    required this.highlighted,
  });

  final Color fill;
  final Color accent;
  final bool selected;
  final bool highlighted;

  @override
  void paint(Canvas canvas, Size size) {
    final diamond = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();

    final shadow = Paint()
      ..color = Colors.black.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawPath(diamond.shift(const Offset(0, 5)), shadow);

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          accent.withValues(alpha: 0.22),
          fill,
          fill.withValues(alpha: 0.92),
        ],
      ).createShader(Offset.zero & size);
    canvas.drawPath(diamond, fillPaint);

    final linePaint = Paint()
      ..color = selected
          ? Colors.white
          : highlighted
          ? NunuColors.primaryLight
          : accent.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = selected ? 2.6 : 1.5;
    canvas.drawPath(diamond, linePaint);
  }

  @override
  bool shouldRepaint(covariant _TilePainter oldDelegate) {
    return fill != oldDelegate.fill ||
        accent != oldDelegate.accent ||
        selected != oldDelegate.selected ||
        highlighted != oldDelegate.highlighted;
  }
}

class _BuildingVisual extends StatelessWidget {
  const _BuildingVisual({
    required this.emoji,
    required this.color,
    required this.selected,
    required this.label,
    required this.pulse,
    required this.showLabel,
    required this.isFull,
  });

  final String emoji;
  final Color color;
  final bool selected;
  final String label;
  final bool pulse;
  final bool showLabel;
  final bool isFull;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: selected ? 1.04 : 1,
      duration: const Duration(milliseconds: 160),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              if (pulse)
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                ),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isFull ? NunuColors.errorMain.withValues(alpha: 0.22) : null,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      color,
                      color,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isFull
                        ? NunuColors.errorLight.withValues(alpha: 0.95)
                        : Colors.white.withValues(alpha: 0.28),
                    width: isFull ? 1.6 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFull
                          ? NunuColors.errorMain.withValues(alpha: 0.28)
                          : color.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (showLabel) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault.withValues(alpha: 0.84),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: NunuColors.textPrimary,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiamondTapRegion extends SingleChildRenderObjectWidget {
  const _DiamondTapRegion({
    required this.onTap,
    required super.child,
  });

  final VoidCallback onTap;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderDiamondTapRegion(onTap);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderDiamondTapRegion renderObject) {
    renderObject.onTap = onTap;
  }
}

class _RenderDiamondTapRegion extends RenderProxyBox {
  _RenderDiamondTapRegion(this.onTap) {
    _tapRecognizer = TapGestureRecognizer()..onTap = _handleTap;
  }

  late TapGestureRecognizer _tapRecognizer;
  VoidCallback onTap;

  void _handleTap() {
    onTap();
  }

  bool _contains(Offset localPosition) {
    final size = this.size;
    final center = Offset(size.width / 2, size.height / 2);
    final normalizedDx = (localPosition.dx - center.dx).abs() / (size.width / 2);
    final normalizedDy = (localPosition.dy - center.dy).abs() / (size.height / 2);
    return normalizedDx + normalizedDy <= 1;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_contains(position)) return false;
    return super.hitTest(result, position: position) || hitTestSelf(position);
  }

  @override
  bool hitTestSelf(Offset position) => _contains(position);

  @override
  void handleEvent(PointerEvent event, covariant HitTestEntry entry) {
    if (event is PointerDownEvent) {
      _tapRecognizer.addPointer(event);
    }
  }

  @override
  void detach() {
    _tapRecognizer.dispose();
    super.detach();
  }
}
