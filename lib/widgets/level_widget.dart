import 'package:flutter/material.dart';

abstract class LevelWidget extends StatefulWidget {
  final Function(bool success, {Map<String, dynamic>? metrics}) onComplete;

  const LevelWidget({Key? key, required this.onComplete}) : super(key: key);
}
