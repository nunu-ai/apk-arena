import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../level_components/phone_sim/phone_homescreen.dart';
import '../level_components/phone_sim/play_store.dart';
import '../level_components/phone_sim/play_store_data.dart';
import '../level_components/phone_sim/stub_apps.dart';
import '../level_components/phone_sim/embedded_place_cards.dart';
import '../level_components/phone_sim/embedded_mega_merge.dart';
import '../level_components/phone_sim/checklist_app.dart';

/// The active app/screen being displayed
enum ActiveScreen {
  homescreen,
  playStore,
  settings,
  phone,
  camera,
  clock,
  calendar,
  gmail,
  messages,
  browser,
  placeTheCards,
  megaMerge,
  checklist,
  genericApp,
}

/// Main Phone Simulator Level
/// 
/// This level presents a fake phone homescreen with multiple apps.
/// The player must:
/// 1. Explore the Play Store and install apps
/// 2. Update and play "Mega Merge" (requires age verification)
/// 3. Install and play "Place the Cards" (no age gate)
/// 4. Answer checklist questions about what they discovered
class LevelPhoneSimulator extends LevelWidget {
  const LevelPhoneSimulator({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelPhoneSimulator> createState() => _LevelPhoneSimulatorState();
}

class _LevelPhoneSimulatorState extends State<LevelPhoneSimulator> {
  // Current screen
  ActiveScreen _currentScreen = ActiveScreen.homescreen;
  String? _genericAppId;

  // Installed apps (by ID)
  final Set<String> _installedApps = {};

  // Special app states
  bool _megaMergeUpdated = false;
  bool _placeCardsTosAccepted = false;
  bool _megaMergeTosAccepted = false;
  bool _megaMergeAgeVerified = false;

  // Checklist answers
  final Map<String, bool?> _checklistAnswers = {};

  // System apps always present on homescreen
  static const List<PhoneApp> _systemApps = [
    PhoneApp(
      id: 'settings',
      name: 'Settings',
      icon: Icons.settings,
      color: Color(0xFF607D8B),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'phone',
      name: 'Phone',
      icon: Icons.phone,
      color: Color(0xFF4CAF50),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'camera',
      name: 'Camera',
      icon: Icons.camera_alt,
      color: Color(0xFF424242),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'clock',
      name: 'Clock',
      icon: Icons.access_time,
      color: Color(0xFF3F51B5),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'calendar',
      name: 'Calendar',
      icon: Icons.calendar_today,
      color: Color(0xFF2196F3),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'gmail',
      name: 'Gmail',
      icon: Icons.mail,
      color: Color(0xFFEA4335),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'play_store',
      name: 'Play Store',
      icon: Icons.shop,
      color: Color(0xFF4CAF50),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'checklist',
      name: 'Checklist',
      icon: Icons.checklist,
      color: Color(0xFFFF9800),
      isSystemApp: true,
    ),
    // Mega Merge is pre-installed but needs update
    PhoneApp(
      id: 'mega_merge',
      name: 'Mega Merge',
      icon: Icons.merge_type,
      color: Color(0xFF9C27B0),
      isSystemApp: false,
      requiresUpdate: true,
    ),
  ];

  // Dock apps
  static const List<PhoneApp> _dockApps = [
    PhoneApp(
      id: 'phone',
      name: 'Phone',
      icon: Icons.phone,
      color: Color(0xFF4CAF50),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'messages',
      name: 'Messages',
      icon: Icons.message,
      color: Color(0xFF2196F3),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'browser',
      name: 'Browser',
      icon: Icons.public,
      color: Color(0xFFFF5722),
      isSystemApp: true,
    ),
    PhoneApp(
      id: 'play_store',
      name: 'Store',
      icon: Icons.shop,
      color: Color(0xFF4CAF50),
      isSystemApp: true,
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Pre-install Mega Merge (but it needs update)
    _installedApps.add('mega_merge');
  }

  List<PhoneApp> get _homescreenApps {
    final apps = <PhoneApp>[];

    // Add system apps
    apps.addAll(_systemApps);

    // Add installed apps from Play Store
    for (final appId in _installedApps) {
      // Skip if already in system apps
      if (_systemApps.any((a) => a.id == appId)) continue;

      // Find the app in store data
      final storeApp = allStoreApps.where((a) => a.id == appId).firstOrNull;
      if (storeApp != null) {
        apps.add(PhoneApp(
          id: storeApp.id,
          name: storeApp.name,
          icon: storeApp.icon,
          color: storeApp.color,
        ));
      }
    }

    return apps;
  }

  void _openApp(PhoneApp app) {
    setState(() {
      switch (app.id) {
        case 'settings':
          _currentScreen = ActiveScreen.settings;
          break;
        case 'phone':
          _currentScreen = ActiveScreen.phone;
          break;
        case 'camera':
          _currentScreen = ActiveScreen.camera;
          break;
        case 'clock':
          _currentScreen = ActiveScreen.clock;
          break;
        case 'calendar':
          _currentScreen = ActiveScreen.calendar;
          break;
        case 'gmail':
          _currentScreen = ActiveScreen.gmail;
          break;
        case 'messages':
          _currentScreen = ActiveScreen.messages;
          break;
        case 'browser':
          _currentScreen = ActiveScreen.browser;
          break;
        case 'play_store':
          _currentScreen = ActiveScreen.playStore;
          break;
        case 'checklist':
          _currentScreen = ActiveScreen.checklist;
          break;
        case 'place_the_cards':
          _currentScreen = ActiveScreen.placeTheCards;
          break;
        case 'mega_merge':
          _currentScreen = ActiveScreen.megaMerge;
          break;
        default:
          _genericAppId = app.id;
          _currentScreen = ActiveScreen.genericApp;
      }
    });
  }

  void _goHome() {
    setState(() {
      _currentScreen = ActiveScreen.homescreen;
      _genericAppId = null;
    });
  }

  void _installApp(StoreApp app) {
    setState(() {
      _installedApps.add(app.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${app.name} installed!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _updateApp(StoreApp app) {
    if (app.id == 'mega_merge') {
      setState(() {
        _megaMergeUpdated = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${app.name} updated!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _onChecklistSubmit(bool allCorrect) {
    if (allCorrect) {
      // Level complete!
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildCurrentScreen();
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case ActiveScreen.homescreen:
        return PhoneHomescreen(
          installedApps: _homescreenApps,
          dockApps: _dockApps,
          onAppTap: _openApp,
        );

      case ActiveScreen.playStore:
        return PlayStoreApp(
          installedApps: _installedApps,
          megaMergeUpdated: _megaMergeUpdated,
          onInstallApp: _installApp,
          onUpdateApp: _updateApp,
          onBack: _goHome,
        );

      case ActiveScreen.settings:
        return SettingsStubApp(onBack: _goHome);

      case ActiveScreen.phone:
        return PhoneStubApp(onBack: _goHome);

      case ActiveScreen.camera:
        return CameraStubApp(onBack: _goHome);

      case ActiveScreen.clock:
        return ClockStubApp(onBack: _goHome);

      case ActiveScreen.calendar:
        return CalendarStubApp(onBack: _goHome);

      case ActiveScreen.gmail:
        return GmailStubApp(onBack: _goHome);

      case ActiveScreen.messages:
        return MessagesStubApp(onBack: _goHome);

      case ActiveScreen.browser:
        return BrowserStubApp(onBack: _goHome);

      case ActiveScreen.placeTheCards:
        return EmbeddedPlaceCardsApp(
          onBack: _goHome,
          tosAccepted: _placeCardsTosAccepted,
          onTosAccepted: (accepted) {
            setState(() => _placeCardsTosAccepted = accepted);
          },
        );

      case ActiveScreen.megaMerge:
        return EmbeddedMegaMergeApp(
          onBack: _goHome,
          isUpdated: _megaMergeUpdated,
          tosAccepted: _megaMergeTosAccepted,
          ageVerified: _megaMergeAgeVerified,
          onTosAccepted: (accepted) {
            setState(() => _megaMergeTosAccepted = accepted);
          },
          onAgeVerified: (verified) {
            setState(() => _megaMergeAgeVerified = verified);
          },
        );

      case ActiveScreen.checklist:
        return ChecklistApp(
          onBack: _goHome,
          answers: _checklistAnswers,
          onAnswerChanged: (questionId, answer) {
            setState(() {
              _checklistAnswers[questionId] = answer;
            });
          },
          onSubmit: _onChecklistSubmit,
        );

      case ActiveScreen.genericApp:
        // Find the app info
        final appInfo = allStoreApps.where((a) => a.id == _genericAppId).firstOrNull;
        return StubApp(
          title: appInfo?.name ?? 'App',
          icon: appInfo?.icon ?? Icons.apps,
          color: appInfo?.color ?? Colors.blue,
          onBack: _goHome,
        );
    }
  }
}

