
import 'dart:math';
import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../services/navigation.dart';
import '../theme/app_theme.dart';
import '../level_registry.dart';
import 'level_screen.dart';
import 'category_levels_screen.dart';

class _CategoryInfo {
  final int index;
  final String name;
  final IconData icon;
  final Color color;

  const _CategoryInfo({
    required this.index,
    required this.name,
    required this.icon,
    required this.color,
  });
}

const _categories = [
  _CategoryInfo(index: 0, name: 'primitives', icon: Icons.touch_app_rounded, color: NunuColors.secondaryLight),
  _CategoryInfo(index: 1, name: 'vision', icon: Icons.visibility_rounded, color: NunuColors.secondaryLight),
  _CategoryInfo(index: 2, name: 'memory', icon: Icons.psychology_rounded, color: NunuColors.secondaryLight),
  _CategoryInfo(index: 3, name: 'iq', icon: Icons.lightbulb_rounded, color: NunuColors.secondaryLight),
  _CategoryInfo(index: 4, name: 'tempospatial', icon: Icons.speed_rounded, color: NunuColors.secondaryLight),
  _CategoryInfo(index: 5, name: 'games', icon: Icons.sports_esports_rounded, color: NunuColors.secondaryLight),
  _CategoryInfo(index: 6, name: 'tasks', icon: Icons.checklist_rounded, color: NunuColors.secondaryLight),
];

class LevelSelectorScreen extends StatefulWidget {
  const LevelSelectorScreen({Key? key}) : super(key: key);

  @override
  State<LevelSelectorScreen> createState() => _LevelSelectorScreenState();
}

class _LevelSelectorScreenState extends State<LevelSelectorScreen> with RouteAware {
  final _progressService = ProgressService.instance;

  void resetProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('RESET ALL LEVELS', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('are you sure you want to reset all progress?', style: TextStyle(color: NunuColors.textSecondary)),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('RESET', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void openCategory(_CategoryInfo cat) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryLevelsScreen(
          categoryIndex: cat.index,
          categoryName: cat.name,
          categoryColor: cat.color,
          categoryIcon: cat.icon,
        ),
      ),
    );
    setState(() {});
  }

  void openRandomLevel() async {
    final all = getAvailableLevels();
    if (all.isEmpty) return;
    final levelNumber = all[Random().nextInt(all.length)];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelScreen(levelNumber: levelNumber, randomMode: true),
      ),
    );
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    setState(() {});
  }

  String _levelRange(int catIndex) {
    final levels = getLevelsForCategory(catIndex);
    if (levels.isEmpty) return 'empty';
    return '${levels.first}–${levels.last}';
  }

  double _categoryProgress(int catIndex) {
    final levels = getLevelsForCategory(catIndex);
    if (levels.isEmpty) return 0;
    int completed = 0;
    for (final l in levels) {
      final s = _progressService.getLevelStatus(l);
      if (s != null && (s.bestScore ?? 0) > 0) completed++;
    }
    return completed / levels.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('APK ARENA', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final levels = getLevelsForCategory(cat.index);
                final progress = _categoryProgress(cat.index);

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: levels.isEmpty ? null : () => openCategory(cat),
                  child: Container(
                    decoration: BoxDecoration(
                      color: NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: levels.isEmpty
                            ? cat.color.withValues(alpha: 0.15)
                            : cat.color.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(cat.icon, color: cat.color, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                cat.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: levels.isEmpty
                                      ? NunuColors.textSecondary.withValues(alpha: 0.4)
                                      : NunuColors.secondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _levelRange(cat.index),
                              style: TextStyle(
                                fontSize: 12,
                                color: levels.isEmpty
                                    ? NunuColors.textSecondary.withValues(alpha: 0.3)
                                    : NunuColors.textSecondary,
                              ),
                            ),
                            if (levels.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(2),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: cat.color.withValues(alpha: 0.1),
                                  valueColor: AlwaysStoppedAnimation(cat.color),
                                  minHeight: 4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // random level button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed: openRandomLevel,
                icon: const Icon(Icons.casino_rounded),
                label: const Text('random level', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: FilledButton.styleFrom(
                  backgroundColor: NunuColors.primaryMain.withValues(alpha: 0.15),
                  foregroundColor: NunuColors.primaryLight,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
