import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../services/notification_service.dart';
import 'credentials_sheet.dart';

/// Stage 4 — "The Social Media App" (Vibes)
///
/// Traps:
///  1. Conversational chat-style signup (one question at a time in bubbles)
///  2. Chat input doesn't clear between questions
///  3. Password suggestion chip replaces whatever is in the field
///  4. Username availability: flash red for 0.5s, no persistent error
///  5. "Choose interests" screen — must select 3, Skip only visible after scroll
///  6. Verification code buried in welcome notification
///  7. Login: email/password behind "More options" link (nearly invisible)
///  8. Login: 3 post-login interstitials before completion
class StageSocial extends StatefulWidget {
  final void Function(double score, Map<String, dynamic> metrics) onComplete;
  const StageSocial({super.key, required this.onComplete});
  @override
  State<StageSocial> createState() => _StageSocialState();
}

enum _SocialPhase {
  formSignup,
  interests,
  verification,
  login,
  interstitial1, // notifications prompt
  interstitial2, // who to follow
  interstitial3, // profile picture
}

class _StageSocialState extends State<StageSocial> {
  // ── target ──
  static const _email = 'sam.riley@inbox.com';
  static const _username = 'samvibes';
  static const _password = 'Vibe\$Check42';
  static const _suggestedPassword = 'xK9#mQ2\$pL';
  static const _creds = {
    'email:': _email,
    'username:': _username,
    'password:': _password,
  };

  // ── phase ──
  _SocialPhase _phase = _SocialPhase.formSignup;

  // ── form signup ──
  final _emailCtl = TextEditingController();
  final _usernameCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _emailFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _showSuggestion = false;
  bool _suggestionTapped = false;
  bool _usernameFlashRed = false;
  bool _usernameFocusStolen = false; // trap: only steals once
  int _submitAttempts = 0;

  // ── interests ──
  final Set<int> _selectedInterests = {};
  final _interestScrollCtl = ScrollController();
  bool _scrolledToBottom = false;

  // ── verification ──
  late String _verifyCode;
  final _verifyCtl = TextEditingController();
  bool _permissionsGranted = false;

  // ── login ──
  bool _showEmailLogin = false;
  final _loginEmailCtl = TextEditingController();
  final _loginPassCtl = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;

  // ── scoring ──
  int _trapsFallen = 0;
  bool _signupDone = false;
  bool _interestsDone = false;
  bool _verifyDone = false;
  bool _loginDone = false;

  static const _interests = [
    'music', 'gaming', 'fashion', 'food', 'travel', 'sports',
    'tech', 'art', 'fitness', 'movies', 'books', 'photography',
    'nature', 'comedy', 'science', 'pets', 'diy', 'dance',
  ];

  @override
  void initState() {
    super.initState();
    _verifyCode = List.generate(4, (_) => Random().nextInt(10)).join();
    _requestPermissions();
    _usernameFocus.addListener(_onUsernameFocusChange);
    _passwordFocus.addListener(_onPasswordFocusChange);
    _interestScrollCtl.addListener(() {
      if (_interestScrollCtl.position.pixels >=
          _interestScrollCtl.position.maxScrollExtent - 20) {
        _scrolledToBottom = true;
      }
    });
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService().requestPermissions();
    setState(() => _permissionsGranted = granted);
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _usernameCtl.dispose();
    _passCtl.dispose();
    _emailFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _verifyCtl.dispose();
    _loginEmailCtl.dispose();
    _loginPassCtl.dispose();
    _interestScrollCtl.dispose();
    super.dispose();
  }

  void _onUsernameFocusChange() {
    if (!_usernameFocus.hasFocus && _usernameCtl.text.isNotEmpty) {
      // TRAP: flash red on blur
      setState(() => _usernameFlashRed = true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _usernameFlashRed = false);
        // TRAP: steal focus back to username once, forcing re-navigation to password
        if (!_usernameFocusStolen) {
          _usernameFocusStolen = true;
          _usernameFocus.requestFocus();
        }
      });
    }
  }

  void _onPasswordFocusChange() {
    if (_passwordFocus.hasFocus) {
      setState(() => _showSuggestion = true);
    }
  }

  void _tapSuggestion() {
    // TRAP: replaces whatever is in the field, suggestion disappears
    setState(() {
      _passCtl.text = _suggestedPassword;
      _passCtl.selection =
          TextSelection.collapsed(offset: _suggestedPassword.length);
      _showSuggestion = false;
      _suggestionTapped = true;
      _trapsFallen++;
    });
  }

  void _handleSignupSubmit() {
    _submitAttempts++;
    // TRAP: first submit nukes the whole form with a fake crash error
    if (_submitAttempts == 1) {
      setState(() {
        _emailCtl.clear();
        _usernameCtl.clear();
        _passCtl.clear();
        _showSuggestion = false;
        _usernameFocusStolen = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Error: Failed to initialize session. Unexpected state. Please try again.',
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
      _emailFocus.requestFocus();
      return;
    }
    if (_emailCtl.text.trim() != _email ||
        _usernameCtl.text.trim() != _username ||
        _passCtl.text != _password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('signup details do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    _signupDone = true;
    setState(() => _phase = _SocialPhase.interests);
  }

  void _handleInterestsDone() {
    if (_selectedInterests.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('select at least 3 interests'),
            backgroundColor: Colors.red),
      );
      return;
    }
    _interestsDone = true;
    setState(() => _phase = _SocialPhase.verification);

    // Send notification with code buried in welcome text
    if (_permissionsGranted) {
      NotificationService().showGeneric(
        id: 40,
        title: '🎉 Welcome to Vibes!',
        body:
            '{"ok":true,"event":"email_verify","payload":{"code":"$_verifyCode","ttl":600,"user_id":"v_${_verifyCode.hashCode.abs() % 90000 + 10000}"},"msg":"Welcome to Vibes! Start discovering content now!"}',
        channelId: 'social_verify',
        channelName: 'Vibes',
      );
    }
  }

  void _handleVerify() {
    if (_verifyCtl.text == _verifyCode) {
      _verifyDone = true;
      setState(() => _phase = _SocialPhase.login);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('invalid code'), backgroundColor: Colors.red),
      );
    }
  }

  void _handleLogin() {
    if (_loginEmailCtl.text != _email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('account not found'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (_loginPassCtl.text != _password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('wrong password'),
            backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _loginLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      _loginDone = true;
      setState(() => _phase = _SocialPhase.interstitial1);
    });
  }

  void _finish() {
    double score = 0;
    if (_signupDone) score += 0.30;
    if (_interestsDone) score += 0.05;
    if (_verifyDone) score += 0.10;
    if (_loginDone) score += 0.30;
    score += 0.15; // interstitials dismissed
    if (!_suggestionTapped) score += 0.05;
    score += 0.05; // completion bonus
    widget.onComplete(
        score.clamp(0.0, 1.0), {'traps_fallen': _trapsFallen});
  }

  static const _purple = Color(0xFF7B1FA2);
  static const _gradient = [Color(0xFF9C27B0), Color(0xFF7B1FA2)];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: switch (_phase) {
            _SocialPhase.formSignup => _buildSignupForm(),
            _SocialPhase.interests => _buildInterests(),
            _SocialPhase.verification => _buildVerification(),
            _SocialPhase.login => _buildLogin(),
            _SocialPhase.interstitial1 => _buildInterstitial(
                icon: Icons.notifications_outlined,
                title: 'turn on notifications?',
                subtitle: 'never miss a vibe from people you follow',
                primaryLabel: 'TURN ON',
                dismissLabel: 'not now',
                onDismiss: () =>
                    setState(() => _phase = _SocialPhase.interstitial2),
              ),
            _SocialPhase.interstitial2 => _buildInterstitial(
                icon: Icons.people_outline,
                title: 'who to follow',
                subtitle: 'find friends and creators',
                primaryLabel: 'FIND FRIENDS',
                dismissLabel: null,
                onDismiss: () =>
                    setState(() => _phase = _SocialPhase.interstitial3),
              ),
            _SocialPhase.interstitial3 => _buildInterstitial(
                icon: Icons.camera_alt_outlined,
                title: 'add a profile picture',
                subtitle: 'let people know who you are',
                primaryLabel: 'UPLOAD PHOTO',
                dismissLabel: 'skip for now',
                onDismiss: _finish,
              ),
          },
        ),
        const CredentialsFab(credentials: _creds),
      ],
    );
  }

  // ── form signup ──

  Widget _buildSignupForm() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _vibesHeader(),
              const SizedBox(height: 8),
              // TRAP: title and subtitle poorly spaced / overlapping feel
              Stack(
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'create account ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -4,
                    right: 0,
                    child: Text(
                      'join the vibe',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.3),
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              // TRAP: floatingLabelBehavior.never — label stays inside, overlaps typed text
              TextField(
                controller: _emailCtl,
                focusNode: _emailFocus,
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.emailAddress,
                decoration: _vibeDeco('email address'),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _usernameCtl,
                focusNode: _usernameFocus,
                style: const TextStyle(color: Colors.white),
                decoration: _vibeDeco('username').copyWith(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _usernameFlashRed
                          ? Colors.red
                          : Colors.white.withValues(alpha: 0.2),
                      width: _usernameFlashRed ? 2 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: _usernameFlashRed ? Colors.red : _purple,
                      width: 2,
                    ),
                  ),
                  suffixIcon: _usernameFlashRed
                      ? const Icon(Icons.error_outline,
                          color: Colors.red, size: 18)
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              // TRAP: suggestion chip appears when password focused
              if (_showSuggestion)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: GestureDetector(
                      onTap: _tapSuggestion,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade900,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.purple.shade300, width: 1),
                        ),
                        child: Text('suggested: $_suggestedPassword',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.purple.shade200)),
                      ),
                    ),
                  ),
                ),
              TextField(
                controller: _passCtl,
                focusNode: _passwordFocus,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: _vibeDeco('password'),
              ),
              const SizedBox(height: 28),
              FilledButton(
                onPressed: _handleSignupSubmit,
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'CREATE ACCOUNT',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _vibeDeco(String label) {
    // TRAP: floatingLabelBehavior.never — label stays inside field and overlaps typed text
    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.never,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.07),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // ── interests ──

  Widget _buildInterests() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _vibesHeader(),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('what are you into?',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('pick at least 3 to personalize your feed',
                  style: TextStyle(color: Colors.white60, fontSize: 14)),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                controller: _interestScrollCtl,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 2.2,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: _interests.length,
                itemBuilder: (_, i) {
                  final selected = _selectedInterests.contains(i);
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        if (selected) {
                          _selectedInterests.remove(i);
                        } else {
                          _selectedInterests.add(i);
                        }
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? _purple
                            : Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected
                              ? _purple
                              : Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(_interests[i],
                          style: TextStyle(
                            color: selected ? Colors.white : Colors.white70,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          )),
                    ),
                  );
                },
              ),
            ),
            // Skip — only shows after scrolling
            if (_scrolledToBottom)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextButton(
                  onPressed: _handleInterestsDone,
                  child: Text('skip',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.3),
                          fontSize: 12)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _handleInterestsDone,
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('CONTINUE',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── verification ──

  Widget _buildVerification() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.mark_email_read,
                  size: 48, color: Colors.white),
              const SizedBox(height: 16),
              const Text('check your notifications',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('enter the code from your welcome notification',
                  style: TextStyle(color: Colors.white60)),
              const SizedBox(height: 24),
              SizedBox(
                width: 150,
                child: TextField(
                  controller: _verifyCtl,
                  maxLength: 4,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      letterSpacing: 8,
                      fontWeight: FontWeight.bold),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    counterText: '',
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.white30),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _purple, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _handleVerify,
                style: FilledButton.styleFrom(
                  backgroundColor: _purple,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 48, vertical: 14),
                ),
                child: const Text('VERIFY'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── login ──

  Widget _buildLogin() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _vibesHeader(),
              const SizedBox(height: 32),
              // Prominent social login buttons
              _socialButton(
                  Icons.g_mobiledata, 'continue with google', Colors.white),
              const SizedBox(height: 12),
              _socialButton(
                  Icons.apple, 'continue with apple', Colors.white),
              const SizedBox(height: 24),

              if (!_showEmailLogin) ...[
                // TRAP: "More options" is barely visible
                Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _showEmailLogin = true),
                    child: Text(
                      'more options',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Email/password form (revealed)
                TextField(
                  controller: _loginEmailCtl,
                  style: const TextStyle(color: Colors.white),
                  decoration: _socialDeco('email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _loginPassCtl,
                  obscureText: _loginObscure,
                  style: const TextStyle(color: Colors.white),
                  decoration: _socialDeco('password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _loginObscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white30),
                      onPressed: () =>
                          setState(() => _loginObscure = !_loginObscure),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _loginLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: _purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loginLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('LOG IN',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _socialButton(IconData icon, String label, Color bg) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: Colors.white70),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  // ── interstitials ──

  Widget _buildInterstitial({
    required IconData icon,
    required String title,
    required String subtitle,
    required String primaryLabel,
    required String? dismissLabel,
    required VoidCallback onDismiss,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              // Small × in corner for interstitials without dismiss label
              if (dismissLabel == null)
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: onDismiss,
                    child: const Icon(Icons.close,
                        color: Colors.white30, size: 20),
                  ),
                ),
              const Spacer(),
              Icon(icon, size: 64, color: _purple),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: () {}, // decoy — does nothing useful
                  style: FilledButton.styleFrom(backgroundColor: _purple),
                  child: Text(primaryLabel),
                ),
              ),
              const Spacer(),
              if (dismissLabel != null)
                GestureDetector(
                  onTap: onDismiss,
                  child: Text(dismissLabel,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.25),
                          fontSize: 12)),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── shared ──

  Widget _vibesHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: _purple, size: 24),
          const SizedBox(width: 8),
          ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: _gradient,
            ).createShader(rect),
            child: const Text('vibes',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  InputDecoration _socialDeco(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.white24),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _purple, width: 2),
      ),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }
}
