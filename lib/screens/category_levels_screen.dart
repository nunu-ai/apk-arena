import 'package:flutter/material.dart';
import '../services/progress_service.dart';
import '../services/navigation.dart';
import '../theme/app_theme.dart';
import '../widgets/level_tile.dart';
import '../level_registry.dart';
import 'level_screen.dart';

class CategoryLevelsScreen extends StatefulWidget {
  final int categoryIndex;
  final String categoryName;
  final Color categoryColor;
  final IconData categoryIcon;

  const CategoryLevelsScreen({
    Key? key,
    required this.categoryIndex,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIcon,
  }) : super(key: key);

  @override
  State<CategoryLevelsScreen> createState() => _CategoryLevelsScreenState();
}

class _CategoryLevelsScreenState extends State<CategoryLevelsScreen> with RouteAware {
  final _progressService = ProgressService.instance;

  List<int> get levels => getLevelsForCategory(widget.categoryIndex);

  void openLevel(int levelNumber) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LevelScreen(levelNumber: levelNumber),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.categoryIcon, color: widget.categoryColor, size: 22),
            const SizedBox(width: 8),
            Text(widget.categoryName, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: levels.length,
        itemBuilder: (context, index) {
          final levelNumber = levels[index];
          final entry = getLevel(levelNumber)!;
          final status = _progressService.getLevelStatus(levelNumber);

          return LevelTile(
            levelNumber: levelNumber,
            title: entry.data.title,
            status: status,
            onTap: () => openLevel(levelNumber),
          );
        },
      ),
    );
  }
}
