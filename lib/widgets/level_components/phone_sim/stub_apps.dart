import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'phone_homescreen.dart';

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
          Expanded(
            child: content ?? _buildDefaultContent(),
          ),
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
            style: TextStyle(
              color: NunuColors.textSecondary,
              fontSize: 14,
            ),
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
          PhoneAppBar(
            title: 'Settings',
            onBack: onBack,
          ),
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
          ? Text(subtitle, style: const TextStyle(color: NunuColors.textSecondary))
          : null,
      trailing: const Icon(Icons.chevron_right, color: NunuColors.textSecondary),
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
          PhoneAppBar(
            title: 'Phone',
            onBack: onBack,
          ),
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
                      for (final digit in ['1', '2', '3', '4', '5', '6', '7', '8', '9', '*', '0', '#'])
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
                    child: const Icon(Icons.call, color: Colors.white, size: 32),
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
          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
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
                        border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                      ),
                    ),
                    const Icon(Icons.cameraswitch, color: Colors.white, size: 32),
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
    final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Clock',
            onBack: onBack,
          ),
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
            color: isSelected ? NunuColors.primaryMain : NunuColors.textSecondary,
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
          PhoneAppBar(
            title: 'Calendar',
            onBack: onBack,
          ),
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
                  .map((d) => Text(
                        d,
                        style: const TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 14,
                        ),
                      ))
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
                    color: isToday ? NunuColors.primaryMain : Colors.transparent,
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
          PhoneAppBar(
            title: 'Messages',
            onBack: onBack,
          ),
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

/// Browser app stub
class BrowserStubApp extends StatelessWidget {
  final VoidCallback onBack;

  const BrowserStubApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Browser',
            onBack: onBack,
          ),
          // URL bar
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                const Icon(Icons.lock, color: NunuColors.textSecondary, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Search or type URL',
                    style: TextStyle(color: NunuColors.textSecondary),
                  ),
                ),
                const Icon(Icons.mic, color: NunuColors.textSecondary),
              ],
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.public,
                    size: 64,
                    color: NunuColors.textSecondary.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'start browsing',
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

