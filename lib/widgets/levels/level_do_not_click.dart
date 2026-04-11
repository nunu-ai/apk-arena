import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelDoNotClick extends LevelWidget {
  const LevelDoNotClick({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelDoNotClick> createState() => _LevelDoNotClickState();
}

class _LevelDoNotClickState extends State<LevelDoNotClick> {
  static const int _totalSeconds = 60;
  int _remainingSeconds = _totalSeconds;
  bool _failed = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _failed) return;
      if (_remainingSeconds <= 1) {
        t.cancel();
        widget.onComplete(LevelOutcome(score: 1));
      } else {
        _remainingSeconds -= 1;
      }
    });
  }

  void _onButtonPressed() {
    if (_failed) return;
    _timer?.cancel();
    setState(() {
      _failed = true;
    });
    widget.onComplete(LevelOutcome(score: 0));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ElevatedButton(
          onPressed: (_failed || _remainingSeconds <= 0) ? null : _onButtonPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: NunuColors.errorMain,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 28),
            textStyle: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(color: Colors.white),
            minimumSize: const Size(260, 100),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text("don't click me"),
        ),
      ),
    );
  }
}
