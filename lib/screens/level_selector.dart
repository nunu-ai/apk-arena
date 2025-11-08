import 'package:flutter/material.dart';
import '../models/level_status.dart';
import '../services/progress_service.dart';
import '../theme/app_theme.dart';
import '../widgets/level_tile.dart';
import '../level_registry.dart';
import 'level_screen.dart';

class LevelSelectorScreen extends StatefulWidget {
  const LevelSelectorScreen({Key? key}) : super(key: key);

  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> {
  final _progressService = ProgressService.instance;

  int selectedDifficulty = 0;

  final Map<int, String> difficultyNames = {
    0: 'baby',
    1: 'human',
    2: 'agi',
  };

  List<int> get visibleLevels {
    return getLevelsForDifficulty(selectedDifficulty);
  }

  void resetProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RESET ALL LEVELS', style: TextStyle(fontWeight: FontWeight.bold),),
        content: const Text('are you sure you want to reset all progress?', style: TextStyle(color: NunuColors.textSecondary),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL', style: TextStyle(color: NunuColors.secondaryMain, fontWeight: FontWeight.bold)),
          ),
          FilledButton(
            onPressed: () {
              _progressService.resetAllProgress();
              setState(() {});
              Navigator.pop(context);
            },
            style: FilledButton.styleFrom(
              backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.2),
              foregroundColor: NunuColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold),),
          ),
        ],
      ),
    );
  }

  void openLevel(int levelNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelScreen(levelNumber: levelNumber),
      ),
    ).then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APK ARENA', style: TextStyle(fontWeight: FontWeight.bold),),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: resetProgress,
            tooltip: 'reset progress',
          ),
        ],
      ),
      body: Column(
        children: [
          // Difficulty chips at the top
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              children: difficultyNames.entries.map((entry) {
                final isSelected = selectedDifficulty == entry.key;
                return ChoiceChip(
                  label: Text(entry.value),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedDifficulty = entry.key;
                      });
                    }
                  },
                  showCheckmark: false,
                  backgroundColor: NunuColors.backgroundPaper,
                  selectedColor: NunuColors.backgroundPaper,
                  labelStyle: TextStyle(
                    color: isSelected ? NunuColors.textPrimary : NunuColors.textSecondary
                  ),
                  side: BorderSide(
                    color: isSelected ? NunuColors.primaryMain : NunuColors.textPrimary.withValues(alpha: 0.2),
                    width: 2
                  )
                );
              }).toList(),
            ),
          ),
          
          // Grid of levels
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5, // 5 levels per row
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1, // Square tiles
              ),
              itemCount: visibleLevels.length,
              itemBuilder: (context, index) {
                final levelNumber = visibleLevels[index];
                final status = _progressService.getLevelStatus(levelNumber);

                return LevelTile(
                  levelNumber: levelNumber,
                  status: status,
                  onTap: () => openLevel(levelNumber),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}