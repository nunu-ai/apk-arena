import 'dart:math';
import 'package:apk_arena/screens/level_selector.dart';
import 'package:apk_arena/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'services/progress_service.dart';
import 'services/analytics_service.dart';
import 'theme/app_theme.dart';
import 'services/deeplink_service.dart';
import 'services/navigation.dart';
import 'level_registry.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await ProgressService.instance.initialize();
  await AnalyticsService.instance.initialize();

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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uri = await DeeplinkService.instance.getInitialLink();
      if (uri != null) {
        _handleUri(uri);
      }
      DeeplinkService.instance.linkStream.listen((uri) {
        _handleUri(uri);
      });
    });
  }

  void _handleUri(Uri uri) {
    final s = uri.toString();
    if (_lastHandledUri == s) return;
    _lastHandledUri = s;
    final link = _parseLevelLink(uri);
    if (link != null) {
      navigateToLevel(link.levelNumber, attemptsRemaining: link.attemptsRemaining);
    }
  }

  _LevelLink? _parseLevelLink(Uri uri) {
    if (uri.scheme != 'apkarena') return null;

    final attempts = int.tryParse(uri.queryParameters['attempts'] ?? '');

    // Preferred: apkarena://open/level/123  or  apkarena://open/random  or  apkarena://open/level/random
    if (uri.host == 'open') {
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'random') {
        final id = _randomLevelId();
        return id != null ? _LevelLink(id, attempts) : null;
      }
      if (uri.pathSegments.length >= 2 && uri.pathSegments.first == 'level') {
        final seg = uri.pathSegments[1];
        if (seg == 'random') {
          final id = _randomLevelId();
          return id != null ? _LevelLink(id, attempts) : null;
        }
        final id = int.tryParse(seg);
        return id != null ? _LevelLink(id, attempts) : null;
      }
      return null;
    }
    // Path-only variant: apkarena:/open/level/123  or  apkarena:/open/random  or  apkarena:/open/level/random
    if (uri.pathSegments.isNotEmpty && uri.pathSegments[0] == 'open') {
      if (uri.pathSegments.length >= 2 && uri.pathSegments[1] == 'random') {
        final id = _randomLevelId();
        return id != null ? _LevelLink(id, attempts) : null;
      }
      if (uri.pathSegments.length >= 3 && uri.pathSegments[1] == 'level') {
        final seg = uri.pathSegments[2];
        if (seg == 'random') {
          final id = _randomLevelId();
          return id != null ? _LevelLink(id, attempts) : null;
        }
        final id = int.tryParse(seg);
        return id != null ? _LevelLink(id, attempts) : null;
      }
    }
    return null;
  }

  int? _randomLevelId() {
    final all = getAvailableLevels();
    if (all.isEmpty) return null;
    return all[Random().nextInt(all.length)];
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

class _LevelLink {
  final int levelNumber;
  final int? attemptsRemaining;
  const _LevelLink(this.levelNumber, this.attemptsRemaining);
}
