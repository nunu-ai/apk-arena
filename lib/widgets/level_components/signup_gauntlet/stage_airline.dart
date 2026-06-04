import 'package:flutter/material.dart';
import 'credentials_sheet.dart';

/// Stage 1 — "The Airline" (FlyBudget)
///
/// Traps:
///  1. Cookie banner: "Accept All" opens marketing prefs, must close with ×
///  2. Title dropdown required but not marked as required
///  3. Password hint says min 6, validates min 8
///  4. Phone +41 re-prepends on blur
///  5. Upsell interstitial with hidden "No thanks"
///  6. Login: pre-filled with wrong email (no dot)
///  7. Login: "Skip" button grayed for 3 seconds
class StageAirline extends StatefulWidget {
  final void Function(double score, Map<String, dynamic> metrics) onComplete;
  const StageAirline({super.key, required this.onComplete});
  @override
  State<StageAirline> createState() => _StageAirlineState();
}

class _StageAirlineState extends State<StageAirline> {
  // ── target credentials ──
  static const _email = 'alex.torres@gmail.com';
  static const _password = 'Fly2025!Safe';
  static const _phone = '7712345678';
  static const _wrongEmail = 'alextorres@gmail.com';

  static const _creds = {
    'title:': 'Mr',
    'email:': _email,
    'password:': _password,
    'phone:': _phone,
  };

  // ── overlays ──
  bool _showCookie = true;
  bool _showMarketingPrefs = false;
  bool _showUpsell = false;
  bool _showProfileModal = false;

  // ── phase ──
  bool _isLogin = false;

  // ── trap tracking ──
  bool _fellCookie = false;
  bool _fellUpsell = false;

  // ── signup form ──
  final _signupKey = GlobalKey<FormState>();
  String? _title;
  final _emailCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _phoneCtl = TextEditingController(text: '+41 ');
  final _phoneFocus = FocusNode();
  bool _obscure = true;
  bool _signupLoading = false;

  // ── login form ──
  final _loginKey = GlobalKey<FormState>();
  late final TextEditingController _loginEmailCtl;
  final _loginPassCtl = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;
  bool _skipEnabled = false;

  // ── scoring flags ──
  bool _signupDone = false;
  bool _loginDone = false;
  bool _upsellDismissed = false;
  bool _profileDismissed = false;
  bool _cookieDismissed = false;

  @override
  void initState() {
    super.initState();
    _loginEmailCtl = TextEditingController(text: _wrongEmail);
    _phoneFocus.addListener(_onPhoneBlur);
  }

  void _onPhoneBlur() {
    if (!_phoneFocus.hasFocus) {
      final t = _phoneCtl.text;
      if (!t.startsWith('+41 ')) {
        _phoneCtl.text = '+41 $t';
        _phoneCtl.selection =
            TextSelection.collapsed(offset: _phoneCtl.text.length);
      }
    }
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _passCtl.dispose();
    _phoneCtl.dispose();
    _phoneFocus.dispose();
    _loginEmailCtl.dispose();
    _loginPassCtl.dispose();
    super.dispose();
  }

  // ── handlers ──

  void _handleSignup() {
    if (_title == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('please complete all fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!_signupKey.currentState!.validate()) return;
    final phone = _phoneCtl.text.replaceFirst('+41 ', '').trim();
    if (_title != 'Mr' ||
        _emailCtl.text.trim() != _email ||
        _passCtl.text != _password ||
        phone != _phone) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('signup details do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _signupLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _signupLoading = false;
        _signupDone = true;
        _showUpsell = true;
      });
    });
  }

  void _handleLogin() {
    if (!_loginKey.currentState!.validate()) return;

    if (_loginEmailCtl.text != _email) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('account not found'), backgroundColor: Colors.red),
      );
      return;
    }
    if (_loginPassCtl.text != _password) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('incorrect password'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _loginLoading = true);
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _loginLoading = false;
        _loginDone = true;
        _showProfileModal = true;
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) setState(() => _skipEnabled = true);
      });
    });
  }

  void _finish() {
    double score = 0;
    int traps = 0;
    if (_cookieDismissed) score += 0.10;
    if (_signupDone) score += 0.35;
    if (_upsellDismissed) score += 0.05;
    if (_loginDone) score += 0.35;
    if (_profileDismissed) score += 0.10;
    if (!_fellCookie && _cookieDismissed) score += 0.025;
    if (!_fellUpsell && _upsellDismissed) score += 0.025;
    if (_fellCookie) {
      score -= 0.05;
      traps++;
    }
    if (_fellUpsell) {
      score -= 0.05;
      traps++;
    }
    widget.onComplete(score.clamp(0.0, 1.0), {'traps_fallen': traps});
  }

  // ── build ──

  @override
  Widget build(BuildContext context) {
    // Force light theme so text is readable on white/light backgrounds
    return Theme(
      data: ThemeData.light().copyWith(
        colorScheme: ColorScheme.light(
          primary: const Color(0xFF1565C0),
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
      ),
      child: Stack(
        children: [
          Container(
            color: const Color(0xFFF5F5F5),
            child: SafeArea(
              child: Column(
                children: [
                  Expanded(child: _isLogin ? _buildLogin() : _buildSignup()),
                  CredentialsFab(credentials: _creds),
                ],
              ),
            ),
          ),
          if (_showCookie) _buildCookieBanner(),
          if (_showMarketingPrefs) _buildMarketingModal(),
          if (_showUpsell) _buildUpsellOverlay(),
          if (_showProfileModal) _buildProfileModal(),
        ],
      ),
    );
  }

  // ───────────── SIGNUP ─────────────

  Widget _buildSignup() {
    const blue = Color(0xFF1565C0);
    const orange = Color(0xFFFF8F00);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.flight, color: blue, size: 28),
              const SizedBox(width: 8),
              const Text('FlyBudget',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: blue)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: orange,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('SIGN UP',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 24),

          Form(
            key: _signupKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title dropdown — required but NO asterisk
                DropdownButtonFormField<String>(
                  value: _title,
                  decoration: _inputDeco('title', Icons.person_outline),
                  dropdownColor: Colors.white,
                  style: const TextStyle(color: Colors.black87, fontSize: 14),
                  items: const [
                    DropdownMenuItem(value: 'Mr', child: Text('Mr')),
                    DropdownMenuItem(value: 'Mrs', child: Text('Mrs')),
                    DropdownMenuItem(value: 'Ms', child: Text('Ms')),
                    DropdownMenuItem(value: 'Dr', child: Text('Dr')),
                    DropdownMenuItem(value: 'Other', child: Text('Other')),
                  ],
                  onChanged: (v) => setState(() => _title = v),
                ),
                const SizedBox(height: 12),

                // Email — narrow (truncates long emails)
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: _emailCtl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: _inputDeco('email *', Icons.email_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'required';
                      if (!v.contains('@')) return 'enter a valid email';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Password — says "minimum 6 characters" but validates 8
                TextFormField(
                  controller: _passCtl,
                  obscureText: _obscure,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration: _inputDeco('password *', Icons.lock_outline)
                      .copyWith(
                    helperText: 'minimum 6 characters',
                    helperStyle: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'required';
                    if (v.length < 8) {
                      return 'password does not meet requirements';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Phone — pre-filled +41, re-prepends on blur
                Focus(
                  onFocusChange: (hasFocus) {
                    if (!hasFocus) _onPhoneBlur();
                  },
                  child: TextFormField(
                    controller: _phoneCtl,
                    focusNode: _phoneFocus,
                    keyboardType: TextInputType.phone,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration:
                        _inputDeco('phone number *', Icons.phone_outlined),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'required';
                      final local = v.replaceFirst('+41 ', '').trim();
                      if (local.length < 6) return 'enter a valid number';
                      return null;
                    },
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _signupLoading ? null : _handleSignup,
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _signupLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('CREATE ACCOUNT',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── LOGIN ─────────────

  Widget _buildLogin() {
    const blue = Color(0xFF1565C0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.flight, color: blue, size: 28),
              const SizedBox(width: 8),
              const Text('FlyBudget',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: blue)),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('LOG IN',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
              ),
            ],
          ),
          const Divider(height: 24),

          // Notice: autocomplete filled your email
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline,
                    color: Colors.blue.shade400, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'we filled your email from your last visit',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          Form(
            key: _loginKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 180,
                  child: TextFormField(
                    controller: _loginEmailCtl,
                    style:
                        const TextStyle(fontSize: 14, color: Colors.black87),
                    decoration: _inputDeco('email', Icons.email_outlined),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'required' : null,
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _loginPassCtl,
                  obscureText: _loginObscure,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                  decoration:
                      _inputDeco('password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                          _loginObscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.grey),
                      onPressed: () =>
                          setState(() => _loginObscure = !_loginObscure),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'required' : null,
                ),
                const SizedBox(height: 24),

                SizedBox(
                  height: 48,
                  child: FilledButton(
                    onPressed: _loginLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                      backgroundColor: blue,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _loginLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('LOG IN',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ───────────── OVERLAYS ─────────────

  Widget _buildCookieBanner() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                    color: Colors.black26,
                    blurRadius: 12,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('🍪', style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('we use cookies',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87)),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showCookie = false;
                          _showMarketingPrefs = false;
                          _cookieDismissed = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            size: 18, color: Colors.grey.shade400),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'we use cookies to personalize your travel experience and show relevant offers.',
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 16),

                SizedBox(
                  height: 44,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _showCookie = false;
                        _cookieDismissed = true;
                      });
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('ACCEPT ALL COOKIES',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _fellCookie = true;
                        _showMarketingPrefs = true;
                      });
                    },
                    child: Text('manage preferences',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade500)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMarketingModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('marketing preferences',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87)),
                const SizedBox(height: 16),
                _marketingToggle('personalized offers', true),
                _marketingToggle('partner deals', true),
                _marketingToggle('email newsletters', true),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    setState(() => _showMarketingPrefs = false);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('SAVE PREFERENCES'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _marketingToggle(String label, bool initial) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.black87))),
          Switch(
            value: initial,
            onChanged: (_) {},
            activeColor: const Color(0xFF1565C0),
          ),
        ],
      ),
    );
  }

  Widget _buildUpsellOverlay() {
    const blue = Color(0xFF1565C0);
    return Positioned.fill(
      child: Container(
        color: Colors.white,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(flex: 2),
                const Icon(Icons.star, color: Colors.amber, size: 64),
                const SizedBox(height: 16),
                const Text('PRIORITY ACCESS',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: blue)),
                const SizedBox(height: 8),
                Text('skip every queue. board first. live better.',
                    style:
                        TextStyle(fontSize: 16, color: Colors.grey.shade600),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: blue),
                  ),
                  child: const Column(
                    children: [
                      Text('only',
                          style: TextStyle(color: Colors.black54)),
                      Text('€4.99/month',
                          style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: blue)),
                      SizedBox(height: 8),
                      Text('cancel anytime*',
                          style: TextStyle(
                              fontSize: 11, color: Colors.black38)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => _fellUpsell = true);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('subscription added to your account!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('GET PRIORITY ACCESS',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const Spacer(flex: 3),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showUpsell = false;
                      _upsellDismissed = true;
                      _isLogin = true;
                    });
                  },
                  child: Text(
                    "no, i don't want to save money",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade300,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_circle,
                    size: 48, color: Color(0xFF1565C0)),
                const SizedBox(height: 12),
                const Text('complete your profile',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.black87)),
                const SizedBox(height: 8),
                Text(
                    'add a profile picture and travel preferences to get personalized deals.',
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                    textAlign: TextAlign.center),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1565C0)),
                    child: const Text('COMPLETE PROFILE'),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _skipEnabled
                      ? () {
                          setState(() {
                            _showProfileModal = false;
                            _profileDismissed = true;
                          });
                          _finish();
                        }
                      : null,
                  child: Text(
                    'skip',
                    style: TextStyle(
                      color: _skipEnabled
                          ? const Color(0xFF1565C0)
                          : Colors.grey.shade300,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ───────────── SHARED ─────────────

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0), size: 20),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide:
              const BorderSide(color: Color(0xFF1565C0), width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
