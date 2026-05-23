import 'package:flutter/material.dart';
import 'dart:async';
import '../models/attempt_record.dart';
import '../models/level_outcome.dart';
import '../services/progress_service.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';
import '../widgets/level_widget.dart';
import '../level_registry.dart';
import 'level_completion_screen.dart';

class LevelScreen extends StatefulWidget {
  final int levelNumber;
  final bool randomMode;

  const LevelScreen({Key? key, required this.levelNumber, this.randomMode = false}) : super(key: key);

  @override
  State<LevelScreen> createState() => _LevelScreenState();
}

class _LevelScreenState extends State<LevelScreen> {
  final _progressService = ProgressService.instance;
  final _analyticsService = AnalyticsService.instance;
  late Stopwatch _stopwatch;
  Timer? _timer;
  Timer? _sessionTimer;
  LevelEntry? _levelEntry;
  LevelWidget? _levelWidget;
  bool _finishLevelCalled = false;

  @override
  void initState() {
    super.initState();

    final entry = getLevel(widget.levelNumber);
    if (entry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return;
    }
    _levelEntry = entry;
    _levelWidget = entry.widgetBuilder(_finishLevel);

    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (mounted) setState(() {});
    });

    _sessionTimer = Timer(entry.data.timeLimit ?? const Duration(minutes: 60), () {
      if (!mounted || _finishLevelCalled) return;
      final timeoutOutcome = _levelWidget?.onTimeout?.call();
      unawaited(_finishLevel(
        LevelOutcome(
          score: timeoutOutcome?.score ?? 0,
          metrics: {
            ...?timeoutOutcome?.metrics,
            'timed_out': true,
          },
        ),
      ));
    });
  }

  @override
  void dispose() {
    _sessionTimer?.cancel();
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

  Future<bool> _confirmExitLevel() async {
    final entry = _levelEntry;
    if (entry == null) return false;

    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'EXIT LEVEL?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'exit to main menu? your best score is kept.',
          style: TextStyle(color: NunuColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL',
                style: TextStyle(color: NunuColors.secondaryMain, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () async {
              _stopwatch.stop();
              _timer?.cancel();
              _sessionTimer?.cancel();

              await _progressService.recordLevelFinish(
                widget.levelNumber,
                LevelOutcome(score: 0, metrics: {'abandoned': true}),
                _stopwatch.elapsed,
              );
              await _analyticsService.recordAttempt(AttemptRecord(
                levelNumber: widget.levelNumber,
                levelTitle: entry.data.title,
                difficulty: getDifficultyName(widget.levelNumber),
                timestamp: DateTime.now().toUtc().toIso8601String(),
                success: false,
                score: 0,
                durationMs: _stopwatch.elapsedMilliseconds,
                metrics: const {'abandoned': true},
              ));

              if (context.mounted) {
                Navigator.pop(context, true);
                Navigator.popUntil(context, (route) => route.isFirst);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.2),
              foregroundColor: NunuColors.primaryLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text(
              'EXIT',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  Future<void> _finishLevel(LevelOutcome outcome) async {
    if (_finishLevelCalled) return;
    _finishLevelCalled = true;

    _sessionTimer?.cancel();
    _stopwatch.stop();
    _timer?.cancel();

    final elapsed = _stopwatch.elapsed;

    await _progressService.recordLevelFinish(
      widget.levelNumber,
      outcome,
      elapsed,
    );

    await _analyticsService.recordAttempt(AttemptRecord(
      levelNumber: widget.levelNumber,
      levelTitle: _levelEntry!.data.title,
      difficulty: getDifficultyName(widget.levelNumber),
      timestamp: DateTime.now().toUtc().toIso8601String(),
      success: outcome.score >= 1.0,
      score: outcome.score,
      durationMs: elapsed.inMilliseconds,
      metrics: outcome.metrics.isEmpty ? null : outcome.metrics,
    ));

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelCompletionScreen(
          levelNumber: widget.levelNumber,
          levelName: _levelEntry!.data.title,
          score: outcome.score,
          completionTime: elapsed,
          metrics: outcome.metrics.isEmpty ? null : outcome.metrics,
          randomMode: widget.randomMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = _levelEntry;
    final levelWidget = _levelWidget;
    if (entry == null) {
      return const Scaffold(body: SizedBox.shrink());
    }

    return WillPopScope(
      onWillPop: () async {
        if (_finishLevelCalled) return true;
        return _confirmExitLevel();
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 48,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            iconSize: 20,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            onPressed: _confirmExitLevel,
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "LVL ${widget.levelNumber}: ${entry.data.title.toUpperCase()}",
                style: const TextStyle(
                  fontSize: 14,
                  color: NunuColors.textPrimary,
                ),
              ),
              Builder(
                builder: (_) {
                  final status = _progressService.getLevelStatus(widget.levelNumber);
                  final best = status?.bestScore;
                  if (best == null) return const SizedBox.shrink();
                  return Text(
                    'best ${(best * 100).round()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: NunuColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        body: SafeArea(
          top: false,
          left: false,
          right: false,
          bottom: true,
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: NunuColors.backgroundPaper,
                child: Text(
                  entry.data.instructions,
                  style: const TextStyle(color: NunuColors.textPrimary),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: levelWidget ?? const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
