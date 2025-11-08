import 'package:flutter/material.dart';

abstract class LevelWidget extends StatefulWidget {
  final Function(bool success) onComplete;

  const LevelWidget({Key? key, required this.onComplete}) : super(key: key);
}