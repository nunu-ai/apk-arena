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
  chatSignup,
  interests,
  verification,
  login,
  interstitial1, // notifications prompt
  interstitial2, // who to follow
  interstitial3, // profile picture
}

enum _ChatStep { email, username, password, done }

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
  _SocialPhase _phase = _SocialPhase.chatSignup;
  _ChatStep _chatStep = _ChatStep.email;

  // ── chat signup ──
  final _chatCtl = TextEditingController();
  final List<_ChatMessage> _messages = [];
  String _enteredEmail = '';
  String _enteredUsername = '';
  String _enteredPassword = '';
  bool _showSuggestion = false;
  bool _suggestionTapped = false;
  bool _usernameFlashRed = false;

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
    _addBotMessage("hey! what's your email? 💌");
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
    _chatCtl.dispose();
    _verifyCtl.dispose();
    _loginEmailCtl.dispose();
    _loginPassCtl.dispose();
    _interestScrollCtl.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    _messages.add(_ChatMessage(text: text, isUser: false));
  }

  void _sendChat() {
    final text = _chatCtl.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      // TRAP: input does NOT clear
    });

    switch (_chatStep) {
      case _ChatStep.email:
        _enteredEmail = text;
        _chatStep = _ChatStep.username;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() => _addBotMessage("cool! now pick a username 🎯"));
        });
        break;
      case _ChatStep.username:
        _enteredUsername = text;
        // Flash red for taken username check (visual only — it's always "available")
        setState(() => _usernameFlashRed = true);
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() => _usernameFlashRed = false);
        });
        _chatStep = _ChatStep.password;
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          setState(() {
            _addBotMessage("nice! last thing — set a password 🔒");
            _showSuggestion = true;
          });
        });
        break;
      case _ChatStep.password:
        _enteredPassword = text;
        _chatStep = _ChatStep.done;
        _signupDone = true;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (!mounted) return;
          setState(() {
            _addBotMessage("you're all set! 🎉");
            _phase = _SocialPhase.interests;
          });
        });
        break;
      case _ChatStep.done:
        break;
    }
  }

  void _tapSuggestion() {
    // TRAP: replaces whatever is in the field, suggestion disappears
    setState(() {
      _chatCtl.text = _suggestedPassword;
      _chatCtl.selection =
          TextSelection.collapsed(offset: _suggestedPassword.length);
      _showSuggestion = false;
      _suggestionTapped = true;
      _trapsFallen++;
    });
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
            'Welcome to Vibes! Your code is $_verifyCode. Start discovering content now!',
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
    return Stack(
      children: [
        switch (_phase) {
          _SocialPhase.chatSignup => _buildChat(),
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
        const CredentialsFab(credentials: _creds),
      ],
    );
  }

  // ── chat signup ──

  Widget _buildChat() {
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
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _messages.length,
                itemBuilder: (_, i) => _buildBubble(_messages[i]),
              ),
            ),
            // Password suggestion chip
            if (_showSuggestion && _chatStep == _ChatStep.password)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _tapSuggestion,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('suggested: $_suggestedPassword',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.purple.shade800)),
                    ),
                  ),
                ),
              ),
            // Chat input
            Container(
              color: const Color(0xFF1A1A2E),
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatCtl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: _chatStep == _ChatStep.email
                            ? 'type your email...'
                            : _chatStep == _ChatStep.username
                                ? 'type a username...'
                                : 'type a password...',
                        hintStyle: TextStyle(color: Colors.grey.shade600),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: _usernameFlashRed
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: _usernameFlashRed
                              ? const BorderSide(color: Colors.red, width: 2)
                              : BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: _purple,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 18),
                      onPressed: _chatStep != _ChatStep.done ? _sendChat : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: msg.isUser
              ? _purple
              : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isUser ? Colors.white : Colors.white70,
            fontSize: 14,
          ),
        ),
      ),
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
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF16213E)
                            .withValues(alpha: 0.3), // nearly invisible
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

class _ChatMessage {
  final String text;
  final bool isUser;
  const _ChatMessage({required this.text, required this.isUser});
}
