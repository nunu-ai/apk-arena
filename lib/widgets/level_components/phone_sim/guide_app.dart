import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'phone_homescreen.dart';

/// Guide app that provides testing guidelines for answering checklist questions
class GuideApp extends StatelessWidget {
  final VoidCallback onBack;

  const GuideApp({Key? key, required this.onBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'Guide',
            onBack: onBack,
            backgroundColor: const Color(0xFF5C6BC0).withOpacity(0.3),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildSection(
                  icon: Icons.verified_user,
                  title: 'verification pop-ups',
                  color: Colors.orange,
                  content: _buildVerificationContent(),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.description,
                  title: 'terms of service & privacy policy',
                  color: Colors.blue,
                  content: _buildTosPrivacyContent(),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.chat_bubble,
                  title: 'chat functions',
                  color: Colors.green,
                  content: _buildChatContent(),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.delete_outline,
                  title: 'fresh install / uninstalling apps',
                  color: Colors.red,
                  content: _buildUninstallContent(),
                ),
                const SizedBox(height: 16),
                _buildSection(
                  icon: Icons.lightbulb,
                  title: 'general tips',
                  color: Colors.amber,
                  content: _buildGeneralTipsContent(),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF5C6BC0),
            const Color(0xFF5C6BC0).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.menu_book, color: Colors.white, size: 48),
          const SizedBox(height: 12),
          const Text(
            'app review guide',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'learn how to properly evaluate apps and answer the checklist questions',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Color color,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(11),
                topRight: Radius.circular(11),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(padding: const EdgeInsets.all(16), child: content),
        ],
      ),
    );
  }

  Widget _buildVerificationContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          'age verification and other pop-ups often only appear when an app '
          'is freshly installed. if you need to check whether an app has a '
          'verification pop-up:',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'make sure the app is a fresh install',
          Icons.check_circle_outline,
          Colors.green,
        ),
        _buildBulletPoint(
          'if already installed, uninstall and reinstall it',
          Icons.refresh,
          NunuColors.textSecondary,
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'see the "fresh install / uninstalling apps" section below for '
          'step-by-step instructions on how to uninstall an app.',
          Icons.arrow_downward,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildTosPrivacyContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          'terms of service and privacy policies are typically shown during '
          'the initial app setup:',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'often displayed when freshly installing/launching the app',
          Icons.launch,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'may require acceptance before using the app',
          Icons.check_box_outlined,
          NunuColors.textSecondary,
        ),
        const SizedBox(height: 16),
        _buildParagraph(
          'if you already accepted them and need to read them again:',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'check sections like "settings", "about", "legal", "help", or "account"',
          Icons.search,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'the exact location varies between apps',
          Icons.info,
          NunuColors.textSecondary,
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'if you can\'t find them anywhere, do a fresh install to see the '
          'initial acceptance screen again. see "fresh install / uninstalling apps" below.',
          Icons.arrow_downward,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildChatContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          'many apps have chat or social features that are not immediately '
          'available:',
        ),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'chat may unlock after completing certain levels',
          Icons.lock_open,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'some features unlock after the onboarding tutorial',
          Icons.school,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'progression through the game may be required',
          Icons.trending_up,
          NunuColors.textSecondary,
        ),
        const SizedBox(height: 16),
        _buildParagraph('apps may have different types of chat features:'),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'public chats: community forums, group discussions visible to all users',
          Icons.forum,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'private chats: direct messages (DMs) for one-on-one communication',
          Icons.chat,
          NunuColors.textSecondary,
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'having one type of chat doesn\'t mean an app has both. '
          'check carefully whether an app offers public community chat, '
          'private messaging, or both.',
          Icons.tips_and_updates,
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildUninstallContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildParagraph(
          'to do a fresh install of an app, you need to uninstall it first. '
          'this resets the app to its initial state.',
        ),
        const SizedBox(height: 16),
        _buildParagraph('how to uninstall an app:'),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'open the play store app',
          Icons.store,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'tap "you" at the bottom of the screen',
          Icons.person,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'tap "manage apps & device"',
          Icons.apps,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'tap "manage" to see your installed apps',
          Icons.list,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'find and select the app you want to uninstall',
          Icons.touch_app,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'tap "uninstall" to remove the app',
          Icons.delete_outline,
          NunuColors.textSecondary,
        ),
        const SizedBox(height: 16),
        _buildParagraph('after uninstalling:'),
        const SizedBox(height: 12),
        _buildBulletPoint(
          'reinstall the app from the play store',
          Icons.download,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'launch it to see the full onboarding experience',
          Icons.play_arrow,
          NunuColors.textSecondary,
        ),
        const SizedBox(height: 12),
        _buildInfoBox(
          'a fresh install lets you see verification pop-ups, terms of service '
          'acceptance screens, and other first-launch experiences.',
          Icons.info_outline,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildGeneralTipsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBulletPoint(
          'explore all menus and settings thoroughly',
          Icons.explore,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'read all text carefully, including fine print',
          Icons.remove_red_eye,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'look for expandable sections like "more details"',
          Icons.expand_more,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'check the store for additional info about apps',
          Icons.store,
          NunuColors.textSecondary,
        ),
        _buildBulletPoint(
          'progress through games to unlock hidden features',
          Icons.games,
          NunuColors.textSecondary,
        ),
      ],
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        color: NunuColors.textSecondary,
        fontSize: 14,
        height: 1.5,
      ),
    );
  }

  Widget _buildBulletPoint(String text, IconData icon, Color iconColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color.withOpacity(0.9),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
