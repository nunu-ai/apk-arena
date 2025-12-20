import 'package:flutter/material.dart';
import 'dart:ui';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelTutorialCards extends LevelWidget {
  const LevelTutorialCards({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelTutorialCards> createState() => _LevelTutorialCardsState();
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

class _LevelTutorialCardsState extends State<LevelTutorialCards>
    with SingleTickerProviderStateMixin {
  // 3 Foundation piles
  final List<List<CardData>> _foundations = [[], [], []];

  // 3 Source stacks (Bottom row)
  late List<List<CardData>> _stacks;

  // Deck (Face down) and Waste (Face up) piles (Top right)
  List<CardData> _deck = [];
  List<CardData> _waste = [];

  // Card dimensions
  static const double _cardWidth = 85.0;
  static const double _cardHeight = 130.0;

  // Tutorial State
  int _currentStep = 0;

  // Animation
  late AnimationController _ghostController;
  // Keys to track positions
  final List<GlobalKey> _foundationKeys = List.generate(3, (_) => GlobalKey());
  final List<GlobalKey> _stackKeys = List.generate(3, (_) => GlobalKey());
  final GlobalKey _deckKey = GlobalKey();
  final GlobalKey _wasteKey = GlobalKey();

  Offset? _ghostStartPos;
  Offset? _ghostEndPos;
  // Change from single card to list of cards for stack animation
  List<CardData>? _ghostCards;
  bool _showTouchFeedback = false; // For showing tap feedback on deck

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

    _ghostController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Calculate positions after layout
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateGhostAnimation();
    });
  }

  @override
  void dispose() {
    _ghostController.dispose();
    super.dispose();
  }

  void _initializeCards() {
    // Define cards needed for the level

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

    // 2. Setup Stacks
    _stacks = [
      [rose, sofa, pizza], // Stack 0
      [dog, burger, petsCat], // Stack 1 (Pets Cat is top/last)
      [cat, chair, tulip], // Stack 2
    ];

    // Deck setup (face down)
    _deck = [
      plane, // Top card when deck is reversed? No, removeLast takes from end
      // So first card to appear should be at the end of the list?
      // When we tap, we do `_deck.removeLast()`.
      // So the last card in this list is the top of the deck.
      foodCat,
      vacCat,
      furnCat,
      beach,
    ];
  }

  void _updateGhostAnimation() {
    if (_currentStep > 11) {
      setState(() {
        _ghostCards = null;
        _showTouchFeedback = false;
      });
      return;
    }

    GlobalKey? startKey;
    GlobalKey? endKey;
    List<CardData>? cards;
    bool showTouch = false;

    // Determine move based on step
    if (_currentStep == 0) {
      // Step 0: Move "Pets" (Stack 1) to Middle Slot (Foundation 1)
      startKey = _stackKeys[1];
      endKey = _foundationKeys[1];
      if (_stacks[1].isNotEmpty) cards = [_stacks[1].last];
    } else if (_currentStep == 1) {
      // Step 1: Move "Tulip" (Stack 2) to Flowers Slot (Foundation 0)
      startKey = _stackKeys[2];
      endKey = _foundationKeys[0];
      if (_stacks[2].isNotEmpty) cards = [_stacks[2].last];
    } else if (_currentStep == 2) {
      // Step 2: Move "Burger" (Stack 1) to "Pizza" (Stack 0)
      startKey = _stackKeys[1];
      endKey = _stackKeys[0];
      if (_stacks[1].isNotEmpty) cards = [_stacks[1].last];
    } else if (_currentStep == 3) {
      // Step 3: Move "Dog" (Stack 1, now exposed) to "Pets" (Foundation 1)
      startKey = _stackKeys[1];
      endKey = _foundationKeys[1];
      if (_stacks[1].isNotEmpty) cards = [_stacks[1].last];
    } else if (_currentStep == 4) {
      // Step 4: Click Deck
      startKey = _deckKey;
      endKey = _deckKey; // Stay in place
      cards = null; // No card moving, just tap indication
      showTouch = true;
    } else if (_currentStep == 5) {
      // Step 5: Move "Pizza/Burger" ministack (Stack 0) to Middle Stack (Stack 1)
      startKey = _stackKeys[0];
      endKey = _stackKeys[1];
      if (_stacks[0].length >= 2) {
        cards = _stacks[0].sublist(_stacks[0].length - 2);
      } else if (_stacks[0].isNotEmpty) {
        cards = [_stacks[0].last];
      }
    } else if (_currentStep == 6) {
      // Step 6: Move "Sofa" (Stack 0) to "Chair" (Stack 2)
      startKey = _stackKeys[0];
      endKey = _stackKeys[2];
      if (_stacks[0].isNotEmpty) cards = [_stacks[0].last];
    } else if (_currentStep == 7) {
      // Step 7: Move "Rose" (Stack 0) to "Tulip" (Foundation 0)
      startKey = _stackKeys[0];
      endKey = _foundationKeys[0];
      if (_stacks[0].isNotEmpty) cards = [_stacks[0].last];
    } else if (_currentStep == 8) {
      // Step 8: Move "Beach" (Waste) to the left empty stack slot (Stack 0)
      startKey = _wasteKey;
      endKey = _stackKeys[0];
      if (_waste.isNotEmpty) cards = [_waste.last];
    } else if (_currentStep == 9) {
      // Step 9: Click the top right stack (Deck)
      startKey = _deckKey;
      endKey = _deckKey;
      cards = null;
      showTouch = true;
    } else if (_currentStep == 10) {
      // Step 10: Drag "Furniture" (Waste) to the right foundation slot (Foundation 2)
      startKey = _wasteKey;
      endKey = _foundationKeys[2];
      if (_waste.isNotEmpty) cards = [_waste.last];
    } else if (_currentStep == 11) {
      // Step 11: Move "Chair/Sofa" ministack (Stack 2) onto "Furniture" (Foundation 2)
      startKey = _stackKeys[2];
      endKey = _foundationKeys[2];
      if (_stacks[2].length >= 2) {
        cards = _stacks[2].sublist(_stacks[2].length - 2);
      } else if (_stacks[2].isNotEmpty) {
        cards = [_stacks[2].last];
      }
    }

    if (showTouch && startKey != null) {
      final RenderBox? startBox =
          startKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? rootBox = context.findRenderObject() as RenderBox?;

      if (startBox != null && rootBox != null) {
        final startGlobal = startBox.localToGlobal(Offset.zero);
        setState(() {
          _ghostStartPos = rootBox.globalToLocal(startGlobal);
          _ghostEndPos = _ghostStartPos; // No movement
          _ghostCards = null;
          _showTouchFeedback = true;
        });
      }
      return;
    }

    if (startKey != null && endKey != null && cards != null) {
      final RenderBox? startBox =
          startKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? endBox =
          endKey.currentContext?.findRenderObject() as RenderBox?;
      final RenderBox? rootBox = context.findRenderObject() as RenderBox?;

      if (startBox != null && endBox != null && rootBox != null) {
        final startGlobal = startBox.localToGlobal(Offset.zero);
        final endGlobal = endBox.localToGlobal(Offset.zero);

        setState(() {
          _ghostStartPos = rootBox.globalToLocal(startGlobal);
          _ghostEndPos = rootBox.globalToLocal(endGlobal);
          _ghostCards = cards;
          _showTouchFeedback = false;
        });
        return;
      }
    }

    setState(() {
      _ghostCards = null;
      _showTouchFeedback = false;
    });
  }

  void _checkCompletion() {
    if (_currentStep > 11) {
      widget.onComplete(true);
    } else {
      // Schedule animation update for next step
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateGhostAnimation();
      });
    }
  }

  void _onDeckTap() {
    // Game Rule: Can tap deck if not empty or waste not empty (to reset)
    // If user taps when they shouldn't (per tutorial), fail.

    bool isCorrectStep = (_currentStep == 4 || _currentStep == 9);

    if (!isCorrectStep) {
      widget.onComplete(false);
      return;
    }

    setState(() {
      if (_deck.isNotEmpty) {
        final card = _deck.removeLast();
        _waste.add(card);
      } else if (_waste.isNotEmpty) {
        _deck.addAll(_waste.reversed);
        _waste.clear();
      }

      _currentStep++;
      _checkCompletion();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(16),
      child: Stack(
        children: [
          // Top Right: Deck & Waste (Visual only)
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                KeyedSubtree(key: _wasteKey, child: _buildWastePile()),
                const SizedBox(width: 8),
                KeyedSubtree(key: _deckKey, child: _buildDeckPile()),
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

          // Ghost Animation Overlay
          if (_showTouchFeedback && _ghostStartPos != null)
            AnimatedBuilder(
              animation: _ghostController,
              builder: (context, child) {
                final val = Curves.easeInOut.transform(_ghostController.value);
                // Pulse effect
                final scale = 1.0 + (val < 0.5 ? val : 1.0 - val) * 0.2;
                final opacity = 0.5 + (val < 0.5 ? val : 1.0 - val) * 0.5;

                return Positioned(
                  left: _ghostStartPos!.dx + (_cardWidth / 2) - 20,
                  top: _ghostStartPos!.dy + (_cardHeight / 2) - 20,
                  // Use IgnorePointer to allow clicks through the pulsing indicator
                  child: IgnorePointer(
                    child: Opacity(
                      opacity: opacity,
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.5),
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),

          if (!_showTouchFeedback &&
              _ghostCards != null &&
              _ghostStartPos != null &&
              _ghostEndPos != null)
            AnimatedBuilder(
              animation: _ghostController,
              builder: (context, child) {
                final val = Curves.easeInOut.transform(_ghostController.value);
                final currentPos = Offset.lerp(
                  _ghostStartPos,
                  _ghostEndPos,
                  val,
                )!;
                // final opacity = (1.0 - (val - 0.5).abs() * 2).clamp(0.2, 0.6); // Fade in/out

                return Positioned(
                  left: currentPos.dx,
                  top: currentPos.dy,
                  child: Transform.scale(
                    scale: 1.05,
                    child: IgnorePointer(
                      child: _ghostCards!.length > 1
                          ? _buildCascadingStack(_ghostCards!)
                          : _buildCardWidget(_ghostCards!.first),
                    ),
                  ),
                );
              },
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

    return KeyedSubtree(
      key: _foundationKeys[slotIndex],
      child: Column(
        children: [
          // Category Label
          Container(
            height: 24,
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

              // Generic Game Rules for Foundation:
              // 1. If empty, accept Category Card.
              // 2. If not empty, accept Card of same Category.
              if (foundation.isEmpty) {
                return data.cards.first.isCategoryCard;
              } else {
                final category = foundation.first.category;
                return data.cards.first.category == category;
              }
            },
            onAccept: (data) {
              // Check Tutorial Step Logic
              bool isCorrectMove = false;

              if (_currentStep == 0) {
                // Pets -> Foundation 1 (Pets)
                if (slotIndex == 1 &&
                    data.cards.first.isCategoryCard &&
                    data.cards.first.category == CardCategory.pets)
                  isCorrectMove = true;
              } else if (_currentStep == 1) {
                // Tulip -> Foundation 0 (Flowers)
                if (slotIndex == 0 && data.cards.first.label == 'Tulip')
                  isCorrectMove = true;
              } else if (_currentStep == 3) {
                // Dog -> Foundation 1 (Pets)
                if (slotIndex == 1 && data.cards.first.label == 'Dog')
                  isCorrectMove = true;
              } else if (_currentStep == 7) {
                // Rose -> Foundation 0 (Flowers)
                if (slotIndex == 0 && data.cards.first.label == 'Rose')
                  isCorrectMove = true;
              } else if (_currentStep == 10) {
                // Furniture -> Foundation 2 (Empty -> Furniture)
                if (slotIndex == 2 &&
                    data.cards.first.isCategoryCard &&
                    data.cards.first.category == CardCategory.furniture)
                  isCorrectMove = true;
              } else if (_currentStep == 11) {
                // Chair/Sofa -> Foundation 2 (Furniture)
                if (slotIndex == 2 &&
                    data.cards.first.category == CardCategory.furniture)
                  isCorrectMove = true;
              }

              if (!isCorrectMove) {
                widget.onComplete(false);
                return;
              }

              // Apply Move
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
              });

              // Advance tutorial step
              if (isCorrectMove) {
                _currentStep++;
                _checkCompletion();
              }
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
      ),
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

    return KeyedSubtree(
      key: _stackKeys[stackIndex],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          DragTarget<_DragData>(
            onWillAccept: (data) {
              if (data == null || data.cards.isEmpty) return false;

              // Generic Game Rules for Stacks:
              // 1. If empty, accept any card? (Normally implies Kings only in Solitaire, but here probably any)
              // 2. If not empty, accept card if SAME Category? (Based on tutorial moves)
              if (stack.isEmpty) {
                return true;
              } else {
                return data.cards.first.category == stack.last.category;
              }
            },
            onAccept: (data) {
              // Prevent accidental drops on the same stack from failing the level
              if (!data.fromDeck && data.stackIndex == stackIndex) {
                return;
              }

              // Check Tutorial Step Logic
              bool isCorrectMove = false;

              if (_currentStep == 2) {
                // Burger -> Pizza (Stack 0)
                if (stackIndex == 0 && data.cards.first.label == 'Burger')
                  isCorrectMove = true;
              } else if (_currentStep == 5) {
                // Pizza/Burger -> Empty Stack 1
                if (stackIndex == 1 && data.cards.first.label == 'Pizza')
                  isCorrectMove = true;
              } else if (_currentStep == 6) {
                // Sofa -> Chair (Stack 2)
                if (stackIndex == 2 && data.cards.first.label == 'Sofa')
                  isCorrectMove = true;
              } else if (_currentStep == 8) {
                // Beach -> Empty Stack 0
                if (stackIndex == 0 && data.cards.first.label == 'Beach')
                  isCorrectMove = true;
              }

              if (!isCorrectMove) {
                widget.onComplete(false);
                return;
              }

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

              if (isCorrectMove) {
                _currentStep++;
                _checkCompletion();
              }
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

              if (matchingCards.isEmpty) return SizedBox();

              final draggableWidget = _buildCascadingStack(matchingCards);

              // Allow drag if there are matching cards
              // Any top card or top consecutive stack is "Valid" in game terms.
              bool isDraggable = matchingCards.isNotEmpty;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Base cards
                  if (baseCards.isNotEmpty) ...[
                    Positioned(top: 0, left: 0, child: _buildCardBack()),
                    if (baseCards.length > 1)
                      Positioned(top: 4, left: 4, child: _buildCardBack()),
                  ],

                  Padding(
                    padding: EdgeInsets.only(
                      top: baseCards.isEmpty ? 0 : 8.0,
                      left: baseCards.isEmpty ? 0 : 8.0,
                    ),
                    child: isDraggable
                        ? Draggable<_DragData>(
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
                              height:
                                  _cardHeight +
                                  (matchingCards.length - 1) * 30.0,
                            ),
                            child: draggableWidget,
                          )
                        : draggableWidget,
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCascadingStack(List<CardData> cards, {bool isFeedback = false}) {
    if (cards.isEmpty) return SizedBox();

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
    // Always enable dragging from Waste if present
    bool isDraggable = _waste.isNotEmpty;

    Widget content = Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _waste.isNotEmpty ? _buildCardWidget(_waste.last) : null,
    );

    if (isDraggable && _waste.isNotEmpty) {
      final topCard = _waste.last;
      return Draggable<_DragData>(
        data: _DragData(cards: [topCard], fromDeck: true),
        feedback: Transform.scale(scale: 1.1, child: _buildCardWidget(topCard)),
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
        child: content,
      );
    }

    return content;
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
