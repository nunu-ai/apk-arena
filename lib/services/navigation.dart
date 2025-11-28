import 'package:flutter/material.dart';
import '../screens/level_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void navigateToLevel(int levelNumber) {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.push(
    MaterialPageRoute(builder: (_) => LevelScreen(levelNumber: levelNumber)),
  );
}

