import 'package:apk_arena/screens/level_selector.dart';
import 'package:apk_arena/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';
import 'services/deeplink_service.dart';
import 'services/navigation.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await ProgressService.instance.initialize();

  await NotificationService().initialize();
  await DeeplinkService.instance.initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _lastHandledUri;
  @override
  void initState() {
    super.initState();
    // Handle initial deep link after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = await DeeplinkService.instance.getInitialLink();
      if (uri != null) {
        _handleUri(uri);
      }
      // Subscribe to runtime links
      DeeplinkService.instance.linkStream.listen((uri) {
        _handleUri(uri);
      });
    });
  }

  void _handleUri(Uri uri) {
    final s = uri.toString();
    if (_lastHandledUri == s) return; // dedupe same link
    _lastHandledUri = s;
    final id = _extractLevelId(uri);
    if (id != null) navigateToLevel(id);
  }

  int? _extractLevelId(Uri uri) {
    if (uri.scheme != 'apkarena') return null;
    // Preferred: apkarena://open/level/123
    if (uri.host == 'open') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'level') {
        return int.tryParse(uri.pathSegments[1]);
      }
      return null;
    }
    // Path-only variant: apkarena:/open/level/123
    if (uri.pathSegments.length >= 3 && uri.pathSegments[0] == 'open' && uri.pathSegments[1] == 'level') {
      return int.tryParse(uri.pathSegments[2]);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AOK ARENA',
      theme: AppTheme.darkTheme,
      navigatorKey: appNavigatorKey,
      navigatorObservers: [routeObserver],
      home: const LevelSelectorScreen(),
    );
  }
}
