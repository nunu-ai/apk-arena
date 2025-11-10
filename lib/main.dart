import 'package:apk_arena/screens/level_selector.dart';
import 'package:apk_arena/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'services/progress_service.dart';
import 'theme/app_theme.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await ProgressService.instance.initialize();

  await NotificationService().initialize();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AOK ARENA',
      theme: AppTheme.darkTheme,
      home: const LevelSelectorScreen(),
    );
  }
}