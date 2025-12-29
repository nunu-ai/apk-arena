import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/phone_sim/phone_homescreen.dart';
import '../level_components/phone_sim/play_store.dart';
import '../level_components/phone_sim/play_store_data.dart';
import '../level_components/phone_sim/stub_apps.dart';
import '../level_components/phone_sim/embedded_place_cards.dart';
import '../level_components/phone_sim/embedded_mega_merge.dart';
import '../level_components/phone_sim/embedded_fitness_tracker.dart';
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
  fitnessTracker,
  checklist,
  genericApp,
}

/// Game state for Mega Merge (persists across uninstall/reinstall)
class MegaMergeGameState {
  final int currentLevel;
  final int highestTier;
  final int totalMerges;

  const MegaMergeGameState({
    this.currentLevel = 2, // Start at level 2 (requires tier 3)
    this.highestTier = 0,
    this.totalMerges = 0,
  });

  MegaMergeGameState copyWith({
    int? currentLevel,
    int? highestTier,
    int? totalMerges,
  }) {
    return MegaMergeGameState(
      currentLevel: currentLevel ?? this.currentLevel,
      highestTier: highestTier ?? this.highestTier,
      totalMerges: totalMerges ?? this.totalMerges,
    );
  }
}

/// Game state for Place the Cards (clears on uninstall)
class PlaceCardsGameState {
  final int currentLevel;
  final int completedLevels;
  final int highScore;

  const PlaceCardsGameState({
    this.currentLevel = 1,
    this.completedLevels = 0,
    this.highScore = 0,
  });

  PlaceCardsGameState copyWith({
    int? currentLevel,
    int? completedLevels,
    int? highScore,
  }) {
    return PlaceCardsGameState(
      currentLevel: currentLevel ?? this.currentLevel,
      completedLevels: completedLevels ?? this.completedLevels,
      highScore: highScore ?? this.highScore,
    );
  }
}

/// Fitness Tracker data (persists ALWAYS - tied to device ID, no delete option)
class FitnessTrackerData {
  final String? userName;
  final String? userEmail;
  final int totalSteps;
  final int totalWorkouts;
  final int streakDays;
  final List<String> achievements;
  final bool onboardingComplete;

  const FitnessTrackerData({
    this.userName,
    this.userEmail,
    this.totalSteps = 0,
    this.totalWorkouts = 0,
    this.streakDays = 0,
    this.achievements = const [],
    this.onboardingComplete = false,
  });

  FitnessTrackerData copyWith({
    String? userName,
    String? userEmail,
    int? totalSteps,
    int? totalWorkouts,
    int? streakDays,
    List<String>? achievements,
    bool? onboardingComplete,
  }) {
    return FitnessTrackerData(
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      totalSteps: totalSteps ?? this.totalSteps,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      streakDays: streakDays ?? this.streakDays,
      achievements: achievements ?? this.achievements,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
    );
  }
}

/// A single browser tab
class BrowserTab {
  final String id;
  final String url;
  final String title;

  const BrowserTab({required this.id, required this.url, required this.title});

  BrowserTab copyWith({String? id, String? url, String? title}) {
    return BrowserTab(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
    );
  }

  /// Get title from URL if not explicitly set
  static String getTitleFromUrl(String url) {
    if (url.isEmpty) return 'New Tab';
    if (url.contains('fittrack-pro.com/terms')) return 'Terms of Service';
    if (url.contains('fittrack-pro.com/privacy')) return 'Privacy Policy';
    // Extract domain as fallback
    final uri = Uri.tryParse('https://$url');
    return uri?.host ?? url;
  }
}

/// Browser state with tab management
class BrowserState {
  final List<BrowserTab> tabs;
  final int activeTabIndex;

  const BrowserState({this.tabs = const [], this.activeTabIndex = 0});

  BrowserTab? get activeTab => tabs.isNotEmpty && activeTabIndex < tabs.length
      ? tabs[activeTabIndex]
      : null;

  BrowserState copyWith({List<BrowserTab>? tabs, int? activeTabIndex}) {
    return BrowserState(
      tabs: tabs ?? this.tabs,
      activeTabIndex: activeTabIndex ?? this.activeTabIndex,
    );
  }

  /// Add a new tab and make it active
  BrowserState addTab(String url) {
    final newTab = BrowserTab(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      url: url,
      title: BrowserTab.getTitleFromUrl(url),
    );
    final newTabs = [...tabs, newTab];
    return BrowserState(tabs: newTabs, activeTabIndex: newTabs.length - 1);
  }

  /// Add a new tab or switch to existing tab with same URL
  BrowserState openUrl(String url) {
    // Check if a tab with this URL already exists
    final existingIndex = tabs.indexWhere((tab) => tab.url == url);
    if (existingIndex >= 0) {
      return copyWith(activeTabIndex: existingIndex);
    }
    return addTab(url);
  }

  /// Close a tab by index
  BrowserState closeTab(int index) {
    if (tabs.length <= 1) {
      // Keep at least one tab (new tab)
      return const BrowserState(
        tabs: [BrowserTab(id: 'default', url: '', title: 'New Tab')],
        activeTabIndex: 0,
      );
    }
    final newTabs = [...tabs]..removeAt(index);
    int newActiveIndex = activeTabIndex;
    if (index <= activeTabIndex && activeTabIndex > 0) {
      newActiveIndex--;
    }
    if (newActiveIndex >= newTabs.length) {
      newActiveIndex = newTabs.length - 1;
    }
    return BrowserState(tabs: newTabs, activeTabIndex: newActiveIndex);
  }

  /// Switch to a tab by index
  BrowserState switchToTab(int index) {
    if (index >= 0 && index < tabs.length) {
      return copyWith(activeTabIndex: index);
    }
    return this;
  }

  /// Update the URL of the active tab
  BrowserState navigateTo(String url) {
    if (tabs.isEmpty) {
      return addTab(url);
    }
    final newTabs = [...tabs];
    newTabs[activeTabIndex] = tabs[activeTabIndex].copyWith(
      url: url,
      title: BrowserTab.getTitleFromUrl(url),
    );
    return copyWith(tabs: newTabs);
  }

  /// Create default state with one empty tab
  static BrowserState initial() {
    return const BrowserState(
      tabs: [BrowserTab(id: 'default', url: '', title: 'New Tab')],
      activeTabIndex: 0,
    );
  }
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

  // Play Store deep-link support - navigate directly to a specific app
  String? _playStoreInitialAppId;

  // Browser state with tabs
  BrowserState _browserState = BrowserState.initial();

  // Installed apps (by ID)
  final Set<String> _installedApps = {};

  // Special app states
  bool _megaMergeUpdated = false;
  bool _placeCardsTosAccepted = false;
  bool _megaMergeTosAccepted = true; // Pre-accepted for this level
  bool _megaMergeAgeVerified = false;
  bool _fitnessTrackerTosAccepted = false;

  // Game-specific data (persists based on app behavior)
  MegaMergeGameState _megaMergeGameState = const MegaMergeGameState();
  PlaceCardsGameState _placeCardsGameState = const PlaceCardsGameState();
  FitnessTrackerData _fitnessTrackerData = const FitnessTrackerData();

  // Checklist answers
  final Map<String, bool?> _checklistAnswers = {};

  // System apps always present on homescreen (cannot be uninstalled)
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
        // Special handling for Mega Merge - show update required badge if not updated
        final requiresUpdate = appId == 'mega_merge' && !_megaMergeUpdated;
        apps.add(
          PhoneApp(
            id: storeApp.id,
            name: storeApp.name,
            icon: storeApp.icon,
            color: storeApp.color,
            isSystemApp: false,
            requiresUpdate: requiresUpdate,
          ),
        );
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
        case 'fitness_tracker':
          _currentScreen = ActiveScreen.fitnessTracker;
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
      _playStoreInitialAppId = null;
    });
  }

  /// Navigate to Play Store and open directly to a specific app's page
  /// This is a reusable feature for any embedded app that needs to link to the store
  void _openPlayStoreForApp(String appId) {
    setState(() {
      _playStoreInitialAppId = appId;
      _currentScreen = ActiveScreen.playStore;
    });
  }

  /// Open browser with a specific URL
  /// Adds a new tab or switches to existing tab with same URL
  void _openBrowserWithUrl(String url) {
    setState(() {
      _browserState = _browserState.openUrl(url);
      _currentScreen = ActiveScreen.browser;
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

  void _uninstallApp(String appId) {
    setState(() {
      _installedApps.remove(appId);

      // Handle data persistence based on app type
      if (appId == 'place_the_cards') {
        // Place the Cards: clear all data on uninstall
        _placeCardsTosAccepted = false;
        _placeCardsGameState = const PlaceCardsGameState();
      } else if (appId == 'mega_merge') {
        // Mega Merge: clear all state on uninstall for fresh reinstall experience
        _megaMergeTosAccepted = false;
        _megaMergeAgeVerified = false;
        _megaMergeUpdated = false;
        _megaMergeGameState = const MegaMergeGameState();
      }
      // Fitness Tracker: data persists across uninstall (tied to device ID)
    });

    final appInfo = allStoreApps.where((a) => a.id == appId).firstOrNull;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${appInfo?.name ?? 'App'} uninstalled'),
        backgroundColor: NunuColors.textSecondary,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showUninstallDialog(PhoneApp app) {
    if (app.isSystemApp) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('System apps cannot be uninstalled'),
          backgroundColor: NunuColors.errorMain,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: NunuColors.backgroundPaper,
        title: Text(
          'Uninstall ${app.name}?',
          style: const TextStyle(color: Colors.white),
        ),
        content: Text(
          'Do you want to uninstall this app?',
          style: TextStyle(color: NunuColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: NunuColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _uninstallApp(app.id);
            },
            child: const Text(
              'Uninstall',
              style: TextStyle(color: NunuColors.errorMain),
            ),
          ),
        ],
      ),
    );
  }

  void _clearMegaMergeData() {
    setState(() {
      _megaMergeGameState = const MegaMergeGameState();
      _megaMergeTosAccepted = true; // Keep ToS accepted but clear game progress
      _megaMergeAgeVerified = false;
    });
  }

  void _clearPlaceCardsData() {
    setState(() {
      _placeCardsGameState = const PlaceCardsGameState();
      _placeCardsTosAccepted = false;
    });
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
          onAppLongPress: _showUninstallDialog,
        );

      case ActiveScreen.playStore:
        return PlayStoreApp(
          installedApps: _installedApps,
          megaMergeUpdated: _megaMergeUpdated,
          onInstallApp: _installApp,
          onUpdateApp: _updateApp,
          onUninstallApp: _uninstallApp,
          onBack: _goHome,
          initialAppId: _playStoreInitialAppId,
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
        return BrowserStubApp(
          onBack: _goHome,
          browserState: _browserState,
          onBrowserStateChanged: (state) {
            setState(() => _browserState = state);
          },
        );

      case ActiveScreen.placeTheCards:
        return EmbeddedPlaceCardsApp(
          onBack: _goHome,
          tosAccepted: _placeCardsTosAccepted,
          onTosAccepted: (accepted) {
            setState(() => _placeCardsTosAccepted = accepted);
          },
          gameState: _placeCardsGameState,
          onGameStateChanged: (state) {
            setState(() => _placeCardsGameState = state);
          },
          onClearData: _clearPlaceCardsData,
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
          gameState: _megaMergeGameState,
          onGameStateChanged: (state) {
            setState(() => _megaMergeGameState = state);
          },
          onClearData: _clearMegaMergeData,
          onNavigateToPlayStore: _openPlayStoreForApp,
        );

      case ActiveScreen.fitnessTracker:
        return EmbeddedFitnessTrackerApp(
          onBack: _goHome,
          tosAccepted: _fitnessTrackerTosAccepted,
          onTosAccepted: (accepted) {
            setState(() => _fitnessTrackerTosAccepted = accepted);
          },
          data: _fitnessTrackerData,
          onDataChanged: (data) {
            setState(() => _fitnessTrackerData = data);
          },
          onOpenBrowser: _openBrowserWithUrl,
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
        final appInfo = allStoreApps
            .where((a) => a.id == _genericAppId)
            .firstOrNull;
        return StubApp(
          title: appInfo?.name ?? 'App',
          icon: appInfo?.icon ?? Icons.apps,
          color: appInfo?.color ?? Colors.blue,
          onBack: _goHome,
        );
    }
  }
}
