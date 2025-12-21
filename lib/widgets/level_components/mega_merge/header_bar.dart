import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Header bar with level, coins, energy, and hamburger menu
class MegaMergeHeaderBar extends StatelessWidget {
  final int playerLevel;
  final int currentXP;
  final int xpForNextLevel;
  final int coins;
  final int energy;
  final int maxEnergy;
  final VoidCallback onMenuPressed;
  final GlobalKey? energyKey;
  final GlobalKey? coinsKey;
  final GlobalKey? menuKey;

  const MegaMergeHeaderBar({
    Key? key,
    required this.playerLevel,
    required this.currentXP,
    required this.xpForNextLevel,
    required this.coins,
    required this.energy,
    required this.maxEnergy,
    required this.onMenuPressed,
    this.energyKey,
    this.coinsKey,
    this.menuKey,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLowEnergy = energy < 5;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Level & XP
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: NunuColors.primaryMain,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'lv $playerLevel',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: currentXP / xpForNextLevel,
                            backgroundColor: NunuColors.backgroundDefault,
                            valueColor: const AlwaysStoppedAnimation(
                              NunuColors.secondaryMain,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$currentXP / $xpForNextLevel xp',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Coins
            Container(
              key: coinsKey,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    _formatNumber(coins),
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Energy
            Container(
              key: energyKey,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isLowEnergy
                      ? NunuColors.errorMain.withOpacity(0.5)
                      : Colors.yellow.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flash_on,
                    color: isLowEnergy ? NunuColors.errorMain : Colors.yellow,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$energy',
                    style: TextStyle(
                      color: isLowEnergy ? NunuColors.errorMain : Colors.yellow,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Hamburger Menu
            Container(
              key: menuKey,
              decoration: BoxDecoration(
                color: NunuColors.backgroundDefault,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: onMenuPressed,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}

/// Menu drawer content
class MegaMergeMenuDrawer extends StatelessWidget {
  final VoidCallback onShopPressed;
  final VoidCallback onProfilePressed;
  final VoidCallback onSettingsPressed;
  final VoidCallback onClose;

  const MegaMergeMenuDrawer({
    Key? key,
    required this.onShopPressed,
    required this.onProfilePressed,
    required this.onSettingsPressed,
    required this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      height: double.infinity,
      color: NunuColors.backgroundPaper,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'menu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12),

            // Menu Items
            _buildMenuItem(
              icon: Icons.store,
              label: 'shop',
              color: NunuColors.primaryMain,
              onTap: () {
                onClose();
                onShopPressed();
              },
            ),
            _buildMenuItem(
              icon: Icons.person,
              label: 'profile',
              color: NunuColors.secondaryMain,
              onTap: () {
                onClose();
                onProfilePressed();
              },
            ),
            _buildMenuItem(
              icon: Icons.settings,
              label: 'settings',
              color: Colors.grey,
              onTap: () {
                onClose();
                onSettingsPressed();
              },
            ),

            const Spacer(),

            // Footer
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: NunuColors.primaryMain.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.factory,
                      color: NunuColors.primaryMain,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'mega merge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'factory simulator',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}

