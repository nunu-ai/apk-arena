import 'package:flutter/material.dart';
import '../screens/level_screen.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final RouteObserver<ModalRoute<void>> routeObserver = RouteObserver<ModalRoute<void>>();

void navigateToLevel(int levelNumber) {
  final navigator = appNavigatorKey.currentState;
  if (navigator == null) return;
  navigator.push(
    MaterialPageRoute(builder: (_) => LevelScreen(levelNumber: levelNumber)),
  );
}
