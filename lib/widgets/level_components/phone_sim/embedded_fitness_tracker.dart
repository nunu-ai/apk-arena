import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'phone_homescreen.dart';
import '../../levels/level_phone_simulator.dart';

/// Terms of Service content for FitTrack Pro
const String fitnessTrackerTos = '''
FITTRACK PRO - TERMS OF SERVICE

Last Updated: December 2024

IMPORTANT: PLEASE READ THESE TERMS CAREFULLY BEFORE USING FITTRACK PRO.

1. ACCEPTANCE OF TERMS
By creating an account and using FitTrack Pro ("the App"), you acknowledge that you have read, understood, and agree to be bound by these Terms of Service. If you do not agree, do not create an account.

2. ACCOUNT REGISTRATION
2.1 You must provide accurate and complete information during registration, including your name and email address.
2.2 You are responsible for maintaining the confidentiality of your account credentials.
2.3 You must be at least 16 years old to create an account.

3. LICENSE GRANT
FitLife Technologies grants you a limited, non-exclusive license to use the App for personal health and fitness tracking purposes only.

4. DATA COLLECTION AND USE
4.1 By using this App, you consent to the collection and processing of your personal data as described in our Privacy Policy.
4.2 We collect your name, email, fitness data, device information, and usage statistics.
4.3 Your data may be used for app functionality, analytics, and marketing purposes.

5. HEALTH DISCLAIMER
This App is for informational purposes only and is not medical advice. Consult a healthcare professional before starting any fitness program. FitLife Technologies is not liable for any health-related consequences.

6. DATA SYNCHRONIZATION
Your fitness data is automatically synchronized with our cloud servers. This ensures you never lose your progress, even if you reinstall the app or switch devices.

7. DEVICE BINDING
Your account may be linked to your device identifier for security and data restoration purposes.

8. PROHIBITED CONDUCT
You agree not to:
- Provide false registration information
- Share your account with others
- Attempt to circumvent security measures
- Use the App for commercial purposes

9. TERMINATION
We reserve the right to terminate your account for violation of these Terms.

10. DISCLAIMER
THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND.

11. LIMITATION OF LIABILITY
FitLife Technologies shall not be liable for any indirect, incidental, or consequential damages.

12. CONTACT
support@fitlifetechnologies.com
''';

const String fitnessTrackerPrivacy = '''
FITTRACK PRO - PRIVACY POLICY

Last Updated: December 2024

IMPORTANT: This Privacy Policy explains how we collect, use, and protect your personal information.

1. INFORMATION WE COLLECT

1.1 Account Information
- Full name (required for registration)
- Email address (required for registration)
- Profile preferences

1.2 Health & Fitness Data
- Step counts and activity data
- Workout logs and exercise history
- Health goals and achievements
- Body measurements (if provided)

1.3 Device Information
- Device identifier (for account binding)
- Operating system version
- Hardware specifications
- IP address

1.4 Usage Data
- App usage patterns and frequency
- Feature interactions
- Session duration
- Crash reports

2. HOW WE USE YOUR INFORMATION

We use your information to:
- Create and manage your account
- Provide personalized fitness tracking
- Send important updates and notifications
- Improve our services through analytics
- Communicate marketing offers (with consent)
- Comply with legal obligations

3. DATA SHARING

We may share your data with:
- Cloud service providers (for data storage)
- Analytics partners (anonymized)
- Marketing partners (with consent)
- Legal authorities (when required)

4. DATA RETENTION

We retain your data for as long as your account is active, plus a reasonable period thereafter for legal and business purposes.

5. DATA SECURITY

We implement industry-standard security measures including:
- Encryption in transit and at rest
- Regular security audits
- Access controls

6. YOUR RIGHTS

You have the right to:
- Access your personal data
- Request correction of inaccurate data
- Object to certain processing
- Data portability

Note: Due to our data synchronization system, complete data deletion may not be available for all data types.

7. CHILDREN'S PRIVACY

This App is not intended for users under 16 years of age.

8. CONTACT US

Privacy inquiries: privacy@fitlifetechnologies.com
Data Protection: dpo@fitlifetechnologies.com
''';

/// Onboarding state for FitTrack Pro
enum FitnessTrackerState {
  welcome,
  tosScreen,
  privacyScreen,
  accountSetup,
  main,
}

/// Embedded FitTrack Pro fitness app with multi-step onboarding
class EmbeddedFitnessTrackerApp extends StatefulWidget {
  final VoidCallback onBack;
  final bool tosAccepted;
  final Function(bool) onTosAccepted;
  final FitnessTrackerData data;
  final Function(FitnessTrackerData) onDataChanged;

  /// Callback to open URLs in browser
  final Function(String url)? onOpenBrowser;

  const EmbeddedFitnessTrackerApp({
    Key? key,
    required this.onBack,
    required this.tosAccepted,
    required this.onTosAccepted,
    required this.data,
    required this.onDataChanged,
    this.onOpenBrowser,
  }) : super(key: key);

  @override
  State<EmbeddedFitnessTrackerApp> createState() =>
      _EmbeddedFitnessTrackerAppState();
}

class _EmbeddedFitnessTrackerAppState extends State<EmbeddedFitnessTrackerApp> {
  late FitnessTrackerState _state;
  int _currentTab = 0;
  bool _showProfile = false;

  // Onboarding form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  String? _nameError;
  String? _emailError;
  bool _tosChecked = false;
  bool _privacyChecked = false;

  static const Color _appColor = Color(0xFF00C853);

  @override
  void initState() {
    super.initState();
    // If onboarding is complete, go straight to main
    if (widget.data.onboardingComplete) {
      _state = FitnessTrackerState.main;
    } else {
      _state = FitnessTrackerState.welcome;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _validateAndProceed() {
    setState(() {
      _nameError = null;
      _emailError = null;

      final name = _nameController.text.trim();
      final email = _emailController.text.trim();

      if (name.isEmpty) {
        _nameError = 'please enter your name';
        return;
      }
      if (name.length < 2) {
        _nameError = 'name must be at least 2 characters';
        return;
      }
      if (email.isEmpty) {
        _emailError = 'please enter your email';
        return;
      }
      if (!_isValidEmail(email)) {
        _emailError = 'please enter a valid email address';
        return;
      }

      // Success - update data and complete onboarding
      widget.onDataChanged(widget.data.copyWith(
        userName: name,
        userEmail: email,
        onboardingComplete: true,
      ));
      widget.onTosAccepted(true);
      _state = FitnessTrackerState.main;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_state) {
      case FitnessTrackerState.welcome:
        return _buildWelcomeScreen();
      case FitnessTrackerState.tosScreen:
        return _buildTosScreen();
      case FitnessTrackerState.privacyScreen:
        return _buildPrivacyScreen();
      case FitnessTrackerState.accountSetup:
        return _buildAccountSetupScreen();
      case FitnessTrackerState.main:
        if (_showProfile) {
          return _buildProfileScreen();
        }
        return _buildMainScreen();
    }
  }

  Widget _buildWelcomeScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            // Close button
            Align(
              alignment: Alignment.topLeft,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: widget.onBack,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_appColor, _appColor.withOpacity(0.7)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _appColor.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.fitness_center,
                        color: Colors.white,
                        size: 60,
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'welcome to',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'FitTrack Pro',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'your personal fitness companion',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 48),
                    // Features list
                    _buildFeatureItem(Icons.directions_run, 'track your daily steps'),
                    _buildFeatureItem(Icons.fitness_center, 'log your workouts'),
                    _buildFeatureItem(Icons.emoji_events, 'earn achievements'),
                    _buildFeatureItem(Icons.cloud_sync, 'sync across devices'),
                  ],
                ),
              ),
            ),
            // Get Started button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => setState(() => _state = FitnessTrackerState.tosScreen),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'get started',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: _appColor, size: 24),
          const SizedBox(width: 16),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildTosScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _state = FitnessTrackerState.welcome),
                  ),
                  const Expanded(
                    child: Text(
                      'terms of service',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildProgressDot(true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressDot(false)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressDot(false)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legal document info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _appColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: _appColor,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'terms of service',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'please review and accept our terms of service to continue using FitTrack Pro.',
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Link to full ToS
                    GestureDetector(
                      onTap: () {
                        widget.onOpenBrowser?.call('fittrack-pro.com/terms-of-service');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: NunuColors.backgroundPaper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _appColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, color: _appColor, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'read full terms of service',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'fittrack-pro.com/terms-of-service',
                                    style: TextStyle(
                                      color: NunuColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: NunuColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'key points:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• You must be at least 16 years old\n'
                            '• One account per person\n'
                            '• Keep your credentials secure\n'
                            '• This is not medical advice\n'
                            '• We may update these terms',
                            style: TextStyle(
                              color: NunuColors.textSecondary,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Checkbox and button
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _tosChecked = !_tosChecked),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _tosChecked ? _appColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _tosChecked ? _appColor : NunuColors.textSecondary,
                            ),
                          ),
                          child: _tosChecked
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'i have read and agree to the terms of service',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _tosChecked
                          ? () => setState(() => _state = FitnessTrackerState.privacyScreen)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appColor,
                        disabledBackgroundColor: NunuColors.backgroundPaper,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'continue',
                        style: TextStyle(
                          color: _tosChecked ? Colors.white : NunuColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildPrivacyScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _state = FitnessTrackerState.tosScreen),
                  ),
                  const Expanded(
                    child: Text(
                      'privacy policy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildProgressDot(true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressDot(true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressDot(false)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Legal document info
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    // Icon
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: _appColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.privacy_tip_outlined,
                          color: _appColor,
                          size: 40,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Center(
                      child: Text(
                        'privacy policy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'please review how we collect, use, and protect your personal information.',
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Link to full Privacy Policy
                    GestureDetector(
                      onTap: () {
                        widget.onOpenBrowser?.call('fittrack-pro.com/privacy-policy');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: NunuColors.backgroundPaper,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _appColor.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.open_in_new, color: _appColor, size: 20),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'read full privacy policy',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    'fittrack-pro.com/privacy-policy',
                                    style: TextStyle(
                                      color: NunuColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              color: NunuColors.textSecondary,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Summary box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'what we collect:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: 12),
                          Text(
                            '• Personal info (name, email)\n'
                            '• Fitness & health data\n'
                            '• Device information\n'
                            '• Usage analytics\n'
                            '• Third-party integrations',
                            style: TextStyle(
                              color: NunuColors.textSecondary,
                              fontSize: 13,
                              height: 1.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Checkbox and button
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _privacyChecked = !_privacyChecked),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _privacyChecked ? _appColor : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: _privacyChecked ? _appColor : NunuColors.textSecondary,
                            ),
                          ),
                          child: _privacyChecked
                              ? const Icon(Icons.check, color: Colors.white, size: 18)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'i have read and agree to the privacy policy',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _privacyChecked
                          ? () => setState(() => _state = FitnessTrackerState.accountSetup)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _appColor,
                        disabledBackgroundColor: NunuColors.backgroundPaper,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'continue',
                        style: TextStyle(
                          color: _privacyChecked ? Colors.white : NunuColors.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildProgressDot(bool active) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active ? _appColor : NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildAccountSetupScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => setState(() => _state = FitnessTrackerState.privacyScreen),
                  ),
                  const Expanded(
                    child: Text(
                      'create account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(child: _buildProgressDot(true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressDot(true)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildProgressDot(true)),
                ],
              ),
            ),
            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    const Text(
                      'almost there!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'enter your details to create your account',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Name field
                    const Text(
                      'full name',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'enter your name',
                        hintStyle: const TextStyle(color: NunuColors.textSecondary),
                        prefixIcon: const Icon(Icons.person_outline, color: NunuColors.textSecondary),
                        filled: true,
                        fillColor: NunuColors.backgroundPaper,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _nameError,
                        errorStyle: const TextStyle(color: NunuColors.errorMain),
                      ),
                      textCapitalization: TextCapitalization.words,
                      onChanged: (_) => setState(() => _nameError = null),
                    ),
                    const SizedBox(height: 24),
                    // Email field
                    const Text(
                      'email address',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'enter your email',
                        hintStyle: const TextStyle(color: NunuColors.textSecondary),
                        prefixIcon: const Icon(Icons.email_outlined, color: NunuColors.textSecondary),
                        filled: true,
                        fillColor: NunuColors.backgroundPaper,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        errorText: _emailError,
                        errorStyle: const TextStyle(color: NunuColors.errorMain),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() => _emailError = null),
                    ),
                    const SizedBox(height: 32),
                    // Info box
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _appColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _appColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: _appColor),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'your information is securely stored and will be used to personalize your fitness experience.',
                              style: TextStyle(
                                color: NunuColors.textSecondary,
                                fontSize: 12,
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
            // Create account button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _validateAndProceed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _appColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'create account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'FitTrack Pro',
            onBack: widget.onBack,
            backgroundColor: _appColor.withOpacity(0.3),
            actions: [
              IconButton(
                icon: const Icon(Icons.person, color: Colors.white),
                onPressed: () => setState(() => _showProfile = true),
              ),
            ],
          ),
          Expanded(child: _buildTabContent()),
          _buildBottomNav(),
        ],
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_currentTab) {
      case 0:
        return _buildDashboard();
      case 1:
        return _buildWorkouts();
      case 2:
        return _buildAchievements();
      default:
        return _buildDashboard();
    }
  }

  Widget _buildDashboard() {
    final userName = widget.data.userName ?? 'User';
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome message
          Text(
            'welcome, $userName!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Steps card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_appColor, _appColor.withOpacity(0.7)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'today\'s steps',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${widget.data.totalSteps}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'goal: 10,000',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      '${((widget.data.totalSteps / 10000) * 100).clamp(0, 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'workouts',
                  '${widget.data.totalWorkouts}',
                  Icons.fitness_center,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'streak',
                  '${widget.data.streakDays} days',
                  Icons.local_fire_department,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Text(
            'quick actions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuickAction('start a workout', Icons.play_arrow),
          _buildQuickAction('log steps manually', Icons.add),
          _buildQuickAction('view progress', Icons.trending_up),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: _appColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: NunuColors.textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _appColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: _appColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: Colors.white)),
          ),
          const Icon(Icons.chevron_right, color: NunuColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildWorkouts() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'workout plans',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildWorkoutPlan('Full Body Burn', '45 min', 'intermediate', Icons.fitness_center),
        _buildWorkoutPlan('Morning HIIT', '20 min', 'beginner', Icons.flash_on),
        _buildWorkoutPlan('Strength Training', '60 min', 'advanced', Icons.sports_gymnastics),
        _buildWorkoutPlan('Cardio Blast', '30 min', 'intermediate', Icons.directions_run),
        _buildWorkoutPlan('Yoga Flow', '25 min', 'beginner', Icons.self_improvement),
      ],
    );
  }

  Widget _buildWorkoutPlan(String title, String duration, String level, IconData icon) {
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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _appColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: _appColor, size: 28),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      duration,
                      style: const TextStyle(color: NunuColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _appColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        level,
                        style: TextStyle(color: _appColor, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: _appColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('start', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievements() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'your achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...widget.data.achievements.map((a) => _buildAchievementItem(a, true)),
        _buildAchievementItem('First Steps', false),
        _buildAchievementItem('Week Warrior', false),
        _buildAchievementItem('Marathon Ready', false),
        _buildAchievementItem('Iron Will', false),
      ],
    );
  }

  Widget _buildAchievementItem(String title, bool unlocked) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: unlocked ? Border.all(color: _appColor, width: 2) : null,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: unlocked ? _appColor : NunuColors.backgroundDefault,
              shape: BoxShape.circle,
            ),
            child: Icon(
              unlocked ? Icons.emoji_events : Icons.lock,
              color: unlocked ? Colors.white : NunuColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: unlocked ? Colors.white : NunuColors.textSecondary,
                fontWeight: unlocked ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
          if (unlocked) Icon(Icons.check_circle, color: _appColor),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, Icons.dashboard, 'dashboard'),
          _buildNavItem(1, Icons.fitness_center, 'workouts'),
          _buildNavItem(2, Icons.emoji_events, 'achievements'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? _appColor : NunuColors.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _appColor : NunuColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileScreen() {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'profile',
            onBack: () => setState(() => _showProfile = false),
            backgroundColor: _appColor.withOpacity(0.3),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Profile header
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
                          child: const Icon(Icons.person, color: Colors.white, size: 40),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.data.userName ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          widget.data.userEmail ?? '',
                          style: const TextStyle(color: NunuColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'member since dec 2024',
                          style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
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
                          'lifetime stats',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow('Total Steps', '${widget.data.totalSteps}'),
                        _buildStatRow('Workouts Completed', '${widget.data.totalWorkouts}'),
                        _buildStatRow('Current Streak', '${widget.data.streakDays} days'),
                        _buildStatRow('Achievements', '${widget.data.achievements.length}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Settings section
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
                        _buildSettingsItem(Icons.notifications, 'notifications', () {}),
                        _buildSettingsItem(Icons.share, 'share progress', () {}),
                        _buildSettingsItem(Icons.help, 'help & support', () {}),
                        _buildSettingsItem(Icons.info, 'about', () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Cloud sync info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _appColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _appColor.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done, color: _appColor),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'data synced to cloud',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                'your progress is automatically saved and will be restored if you reinstall the app.',
                                style: TextStyle(
                                  color: NunuColors.textSecondary,
                                  fontSize: 12,
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
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: NunuColors.textSecondary),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      trailing: const Icon(Icons.chevron_right, color: NunuColors.textSecondary),
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
    );
  }
}
