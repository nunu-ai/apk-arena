import 'package:flutter/material.dart';
import '../models/level_outcome.dart';

abstract class LevelWidget extends StatefulWidget {
  final void Function(LevelOutcome outcome) onComplete;

  const LevelWidget({Key? key, required this.onComplete}) : super(key: key);
}
