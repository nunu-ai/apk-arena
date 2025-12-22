import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Represents an app that can be displayed on the phone homescreen
class PhoneApp {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final bool isSystemApp;
  final bool requiresUpdate;

  const PhoneApp({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    this.isSystemApp = false,
    this.requiresUpdate = false,
  });
}

/// Phone homescreen widget with status bar, app grid, and dock
class PhoneHomescreen extends StatelessWidget {
  final List<PhoneApp> installedApps;
  final List<PhoneApp> dockApps;
  final Function(PhoneApp) onAppTap;
  final Function(PhoneApp)? onAppLongPress;
  final VoidCallback? onBackgroundTap;

  const PhoneHomescreen({
    Key? key,
    required this.installedApps,
    required this.dockApps,
    required this.onAppTap,
    this.onAppLongPress,
    this.onBackgroundTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1a1a2e), Color(0xFF16213e), Color(0xFF0f3460)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildStatusBar(),
            Expanded(
              child: GestureDetector(
                onTap: onBackgroundTap,
                behavior: HitTestBehavior.translucent,
                child: _buildAppGrid(),
              ),
            ),
            _buildDock(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBar() {
    final now = DateTime.now();
    final timeStr =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            timeStr,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.signal_cellular_4_bar,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              const Icon(Icons.wifi, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              const Icon(Icons.battery_full, color: Colors.white, size: 16),
              const SizedBox(width: 2),
              const Text(
                '87%',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 16,
        ),
        itemCount: installedApps.length,
        itemBuilder: (context, index) {
          return _buildAppIcon(installedApps[index]);
        },
      ),
    );
  }

  Widget _buildAppIcon(PhoneApp app) {
    return GestureDetector(
      onTap: () => onAppTap(app),
      onLongPress: onAppLongPress != null ? () => onAppLongPress!(app) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: app.color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: app.color.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(app.icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            app.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w400,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDock() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: dockApps.map((app) {
          return GestureDetector(
            onTap: () => onAppTap(app),
            onLongPress: onAppLongPress != null
                ? () => onAppLongPress!(app)
                : null,
            child: Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: app.color,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(app.icon, color: Colors.white, size: 26),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// App bar for inside apps with back button
class PhoneAppBar extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const PhoneAppBar({
    Key? key,
    required this.title,
    required this.onBack,
    this.actions,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: backgroundColor ?? NunuColors.backgroundPaper,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: onBack,
            ),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (actions != null) ...actions!,
          ],
        ),
      ),
    );
  }
}
