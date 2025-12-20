import 'package:flutter/material.dart';
import 'dart:ui';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelCardSlots extends LevelWidget {
  const LevelCardSlots({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelCardSlots> createState() => _LevelCardSlotsState();
}

enum CardCategory { flowers, pets, food }

extension CardCategoryExt on CardCategory {
  String get displayName {
    switch (this) {
      case CardCategory.flowers:
        return 'Flowers';
      case CardCategory.pets:
        return 'Pets';
      case CardCategory.food:
        return 'Food';
    }
  }
}

class CardData {
  final String label;
  final CardCategory category;
  final bool isCategoryCard;

  const CardData({
    required this.label,
    required this.category,
    this.isCategoryCard = false,
  });
}

class _LevelCardSlotsState extends State<LevelCardSlots> {
  // 3 Foundation piles
  final List<List<CardData>> _foundations = [[], [], []];

  // 3 Source stacks
  late List<List<CardData>> _stacks;

  // Category Colors
  final Map<CardCategory, Color> _categoryColors = {
    CardCategory.flowers: NunuColors.primaryMain, // Pink
    CardCategory.pets: NunuColors.secondaryMain, // Purple
    CardCategory.food: NunuColors.successMain, // Green
  };

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    // Define all cards
    final flowerCat = const CardData(
      label: 'Flowers',
      category: CardCategory.flowers,
      isCategoryCard: true,
    );
    final petsCat = const CardData(
      label: 'Pets',
      category: CardCategory.pets,
      isCategoryCard: true,
    );
    final foodCat = const CardData(
      label: 'Food',
      category: CardCategory.food,
      isCategoryCard: true,
    );

    final rose = const CardData(label: 'Rose', category: CardCategory.flowers);
    final tulip = const CardData(
      label: 'Tulip',
      category: CardCategory.flowers,
    );

    final cat = const CardData(label: 'Cat', category: CardCategory.pets);
    final dog = const CardData(label: 'Dog', category: CardCategory.pets);

    final pizza = const CardData(label: 'Pizza', category: CardCategory.food);
    final burger = const CardData(label: 'Burger', category: CardCategory.food);

    // Initial State Requirements:
    // 1. "Flowers" category card already in Left Spot (Slot 0)
    _foundations[0] = [flowerCat];

    // 2. Middle Stack (Stack 1) shows "Pets" category card as top card.
    // 3. Other cards mixed.

    // Remaining cards to distribute:
    // Food Cat, Rose, Tulip, Cat, Dog, Pizza, Burger (7 cards)

    // Stacks:
    // Stack 0: 2 cards
    // Stack 1: 3 cards (Top is Pets Cat)
    // Stack 2: 2 cards

    _stacks = [
      [rose, pizza], // Stack 0
      [dog, burger, petsCat], // Stack 1 (Pets Cat is top/last)
      [cat, foodCat, tulip], // Stack 2 (Food Cat is buried)
    ];
  }

  void _checkCompletion() {
    // Complete if all source stacks are empty
    if (_stacks.every((stack) => stack.isEmpty)) {
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Place the cards',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Sort by category. Category cards first!',
            style: TextStyle(fontSize: 16, color: Colors.white70),
          ),
          const SizedBox(height: 60),

          // Top Row: Foundations
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => _buildFoundation(index)),
          ),

          const SizedBox(height: 80),

          // Bottom Row: Source Stacks
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (index) => _buildSourceStack(index)),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundation(int slotIndex) {
    final foundation = _foundations[slotIndex];
    final topCard = foundation.isNotEmpty ? foundation.last : null;
    final foundationCategory = foundation.isNotEmpty
        ? foundation.first.category
        : null;

    return Column(
      children: [
        // Category Label
        if (foundationCategory != null)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD54F), // Gold tab
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Text(
              foundationCategory.displayName,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          )
        else
          const SizedBox(height: 24), // Spacer to maintain alignment

        DragTarget<_DragData>(
          onWillAccept: (data) {
            if (data == null) return false;

            if (foundation.isEmpty) {
              // Empty slot: Can only accept a Category Card
              return data.card.isCategoryCard;
            } else {
              // Filled slot: Can only accept items of same category
              // And strictly NOT another category card (though implied by logic)
              return !data.card.isCategoryCard &&
                  data.card.category == foundationCategory;
            }
          },
          onAccept: (data) {
            setState(() {
              _foundations[slotIndex].add(data.card);
              _stacks[data.stackIndex].removeLast();
            });
            _checkCompletion();
          },
          builder: (context, candidateData, rejectedData) {
            final isCandidate = candidateData.isNotEmpty;
            final borderColor = isCandidate
                ? Colors.white
                : (topCard != null ? Colors.transparent : Colors.white24);

            return Container(
              width: 80,
              height: 120,
              child: Stack(
                children: [
                  // Base placeholder
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: borderColor,
                          width: 2,
                          style: topCard != null
                              ? BorderStyle.solid
                              : BorderStyle.none,
                        ),
                      ),
                      child: topCard == null
                          ? CustomPaint(
                              painter: _DashedBorderPainter(
                                color: borderColor,
                                strokeWidth: 2,
                                gap: 5,
                              ),
                            )
                          : null,
                    ),
                  ),

                  // Stacked cards
                  if (foundation.isNotEmpty)
                    ...List.generate(
                      foundation.length > 3 ? 3 : foundation.length,
                      (i) {
                        final reverseI =
                            (foundation.length > 3 ? 3 : foundation.length) -
                            1 -
                            i;
                        final offset = reverseI * 4.0;

                        // Actual index in the foundation list
                        final cardIndex = foundation.length - 1 - reverseI;
                        final card = foundation[cardIndex];

                        return Positioned(
                          top: offset,
                          left: 0,
                          child: _buildCardWidget(card),
                        );
                      },
                    ).reversed,
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSourceStack(int stackIndex) {
    final stack = _stacks[stackIndex];
    // For alignment, source stacks should also account for the label space above foundations
    // So that Top Row and Bottom Row are spaced consistently relative to their containers?
    // No, Row alignment `crossAxisAlignment: CrossAxisAlignment.center` (default) is fine.
    // But `_buildFoundation` returns a Column (Label + Stack). `_buildSourceStack` returns just Stack.
    // If I put them in a Row, `_buildFoundation` will be taller.
    // The Row will center them vertically.
    // It might look slightly misaligned if not careful.
    // I should probably wrap Source Stack in a Column with a SizedBox spacer to match.

    final topCard = stack.isNotEmpty ? stack.last : null;

    return Column(
      children: [
        const SizedBox(height: 24), // Match the label height spacer
        DragTarget<_DragData>(
          onWillAccept: (data) {
            if (data == null) return false;
            if (data.stackIndex == stackIndex)
              return false; // Don't drop on self

            if (stack.isEmpty) {
              // Allow placing any card on empty stack to reorganize
              return true;
            } else {
              // Allow stacking if categories match
              return topCard!.category == data.card.category;
            }
          },
          onAccept: (data) {
            setState(() {
              _stacks[stackIndex].add(data.card);
              _stacks[data.stackIndex].removeLast();
            });
            _checkCompletion();
          },
          builder: (context, candidateData, rejectedData) {
            final isCandidate = candidateData.isNotEmpty;

            // Base empty slot visual if stack is empty
            if (stack.isEmpty) {
              return Container(
                width: 80,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: isCandidate
                      ? Border.all(color: Colors.white, width: 2)
                      : null,
                ),
              );
            }

            // The draggable widget (top card)
            final cardWidget = _buildCardWidget(topCard!);

            // Stack visual (cards underneath)
            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Highlight border if candidate
                if (isCandidate)
                  Positioned(
                    top: -4,
                    left: -4,
                    right: -4,
                    bottom: -4,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),

                // Cards underneath (up to 2 visible)
                if (stack.length > 1)
                  Positioned(top: 4, left: 4, child: _buildCardBack()),
                if (stack.length > 2)
                  Positioned(top: 8, left: 8, child: _buildCardBack()),

                Draggable<_DragData>(
                  data: _DragData(stackIndex, topCard),
                  feedback: Transform.scale(scale: 1.1, child: cardWidget),
                  childWhenDragging: stack.length > 1
                      ? _buildCardBack()
                      : Container(
                          width: 80,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                  child: cardWidget,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCardWidget(CardData card) {
    final color = _categoryColors[card.category]!;

    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper, // Card face is white/paper
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: card.isCategoryCard ? const Color(0xFFFFD54F) : color,
          width: card.isCategoryCard ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.isCategoryCard)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD54F),
                size: 20,
              ),
            ),
          Text(
            card.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: card.isCategoryCard
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardBack() {
    return Container(
      width: 80,
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFF3B7DD8), // Blue card back
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: Icon(Icons.grid_view, color: Colors.white24, size: 24),
      ),
    );
  }
}

class _DragData {
  final int stackIndex;
  final CardData card;
  _DragData(this.stackIndex, this.card);
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;

  _DashedBorderPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gap = 5.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(12),
        ),
      );

    final Path dashedPath = _dashPath(path, width: 10, space: gap);
    canvas.drawPath(dashedPath, paint);
  }

  Path _dashPath(Path source, {required double width, required double space}) {
    final Path dest = Path();
    for (final PathMetric metric in source.computeMetrics()) {
      double distance = 0;
      bool draw = true;
      while (distance < metric.length) {
        final double len = draw ? width : space;
        if (draw) {
          dest.addPath(
            metric.extractPath(distance, distance + len),
            Offset.zero,
          );
        }
        distance += len;
        draw = !draw;
      }
    }
    return dest;
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap;
  }
}
