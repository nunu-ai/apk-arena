import 'package:apk_arena/screens/level_selector.dart';
import 'package:flutter/material.dart';
import 'theme/app_theme.dart';

void main() {
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