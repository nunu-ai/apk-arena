import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'game_onboarding.dart';
import 'phone_homescreen.dart';

/// Terms of Service content for Place the Cards
/// Note: Contains hidden clause about age 13+ but NO age gate popup
const String placeCardsTos = '''
PLACE THE CARDS - TERMS OF SERVICE

Last Updated: December 2024

1. ACCEPTANCE OF TERMS
By downloading, installing, or using Place the Cards ("the Game"), you agree to be bound by these Terms of Service.

2. LICENSE
CardMaster Games grants you a limited, non-exclusive, non-transferable license to use the Game for personal, non-commercial purposes.

3. USER CONDUCT
You agree not to:
- Modify, adapt, or hack the Game
- Use cheats, exploits, or automation software
- Attempt to decompile or reverse engineer the Game

4. AGE REQUIREMENTS
This Game is intended for users aged 13 and older. By using this Game, you represent that you are at least 13 years of age. Users under 13 should not use this application.

5. VIRTUAL ITEMS
Any virtual items, currency, or rewards earned in the Game have no real-world value and cannot be exchanged for money.

6. UPDATES
We may update the Game from time to time. Continued use after updates constitutes acceptance of any changes.

7. DISCLAIMER
THE GAME IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.

8. LIMITATION OF LIABILITY
CardMaster Games shall not be liable for any indirect, incidental, or consequential damages.

9. GOVERNING LAW
These Terms shall be governed by applicable law.

10. CONTACT
For questions about these Terms, contact: support@cardmastergames.com
''';

const String placeCardsPrivacy = '''
PLACE THE CARDS - PRIVACY POLICY

Last Updated: December 2024

1. INFORMATION WE COLLECT

We collect the following types of information:

a) Device Information
- Device type and model
- Operating system version
- Unique device identifiers

b) Usage Data
- Game progress and achievements
- Session duration and frequency
- In-game actions and preferences

c) Analytics Data
- Crash reports and performance data
- Feature usage statistics

2. HOW WE USE YOUR INFORMATION

We use collected data to:
- Provide and maintain the Game
- Improve game features and user experience
- Send important updates and notifications
- Analyze usage patterns and trends

3. DATA SHARING

We may share anonymized, aggregated data with:
- Analytics providers
- Advertising partners
- Business partners

4. DATA RETENTION

We retain your data for as long as you use the Game, plus a reasonable period thereafter.

5. YOUR RIGHTS

You may request:
- Access to your personal data
- Deletion of your data
- Correction of inaccurate data

6. CHILDREN'S PRIVACY

We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us.

7. SECURITY

We implement reasonable security measures to protect your data.

8. CHANGES TO THIS POLICY

We may update this Privacy Policy periodically. Continued use constitutes acceptance.

9. CONTACT US

For privacy inquiries: privacy@cardmastergames.com
''';

/// Onboarding state for Place the Cards
enum PlaceCardsState {
  loading,
  tos,
  playing,
}

/// Embedded Place the Cards game with full onboarding
class EmbeddedPlaceCardsApp extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onGameComplete;
  final bool tosAccepted;
  final Function(bool) onTosAccepted;

  const EmbeddedPlaceCardsApp({
    Key? key,
    required this.onBack,
    this.onGameComplete,
    required this.tosAccepted,
    required this.onTosAccepted,
  }) : super(key: key);

  @override
  State<EmbeddedPlaceCardsApp> createState() => _EmbeddedPlaceCardsAppState();
}

class _EmbeddedPlaceCardsAppState extends State<EmbeddedPlaceCardsApp> {
  late PlaceCardsState _state;

  @override
  void initState() {
    super.initState();
    _state = widget.tosAccepted ? PlaceCardsState.playing : PlaceCardsState.loading;
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case PlaceCardsState.loading:
        return GameLoadingScreen(
          appName: 'Place the Cards',
          appIcon: Icons.style,
          appColor: const Color(0xFF3B7DD8),
          onLoadingComplete: () {
            setState(() => _state = PlaceCardsState.tos);
          },
        );
      case PlaceCardsState.tos:
        return GameTosScreen(
          appName: 'Place the Cards',
          tosContent: placeCardsTos,
          privacyContent: placeCardsPrivacy,
          onAccept: () {
            widget.onTosAccepted(true);
            setState(() => _state = PlaceCardsState.playing);
          },
          onDecline: widget.onBack,
        );
      case PlaceCardsState.playing:
        return _PlaceCardsGame(
          onBack: widget.onBack,
          onComplete: widget.onGameComplete,
        );
    }
  }
}

/// Simplified Place the Cards game
class _PlaceCardsGame extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onComplete;

  const _PlaceCardsGame({
    Key? key,
    required this.onBack,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_PlaceCardsGame> createState() => _PlaceCardsGameState();
}

enum _CardCategory { flowers, pets, food }

class _CardData {
  final String label;
  final _CardCategory category;
  final bool isCategoryCard;

  const _CardData({
    required this.label,
    required this.category,
    this.isCategoryCard = false,
  });
}

class _PlaceCardsGameState extends State<_PlaceCardsGame> {
  // 3 Foundation slots
  final List<List<_CardData>> _foundations = [[], [], []];
  
  // 3 Source stacks
  late List<List<_CardData>> _stacks;
  
  // Deck and waste
  List<_CardData> _deck = [];
  List<_CardData> _waste = [];
  
  int _completedCategories = 0;

  static const double _cardWidth = 75.0;
  static const double _cardHeight = 110.0;

  final Map<_CardCategory, Color> _categoryColors = {
    _CardCategory.flowers: NunuColors.primaryMain,
    _CardCategory.pets: NunuColors.secondaryMain,
    _CardCategory.food: NunuColors.successMain,
  };

  @override
  void initState() {
    super.initState();
    _initializeCards();
  }

  void _initializeCards() {
    // Simplified card setup for the embedded game
    const flowerCat = _CardData(label: 'Flowers', category: _CardCategory.flowers, isCategoryCard: true);
    const rose = _CardData(label: 'Rose', category: _CardCategory.flowers);
    const tulip = _CardData(label: 'Tulip', category: _CardCategory.flowers);

    const petsCat = _CardData(label: 'Pets', category: _CardCategory.pets, isCategoryCard: true);
    const cat = _CardData(label: 'Cat', category: _CardCategory.pets);
    const dog = _CardData(label: 'Dog', category: _CardCategory.pets);

    const foodCat = _CardData(label: 'Food', category: _CardCategory.food, isCategoryCard: true);
    const pizza = _CardData(label: 'Pizza', category: _CardCategory.food);
    const burger = _CardData(label: 'Burger', category: _CardCategory.food);

    // Initial setup
    _foundations[0] = [flowerCat];

    _stacks = [
      [rose, pizza],
      [dog, petsCat],
      [cat, tulip],
    ];

    _deck = [burger, foodCat];
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

  void _checkCompletion() {
    if (_completedCategories >= 3) {
      widget.onComplete?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Place the Cards',
            onBack: widget.onBack,
            backgroundColor: const Color(0xFF3B7DD8).withOpacity(0.3),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Top row: Deck and Waste
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildWastePile(),
                      const SizedBox(width: 8),
                      _buildDeckPile(),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Foundation slots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(3, (i) => _buildFoundation(i)),
                  ),
                  const SizedBox(height: 20),
                  // Source stacks
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(3, (i) => _buildSourceStack(i)),
                  ),
                  const Spacer(),
                  // Instructions
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'drag cards to match categories. complete all 3 to win!',
                      style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFoundation(int index) {
    final foundation = _foundations[index];
    final topCard = foundation.isNotEmpty ? foundation.last : null;
    final category = foundation.isNotEmpty ? foundation.first.category : null;

    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data.cards.isEmpty) return false;
        if (foundation.isEmpty) return data.cards.first.isCategoryCard;
        return data.cards.first.category == category;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        setState(() {
          _foundations[index].addAll(data.cards);
          if (data.fromDeck) {
            _waste.removeLast();
          } else {
            _stacks[data.stackIndex!].removeRange(
              _stacks[data.stackIndex!].length - data.cards.length,
              _stacks[data.stackIndex!].length,
            );
          }
          if (_foundations[index].length >= 3) {
            _foundations[index].clear();
            _completedCategories++;
          }
        });
        _checkCompletion();
      },
      builder: (context, candidateData, rejectedData) {
        return Column(
          children: [
            if (category != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD54F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  category.name,
                  style: const TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 4),
            Container(
              width: _cardWidth,
              height: _cardHeight,
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: candidateData.isNotEmpty ? Colors.white : Colors.white24,
                  width: candidateData.isNotEmpty ? 2 : 1,
                ),
              ),
              child: topCard != null ? _buildCardWidget(topCard) : null,
            ),
          ],
        );
      },
    );
  }

  Widget _buildSourceStack(int index) {
    final stack = _stacks[index];
    if (stack.isEmpty) {
      return DragTarget<_DragData>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          final data = details.data;
          setState(() {
            _stacks[index].addAll(data.cards);
            if (data.fromDeck) {
              _waste.removeLast();
            } else {
              _stacks[data.stackIndex!].removeRange(
                _stacks[data.stackIndex!].length - data.cards.length,
                _stacks[data.stackIndex!].length,
              );
            }
          });
        },
        builder: (context, candidateData, rejectedData) {
          return Container(
            width: _cardWidth,
            height: _cardHeight,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
            ),
          );
        },
      );
    }

    // Get matching sequence from top
    int matchingCount = 1;
    final topCategory = stack.last.category;
    for (int i = stack.length - 2; i >= 0; i--) {
      if (stack[i].category == topCategory) {
        matchingCount++;
      } else {
        break;
      }
    }

    final matchingCards = stack.skip(stack.length - matchingCount).toList();

    return DragTarget<_DragData>(
      onWillAcceptWithDetails: (details) {
        final data = details.data;
        if (data.cards.isEmpty) return false;
        return data.cards.first.category == stack.last.category;
      },
      onAcceptWithDetails: (details) {
        final data = details.data;
        setState(() {
          _stacks[index].addAll(data.cards);
          if (data.fromDeck) {
            _waste.removeLast();
          } else {
            _stacks[data.stackIndex!].removeRange(
              _stacks[data.stackIndex!].length - data.cards.length,
              _stacks[data.stackIndex!].length,
            );
          }
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Draggable<_DragData>(
          data: _DragData(stackIndex: index, cards: matchingCards, fromDeck: false),
          feedback: Material(
            color: Colors.transparent,
            child: _buildCascadingStack(matchingCards),
          ),
          childWhenDragging: SizedBox(
            width: _cardWidth,
            height: _cardHeight + (matchingCards.length - 1) * 25.0,
          ),
          child: _buildCascadingStack(matchingCards),
        );
      },
    );
  }

  Widget _buildCascadingStack(List<_CardData> cards) {
    final totalHeight = _cardHeight + (cards.length - 1) * 25.0;
    return SizedBox(
      width: _cardWidth,
      height: totalHeight,
      child: Stack(
        children: List.generate(cards.length, (i) {
          return Positioned(
            top: i * 25.0,
            left: 0,
            child: _buildCardWidget(cards[i]),
          );
        }),
      ),
    );
  }

  Widget _buildDeckPile() {
    return GestureDetector(
      onTap: _onDeckTap,
      child: Container(
        width: _cardWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          color: _deck.isEmpty ? Colors.transparent : const Color(0xFF3B7DD8),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24, width: 1),
        ),
        child: _deck.isEmpty
            ? const Icon(Icons.refresh, color: Colors.white54)
            : const Icon(Icons.grid_view, color: Colors.white24, size: 24),
      ),
    );
  }

  Widget _buildWastePile() {
    if (_waste.isEmpty) {
      return Container(
        width: _cardWidth,
        height: _cardHeight,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
      );
    }

    final topCard = _waste.last;
    return Draggable<_DragData>(
      data: _DragData(cards: [topCard], fromDeck: true),
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(scale: 1.05, child: _buildCardWidget(topCard)),
      ),
      childWhenDragging: _waste.length > 1
          ? _buildCardWidget(_waste[_waste.length - 2])
          : Container(
              width: _cardWidth,
              height: _cardHeight,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
      child: _buildCardWidget(topCard),
    );
  }

  Widget _buildCardWidget(_CardData card) {
    final color = _categoryColors[card.category]!;
    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: card.isCategoryCard ? const Color(0xFFFFD54F) : color,
          width: card.isCategoryCard ? 2 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (card.isCategoryCard)
            const Icon(Icons.emoji_events, color: Color(0xFFFFD54F), size: 20),
          const SizedBox(height: 4),
          Text(
            card.label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _DragData {
  final int? stackIndex;
  final List<_CardData> cards;
  final bool fromDeck;

  _DragData({this.stackIndex, required this.cards, this.fromDeck = false});
}

