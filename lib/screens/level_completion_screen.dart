import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../level_registry.dart';
import 'level_screen.dart';

class LevelCompletionScreen extends StatelessWidget {
  final int levelNumber;
  final String levelName;
  final Duration completionTime;
  final double score;
  final Map<String, dynamic>? metrics;
  final Set<String>? visibleMetricKeys;
  final bool randomMode;
  // null = normal mode; 0 = locked, no retries left; >0 = locked, retries available
  final int? attemptsRemaining;

  const LevelCompletionScreen({
    Key? key,
    required this.levelNumber,
    required this.levelName,
    required this.score,
    required this.completionTime,
    this.metrics,
    this.visibleMetricKeys,
    this.randomMode = false,
    this.attemptsRemaining,
  }) : super(key: key);

  String get formattedTime {
    final minutes = completionTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (completionTime.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((completionTime.inMilliseconds % 1000) ~/ 100)
        .toString();
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatMetricKey(String key) {
    return key.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildMetricsGrid() {
    final entries = _visibleMetrics.entries.toList();
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      alignment: WrapAlignment.center,
      children: entries.map((e) {
        return Container(
          width: 130,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5)),
          ),
          child: Column(
            children: [
              Text(
                _formatMetricKey(e.key),
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                '${e.value}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.primaryLight,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Map<String, dynamic> get _visibleMetrics {
    final rawMetrics = metrics;
    if (rawMetrics == null || rawMetrics.isEmpty) return const {};
    final keys = visibleMetricKeys;
    if (keys == null) return rawMetrics;

    return {
      for (final entry in rawMetrics.entries)
        if (keys.contains(entry.key)) entry.key: entry.value,
    };
  }

  int? get nextLevelNumber {
    if (randomMode) {
      final all = getAvailableLevels();
      if (all.isEmpty) return null;
      return all[Random().nextInt(all.length)];
    }
    return getNextSequentialLevel(levelNumber);
  }

  Color get _accentColor {
    if (score >= 0.85) return NunuColors.successMain;
    if (score >= 0.5) return NunuColors.warningMain;
    return NunuColors.errorMain;
  }

  String get _emoji {
    if (score >= 0.85) return '🎉';
    if (score >= 0.5) return '✨';
    return '💔';
  }

  @override
  Widget build(BuildContext context) {
    final pct = (score * 100).round();

    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_emoji, style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              Text(
                'SCORE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.textSecondary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _accentColor,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LVL ${levelNumber}: ${levelName.toUpperCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  color: NunuColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: NunuColors.backgroundPaper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: NunuColors.secondaryLight,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      'TIME',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              if (_visibleMetrics.isNotEmpty) ...[
                const SizedBox(height: 16),
                _buildMetricsGrid(),
              ],
              const SizedBox(height: 36),
              if (attemptsRemaining == null) ...[
                // Normal mode: main menu + next/random
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FilledButton(
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);
                      },
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        foregroundColor: NunuColors.secondaryLight,
                        backgroundColor: NunuColors.secondaryMain.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'MAIN MENU',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: nextLevelNumber != null
                          ? () {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LevelScreen(
                                    levelNumber: nextLevelNumber!,
                                    randomMode: randomMode,
                                  ),
                                ),
                                (route) => route.isFirst,
                              );
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        foregroundColor: NunuColors.primaryLight,
                        backgroundColor: NunuColors.primaryMain.withValues(
                          alpha: 0.4,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        randomMode ? 'RANDOM' : 'NEXT',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ] else if (attemptsRemaining! > 0) ...[
                // Locked mode with retries remaining
                Text(
                  '$attemptsRemaining ${attemptsRemaining == 1 ? 'ATTEMPT' : 'ATTEMPTS'} LEFT',
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LevelScreen(
                          levelNumber: levelNumber,
                          attemptsRemaining: attemptsRemaining,
                        ),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    foregroundColor: NunuColors.primaryLight,
                    backgroundColor: NunuColors.primaryMain.withValues(
                      alpha: 0.4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'RETRY',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ] else ...[
                // Locked mode, no attempts left
                const Text(
                  'NO MORE ATTEMPTS',
                  style: TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
        ),
      ),
    );
  }
}
