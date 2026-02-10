import 'package:flutter/material.dart';
import 'dart:ui';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelCardSlots extends LevelWidget {
  const LevelCardSlots({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelCardSlots> createState() => _LevelCardSlotsState();
}

enum CardCategory { flowers, pets, food, furniture, vacation }

extension CardCategoryExt on CardCategory {
  String get displayName {
    switch (this) {
      case CardCategory.flowers:
        return 'Flowers';
      case CardCategory.pets:
        return 'Pets';
      case CardCategory.food:
        return 'Food';
      case CardCategory.furniture:
        return 'Furniture';
      case CardCategory.vacation:
        return 'Vacation';
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

  // 3 Source stacks (Bottom row)
  late List<List<CardData>> _stacks;

  // Deck (Face down) and Waste (Face up) piles (Top right)
  List<CardData> _deck = [];
  List<CardData> _waste = [];

  int _completedCategories = 0;

  // Card dimensions
  static const double _cardWidth = 85.0;
  static const double _cardHeight = 130.0;

  // Category Colors
  final Map<CardCategory, Color> _categoryColors = {
    CardCategory.flowers: NunuColors.primaryMain, // Pink
    CardCategory.pets: NunuColors.secondaryMain, // Purple
    CardCategory.food: NunuColors.successMain, // Green
    CardCategory.furniture: NunuColors.infoMain, // Blue
    CardCategory.vacation: NunuColors.warningMain, // Orange
  };

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    // Define all cards (15 total: 5 categories * 3 cards)

    // Flowers
    final flowerCat = const CardData(
      label: 'Flowers',
      category: CardCategory.flowers,
      isCategoryCard: true,
    );
    final rose = const CardData(label: 'Rose', category: CardCategory.flowers);
    final tulip = const CardData(
      label: 'Tulip',
      category: CardCategory.flowers,
    );

    // Pets
    final petsCat = const CardData(
      label: 'Pets',
      category: CardCategory.pets,
      isCategoryCard: true,
    );
    final cat = const CardData(label: 'Cat', category: CardCategory.pets);
    final dog = const CardData(label: 'Dog', category: CardCategory.pets);

    // Food
    final foodCat = const CardData(
      label: 'Food',
      category: CardCategory.food,
      isCategoryCard: true,
    );
    final pizza = const CardData(label: 'Pizza', category: CardCategory.food);
    final burger = const CardData(label: 'Burger', category: CardCategory.food);

    // Furniture
    final furnCat = const CardData(
      label: 'Furniture',
      category: CardCategory.furniture,
      isCategoryCard: true,
    );
    final sofa = const CardData(
      label: 'Sofa',
      category: CardCategory.furniture,
    );
    final chair = const CardData(
      label: 'Chair',
      category: CardCategory.furniture,
    );

    // Vacation
    final vacCat = const CardData(
      label: 'Vacation',
      category: CardCategory.vacation,
      isCategoryCard: true,
    );
    final beach = const CardData(
      label: 'Beach',
      category: CardCategory.vacation,
    );
    final plane = const CardData(
      label: 'Plane',
      category: CardCategory.vacation,
    );

    // Initial State Requirements:
    // 1. "Flowers" category card already in Left Spot (Slot 0)
    _foundations[0] = [flowerCat];

    // 2. Middle Stack (Stack 1) shows "Pets" category card as top card.

    _stacks = [
      [rose, sofa, pizza], // Stack 0
      [dog, burger, petsCat], // Stack 1 (Pets Cat is top/last)
      [cat, chair, tulip], // Stack 2
    ];

    _deck = [
      plane,
      foodCat, // Category card in deck
      vacCat, // Category card in deck
      furnCat, // Category card in deck
      beach,
    ];
  }

  void _checkCompletion() {
    if (_completedCategories >= 5) {
      widget.onComplete(true);
    }
  }

  void _onDeckTap() {
    setState(() {
      if (_deck.isNotEmpty) {
        final card = _deck.removeLast();
        _waste.add(card);
      } else if (_waste.isNotEmpty) {
        _deck.addAll(_waste.reversed);
        _waste.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Top Right: Deck & Waste
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildWastePile(),
                const SizedBox(width: 8),
                _buildDeckPile(),
              ],
            ),
          ),

          // Main Game Area
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Middle: 3 Category Slots
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      3,
                      (index) => _buildFoundation(index),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // Below: 3 Source Stacks
                SizedBox(
                  width: double.infinity,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                      3,
                      (index) => _buildSourceStack(index),
                    ),
                  ),
                ),
              ],
            ),
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
        Container(
          height: 24, // Fixed height to prevent layout shifts
          child: foundationCategory != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
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
              : null,
        ),
        const SizedBox(height: 4),

        DragTarget<_DragData>(
          onWillAccept: (data) {
            if (data == null || data.cards.isEmpty) return false;

            final firstCard = data.cards.first;

            if (foundation.isEmpty) {
              // Allow drop if incoming stack starts with a Category Card
              return firstCard.isCategoryCard;
            } else {
              // Can only add if not a category card (already have one) and matches category
              return data.cards.every(
                (c) => !c.isCategoryCard && c.category == foundationCategory,
              );
            }
          },
          onAccept: (data) {
            setState(() {
              _foundations[slotIndex].addAll(data.cards);

              if (data.fromDeck) {
                _waste.removeLast();
              } else {
                final sourceStack = _stacks[data.stackIndex!];
                sourceStack.removeRange(
                  sourceStack.length - data.cards.length,
                  sourceStack.length,
                );
              }

              if (_foundations[slotIndex].length == 3) {
                _foundations[slotIndex].clear();
                _completedCategories++;
              }
            });
            _checkCompletion();
          },
          builder: (context, candidateData, rejectedData) {
            final isCandidate = candidateData.isNotEmpty;
            final borderColor = isCandidate
                ? Colors.white
                : (topCard != null ? Colors.transparent : Colors.white24);

            return Container(
              width: _cardWidth,
              height: _cardHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Base placeholder
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(8),
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
                    ...List.generate(foundation.length, (i) {
                      final offset = i * 4.0;
                      return Positioned(
                        top: offset,
                        left: 0,
                        child: _buildCardWidget(foundation[i]),
                      );
                    }),
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

    // Calculate how many cards from the top match the same category
    int matchingCount = 0;
    if (stack.isNotEmpty) {
      matchingCount = 1;
      final topCategory = stack.last.category;
      for (int i = stack.length - 2; i >= 0; i--) {
        if (stack[i].category == topCategory) {
          matchingCount++;
        } else {
          break;
        }
      }
    }

    final baseCards = stack.take(stack.length - matchingCount).toList();
    final matchingCards = stack.skip(stack.length - matchingCount).toList();

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        DragTarget<_DragData>(
          onWillAccept: (data) {
            if (data == null || data.cards.isEmpty) return false;

            // Cannot drop if incoming stack's bottom card is a Category Card on an existing stack
            if (data.cards.first.isCategoryCard && stack.isNotEmpty) {
              return false;
            }

            // Can drop if stack is empty OR if matches top card category
            if (stack.isEmpty) return true;
            return data.cards.first.category == stack.last.category;
          },
          onAccept: (data) {
            setState(() {
              _stacks[stackIndex].addAll(data.cards);
              if (data.fromDeck) {
                _waste.removeLast();
              } else {
                final sourceStack = _stacks[data.stackIndex!];
                sourceStack.removeRange(
                  sourceStack.length - data.cards.length,
                  sourceStack.length,
                );
              }
            });
          },
          builder: (context, candidateData, rejectedData) {
            if (stack.isEmpty) {
              return Container(
                width: _cardWidth,
                height: _cardHeight,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }

            // The draggable part is the matching sequence
            // The feedback needs to show the whole sequence cascaded
            // The childWhenDragging shows the baseCards

            // Note: If matchingCards is empty (shouldn't happen if stack not empty), handle it
            if (matchingCards.isEmpty) return SizedBox();

            final draggableWidget = _buildCascadingStack(matchingCards);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // Base cards (collapsed/hidden mostly)
                if (baseCards.isNotEmpty) ...[
                  Positioned(top: 0, left: 0, child: _buildCardBack()),
                  if (baseCards.length > 1)
                    Positioned(top: 4, left: 4, child: _buildCardBack()),
                ],

                // The interactive part
                // If base cards exist, offset the top stack slightly so we see there are cards below
                Padding(
                  padding: EdgeInsets.only(
                    top: baseCards.isEmpty ? 0 : 8.0,
                    left: baseCards.isEmpty ? 0 : 8.0,
                  ),
                  child: Draggable<_DragData>(
                    data: _DragData(
                      stackIndex: stackIndex,
                      cards: matchingCards,
                      fromDeck: false,
                    ),
                    feedback: _buildCascadingStack(
                      matchingCards,
                      isFeedback: true,
                    ),
                    childWhenDragging: SizedBox(
                      width: _cardWidth,
                      height: _cardHeight + (matchingCards.length - 1) * 30.0,
                    ), // Placeholder size? Or invisible?
                    // Actually, if we drag the whole top stack, we just want to see the base cards below.
                    // The 'childWhenDragging' replaces the 'child' in the tree.
                    // So it should be empty here because the base cards are rendered in the parent Stack above this Draggable.
                    child: draggableWidget,
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCascadingStack(List<CardData> cards, {bool isFeedback = false}) {
    if (cards.isEmpty) return SizedBox();

    // Height needs to accommodate the cascade
    final totalHeight = _cardHeight + (cards.length - 1) * 30.0;

    Widget content = Container(
      width: _cardWidth,
      height: totalHeight,
      child: Stack(
        children: List.generate(cards.length, (index) {
          return Positioned(
            top: index * 30.0,
            left: 0,
            child: _buildCardWidget(cards[index]),
          );
        }),
      ),
    );

    if (isFeedback) {
      // Remove material/scaffold dependencies for feedback if needed,
      // but Card/Container is usually fine.
      return Material(color: Colors.transparent, child: content);
    }
    return content;
  }

  Widget _buildDeckPile() {
    return GestureDetector(
      onTap: _onDeckTap,
      child: Stack(
        children: [
          if (_deck.isEmpty)
            Container(
              width: _cardWidth,
              height: _cardHeight,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white24, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Icon(Icons.refresh, color: Colors.white54),
              ),
            )
          else
            _buildCardBack(),

          if (_deck.length > 1)
            Positioned(top: 2, left: 2, child: _buildCardBack()),
        ],
      ),
    );
  }

  Widget _buildWastePile() {
    if (_waste.isEmpty) {
      return Container(
        width: _cardWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    final topCard = _waste.last;
    final cardWidget = _buildCardWidget(topCard);

    return Draggable<_DragData>(
      data: _DragData(cards: [topCard], fromDeck: true),
      feedback: Transform.scale(scale: 1.1, child: cardWidget),
      childWhenDragging: _waste.length > 1
          ? _buildCardWidget(_waste[_waste.length - 2])
          : Container(
              width: _cardWidth,
              height: _cardHeight,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
      child: cardWidget,
    );
  }

  Widget _buildCardWidget(CardData card) {
    final color = _categoryColors[card.category]!;

    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(8),
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          if (card.isCategoryCard)
            const Padding(
              padding: EdgeInsets.only(bottom: 4),
              child: Icon(
                Icons.emoji_events,
                color: Color(0xFFFFD54F),
                size: 24,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text(
              card.label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: card.isCategoryCard
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 50,
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
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF3B7DD8),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Center(
        child: Icon(Icons.grid_view, color: Colors.white24, size: 32),
      ),
    );
  }
}

class _DragData {
  final int? stackIndex;
  final List<CardData> cards;
  final bool fromDeck;

  _DragData({this.stackIndex, required this.cards, this.fromDeck = false});
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
          const Radius.circular(8),
        ),
      );

    final Path dashedPath = _dashPath(path, width: 8, space: gap);
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
