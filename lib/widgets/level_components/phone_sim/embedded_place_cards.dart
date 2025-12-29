import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import 'game_onboarding.dart';
import 'phone_homescreen.dart';
import '../../levels/level_phone_simulator.dart';

/// Terms of Service content for Place the Cards
const String placeCardsTos = '''
PLACE THE CARDS - TERMS OF SERVICE

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

5. COMMUNITY CHAT FEATURE

5.1 Chat Access
The Game includes a community chat feature that is unlocked after completing Level 1. By using the chat feature, you agree to these additional terms.

5.2 User Conduct in Chat
When using the community chat, you agree to:
- Treat all users with respect and courtesy
- Not post content that is offensive, abusive, threatening, or harassing
- Not use hate speech, discriminatory language, or slurs
- Not share personal information (yours or others')
- Not spam, advertise, or promote external products/services
- Not share links to malicious or inappropriate websites
- Not impersonate CardMaster Games staff or other users
- Not discuss or encourage illegal activities
- Not engage in bullying or targeted harassment
- Not post sexually explicit or suggestive content

5.3 Content Moderation
We reserve the right to:
- Monitor all chat communications for safety and compliance
- Remove any content that violates these terms without notice
- Temporarily or permanently ban users who violate chat guidelines
- Report serious violations to appropriate authorities
- Use automated filtering to block prohibited content

5.4 Reporting and Blocking
Users can report inappropriate content or behavior through:
- The flag icon in the chat interface
- Emailing safety@cardmastergames.com
We investigate all reports and take appropriate action within 48 hours.

5.5 User Safety
For your safety:
- Never share personal contact information in chat
- Be cautious when interacting with strangers
- Report any suspicious or uncomfortable interactions
- Users under 18 should inform a parent/guardian about chat use

5.6 Parental Notice
Parents and guardians should be aware that this Game contains a chat feature that allows interaction with other users. We recommend:
- Discussing safe online communication with your child
- Monitoring your child's use of the chat feature
- Familiarizing yourself with the reporting tools available

6. VIRTUAL ITEMS
Any virtual items, currency, or rewards earned in the Game have no real-world value and cannot be exchanged for money.

7. UPDATES
We may update the Game from time to time. Continued use after updates constitutes acceptance of any changes.

8. DISCLAIMER
THE GAME IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.

9. LIMITATION OF LIABILITY
CardMaster Games shall not be liable for any indirect, incidental, or consequential damages.

10. GOVERNING LAW
These Terms shall be governed by applicable law.

11. CONTACT
For questions about these Terms, contact: support@cardmastergames.com
For safety concerns: safety@cardmastergames.com

Document Version 2.1.4
Last Updated: November 28, 2024
''';

const String placeCardsPrivacy = '''
PLACE THE CARDS - PRIVACY POLICY

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

d) Chat and Communication Data
- Messages sent through the community chat feature
- User reports and moderation actions
- Chat activity metadata (timestamps, message counts)

2. HOW WE USE YOUR INFORMATION

We use collected data to:
- Provide and maintain the Game
- Improve game features and user experience
- Send important updates and notifications
- Analyze usage patterns and trends
- Moderate community chat and enforce guidelines
- Investigate reports of abuse or violations
- Protect user safety and prevent harmful content
- Comply with legal obligations

2.1 Chat Data Specifically
Chat messages may be:
- Monitored by automated content filtering systems
- Reviewed by human moderators when flagged or reported
- Retained for moderation, safety, and legal compliance
- Used to train and improve content moderation systems
- Analyzed to identify and prevent harmful behavior patterns

3. DATA SHARING

We may share anonymized, aggregated data with:
- Analytics providers
- Advertising partners
- Business partners

We may share chat data with:
- Third-party safety and moderation tools
- Law enforcement when required by law
- Child safety organizations when necessary

4. DATA RETENTION

We retain your data for as long as you use the Game, plus a reasonable period thereafter.

Chat messages are retained for:
- Active moderation: 90 days
- Reported content: Up to 2 years
- Legal compliance: As required by law

5. YOUR RIGHTS

You may request:
- Access to your personal data
- Deletion of your data
- Correction of inaccurate data

Note: Some chat data may be retained even after deletion requests for safety and legal compliance purposes.

6. CHILDREN'S PRIVACY

We do not knowingly collect personal information from children under 13. If you believe we have collected such information, please contact us.

6.1 Chat Feature for Minors
Users aged 13-17 should use the chat feature with parental awareness. We recommend parents discuss safe online communication practices with their children.

7. SECURITY

We implement reasonable security measures to protect your data, including:
- Encryption of data in transit
- Secure storage of chat logs
- Access controls for moderation staff
- Regular security audits

8. CHANGES TO THIS POLICY

We may update this Privacy Policy periodically. Continued use constitutes acceptance.

9. CONTACT US

For privacy inquiries: privacy@cardmastergames.com
For safety concerns: safety@cardmastergames.com

---
Privacy Policy v1.3 | Effective: November 28, 2024
''';

/// Onboarding state for Place the Cards
enum PlaceCardsState { loading, tos, playing }

/// Card category for matching
enum CardCategory { animals, fruits, colors, shapes, sports }

/// A card in the matching game
class MatchCard {
  final String id;
  final String label;
  final CardCategory category;
  final IconData icon;

  const MatchCard({
    required this.id,
    required this.label,
    required this.category,
    required this.icon,
  });
}

/// Level definition
class LevelConfig {
  final int levelNumber;
  final List<CardCategory> categories;
  final int cardsPerCategory;
  final String description;

  const LevelConfig({
    required this.levelNumber,
    required this.categories,
    required this.cardsPerCategory,
    required this.description,
  });

  int get totalCards => categories.length * cardsPerCategory;
}

/// All available cards by category
const Map<CardCategory, List<MatchCard>> allCards = {
  CardCategory.animals: [
    MatchCard(
      id: 'cat',
      label: 'Cat',
      category: CardCategory.animals,
      icon: Icons.pets,
    ),
    MatchCard(
      id: 'dog',
      label: 'Dog',
      category: CardCategory.animals,
      icon: Icons.cruelty_free,
    ),
    MatchCard(
      id: 'bird',
      label: 'Bird',
      category: CardCategory.animals,
      icon: Icons.flutter_dash,
    ),
    MatchCard(
      id: 'fish',
      label: 'Fish',
      category: CardCategory.animals,
      icon: Icons.water,
    ),
  ],
  CardCategory.fruits: [
    MatchCard(
      id: 'apple',
      label: 'Apple',
      category: CardCategory.fruits,
      icon: Icons.apple,
    ),
    MatchCard(
      id: 'cherry',
      label: 'Cherry',
      category: CardCategory.fruits,
      icon: Icons.local_dining,
    ),
    MatchCard(
      id: 'banana',
      label: 'Banana',
      category: CardCategory.fruits,
      icon: Icons.breakfast_dining,
    ),
    MatchCard(
      id: 'grape',
      label: 'Grape',
      category: CardCategory.fruits,
      icon: Icons.eco,
    ),
  ],
  CardCategory.colors: [
    MatchCard(
      id: 'red',
      label: 'Red',
      category: CardCategory.colors,
      icon: Icons.circle,
    ),
    MatchCard(
      id: 'blue',
      label: 'Blue',
      category: CardCategory.colors,
      icon: Icons.circle,
    ),
    MatchCard(
      id: 'green',
      label: 'Green',
      category: CardCategory.colors,
      icon: Icons.circle,
    ),
    MatchCard(
      id: 'yellow',
      label: 'Yellow',
      category: CardCategory.colors,
      icon: Icons.circle,
    ),
  ],
  CardCategory.shapes: [
    MatchCard(
      id: 'square',
      label: 'Square',
      category: CardCategory.shapes,
      icon: Icons.square,
    ),
    MatchCard(
      id: 'circle',
      label: 'Circle',
      category: CardCategory.shapes,
      icon: Icons.circle_outlined,
    ),
    MatchCard(
      id: 'triangle',
      label: 'Triangle',
      category: CardCategory.shapes,
      icon: Icons.change_history,
    ),
    MatchCard(
      id: 'star',
      label: 'Star',
      category: CardCategory.shapes,
      icon: Icons.star,
    ),
  ],
  CardCategory.sports: [
    MatchCard(
      id: 'soccer',
      label: 'Soccer',
      category: CardCategory.sports,
      icon: Icons.sports_soccer,
    ),
    MatchCard(
      id: 'basketball',
      label: 'Basketball',
      category: CardCategory.sports,
      icon: Icons.sports_basketball,
    ),
    MatchCard(
      id: 'tennis',
      label: 'Tennis',
      category: CardCategory.sports,
      icon: Icons.sports_tennis,
    ),
    MatchCard(
      id: 'golf',
      label: 'Golf',
      category: CardCategory.sports,
      icon: Icons.golf_course,
    ),
  ],
};

/// Level configurations
const List<LevelConfig> levels = [
  LevelConfig(
    levelNumber: 1,
    categories: [CardCategory.animals],
    cardsPerCategory: 2,
    description: 'match 2 animals',
  ),
  LevelConfig(
    levelNumber: 2,
    categories: [CardCategory.animals, CardCategory.fruits],
    cardsPerCategory: 1,
    description: 'match animals & fruits',
  ),
  LevelConfig(
    levelNumber: 3,
    categories: [CardCategory.animals, CardCategory.fruits],
    cardsPerCategory: 2,
    description: 'more cards!',
  ),
  LevelConfig(
    levelNumber: 4,
    categories: [CardCategory.colors, CardCategory.shapes],
    cardsPerCategory: 2,
    description: 'colors & shapes',
  ),
  LevelConfig(
    levelNumber: 5,
    categories: [
      CardCategory.animals,
      CardCategory.fruits,
      CardCategory.sports,
    ],
    cardsPerCategory: 2,
    description: 'triple challenge',
  ),
  LevelConfig(
    levelNumber: 6,
    categories: [
      CardCategory.animals,
      CardCategory.fruits,
      CardCategory.colors,
      CardCategory.shapes,
    ],
    cardsPerCategory: 1,
    description: 'all categories!',
  ),
];

/// Category colors
Color getCategoryColor(CardCategory category) {
  switch (category) {
    case CardCategory.animals:
      return const Color(0xFF8B5CF6);
    case CardCategory.fruits:
      return const Color(0xFFEF4444);
    case CardCategory.colors:
      return const Color(0xFF3B82F6);
    case CardCategory.shapes:
      return const Color(0xFFF59E0B);
    case CardCategory.sports:
      return const Color(0xFF10B981);
  }
}

/// Embedded Place the Cards game with simple matching and level system
class EmbeddedPlaceCardsApp extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onGameComplete;
  final bool tosAccepted;
  final Function(bool) onTosAccepted;
  final PlaceCardsGameState gameState;
  final Function(PlaceCardsGameState) onGameStateChanged;
  final VoidCallback onClearData;

  const EmbeddedPlaceCardsApp({
    Key? key,
    required this.onBack,
    this.onGameComplete,
    required this.tosAccepted,
    required this.onTosAccepted,
    required this.gameState,
    required this.onGameStateChanged,
    required this.onClearData,
  }) : super(key: key);

  @override
  State<EmbeddedPlaceCardsApp> createState() => _EmbeddedPlaceCardsAppState();
}

class _EmbeddedPlaceCardsAppState extends State<EmbeddedPlaceCardsApp> {
  late PlaceCardsState _state;
  bool _showProfile = false;
  bool _showLevelSelect = false;
  bool _showStore = false;
  bool _showChat = false;

  // Chat message state
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, dynamic>> _chatMessages = [];
  bool _chatInitialized = false;

  static const Color _appColor = Color(0xFF3B7DD8);

  @override
  void initState() {
    super.initState();
    _state = widget.tosAccepted
        ? PlaceCardsState.playing
        : PlaceCardsState.loading;
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _initChatMessages() {
    if (_chatInitialized) return;
    _chatInitialized = true;
    _chatMessages.addAll([
      {
        'sender': 'CardMaster_99',
        'message': 'hey everyone! just beat level 5 🎉',
        'time': '2m ago',
        'isMe': false,
      },
      {
        'sender': 'PuzzlePro',
        'message': 'nice! that one took me forever',
        'time': '1m ago',
        'isMe': false,
      },
      {
        'sender': 'CardMaster_99',
        'message': 'the shapes category is tricky',
        'time': '1m ago',
        'isMe': false,
      },
      {
        'sender': 'NewPlayer42',
        'message': 'any tips for beginners?',
        'time': '30s ago',
        'isMe': false,
      },
      {
        'sender': 'PuzzlePro',
        'message': 'focus on one category at a time!',
        'time': 'just now',
        'isMe': false,
      },
    ]);
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case PlaceCardsState.loading:
        return GameLoadingScreen(
          appName: 'Place the Cards',
          appIcon: Icons.style,
          appColor: _appColor,
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
        if (_showProfile) {
          return _buildProfileScreen();
        }
        if (_showLevelSelect) {
          return _buildLevelSelectScreen();
        }
        if (_showStore) {
          return _buildStoreScreen();
        }
        if (_showChat) {
          _initChatMessages();
          return _buildChatScreen();
        }
        return _PlaceCardsGame(
          currentLevel: widget.gameState.currentLevel,
          onBack: widget.onBack,
          onComplete: (levelNum) {
            // Update progress
            final newCompletedLevels =
                levelNum > widget.gameState.completedLevels
                ? levelNum
                : widget.gameState.completedLevels;
            final nextLevel = levelNum < levels.length
                ? levelNum + 1
                : levelNum;
            widget.onGameStateChanged(
              widget.gameState.copyWith(
                currentLevel: nextLevel,
                completedLevels: newCompletedLevels,
                highScore: widget.gameState.highScore + 100,
              ),
            );
            widget.onGameComplete?.call();
          },
          onOpenProfile: () => setState(() => _showProfile = true),
          onOpenLevelSelect: () => setState(() => _showLevelSelect = true),
          onOpenStore: () => setState(() => _showStore = true),
          onOpenChat: () => setState(() => _showChat = true),
          completedLevels: widget.gameState.completedLevels,
        );
    }
  }

  Widget _buildStoreScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'store',
            onBack: () => setState(() => _showStore = false),
            backgroundColor: Colors.amber.withOpacity(0.3),
          ),
          // Coins display
          Container(
            padding: const EdgeInsets.all(12),
            color: NunuColors.backgroundPaper.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 18,
                      ),
                      SizedBox(width: 6),
                      Text(
                        '850',
                        style: TextStyle(
                          color: Colors.amber,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'themes',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'customize your game board',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStoreItem(
                  'Ocean Breeze',
                  'relaxing blue theme',
                  '200 coins',
                  Icons.waves,
                  Colors.blue,
                ),
                _buildStoreItem(
                  'Forest Glade',
                  'nature-inspired greens',
                  '200 coins',
                  Icons.forest,
                  Colors.green,
                ),
                _buildStoreItem(
                  'Sunset Glow',
                  'warm orange tones',
                  '250 coins',
                  Icons.wb_twilight,
                  Colors.orange,
                ),
                _buildStoreItem(
                  'Midnight',
                  'sleek dark purple',
                  '300 coins',
                  Icons.nightlight,
                  Colors.purple,
                  isPremium: true,
                ),
                const SizedBox(height: 24),
                const Text(
                  'card backs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'style your cards',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStoreItem(
                  'Classic Pattern',
                  'traditional card back',
                  '100 coins',
                  Icons.pattern,
                  Colors.grey,
                ),
                _buildStoreItem(
                  'Starry Night',
                  'twinkling stars design',
                  '150 coins',
                  Icons.star,
                  Colors.indigo,
                ),
                _buildStoreItem(
                  'Geometric',
                  'modern shapes',
                  '150 coins',
                  Icons.hexagon,
                  Colors.teal,
                ),
                const SizedBox(height: 24),
                const Text(
                  'power-ups',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'helpful items for tough levels',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                _buildStoreItem(
                  'Hint x3',
                  'reveals a matching pair',
                  '50 coins',
                  Icons.lightbulb,
                  Colors.yellow,
                ),
                _buildStoreItem(
                  'Time Freeze x2',
                  'pauses timer for 30 seconds',
                  '75 coins',
                  Icons.timer_off,
                  Colors.cyan,
                ),
                _buildStoreItem(
                  'Shuffle x3',
                  'rearranges all cards',
                  '40 coins',
                  Icons.shuffle,
                  Colors.pink,
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 24),
                // Tier 3 - Power Card Pack (real money, gameplay impact, no trading)
                const Text(
                  'premium packs',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'boost your gameplay with premium items',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade700, Colors.red.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.bolt,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'power card pack',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'REAL MONEY',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.orange,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'GAMEPLAY ADVANTAGE',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'powerful items to help you beat difficult levels!',
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'possible contents:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '• super hint (reveals 3 pairs): 35%\n'
                              '• wildcard (matches any card): 25%\n'
                              '• extra moves (+5): 20%\n'
                              '• time freeze (2 min): 12%\n'
                              '• level skip token: 5%\n'
                              '• mega bundle (all above): 3%',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // No trading warning
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(Icons.block, color: Colors.white70, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'NO THIRD-PARTY TRADING - items are bound to your account and cannot be sold, traded, or transferred',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                '\$7.99',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {},
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade900,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                '3 for \$19.99',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text(
                          'all purchases are final and non-refundable',
                          style: TextStyle(color: Colors.white60, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Info about earning coins
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.info_outline,
                            color: Colors.amber,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'how to earn coins',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• Complete levels to earn coins\n'
                        '• Daily login bonus: 25 coins\n'
                        '• Beat your high score: bonus coins\n'
                        '• Complete all levels: 500 coin reward',
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 12,
                          height: 1.5,
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

  Widget _buildStoreItem(
    String name,
    String description,
    String price,
    IconData icon,
    Color color, {
    bool isPremium = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: isPremium ? Border.all(color: Colors.amber, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEW',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            child: Text(
              price,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatScreen() {
    final chatUnlocked = widget.gameState.completedLevels >= 1;

    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'community chat',
            onBack: () => setState(() => _showChat = false),
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          if (!chatUnlocked) ...[
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: NunuColors.backgroundPaper,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_outline,
                          color: NunuColors.textSecondary,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'chat locked',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'complete level 1 to unlock the community chat and connect with other players!',
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => _showChat = false),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('play now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _appColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ] else ...[
            // Online users indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: NunuColors.backgroundPaper,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    '247 players online',
                    style: TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {},
                    child: const Icon(
                      Icons.flag_outlined,
                      color: NunuColors.textSecondary,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            // Chat messages
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _chatMessages.length,
                itemBuilder: (context, index) {
                  final msg = _chatMessages[index];
                  final isMe = msg['isMe'] == true;
                  return _buildChatMessage(
                    msg['sender'] as String,
                    msg['message'] as String,
                    msg['time'] as String,
                    isMe,
                  );
                },
              ),
            ),
            // Message input
            Container(
              padding: const EdgeInsets.all(12),
              color: NunuColors.backgroundPaper,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'type a message...',
                        hintStyle: const TextStyle(
                          color: NunuColors.textSecondary,
                        ),
                        filled: true,
                        fillColor: NunuColors.backgroundDefault,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      if (_chatController.text.trim().isNotEmpty) {
                        setState(() {
                          _chatMessages.add({
                            'sender': 'You',
                            'message': _chatController.text.trim(),
                            'time': 'just now',
                            'isMe': true,
                          });
                          _chatController.clear();
                        });
                      }
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: _appColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.send,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildChatMessage(
    String sender,
    String message,
    String time,
    bool isMe,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: _appColor.withOpacity(0.3),
              child: Text(
                sender[0].toUpperCase(),
                style: TextStyle(
                  color: _appColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isMe ? _appColor : NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Text(
                      sender,
                      style: TextStyle(
                        color: _appColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Text(
                    message,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: isMe ? Colors.white70 : NunuColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildLevelSelectScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'select level',
            onBack: () => setState(() => _showLevelSelect = false),
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: levels.length,
              itemBuilder: (context, index) {
                final level = levels[index];
                final isUnlocked =
                    level.levelNumber <= widget.gameState.completedLevels + 1;
                final isCompleted =
                    level.levelNumber <= widget.gameState.completedLevels;
                final isCurrent =
                    level.levelNumber == widget.gameState.currentLevel;

                return GestureDetector(
                  onTap: isUnlocked
                      ? () {
                          widget.onGameStateChanged(
                            widget.gameState.copyWith(
                              currentLevel: level.levelNumber,
                            ),
                          );
                          setState(() => _showLevelSelect = false);
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isUnlocked
                          ? NunuColors.backgroundPaper
                          : NunuColors.backgroundDefault,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isCurrent
                            ? _appColor
                            : isCompleted
                            ? NunuColors.successMain
                            : Colors.white.withOpacity(0.1),
                        width: isCurrent ? 3 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (isCompleted)
                          const Icon(
                            Icons.check_circle,
                            color: NunuColors.successMain,
                            size: 28,
                          )
                        else if (!isUnlocked)
                          const Icon(
                            Icons.lock,
                            color: NunuColors.textSecondary,
                            size: 28,
                          )
                        else
                          Text(
                            '${level.levelNumber}',
                            style: TextStyle(
                              color: isCurrent ? _appColor : Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          level.description,
                          style: TextStyle(
                            color: isUnlocked
                                ? NunuColors.textSecondary
                                : NunuColors.textSecondary.withOpacity(0.5),
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'profile & settings',
            onBack: () => setState(() => _showProfile = false),
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _appColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'guest player',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'level ${widget.gameState.currentLevel}',
                          style: const TextStyle(
                            color: NunuColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Stats
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'game stats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(
                          'Current Level',
                          '${widget.gameState.currentLevel}',
                        ),
                        _buildStatRow(
                          'Levels Completed',
                          '${widget.gameState.completedLevels}',
                        ),
                        _buildStatRow(
                          'High Score',
                          '${widget.gameState.highScore}',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Settings
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildSettingsItem(
                          Icons.notifications,
                          'notifications',
                          () {},
                        ),
                        _buildSettingsItem(Icons.volume_up, 'sound', () {}),
                        _buildSettingsItem(Icons.help, 'help', () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Data management
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'data management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ListTile(
                          leading: const Icon(
                            Icons.delete_outline,
                            color: NunuColors.errorMain,
                          ),
                          title: const Text(
                            'delete game data',
                            style: TextStyle(color: NunuColors.errorMain),
                          ),
                          subtitle: const Text(
                            'remove all progress and start fresh',
                            style: TextStyle(
                              color: NunuColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                          onTap: _showDeleteConfirmation,
                        ),
                      ],
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

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: NunuColors.textSecondary)),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: NunuColors.textSecondary),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(
        Icons.chevron_right,
        color: NunuColors.textSecondary,
      ),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        title: const Text(
          'delete game data?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'this will delete all your game progress including completed levels and high scores. this action cannot be undone.',
          style: TextStyle(color: NunuColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'cancel',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onClearData();
              setState(() => _showProfile = false);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('game data deleted'),
                  backgroundColor: NunuColors.errorMain,
                ),
              );
            },
            child: const Text(
              'delete',
              style: TextStyle(color: NunuColors.errorMain),
            ),
          ),
        ],
      ),
    );
  }
}

/// The actual matching game
class _PlaceCardsGame extends StatefulWidget {
  final int currentLevel;
  final VoidCallback onBack;
  final Function(int levelNum) onComplete;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenLevelSelect;
  final VoidCallback? onOpenStore;
  final VoidCallback? onOpenChat;
  final int completedLevels;

  const _PlaceCardsGame({
    Key? key,
    required this.currentLevel,
    required this.onBack,
    required this.onComplete,
    this.onOpenProfile,
    this.onOpenLevelSelect,
    this.onOpenStore,
    this.onOpenChat,
    this.completedLevels = 0,
  }) : super(key: key);

  @override
  State<_PlaceCardsGame> createState() => _PlaceCardsGameState();
}

class _PlaceCardsGameState extends State<_PlaceCardsGame> {
  late LevelConfig _levelConfig;
  late List<MatchCard> _cards;
  late Map<CardCategory, List<MatchCard>> _placedCards;
  bool _levelComplete = false;

  static const double _cardWidth = 70.0;
  static const double _cardHeight = 90.0;
  static const Color _appColor = Color(0xFF3B7DD8);

  @override
  void initState() {
    super.initState();
    _initLevel();
  }

  @override
  void didUpdateWidget(_PlaceCardsGame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentLevel != widget.currentLevel) {
      _initLevel();
    }
  }

  void _initLevel() {
    final levelIndex = (widget.currentLevel - 1).clamp(0, levels.length - 1);
    _levelConfig = levels[levelIndex];
    _levelComplete = false;
    _placedCards = {};

    // Initialize placed cards map
    for (final cat in _levelConfig.categories) {
      _placedCards[cat] = [];
    }

    // Generate cards for this level
    _cards = [];
    for (final cat in _levelConfig.categories) {
      final categoryCards = allCards[cat]!;
      for (int i = 0; i < _levelConfig.cardsPerCategory; i++) {
        _cards.add(categoryCards[i % categoryCards.length]);
      }
    }
    // Shuffle cards
    _cards.shuffle();
  }

  void _onCardPlaced(MatchCard card, CardCategory targetCategory) {
    if (card.category != targetCategory) {
      // Wrong category - show error feedback
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${card.label} doesn\'t belong in ${targetCategory.name}!',
          ),
          backgroundColor: NunuColors.errorMain,
          duration: const Duration(milliseconds: 800),
        ),
      );
      return;
    }

    // Correct placement
    setState(() {
      _cards.remove(card);
      _placedCards[targetCategory]!.add(card);
    });
    HapticFeedback.mediumImpact();

    // Check if level complete
    if (_cards.isEmpty) {
      setState(() => _levelComplete = true);
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(_levelConfig.levelNumber);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'level ${_levelConfig.levelNumber}',
            onBack: widget.onBack,
            backgroundColor: _appColor.withOpacity(0.3),
            actions: [
              if (widget.onOpenStore != null)
                IconButton(
                  icon: const Icon(Icons.store, color: Colors.amber),
                  onPressed: widget.onOpenStore,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36),
                ),
              if (widget.onOpenChat != null)
                Stack(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.chat_bubble_outline,
                        color: widget.completedLevels >= 1
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                      ),
                      onPressed: widget.onOpenChat,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36),
                    ),
                    if (widget.completedLevels < 1)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: NunuColors.backgroundPaper,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock,
                            size: 8,
                            color: NunuColors.textSecondary,
                          ),
                        ),
                      ),
                  ],
                ),
              if (widget.onOpenLevelSelect != null)
                IconButton(
                  icon: const Icon(Icons.grid_view, color: Colors.white),
                  onPressed: widget.onOpenLevelSelect,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36),
                ),
              if (widget.onOpenProfile != null)
                IconButton(
                  icon: const Icon(Icons.person, color: Colors.white),
                  onPressed: widget.onOpenProfile,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36),
                ),
            ],
          ),
          // Level info
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: NunuColors.backgroundPaper.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _levelConfig.description,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  '${_cards.length} cards left',
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Category slots (drop targets)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _levelConfig.categories
                  .map((cat) => _buildCategorySlot(cat))
                  .toList(),
            ),
          ),
          const SizedBox(height: 24),
          // Divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            height: 2,
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 16),
          // Cards to place
          Expanded(
            child: _levelComplete
                ? _buildLevelCompleteMessage()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: _cards
                          .map((card) => _buildDraggableCard(card))
                          .toList(),
                    ),
                  ),
          ),
          // Instructions
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'drag each card to its matching category!',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCompleteMessage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: NunuColors.successMain.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check,
              color: NunuColors.successMain,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'level complete!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'well done!',
            style: TextStyle(color: NunuColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySlot(CardCategory category) {
    final color = getCategoryColor(category);
    final placedCount = _placedCards[category]?.length ?? 0;
    final targetCount = _levelConfig.cardsPerCategory;
    final isComplete = placedCount >= targetCount;

    return DragTarget<MatchCard>(
      onWillAcceptWithDetails: (details) => !isComplete,
      onAcceptWithDetails: (details) => _onCardPlaced(details.data, category),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final isCorrectCategory =
            candidateData.isNotEmpty &&
            candidateData.first?.category == category;

        return Container(
          width: 100,
          height: 120,
          decoration: BoxDecoration(
            color: isComplete
                ? color.withOpacity(0.3)
                : isHighlighted
                ? (isCorrectCategory
                      ? color.withOpacity(0.3)
                      : NunuColors.errorMain.withOpacity(0.2))
                : NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isComplete
                  ? NunuColors.successMain
                  : isHighlighted
                  ? (isCorrectCategory ? color : NunuColors.errorMain)
                  : color.withOpacity(0.5),
              width: isHighlighted || isComplete ? 3 : 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isComplete)
                const Icon(
                  Icons.check_circle,
                  color: NunuColors.successMain,
                  size: 32,
                )
              else
                Icon(_getCategoryIcon(category), color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$placedCount / $targetCount',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getCategoryIcon(CardCategory category) {
    switch (category) {
      case CardCategory.animals:
        return Icons.pets;
      case CardCategory.fruits:
        return Icons.restaurant;
      case CardCategory.colors:
        return Icons.palette;
      case CardCategory.shapes:
        return Icons.category;
      case CardCategory.sports:
        return Icons.sports;
    }
  }

  Widget _buildDraggableCard(MatchCard card) {
    final color = getCategoryColor(card.category);

    return Draggable<MatchCard>(
      data: card,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.1,
          child: _buildCardWidget(card, color, isDragging: true),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildCardWidget(card, color),
      ),
      child: _buildCardWidget(card, color),
    );
  }

  Widget _buildCardWidget(
    MatchCard card,
    Color color, {
    bool isDragging = false,
  }) {
    return Container(
      width: _cardWidth,
      height: _cardHeight,
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 2),
        boxShadow: isDragging
            ? [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(card.icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            card.label,
            style: const TextStyle(color: Colors.white, fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
