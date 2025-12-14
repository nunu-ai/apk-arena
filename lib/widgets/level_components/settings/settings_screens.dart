import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'settings_app_state.dart';
import 'settings_widgets.dart';

/// Builds all the individual screens for the settings app
class SettingsScreens {
  final SettingsAppState state;
  final void Function(String) navigateTo;
  final VoidCallback goBack;
  final void Function(void Function(SettingsAppState)) updateState;
  final void Function(String message, Color color) showSnackBar;
  final Future<dynamic> Function(Widget dialog) showDialog;
  final Future<TimeOfDay?> Function(TimeOfDay initial) showTimePicker;
  final BuildContext context;
  
  SettingsScreens({
    required this.state,
    required this.navigateTo,
    required this.goBack,
    required this.updateState,
    required this.showSnackBar,
    required this.showDialog,
    required this.showTimePicker,
    required this.context,
  });
  
  // ============================================================
  // MAIN SETTINGS SCREEN
  // ============================================================
  
  Widget buildMainSettings() {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        _buildProfileCard(),
        const SizedBox(height: 16),
        SettingsSection(
          title: 'account',
          children: [
            SettingsTile(
              icon: Icons.person_outline,
              title: 'profile',
              subtitle: 'name, email, phone, bio',
              onTap: () => navigateTo('profile'),
            ),
            SettingsTile(
              icon: Icons.security_outlined,
              title: 'account',
              subtitle: 'password, 2FA, sessions',
              onTap: () => navigateTo('account'),
            ),
          ],
        ),
        SettingsSection(
          title: 'preferences',
          children: [
            SettingsTile(
              icon: Icons.notifications_outlined,
              title: 'notifications',
              subtitle: state.pushNotifications ? 'on' : 'off',
              onTap: () => navigateTo('notifications'),
            ),
            SettingsTile(
              icon: Icons.lock_outline,
              title: 'privacy & security',
              subtitle: 'visibility, data, permissions',
              onTap: () => navigateTo('privacy'),
            ),
            SettingsTile(
              icon: Icons.palette_outlined,
              title: 'display & theme',
              subtitle: state.darkMode ? 'dark mode' : 'light mode',
              onTap: () => navigateTo('display'),
            ),
            SettingsTile(
              icon: Icons.volume_up_outlined,
              title: 'sound & haptics',
              subtitle: '${(state.masterVolume * 100).round()}% volume',
              onTap: () => navigateTo('sound'),
            ),
          ],
        ),
        SettingsSection(
          title: 'region',
          children: [
            SettingsTile(
              icon: Icons.language_outlined,
              title: 'language & region',
              subtitle: '${state.language} · ${state.region}',
              onTap: () => navigateTo('language'),
            ),
            SettingsTile(
              icon: Icons.storage_outlined,
              title: 'data & storage',
              subtitle: 'cache: ${state.cacheSize}',
              onTap: () => navigateTo('data'),
            ),
          ],
        ),
        SettingsSection(
          title: 'other',
          children: [
            SettingsTile(
              icon: Icons.accessibility_new_outlined,
              title: 'accessibility',
              subtitle: 'vision, motion, display',
              onTap: () => navigateTo('accessibility'),
            ),
            SettingsTile(
              icon: Icons.info_outline,
              title: 'about',
              subtitle: 'version ${state.appVersion}',
              onTap: () => navigateTo('about'),
            ),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
  
  Widget _buildProfileCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            NunuColors.primaryDark.withOpacity(0.3),
            NunuColors.secondaryDark.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: NunuColors.primaryMain.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: NunuColors.primaryMain,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                state.currentProfilePhoto,
                style: const TextStyle(fontSize: 30),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.userEmail,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: NunuColors.primaryLight),
            onPressed: () => navigateTo('profile'),
          ),
        ],
      ),
    );
  }
  
  // ============================================================
  // PROFILE SETTINGS
  // ============================================================
  
  Widget buildProfileSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: NunuColors.primaryMain,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                state.currentProfilePhoto,
                style: const TextStyle(fontSize: 50),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => navigateTo('profile_photo'),
            child: const Text('change photo'),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.badge_outlined,
                title: 'name',
                subtitle: state.userName,
                onTap: () => navigateTo('profile_edit_name'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.email_outlined,
                title: 'email',
                subtitle: state.userEmail,
                onTap: () => navigateTo('profile_edit_email'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.phone_outlined,
                title: 'phone',
                subtitle: state.userPhone,
                onTap: () => navigateTo('profile_edit_phone'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.info_outline,
                title: 'bio',
                subtitle: state.userBio.length > 30 ? '${state.userBio.substring(0, 30)}...' : state.userBio,
                onTap: () => navigateTo('profile_edit_bio'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SettingsTile(
            icon: Icons.link,
            title: 'linked accounts',
            subtitle: '${[state.googleLinked, state.appleLinked, state.facebookLinked, state.twitterLinked].where((e) => e).length} connected',
            onTap: () => navigateTo('profile_linked'),
          ),
        ),
      ],
    );
  }
  
  Widget buildPhotoSelector() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: SettingsAppState.profilePhotos.length,
      itemBuilder: (context, index) {
        final isSelected = state.profilePhotoIndex == index;
        return GestureDetector(
          onTap: () {
            updateState((s) => s.profilePhotoIndex = index);
            goBack();
          },
          child: Container(
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? NunuColors.primaryMain : Colors.transparent,
                width: 3,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: NunuColors.primaryMain.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ] : null,
            ),
            child: Center(
              child: Text(
                SettingsAppState.profilePhotos[index],
                style: const TextStyle(fontSize: 32),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget buildEditName() {
    final controller = TextEditingController(text: state.userName);
    return SettingsEditScreen(
      label: 'name',
      hint: 'enter your display name',
      controller: controller,
      onSave: () {
        updateState((s) => s.userName = controller.text);
        goBack();
      },
    );
  }
  
  Widget buildEditEmail() {
    final controller = TextEditingController(text: state.userEmail);
    return SettingsEditScreen(
      label: 'email',
      hint: 'enter your email address',
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      onSave: () {
        updateState((s) => s.userEmail = controller.text);
        goBack();
      },
    );
  }
  
  Widget buildEditPhone() {
    final controller = TextEditingController(text: state.userPhone);
    return SettingsEditScreen(
      label: 'phone number',
      hint: 'enter your phone number',
      controller: controller,
      keyboardType: TextInputType.phone,
      onSave: () {
        updateState((s) => s.userPhone = controller.text);
        goBack();
      },
    );
  }
  
  Widget buildEditBio() {
    final controller = TextEditingController(text: state.userBio);
    return SettingsEditScreen(
      label: 'bio',
      hint: 'tell us about yourself',
      controller: controller,
      maxLines: 4,
      onSave: () {
        updateState((s) => s.userBio = controller.text);
        goBack();
      },
    );
  }
  
  Widget buildLinkedAccounts() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.g_mobiledata,
                title: 'google',
                subtitle: state.googleLinked ? 'connected' : 'not connected',
                value: state.googleLinked,
                onChanged: (v) => updateState((s) => s.googleLinked = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.apple,
                title: 'apple',
                subtitle: state.appleLinked ? 'connected' : 'not connected',
                value: state.appleLinked,
                onChanged: (v) => updateState((s) => s.appleLinked = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.facebook,
                title: 'facebook',
                subtitle: state.facebookLinked ? 'connected' : 'not connected',
                value: state.facebookLinked,
                onChanged: (v) => updateState((s) => s.facebookLinked = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.alternate_email,
                title: 'twitter / x',
                subtitle: state.twitterLinked ? 'connected' : 'not connected',
                value: state.twitterLinked,
                onChanged: (v) => updateState((s) => s.twitterLinked = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'linked accounts can be used for quick sign-in and sharing.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  // ============================================================
  // ACCOUNT SETTINGS
  // ============================================================
  
  Widget buildAccountSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.password,
                title: 'change password',
                subtitle: 'last changed 30 days ago',
                onTap: () => navigateTo('account_password'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.security,
                title: 'two-factor authentication',
                subtitle: state.twoFactorEnabled ? 'enabled' : 'disabled',
                onTap: () => navigateTo('account_2fa'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: state.twoFactorEnabled 
                        ? NunuColors.successMain.withOpacity(0.2)
                        : NunuColors.warningMain.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    state.twoFactorEnabled ? 'on' : 'off',
                    style: TextStyle(
                      color: state.twoFactorEnabled ? NunuColors.successMain : NunuColors.warningMain,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.devices,
                title: 'active sessions',
                subtitle: '${state.activeSessions} devices logged in',
                onTap: () => navigateTo('account_sessions'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.errorMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: NunuColors.errorMain.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showDeleteAccountDialog(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.delete_forever, color: NunuColors.errorMain),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'delete account',
                            style: TextStyle(
                              color: NunuColors.errorMain,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'permanently remove your account and data',
                            style: TextStyle(
                              color: NunuColors.errorMain.withOpacity(0.7),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  void _showDeleteAccountDialog() {
    showDialog(AlertDialog(
      backgroundColor: NunuColors.backgroundPaper,
      title: const Text('delete account?', style: TextStyle(color: Colors.white)),
      content: const Text(
        'this action cannot be undone. all your data will be permanently removed.',
        style: TextStyle(color: NunuColors.textSecondary),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: ElevatedButton.styleFrom(
            backgroundColor: NunuColors.errorMain,
          ),
          child: const Text('delete'),
        ),
      ],
    ));
  }
  
  Widget buildChangePassword() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SettingsPasswordField(label: 'current password', controller: currentController),
          const SizedBox(height: 16),
          SettingsPasswordField(label: 'new password', controller: newController),
          const SizedBox(height: 16),
          SettingsPasswordField(label: 'confirm new password', controller: confirmController),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              showSnackBar('password updated successfully', NunuColors.successMain);
              goBack();
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('update password'),
          ),
          const SizedBox(height: 16),
          Text(
            'password must be at least 8 characters and include a number and special character.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget buildTwoFactorAuth() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: state.twoFactorEnabled 
                ? NunuColors.successMain.withOpacity(0.1)
                : NunuColors.warningMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: state.twoFactorEnabled 
                  ? NunuColors.successMain.withOpacity(0.3)
                  : NunuColors.warningMain.withOpacity(0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                state.twoFactorEnabled ? Icons.verified_user : Icons.gpp_maybe,
                color: state.twoFactorEnabled ? NunuColors.successMain : NunuColors.warningMain,
                size: 32,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.twoFactorEnabled ? 'protected' : 'not protected',
                      style: TextStyle(
                        color: state.twoFactorEnabled ? NunuColors.successMain : NunuColors.warningMain,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      state.twoFactorEnabled 
                          ? 'your account has an extra layer of security.'
                          : 'enable 2FA for additional account protection.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SettingsToggleTile(
            icon: Icons.smartphone,
            title: 'authenticator app',
            subtitle: 'use google authenticator or similar',
            value: state.twoFactorEnabled,
            onChanged: (v) => updateState((s) => s.twoFactorEnabled = v),
          ),
        ),
        const SizedBox(height: 16),
        if (state.twoFactorEnabled)
          Container(
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SettingsTile(
              icon: Icons.key,
              title: 'backup codes',
              subtitle: 'view your emergency backup codes',
              onTap: () {
                showSnackBar('backup codes: 1234-5678-9012', NunuColors.infoMain);
              },
            ),
          ),
      ],
    );
  }
  
  Widget buildActiveSessions() {
    final sessions = [
      {'device': 'iPhone 15 Pro', 'location': 'San Francisco, CA', 'current': true},
      {'device': 'MacBook Pro', 'location': 'San Francisco, CA', 'current': false},
      {'device': 'Chrome on Windows', 'location': 'New York, NY', 'current': false},
    ];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'devices currently signed in to your account:',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        ...sessions.map((session) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
            border: session['current'] == true 
                ? Border.all(color: NunuColors.primaryMain.withOpacity(0.5))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                session['device'].toString().contains('iPhone') 
                    ? Icons.phone_iphone
                    : session['device'].toString().contains('Mac')
                        ? Icons.laptop_mac
                        : Icons.computer,
                color: NunuColors.primaryLight,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          session['device'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (session['current'] == true) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: NunuColors.successMain.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'current',
                              style: TextStyle(
                                color: NunuColors.successMain,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session['location'] as String,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (session['current'] != true)
                TextButton(
                  onPressed: () {
                    updateState((s) => s.activeSessions--);
                  },
                  child: const Text('sign out'),
                ),
            ],
          ),
        )),
        const SizedBox(height: 16),
        OutlinedButton(
          onPressed: () {
            updateState((s) => s.activeSessions = 1);
          },
          child: const Text('sign out all other devices'),
        ),
      ],
    );
  }
  
  // ============================================================
  // NOTIFICATION SETTINGS
  // ============================================================
  
  Widget buildNotificationSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.notifications_active,
                title: 'push notifications',
                subtitle: 'receive alerts on your device',
                value: state.pushNotifications,
                onChanged: (v) => updateState((s) => s.pushNotifications = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.email,
                title: 'email notifications',
                subtitle: 'receive updates via email',
                value: state.emailNotifications,
                onChanged: (v) => updateState((s) => s.emailNotifications = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.campaign,
                title: 'marketing emails',
                subtitle: 'offers, news, and promotions',
                value: state.marketingEmails,
                onChanged: (v) => updateState((s) => s.marketingEmails = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.volume_up,
                title: 'notification sound',
                value: state.notificationSound,
                onChanged: (v) => updateState((s) => s.notificationSound = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.vibration,
                title: 'vibration',
                value: state.notificationVibration,
                onChanged: (v) => updateState((s) => s.notificationVibration = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SettingsTile(
            icon: Icons.bedtime,
            title: 'quiet hours',
            subtitle: state.quietHoursEnabled 
                ? '${state.quietHoursStart.format(context)} - ${state.quietHoursEnd.format(context)}'
                : 'off',
            onTap: () => navigateTo('notifications_quiet'),
          ),
        ),
      ],
    );
  }
  
  Widget buildQuietHours() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SettingsToggleTile(
            icon: Icons.bedtime,
            title: 'enable quiet hours',
            subtitle: 'mute notifications during set times',
            value: state.quietHoursEnabled,
            onChanged: (v) => updateState((s) => s.quietHoursEnabled = v),
          ),
        ),
        if (state.quietHoursEnabled) ...[
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NunuColors.primaryMain.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule, color: NunuColors.primaryLight, size: 22),
                  ),
                  title: const Text('start time', style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    state.quietHoursStart.format(context),
                    style: const TextStyle(color: NunuColors.primaryLight, fontSize: 16),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(state.quietHoursStart);
                    if (time != null) {
                      updateState((s) => s.quietHoursStart = time);
                    }
                  },
                ),
                const SettingsDivider(),
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: NunuColors.primaryMain.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.schedule, color: NunuColors.primaryLight, size: 22),
                  ),
                  title: const Text('end time', style: TextStyle(color: Colors.white)),
                  trailing: Text(
                    state.quietHoursEnd.format(context),
                    style: const TextStyle(color: NunuColors.primaryLight, fontSize: 16),
                  ),
                  onTap: () async {
                    final time = await showTimePicker(state.quietHoursEnd);
                    if (time != null) {
                      updateState((s) => s.quietHoursEnd = time);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
  
  // ============================================================
  // PRIVACY SETTINGS
  // ============================================================
  
  Widget buildPrivacySettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.visibility,
                title: 'profile visibility',
                subtitle: state.profileVisibility.toLowerCase(),
                onTap: () => navigateTo('privacy_visibility'),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.location_on,
                title: 'location sharing',
                subtitle: 'allow access to your location',
                value: state.locationSharing,
                onChanged: (v) => updateState((s) => s.locationSharing = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.analytics,
                title: 'usage analytics',
                subtitle: 'help improve the app',
                value: state.analyticsEnabled,
                onChanged: (v) => updateState((s) => s.analyticsEnabled = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.ads_click,
                title: 'personalized ads',
                subtitle: 'show relevant advertisements',
                value: state.personalizedAds,
                onChanged: (v) => updateState((s) => s.personalizedAds = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SettingsTile(
            icon: Icons.download,
            title: 'your data',
            subtitle: 'download or delete your data',
            onTap: () => navigateTo('privacy_data'),
          ),
        ),
      ],
    );
  }
  
  Widget buildProfileVisibility() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: SettingsAppState.visibilityOptions.map((option) {
              final isSelected = state.profileVisibility == option;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => updateState((s) => s.profileVisibility = option),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Icon(
                          option == 'Public' 
                              ? Icons.public 
                              : option == 'Friends' 
                                  ? Icons.people 
                                  : Icons.lock,
                          color: NunuColors.primaryLight,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                option.toLowerCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                option == 'Public' 
                                    ? 'anyone can see your profile'
                                    : option == 'Friends'
                                        ? 'only friends can see your profile'
                                        : 'only you can see your profile',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.5),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: NunuColors.primaryMain),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget buildYourData() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.download,
                title: 'download your data',
                subtitle: 'get a copy of your information',
                onTap: () {
                  showSnackBar('preparing your data export...', NunuColors.infoMain);
                },
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.delete_sweep,
                title: 'clear activity history',
                subtitle: 'remove your activity data',
                onTap: () {
                  showSnackBar('activity history cleared', NunuColors.successMain);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // DISPLAY SETTINGS
  // ============================================================
  
  Widget buildDisplaySettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.dark_mode,
                title: 'dark mode',
                subtitle: 'reduce eye strain in low light',
                value: state.darkMode,
                onChanged: (v) => updateState((s) => s.darkMode = v),
              ),
              const SettingsDivider(),
              SettingsSliderTile(
                icon: Icons.format_size,
                title: 'font size',
                value: state.fontSize,
                min: 0.8,
                max: 1.4,
                valueLabel: '${(state.fontSize * 100).round()}%',
                onChanged: (v) => updateState((s) => s.fontSize = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.animation,
                title: 'animations',
                subtitle: 'enable smooth transitions',
                value: state.animationsEnabled,
                onChanged: (v) => updateState((s) => s.animationsEnabled = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.view_compact,
                title: 'compact mode',
                subtitle: 'show more content on screen',
                value: state.compactMode,
                onChanged: (v) => updateState((s) => s.compactMode = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.slow_motion_video,
                title: 'reduced motion',
                subtitle: 'minimize animation effects',
                value: state.reducedMotion,
                onChanged: (v) => updateState((s) => s.reducedMotion = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // SOUND SETTINGS
  // ============================================================
  
  Widget buildSoundSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SettingsSliderTile(
            icon: Icons.volume_up,
            title: 'master volume',
            value: state.masterVolume,
            min: 0.0,
            max: 1.0,
            valueLabel: '${(state.masterVolume * 100).round()}%',
            onChanged: (v) => updateState((s) => s.masterVolume = v),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SettingsDropdownTile(
            icon: Icons.music_note,
            title: 'notification tone',
            value: state.notificationTone,
            options: SettingsAppState.notificationTones,
            onChanged: (v) => updateState((s) => s.notificationTone = v),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.vibration,
                title: 'haptic feedback',
                subtitle: 'vibrate on interactions',
                value: state.hapticFeedback,
                onChanged: (v) => updateState((s) => s.hapticFeedback = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.keyboard,
                title: 'keyboard sounds',
                subtitle: 'click sounds when typing',
                value: state.keyboardSounds,
                onChanged: (v) => updateState((s) => s.keyboardSounds = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.surround_sound,
                title: 'in-app sounds',
                subtitle: 'ui feedback and alerts',
                value: state.inAppSounds,
                onChanged: (v) => updateState((s) => s.inAppSounds = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // LANGUAGE & REGION SETTINGS
  // ============================================================
  
  Widget buildLanguageSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsDropdownTile(
                icon: Icons.language,
                title: 'language',
                value: state.language,
                options: SettingsAppState.availableLanguages,
                onChanged: (v) => updateState((s) => s.language = v),
              ),
              const SettingsDivider(),
              SettingsDropdownTile(
                icon: Icons.public,
                title: 'region',
                value: state.region,
                options: SettingsAppState.availableRegions,
                onChanged: (v) => updateState((s) => s.region = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsDropdownTile(
                icon: Icons.calendar_today,
                title: 'date format',
                value: state.dateFormat,
                options: SettingsAppState.dateFormats,
                onChanged: (v) => updateState((s) => s.dateFormat = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.access_time,
                title: '24-hour time',
                subtitle: 'use 24-hour clock format',
                value: state.use24HourTime,
                onChanged: (v) => updateState((s) => s.use24HourTime = v),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.schedule,
                title: 'timezone',
                subtitle: state.timezone,
                onTap: () => navigateTo('language_timezone'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget buildTimezoneSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: SettingsAppState.availableTimezones.map((tz) {
              final isSelected = state.timezone == tz;
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => updateState((s) => s.timezone = tz),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            tz,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: NunuColors.primaryMain),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // DATA & STORAGE SETTINGS
  // ============================================================
  
  Widget buildDataSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.storage, color: NunuColors.primaryLight),
                  const SizedBox(width: 10),
                  const Text(
                    'storage used',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    state.cacheSize,
                    style: const TextStyle(
                      color: NunuColors.primaryLight,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.35,
                  backgroundColor: NunuColors.primaryDark.withOpacity(0.3),
                  valueColor: const AlwaysStoppedAnimation(NunuColors.primaryMain),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '234 MB of 1 GB used',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.cleaning_services,
                title: 'cache management',
                subtitle: 'clear temporary files',
                onTap: () => navigateTo('data_cache'),
              ),
              const SettingsDivider(),
              SettingsDropdownTile(
                icon: Icons.high_quality,
                title: 'download quality',
                value: state.downloadQuality,
                options: SettingsAppState.downloadQualities,
                onChanged: (v) => updateState((s) => s.downloadQuality = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.cloud_download,
                title: 'auto-download',
                subtitle: 'automatically download new content',
                value: state.autoDownload,
                onChanged: (v) => updateState((s) => s.autoDownload = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.wifi,
                title: 'wifi only download',
                subtitle: 'save mobile data',
                value: state.wifiOnlyDownload,
                onChanged: (v) => updateState((s) => s.wifiOnlyDownload = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.photo_library,
                title: 'save to gallery',
                subtitle: 'auto-save media to device',
                value: state.saveToGallery,
                onChanged: (v) => updateState((s) => s.saveToGallery = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget buildCacheManagement() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.image, color: NunuColors.primaryLight),
                title: const Text('image cache', style: TextStyle(color: Colors.white)),
                subtitle: Text('128 MB', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                trailing: TextButton(
                  onPressed: () {
                    showSnackBar('image cache cleared', NunuColors.successMain);
                  },
                  child: const Text('clear'),
                ),
              ),
              const SettingsDivider(),
              ListTile(
                leading: const Icon(Icons.video_library, color: NunuColors.primaryLight),
                title: const Text('video cache', style: TextStyle(color: Colors.white)),
                subtitle: Text('82 MB', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                trailing: TextButton(
                  onPressed: () {
                    showSnackBar('video cache cleared', NunuColors.successMain);
                  },
                  child: const Text('clear'),
                ),
              ),
              const SettingsDivider(),
              ListTile(
                leading: const Icon(Icons.file_copy, color: NunuColors.primaryLight),
                title: const Text('other files', style: TextStyle(color: Colors.white)),
                subtitle: Text('24 MB', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                trailing: TextButton(
                  onPressed: () {
                    showSnackBar('other cache cleared', NunuColors.successMain);
                  },
                  child: const Text('clear'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () {
            updateState((s) => s.cacheSize = '0 MB');
            showSnackBar('all cache cleared', NunuColors.successMain);
          },
          icon: const Icon(Icons.delete_sweep),
          label: const Text('clear all cache'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // ACCESSIBILITY SETTINGS
  // ============================================================
  
  Widget buildAccessibilitySettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.infoMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NunuColors.infoMain.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.accessibility_new, color: NunuColors.infoMain),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'customize your experience to meet your accessibility needs.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.record_voice_over,
                title: 'screen reader optimized',
                subtitle: 'enhance for voiceover/talkback',
                value: state.screenReaderOptimized,
                onChanged: (v) => updateState((s) => s.screenReaderOptimized = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.contrast,
                title: 'high contrast',
                subtitle: 'increase color contrast',
                value: state.highContrast,
                onChanged: (v) => updateState((s) => s.highContrast = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsToggleTile(
                icon: Icons.text_fields,
                title: 'larger text',
                subtitle: 'increase text size throughout',
                value: state.largeText,
                onChanged: (v) => updateState((s) => s.largeText = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.format_bold,
                title: 'bold text',
                subtitle: 'make text bolder',
                value: state.boldText,
                onChanged: (v) => updateState((s) => s.boldText = v),
              ),
              const SettingsDivider(),
              SettingsToggleTile(
                icon: Icons.slow_motion_video,
                title: 'reduced motion',
                subtitle: 'minimize animations',
                value: state.reducedMotion,
                onChanged: (v) => updateState((s) => s.reducedMotion = v),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // ABOUT SETTINGS
  // ============================================================
  
  Widget buildAboutSettings() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                NunuColors.primaryDark.withOpacity(0.3),
                NunuColors.secondaryDark.withOpacity(0.2),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.settings_applications, color: Colors.white, size: 36),
              ),
              const SizedBox(height: 12),
              const Text(
                'settings app',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'version ${state.appVersion} (build ${state.buildNumber})',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.description,
                title: 'terms of service',
                subtitle: 'read our terms',
                onTap: () => navigateTo('about_terms'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.privacy_tip,
                title: 'privacy policy',
                subtitle: 'how we handle your data',
                onTap: () => navigateTo('about_privacy'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.gavel,
                title: 'licenses',
                subtitle: 'open source licenses',
                onTap: () => navigateTo('about_licenses'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.help_outline,
                title: 'help & support',
                subtitle: 'faq, contact, feedback',
                onTap: () => navigateTo('about_support'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.rate_review,
                title: 'rate the app',
                subtitle: 'leave a review',
                onTap: () => navigateTo('about_rate'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          '© 2024 nunu.ai — all rights reserved',
          style: TextStyle(
            color: Colors.white.withOpacity(0.4),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
  
  Widget buildLicenses() {
    final licenses = [
      {
        'name': 'Flutter',
        'license': 'BSD-3-Clause',
        'text': '''Copyright 2014 The Flutter Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.'''
      },
      {
        'name': 'Google Fonts',
        'license': 'Apache 2.0',
        'text': '''Copyright 2020 The Google Fonts Authors

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.'''
      },
      {
        'name': 'Provider',
        'license': 'MIT',
        'text': '''MIT License

Copyright (c) 2019 Remi Rousselet

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.'''
      },
      {
        'name': 'SharedPreferences',
        'license': 'BSD-3-Clause',
        'text': '''Copyright 2017 The Chromium Authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES ARE DISCLAIMED.'''
      },
      {
        'name': 'HTTP',
        'license': 'BSD-3-Clause',
        'text': '''Copyright 2014, the Dart project authors. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND.'''
      },
    ];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: licenses.asMap().entries.map((entry) {
              final lic = entry.value;
              final isLast = entry.key == licenses.length - 1;
              return Column(
                children: [
                  ExpansionTile(
                    title: Text(lic['name']!, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(lic['license']!, style: TextStyle(color: Colors.white.withOpacity(0.5))),
                    iconColor: NunuColors.primaryLight,
                    collapsedIconColor: NunuColors.textSecondary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          lic['text']!,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12,
                            height: 1.5,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) const SettingsDivider(),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget buildSupport() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              SettingsTile(
                icon: Icons.help,
                title: 'faq',
                subtitle: 'frequently asked questions',
                onTap: () => navigateTo('support_faq'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.email,
                title: 'contact support',
                subtitle: 'send us a message',
                onTap: () => navigateTo('support_contact'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.feedback,
                title: 'send feedback',
                subtitle: 'help us improve',
                onTap: () => navigateTo('support_feedback'),
              ),
              const SettingsDivider(),
              SettingsTile(
                icon: Icons.bug_report,
                title: 'report a bug',
                subtitle: 'found something wrong?',
                onTap: () => navigateTo('support_bug'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  // ============================================================
  // NEW ABOUT SCREENS
  // ============================================================
  
  Widget buildTermsOfService() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'terms of service',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'last updated: december 1, 2024',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 16),
              const _LegalSection(
                title: '1. acceptance of terms',
                content: 'by accessing and using this application ("the app"), you acknowledge that you have read, understood, and agree to be bound by these terms of service ("terms"). if you do not agree to these terms, you must immediately discontinue use of the app. these terms constitute a legally binding agreement between you and nunu.ai ("we," "us," or "our"). your continued use of the app following any modifications to these terms constitutes acceptance of those modifications.',
              ),
              const _LegalSection(
                title: '2. eligibility',
                content: 'you must be at least 13 years of age to use this app. if you are between 13 and 18 years of age, you represent that your legal guardian has reviewed and agrees to these terms. by using the app, you represent and warrant that you have the right, authority, and capacity to enter into these terms and to abide by all of the terms and conditions set forth herein. we reserve the right to refuse service, terminate accounts, or cancel orders at our sole discretion.',
              ),
              const _LegalSection(
                title: '3. user accounts',
                content: 'to access certain features of the app, you may be required to create an account. you agree to provide accurate, current, and complete information during the registration process and to update such information as necessary. you are solely responsible for safeguarding your password and for all activities that occur under your account. you agree to notify us immediately of any unauthorized use of your account. we reserve the right to suspend or terminate your account if any information provided proves to be inaccurate, not current, or incomplete.',
              ),
              const _LegalSection(
                title: '4. license grant',
                content: 'subject to your compliance with these terms, we grant you a limited, non-exclusive, non-transferable, revocable license to download, install, and use the app for your personal, non-commercial purposes strictly in accordance with these terms. this license does not include any right to: (a) modify or make derivative works based upon the app; (b) reverse engineer, disassemble, or decompile the app; (c) rent, lease, loan, resell, sublicense, or otherwise transfer the app to any third party; or (d) use the app for any commercial purpose without our prior written consent.',
              ),
              const _LegalSection(
                title: '5. user content',
                content: 'you retain ownership of any content you submit, post, or display through the app ("user content"). by submitting user content, you grant us a worldwide, non-exclusive, royalty-free, sublicensable, and transferable license to use, reproduce, modify, adapt, publish, translate, create derivative works from, distribute, and display such content in connection with operating and providing the app. you represent and warrant that you own or have the necessary rights to grant this license and that your user content does not violate any third party rights.',
              ),
              const _LegalSection(
                title: '6. prohibited conduct',
                content: 'you agree not to: (a) use the app for any illegal purpose or in violation of any laws; (b) harass, abuse, or harm another person; (c) impersonate any person or entity; (d) interfere with or disrupt the app or servers; (e) attempt to gain unauthorized access to any portion of the app; (f) use any robot, spider, or other automated device to access the app; (g) introduce viruses, trojans, worms, or other malicious code; (h) collect personal information about other users without their consent; or (i) engage in any activity that could damage, disable, or impair the app.',
              ),
              const _LegalSection(
                title: '7. intellectual property',
                content: 'the app and its entire contents, features, and functionality (including but not limited to all information, software, text, displays, images, video, and audio, and the design, selection, and arrangement thereof) are owned by us, our licensors, or other providers of such material and are protected by copyright, trademark, patent, trade secret, and other intellectual property or proprietary rights laws. these terms do not grant you any right, title, or interest in the app, others\' content in the app, or our trademarks, logos, or other brand features.',
              ),
              const _LegalSection(
                title: '8. third-party services',
                content: 'the app may contain links to third-party websites, services, or resources that are not owned or controlled by us. we have no control over, and assume no responsibility for, the content, privacy policies, or practices of any third-party websites or services. you acknowledge and agree that we shall not be responsible or liable, directly or indirectly, for any damage or loss caused or alleged to be caused by or in connection with the use of or reliance on any such content, goods, or services available on or through any such websites or services.',
              ),
              const _LegalSection(
                title: '9. disclaimer of warranties',
                content: 'the app is provided on an "as is" and "as available" basis without any warranties of any kind, either express or implied. to the fullest extent permissible under applicable law, we disclaim all warranties, express or implied, including but not limited to implied warranties of merchantability, fitness for a particular purpose, and non-infringement. we do not warrant that the app will be uninterrupted, timely, secure, or error-free, that defects will be corrected, or that the app is free of viruses or other harmful components.',
              ),
              const _LegalSection(
                title: '10. limitation of liability',
                content: 'in no event shall we, our directors, officers, employees, agents, partners, suppliers, or affiliates be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from: (a) your access to or use of or inability to access or use the app; (b) any conduct or content of any third party on the app; (c) any content obtained from the app; or (d) unauthorized access, use, or alteration of your transmissions or content, whether based on warranty, contract, tort (including negligence), or any other legal theory.',
              ),
              const _LegalSection(
                title: '11. indemnification',
                content: 'you agree to defend, indemnify, and hold harmless us and our officers, directors, employees, contractors, agents, licensors, suppliers, successors, and assigns from and against any claims, liabilities, damages, judgments, awards, losses, costs, expenses, or fees (including reasonable attorneys\' fees) arising out of or relating to your violation of these terms or your use of the app, including but not limited to your user content, any use of the app\'s content and services other than as expressly authorized in these terms.',
              ),
              const _LegalSection(
                title: '12. termination',
                content: 'we may terminate or suspend your access to the app immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach these terms. upon termination, your right to use the app will immediately cease. all provisions of these terms which by their nature should survive termination shall survive termination, including, without limitation, ownership provisions, warranty disclaimers, indemnity, and limitations of liability.',
              ),
              const _LegalSection(
                title: '13. governing law',
                content: 'these terms shall be governed by and construed in accordance with the laws of the state of california, united states, without regard to its conflict of law provisions. you agree to submit to the personal and exclusive jurisdiction of the courts located within san francisco county, california, for the resolution of any disputes arising out of or relating to these terms or your use of the app.',
              ),
              const _LegalSection(
                title: '14. changes to terms',
                content: 'we reserve the right, at our sole discretion, to modify or replace these terms at any time. if a revision is material, we will provide at least 30 days\' notice prior to any new terms taking effect. what constitutes a material change will be determined at our sole discretion. by continuing to access or use the app after any revisions become effective, you agree to be bound by the revised terms.',
              ),
              const _LegalSection(
                title: '15. contact information',
                content: 'if you have any questions about these terms, please contact us at legal@nunu.ai or write to us at: nunu.ai legal department, 123 innovation drive, suite 456, san francisco, ca 94105, united states.',
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget buildPrivacyPolicy() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'privacy policy',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'last updated: december 1, 2024',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12),
              ),
              const SizedBox(height: 16),
              const _LegalSection(
                title: '1. introduction',
                content: 'nunu.ai ("we," "us," or "our") is committed to protecting your privacy. this privacy policy explains how we collect, use, disclose, and safeguard your information when you use our mobile application (the "app"). please read this privacy policy carefully. if you do not agree with the terms of this privacy policy, please do not access the app. we reserve the right to make changes to this privacy policy at any time and for any reason.',
              ),
              const _LegalSection(
                title: '2. information we collect',
                content: 'we may collect information about you in a variety of ways. the information we may collect via the app includes: (a) personal data such as your name, email address, phone number, and demographic information that you voluntarily provide when registering or using certain features; (b) derivative data automatically collected by our servers, including your ip address, browser type, operating system, access times, and pages viewed; (c) financial data such as payment card details when you make purchases; (d) mobile device data including device id, model, manufacturer, and location information if enabled.',
              ),
              const _LegalSection(
                title: '3. use of your information',
                content: 'we use information collected about you to: (a) create and manage your account; (b) process transactions and send related information; (c) send you administrative information, updates, and security alerts; (d) respond to your comments, questions, and requests; (e) monitor and analyze usage patterns and trends; (f) develop new products, services, features, and functionality; (g) prevent fraudulent transactions and monitor against theft; (h) personalize and improve your experience; (i) send you marketing and promotional communications (with opt-out options); (j) enforce our terms, conditions, and policies.',
              ),
              const _LegalSection(
                title: '4. disclosure of your information',
                content: 'we may share information we have collected about you in certain situations: (a) by law or to protect rights when we believe release is appropriate to comply with the law or protect our rights; (b) with third-party service providers who perform services on our behalf, such as payment processing, data analysis, email delivery, hosting, customer service, and marketing assistance; (c) in connection with a merger, acquisition, or sale of all or a portion of our assets; (d) with your consent or at your direction; (e) with other users when you share information publicly through the app.',
              ),
              const _LegalSection(
                title: '5. tracking technologies',
                content: 'we may use cookies, web beacons, tracking pixels, and other tracking technologies to help customize the app and improve your experience. when you access the app, your personal information is not collected through the use of tracking technology. most browsers are set to accept cookies by default. you can remove or reject cookies, but be aware that such action could affect the availability and functionality of the app. we may use third-party analytics tools to help understand use of the app.',
              ),
              const _LegalSection(
                title: '6. third-party websites',
                content: 'the app may contain links to third-party websites and applications of interest, including advertisements and external services, that are not affiliated with us. once you have used these links to leave the app, any information you provide to these third parties is not covered by this privacy policy, and we cannot guarantee the safety and privacy of your information. before visiting and providing any information to any third-party websites, you should inform yourself of the privacy policies and practices of the third party.',
              ),
              const _LegalSection(
                title: '7. security of your information',
                content: 'we use administrative, technical, and physical security measures to help protect your personal information. while we have taken reasonable steps to secure the personal information you provide to us, please be aware that despite our efforts, no security measures are perfect or impenetrable, and no method of data transmission can be guaranteed against any interception or other type of misuse. any information disclosed online is vulnerable to interception and misuse by unauthorized parties.',
              ),
              const _LegalSection(
                title: '8. data retention',
                content: 'we will retain your personal information only for as long as is necessary for the purposes set out in this privacy policy. we will retain and use your information to the extent necessary to comply with our legal obligations, resolve disputes, and enforce our policies. if you wish to request that we no longer use your information, please contact us at privacy@nunu.ai. we will respond to your request within 30 days.',
              ),
              const _LegalSection(
                title: '9. your privacy rights',
                content: 'depending on your location, you may have certain rights regarding your personal information, including: (a) the right to access personal information we hold about you; (b) the right to request correction of inaccurate data; (c) the right to request deletion of your data; (d) the right to object to or restrict processing; (e) the right to data portability; (f) the right to withdraw consent at any time. to exercise these rights, please contact us using the information provided below.',
              ),
              const _LegalSection(
                title: '10. california privacy rights',
                content: 'california civil code section 1798.83, also known as the "shine the light" law, permits our users who are california residents to request and obtain from us, once a year and free of charge, information about categories of personal information (if any) we disclosed to third parties for direct marketing purposes and the names and addresses of all third parties with which we shared personal information in the immediately preceding calendar year.',
              ),
              const _LegalSection(
                title: '11. gdpr compliance',
                content: 'if you are a resident of the european economic area (eea), you have certain data protection rights under the general data protection regulation (gdpr). we aim to take reasonable steps to allow you to correct, amend, delete, or limit the use of your personal data. if you wish to be informed about what personal data we hold about you and if you want it to be removed from our systems, please contact our data protection officer at dpo@nunu.ai.',
              ),
              const _LegalSection(
                title: '12. children\'s privacy',
                content: 'we do not knowingly solicit data from or market to children under 13 years of age. by using the app, you represent that you are at least 13 or that you are the parent or guardian of such a minor and consent to such minor dependent\'s use of the app. if we learn that personal information from users less than 13 years of age has been collected, we will deactivate the account and take reasonable measures to promptly delete such data from our records.',
              ),
              const _LegalSection(
                title: '13. international transfers',
                content: 'your information may be transferred to and maintained on computers located outside of your state, province, country, or other governmental jurisdiction where the data protection laws may differ from those of your jurisdiction. if you are located outside the united states and choose to provide information to us, please note that we transfer the data to the united states and process it there. your consent to this privacy policy followed by your submission of such information represents your agreement to that transfer.',
              ),
              const _LegalSection(
                title: '14. policy updates',
                content: 'we may update this privacy policy from time to time in order to reflect changes to our practices or for other operational, legal, or regulatory reasons. we will notify you of any material changes by posting the new privacy policy on this page and updating the "last updated" date. you are advised to review this privacy policy periodically for any changes. changes to this privacy policy are effective when they are posted on this page.',
              ),
              const _LegalSection(
                title: '15. contact us',
                content: 'if you have questions or comments about this privacy policy, please contact us at: nunu.ai privacy team, email: privacy@nunu.ai, address: 123 innovation drive, suite 456, san francisco, ca 94105, united states, phone: +1 (555) 123-4567. for gdpr-related inquiries, contact our data protection officer at dpo@nunu.ai.',
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget buildRateApp() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 48)),
                const SizedBox(height: 16),
                const Text(
                  'enjoying the app?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'we\'d love to hear your feedback! tap a star to rate us.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) => 
                    GestureDetector(
                      onTap: () {
                        showSnackBar('thanks for rating ${index + 1} stars!', NunuColors.successMain);
                        goBack();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.star_outline,
                          color: NunuColors.warningMain,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: goBack,
                  child: const Text('maybe later'),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
  
  // ============================================================
  // SUPPORT SCREENS
  // ============================================================
  
  Widget buildFaq() {
    final faqs = [
      {'q': 'how do i reset my password?', 'a': 'go to account > change password and follow the instructions.'},
      {'q': 'can i use multiple devices?', 'a': 'yes, you can sign in on up to 5 devices simultaneously.'},
      {'q': 'how do i enable dark mode?', 'a': 'navigate to display & theme and toggle the dark mode switch.'},
      {'q': 'where can i view my data?', 'a': 'go to privacy & security > your data to download or manage your information.'},
      {'q': 'how do i delete my account?', 'a': 'visit account settings and scroll to the bottom to find the delete account option.'},
    ];
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: faqs.asMap().entries.map((entry) {
              final faq = entry.value;
              final isLast = entry.key == faqs.length - 1;
              return Column(
                children: [
                  ExpansionTile(
                    title: Text(
                      faq['q']!,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    iconColor: NunuColors.primaryLight,
                    collapsedIconColor: NunuColors.textSecondary,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Text(
                          faq['a']!,
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  if (!isLast) const SettingsDivider(),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
  
  Widget buildContactSupport() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'contact support',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: subjectController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  labelText: 'subject',
                  hintText: 'what is this about?',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: messageController,
                style: const TextStyle(color: Colors.white),
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'message',
                  hintText: 'describe your issue...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  showSnackBar('message sent! we\'ll respond within 24 hours.', NunuColors.successMain);
                  goBack();
                },
                child: const Text('send message'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget buildSendFeedback() {
    final feedbackController = TextEditingController();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'send feedback',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'we value your input! let us know how we can improve.',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: feedbackController,
                style: const TextStyle(color: Colors.white),
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'share your thoughts...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  showSnackBar('thank you for your feedback!', NunuColors.successMain);
                  goBack();
                },
                child: const Text('submit feedback'),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget buildReportBug() {
    final descriptionController = TextEditingController();
    final stepsController = TextEditingController();
    
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Row(
                children: [
                  Icon(Icons.bug_report, color: NunuColors.errorMain),
                  SizedBox(width: 8),
                  Text(
                    'report a bug',
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'describe the bug',
                  hintText: 'what happened?',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stepsController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'steps to reproduce',
                  hintText: '1. go to...\n2. tap on...\n3. see error',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  showSnackBar('bug report submitted. thank you!', NunuColors.successMain);
                  goBack();
                },
                icon: const Icon(Icons.send),
                label: const Text('submit report'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Helper widget for legal sections
class _LegalSection extends StatelessWidget {
  final String title;
  final String content;
  
  const _LegalSection({required this.title, required this.content});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: NunuColors.primaryLight,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

