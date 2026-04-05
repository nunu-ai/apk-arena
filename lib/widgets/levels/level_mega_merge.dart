import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/mega_merge/header_bar.dart';
import '../level_components/mega_merge/shop_dialog.dart';
import '../level_components/mega_merge/profile_page.dart';
import '../level_components/mega_merge/settings_page.dart';
import '../level_components/mega_merge/unlock_popup.dart';
import '../level_components/mega_merge/tutorial_overlay.dart';

// -----------------------------------------------------------------------------
// Data Models
// -----------------------------------------------------------------------------

enum ItemType { generator, part }

class HardwareItem {
  final String id;
  final ItemType type;
  final int tier; // 1..8 for parts, 0 for generator
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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HardwareItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type &&
          tier == other.tier &&
          isFrozen == other.isFrozen;

  @override
  int get hashCode =>
      id.hashCode ^ type.hashCode ^ tier.hashCode ^ isFrozen.hashCode;
}

/// Represents the requirement for a specific tier.
class OrderRequirement {
  final int targetTier;
  bool isCompleted;

  OrderRequirement({required this.targetTier, this.isCompleted = false});
}

// -----------------------------------------------------------------------------
// Level Implementation
// -----------------------------------------------------------------------------

class LevelMegaMerge extends LevelWidget {
  const LevelMegaMerge({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelMegaMerge> createState() => _LevelMegaMergeState();
}

class _LevelMegaMergeState extends State<LevelMegaMerge>
    with TickerProviderStateMixin {
  // Grid Configuration
  static const int _cols = 7;
  static const int _rows = 9;
  static const int _totalCells = _cols * _rows;
  static const Duration _energyRegenInterval = Duration(seconds: 30);

  // Items
  static const int _maxTier = 8;

  // Game State
  late List<HardwareItem?> _gridItems;
  late List<int> _gridUnlockLevels; // 0=unlocked, N=level, -1=blocked, -2=rock
  final Set<int> _manuallyUnlockedIndices = {};
  final Map<int, GlobalKey> _cellKeys = {};
  int _generatorIndex = 0;

  int _playerLevel = 1;
  int _currentXP = 0;
  int _xpForNextLevel = 100;

  // Economy
  int _coins = 100;
  int _energy = 20;
  static const int _maxEnergy = 50;
  Set<String> _ownedCosmetics = {};
  final Set<String> _claimedCoinPacks = {};
  Timer? _energyTimer;
  DateTime _lastEnergyRegen = DateTime.now();
  final Set<int> _unlockedTiers = {1};

  // Stats (for profile)
  int _totalMerges = 0;
  int _highestTier = 1;
  int _ordersCompleted = 0;
  int _totalCoinsEarned = 100;

  // Settings
  SettingsState _settings = const SettingsState();
  int _selectedAvatar = 0;

  // Orders: Robot (6), Battery (5), Chip (4)
  late List<OrderRequirement> _orders;

  // UI State
  int? _focusedIndex;
  bool _isMenuOpen = false;

  // Tutorial State
  int _tutorialStep = 0;
  int _tutorialTapCount = 0;
  int _tutorialChipIndex = -1;
  bool _tutorialComplete = false;

  // Keys for tutorial targeting
  final GlobalKey _generatorKey = GlobalKey();
  final GlobalKey _energyKey = GlobalKey();
  final GlobalKey _coinsKey = GlobalKey();
  final GlobalKey _menuKey = GlobalKey();
  final List<GlobalKey> _orderKeys = List.generate(4, (_) => GlobalKey());

  @override
  void initState() {
    super.initState();
    _initializeLevel();
    _lastEnergyRegen = DateTime.now();
    _energyTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _tickEnergyRegen(),
    );
  }

  @override
  void dispose() {
    _energyTimer?.cancel();
    super.dispose();
  }

  void _initializeLevel() {
    // 1. Initialize Orders
    _orders = [
      OrderRequirement(targetTier: 7), // Server
      OrderRequirement(targetTier: 6), // Robot
      OrderRequirement(targetTier: 5), // Battery
      OrderRequirement(targetTier: 4), // Chip
    ];

    // 2. Initialize Map (7x9) using the original Hardware Merge layout
    // 0: Unlocked, N: Locked until Lvl N, -1: Blocked, -2: rock (blocked alt)
    const List<int> mapDesign = [
      // Row 0
      -1, -1, 3, 4, -1, -1, -2,
      // Row 1
      -2, 5, 5, 7, 4, -1, -2,
      // Row 2
      -1, 3, 5, 5, 6, 7, -1,
      // Row 3
      5, 3, 0, 0, 0, 6, -1,
      // Row 4
      -1, 3, 6, 4, 6, -1, -1,
      // Row 5
      -1, 3, 8, -1, -1, -1, -1,
      // Row 6
      -1, 4, 4, 3, -2, -2, -1,
      // Row 7
      -1, -2, -2, 4, 4, -1, -1,
      // Row 8
      -1, -2, -1, 5, -1, -2, -2,
    ];

    _gridUnlockLevels = List.from(mapDesign);
    _manuallyUnlockedIndices.clear();
    _unlockedTiers
      ..clear()
      ..add(1);

    // 3. Initialize Items
    _gridItems = List<HardwareItem?>.filled(_totalCells, null);

    // Place Generator in the cluster at [3, 2]
    _generatorIndex = _index(3, 2);
    _gridItems[_generatorIndex] = const HardwareItem(
      id: 'gen_1',
      type: ItemType.generator,
      tier: 0,
    );

    // Place frozen items mirroring the original progression
    _placeFrozenItem(4, 2, 2); // Gear (Lvl 2 unlock)
    _placeFrozenItem(2, 4, 3); // Motor (Lvl 3 unlock)
    _placeFrozenItem(1, 2, 4); // Chip (Lvl 4 unlock)
    _placeFrozenItem(1, 3, 5); // Battery (Lvl 5 unlock)
    _placeFrozenItem(3, 5, 6); // Robot (Lvl 6 unlock)
    _placeFrozenItem(4, 3, 7); // Server (Lvl 7 unlock)
    _placeFrozenItem(5, 2, 8); // AI Core (Lvl 8 unlock)
  }

  void _placeFrozenItem(int r, int c, int tier) {
    int index = r * _cols + c;
    if (index >= 0 && index < _totalCells) {
      final cellLevel = _gridUnlockLevels[index];
      if (cellLevel > 0) {
        // Only on locked cells
        _gridItems[index] = HardwareItem(
          id: 'frozen_${r}_$c',
          type: ItemType.part,
          tier: tier,
          isFrozen: true,
        );
      }
    }
  }

  int _index(int r, int c) => r * _cols + c;

  // ---------------------------------------------------------------------------
  // Game Logic
  // ---------------------------------------------------------------------------

  void _tickEnergyRegen() {
    final now = DateTime.now();
    if (_energy >= _maxEnergy) {
      _lastEnergyRegen = now;
      return;
    }

    final elapsedSeconds = now.difference(_lastEnergyRegen).inSeconds;
    if (elapsedSeconds >= _energyRegenInterval.inSeconds) {
      final gained = elapsedSeconds ~/ _energyRegenInterval.inSeconds;
      _lastEnergyRegen = _lastEnergyRegen.add(
        Duration(seconds: gained * _energyRegenInterval.inSeconds),
      );
      setState(() {
        _energy = min(_maxEnergy, _energy + gained);
      });
    }
  }

  bool _isCellUnlocked(int index) {
    if (_manuallyUnlockedIndices.contains(index)) return true;
    int required = _gridUnlockLevels[index];
    return required == 0 || (required > 0 && _playerLevel >= required);
  }

  bool _isCellBlocked(int index) {
    return _gridUnlockLevels[index] == -1;
  }

  bool _isCellRock(int index) {
    return _gridUnlockLevels[index] == -2;
  }

  void _addXP(int amount) {
    setState(() {
      _currentXP += amount;
      while (_currentXP >= _xpForNextLevel) {
        _currentXP -= _xpForNextLevel;
        _playerLevel++;
        _xpForNextLevel = (_xpForNextLevel * 1.8).round();

        if (_settings.vibrationEnabled) {
          HapticFeedback.heavyImpact();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('level up! now level $_playerLevel'),
            duration: const Duration(seconds: 1),
            backgroundColor: NunuColors.primaryMain,
          ),
        );
      }
    });
  }

  void _spawnItem() {
    if (!_tutorialComplete &&
        _tutorialSteps.isNotEmpty &&
        _tutorialSteps[_tutorialStep].targetKey == _generatorKey) {
      _tutorialTapCount++;
      if (_tutorialTapCount >= 2) {
        _advanceTutorial();
      }
    }

    _tickEnergyRegen();

    // Check energy
    if (_energy <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('no energy! buy more in the shop.'),
          duration: Duration(milliseconds: 800),
          backgroundColor: NunuColors.errorMain,
        ),
      );
      return;
    }

    // Find all empty unlocked cells
    List<int> emptyIndices = [];
    for (int i = 0; i < _totalCells; i++) {
      if (_gridItems[i] == null && _isCellUnlocked(i)) {
        emptyIndices.add(i);
      }
    }

    if (emptyIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('no space to spawn items!'),
          duration: Duration(milliseconds: 500),
          backgroundColor: NunuColors.errorMain,
        ),
      );
      return;
    }

    // Consume energy
    setState(() {
      _energy--;
    });

    // Pick random spot
    int targetIndex = -1;

    if (!_tutorialComplete && _tutorialStep == 0) {
      if (_tutorialTapCount == 1) {
        targetIndex = _index(3, 3);
      } else if (_tutorialTapCount == 2) {
        targetIndex = _index(3, 4);
      }
    }

    if (targetIndex != -1) {
      if (_gridItems[targetIndex] != null) {
        targetIndex = -1; // Fallback to random if occupied
      }
    }

    if (targetIndex == -1) {
      targetIndex = emptyIndices[Random().nextInt(emptyIndices.length)];
    }

    setState(() {
      _gridItems[targetIndex] = HardwareItem(
        id: DateTime.now().toIso8601String(),
        type: ItemType.part,
        tier: 1,
      );
    });

    if (_settings.vibrationEnabled) {
      HapticFeedback.lightImpact();
    }
  }

  void _onItemMove(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    // Strict tutorial enforcement for drag step
    if (!_tutorialComplete) {
      if (_tutorialStep == 1) {
        final int sourceIndex = _index(3, 4);
        final int destIndex = _index(3, 3);
        // Only allow the specific drag: source -> dest
        if (fromIndex != sourceIndex || toIndex != destIndex) return;
      } else if (_tutorialStep == 2) {
        final int sourceIndex = _index(3, 3);
        final int destIndex = _index(4, 2); // Frozen gear location
        // Only allow the specific drag: source -> dest
        if (fromIndex != sourceIndex || toIndex != destIndex) return;
      } else if (_tutorialStep == 5) {
        // Step 5: Delivery only. No grid-to-grid moves allowed.
        return;
      }
    }

    final source = _gridItems[fromIndex];
    if (source == null) return;
    if (source.isFrozen) return;

    final target = _gridItems[toIndex];

    bool isMergeWithFrozen = false;
    if (target != null &&
        target.isFrozen &&
        source.type == target.type &&
        source.tier == target.tier) {
      isMergeWithFrozen = true;
    }

    if (!_isCellUnlocked(toIndex) && !isMergeWithFrozen) return;

    setState(() {
      if (target == null) {
        // Move to empty slot
        _gridItems[toIndex] = source;
        _gridItems[fromIndex] = null;
        _focusedIndex = toIndex;
      } else {
        // Attempt Merge
        if (source.type == ItemType.part &&
            target.type == ItemType.part &&
            source.tier == target.tier &&
            source.tier < _maxTier) {
          if (target.isFrozen) {
            // Merging with frozen: unfreeze (no tier upgrade)
            _gridItems[toIndex] = target.copyWith(isFrozen: false);
            _gridItems[fromIndex] = null;
            _manuallyUnlockedIndices.add(toIndex);

            if (!_tutorialComplete && _tutorialStep == 2) {
              _advanceTutorial();
            }

            if (_settings.vibrationEnabled) {
              HapticFeedback.heavyImpact();
            }

            // Show unlock popup
            _maybeShowUnlock(target.tier);
          } else {
            // Normal merge: upgrade to next tier
            final newTier = target.tier + 1;
            _gridItems[toIndex] = target.copyWith(tier: newTier);
            _gridItems[fromIndex] = null;

            if (!_tutorialComplete && _tutorialStep == 1) {
              _advanceTutorial();
            }

            // Check for Chip (Tier 4) creation during tutorial
            if (!_tutorialComplete &&
                _tutorialStep == 4 && // Waiting state
                newTier == 4) {
              _tutorialChipIndex = toIndex;
              _advanceTutorial(); // Go to step 5 (deliver chip)
            }

            _totalMerges++;
            if (newTier > _highestTier) {
              _highestTier = newTier;
            }

            _maybeShowUnlock(newTier);

            if (_settings.vibrationEnabled) {
              HapticFeedback.lightImpact();
            }
          }

          // Grant XP and coins
          _addXP(target.tier * 5);
          final coinReward = target.tier * 2;
          _coins += coinReward;
          _totalCoinsEarned += coinReward;
          _focusedIndex = toIndex;
        } else {
          // Swap items
          if (target.isFrozen) return;
          if (!_isCellUnlocked(toIndex) || !_isCellUnlocked(fromIndex)) return;

          _gridItems[toIndex] = source;
          _gridItems[fromIndex] = target;
          _focusedIndex = toIndex;
        }
      }
    });
  }

  void _onItemDelivered(int fromIndex, int orderIndex) {
    final item = _gridItems[fromIndex];
    if (item == null) return;

    final order = _orders[orderIndex];
    if (order.isCompleted) return;

    if (item.type == ItemType.part && item.tier == order.targetTier) {
      setState(() {
        _gridItems[fromIndex] = null;
        order.isCompleted = true;
        _ordersCompleted++;

        if (_settings.vibrationEnabled) {
          HapticFeedback.mediumImpact();
        }

        // Check win
        if (_tutorialComplete && _orders.every((o) => o.isCompleted)) {
          widget.onComplete(LevelOutcome(score: 1));
        }

        if (!_tutorialComplete && _tutorialStep == 5 && orderIndex == 3) {
          // Chip delivered
          _advanceTutorial();
        }
      });
    }
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

  // ---------------------------------------------------------------------------
  // Tutorial
  // ---------------------------------------------------------------------------

  void _advanceTutorial() {
    setState(() {
      _tutorialTapCount = 0; // Reset tap count for next step
      if (_tutorialStep < _tutorialSteps.length - 1) {
        _tutorialStep++;
      } else {
        _tutorialComplete = true;
      }
    });
  }

  List<TutorialStep> get _tutorialSteps {
    return [
      TutorialStep(
        instruction: 'keep tapping the generator to produce more items!',
        targetKey: _generatorKey,
        requiresTap: true,
      ),
      TutorialStep(
        instruction: 'drag matching items together to merge them!',
        sourceKey: _getCellKey(_index(3, 4)),
        destinationKey: _getCellKey(_index(3, 3)),
        targetKey: _getCellKey(_index(3, 3)),
        requiresDrag: true,
      ),
      TutorialStep(
        instruction: 'drag the item to the frozen item to unlock the cell!',
        sourceKey: _getCellKey(_index(3, 3)),
        destinationKey: _getCellKey(_index(4, 2)),
        targetKey: _getCellKey(_index(4, 2)),
        requiresDrag: true,
      ),
      const TutorialStep(
        instruction:
            'keep producing, merging, and upgrading items to get higher tier ones!',
        targetKey: null,
      ),
      const TutorialStep(
        instruction: 'waiting for chip...', // Placeholder, not shown
        targetKey: null,
      ),
      TutorialStep(
        instruction: 'drag the chip to the order panel to complete the order!',
        sourceKey: _tutorialChipIndex != -1
            ? _getCellKey(_tutorialChipIndex)
            : null,
        destinationKey: _orderKeys[3], // Chip order
        targetKey: _orderKeys[3],
        requiresDrag: true,
      ),
    ];
  }

  GlobalKey _getCellKey(int index) {
    return _cellKeys.putIfAbsent(index, () => GlobalKey());
  }

  // ---------------------------------------------------------------------------
  // Menu & Navigation
  // ---------------------------------------------------------------------------

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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('booster activated: $id'),
                    backgroundColor: NunuColors.successMain,
                  ),
                );
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
                  _initializeLevel();
                  _playerLevel = 1;
                  _currentXP = 0;
                  _xpForNextLevel = 100;
                  _coins = 100;
                  _energy = 20;
                  _totalMerges = 0;
                  _highestTier = 1;
                  _ordersCompleted = 0;
                  _tutorialStep = 0;
                  _tutorialTapCount = 0;
                  _tutorialChipIndex = -1;
                  _tutorialComplete = false;
                  _manuallyUnlockedIndices.clear();
                  _ownedCosmetics.clear();
                  _claimedCoinPacks.clear();
                  _unlockedTiers
                    ..clear()
                    ..add(1);
                  _lastEnergyRegen = DateTime.now();
                });
              },
            ),
          ),
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // UI Helpers
  // ---------------------------------------------------------------------------

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
      default:
        return Colors.white;
    }
  }

  String _getNameForTier(int tier) {
    switch (tier) {
      case 1:
        return 'energy';
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
      default:
        return '???';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final step =
        !_tutorialComplete &&
            _tutorialStep < _tutorialSteps.length &&
            _tutorialStep != 4
        ? _tutorialSteps[_tutorialStep]
        : null;

    Widget content = Stack(
      children: [
        // Main Game
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

        // Menu Drawer
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: NunuColors.backgroundPaper.withOpacity(0.5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_orders.length, (index) {
          final order = _orders[index];
          final icon = _getIconForTier(order.targetTier);
          final color = _getColorForTier(order.targetTier);

          return KeyedSubtree(
            key: _orderKeys[index],
            child: DragTarget<int>(
              onWillAccept: (fromIndex) {
                if (order.isCompleted) return false;
                if (fromIndex == null) return false;
                final item = _gridItems[fromIndex];
                return item != null &&
                    item.type == ItemType.part &&
                    item.tier == order.targetTier;
              },
              onAccept: (fromIndex) => _onItemDelivered(fromIndex, index),
              builder: (context, candidateData, rejectedData) {
                final bool isCandidateValid = candidateData.isNotEmpty;

                return Column(
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: NunuColors.backgroundDefault,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: order.isCompleted
                                  ? NunuColors.successMain
                                  : (isCandidateValid
                                        ? NunuColors.primaryMain
                                        : NunuColors.textSecondary.withOpacity(
                                            0.3,
                                          )),
                              width: isCandidateValid ? 3 : 2,
                            ),
                            boxShadow: isCandidateValid
                                ? [
                                    BoxShadow(
                                      color: NunuColors.primaryMain.withOpacity(
                                        0.5,
                                      ),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                          ),
                          child: Icon(icon, color: color, size: 28),
                        ),
                        if (order.isCompleted)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check,
                              color: NunuColors.successMain,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getNameForTier(order.targetTier),
                      style: TextStyle(
                        fontSize: 10,
                        color: order.isCompleted
                            ? NunuColors.textSecondary
                            : NunuColors.textPrimary,
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double cellWidth = constraints.maxWidth / _cols;
        final double cellHeight = constraints.maxHeight / _rows;
        final double size = min(cellWidth, cellHeight);

        final double gridWidth = size * _cols;
        final double gridHeight = size * _rows;

        return Center(
          child: SizedBox(
            width: gridWidth,
            height: gridHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                childAspectRatio: 1.0,
                crossAxisSpacing: 2,
                mainAxisSpacing: 2,
              ),
              itemCount: _totalCells,
              itemBuilder: (context, index) {
                return _buildCell(index);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCell(int index) {
    final bool isBlocked = _isCellBlocked(index);
    final bool isRock = _isCellRock(index);
    final bool isUnlocked = _isCellUnlocked(index);
    final HardwareItem? item = _gridItems[index];
    final bool isFocused = _focusedIndex == index;
    final bool isGenerator = item?.type == ItemType.generator;

    return DragTarget<int>(
      onWillAccept: (fromIndex) {
        if (fromIndex == null || fromIndex == index) return false;
        if (isUnlocked) return true;

        if (!isUnlocked && item != null && item.isFrozen) {
          final source = _gridItems[fromIndex];
          if (source != null &&
              source.type == item.type &&
              source.tier == item.tier) {
            return true;
          }
        }
        return false;
      },
      onAccept: (fromIndex) => _onItemMove(fromIndex, index),
      builder: (context, candidateData, rejectedData) {
        Color bgColor = NunuColors.backgroundPaper;
        Widget? content;

        if (isBlocked) {
          bgColor = Colors.black26;
          content = const Icon(Icons.block, color: Colors.white10, size: 16);
        } else if (isRock) {
          bgColor = Colors.brown.shade900.withOpacity(0.5);
          content = Icon(Icons.terrain, color: Colors.brown.shade400, size: 20);
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
              const Icon(Icons.lock, color: Colors.white24, size: 16),
              const SizedBox(height: 2),
              Text(
                'lv${_gridUnlockLevels[index]}',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          );
        }

        // Highlight if candidate dragging over
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

        Widget cellWidget = Container(
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(4),
            border: isFocused
                ? Border.all(color: NunuColors.primaryMain, width: 2)
                : Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: content,
        );

        Widget gestureWrapped;
        if (isGenerator) {
          gestureWrapped = GestureDetector(
            onTap: () {
              if (isUnlocked) {
                setState(() {
                  _focusedIndex = index;
                  _spawnItem();
                });
              }
            },
            child: cellWidget,
          );
        } else {
          gestureWrapped = GestureDetector(
            onTap: () {
              if (isUnlocked) {
                setState(() => _focusedIndex = index);
              }
            },
            child: cellWidget,
          );
        }

        return KeyedSubtree(
          key: isGenerator ? _generatorKey : _getCellKey(index),
          child: gestureWrapped,
        );
      },
    );
  }

  Widget _buildDraggableItem(int index, HardwareItem item) {
    Widget child;

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
          child: Icon(Icons.inventory_2, color: Colors.white, size: 24),
        ),
      );
    } else {
      final Color itemColor = item.isFrozen
          ? Colors.grey
          : _getColorForTier(item.tier);

      child = Container(
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: itemColor, width: 2),
        ),
        child: Center(
          child: Icon(_getIconForTier(item.tier), color: itemColor, size: 24),
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
      padding: const EdgeInsets.all(16),
      color: NunuColors.backgroundPaper,
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 40,
          child: const SizedBox.shrink(),
        ),
      ),
    );
  }
}
