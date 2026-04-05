import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// -----------------------------------------------------------------------------
// Data Models
// -----------------------------------------------------------------------------

enum ItemType { generator, part }

class HardwareItem {
  final String id;
  final ItemType type;
  final int tier; // 1..6 for parts. 0 for generator
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

class LevelHardwareMerge extends LevelWidget {
  const LevelHardwareMerge({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelHardwareMerge> createState() => _LevelHardwareMergeState();
}

class _LevelHardwareMergeState extends State<LevelHardwareMerge> {
  // Grid Configuration
  static const int _cols = 7;
  static const int _rows = 9;
  static const int _totalCells = _cols * _rows;

  // Items
  static const int _maxTier = 8;

  // Game State
  late List<HardwareItem?> _gridItems;
  late List<int> _gridUnlockLevels; // 0 = start, N = level N, -1 = blocked
  final Set<int> _manuallyUnlockedIndices = {};

  int _playerLevel = 1;
  int _currentXP = 0;
  int _xpForNextLevel = 100; // Slower start

  // Orders: Robot (6), Battery (5), Chip (4)
  late List<OrderRequirement> _orders;

  // Focused Cell (Selection)
  int? _focusedIndex;

  @override
  void initState() {
    super.initState();
    _initializeLevel();
  }

  void _initializeLevel() {
    // 1. Initialize Orders
    _orders = [
      OrderRequirement(targetTier: 6), // Robot
      OrderRequirement(targetTier: 5), // Battery
      OrderRequirement(targetTier: 4), // Chip
    ];

    // 2. Initialize Map (7x9)
    // 0: Unlocked, 1+: Locked until Lvl, -1: Blocked
    // Tight, Asymmetrical "Ruined Lab" Layout
    // 7 cols
    const List<int> mapDesign = [
      // Row 0
      -1, -1, 99, 99, -1, -1, -1,
      // Row 1
      -1,
      99,
      4,
      5,
      99,
      -1,
      -1, // [1, 2] is Lvl 4 unlock, [1, 3] is Lvl 5 unlock
      // Row 2
      -1,
      99,
      0,
      0,
      3,
      99,
      -1, // [2, 2], [2, 3] unlocked. [2, 4] is Lvl 3 unlock
      // Row 3
      -1,
      99,
      0,
      0,
      0,
      6,
      -1, // [3, 2] is Generator. [3, 3], [3, 4] unlocked. [3, 5] is Lvl 6 unlock
      // Row 4
      -1,
      99,
      2,
      7,
      99,
      -1,
      -1, // [4, 2] is Lvl 2 unlock, [4, 3] is Lvl 7 unlock
      // Row 5
      -1, -1, 8, -1, -1, -1, -1, // [5, 2] is Lvl 8 unlock
      // Row 6
      -1, -1, -1, -1, -1, -1, -1,
      // Row 7
      -1, -1, -1, -1, -1, -1, -1,
      // Row 8
      -1, -1, -1, -1, -1, -1, -1,
    ];

    // Validate map assumptions:
    // Unlocked (0): [2,2], [2,3], [3,3], [3,4]. Plus Generator at [3,2]. Total 5.
    // Lvl 2 (2): [4,2]. Adjacent to [3,2] (Gen).
    // Lvl 3 (3): [2,4]. Adjacent to [2,3] (0) and [3,4] (0).
    // Lvl 4 (4): [1,2]. Adjacent to [2,2] (0).
    // Lvl 5 (5): [1,3]. Adjacent to [1,2] (4) and [2,3] (0).
    // Lvl 6 (6): [3,5]. Adjacent to [2,4] (3) and [3,4] (0).
    // Lvl 7 (7): [4,3]. Adjacent to [4,2] (2) and [3,3] (0).
    // Lvl 8 (8): [5,2]. Adjacent to [4,2] (2).

    _gridUnlockLevels = List.from(mapDesign);

    // 3. Initialize Items
    // Force reset to nulls first to ensure clean state
    _gridItems = List<HardwareItem?>.filled(_totalCells, null);

    // Place Generator in the cluster at [3, 2]
    // 3 * 7 + 2 = 23
    int centerIndex = 3 * _cols + 2;
    _gridItems[centerIndex] = const HardwareItem(
      id: 'gen_1',
      type: ItemType.generator,
      tier: 0,
    );

    // Add pre-filled frozen items on the specific unlock cells
    // Strategy: Place high-tier frozen items on LOCKED cells adjacent to the start.
    // Unlocking these requires merging a matching item into them.

    // 1. Frozen Gear (Tier 2) on [4, 2] (Originally Lvl 2 unlock)
    // Adjacent to Generator at [3, 2]
    _placeFrozenItem(4, 2, 2);

    // 2. Frozen Motor (Tier 3) on [2, 4] (Originally Lvl 3 unlock)
    // Adjacent to unlocked [2, 3] and [3, 4]
    _placeFrozenItem(2, 4, 3);

    // 3. Frozen Chip (Tier 4) on [1, 2] (Originally Lvl 4 unlock)
    // Adjacent to unlocked [2, 2]
    _placeFrozenItem(1, 2, 4);

    // 4. Frozen Battery (Tier 5) on [1, 3] (Lvl 5 unlock)
    // Adjacent to [1, 2] (4) and [2, 3] (0)
    _placeFrozenItem(1, 3, 5);

    // 5. Frozen Robot (Tier 6) on [3, 5] (Lvl 6 unlock)
    // Adjacent to [3, 4] (0)
    _placeFrozenItem(3, 5, 6);

    // 6. Frozen Server (Tier 7) on [4, 3] (Lvl 7 unlock)
    // Adjacent to [3, 3] (0)
    _placeFrozenItem(4, 3, 7);

    // 7. Frozen AI Core (Tier 8) on [5, 2] (Lvl 8 unlock)
    // Adjacent to [4, 2] (2)
    _placeFrozenItem(5, 2, 8);
  }

  void _placeFrozenItem(int r, int c, int tier) {
    int index = r * _cols + c;
    // We allow placing on locked cells (except blocked -1)
    if (index >= 0 && index < _totalCells && _gridUnlockLevels[index] != -1) {
      _gridItems[index] = HardwareItem(
        id: 'frozen_${r}_$c',
        type: ItemType.part,
        tier: tier,
        isFrozen: true,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Game Logic
  // ---------------------------------------------------------------------------

  bool _isCellUnlocked(int index) {
    if (_manuallyUnlockedIndices.contains(index)) return true;
    int required = _gridUnlockLevels[index];
    return required != -1 && _playerLevel >= required;
  }

  bool _isCellBlocked(int index) {
    return _gridUnlockLevels[index] == -1;
  }

  void _addXP(int amount) {
    setState(() {
      _currentXP += amount;
      // Level Up Logic
      while (_currentXP >= _xpForNextLevel) {
        _currentXP -= _xpForNextLevel;
        _playerLevel++;
        _xpForNextLevel = (_xpForNextLevel * 2.0).round(); // Slower scaling

        // Show Level Up Feedback?
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Level Up! Now Level $_playerLevel'),
            duration: const Duration(seconds: 1),
            backgroundColor: NunuColors.primaryMain,
          ),
        );
      }
    });
  }

  void _spawnItem() {
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
          content: Text('No space to spawn items!'),
          duration: Duration(milliseconds: 500),
          backgroundColor: NunuColors.errorMain,
        ),
      );
      return;
    }

    // Pick random spot
    int targetIndex = emptyIndices[Random().nextInt(emptyIndices.length)];

    setState(() {
      _gridItems[targetIndex] = HardwareItem(
        id: DateTime.now().toIso8601String(),
        type: ItemType.part,
        tier: 1, // Start with Screw
      );
    });
  }

  void _onItemMove(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    // Source item
    final source = _gridItems[fromIndex];
    if (source == null) return;
    if (source.isFrozen) return; // Frozen items cannot be moved

    // Check target validity
    // Can move to unlocked cells, OR to a locked cell if it contains a frozen item we can merge with
    // But simplistic logic first: target cell must be unlocked unless we are merging with a frozen item there?
    // Actually, usually in these games, frozen items sit on LOCKED cells or UNLOCKED cells.
    // If on Locked cell, you can't place anything there unless it's a merge.
    // If on Unlocked cell, same.

    // Let's stick to: Target slot must be unlocked, OR we are merging with an existing item (which might be frozen)
    // If target is empty, slot MUST be unlocked.
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
          // Check if merging with a frozen item
          if (target.isFrozen) {
            // Merging with frozen: just unfreeze (no tier upgrade)
            // The source item is consumed, the frozen item becomes colorful
            _gridItems[toIndex] = target.copyWith(isFrozen: false);
            _gridItems[fromIndex] = null;

            // Unlock the cell
            _manuallyUnlockedIndices.add(toIndex);
            HapticFeedback.heavyImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Unlocked ${_getNameForTier(target.tier)}! Cell now available.',
                ),
                duration: const Duration(milliseconds: 800),
                backgroundColor: NunuColors.successMain,
              ),
            );
          } else {
            // Normal merge: upgrade to next tier
            _gridItems[toIndex] = target.copyWith(tier: target.tier + 1);
            _gridItems[fromIndex] = null;
            HapticFeedback.lightImpact();
          }

          // Grant XP: Tier * 5 (Slower progression)
          _addXP(target.tier * 5);
          _focusedIndex = toIndex;
        } else {
          // Swap items (if valid move, e.g. moving bucket)
          // Cannot swap if target is frozen
          if (target.isFrozen) return;

          // Both must be on unlocked cells to swap freely
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
        // Consume item
        _gridItems[fromIndex] = null;
        // Complete order
        order.isCompleted = true;
        HapticFeedback.mediumImpact();

        // Check win
        if (_orders.every((o) => o.isCompleted)) {
          widget.onComplete(LevelOutcome(score: 1));
        }
      });
    }
  }

  // ---------------------------------------------------------------------------
  // UI Helpers
  // ---------------------------------------------------------------------------

  IconData _getIconForTier(int tier) {
    switch (tier) {
      case 1:
        return Icons.flash_on; // Screw/Flash
      case 2:
        return Icons.settings; // Gear
      case 3:
        return Icons.memory; // Motor/Chip-ish
      case 4:
        return Icons.developer_board; // Chip
      case 5:
        return Icons.battery_charging_full; // Battery
      case 6:
        return Icons.smart_toy; // Robot
      case 7:
        return Icons.router; // Server
      case 8:
        return Icons.rocket_launch; // Rocket
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
        return 'Energy';
      case 2:
        return 'Gear';
      case 3:
        return 'Motor';
      case 4:
        return 'Chip';
      case 5:
        return 'Battery';
      case 6:
        return 'Robot';
      case 7:
        return 'Server';
      case 8:
        return 'AI Core';
      default:
        return '???';
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGrid()),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: NunuColors.backgroundPaper,
      child: Column(
        children: [
          // XP Bar & Level
          Row(
            children: [
              Text(
                'Lvl $_playerLevel',
                style: const TextStyle(
                  color: NunuColors.primaryMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: _currentXP / _xpForNextLevel,
                    backgroundColor: NunuColors.backgroundDefault,
                    valueColor: const AlwaysStoppedAnimation(
                      NunuColors.secondaryMain,
                    ),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '$_currentXP / $_xpForNextLevel XP',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Orders
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_orders.length, (index) {
              final order = _orders[index];
              final icon = _getIconForTier(order.targetTier);
              final color = _getColorForTier(order.targetTier);

              return DragTarget<int>(
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
                                          : NunuColors.textSecondary
                                                .withOpacity(0.3)),
                                width: isCandidateValid ? 3 : 2,
                              ),
                              boxShadow: isCandidateValid
                                  ? [
                                      BoxShadow(
                                        color: NunuColors.primaryMain
                                            .withOpacity(0.5),
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
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate cell size
        final double cellWidth = constraints.maxWidth / _cols;
        final double cellHeight = constraints.maxHeight / _rows;
        final double size = min(cellWidth, cellHeight);

        // Center the grid
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
    final bool isUnlocked = _isCellUnlocked(index);
    final HardwareItem? item = _gridItems[index];
    final bool isFocused = _focusedIndex == index;

    return DragTarget<int>(
      onWillAccept: (fromIndex) {
        if (fromIndex == null || fromIndex == index) return false;

        // Allow if unlocked
        if (isUnlocked) return true;

        // Allow if locked BUT has a frozen item we can merge with
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
        } else if (item != null) {
          // Render item (even if locked, to show frozen items)
          content = _buildDraggableItem(index, item);

          // If locked, maybe dim background more?
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
                'Lv${_gridUnlockLevels[index]}',
                style: const TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          );
        }

        // Highlight if candidate dragging over
        if (candidateData.isNotEmpty) {
          // Show merge hint
          if (item != null) {
            final fromIndex = candidateData.first;
            if (fromIndex != null) {
              final source = _gridItems[fromIndex];
              if (source != null &&
                  source.type == ItemType.part &&
                  item.type == ItemType.part &&
                  source.tier == item.tier &&
                  source.tier < _maxTier) {
                // Valid merge candidate (works for unlocked or frozen/locked)
                bgColor = NunuColors.primaryMain.withOpacity(0.3);
              }
            }
          } else if (isUnlocked) {
            // Valid move candidate (only for empty unlocked cells)
            bgColor = bgColor.withOpacity(0.8);
          }
        }

        return GestureDetector(
          onTap: () {
            if (isUnlocked) {
              setState(() {
                _focusedIndex = index;
                if (item?.type == ItemType.generator) {
                  _spawnItem();
                }
              });
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(4),
              border: isFocused
                  ? Border.all(color: NunuColors.primaryMain, width: 2)
                  : Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: content,
          ),
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
      // Part
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
      // Disable dragging if frozen
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
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: Center(
            child: Text(
              'Drag items to the orders above to deliver.',
              style: const TextStyle(color: NunuColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
