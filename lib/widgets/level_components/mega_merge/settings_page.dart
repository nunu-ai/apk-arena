import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

/// Settings state
class SettingsState {
  final bool soundEnabled;
  final bool vibrationEnabled;
  final bool notificationsEnabled;
  final double masterVolume;

  const SettingsState({
    this.soundEnabled = true,
    this.vibrationEnabled = true,
    this.notificationsEnabled = true,
    this.masterVolume = 0.8,
  });

  SettingsState copyWith({
    bool? soundEnabled,
    bool? vibrationEnabled,
    bool? notificationsEnabled,
    double? masterVolume,
  }) {
    return SettingsState(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      masterVolume: masterVolume ?? this.masterVolume,
    );
  }
}

/// Full settings page with toggles
class SettingsPage extends StatefulWidget {
  final SettingsState settings;
  final Function(SettingsState) onSettingsChanged;
  final VoidCallback onResetProgress;

  const SettingsPage({
    Key? key,
    required this.settings,
    required this.onSettingsChanged,
    required this.onResetProgress,
  }) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late SettingsState _localSettings;

  @override
  void initState() {
    super.initState();
    _localSettings = widget.settings;
  }

  void _updateSetting(SettingsState newSettings) {
    setState(() => _localSettings = newSettings);
    widget.onSettingsChanged(newSettings);
    HapticFeedback.selectionClick();
  }

  void _showResetConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'reset progress?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'this will reset all your progress in this level. this cannot be undone!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'cancel',
              style: TextStyle(color: Colors.white54),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onResetProgress();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('progress reset!'),
                  backgroundColor: NunuColors.warningMain,
                ),
              );
            },
            child: const Text(
              'reset',
              style: TextStyle(color: NunuColors.errorMain),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NunuColors.backgroundDefault,
      appBar: AppBar(
        backgroundColor: NunuColors.backgroundPaper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'settings',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Audio Section
          _buildSectionHeader('audio'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildToggleTile(
              icon: Icons.volume_up,
              title: 'sound effects',
              subtitle: 'play sounds on actions',
              value: _localSettings.soundEnabled,
              onChanged: (value) => _updateSetting(
                _localSettings.copyWith(soundEnabled: value),
              ),
            ),
            const Divider(color: Colors.white12),
            _buildSliderTile(
              icon: Icons.speaker,
              title: 'master volume',
              value: _localSettings.masterVolume,
              enabled: _localSettings.soundEnabled,
              onChanged: (value) => _updateSetting(
                _localSettings.copyWith(masterVolume: value),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Feedback Section
          _buildSectionHeader('feedback'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildToggleTile(
              icon: Icons.vibration,
              title: 'vibration',
              subtitle: 'haptic feedback on interactions',
              value: _localSettings.vibrationEnabled,
              onChanged: (value) => _updateSetting(
                _localSettings.copyWith(vibrationEnabled: value),
              ),
            ),
            const Divider(color: Colors.white12),
            _buildToggleTile(
              icon: Icons.notifications,
              title: 'notifications',
              subtitle: 'energy refill reminders',
              value: _localSettings.notificationsEnabled,
              onChanged: (value) => _updateSetting(
                _localSettings.copyWith(notificationsEnabled: value),
              ),
            ),
          ]),
          const SizedBox(height: 24),

          // Data Section
          _buildSectionHeader('data'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildActionTile(
              icon: Icons.delete_forever,
              title: 'reset progress',
              subtitle: 'start fresh (cannot be undone)',
              iconColor: NunuColors.errorMain,
              onTap: _showResetConfirmation,
            ),
          ]),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('about'),
          const SizedBox(height: 12),
          _buildSettingsCard([
            _buildInfoTile(
              icon: Icons.info_outline,
              title: 'version',
              value: '1.0.0',
            ),
            const Divider(color: Colors.white12),
            _buildInfoTile(
              icon: Icons.code,
              title: 'made by',
              value: 'nunu.ai',
            ),
          ]),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: NunuColors.primaryMain,
        fontSize: 14,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: NunuColors.primaryMain),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: NunuColors.primaryMain,
        activeTrackColor: NunuColors.primaryMain.withOpacity(0.3),
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String title,
    required double value,
    required bool enabled,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: enabled ? NunuColors.primaryMain : Colors.white38),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: enabled ? Colors.white : Colors.white54,
                    fontSize: 16,
                  ),
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: NunuColors.primaryMain,
                    inactiveTrackColor: Colors.white24,
                    thumbColor: NunuColors.primaryMain,
                    overlayColor: NunuColors.primaryMain.withOpacity(0.2),
                  ),
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    onChanged: enabled ? onChanged : null,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              color: enabled ? Colors.white : Colors.white38,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white38),
      onTap: onTap,
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return ListTile(
      leading: Icon(icon, color: NunuColors.primaryMain),
      title: Text(
        title,
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      trailing: Text(
        value,
        style: const TextStyle(color: Colors.white54, fontSize: 14),
      ),
    );
  }
}

