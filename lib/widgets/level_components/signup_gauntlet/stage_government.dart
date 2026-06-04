import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../services/notification_service.dart';
import 'credentials_sheet.dart';

/// Stage 3 — "The Government Portal" (MyGov Portal)
///
/// Traps:
///  1. Fields render progressively (email → username → password, 1.5s apart)
///     Typing before all fields load causes focus stealing
///  2. Username validation reveals rules one at a time
///  3. SSN field: label says "last 4 digits" but nearby label says "XXX-XX-XXXX"
///  4. Submit button: first click does nothing, second click works
///  5. Confirmation notification arrives after 8-second delay
///  6. Login: "User ID" only accepts username, not email
///  7. Login: show/hide password toggle corrupts the last character
///  8. Login: "Acknowledge" modal unresponsive for 2 seconds
class StageGovernment extends StatefulWidget {
  final void Function(double score, Map<String, dynamic> metrics) onComplete;
  const StageGovernment({super.key, required this.onComplete});
  @override
  State<StageGovernment> createState() => _StageGovernmentState();
}

class _StageGovernmentState extends State<StageGovernment> {
  // ── target ──
  static const _email = 'pat.chen@webmail.com';
  static const _username = 'patchen90';
  static const _ssn4 = '5678';
  static const _password = 'G0vAccess!2025';
  static const _creds = {
    'email:': _email,
    'username:': _username,
    'ssn last 4:': _ssn4,
    'password:': _password,
  };

  // ── progressive rendering ──
  bool _emailVisible = false;
  bool _usernameVisible = false;
  bool _passwordVisible = false;
  bool _ssnVisible = false;
  bool _submitVisible = false;
  final FocusNode _emailFocus = FocusNode();
  final FocusNode _userFocus = FocusNode();
  final FocusNode _passFocus = FocusNode();
  final FocusNode _ssnFocus = FocusNode();

  // ── phase ──
  bool _isLogin = false;
  bool _showVerification = false;
  bool _showMaintenanceModal = false;

  // ── signup form ──
  final _signupKey = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _userCtl = TextEditingController();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  final _ssnCtl = TextEditingController();
  bool _obscure = true;
  bool _confirmObscure = true;
  bool _signupLoading = false;
  int _submitClicks = 0;
  bool _showDuplicate = false;

  // ── verification ──
  late String _verifyCode;
  final _verifyCtl = TextEditingController();
  bool _notificationSent = false;
  bool _permissionsGranted = false;

  // ── login ──
  final _loginKey = GlobalKey<FormState>();
  final _loginIdCtl = TextEditingController();
  final _loginPassCtl = TextEditingController();
  bool _loginObscure = true;
  bool _loginPassCorrupted = false;
  bool _loginLoading = false;
  bool _modalClickable = false;
  bool _showCheckbox = false;

  // ── scoring ──
  bool _signupDone = false;
  bool _verifyDone = false;
  bool _loginDone = false;
  int _trapsFallen = 0;
  bool _doubleClicked = false;
  bool _toggledShowHide = false;
  int _duplicateWaitSeconds = 10;

  @override
  void initState() {
    super.initState();
    _verifyCode = List.generate(6, (_) => Random().nextInt(10)).join();
    _requestPermissions();
    _startProgressiveRendering();
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService().requestPermissions();
    setState(() => _permissionsGranted = granted);
  }

  void _startProgressiveRendering() {
    // Fields appear one by one
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _emailVisible = true);
      _emailFocus.requestFocus();
    });
    Future.delayed(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      setState(() => _usernameVisible = true);
      // TRAP: steal focus to the new field
      _userFocus.requestFocus();
    });
    Future.delayed(const Duration(milliseconds: 10000), () {
      if (!mounted) return;
      setState(() {
        _passwordVisible = true;
        _ssnVisible = true;
      });
      _passFocus.requestFocus();
    });
    Future.delayed(const Duration(milliseconds: 13000), () {
      if (!mounted) return;
      setState(() => _submitVisible = true);
    });
  }

  @override
  void dispose() {
    _emailCtl.dispose();
    _userCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    _ssnCtl.dispose();
    _emailFocus.dispose();
    _userFocus.dispose();
    _passFocus.dispose();
    _ssnFocus.dispose();
    _verifyCtl.dispose();
    _loginIdCtl.dispose();
    _loginPassCtl.dispose();
    super.dispose();
  }

  // ── handlers ──

  void _handleSignup() {
    // First click does nothing
    _submitClicks++;
    if (_submitClicks == 1) return;

    // Third+ click shows "duplicate submission" for 30s
    if (_submitClicks > 2) {
      _doubleClicked = true;
      _trapsFallen++;
      const waitSeconds = 10;
      setState(() {
        _showDuplicate = true;
        _duplicateWaitSeconds = waitSeconds;
      });
      Future.delayed(const Duration(seconds: waitSeconds), () {
        if (mounted) {
          setState(() {
            _showDuplicate = false;
            // Let the user recover after the timeout instead of
            // permanently re-triggering the duplicate submission trap.
            _submitClicks = 1;
          });
        }
      });
      return;
    }

    // Second click — actual submit
    if (!_signupKey.currentState!.validate()) return;
    if (_emailCtl.text.trim() != _email ||
        _userCtl.text.trim() != _username ||
        _passCtl.text != _password ||
        _ssnCtl.text.trim() != _ssn4) {
      _submitClicks = 1;
      _snack('signup details do not match');
      return;
    }

    setState(() => _signupLoading = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _signupLoading = false;
        _signupDone = true;
        _showVerification = true;
      });
      // Send notification after 8 second delay
      Future.delayed(const Duration(seconds: 8), () {
        if (!mounted) return;
        _notificationSent = true;
        if (_permissionsGranted) {
          NotificationService().showGeneric(
            id: 30,
            title: 'MyGov Portal — Account Confirmation',
            body: 'Your confirmation code is: $_verifyCode',
            channelId: 'gov_verify',
            channelName: 'Government Verification',
          );
        }
      });
    });
  }

  void _handleVerify() {
    if (_verifyCtl.text == _verifyCode) {
      setState(() {
        _verifyDone = true;
        _showVerification = false;
        _isLogin = true;
      });
    } else {
      _snack('invalid confirmation code');
    }
  }

  void _handleLogin() {
    if (!_loginKey.currentState!.validate()) return;

    // Only accepts username, NOT email
    if (_loginIdCtl.text != _username) {
      if (_loginIdCtl.text.contains('@')) {
        _snack('account not found');
      } else {
        _snack('account not found');
      }
      return;
    }
    if (_loginPassCtl.text != _password) {
      _snack('incorrect password');
      return;
    }

    setState(() => _loginLoading = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      setState(() {
        _loginLoading = false;
        _loginDone = true;
        _showMaintenanceModal = true;
      });
      // Modal unresponsive for 2 seconds
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) setState(() => _modalClickable = true);
      });
    });
  }

  void _finish() {
    double score = 0;
    if (_signupDone) score += 0.35;
    if (_verifyDone) score += 0.10;
    if (_loginDone) score += 0.35;
    if (!_doubleClicked) score += 0.10;
    if (!_toggledShowHide) score += 0.05;
    score += 0.05; // maintenance modal
    widget.onComplete(
        score.clamp(0.0, 1.0), {'traps_fallen': _trapsFallen});
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  static const _gray = Color(0xFF37474F);
  static const _navy = Color(0xFF263238);

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: const ColorScheme.light(
          primary: _gray,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        textTheme: baseTheme.textTheme.apply(
          bodyColor: Colors.black87,
          displayColor: Colors.black87,
        ),
        inputDecorationTheme: baseTheme.inputDecorationTheme.copyWith(
          labelStyle: TextStyle(color: Colors.grey.shade700),
          floatingLabelStyle: const TextStyle(color: Colors.black87),
          hintStyle: TextStyle(color: Colors.grey.shade600),
          helperStyle: TextStyle(color: Colors.grey.shade600),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        hintColor: Colors.grey,
        canvasColor: Colors.white,
      ),
      child: Stack(
        children: [
          Container(
            color: const Color(0xFFF0F0F0),
            child: SafeArea(
              child: Column(
                children: [
                  _buildGovHeader(),
                  Expanded(
                    child: _showVerification
                        ? _buildVerification()
                        : _isLogin
                            ? _buildLogin()
                            : _buildSignup(),
                  ),
                  const CredentialsFab(credentials: _creds),
                ],
              ),
            ),
          ),
          if (_showDuplicate) _buildDuplicateWarning(),
          if (_showMaintenanceModal) _buildMaintenanceModal(),
        ],
      ),
    );
  }

  Widget _buildGovHeader() {
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.assured_workload, color: Colors.white70, size: 22),
          const SizedBox(width: 8),
          const Text('MyGov Portal',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.shade800,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('.GOV',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSignup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _signupKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Loading indicator while fields render
            if (!_submitVisible)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(minHeight: 2),
              ),

            // Email — appears first
            if (_emailVisible)
              _animatedField(
                child: TextFormField(
                  controller: _emailCtl,
                  focusNode: _emailFocus,
                  decoration: _deco('email address'),
                  validator: (v) => v!.isEmpty ? 'required' : null,
                ),
              ),
            if (_emailVisible) const SizedBox(height: 12),

            // Username — appears 1.5s later, steals focus
            if (_usernameVisible)
              _animatedField(
                child: TextFormField(
                  controller: _userCtl,
                  focusNode: _userFocus,
                  decoration: _deco('username').copyWith(
                    helperText: '8-15 characters',
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'required';
                    // One error at a time
                    if (v.length < 8 || v.length > 15) {
                      return 'username must be between 8 and 15 characters';
                    }
                    if (RegExp(r'^[0-9]').hasMatch(v)) {
                      return 'username cannot start with a number';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9]+$').hasMatch(v)) {
                      return 'alphanumeric characters only';
                    }
                    return null;
                  },
                ),
              ),
            if (_usernameVisible) const SizedBox(height: 12),

            // Password + SSN — appear last
            if (_passwordVisible) ...[
              _animatedField(
                child: TextFormField(
                  controller: _passCtl,
                  focusNode: _passFocus,
                  obscureText: _obscure,
                  decoration: _deco('password').copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v!.isEmpty) return 'required';
                    if (v.length < 8) return 'min 8 characters';
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 12),
              _animatedField(
                child: TextFormField(
                  controller: _confirmCtl,
                  obscureText: _confirmObscure,
                  decoration: _deco('confirm password'),
                  validator: (v) {
                    if (v != _passCtl.text) return 'passwords do not match';
                    return null;
                  },
                ),
              ),
            ],
            if (_passwordVisible) const SizedBox(height: 12),

            if (_ssnVisible) ...[
              _animatedField(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _ssnCtl,
                      focusNode: _ssnFocus,
                      obscureText: true,
                      maxLength: 4,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly
                      ],
                      decoration: _deco('social security number (last 4 digits)')
                          .copyWith(counterText: ''),
                      validator: (v) {
                        if (v!.isEmpty) return 'required';
                        if (v.length != 4) return 'enter exactly 4 digits';
                        return null;
                      },
                    ),
                    // TRAP: leftover label from full SSN field
                    Padding(
                      padding: const EdgeInsets.only(left: 12, top: 4),
                      child: Text('format: XXX-XX-XXXX',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500)),
                    ),
                  ],
                ),
              ),
            ],
            if (_ssnVisible) const SizedBox(height: 20),

            // Submit — first click does nothing
            if (_submitVisible)
              FilledButton(
                onPressed: _signupLoading ? null : _handleSignup,
                style: FilledButton.styleFrom(
                  backgroundColor: _gray,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _signupLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('CREATE ACCOUNT',
                        style: TextStyle(fontWeight: FontWeight.bold)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _animatedField({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (_, opacity, c) => Opacity(opacity: opacity, child: c),
      child: child,
    );
  }

  // ── verification ──

  Widget _buildVerification() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read, size: 48, color: _gray),
          const SizedBox(height: 16),
          const Text('a confirmation email has been sent',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text(
              'check your notifications for the verification code',
              style: TextStyle(color: Colors.black54)),
          if (!_notificationSent) ...[
            const SizedBox(height: 16),
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 8),
            const Text('sending...',
                style: TextStyle(fontSize: 12, color: Colors.black38)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: 200,
            child: TextFormField(
              controller: _verifyCtl,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 6, color: Colors.black87),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _handleVerify,
            style: FilledButton.styleFrom(
              backgroundColor: _gray,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
            ),
            child: const Text('CONFIRM'),
          ),
        ],
      ),
    );
  }

  // ── login ──

  Widget _buildLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _loginKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TRAP: labeled "User ID" with confusing placeholder
            TextFormField(
              controller: _loginIdCtl,
              decoration: _deco('user ID').copyWith(
                hintText: 'enter your User ID (username or email)',
                hintStyle:
                    TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 12),
            // TRAP: show/hide corrupts password
            TextFormField(
              controller: _loginPassCtl,
              obscureText: _loginObscure,
              decoration: _deco('password').copyWith(
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Show password checkbox
                    Checkbox(
                      value: _showCheckbox,
                      onChanged: (v) {
                        _toggledShowHide = true;
                        _trapsFallen++;
                        final text = _loginPassCtl.text;
                        setState(() {
                          _showCheckbox = v ?? false;
                          _loginObscure = !_showCheckbox;
                        });
                        // TRAP: when hiding (unchecking), corrupt last char
                        if (!_showCheckbox && text.isNotEmpty) {
                          _loginPassCtl.text =
                              '${text.substring(0, text.length - 1)}\u2022';
                          _loginPassCorrupted = true;
                        }
                      },
                    ),
                    const Text('show',
                        style:
                            TextStyle(fontSize: 11, color: Colors.black45)),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _loginLoading ? null : _handleLogin,
              style: FilledButton.styleFrom(
                backgroundColor: _gray,
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
        ),
      ),
    );
  }

  // ── overlays ──

  Widget _buildDuplicateWarning() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 40),
                const SizedBox(height: 12),
                const Text('duplicate submission detected',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('please wait $_duplicateWaitSeconds seconds before trying again.',
                    style: const TextStyle(color: Colors.black54),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.construction, color: Colors.amber, size: 24),
                    SizedBox(width: 8),
                    Text('system maintenance notice',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'scheduled maintenance will occur on Saturday, April 19, 2026 from 2:00 AM to 6:00 AM EST. '
                  'during this time, some services may be unavailable. we apologize for any inconvenience. '
                  'if you experience issues, please contact support at 1-800-MYGOV-HELP. '
                  'this notice is provided in accordance with federal IT policy directive 12-09.',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () {
                        // Wrong button — goes back to login
                        setState(() => _showMaintenanceModal = false);
                        setState(() {
                          _loginDone = false;
                          _isLogin = true;
                        });
                      },
                      child: const Text('return to login',
                          style: TextStyle(fontSize: 13)),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _modalClickable
                          ? () {
                              setState(
                                  () => _showMaintenanceModal = false);
                              _finish();
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _gray,
                        disabledBackgroundColor: Colors.grey.shade300,
                      ),
                      child: const Text('acknowledge'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── shared ──

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade400)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _gray, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
    );
  }
}
