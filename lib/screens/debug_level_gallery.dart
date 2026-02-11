import 'package:flutter/material.dart';
import '../level_registry.dart';
import '../theme/app_theme.dart';
import 'level_screen.dart';

class DebugLevelGallery extends StatelessWidget {
  const DebugLevelGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final allLevels = levelsRegistry.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final easyLevels = allLevels.where((e) => e.key < 100).toList();
    final mediumLevels = allLevels.where((e) => e.key >= 100 && e.key < 200).toList();
    final hardLevels = allLevels.where((e) => e.key >= 200).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('DEBUG: LEVEL GALLERY'),
      ),
      body: CustomScrollView(
        slivers: [
          if (easyLevels.isNotEmpty) ...[
            _buildHeader('EASY LEVELS (0-99)', NunuColors.successMain),
            _buildGrid(context, easyLevels),
          ],
          if (mediumLevels.isNotEmpty) ...[
            _buildHeader('MEDIUM LEVELS (100-199)', NunuColors.warningMain),
            _buildGrid(context, mediumLevels),
          ],
          if (hardLevels.isNotEmpty) ...[
            _buildHeader('HARD LEVELS (200+)', NunuColors.errorMain),
            _buildGrid(context, hardLevels),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, Color color) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 24,
              color: color,
              margin: const EdgeInsets.only(right: 8),
            ),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, List<MapEntry<int, LevelEntry>> levels) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.6,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final entry = levels[index];
            final levelNumber = entry.key;
            final levelEntry = entry.value;

            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LevelScreen(levelNumber: levelNumber),
                  ),
                );
              },
              child: Card(
                clipBehavior: Clip.antiAlias,
                color: NunuColors.backgroundPaper,
                elevation: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(8),
                      color: NunuColors.backgroundDefault,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#$levelNumber',
                            style: const TextStyle(
                              color: NunuColors.primaryMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            levelEntry.data.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Preview
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.white.withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Stack(
                          children: [
                            // The Level Preview
                            Positioned.fill(
                              child: IgnorePointer(
                                child: FittedBox(
                                  fit: BoxFit.contain,
                                  child: SizedBox(
                                    width: 360, // Standard-ish mobile width
                                    height: 640, // Standard-ish mobile height
                                    child: Theme(
                                      data: AppTheme.darkTheme,
                                      child: Scaffold(
                                        body: levelEntry.widgetBuilder((_, {Map<String, dynamic>? metrics}) {}),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Shadow overlay (gradient) to give it that "shadowed" look
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.3),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
          childCount: levels.length,
        ),
      ),
    );
  }
}
