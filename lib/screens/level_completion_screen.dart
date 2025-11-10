import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../level_registry.dart';
import 'level_screen.dart';
import 'level_selector.dart';

class LevelCompletionScreen extends StatelessWidget {
  final int levelNumber;
  final String levelName;
  final Duration completionTime;

  const LevelCompletionScreen({
    Key? key,
    required this.levelNumber,
    required this.levelName,
    required this.completionTime,
  }) : super(key: key);

  String get formattedTime {
    final minutes = completionTime.inMinutes.toString().padLeft(2, '0');
    final seconds = (completionTime.inSeconds % 60).toString().padLeft(2, '0');
    final milliseconds = ((completionTime.inMilliseconds % 1000) ~/ 100).toString();
    return '$minutes:$seconds.$milliseconds';
  }

  int? get nextLevelNumber {
    final allLevels = getAvailableLevels();
    final currentIndex = allLevels.indexOf(levelNumber);
    if (currentIndex != -1 && currentIndex < allLevels.length - 1) {
      return allLevels[currentIndex + 1];
    }
    return null;
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
              const Text('🎉', style: TextStyle(fontSize: 80)),
              const SizedBox(height: 24),
              const Text(
                'LEVEL COMPLETE!',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.primaryMain,
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
              const SizedBox(height: 36),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(builder: (context) => const LevelSelectorScreen()),
                            (route) => false, // Remove all routes
                      );
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
                            (route) => false,
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
                    child: const Text('NEXT LEVEL',
                        style: TextStyle(fontWeight: FontWeight.bold)),
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