import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelSortShelf extends LevelWidget {
  const LevelSortShelf({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelSortShelf> createState() => _LevelSortShelfState();
}

class _LevelSortShelfState extends State<LevelSortShelf>
    with TickerProviderStateMixin {
  late List<_ShelfItem> _items;
  bool _isComplete = false;
  int _moveCount = 0;

  // shelf items: books with numbers on the spine
  static const List<_ShelfItemData> _allBooks = [
    _ShelfItemData(label: '1', color: Color(0xFFE55CD8), icon: Icons.book),
    _ShelfItemData(label: '2', color: Color(0xFF805CE5), icon: Icons.book),
    _ShelfItemData(label: '3', color: Color(0xFF00B8D9), icon: Icons.book),
    _ShelfItemData(label: '4', color: Color(0xFF22C55E), icon: Icons.book),
    _ShelfItemData(label: '5', color: Color(0xFFFFAB00), icon: Icons.book),
    _ShelfItemData(label: '6', color: Color(0xFFFF5630), icon: Icons.book),
    _ShelfItemData(label: '7', color: Color(0xFFF79EDE), icon: Icons.book),
    _ShelfItemData(label: '8', color: Color(0xFFBA9EF7), icon: Icons.book),
  ];

  @override
  void initState() {
    super.initState();
    _generateShelf();
  }

  void _generateShelf() {
    final rng = Random();
    // pick 6 books
    final selected = List<_ShelfItemData>.from(_allBooks)..shuffle(rng);
    final books = selected.take(6).toList();

    // create items with correct order
    _items = List.generate(
      books.length,
      (i) => _ShelfItem(
        key: ValueKey('book_${books[i].label}'),
        data: books[i],
        correctIndex: int.parse(books[i].label),
      ),
    );

    // sort by correctIndex so we know the right order
    _items.sort((a, b) => a.correctIndex.compareTo(b.correctIndex));

    // assign correct positions
    for (int i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(correctPosition: i);
    }

    // now shuffle for display
    _items.shuffle(rng);

    // make sure it's not already sorted
    while (_isSorted()) {
      _items.shuffle(rng);
    }
  }

  bool _isSorted() {
    for (int i = 0; i < _items.length - 1; i++) {
      if (_items[i].correctIndex > _items[i + 1].correctIndex) {
        return false;
      }
    }
    return true;
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (_isComplete) return;

    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _items.removeAt(oldIndex);
      _items.insert(newIndex, item);
      _moveCount++;
    });

    if (_isSorted()) {
      setState(() {
        _isComplete = true;
      });
      Future.delayed(const Duration(milliseconds: 600), () {
        widget.onComplete(true, metrics: {'moves': _moveCount});
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 24),
            // header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const Icon(
                    Icons.shelves,
                    color: NunuColors.primaryMain,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'drag the books into ascending order',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: NunuColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'moves: $_moveCount',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NunuColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // shelf
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildShelf(),
              ),
            ),

            if (_isComplete)
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle,
                        color: NunuColors.successMain, size: 28),
                    const SizedBox(width: 8),
                    Text(
                      'sorted!',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: NunuColors.successMain,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildShelf() {
    return ReorderableListView.builder(
      itemCount: _items.length,
      onReorder: _onReorder,
      proxyDecorator: (child, index, animation) {
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final scale = Tween<double>(begin: 1.0, end: 1.05)
                .animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeInOut,
            ));
            return Transform.scale(
              scale: scale.value,
              child: Material(
                color: Colors.transparent,
                elevation: 8,
                shadowColor: NunuColors.primaryMain.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                child: child,
              ),
            );
          },
          child: child,
        );
      },
      itemBuilder: (context, index) {
        final item = _items[index];
        final isCorrectPosition = _isItemInCorrectPosition(index);

        return Container(
          key: item.key,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: item.data.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCorrectPosition && !_isComplete
                      ? NunuColors.successMain.withValues(alpha: 0.5)
                      : _isComplete
                          ? NunuColors.successMain
                          : item.data.color.withValues(alpha: 0.4),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  // book icon
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: item.data.color.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        item.data.label,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: item.data.color,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'book ${item.data.label}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                  Icon(
                    Icons.drag_handle,
                    color: NunuColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  bool _isItemInCorrectPosition(int currentIndex) {
    if (currentIndex >= _items.length) return false;
    // check if this item's correct position matches its current index
    // we need to figure out what the correct position is for items currently displayed
    final sortedItems = List<_ShelfItem>.from(_items)
      ..sort((a, b) => a.correctIndex.compareTo(b.correctIndex));
    return _items[currentIndex].correctIndex ==
        sortedItems[currentIndex].correctIndex;
  }
}

class _ShelfItemData {
  final String label;
  final Color color;
  final IconData icon;

  const _ShelfItemData({
    required this.label,
    required this.color,
    required this.icon,
  });
}

class _ShelfItem {
  final ValueKey key;
  final _ShelfItemData data;
  final int correctIndex;
  final int correctPosition;

  _ShelfItem({
    required this.key,
    required this.data,
    required this.correctIndex,
    this.correctPosition = 0,
  });

  _ShelfItem copyWith({int? correctPosition}) {
    return _ShelfItem(
      key: key,
      data: data,
      correctIndex: correctIndex,
      correctPosition: correctPosition ?? this.correctPosition,
    );
  }
}
