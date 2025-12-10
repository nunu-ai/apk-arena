import 'package:flutter/material.dart';
import 'dart:async';
import '../models/level_status.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../../level_registry.dart';
import 'level_completion_screen.dart';

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
    final status = _progressService.getLevelStatus(widget.levelNumber);
    final alreadyCompleted = status?.result == LevelResult.success;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          alreadyCompleted ? 'EXIT LEVEL?' : 'GIVE UP?',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          alreadyCompleted
              ? 'exit to main menu? your completion stays recorded.'
              : 'are you sure you want to give up on this level?',
          style: const TextStyle(color: NunuColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL',
                style: TextStyle(color: NunuColors.secondaryMain, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () async {
              if (!alreadyCompleted) {
                await _progressService.completeLevel(
                  widget.levelNumber,
                  LevelResult.failed,
                  null, // No completion time for failed attempts
                );
              }
              Navigator.popUntil(context, (route) => route.isFirst);
            },
            style: FilledButton.styleFrom(
              backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.2),
              foregroundColor: NunuColors.primaryLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(
              alreadyCompleted ? 'EXIT' : 'GIVE UP',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
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
        toolbarHeight: 48,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          iconSize: 20,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          onPressed: _showGiveUpDialog,
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (_) {
                final status = _progressService.getLevelStatus(widget.levelNumber);
                final isCompleted = status?.result == LevelResult.success;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "LVL ${widget.levelNumber}: ${levelEntry.data.title.toUpperCase()}",
                      style: const TextStyle(
                        fontSize: 14,
                        color: NunuColors.textPrimary,
                      ),
                    ),
                    if (isCompleted) ...[
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.check_circle,
                        size: 16,
                        color: NunuColors.successLight,
                      )
                    ]
                  ],
                );
              },
            ),
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
