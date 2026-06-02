import 'package:flutter/material.dart';
import '../models/level_outcome.dart';

abstract class LevelWidget extends StatefulWidget {
  static final Expando<LevelOutcome Function()> _partialScoreGetters =
      Expando<LevelOutcome Function()>();
  final void Function(LevelOutcome outcome) onComplete;

  const LevelWidget({Key? key, required this.onComplete}) : super(key: key);

  LevelOutcome Function()? get partialScoreGetter => _partialScoreGetters[this];

  void registerPartialScoreGetter(LevelOutcome Function() getter) {
    _partialScoreGetters[this] = getter;
  }

  void clearPartialScoreGetter() {
    _partialScoreGetters[this] = null;
  }
}
