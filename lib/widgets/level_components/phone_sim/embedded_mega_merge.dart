import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';
import 'game_onboarding.dart';
import 'phone_homescreen.dart';

/// Terms of Service content for Mega Merge
/// Note: Contains age requirement AND will show age gate popup
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
enum MegaMergeState {
  notUpdated,
  loading,
  tos,
  ageGate,
  playing,
}

/// Embedded Mega Merge game with full onboarding including age gate
class EmbeddedMegaMergeApp extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onGameComplete;
  final bool isUpdated;
  final bool tosAccepted;
  final bool ageVerified;
  final Function(bool) onTosAccepted;
  final Function(bool) onAgeVerified;

  const EmbeddedMegaMergeApp({
    Key? key,
    required this.onBack,
    this.onGameComplete,
    required this.isUpdated,
    required this.tosAccepted,
    required this.ageVerified,
    required this.onTosAccepted,
    required this.onAgeVerified,
  }) : super(key: key);

  @override
  State<EmbeddedMegaMergeApp> createState() => _EmbeddedMegaMergeAppState();
}

class _EmbeddedMegaMergeAppState extends State<EmbeddedMegaMergeApp> {
  late MegaMergeState _state;

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
          appColor: const Color(0xFF9C27B0),
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
        return _MegaMergeGame(
          onBack: widget.onBack,
          onComplete: widget.onGameComplete,
        );
    }
  }

  Widget _buildUpdateRequired() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Mega Merge',
            onBack: widget.onBack,
            backgroundColor: const Color(0xFF9C27B0).withOpacity(0.3),
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
                        color: const Color(0xFF9C27B0).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.system_update,
                        color: Color(0xFF9C27B0),
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
                      onPressed: widget.onBack,
                      icon: const Icon(Icons.storefront, color: Colors.white),
                      label: const Text(
                        'go to play store',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF9C27B0),
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
            child: _MegaMergeGame(onBack: () {}, onComplete: null),
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

/// Simplified Mega Merge game
class _MegaMergeGame extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onComplete;

  const _MegaMergeGame({
    Key? key,
    required this.onBack,
    this.onComplete,
  }) : super(key: key);

  @override
  State<_MegaMergeGame> createState() => _MegaMergeGameState();
}

class _MegaMergeGameState extends State<_MegaMergeGame> {
  static const int _cols = 5;
  static const int _rows = 5;
  static const int _totalCells = _cols * _rows;
  static const int _maxTier = 5;

  late List<_MergeItem?> _gridItems;
  int _generatorIndex = 12; // Center
  int _targetTier = 4; // Goal: create a tier 4 item
  bool _targetReached = false;

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

        if (newTier >= _targetTier && !_targetReached) {
          _targetReached = true;
          widget.onComplete?.call();
        }
      } else if (!target.isGenerator) {
        // Swap
        _gridItems[toIndex] = source;
        _gridItems[fromIndex] = target;
      }
    });
  }

  Color _getColorForTier(int tier) {
    switch (tier) {
      case 1: return Colors.amber;
      case 2: return Colors.orange;
      case 3: return Colors.teal;
      case 4: return Colors.green;
      case 5: return Colors.blue;
      default: return Colors.white;
    }
  }

  IconData _getIconForTier(int tier) {
    switch (tier) {
      case 1: return Icons.flash_on;
      case 2: return Icons.settings;
      case 3: return Icons.memory;
      case 4: return Icons.developer_board;
      case 5: return Icons.smart_toy;
      default: return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Mega Merge',
            onBack: widget.onBack,
            backgroundColor: const Color(0xFF9C27B0).withOpacity(0.3),
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
                  style: TextStyle(color: NunuColors.textSecondary, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getColorForTier(_targetTier).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _getColorForTier(_targetTier)),
                  ),
                  child: Icon(
                    _getIconForTier(_targetTier),
                    color: _getColorForTier(_targetTier),
                    size: 20,
                  ),
                ),
                if (_targetReached)
                  const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.check_circle, color: NunuColors.successMain),
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
              child: const Icon(Icons.inventory_2, color: Colors.white, size: 32),
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
            child: Icon(_getIconForTier(item.tier), color: color, size: 28),
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

