import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../level_registry.dart';
import '../services/progress_service.dart';
import 'level_screen.dart';

class LevelCompletionScreen extends StatelessWidget {
  final int levelNumber;
  final String levelName;
  final Duration? completionTime;
  final bool success;
  final Map<String, dynamic>? metrics;

  const LevelCompletionScreen({
    Key? key,
    required this.levelNumber,
    required this.levelName,
    required this.success,
    this.completionTime,
    this.metrics,
  }) : super(key: key);

  String get formattedTime {
    if (completionTime == null) return '--:--.--';
    final minutes = completionTime!.inMinutes.toString().padLeft(2, '0');
    final seconds = (completionTime!.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((completionTime!.inMilliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$milliseconds';
  }

  String _formatMetricKey(String key) {
    return key.replaceAll('_', ' ').toUpperCase();
  }

  Widget _buildMetricsGrid() {
    final entries = metrics!.entries.toList();
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
            border: Border.all(
              color: NunuColors.primaryDark.withOpacity(0.5),
            ),
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

  int? get nextLevelNumber {
    final allLevels = getAvailableLevels();
    return ProgressService.instance.nextUncompletedLevel(allLevels, levelNumber);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                success ? '🎉' : '💔',
                style: const TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),
              Text(
                success ? 'LEVEL COMPLETE!' : 'LEVEL FAILED',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: success ? NunuColors.primaryMain : NunuColors.errorMain,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'LVL ${levelNumber}: ${levelName.toUpperCase()}',
                style: const TextStyle(
                  fontSize: 20,
                  color: NunuColors.textPrimary,
                ),
              ),
              const SizedBox(height: 32),
              if (success) ...[
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: NunuColors.secondaryLight, width: 2),
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
                if (metrics != null && metrics!.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildMetricsGrid(),
                ],
                const SizedBox(height: 36),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      foregroundColor: NunuColors.secondaryLight,
                      backgroundColor: NunuColors.secondaryMain.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('MAIN MENU',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 16),
                  FilledButton(
                    onPressed: nextLevelNumber != null
                        ? () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LevelScreen(levelNumber: nextLevelNumber!),
                        ),
                        (route) => route.isFirst,
                      );
                    }
                        : null,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      foregroundColor: NunuColors.primaryLight,
                      backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'NEXT LEVEL',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
