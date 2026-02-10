import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'settings_app_state.dart';
import 'settings_widgets.dart';
import 'settings_screens.dart';

/// A complete settings mini-app that can be used in various levels.
/// Provides a comprehensive, realistic settings experience.
class SettingsApp extends StatefulWidget {
  final SettingsAppState initialState;
  final Widget? bottomBar;

  /// When true, clearing cache will update the cache page but NOT the storage bar.
  /// This simulates a bug where the storage display doesn't refresh after clearing cache.
  final bool hasCacheClearingBug;

  const SettingsApp({
    super.key,
    required this.initialState,
    this.bottomBar,
    this.hasCacheClearingBug = false,
  });
  
  @override
  State<SettingsApp> createState() => _SettingsAppState();
}

class _SettingsAppState extends State<SettingsApp> {
  late SettingsAppState _state;
  final List<String> _navStack = ['main'];
  
  @override
  void initState() {
    super.initState();
    _state = widget.initialState;
    // If bug is enabled, freeze initial storage values so they won't update
    if (widget.hasCacheClearingBug) {
      _state.freezeStorageValues();
    }
  }
  
  void _navigateTo(String screen) {
    setState(() {
      _navStack.add(screen);
    });
  }
  
  void _goBack() {
    if (_navStack.length > 1) {
      setState(() {
        _navStack.removeLast();
      });
    }
  }
  
  String get _currentScreen => _navStack.last;
  
  void _updateState(void Function(SettingsAppState) updater) {
    setState(() {
      updater(_state);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Bold text applies FontWeight.bold to all text
    final textStyle = _state.boldText 
        ? const TextStyle(fontWeight: FontWeight.bold)
        : const TextStyle();
    
    return DefaultTextStyle.merge(
      style: textStyle,
      child: Container(
        color: NunuColors.backgroundDefault,
        child: SafeArea(
          child: Column(
            children: [
              SettingsHeader(
                title: _getScreenTitle(_currentScreen),
                showBackButton: _currentScreen != 'main',
                onBack: _goBack,
              ),
              Expanded(
                child: _buildCurrentScreen(),
              ),
              if (widget.bottomBar != null) widget.bottomBar!,
            ],
          ),
        ),
      ),
    );
  }
  
  String _getScreenTitle(String screen) {
    switch (screen) {
      case 'main': return 'settings';
      case 'profile': return 'profile';
      case 'profile_edit_name': return 'edit name';
      case 'profile_edit_email': return 'edit email';
      case 'profile_edit_phone': return 'edit phone';
      case 'profile_edit_bio': return 'edit bio';
      case 'profile_linked': return 'linked accounts';
      case 'profile_photo': return 'choose photo';
      case 'account': return 'account';
      case 'account_password': return 'change password';
      case 'account_2fa': return 'two-factor auth';
      case 'account_sessions': return 'active sessions';
      case 'notifications': return 'notifications';
      case 'notifications_quiet': return 'quiet hours';
      case 'privacy': return 'privacy & security';
      case 'privacy_visibility': return 'profile visibility';
      case 'privacy_data': return 'your data';
      case 'display': return 'display & theme';
      case 'sound': return 'sound & haptics';
      case 'language': return 'language & region';
      case 'language_timezone': return 'timezone';
      case 'data': return 'data & storage';
      case 'data_cache': return 'cache management';
      case 'accessibility': return 'accessibility';
      case 'about': return 'about';
      case 'about_licenses': return 'licenses';
      case 'about_support': return 'help & support';
      case 'about_terms': return 'terms of service';
      case 'about_privacy': return 'privacy policy';
      case 'about_rate': return 'rate the app';
      case 'support_faq': return 'faq';
      case 'support_contact': return 'contact support';
      case 'support_feedback': return 'send feedback';
      case 'support_bug': return 'report a bug';
      default: return 'settings';
    }
  }
  
  Widget _buildCurrentScreen() {
    final screens = SettingsScreens(
      state: _state,
      navigateTo: _navigateTo,
      goBack: _goBack,
      updateState: _updateState,
      context: context,
      showSnackBar: (msg, color) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: color),
        );
      },
      showDialog: (dialog) => showDialog(context: context, builder: (_) => dialog),
      showTimePicker: (initial) => showTimePicker(context: context, initialTime: initial),
      hasCacheClearingBug: widget.hasCacheClearingBug,
    );
    
    switch (_currentScreen) {
      case 'main': return screens.buildMainSettings();
      case 'profile': return screens.buildProfileSettings();
      case 'profile_edit_name': return screens.buildEditName();
      case 'profile_edit_email': return screens.buildEditEmail();
      case 'profile_edit_phone': return screens.buildEditPhone();
      case 'profile_edit_bio': return screens.buildEditBio();
      case 'profile_linked': return screens.buildLinkedAccounts();
      case 'profile_photo': return screens.buildPhotoSelector();
      case 'account': return screens.buildAccountSettings();
      case 'account_password': return screens.buildChangePassword();
      case 'account_2fa': return screens.buildTwoFactorAuth();
      case 'account_sessions': return screens.buildActiveSessions();
      case 'notifications': return screens.buildNotificationSettings();
      case 'notifications_quiet': return screens.buildQuietHours();
      case 'privacy': return screens.buildPrivacySettings();
      case 'privacy_visibility': return screens.buildProfileVisibility();
      case 'privacy_data': return screens.buildYourData();
      case 'display': return screens.buildDisplaySettings();
      case 'sound': return screens.buildSoundSettings();
      case 'language': return screens.buildLanguageSettings();
      case 'language_timezone': return screens.buildTimezoneSettings();
      case 'data': return screens.buildDataSettings();
      case 'data_cache': return screens.buildCacheManagement();
      case 'accessibility': return screens.buildAccessibilitySettings();
      case 'about': return screens.buildAboutSettings();
      case 'about_licenses': return screens.buildLicenses();
      case 'about_support': return screens.buildSupport();
      case 'about_terms': return screens.buildTermsOfService();
      case 'about_privacy': return screens.buildPrivacyPolicy();
      case 'about_rate': return screens.buildRateApp();
      case 'support_faq': return screens.buildFaq();
      case 'support_contact': return screens.buildContactSupport();
      case 'support_feedback': return screens.buildSendFeedback();
      case 'support_bug': return screens.buildReportBug();
      default: return screens.buildMainSettings();
    }
  }
}

