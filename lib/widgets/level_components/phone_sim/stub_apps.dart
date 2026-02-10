import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'phone_homescreen.dart';
import '../../levels/level_phone_simulator.dart' show BrowserState, BrowserTab;

/// Base stub app widget
class StubApp extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onBack;
  final Widget? content;

  const StubApp({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onBack,
    this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: title,
            onBack: onBack,
            backgroundColor: color.withOpacity(0.3),
          ),
          Expanded(child: content ?? _buildDefaultContent()),
        ],
      ),
    );
  }

  Widget _buildDefaultContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'this app is not available in demo mode',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Settings app stub
class SettingsStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const SettingsStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(title: 'Settings', onBack: onBack),
          Expanded(
            child: ListView(
              children: [
                _buildSettingsGroup('network & internet', [
                  _buildSettingItem(Icons.wifi, 'Wi-Fi', 'Connected'),
                  _buildSettingItem(Icons.bluetooth, 'Bluetooth', 'On'),
                  _buildSettingItem(Icons.sim_card, 'SIM cards', ''),
                ]),
                _buildSettingsGroup('device', [
                  _buildSettingItem(Icons.battery_full, 'Battery', '87%'),
                  _buildSettingItem(Icons.storage, 'Storage', '45 GB used'),
                  _buildSettingItem(Icons.volume_up, 'Sound & vibration', ''),
                  _buildSettingItem(Icons.brightness_6, 'Display', ''),
                ]),
                _buildSettingsGroup('personal', [
                  _buildSettingItem(Icons.security, 'Security', ''),
                  _buildSettingItem(Icons.privacy_tip, 'Privacy', ''),
                  _buildSettingItem(Icons.location_on, 'Location', 'On'),
                ]),
                _buildSettingsGroup('system', [
                  _buildSettingItem(Icons.language, 'Languages', 'English'),
                  _buildSettingItem(Icons.update, 'System update', ''),
                  _buildSettingItem(Icons.info, 'About phone', ''),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsGroup(String title, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              color: NunuColors.primaryMain,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        ...items,
      ],
    );
  }

  Widget _buildSettingItem(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: subtitle.isNotEmpty
          ? Text(
              subtitle,
              style: const TextStyle(color: NunuColors.textSecondary),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: NunuColors.textSecondary,
      ),
    );
  }
}

/// Phone app stub
class PhoneStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const PhoneStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(title: 'Phone', onBack: onBack),
          Expanded(
            child: Column(
              children: [
                // Dialpad display
                Container(
                  padding: const EdgeInsets.all(24),
                  child: const Text(
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                // Dialpad
                Expanded(
                  child: GridView.count(
                    crossAxisCount: 3,
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    children: [
                      for (final digit in [
                        '1',
                        '2',
                        '3',
                        '4',
                        '5',
                        '6',
                        '7',
                        '8',
                        '9',
                        '*',
                        '0',
                        '#',
                      ])
                        _buildDialButton(digit),
                    ],
                  ),
                ),
                // Call button
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(
                      color: NunuColors.successMain,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.call,
                      color: Colors.white,
                      size: 32,
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

  Widget _buildDialButton(String digit) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          digit,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

/// Camera app stub
class CameraStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const CameraStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          // Viewfinder placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  color: Colors.white.withOpacity(0.3),
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  'camera not available',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Top bar with back button
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: onBack,
                  ),
                  const Icon(Icons.flash_off, color: Colors.white),
                  const Icon(Icons.settings, color: Colors.white),
                ],
              ),
            ),
          ),
          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.5),
                          width: 4,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.cameraswitch,
                      color: Colors.white,
                      size: 32,
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
}

/// Clock app stub
class ClockStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const ClockStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(title: 'Clock', onBack: onBack),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w200,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sunday, Dec 21',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          // Bottom tabs
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTab(Icons.alarm, 'alarm', true),
                _buildTab(Icons.access_time, 'clock', false),
                _buildTab(Icons.timer, 'timer', false),
                _buildTab(Icons.hourglass_empty, 'stopwatch', false),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(IconData icon, String label, bool isSelected) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isSelected ? NunuColors.primaryMain : NunuColors.textSecondary,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isSelected
                ? NunuColors.primaryMain
                : NunuColors.textSecondary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Calendar app stub
class CalendarStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const CalendarStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(title: 'Calendar', onBack: onBack),
          // Month header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Icon(Icons.chevron_left, color: Colors.white),
                const Text(
                  'December 2024',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
          // Days of week
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
                  .map(
                    (d) => Text(
                      d,
                      style: const TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 8),
          // Calendar grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: 35,
              itemBuilder: (context, index) {
                final day = index - 0 + 1; // Simplified
                final isToday = day == 21;
                if (day < 1 || day > 31) {
                  return const SizedBox();
                }
                return Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isToday
                        ? NunuColors.primaryMain
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: isToday ? Colors.white : NunuColors.textPrimary,
                        fontSize: 14,
                      ),
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
}

/// Gmail app stub
class GmailStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const GmailStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Gmail',
            onBack: onBack,
            backgroundColor: const Color(0xFFEA4335).withOpacity(0.2),
          ),
          // Search bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.menu, color: NunuColors.textSecondary),
                const SizedBox(width: 16),
                const Text(
                  'Search in mail',
                  style: TextStyle(color: NunuColors.textSecondary),
                ),
                const Spacer(),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: NunuColors.primaryMain,
                  child: const Text('G', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          // Empty inbox
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 64,
                    color: NunuColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'your inbox is empty',
                    style: TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 16,
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
}

/// Messages app stub
class MessagesStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const MessagesStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(title: 'Messages', onBack: onBack),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 64,
                    color: NunuColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'no messages',
                    style: TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 16,
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
}

/// Full-featured browser app with tab management
class BrowserStubApp extends StatefulWidget {
  final VoidCallback onBack;
  final BrowserState browserState;
  final Function(BrowserState) onBrowserStateChanged;

  const BrowserStubApp({
    Key? key,
    required this.onBack,
    required this.browserState,
    required this.onBrowserStateChanged,
  }) : super(key: key);

  @override
  State<BrowserStubApp> createState() => _BrowserStubAppState();
}

class _BrowserStubAppState extends State<BrowserStubApp> {
  // Track expanded sections for legal pages
  final Set<String> _expandedSections = {};

  BrowserState get _state => widget.browserState;
  BrowserTab? get _activeTab => _state.activeTab;

  void _updateState(BrowserState newState) {
    widget.onBrowserStateChanged(newState);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Tab bar
          _buildTabBar(),
          // URL bar
          _buildUrlBar(),
          // Page content
          Expanded(child: _buildPageContent()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: const Color(0xFFE8E8E8),
      child: Column(
        children: [
          // Status area spacer
          const SizedBox(height: 4),
          // Tabs row
          SizedBox(
            height: 36,
            child: Row(
              children: [
                Expanded(
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: _state.tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _state.tabs[index];
                      final isActive = index == _state.activeTabIndex;
                      return _buildTab(tab, index, isActive);
                    },
                  ),
                ),
                // Add tab button
                GestureDetector(
                  onTap: () {
                    _updateState(_state.addTab(''));
                  },
                  child: Container(
                    width: 32,
                    height: 32,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.add,
                      size: 18,
                      color: Colors.black54,
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

  Widget _buildTab(BrowserTab tab, int index, bool isActive) {
    return GestureDetector(
      onTap: () => _updateState(_state.switchToTab(index)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 150, minWidth: 80),
        margin: const EdgeInsets.only(right: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.grey.shade200,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Row(
          children: [
            Icon(
              tab.url.isEmpty ? Icons.home : Icons.public,
              size: 14,
              color: Colors.black54,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                tab.title.isEmpty ? 'New Tab' : tab.title,
                style: TextStyle(
                  color: isActive ? Colors.black87 : Colors.black54,
                  fontSize: 12,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            GestureDetector(
              onTap: () => _updateState(_state.closeTab(index)),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 14, color: Colors.black45),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUrlBar() {
    return Container(
      color: const Color(0xFFF5F5F5),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black54, size: 20),
            onPressed: widget.onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(
                    _activeTab?.url.isNotEmpty == true
                        ? Icons.lock
                        : Icons.search,
                    color: _activeTab?.url.isNotEmpty == true
                        ? Colors.green
                        : Colors.grey,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _activeTab?.url.isNotEmpty == true
                          ? _activeTab!.url
                          : 'Search or type URL',
                      style: TextStyle(
                        color: _activeTab?.url.isNotEmpty == true
                            ? Colors.black87
                            : Colors.grey,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black54, size: 20),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    final url = _activeTab?.url ?? '';

    if (url.isEmpty) {
      return _buildHomePage();
    } else if (url.contains('fittrack-pro.com/terms')) {
      return _buildLegalPage('FitTrack Pro', 'Terms of Service', true);
    } else if (url.contains('fittrack-pro.com/privacy')) {
      return _buildLegalPage('FitTrack Pro', 'Privacy Policy', false);
    } else {
      return _buildGenericPage(url);
    }
  }

  Widget _buildHomePage() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.public, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            const Text(
              'start browsing',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenericPage(String url) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.web_asset_off, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(url, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalPage(String appName, String pageTitle, bool isTerms) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            color: const Color(0xFF1A1A2E),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appName,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  pageTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Last Updated: December 2024',
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          // Legal sections
          if (isTerms)
            ..._buildTermsOfServiceSections()
          else
            ..._buildPrivacyPolicySections(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ==================== LEGAL PAGE CONTENT ====================

  List<Widget> _buildPrivacyPolicySections() {
    return [
      _buildIntroSection(
        'Your privacy matters to us. This Privacy Policy explains how FitLife Technologies ("we", "us", "our") collects, uses, shares, and protects your personal information when you use FitTrack Pro.',
      ),
      _buildExpandableSection(
        'data_collection',
        'Data Collection',
        'We collect various types of information to provide and improve our services.',
        [
          _buildSubSection(
            'personal_info',
            'Personal Information',
            'Information you provide directly to us:',
            '''• Full legal name (required for account creation)
• Email address (required for account verification and communications)
• Date of birth (for age verification and personalized recommendations)
• Profile photograph (optional, stored on our servers)
• Physical characteristics: height, weight, body measurements
• Health conditions and medical history (optional, used for personalized advice)
• Fitness goals and preferences
• Payment information (processed by third-party payment processors)''',
          ),
          _buildSubSection(
            'device_info',
            'Device & Technical Information',
            'Information collected automatically:',
            '''• Unique device identifiers (IMEI, Android ID, Advertising ID)
• Device make, model, and operating system version
• IP address and approximate geographic location
• Mobile network carrier information
• Browser type and version
• Screen resolution and device capabilities
• App version and installation source
• Crash logs and diagnostic data''',
          ),
          _buildSubSection(
            'usage_data',
            'Usage & Activity Data',
            'Information about how you use our services:',
            '''• Step counts, distance traveled, calories burned
• Workout sessions: type, duration, intensity, frequency
• Heart rate data (if connected to compatible devices)
• Sleep patterns and quality metrics
• Water intake and nutrition logging
• App feature usage and interaction patterns
• Session timestamps and frequency
• Content viewed and features accessed
• In-app purchases and transaction history''',
          ),
        ],
      ),
      _buildExpandableSection(
        'data_use',
        'How We Use Your Information',
        'We use collected data for multiple purposes.',
        [
          _buildSubSection(
            'service_provision',
            'Service Provision & Improvement',
            'Core functionality:',
            '''• Creating and managing your account
• Providing personalized fitness tracking and recommendations
• Syncing data across your devices
• Generating progress reports and insights
• Improving our algorithms and features
• Conducting research and analytics
• Developing new products and services''',
          ),
          _buildSubSection(
            'personalization',
            'Personalization & Advertising',
            'Tailoring your experience:',
            '''• Customizing app content and recommendations
• Displaying relevant advertisements
• Measuring advertising effectiveness
• Creating audience segments for marketing
• A/B testing and feature optimization
• Cross-platform advertising attribution''',
          ),
        ],
      ),
      _buildExpandableSection(
        'data_sharing',
        'Data Sharing & Third Parties',
        'We share your information with various third parties.',
        [
          _buildSubSection(
            'service_providers',
            'Service Providers',
            'Companies that help us operate:',
            '''• Cloud hosting providers (Amazon Web Services, Google Cloud)
• Analytics platforms (Google Analytics, Mixpanel, Amplitude)
• Customer support tools (Zendesk, Intercom)
• Email service providers (SendGrid, Mailchimp)
• Push notification services (Firebase, OneSignal)
• Payment processors (Stripe, PayPal)
• Content delivery networks (Cloudflare, Fastly)''',
          ),
          _buildSubSection(
            'advertising_partners',
            'Advertising & Marketing Partners',
            'For personalized advertising:',
            '''• Ad networks (Google AdMob, Facebook Audience Network)
• Demand-side platforms
• Data management platforms
• Attribution and measurement partners
• Retargeting service providers
• Social media platforms for custom audiences''',
          ),
        ],
      ),
      _buildExpandableSection(
        'your_rights',
        'Your Rights',
        'You have various rights regarding your data.',
        [
          _buildSubSection(
            'access_rights',
            'Access & Portability',
            'Understanding your data:',
            '''• Request a copy of your personal data
• Receive data in a machine-readable format
• Transfer data to another service provider
• View what third parties have received your data
• Understand how decisions are made about you''',
          ),
          _buildSubSection(
            'control_rights',
            'Control & Correction',
            'Managing your information:',
            '''• Update or correct inaccurate information
• Delete certain personal data (subject to limitations)
• Restrict processing in certain circumstances
• Object to processing for direct marketing
• Withdraw consent (where processing is based on consent)''',
          ),
        ],
      ),
      _buildExpandableSection(
        'security',
        'Security Measures',
        'How we protect your data.',
        [
          _buildSubSection(
            'technical_security',
            'Technical Safeguards',
            'Security technologies:',
            '''• TLS 1.3 encryption for data in transit
• AES-256 encryption for data at rest
• Multi-factor authentication support
• Regular security audits and penetration testing
• Intrusion detection and prevention systems
• Web application firewalls
• DDoS protection''',
          ),
        ],
      ),
      _buildExpandableSection(
        'contact',
        'Contact Information',
        'How to reach us about privacy matters.',
        [
          _buildSubSection(
            'contact_details',
            'Contact Details',
            'Get in touch:',
            '''• Privacy inquiries: privacy@fitlifetechnologies.com
• Data Protection Officer: dpo@fitlifetechnologies.com
• Mailing address: FitLife Technologies, Inc.
  123 Fitness Way, Suite 500
  San Francisco, CA 94105
  United States

• Response time: Within 30 days of receipt''',
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildTermsOfServiceSections() {
    return [
      _buildIntroSection(
        'Welcome to FitTrack Pro. These Terms of Service ("Terms") govern your access to and use of FitTrack Pro mobile application and related services (collectively, the "Service") provided by FitLife Technologies, Inc. ("Company", "we", "us", "our"). By accessing or using our Service, you agree to be bound by these Terms.',
      ),
      _buildExpandableSection(
        'acceptance',
        'Acceptance of Terms',
        'By using FitTrack Pro, you agree to these terms.',
        [
          _buildSubSection(
            'binding_agreement',
            'Binding Agreement',
            'This creates a legal contract:',
            '''• These Terms constitute a legally binding agreement between you and FitLife Technologies
• By creating an account, you confirm you have read and understood these Terms
• If you do not agree, you must not use the Service
• Your continued use constitutes ongoing acceptance
• We may update these Terms at any time
• Material changes will be notified via email or in-app notification''',
          ),
        ],
      ),
      _buildExpandableSection(
        'eligibility',
        'Eligibility & Account Registration',
        'Requirements to use our Service.',
        [
          _buildSubSection(
            'age_requirements',
            'Age Requirements',
            'Minimum age to use FitTrack Pro:',
            '''• You must be at least 16 years of age to create an account
• Users aged 16-17 represent they have parental or guardian consent
• Users under 13 are strictly prohibited from using this Service
• We may require age verification at any time
• Providing false age information is grounds for account termination
• Some features may require users to be 18 or older''',
          ),
          _buildSubSection(
            'account_creation',
            'Account Creation & Responsibilities',
            'Your account obligations:',
            '''• You must provide accurate and complete registration information
• You must provide a valid email address
• You are responsible for maintaining the confidentiality of your login credentials
• You must not share your account with others
• You must notify us immediately of any unauthorized access
• One account per person; duplicate accounts may be terminated
• You are responsible for all activities under your account''',
          ),
        ],
      ),
      _buildExpandableSection(
        'license',
        'License & Permitted Use',
        'What you can do with our Service.',
        [
          _buildSubSection(
            'license_grant',
            'License Grant',
            'We grant you a limited license:',
            '''• Personal, non-exclusive, non-transferable, revocable license
• To download and install the App on your personal devices
• To access and use the Service for personal, non-commercial purposes
• Subject to compliance with these Terms
• License does not include any right to modify, distribute, or create derivative works
• License terminates upon termination of your account''',
          ),
        ],
      ),
      _buildExpandableSection(
        'prohibited',
        'Prohibited Conduct',
        'What you must not do.',
        [
          _buildSubSection(
            'general_prohibitions',
            'General Prohibitions',
            'You agree not to:',
            '''• Violate any applicable laws or regulations
• Provide false or misleading information
• Impersonate any person or entity
• Use the Service for commercial purposes without authorization
• Interfere with or disrupt the Service
• Access accounts or data not belonging to you
• Engage in any fraudulent activity''',
          ),
          _buildSubSection(
            'technical_prohibitions',
            'Technical Prohibitions',
            'Technical activities prohibited:',
            '''• Reverse engineer, decompile, or disassemble the App
• Modify, adapt, or create derivative works
• Remove or alter any proprietary notices
• Use automated systems, bots, or scrapers
• Attempt to bypass security measures
• Exploit bugs, vulnerabilities, or glitches
• Introduce malware, viruses, or harmful code
• Perform load testing without written permission''',
          ),
        ],
      ),
      _buildExpandableSection(
        'health_disclaimer',
        'Health & Medical Disclaimer',
        'Important health information.',
        [
          _buildSubSection(
            'not_medical_advice',
            'Not Medical Advice',
            'Our Service is not medical advice:',
            '''• FitTrack Pro is intended for informational purposes only
• The Service does not provide medical advice, diagnosis, or treatment
• Content is not a substitute for professional medical advice
• Always consult a qualified healthcare provider before starting any fitness program
• Do not disregard professional medical advice based on app information
• Seek immediate medical attention for any medical emergency''',
          ),
        ],
      ),
      _buildExpandableSection(
        'disclaimers',
        'Disclaimers & Limitations',
        'Important limitations on our liability.',
        [
          _buildSubSection(
            'warranty_disclaimer',
            'Warranty Disclaimer',
            'Service provided "as is":',
            '''• THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE"
• WE DISCLAIM ALL WARRANTIES, EXPRESS OR IMPLIED
• INCLUDING WARRANTIES OF MERCHANTABILITY AND FITNESS FOR PURPOSE
• WE DO NOT GUARANTEE UNINTERRUPTED OR ERROR-FREE SERVICE
• WE DO NOT WARRANT THE ACCURACY OF ANY INFORMATION
• USE OF THE SERVICE IS AT YOUR SOLE RISK''',
          ),
          _buildSubSection(
            'liability_limitation',
            'Limitation of Liability',
            'Caps on our liability:',
            '''• WE SHALL NOT BE LIABLE FOR INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES
• INCLUDING LOST PROFITS, DATA LOSS, OR PERSONAL INJURY
• OUR TOTAL LIABILITY SHALL NOT EXCEED \$100 OR FEES PAID IN PAST 12 MONTHS
• THESE LIMITATIONS APPLY REGARDLESS OF LEGAL THEORY
• SOME JURISDICTIONS DO NOT ALLOW THESE LIMITATIONS''',
          ),
        ],
      ),
      _buildExpandableSection(
        'general',
        'General Provisions',
        'Additional legal terms.',
        [
          _buildSubSection(
            'contact_info',
            'Contact Information',
            'How to reach us:',
            '''• Legal inquiries: legal@fitlifetechnologies.com
• Support: support@fitlifetechnologies.com
• Mailing address: FitLife Technologies, Inc.
  123 Fitness Way, Suite 500
  San Francisco, CA 94105
  United States''',
          ),
        ],
      ),
    ];
  }

  Widget _buildIntroSection(String text) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 14,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildExpandableSection(
    String id,
    String title,
    String summary,
    List<Widget> children,
  ) {
    final isExpanded = _expandedSections.contains(id);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSections.remove(id);
                } else {
                  _expandedSections.add(id);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          summary,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4A90D9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isExpanded ? 'less details' : 'more details',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              color: const Color(0xFFF8F9FA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubSection(
    String id,
    String title,
    String subtitle,
    String content,
  ) {
    final fullId = '${id}_sub';
    final isExpanded = _expandedSections.contains(fullId);

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSections.remove(fullId);
                } else {
                  _expandedSections.add(fullId);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    isExpanded
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: const Color(0xFF4A90D9),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.fromLTRB(52, 0, 20, 16),
              child: Text(
                content,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
