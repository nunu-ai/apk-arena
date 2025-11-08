import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/level_tile.dart';

class LevelSelectorScreen extends StatefulWidget {
  const LevelSelectorScreen({Key? key}) : super(key: key);

  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> {
  Set<int> completedLevels = {1, 5, 12, 23};

  String selectedDifficulty = 'baby';

  final Map<String, List<int>> difficulties = {
    'baby': [0, 45],
    'human': [100, 167],
    'agi': [200, 234],
  };

  List<int> get visibleLevels {
    final range = difficulties[selectedDifficulty]!;
    return List.generate(
      range[1] - range[0] + 1,
          (index) => range[0] + index,
    );
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
              setState(() {
                completedLevels.clear();
              });
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
    // TODO: Navigate to your level screen
    print('opening level $levelNumber');
    // Example: Navigator.push(context, MaterialPageRoute(builder: (context) => LevelScreen(levelNumber: levelNumber)));
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
              children: difficulties.keys.map((difficulty) {
                final isSelected = selectedDifficulty == difficulty;
                return ChoiceChip(
                  label: Text(difficulty),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        selectedDifficulty = difficulty;
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

          const Divider(height: 1),

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
                final isCompleted = completedLevels.contains(levelNumber);

                return LevelTile(
                  levelNumber: levelNumber,
                  isCompleted: isCompleted,
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