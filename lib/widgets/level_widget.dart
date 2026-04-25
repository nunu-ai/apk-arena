import 'package:flutter/material.dart';
import '../models/level_outcome.dart';

abstract class LevelWidget extends StatefulWidget {
  static final Expando<LevelOutcome Function()> _timeoutBuilders =
      Expando<LevelOutcome Function()>();
  final void Function(LevelOutcome outcome) onComplete;

  const LevelWidget({Key? key, required this.onComplete}) : super(key: key);

  LevelOutcome Function()? get onTimeout => _timeoutBuilders[this];

  void registerTimeoutBuilder(LevelOutcome Function() builder) {
    _timeoutBuilders[this] = builder;
  }

  void clearTimeoutBuilder() {
    _timeoutBuilders[this] = null;
  }
}
