import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

/// Player stats for profile
class PlayerStats {
  final int totalMerges;
  final int highestTier;
  final int ordersCompleted;
  final int totalCoinsEarned;
  final int levelsReached;

  const PlayerStats({
    this.totalMerges = 0,
    this.highestTier = 1,
    this.ordersCompleted = 0,
    this.totalCoinsEarned = 0,
    this.levelsReached = 1,
  });
}

/// Achievement data
class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final bool isUnlocked;
  final Color color;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.isUnlocked,
    required this.color,
  });
}

/// Full profile page with avatar, stats, and achievements
class ProfilePage extends StatefulWidget {
  final int playerLevel;
  final PlayerStats stats;
  final int selectedAvatar;
  final Function(int avatar) onAvatarChanged;

  const ProfilePage({
    Key? key,
    required this.playerLevel,
    required this.stats,
    required this.selectedAvatar,
    required this.onAvatarChanged,
  }) : super(key: key);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const List<IconData> _avatarIcons = [
    Icons.person,
    Icons.face,
    Icons.face_2,
    Icons.face_3,
    Icons.face_4,
    Icons.face_5,
    Icons.face_6,
    Icons.smart_toy,
    Icons.pets,
    Icons.rocket_launch,
    Icons.emoji_emotions,
    Icons.psychology,
  ];

  static const List<Color> _avatarColors = [
    NunuColors.primaryMain,
    NunuColors.secondaryMain,
    NunuColors.successMain,
    NunuColors.infoMain,
    Colors.orange,
    Colors.teal,
    Colors.pink,
    Colors.purple,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.indigo,
  ];

  List<Achievement> _getAchievements() {
    return [
      Achievement(
        id: 'first_merge',
        name: 'first merge',
        description: 'merge your first items',
        icon: Icons.merge_type,
        isUnlocked: widget.stats.totalMerges >= 1,
        color: const Color(0xFFCD7F32),
      ),
      Achievement(
        id: 'merge_master',
        name: 'merge master',
        description: 'complete 50 merges',
        icon: Icons.auto_awesome,
        isUnlocked: widget.stats.totalMerges >= 50,
        color: Colors.amber,
      ),
      Achievement(
        id: 'tier_hunter',
        name: 'tier hunter',
        description: 'reach tier 5',
        icon: Icons.trending_up,
        isUnlocked: widget.stats.highestTier >= 5,
        color: Colors.purple,
      ),
      Achievement(
        id: 'max_tier',
        name: 'max tier',
        description: 'reach tier 8',
        icon: Icons.rocket_launch,
        isUnlocked: widget.stats.highestTier >= 8,
        color: Colors.pink,
      ),
      Achievement(
        id: 'first_order',
        name: 'first delivery',
        description: 'complete your first order',
        icon: Icons.local_shipping,
        isUnlocked: widget.stats.ordersCompleted >= 1,
        color: Colors.green,
      ),
      Achievement(
        id: 'order_streak',
        name: 'delivery streak',
        description: 'complete 10 orders',
        icon: Icons.verified,
        isUnlocked: widget.stats.ordersCompleted >= 10,
        color: Colors.blue,
      ),
      Achievement(
        id: 'level_5',
        name: 'rising star',
        description: 'reach level 5',
        icon: Icons.stars,
        isUnlocked: widget.stats.levelsReached >= 5,
        color: Colors.orange,
      ),
      Achievement(
        id: 'level_10',
        name: 'factory boss',
        description: 'reach level 10',
        icon: Icons.emoji_events,
        isUnlocked: widget.stats.levelsReached >= 10,
        color: Colors.amber,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final achievements = _getAchievements();
    final unlockedCount = achievements.where((a) => a.isUnlocked).length;

    return Scaffold(
      backgroundColor: NunuColors.backgroundDefault,
      appBar: AppBar(
        backgroundColor: NunuColors.backgroundPaper,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'profile',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar Section
            Center(
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _avatarColors[widget.selectedAvatar % _avatarColors.length],
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _avatarColors[widget.selectedAvatar % _avatarColors.length]
                              .withOpacity(0.5),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _avatarIcons[widget.selectedAvatar % _avatarIcons.length],
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'level ${widget.playerLevel}',
                    style: const TextStyle(
                      color: NunuColors.primaryMain,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Avatar Selection
            const Text(
              'choose avatar',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 60,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _avatarIcons.length,
                itemBuilder: (context, index) {
                  final isSelected = index == widget.selectedAvatar;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      widget.onAvatarChanged(index);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _avatarColors[index % _avatarColors.length]
                            .withOpacity(isSelected ? 1.0 : 0.3),
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _avatarIcons[index],
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),

            // Stats Section
            const Text(
              'stats',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildStatRow(Icons.merge_type, 'total merges', '${widget.stats.totalMerges}'),
                  const Divider(color: Colors.white12),
                  _buildStatRow(Icons.trending_up, 'highest tier', '${widget.stats.highestTier}'),
                  const Divider(color: Colors.white12),
                  _buildStatRow(Icons.local_shipping, 'orders completed', '${widget.stats.ordersCompleted}'),
                  const Divider(color: Colors.white12),
                  _buildStatRow(Icons.monetization_on, 'coins earned', '${widget.stats.totalCoinsEarned}'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Achievements Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'achievements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$unlockedCount / ${achievements.length}',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 0.8,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: achievements.length,
              itemBuilder: (context, index) {
                final achievement = achievements[index];
                return _buildAchievementTile(achievement);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: NunuColors.primaryMain, size: 20),
          const SizedBox(width: 12),
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementTile(Achievement achievement) {
    return Tooltip(
      message: '${achievement.name}: ${achievement.description}',
      child: Container(
        decoration: BoxDecoration(
          color: achievement.isUnlocked
              ? achievement.color.withOpacity(0.2)
              : NunuColors.backgroundPaper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: achievement.isUnlocked
                ? achievement.color
                : Colors.white24,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement.icon,
              color: achievement.isUnlocked ? achievement.color : Colors.white24,
              size: 28,
            ),
            const SizedBox(height: 4),
            Text(
              achievement.name.split(' ').first,
              style: TextStyle(
                color: achievement.isUnlocked ? Colors.white : Colors.white38,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


