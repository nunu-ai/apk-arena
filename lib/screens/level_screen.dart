import 'package:flutter/material.dart';
import 'dart:async';
import '../models/level_status.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../../level_registry.dart';
import 'level_completion_screen.dart';
import 'level_selector.dart';

class LevelScreen extends StatefulWidget {
  final int levelNumber;

  const LevelScreen({Key? key, required this.levelNumber}) : super(key: key);

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final _progressService = ProgressService.instance;
  late Stopwatch _stopwatch;
  Timer? _timer;
  late LevelEntry levelEntry;

  @override
  void initState() {
    super.initState();

    final entry = getLevel(widget.levelNumber);
    if (entry == null) {
      // Handle missing level
      Navigator.pop(context);
      return;
    }
    levelEntry = entry;

    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  String get elapsedTime {
    final elapsed = _stopwatch.elapsed;
    final minutes = elapsed.inMinutes.toString().padLeft(2, '0');
    final seconds = (elapsed.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((elapsed.inMilliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$milliseconds';
  }

  void _showGiveUpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GIVE UP?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('are you sure you want to give up on this level?',
            style: TextStyle(color: NunuColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: NunuColors.secondaryMain, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () async {
              await _progressService.completeLevel(
                widget.levelNumber,
                LevelResult.failed,
                null, // No completion time for failed attempts
              );
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LevelSelectorScreen()),
                    (route) => false, // Remove all routes
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.2),
              foregroundColor: NunuColors.primaryLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('GIVE UP', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onLevelComplete(bool success) async {
    _stopwatch.stop();
    _timer?.cancel();

    await _progressService.completeLevel(
      widget.levelNumber,
      success ? LevelResult.success : LevelResult.failed,
      success ? _stopwatch.elapsed : null,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelCompletionScreen(
          levelNumber: widget.levelNumber,
          levelName: levelEntry.data.title,
          success: success,
          completionTime: success ? _stopwatch.elapsed : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _showGiveUpDialog,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("LVL ${widget.levelNumber}: ${levelEntry.data.title.toUpperCase()}",
                style: const TextStyle(fontSize: 16, color: NunuColors.textPrimary)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Instructions banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: NunuColors.backgroundPaper,
            child: Text(
              levelEntry.data.instructions,
              style: const TextStyle(color: NunuColors.textPrimary),
            ),
          ),
          const Divider(height: 1),

          // Level content
          Expanded(
            child: levelEntry.widgetBuilder(_onLevelComplete),
          ),
        ],
      ),
    );
  }
}