import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import 'game_onboarding.dart';
import 'phone_homescreen.dart';
import '../../levels/level_phone_simulator.dart';

/// Terms of Service content for Mega Merge
const String megaMergeTos = '''
MEGA MERGE - TERMS OF SERVICE

Last Updated: December 2024

1. ACCEPTANCE OF TERMS
By downloading, installing, or using Mega Merge ("the Game"), you agree to be bound by these Terms of Service.

2. LICENSE GRANT
MergeCorp Studios grants you a limited, non-exclusive, revocable license to use the Game for personal entertainment purposes only.

3. ELIGIBILITY AND AGE REQUIREMENTS
IMPORTANT: This Game is intended for mature audiences.

3.1 Age Verification Required
You must be at least 18 years of age to play this Game. Upon first launch, you will be required to confirm your age through our age verification system.

3.2 Prohibition of Minor Users
Users under the age of 18 are strictly prohibited from using this Game. By accepting these terms, you confirm that you are 18 years of age or older.

3.3 Parental Responsibility
Parents and guardians should monitor their children's device usage to prevent unauthorized access to age-restricted content.

4. USER ACCOUNTS
- You are responsible for maintaining account security
- One account per user
- Account sharing is prohibited

5. IN-GAME PURCHASES
- Virtual currency and items have no real-world value
- All purchases are final
- Refunds are at our sole discretion

6. PROHIBITED CONDUCT
You agree not to:
- Use cheats, bots, or automation tools
- Exploit bugs or glitches
- Harass other players
- Engage in fraudulent activity

7. INTELLECTUAL PROPERTY
All game content, including graphics, audio, and code, is owned by MergeCorp Studios.

8. PRIVACY
Your use of the Game is subject to our Privacy Policy.

9. TERMINATION
We may terminate your access for violation of these Terms.

10. DISCLAIMER
THE GAME IS PROVIDED "AS IS" WITHOUT WARRANTIES.

11. LIMITATION OF LIABILITY
MergeCorp Studios shall not be liable for any damages arising from use of the Game.

12. CONTACT
support@mergecorp.com
''';

const String megaMergePrivacy = '''
MEGA MERGE - PRIVACY POLICY

Last Updated: December 2024

MergeCorp Studios ("we", "our", "us") is committed to protecting your privacy.

1. INFORMATION COLLECTION

1.1 Information You Provide
- Account registration data (email, username)
- Age verification confirmation
- Customer support communications

1.2 Automatically Collected Information
- Device identifiers and specifications
- IP address and general location
- Game progress and statistics
- Session duration and frequency

1.3 Third-Party Services
- Analytics providers (anonymized data)
- Cloud save services

2. USE OF INFORMATION

We use your information to:
- Provide and improve the Game
- Verify user eligibility (age verification)
- Send important service updates
- Respond to support requests
- Analyze usage patterns

3. DATA SHARING

We may share data with:
- Service providers (hosting, analytics)
- Legal authorities when required
- Business partners (anonymized only)

4. CHILDREN'S PRIVACY

IMPORTANT: This Game is not intended for children under 18.

4.1 No Data Collection from Minors
We do not knowingly collect personal information from users under 18 years of age.

4.2 Parental Notice
If you are a parent and believe your child has provided personal information, please contact us immediately at privacy@mergecorp.com.

4.3 Data Deletion
Upon notification, we will promptly delete any information collected from minors.

5. DATA SECURITY

We implement industry-standard security measures including:
- Encryption in transit and at rest
- Regular security audits
- Access controls and monitoring

6. DATA RETENTION

We retain data for the duration of your account plus 2 years, unless legal requirements mandate longer retention.

7. YOUR RIGHTS

You have the right to:
- Access your personal data
- Request data deletion
- Opt out of marketing
- Export your data

8. INTERNATIONAL TRANSFERS

Your data may be transferred to and processed in other countries.

9. POLICY UPDATES

We may update this policy. Continued use after changes constitutes acceptance.

10. CONTACT US

Privacy inquiries: privacy@mergecorp.com
Data Protection Officer: dpo@mergecorp.com
''';

/// Onboarding state for Mega Merge
enum MegaMergeState { notUpdated, loading, tos, ageGate, playing }

/// Embedded Mega Merge game with full onboarding including age gate
class EmbeddedMegaMergeApp extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onGameComplete;
  final bool isUpdated;
  final bool tosAccepted;
  final bool ageVerified;
  final Function(bool) onTosAccepted;
  final Function(bool) onAgeVerified;
  final MegaMergeGameState gameState;
  final Function(MegaMergeGameState) onGameStateChanged;
  final VoidCallback onClearData;

  /// Callback to navigate to Play Store with a specific app ID
  final Function(String appId)? onNavigateToPlayStore;

  const EmbeddedMegaMergeApp({
    Key? key,
    required this.onBack,
    this.onGameComplete,
    required this.isUpdated,
    required this.tosAccepted,
    required this.ageVerified,
    required this.onTosAccepted,
    required this.onAgeVerified,
    required this.gameState,
    required this.onGameStateChanged,
    required this.onClearData,
    this.onNavigateToPlayStore,
  }) : super(key: key);

  @override
  State<EmbeddedMegaMergeApp> createState() => _EmbeddedMegaMergeAppState();
}

/// Menu sub-screen options
enum MenuSubScreen {
  main,
  mergePlus,
  followUs,
  settings,
  promoCode,
  adventures,
  giftCenter,
  rewardCenter,
  connectLogout,
  support,
}

class _EmbeddedMegaMergeAppState extends State<EmbeddedMegaMergeApp> {
  late MegaMergeState _state;
  bool _showMenu = false;
  MenuSubScreen _menuSubScreen = MenuSubScreen.main;

  static const Color _appColor = Color(0xFF9C27B0);

  @override
  void initState() {
    super.initState();
    _determineState();
  }

  @override
  void didUpdateWidget(EmbeddedMegaMergeApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isUpdated != widget.isUpdated) {
      _determineState();
    }
  }

  void _determineState() {
    if (!widget.isUpdated) {
      _state = MegaMergeState.notUpdated;
    } else if (widget.ageVerified) {
      _state = MegaMergeState.playing;
    } else if (widget.tosAccepted) {
      _state = MegaMergeState.ageGate;
    } else {
      _state = MegaMergeState.loading;
    }
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case MegaMergeState.notUpdated:
        return _buildUpdateRequired();
      case MegaMergeState.loading:
        return GameLoadingScreen(
          appName: 'Mega Merge',
          appIcon: Icons.merge_type,
          appColor: _appColor,
          onLoadingComplete: () {
            setState(() => _state = MegaMergeState.tos);
          },
        );
      case MegaMergeState.tos:
        return GameTosScreen(
          appName: 'Mega Merge',
          tosContent: megaMergeTos,
          privacyContent: megaMergePrivacy,
          onAccept: () {
            widget.onTosAccepted(true);
            setState(() => _state = MegaMergeState.ageGate);
          },
          onDecline: widget.onBack,
        );
      case MegaMergeState.ageGate:
        return _buildAgeGateScreen();
      case MegaMergeState.playing:
        if (_showMenu) {
          return _buildMenuScreen();
        }
        return _MegaMergeGame(
          onBack: widget.onBack,
          onComplete: () {
            // Level complete - advance to next level
            final newLevel = widget.gameState.currentLevel + 1;
            widget.onGameStateChanged(
              widget.gameState.copyWith(currentLevel: newLevel),
            );
            widget.onGameComplete?.call();
          },
          onOpenMenu: () => setState(() => _showMenu = true),
          gameState: widget.gameState,
          onGameStateChanged: widget.onGameStateChanged,
        );
    }
  }

  Widget _buildMenuScreen() {
    switch (_menuSubScreen) {
      case MenuSubScreen.main:
        return _buildMainMenu();
      case MenuSubScreen.mergePlus:
        return _buildMergePlusScreen();
      case MenuSubScreen.followUs:
        return _buildFollowUsScreen();
      case MenuSubScreen.settings:
        return _buildSettingsScreen();
      case MenuSubScreen.promoCode:
        return _buildPromoCodeScreen();
      case MenuSubScreen.adventures:
        return _buildAdventuresScreen();
      case MenuSubScreen.giftCenter:
        return _buildGiftCenterScreen();
      case MenuSubScreen.rewardCenter:
        return _buildRewardCenterScreen();
      case MenuSubScreen.connectLogout:
        return _buildConnectLogoutScreen();
      case MenuSubScreen.support:
        return _buildSupportScreen();
    }
  }

  Widget _buildMainMenu() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'menu',
            onBack: () => setState(() {
              _showMenu = false;
              _menuSubScreen = MenuSubScreen.main;
            }),
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildMenuItem(
                  Icons.workspace_premium,
                  'merge plus',
                  _appColor,
                  () =>
                      setState(() => _menuSubScreen = MenuSubScreen.mergePlus),
                ),
                _buildMenuItem(
                  Icons.people,
                  'follow us',
                  null,
                  () => setState(() => _menuSubScreen = MenuSubScreen.followUs),
                ),
                _buildMenuItem(
                  Icons.settings,
                  'settings',
                  null,
                  () => setState(() => _menuSubScreen = MenuSubScreen.settings),
                ),
                _buildMenuItem(
                  Icons.confirmation_number,
                  'promo code',
                  null,
                  () =>
                      setState(() => _menuSubScreen = MenuSubScreen.promoCode),
                ),
                _buildMenuItem(
                  Icons.explore,
                  'adventures',
                  null,
                  () =>
                      setState(() => _menuSubScreen = MenuSubScreen.adventures),
                ),
                _buildMenuItem(
                  Icons.card_giftcard,
                  'gift center',
                  null,
                  () =>
                      setState(() => _menuSubScreen = MenuSubScreen.giftCenter),
                ),
                _buildMenuItem(
                  Icons.emoji_events,
                  'reward center',
                  null,
                  () => setState(
                    () => _menuSubScreen = MenuSubScreen.rewardCenter,
                  ),
                ),
                _buildMenuItem(
                  Icons.sync_alt,
                  'connect/logout',
                  null,
                  () => setState(
                    () => _menuSubScreen = MenuSubScreen.connectLogout,
                  ),
                ),
                _buildMenuItem(
                  Icons.info,
                  'about',
                  null,
                  () => _showAboutDialog(),
                ),
                _buildMenuItem(
                  Icons.help,
                  'support',
                  null,
                  () => setState(() => _menuSubScreen = MenuSubScreen.support),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _goBackToMainMenu() {
    setState(() => _menuSubScreen = MenuSubScreen.main);
  }

  Widget _buildMergePlusScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'merge plus',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Premium badge
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_appColor, Colors.amber],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.workspace_premium,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'upgrade to merge plus',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'unlock exclusive features',
                    style: TextStyle(color: NunuColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  _buildPremiumFeature(Icons.block, 'ad-free experience'),
                  _buildPremiumFeature(Icons.speed, '2x merge speed'),
                  _buildPremiumFeature(
                    Icons.inventory_2,
                    'unlimited generator uses',
                  ),
                  _buildPremiumFeature(Icons.palette, 'exclusive themes'),
                  _buildPremiumFeature(Icons.support_agent, 'priority support'),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'monthly',
                          style: TextStyle(color: NunuColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '\$4.99/month',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _appColor,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: const Text(
                              'subscribe',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
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

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _appColor, size: 24),
          const SizedBox(width: 16),
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildFollowUsScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'follow us',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  const Text(
                    'stay connected!',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'follow us for updates, tips & giveaways',
                    style: TextStyle(color: NunuColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildSocialLink(
                    Icons.facebook,
                    'facebook',
                    const Color(0xFF1877F2),
                  ),
                  _buildSocialLink(
                    Icons.camera_alt,
                    'instagram',
                    const Color(0xFFE4405F),
                  ),
                  _buildSocialLink(
                    Icons.alternate_email,
                    'twitter / x',
                    const Color(0xFF1DA1F2),
                  ),
                  _buildSocialLink(
                    Icons.play_circle,
                    'youtube',
                    const Color(0xFFFF0000),
                  ),
                  _buildSocialLink(
                    Icons.discord,
                    'discord',
                    const Color(0xFF5865F2),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLink(IconData icon, String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        trailing: const Icon(
          Icons.open_in_new,
          color: NunuColors.textSecondary,
        ),
        tileColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {},
      ),
    );
  }

  Widget _buildSettingsScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'settings',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSettingsSection('sound & music', [
                  _buildSettingsToggle('sound effects', true),
                  _buildSettingsToggle('background music', true),
                  _buildSettingsToggle('vibration', true),
                ]),
                const SizedBox(height: 16),
                _buildSettingsSection('notifications', [
                  _buildSettingsToggle('push notifications', true),
                  _buildSettingsToggle('daily reminders', false),
                  _buildSettingsToggle('event alerts', true),
                ]),
                const SizedBox(height: 16),
                _buildSettingsSection('display', [
                  _buildSettingsToggle('show hints', true),
                  _buildSettingsToggle('animations', true),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...items,
        ],
      ),
    );
  }

  Widget _buildSettingsToggle(String label, bool initialValue) {
    return StatefulBuilder(
      builder: (context, setLocalState) {
        bool value = initialValue;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(color: NunuColors.textSecondary),
              ),
              Switch(
                value: value,
                onChanged: (v) => setLocalState(() => value = v),
                activeColor: _appColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPromoCodeScreen() {
    final controller = TextEditingController();
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'promo code',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.confirmation_number,
                    color: NunuColors.primaryMain,
                    size: 64,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'enter promo code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'redeem codes for exclusive rewards',
                    style: TextStyle(color: NunuColors.textSecondary),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      hintText: 'XXXXXX',
                      hintStyle: const TextStyle(
                        color: NunuColors.textSecondary,
                      ),
                      filled: true,
                      fillColor: NunuColors.backgroundPaper,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('invalid or expired code'),
                            backgroundColor: NunuColors.errorMain,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'redeem',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
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

  Widget _buildAdventuresScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'adventures',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: _appColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.explore,
                        color: NunuColors.primaryMain,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'adventure mode',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'coming soon!',
                      style: TextStyle(
                        color: NunuColors.primaryMain,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'explore new worlds, complete quests, and unlock legendary items in our upcoming adventure mode.',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCenterScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'gift center',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildGiftCard(
                  'daily login bonus',
                  'claim your daily reward!',
                  Icons.calendar_today,
                  true,
                ),
                _buildGiftCard(
                  'weekly chest',
                  'opens in 3 days',
                  Icons.inventory_2,
                  false,
                ),
                _buildGiftCard(
                  'friend referral',
                  'invite 3 friends',
                  Icons.group_add,
                  false,
                ),
                _buildGiftCard(
                  'achievement reward',
                  'complete 5 levels',
                  Icons.emoji_events,
                  false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGiftCard(
    String title,
    String subtitle,
    IconData icon,
    bool available,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(16),
        border: available
            ? Border.all(color: NunuColors.successMain, width: 2)
            : null,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: available
                  ? NunuColors.successMain.withOpacity(0.2)
                  : _appColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: available ? NunuColors.successMain : _appColor,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (available)
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: NunuColors.successMain,
              ),
              child: const Text('claim', style: TextStyle(color: Colors.white)),
            )
          else
            const Icon(Icons.lock, color: NunuColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildRewardCenterScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'reward center',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          // Points banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_appColor, _appColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 48),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'your points',
                      style: TextStyle(color: Colors.white70),
                    ),
                    Text(
                      '1,250',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text(
                  'redeem rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildRewardItem('extra life', 500, Icons.favorite),
                _buildRewardItem('2x points boost', 750, Icons.speed),
                _buildRewardItem('mystery box', 1000, Icons.inventory_2),
                _buildRewardItem('exclusive theme', 2000, Icons.palette),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem(String title, int points, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _appColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _appColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: const TextStyle(color: Colors.white)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _appColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.stars, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  '$points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectLogoutScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'account',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Current account card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: _appColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'guest player',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'not connected',
                              style: TextStyle(color: NunuColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'connect account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildConnectOption(
                    Icons.g_mobiledata,
                    'google play games',
                    const Color(0xFF4CAF50),
                  ),
                  _buildConnectOption(Icons.apple, 'game center', Colors.white),
                  _buildConnectOption(
                    Icons.facebook,
                    'facebook',
                    const Color(0xFF1877F2),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'logout',
                      style: TextStyle(color: NunuColors.errorMain),
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

  Widget _buildConnectOption(IconData icon, String name, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(name, style: const TextStyle(color: Colors.white)),
        trailing: OutlinedButton(
          onPressed: () {},
          style: OutlinedButton.styleFrom(side: BorderSide(color: _appColor)),
          child: const Text(
            'connect',
            style: TextStyle(color: NunuColors.primaryMain),
          ),
        ),
        tileColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSupportScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'support',
            onBack: _goBackToMainMenu,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'how can we help?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildFaqItem(
                  'how do i merge items?',
                  'Drag items of the same tier together to create a higher tier item.',
                ),
                _buildFaqItem(
                  'why is my progress not saving?',
                  'Make sure you have a stable internet connection. Progress saves automatically.',
                ),
                _buildFaqItem(
                  'how do i earn more points?',
                  'Complete levels, claim daily rewards, and participate in events.',
                ),
                _buildFaqItem(
                  'can i play offline?',
                  'Yes! Progress will sync when you reconnect.',
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'still need help?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'contact our support team',
                        style: TextStyle(color: NunuColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {},
                          icon: const Icon(
                            Icons.email,
                            color: NunuColors.primaryMain,
                          ),
                          label: const Text(
                            'email support',
                            style: TextStyle(color: NunuColors.primaryMain),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: NunuColors.primaryMain,
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
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

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(color: Colors.white, fontSize: 14),
        ),
        iconColor: NunuColors.textSecondary,
        collapsedIconColor: NunuColors.textSecondary,
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Text(
            answer,
            style: const TextStyle(
              color: NunuColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    IconData icon,
    String title,
    Color? accentColor,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: (accentColor ?? NunuColors.textSecondary).withOpacity(0.2),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: accentColor ?? NunuColors.textSecondary),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: accentColor ?? Colors.white,
          fontWeight: accentColor != null ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: NunuColors.textSecondary,
      ),
      onTap: onTap,
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _appColor.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'privacy policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  megaMergePrivacy,
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _appColor.withOpacity(0.2),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'terms of service',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Content
            SizedBox(
              height: 400,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  megaMergeTos,
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardRules() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'reward rules',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildRuleItem('1.', 'Complete levels to earn merge points.'),
              _buildRuleItem(
                '2.',
                'Daily login bonuses refresh every 24 hours.',
              ),
              _buildRuleItem('3.', 'Rewards expire 30 days after earning.'),
              _buildRuleItem('4.', 'Maximum 10,000 points can be accumulated.'),
              _buildRuleItem(
                '5.',
                'Points cannot be transferred or exchanged.',
              ),
              _buildRuleItem('6.', 'Rewards are subject to availability.'),
              _buildRuleItem(
                '7.',
                'MergeCorp reserves the right to modify rules.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'close',
              style: TextStyle(color: NunuColors.primaryMain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: const TextStyle(
              color: NunuColors.primaryMain,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showResponsibleGaming() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'responsible gaming',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'At MergeCorp, we believe gaming should be fun and safe.',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'tips for healthy gaming:',
                style: TextStyle(
                  color: NunuColors.primaryMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '• Set time limits for your gaming sessions',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
              ),
              Text(
                '• Take regular breaks every 30-60 minutes',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
              ),
              Text(
                '• Never spend more than you can afford',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
              ),
              Text(
                '• Gaming should not interfere with daily life',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
              ),
              Text(
                '• Seek help if gaming becomes problematic',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
              ),
              SizedBox(height: 16),
              Text(
                'need help?',
                style: TextStyle(
                  color: NunuColors.primaryMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Contact our support team or visit responsible gaming resources at helpline.org',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'close',
              style: TextStyle(color: NunuColors.primaryMain),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(
                    Icons.close,
                    color: NunuColors.textSecondary,
                  ),
                ),
              ),
              // Logo placeholder
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [NunuColors.primaryMain, NunuColors.secondaryMain],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'N',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Mega Merge',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'developed by nunu.ai',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 8),
              const Text(
                'version 2.1.0',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 24),
              // Buttons row
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showPrivacyPolicy();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NunuColors.primaryMain),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'privacy policy',
                        style: TextStyle(
                          color: NunuColors.primaryMain,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showTermsOfService();
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: NunuColors.primaryMain),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'terms of service',
                        style: TextStyle(
                          color: NunuColors.primaryMain,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Footer links
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showRewardRules();
                    },
                    child: const Text(
                      'reward rules',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      _showResponsibleGaming();
                    },
                    child: const Text(
                      'responsible gaming',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 11,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  Navigator.of(context).pop();
                  _showDeleteAccountConfirmation();
                },
                child: const Text(
                  'delete my account',
                  style: TextStyle(
                    color: NunuColors.errorMain,
                    fontSize: 11,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteAccountConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        title: const Text(
          'delete all data?',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'this will permanently delete:',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              '• your game progress',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
            const Text(
              '• your achievements',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
            const Text(
              '• your settings',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
            const SizedBox(height: 12),
            const Text(
              'this action cannot be undone!',
              style: TextStyle(
                color: NunuColors.errorMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
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
              setState(() {
                _showMenu = false;
                _menuSubScreen = MenuSubScreen.main;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('all data has been deleted'),
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

  Widget _buildUpdateRequired() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Mega Merge',
            onBack: widget.onBack,
            backgroundColor: _appColor.withOpacity(0.3),
          ),
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
                        color: _appColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(
                        Icons.system_update,
                        color: _appColor,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'update required',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'a new version of mega merge is available. please update from the play store to continue.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to Play Store with mega_merge app pre-selected
                        if (widget.onNavigateToPlayStore != null) {
                          widget.onNavigateToPlayStore!('mega_merge');
                        } else {
                          widget.onBack();
                        }
                      },
                      icon: const Icon(Icons.storefront, color: Colors.white),
                      label: const Text(
                        'go to play store',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGateScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Stack(
        children: [
          // Background app preview (blurred)
          Opacity(
            opacity: 0.3,
            child: _MegaMergeGame(
              onBack: () {},
              onComplete: null,
              gameState: widget.gameState,
              onGameStateChanged: (_) {},
            ),
          ),
          // Age gate dialog
          Center(
            child: AgeGateDialog(
              appName: 'Mega Merge',
              requiredAge: 18,
              onConfirm: () {
                widget.onAgeVerified(true);
                setState(() => _state = MegaMergeState.playing);
              },
              onCancel: widget.onBack,
            ),
          ),
        ],
      ),
    );
  }
}

/// Mega Merge game with level system
class _MegaMergeGame extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onComplete;
  final VoidCallback? onOpenMenu;
  final MegaMergeGameState gameState;
  final Function(MegaMergeGameState) onGameStateChanged;

  const _MegaMergeGame({
    Key? key,
    required this.onBack,
    this.onComplete,
    this.onOpenMenu,
    required this.gameState,
    required this.onGameStateChanged,
  }) : super(key: key);

  @override
  State<_MegaMergeGame> createState() => _MegaMergeGameState();
}

class _MegaMergeGameState extends State<_MegaMergeGame> {
  static const int _cols = 5;
  static const int _rows = 5;
  static const int _totalCells = _cols * _rows;
  static const int _maxTier = 6;
  static const Color _appColor = Color(0xFF9C27B0);

  late List<_MergeItem?> _gridItems;
  int _generatorIndex = 12; // Center
  bool _levelComplete = false;

  // Level = tier required (Level 1 needs tier 2, Level 2 needs tier 3, etc.)
  int get _targetTier => widget.gameState.currentLevel + 1;
  int get _currentLevel => widget.gameState.currentLevel;

  @override
  void initState() {
    super.initState();
    _initializeGrid();
  }

  void _initializeGrid() {
    _gridItems = List<_MergeItem?>.filled(_totalCells, null);
    _gridItems[_generatorIndex] = _MergeItem(
      id: 'gen',
      tier: 0,
      isGenerator: true,
    );
    _levelComplete = false;
  }

  void _spawnItem() {
    final emptyIndices = <int>[];
    for (int i = 0; i < _totalCells; i++) {
      if (_gridItems[i] == null) {
        emptyIndices.add(i);
      }
    }

    if (emptyIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('no space!'),
          duration: Duration(milliseconds: 500),
          backgroundColor: NunuColors.errorMain,
        ),
      );
      return;
    }

    final targetIndex = emptyIndices[Random().nextInt(emptyIndices.length)];
    setState(() {
      _gridItems[targetIndex] = _MergeItem(
        id: DateTime.now().toIso8601String(),
        tier: 1,
        isGenerator: false,
      );
    });
    HapticFeedback.lightImpact();
  }

  void _onItemMove(int fromIndex, int toIndex) {
    if (fromIndex == toIndex) return;

    final source = _gridItems[fromIndex];
    if (source == null || source.isGenerator) return;

    final target = _gridItems[toIndex];

    setState(() {
      if (target == null) {
        _gridItems[toIndex] = source;
        _gridItems[fromIndex] = null;
      } else if (!target.isGenerator &&
          source.tier == target.tier &&
          source.tier < _maxTier) {
        // Merge!
        final newTier = source.tier + 1;
        _gridItems[toIndex] = _MergeItem(
          id: DateTime.now().toIso8601String(),
          tier: newTier,
          isGenerator: false,
        );
        _gridItems[fromIndex] = null;
        HapticFeedback.mediumImpact();

        // Update game state
        widget.onGameStateChanged(
          widget.gameState.copyWith(
            highestTier: newTier > widget.gameState.highestTier
                ? newTier
                : null,
            totalMerges: widget.gameState.totalMerges + 1,
          ),
        );

        // Check if level complete
        if (newTier >= _targetTier && !_levelComplete) {
          _levelComplete = true;
          _showLevelCompleteDialog();
        }
      } else if (!target.isGenerator) {
        // Swap
        _gridItems[toIndex] = source;
        _gridItems[fromIndex] = target;
      }
    });
  }

  void _showLevelCompleteDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
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
            Text(
              'level $_currentLevel complete!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'you created a tier $_targetTier item!',
              style: const TextStyle(color: NunuColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onComplete?.call();
                  _initializeGrid();
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NunuColors.successMain,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'next level',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        return Colors.purple;
      default:
        return Colors.white;
    }
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
        return Icons.smart_toy;
      case 6:
        return Icons.auto_awesome;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'level $_currentLevel',
            onBack: widget.onBack,
            backgroundColor: _appColor.withOpacity(0.3),
            actions: widget.onOpenMenu != null
                ? [
                    IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: widget.onOpenMenu,
                    ),
                  ]
                : null,
          ),
          // Goal indicator
          Container(
            padding: const EdgeInsets.all(12),
            color: NunuColors.backgroundPaper.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'goal: create a ',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getColorForTier(_targetTier).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getColorForTier(_targetTier)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getIconForTier(_targetTier),
                        color: _getColorForTier(_targetTier),
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'tier $_targetTier',
                        style: TextStyle(
                          color: _getColorForTier(_targetTier),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _cols,
                  childAspectRatio: 1.0,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                ),
                itemCount: _totalCells,
                itemBuilder: (context, index) => _buildCell(index),
              ),
            ),
          ),
          // Stats bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: NunuColors.backgroundPaper.withOpacity(0.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  Icons.merge_type,
                  'merges',
                  '${widget.gameState.totalMerges}',
                ),
                _buildStatChip(
                  Icons.star,
                  'highest',
                  'tier ${widget.gameState.highestTier}',
                ),
              ],
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
              'tap generator to spawn items. drag matching items to merge!',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: _appColor, size: 16),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(color: NunuColors.textSecondary, fontSize: 12),
        ),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCell(int index) {
    final item = _gridItems[index];

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) {
        final fromIndex = details.data;
        if (fromIndex == index) return false;
        final source = _gridItems[fromIndex];
        if (source == null || source.isGenerator) return false;
        return true;
      },
      onAcceptWithDetails: (details) => _onItemMove(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;

        if (item == null) {
          return Container(
            decoration: BoxDecoration(
              color: isHighlighted
                  ? NunuColors.primaryMain.withOpacity(0.3)
                  : NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(8),
            ),
          );
        }

        if (item.isGenerator) {
          return GestureDetector(
            onTap: _spawnItem,
            child: Container(
              decoration: BoxDecoration(
                color: NunuColors.secondaryMain,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: Colors.white,
                size: 32,
              ),
            ),
          );
        }

        final color = _getColorForTier(item.tier);
        return Draggable<int>(
          data: index,
          feedback: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: NunuColors.backgroundDefault,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(_getIconForTier(item.tier), color: color, size: 28),
          ),
          childWhenDragging: Container(
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: isHighlighted
                  ? NunuColors.primaryMain.withOpacity(0.3)
                  : NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color, width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(_getIconForTier(item.tier), color: color, size: 24),
                const SizedBox(height: 2),
                Text(
                  '${item.tier}',
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MergeItem {
  final String id;
  final int tier;
  final bool isGenerator;

  const _MergeItem({
    required this.id,
    required this.tier,
    required this.isGenerator,
  });
}
