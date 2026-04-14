import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_components/mega_merge/header_bar.dart';
import '../level_components/mega_merge/profile_page.dart';
import '../level_components/mega_merge/settings_page.dart';
import '../level_components/mega_merge/shop_dialog.dart';
import '../level_components/mega_merge/tutorial_overlay.dart';
import '../level_components/mega_merge/unlock_popup.dart';
import '../level_widget.dart';

enum ItemType { generator, part }

class HardwareItem {
  final String id;
  final ItemType type;
  final int tier;
  final bool isFrozen;

  const HardwareItem({
    required this.id,
    required this.type,
    this.tier = 1,
    this.isFrozen = false,
  });

  HardwareItem copyWith({int? tier, bool? isFrozen}) {
    return HardwareItem(
      id: id,
      type: type,
      tier: tier ?? this.tier,
      isFrozen: isFrozen ?? this.isFrozen,
    );
  }
}

class OrderRequirement {
  final int targetTier;
  final int rewardPoints;

  const OrderRequirement({
    required this.targetTier,
    required this.rewardPoints,
  });
}

class LevelMegaMerge extends LevelWidget {
  const LevelMegaMerge({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelMegaMerge> createState() => _LevelMegaMergeState();
}

class _LevelMegaMergeState extends State<LevelMegaMerge> {
  static const int _cols = 8;
  static const int _rows = 10;
  static const int _totalCells = _cols * _rows;
  static const int _maxTier = 13;
  static const int _orderSlotCount = 5;
  static const int _maxEnergy = 120;
  static const int _scoreTarget = 20000;
  static const Duration _energyRegenInterval = Duration(seconds: 5);
  static const Duration _runDuration = Duration(minutes: 29, seconds: 59);

  final Random _random = Random();
  final Set<int> _manuallyUnlockedIndices = {};
  final Map<int, GlobalKey> _cellKeys = {};
  final Set<int> _unlockedTiers = {1};
  final Set<String> _claimedCoinPacks = {};
  final Set<String> _ownedCosmetics = {};
  final Map<String, DateTime> _activeBoosters = {};
  final GlobalKey _generatorKey = GlobalKey();
  final GlobalKey _energyKey = GlobalKey();
  final GlobalKey _coinsKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final List<GlobalKey> _orderKeys = List.generate(
    _orderSlotCount,
    (_) => GlobalKey(),
  );

  late List<HardwareItem?> _gridItems;
  late List<int> _gridUnlockLevels;
  late List<OrderRequirement> _orders;

  Timer? _energyTimer;
  Timer? _runTimer;
  DateTime _lastEnergyRegen = DateTime.now();
  late DateTime _runEndsAt;

  int _playerLevel = 1;
  int _currentXP = 0;
  int _xpForNextLevel = 100;
  int _coins = 100;
  int _energy = 60;
  int _sessionScore = 0;
  int _totalMerges = 0;
  int _highestTier = 1;
  int _ordersCompleted = 0;
  int _totalCoinsEarned = 100;
  int _selectedAvatar = 0;
  int? _focusedIndex;

  bool _isMenuOpen = false;
  bool _tutorialComplete = false;
  bool _runFinished = false;
  int _tutorialStep = 0;
  int _tutorialTapCount = 0;

  SettingsState _settings = const SettingsState();

  @override
  void initState() {
    super.initState();
    _initializeLevel();
    _lastEnergyRegen = DateTime.now();
    _runEndsAt = DateTime.now().add(_runDuration);
    _energyTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted || _runFinished) return;
        setState(() {
          _tickEnergyRegen();
        });
      },
    );
    _runTimer = Timer(_runDuration, _finishRun);
  }

  @override
  void dispose() {
    _energyTimer?.cancel();
    _runTimer?.cancel();
    super.dispose();
  }

  void _initializeLevel() {
    _highestTier = 1;

    const List<int> mapDesign = [
      -1, -1, 4, 5, 6, 7, -1, -1,
      -1, 3, 3, 4, 5, 6, 7, -1,
      2, 2, 2, 3, 3, 4, 6, 7,
      2, 1, 1, 0, 1, 2, 5, 6,
      1, 1, 0, 0, 0, 0, 4, 5,
      2, 1, 1, 0, 2, 1, 5, 6,
      3, 3, 2, 1, 1, 2, 6, 7,
      -1, 4, 4, 5, 6, 7, 8, -1,
      -1, -2, 5, 6, 7, 8, -2, -1,
      -1, -1, 6, 7, 8, 9, -1, -1,
    ];

    _gridUnlockLevels = List<int>.from(mapDesign);
    _gridItems = List<HardwareItem?>.filled(_totalCells, null);
    _manuallyUnlockedIndices.clear();
    _cellKeys.clear();
    _unlockedTiers
      ..clear()
      ..add(1);

    _gridItems[_index(4, 3)] = const HardwareItem(
      id: 'gen_1',
      type: ItemType.generator,
      tier: 0,
    );

    _placeFrozenItem(5, 4, 2);
    _placeFrozenItem(4, 6, 3);
    _placeFrozenItem(3, 6, 4);
    _placeFrozenItem(2, 6, 5);
    _placeFrozenItem(1, 6, 6);
    _placeFrozenItem(0, 5, 7);
    _placeFrozenItem(7, 5, 8);
    _placeFrozenItem(7, 6, 9);
    _placeFrozenItem(8, 5, 10);
    _placeFrozenItem(9, 5, 11);
    _placeFrozenItem(9, 4, 12);
    _placeFrozenItem(8, 2, 13);

    _orders = List.generate(_orderSlotCount, (_) => _createOrder());
  }

  void _placeFrozenItem(int row, int col, int tier) {
    final index = _index(row, col);
    if (_gridUnlockLevels[index] <= 0) return;
    _gridItems[index] = HardwareItem(
      id: 'frozen_${row}_$col',
      type: ItemType.part,
      tier: tier,
      isFrozen: true,
    );
  }

  int _index(int row, int col) => row * _cols + col;

  bool _isCellUnlocked(int index) {
    if (_manuallyUnlockedIndices.contains(index)) return true;
    final required = _gridUnlockLevels[index];
    return required == 0 || (required > 0 && _playerLevel >= required);
  }

  bool _isCellBlocked(int index) => _gridUnlockLevels[index] == -1;

  bool _isCellRock(int index) => _gridUnlockLevels[index] == -2;

  bool _isBoosterActive(String id) {
    final expiresAt = _activeBoosters[id];
    if (expiresAt == null) return false;
    return expiresAt.isAfter(DateTime.now());
  }

  void _pruneExpiredBoosters() {
    final now = DateTime.now();
    _activeBoosters.removeWhere((_, expiresAt) => !expiresAt.isAfter(now));
  }

  void _tickEnergyRegen() {
    _pruneExpiredBoosters();

    final now = DateTime.now();
    if (_energy >= _maxEnergy) {
      _lastEnergyRegen = now;
      return;
    }

    final interval = _isBoosterActive('boost_speed')
        ? const Duration(seconds: 2)
        : _energyRegenInterval;
    final elapsedSeconds = now.difference(_lastEnergyRegen).inSeconds;
    if (elapsedSeconds < interval.inSeconds) return;

    final gained = elapsedSeconds ~/ interval.inSeconds;
    _lastEnergyRegen = _lastEnergyRegen.add(
      Duration(seconds: gained * interval.inSeconds),
    );
    _energy = min(_maxEnergy, _energy + gained);
  }

  String get _remainingTimeLabel {
    final remaining = _runEndsAt.difference(DateTime.now());
    final clamped = remaining.isNegative ? Duration.zero : remaining;
    final minutes = clamped.inMinutes.toString().padLeft(2, '0');
    final seconds = (clamped.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _addXP(int amount) {
    _currentXP += amount;
    while (_currentXP >= _xpForNextLevel) {
      _currentXP -= _xpForNextLevel;
      _playerLevel++;
      _xpForNextLevel = (_xpForNextLevel * 1.5).round();

      if (_settings.vibrationEnabled) {
        HapticFeedback.heavyImpact();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('level up! now level $_playerLevel'),
          duration: const Duration(milliseconds: 900),
          backgroundColor: NunuColors.primaryMain,
        ),
      );
    }
  }

  void _spawnItem() {
    if (_runFinished) return;

    if (!_tutorialComplete && _tutorialStep == 0) {
      _tutorialTapCount++;
      if (_tutorialTapCount >= 2) {
        _advanceTutorial();
      }
    }

    _tickEnergyRegen();

    final spawnCount = _isBoosterActive('boost_extra') ? 2 : 1;
    final energyCost = _isBoosterActive('boost_speed') ? 0 : 1;

    if (_energy < energyCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('no energy! buy more in the shop.'),
          duration: Duration(milliseconds: 700),
          backgroundColor: NunuColors.errorMain,
        ),
      );
      return;
    }

    final emptyIndices = <int>[];
    for (var i = 0; i < _totalCells; i++) {
      if (_gridItems[i] == null && _isCellUnlocked(i)) {
        emptyIndices.add(i);
      }
    }

    if (emptyIndices.length < spawnCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('no space to spawn items!'),
          duration: Duration(milliseconds: 500),
          backgroundColor: NunuColors.errorMain,
        ),
      );
      return;
    }

    setState(() {
      _energy = max(0, _energy - energyCost);

      final spawnTargets = <int>[];
      for (var spawnIndex = 0; spawnIndex < spawnCount; spawnIndex++) {
        var targetIndex = -1;
        if (!_tutorialComplete && _tutorialStep == 0 && spawnIndex == 0) {
          if (_tutorialTapCount == 1) targetIndex = _index(4, 4);
          if (_tutorialTapCount == 2) targetIndex = _index(4, 5);
        }
        if (targetIndex != -1 &&
            (_gridItems[targetIndex] != null || spawnTargets.contains(targetIndex))) {
          targetIndex = -1;
        }
        if (targetIndex == -1) {
          final available = emptyIndices
              .where((index) => !spawnTargets.contains(index))
              .toList();
          targetIndex = available[_random.nextInt(available.length)];
        }

        _gridItems[targetIndex] = HardwareItem(
          id: '${DateTime.now().microsecondsSinceEpoch}_$spawnIndex',
          type: ItemType.part,
          tier: 1,
        );
        spawnTargets.add(targetIndex);
        _focusedIndex = targetIndex;
      }

      _processAutoMerge();
    });

    if (_settings.vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _onItemMove(int fromIndex, int toIndex) {
    if (_runFinished || fromIndex == toIndex) return;

    if (!_tutorialComplete) {
      if (_tutorialStep == 1) {
        if (fromIndex != _index(4, 5) || toIndex != _index(4, 4)) return;
      } else if (_tutorialStep == 2) {
        if (fromIndex != _index(4, 4) || toIndex != _index(5, 4)) return;
      }
    }

    final source = _gridItems[fromIndex];
    if (source == null || source.isFrozen) return;

    final target = _gridItems[toIndex];
    final isMergeWithFrozen =
        target != null &&
        target.isFrozen &&
        source.type == target.type &&
        source.tier == target.tier;

    if (!_isCellUnlocked(toIndex) && !isMergeWithFrozen) return;

    setState(() {
      if (target == null) {
      _gridItems[toIndex] = source;
      _gridItems[fromIndex] = null;
      _focusedIndex = toIndex;
      _processAutoMerge();
      return;
    }

      if (source.type == ItemType.part &&
          target.type == ItemType.part &&
          source.tier == target.tier &&
          source.tier < _maxTier) {
        if (target.isFrozen) {
          _gridItems[toIndex] = target.copyWith(isFrozen: false);
          _gridItems[fromIndex] = null;
          _manuallyUnlockedIndices.add(toIndex);
          _focusedIndex = toIndex;

          if (_settings.vibrationEnabled) {
            HapticFeedback.heavyImpact();
          }

          _maybeShowUnlock(target.tier);

          if (!_tutorialComplete && _tutorialStep == 2) {
            _advanceTutorial();
          }
          _processAutoMerge();
          return;
        }

        final newTier = target.tier + 1;
        _gridItems[toIndex] = target.copyWith(tier: newTier);
        _gridItems[fromIndex] = null;
        _focusedIndex = toIndex;
        _totalMerges++;
        _highestTier = max(_highestTier, newTier);
        _coins += newTier * 2;
        _totalCoinsEarned += newTier * 2;
        _addXP(newTier * 6);
        _maybeShowUnlock(newTier);

        if (_settings.vibrationEnabled) {
          HapticFeedback.lightImpact();
        }

        if (!_tutorialComplete && _tutorialStep == 1) {
          _advanceTutorial();
        }
        _processAutoMerge();
        return;
      }

      if (target.isFrozen) return;
      if (!_isCellUnlocked(toIndex) || !_isCellUnlocked(fromIndex)) return;

      _gridItems[toIndex] = source;
      _gridItems[fromIndex] = target;
      _focusedIndex = toIndex;
      _processAutoMerge();
    });
  }

  void _onItemDelivered(int fromIndex, int orderIndex) {
    if (_runFinished) return;

    final item = _gridItems[fromIndex];
    if (item == null) return;

    final order = _orders[orderIndex];
    if (item.type != ItemType.part || item.tier != order.targetTier) return;

    setState(() {
      _gridItems[fromIndex] = null;
      _ordersCompleted++;
      _sessionScore += order.rewardPoints;
      _coins += order.rewardPoints ~/ 3;
      _energy = min(_maxEnergy, _energy + 4);
      _totalCoinsEarned += order.rewardPoints ~/ 3;
      _orders[orderIndex] = _createOrder();

      if (_settings.vibrationEnabled) {
        HapticFeedback.mediumImpact();
      }
    });
  }

  OrderRequirement _createOrder() {
    final maxTargetTier = max(4, min(_maxTier, _highestTier + 1));
    final minTargetTier = max(4, maxTargetTier - 3);
    final targetTier =
        minTargetTier + _random.nextInt(maxTargetTier - minTargetTier + 1);
    final reward = (
        (targetTier * targetTier * 25) +
        (max(0, targetTier - 6) * max(0, targetTier - 6) * 120))
        .toInt();
    return OrderRequirement(targetTier: targetTier, rewardPoints: reward);
  }

  Iterable<int> _adjacentIndices(int index) sync* {
    final row = index ~/ _cols;
    final col = index % _cols;
    if (row > 0) yield _index(row - 1, col);
    if (row < _rows - 1) yield _index(row + 1, col);
    if (col > 0) yield _index(row, col - 1);
    if (col < _cols - 1) yield _index(row, col + 1);
  }

  void _processAutoMerge() {
    if (!_isBoosterActive('boost_auto')) return;

    var merged = true;
    while (merged) {
      merged = false;
      for (var index = 0; index < _totalCells; index++) {
        final item = _gridItems[index];
        if (item == null ||
            item.type != ItemType.part ||
            item.isFrozen ||
            item.tier != 1) {
          continue;
        }

        for (final neighborIndex in _adjacentIndices(index)) {
          final neighbor = _gridItems[neighborIndex];
          if (neighbor == null ||
              neighbor.type != ItemType.part ||
              neighbor.isFrozen ||
              neighbor.tier != 1) {
            continue;
          }

          _gridItems[index] = item.copyWith(tier: 2);
          _gridItems[neighborIndex] = null;
          _focusedIndex = index;
          _totalMerges++;
          _highestTier = max(_highestTier, 2);
          _coins += 4;
          _totalCoinsEarned += 4;
          _addXP(12);
          _maybeShowUnlock(2);
          merged = true;
          break;
        }

        if (merged) {
          break;
        }
      }
    }
  }

  void _activateBooster(String id) {
    setState(() {
      _activeBoosters[id] = DateTime.now().add(const Duration(seconds: 30));
      if (id == 'boost_auto') {
        _processAutoMerge();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('booster activated: $id'),
        backgroundColor: NunuColors.successMain,
      ),
    );
  }

  void _showUnlockPopup(int tier) {
    showUnlockPopup(
      context: context,
      itemName: _getNameForTier(tier),
      itemIcon: _getIconForTier(tier),
      itemColor: _getColorForTier(tier),
      tier: tier,
      onOk: () {},
      onShop: _openShop,
    );
  }

  void _maybeShowUnlock(int tier) {
    if (_unlockedTiers.contains(tier)) return;
    _unlockedTiers.add(tier);
    _showUnlockPopup(tier);
  }

  void _advanceTutorial() {
    setState(() {
      _tutorialTapCount = 0;
      if (_tutorialStep < _tutorialSteps.length - 1) {
        _tutorialStep++;
      } else {
        _tutorialComplete = true;
      }
    });
  }

  List<TutorialStep> get _tutorialSteps => [
    TutorialStep(
      instruction: 'tap the generator twice to make two starter parts.',
      targetKey: _generatorKey,
      requiresTap: true,
    ),
    TutorialStep(
      instruction: 'drag matching parts together to merge them.',
      sourceKey: _getCellKey(_index(4, 5)),
      destinationKey: _getCellKey(_index(4, 4)),
      targetKey: _getCellKey(_index(4, 4)),
      requiresDrag: true,
    ),
    TutorialStep(
      instruction: 'drag that part onto the frozen one to unlock the cell.',
      sourceKey: _getCellKey(_index(4, 4)),
      destinationKey: _getCellKey(_index(5, 4)),
      targetKey: _getCellKey(_index(5, 4)),
      requiresDrag: true,
    ),
  ];

  GlobalKey _getCellKey(int index) {
    return _cellKeys.putIfAbsent(index, () => GlobalKey());
  }

  void _finishRun() {
    if (!mounted || _runFinished) return;
    _runFinished = true;
    widget.onComplete(
      LevelOutcome(
        score: ((_sessionScore / _scoreTarget).clamp(0.0, 1.0) as num)
            .toDouble(),
        metrics: {
          'score_points': _sessionScore,
          'orders_completed': _ordersCompleted,
          'highest_tier': _highestTier,
          'merges': _totalMerges,
        },
      ),
    );
  }

  void _openShop() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: ShopDialog(
              currentCoins: _coins,
              currentEnergy: _energy,
              maxEnergy: _maxEnergy,
              ownedCosmetics: _ownedCosmetics,
              claimedCoinPacks: _claimedCoinPacks,
              onClaimCoins: (packId, amount) {
                setState(() {
                  _claimedCoinPacks.add(packId);
                  _coins += amount;
                  _totalCoinsEarned += amount;
                });
              },
              onBuyEnergy: (amount) {
                setState(() {
                  _energy = min(_energy + amount, _maxEnergy);
                });
              },
              onBuyBooster: (id) {
                _activateBooster(id);
              },
              onBuyCosmetic: (id) {
                setState(() {
                  _ownedCosmetics.add(id);
                });
              },
            ),
          ),
        );
      },
    );
  }

  void _openProfile() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: ProfilePage(
              playerLevel: _playerLevel,
              stats: PlayerStats(
                totalMerges: _totalMerges,
                highestTier: _highestTier,
                ordersCompleted: _ordersCompleted,
                totalCoinsEarned: _totalCoinsEarned,
                levelsReached: _playerLevel,
              ),
              selectedAvatar: _selectedAvatar,
              onAvatarChanged: (avatar) {
                setState(() => _selectedAvatar = avatar);
              },
            ),
          ),
        );
      },
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: SettingsPage(
              settings: _settings,
              onSettingsChanged: (settings) {
                setState(() => _settings = settings);
              },
              onResetProgress: () {
                setState(() {
                  _runTimer?.cancel();
                  _initializeLevel();
                  _playerLevel = 1;
                  _currentXP = 0;
                  _xpForNextLevel = 100;
                  _coins = 100;
                  _energy = 60;
                  _sessionScore = 0;
                  _totalMerges = 0;
                  _ordersCompleted = 0;
                  _totalCoinsEarned = 100;
                  _tutorialStep = 0;
                  _tutorialTapCount = 0;
                  _tutorialComplete = false;
                  _focusedIndex = null;
                  _activeBoosters.clear();
                  _ownedCosmetics.clear();
                  _claimedCoinPacks.clear();
                  _lastEnergyRegen = DateTime.now();
                  _runEndsAt = DateTime.now().add(_runDuration);
                  _runFinished = false;
                  _runTimer = Timer(_runDuration, _finishRun);
                });
              },
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForTier(int tier) {
    switch (tier) {
      case 1:
        return Icons.flash_on;
      case 2:
        return Icons.settings;
      case 3:
        return Icons.memory;
      case 4:
        return Icons.developer_board;
      case 5:
        return Icons.battery_charging_full;
      case 6:
        return Icons.smart_toy;
      case 7:
        return Icons.router;
      case 8:
        return Icons.rocket_launch;
      case 9:
        return Icons.device_hub;
      case 10:
        return Icons.cloud;
      case 11:
        return Icons.build;
      case 12:
        return Icons.star;
      case 13:
        return Icons.bolt;
      default:
        return Icons.help_outline;
    }
  }

  Color _getColorForTier(int tier) {
    switch (tier) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.teal;
      case 4:
        return Colors.green;
      case 5:
        return Colors.blue;
      case 6:
        return Colors.purpleAccent;
      case 7:
        return Colors.deepPurple;
      case 8:
        return Colors.pinkAccent;
      case 9:
        return Colors.cyanAccent;
      case 10:
        return Colors.indigoAccent;
      case 11:
        return Colors.redAccent;
      case 12:
        return Colors.limeAccent;
      case 13:
        return Colors.yellowAccent;
      default:
        return Colors.white;
    }
  }

  String _getNameForTier(int tier) {
    switch (tier) {
      case 1:
        return 'spark';
      case 2:
        return 'gear';
      case 3:
        return 'motor';
      case 4:
        return 'chip';
      case 5:
        return 'battery';
      case 6:
        return 'robot';
      case 7:
        return 'server';
      case 8:
        return 'ai core';
      case 9:
        return 'relay';
      case 10:
        return 'cloud node';
      case 11:
        return 'forge';
      case 12:
        return 'star drive';
      case 13:
        return 'storm engine';
      default:
        return '???';
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = !_tutorialComplete && _tutorialStep < _tutorialSteps.length
        ? _tutorialSteps[_tutorialStep]
        : null;

    final content = Stack(
      children: [
        Container(
          color: NunuColors.backgroundDefault,
          child: Column(
            children: [
              MegaMergeHeaderBar(
                playerLevel: _playerLevel,
                currentXP: _currentXP,
                xpForNextLevel: _xpForNextLevel,
                coins: _coins,
                energy: _energy,
                maxEnergy: _maxEnergy,
                energyKey: _energyKey,
                coinsKey: _coinsKey,
                menuKey: _menuKey,
                onMenuPressed: () => setState(() => _isMenuOpen = true),
              ),
              _buildOrdersRow(),
              Expanded(child: _buildGrid()),
              _buildFooter(),
            ],
          ),
        ),
        if (_isMenuOpen) ...[
          GestureDetector(
            onTap: () => setState(() => _isMenuOpen = false),
            child: Container(color: Colors.black54),
          ),
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: MegaMergeMenuDrawer(
              onShopPressed: _openShop,
              onProfilePressed: _openProfile,
              onSettingsPressed: _openSettings,
              onClose: () => setState(() => _isMenuOpen = false),
            ),
          ),
        ],
      ],
    );

    if (step != null) {
      return TutorialOverlay(
        step: step,
        onStepComplete: _advanceTutorial,
        child: content,
      );
    }

    return content;
  }

  Widget _buildOrdersRow() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      color: NunuColors.backgroundPaper.withOpacity(0.5),
      child: Row(
        children: List.generate(_orders.length, (index) {
          final order = _orders[index];
          final icon = _getIconForTier(order.targetTier);
          final color = _getColorForTier(order.targetTier);

          return Expanded(
            child: KeyedSubtree(
              key: _orderKeys[index],
              child: DragTarget<int>(
                onWillAccept: (fromIndex) {
                  if (fromIndex == null) return false;
                  final item = _gridItems[fromIndex];
                  return item != null &&
                      item.type == ItemType.part &&
                      item.tier == order.targetTier;
                },
                onAccept: (fromIndex) => _onItemDelivered(fromIndex, index),
                builder: (context, candidateData, rejectedData) {
                  final isCandidateValid = candidateData.isNotEmpty;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: NunuColors.backgroundDefault,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isCandidateValid
                                ? NunuColors.primaryMain
                                : NunuColors.textSecondary.withOpacity(0.3),
                            width: isCandidateValid ? 3 : 2,
                          ),
                        ),
                        child: Icon(icon, color: color, size: 24),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getNameForTier(order.targetTier),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          color: NunuColors.textPrimary,
                        ),
                      ),
                      Text(
                        '+${order.rewardPoints}',
                        style: TextStyle(
                          fontSize: 9,
                          color: NunuColors.warningMain.withOpacity(0.9),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellWidth = constraints.maxWidth / _cols;
        final cellHeight = constraints.maxHeight / _rows;
        final size = min(cellWidth, cellHeight);

        return Center(
          child: SizedBox(
            width: size * _cols,
            height: size * _rows,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                childAspectRatio: 1,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _totalCells,
              itemBuilder: (context, index) => _buildCell(index),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int index) {
    final isBlocked = _isCellBlocked(index);
    final isRock = _isCellRock(index);
    final isUnlocked = _isCellUnlocked(index);
    final item = _gridItems[index];
    final isFocused = _focusedIndex == index;
    final isGenerator = item?.type == ItemType.generator;

    return DragTarget<int>(
      onWillAccept: (fromIndex) {
        if (fromIndex == null || fromIndex == index) return false;
        if (isUnlocked) return true;

        if (!isUnlocked && item != null && item.isFrozen) {
          final source = _gridItems[fromIndex];
          return source != null &&
              source.type == item.type &&
              source.tier == item.tier;
        }
        return false;
      },
      onAccept: (fromIndex) => _onItemMove(fromIndex, index),
      builder: (context, candidateData, rejectedData) {
        var bgColor = NunuColors.backgroundPaper;
        Widget? content;

        if (isBlocked) {
          bgColor = Colors.black26;
          content = const Icon(Icons.block, color: Colors.white10, size: 16);
        } else if (isRock) {
          bgColor = Colors.brown.shade900.withOpacity(0.5);
          content = Icon(Icons.terrain, color: Colors.brown.shade400, size: 18);
        } else if (item != null) {
          content = _buildDraggableItem(index, item);
          if (!isUnlocked) {
            bgColor = NunuColors.backgroundDefault.withOpacity(0.5);
          }
        } else if (!isUnlocked) {
          bgColor = NunuColors.backgroundDefault.withOpacity(0.5);
          content = Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock, color: Colors.white24, size: 14),
              const SizedBox(height: 2),
              Text(
                'lv${_gridUnlockLevels[index]}',
                style: const TextStyle(color: Colors.white24, fontSize: 9),
              ),
            ],
          );
        }

        if (candidateData.isNotEmpty) {
          if (item != null) {
            final fromIndex = candidateData.first;
            if (fromIndex != null) {
              final source = _gridItems[fromIndex];
              if (source != null &&
                  source.type == ItemType.part &&
                  item.type == ItemType.part &&
                  source.tier == item.tier &&
                  source.tier < _maxTier) {
                bgColor = NunuColors.primaryMain.withOpacity(0.3);
              }
            }
          } else if (isUnlocked) {
            bgColor = bgColor.withOpacity(0.8);
          }
        }

        final cellWidget = Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: isFocused
                ? Border.all(color: NunuColors.primaryMain, width: 2)
                : Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: content,
        );

        final gestureWrapped = GestureDetector(
          onTap: () {
            if (!isUnlocked) return;
            setState(() {
              _focusedIndex = index;
            });
            if (isGenerator) {
              _spawnItem();
            }
          },
          child: cellWidget,
        );

        return KeyedSubtree(
          key: isGenerator ? _generatorKey : _getCellKey(index),
          child: gestureWrapped,
        );
      },
    );
  }

  Widget _buildDraggableItem(int index, HardwareItem item) {
    late final Widget child;

    if (item.type == ItemType.generator) {
      child = Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: NunuColors.secondaryMain,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Icon(Icons.inventory_2, color: Colors.white, size: 22),
        ),
      );
    } else {
      final itemColor = item.isFrozen ? Colors.grey : _getColorForTier(item.tier);
      child = Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: itemColor, width: 2),
        ),
        child: Center(
          child: Icon(_getIconForTier(item.tier), color: itemColor, size: 20),
        ),
      );
    }

    return Draggable<int>(
      data: index,
      maxSimultaneousDrags: item.isFrozen ? 0 : 1,
      feedback: SizedBox(
        width: 50,
        height: 50,
        child: Material(color: Colors.transparent, child: child),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: NunuColors.backgroundPaper,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFooterStat('time', _remainingTimeLabel),
            _buildFooterStat('score', '$_sessionScore'),
            _buildFooterStat('orders', '$_ordersCompleted'),
            _buildFooterStat('best tier', '$_highestTier'),
            _buildFooterStat(
              'boost',
              _activeBoosters.isEmpty
                  ? '-'
                  : _activeBoosters.keys
                      .where(_isBoosterActive)
                      .map((id) => id.replaceFirst('boost_', ''))
                      .join('/'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: NunuColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: NunuColors.textSecondary.withOpacity(0.9),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
