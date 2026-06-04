import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../services/notification_service.dart';
import 'credentials_sheet.dart';

/// Stage 5 — "The Enterprise SaaS" (SynergyOS)
///
/// Traps:
///  1. "Start Free Trial" opens demo request modal — real signup link below fold
///  2. Work email required (rejects gmail/yahoo/hotmail)
///  3. Company autocomplete: after 3 chars, auto-selects on blur
///  4. Breached password rejection for common passwords
///  5. Role "Other" leaves hidden field that causes 422
///  6. Two-step login: email first, password appears after, premature submit clears email
///  7. Workspace selector: real vs archived workspace
///  8. 2FA auto-formats with dash (XXX-XXX), breaks paste
class StageEnterprise extends StatefulWidget {
  final void Function(double score, Map<String, dynamic> metrics) onComplete;
  const StageEnterprise({super.key, required this.onComplete});
  @override
  State<StageEnterprise> createState() => _StageEnterpriseState();
}

enum _EntPhase {
  landing, // "Start Free Trial" bait
  signup,
  verification,
  workspaceSetup,
  login,
  loginPassword, // second step
  workspaceSelect,
  twoFA,
}

class _StageEnterpriseState extends State<StageEnterprise> {
  // ── target ──
  static const _company = 'Quantum Dynamics';
  static const _workEmail = 'morgan.lee@quantumdyn.com';
  static const _fullName = 'Morgan Lee';
  static const _role = 'Engineer';
  static const _password = 'Entr8prise!Pwd';
  static const _creds = {
    'company:': _company,
    'email:': _workEmail,
    'name:': _fullName,
    'role:': _role,
    'password:': _password,
  };

  // ── phase ──
  _EntPhase _phase = _EntPhase.landing;
  bool _showDemoModal = false;

  // ── landing ──
  final ScrollController _landingScroll = ScrollController();

  // ── signup ──
  final _signupKey = GlobalKey<FormState>();
  final _companyCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _nameCtl = TextEditingController();
  String? _roleVal;
  final _customRoleCtl = TextEditingController();
  bool _showCustomRole = false;
  bool _roleWasOther = false; // TRAP: residual value
  final _passCtl = TextEditingController();
  bool _obscure = true;
  bool _signupLoading = false;
  bool _showAutocomplete = false;
  final FocusNode _companyFocus = FocusNode();

  // ── verification ──
  late String _verifyCode;
  bool _verified = false;
  bool _staleState = true; // needs refresh
  bool _permissionsGranted = false;

  // ── workspace setup ──
  final _wsNameCtl = TextEditingController();
  String? _timezone;

  // ── login ──
  final _loginEmailCtl = TextEditingController();
  final _loginPassCtl = TextEditingController();
  bool _loginObscure = true;
  bool _passwordVisible = false;
  bool _loginLoading = false;

  // ── workspace select ──
  int? _selectedWorkspace;

  // ── 2FA ──
  late String _tfaCode;
  final _tfaCtl = TextEditingController();
  String _formattedTfa = '';

  // ── scoring ──
  int _trapsFallen = 0;
  bool _signupDone = false;
  bool _verifyDone = false;
  bool _setupDone = false;
  bool _loginDone = false;
  bool _fellForDemo = false;
  bool _fellForAutocomplete = false;
  bool _fellForBreached = false;
  bool _selectedArchived = false;

  static const _breachedPasswords = [
    'Test123!', 'Password1!', 'Password123!', 'Qwerty123!',
    'Admin123!', 'Welcome1!', 'Changeme1!', 'Letmein123!',
  ];

  static const _autocompleteCompanies = [
    'Acme Corporation',
    'Quantum Computing Inc',
    'Quantum Industries',
    'QuickBooks LLC',
  ];

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _verifyCode = List.generate(6, (_) => rng.nextInt(10)).join();
    _tfaCode = List.generate(6, (_) => rng.nextInt(10)).join();
    _requestPermissions();
    _companyFocus.addListener(() {
      if (!_companyFocus.hasFocus && _showAutocomplete) {
        // TRAP: auto-select top result on blur
        setState(() {
          if (_companyCtl.text.length >= 3 && _companyCtl.text != _company) {
            _fellForAutocomplete = true;
            _trapsFallen++;
          }
          _companyCtl.text = _autocompleteCompanies.first;
          _showAutocomplete = false;
        });
      }
    });
    _tfaCtl.addListener(_formatTfa);
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService().requestPermissions();
    setState(() => _permissionsGranted = granted);
  }

  void _formatTfa() {
    final raw = _tfaCtl.text.replaceAll('-', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.length > 3) {
      _formattedTfa = '${raw.substring(0, 3)}-${raw.substring(3)}';
    } else {
      _formattedTfa = raw;
    }
    // Don't update controller here — let the formatting happen display-side
  }

  @override
  void dispose() {
    _companyCtl.dispose();
    _emailCtl.dispose();
    _nameCtl.dispose();
    _customRoleCtl.dispose();
    _passCtl.dispose();
    _companyFocus.dispose();
    _wsNameCtl.dispose();
    _loginEmailCtl.dispose();
    _loginPassCtl.dispose();
    _tfaCtl.dispose();
    _landingScroll.dispose();
    super.dispose();
  }

  // ── handlers ──

  void _handleSignup() {
    if (!_signupKey.currentState!.validate()) return;

    // Check breached passwords
    if (_breachedPasswords.contains(_passCtl.text)) {
      _fellForBreached = true;
      _trapsFallen++;
      _snack(
          'this password has appeared in a data breach. please choose another.');
      return;
    }

    // TRAP: if role was ever "Other" but changed, residual custom role causes 422
    if (_roleWasOther && _roleVal != 'Other' && _customRoleCtl.text.isNotEmpty) {
      _snack('an unexpected error occurred');
      return;
    }
    if (_companyCtl.text.trim() != _company ||
        _emailCtl.text.trim() != _workEmail ||
        _nameCtl.text.trim() != _fullName ||
        _roleVal != _role ||
        _passCtl.text != _password) {
      _snack('signup details do not match');
      return;
    }

    setState(() => _signupLoading = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      _signupDone = true;
      setState(() {
        _signupLoading = false;
        _phase = _EntPhase.verification;
      });
      // Send verification notification
      if (_permissionsGranted) {
        NotificationService().showGeneric(
          id: 50,
          title: 'SynergyOS — Verify Your Email',
          body:
              'Click to verify your email. Verification code: $_verifyCode. Return to the app after verifying.',
          channelId: 'enterprise_verify',
          channelName: 'SynergyOS',
        );
      }
    });
  }

  void _handleVerify() {
    setState(() {
      _verified = true;
      _staleState = false;
      _verifyDone = true;
      _wsNameCtl.text = _company.toLowerCase().replaceAll(' ', '');
      _phase = _EntPhase.workspaceSetup;
    });
  }

  void _handleWorkspaceSetup() {
    if (_timezone == null) {
      _snack('please select a timezone');
      return;
    }
    _setupDone = true;
    setState(() => _phase = _EntPhase.login);
  }

  void _handleLoginEmail() {
    if (_loginEmailCtl.text.isEmpty) {
      _snack('email is required');
      return;
    }
    // TRAP: if password field not visible yet but user clicks, submit with no password
    if (!_passwordVisible) {
      setState(() => _passwordVisible = true);
      // Button changes to "Log In" during animation
      return;
    }
    // If password is visible, treat as full submit
    _handleLoginFull();
  }

  void _handleLoginFull() {
    if (_loginPassCtl.text.isEmpty) {
      // Premature submit — clears email too
      setState(() {
        _loginEmailCtl.clear();
        _passwordVisible = false;
      });
      _snack('incorrect password');
      return;
    }
    if (_loginEmailCtl.text != _workEmail || _loginPassCtl.text != _password) {
      _snack('invalid credentials');
      return;
    }
    setState(() {
      _loginLoading = true;
    });
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _loginLoading = false;
        _phase = _EntPhase.workspaceSelect;
      });
    });
  }

  void _handleWorkspaceSelect() {
    if (_selectedWorkspace == null) {
      _snack('please select a workspace');
      return;
    }
    if (_selectedWorkspace == 1) {
      _selectedArchived = true;
      _trapsFallen++;
      _snack('this workspace is no longer active. contact your admin.');
      setState(() => _selectedWorkspace = null);
      return;
    }
    setState(() => _phase = _EntPhase.twoFA);
    // Send 2FA
    if (_permissionsGranted) {
      NotificationService().showGeneric(
        id: 51,
        title: 'SynergyOS Security',
        body: 'Your verification code is $_tfaCode',
        channelId: 'enterprise_2fa',
        channelName: 'SynergyOS 2FA',
      );
    }
  }

  void _handleTfa() {
    // Extract digits from formatted input
    final entered = _tfaCtl.text.replaceAll('-', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (entered == _tfaCode) {
      _loginDone = true;
      _finish();
    } else {
      _snack('invalid verification code');
    }
  }

  void _finish() {
    double score = 0;
    if (!_fellForDemo) score += 0.05;
    if (_signupDone) score += 0.25;
    if (_verifyDone) score += 0.10;
    if (_setupDone) score += 0.05;
    if (_loginDone) score += 0.30;
    if (!_selectedArchived) score += 0.05;
    score += 0.10; // 2FA
    if (!_fellForAutocomplete) score += 0.05;
    if (!_fellForBreached) score += 0.05;
    widget.onComplete(
        score.clamp(0.0, 1.0), {'traps_fallen': _trapsFallen});
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  static const _teal = Color(0xFF00695C);
  static const _dark = Color(0xFF1B2631);

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData.light();
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: const ColorScheme.light(
          primary: _teal,
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
            color: const Color(0xFFF5F6FA),
            child: SafeArea(
              child: Column(
                children: [
                  _buildSaasHeader(),
                  Expanded(child: _buildPhase()),
                  const CredentialsFab(credentials: _creds),
                ],
              ),
            ),
          ),
          if (_showDemoModal) _buildDemoModal(),
        ],
      ),
    );
  }

  Widget _buildSaasHeader() {
    return Container(
      color: _dark,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          const Icon(Icons.hub, color: _teal, size: 22),
          const SizedBox(width: 8),
          const Text('SynergyOS',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _teal,
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Text('PRO',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPhase() {
    switch (_phase) {
      case _EntPhase.landing:
        return _buildLanding();
      case _EntPhase.signup:
        return _buildSignup();
      case _EntPhase.verification:
        return _buildVerification();
      case _EntPhase.workspaceSetup:
        return _buildWorkspaceSetup();
      case _EntPhase.login:
      case _EntPhase.loginPassword:
        return _buildLogin();
      case _EntPhase.workspaceSelect:
        return _buildWorkspaceSelect();
      case _EntPhase.twoFA:
        return _build2FA();
    }
  }

  // ── landing ──

  Widget _buildLanding() {
    return SingleChildScrollView(
      controller: _landingScroll,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 40),
          const Text('streamline your workflow',
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1B2631)),
              textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              'the all-in-one platform trusted by 10,000+ teams worldwide',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center),
          const SizedBox(height: 32),

          // TRAP: "Start Free Trial" opens demo request modal
          SizedBox(
            height: 52,
            child: FilledButton(
              onPressed: () {
                _fellForDemo = true;
                _trapsFallen++;
                setState(() => _showDemoModal = true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('START FREE TRIAL',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 200), // push real link below fold

          // Real signup link — below the fold
          Center(
            child: GestureDetector(
              onTap: () => setState(() => _phase = _EntPhase.signup),
              child: Text(
                'or create an account instantly →',
                style: TextStyle(
                    fontSize: 13,
                    color: _teal.withValues(alpha: 0.7),
                    decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDemoModal() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('request a demo',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _showDemoModal = false),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                    "a product specialist will reach out within 24 hours to schedule your personalized demo.",
                    style: TextStyle(fontSize: 13, color: Colors.black54)),
                const SizedBox(height: 16),
                TextField(decoration: _entDeco('work email')),
                const SizedBox(height: 12),
                TextField(decoration: _entDeco('company')),
                const SizedBox(height: 12),
                TextField(decoration: _entDeco('phone number')),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => setState(() => _showDemoModal = false),
                  style: FilledButton.styleFrom(backgroundColor: _teal),
                  child: const Text('REQUEST DEMO'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── signup ──

  Widget _buildSignup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _signupKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('create your account',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
            const SizedBox(height: 16),

            // Company — with autocomplete trap
            Stack(
              clipBehavior: Clip.none,
              children: [
                TextFormField(
                  controller: _companyCtl,
                  focusNode: _companyFocus,
                  decoration: _entDeco('company name'),
                  onChanged: (v) {
                    setState(() => _showAutocomplete = v.length >= 3);
                  },
                  validator: (v) => v!.isEmpty ? 'required' : null,
                ),
                if (_showAutocomplete)
                  Positioned(
                    top: 56,
                    left: 0,
                    right: 0,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(8),
                      child: Column(
                        children: _autocompleteCompanies.map((c) {
                          return ListTile(
                            dense: true,
                            title: Text(c, style: const TextStyle(fontSize: 13)),
                            onTap: () {
                              setState(() {
                                _companyCtl.text = c;
                                _showAutocomplete = false;
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Work email — rejects consumer domains
            TextFormField(
              controller: _emailCtl,
              decoration: _entDeco('work email'),
              validator: (v) {
                if (v!.isEmpty) return 'required';
                final lower = v.toLowerCase();
                if (lower.endsWith('@gmail.com') ||
                    lower.endsWith('@yahoo.com') ||
                    lower.endsWith('@hotmail.com') ||
                    lower.endsWith('@outlook.com')) {
                  return 'please use a work email address';
                }
                if (!v.contains('@')) return 'enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _nameCtl,
              decoration: _entDeco('full name'),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 12),

            // Role dropdown — "Other" shows custom field
            DropdownButtonFormField<String>(
              value: _roleVal,
              decoration: _entDeco('role'),
              items: const [
                DropdownMenuItem(value: 'Engineer', child: Text('Engineer')),
                DropdownMenuItem(value: 'Designer', child: Text('Designer')),
                DropdownMenuItem(value: 'Manager', child: Text('Manager')),
                DropdownMenuItem(
                    value: 'Executive', child: Text('Executive')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (v) {
                setState(() {
                  if (v == 'Other') _roleWasOther = true;
                  _roleVal = v;
                  _showCustomRole = v == 'Other';
                });
              },
              validator: (v) => v == null ? 'required' : null,
            ),
            if (_showCustomRole) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customRoleCtl,
                decoration: _entDeco('custom role'),
              ),
            ],
            const SizedBox(height: 12),

            // Password — breached check
            TextFormField(
              controller: _passCtl,
              obscureText: _obscure,
              decoration: _entDeco('password').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(_obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
              validator: (v) {
                if (v!.isEmpty) return 'required';
                if (v.length < 8) return 'min 8 characters';
                return null;
              },
            ),
            const SizedBox(height: 24),

            FilledButton(
              onPressed: _signupLoading ? null : _handleSignup,
              style: FilledButton.styleFrom(
                backgroundColor: _teal,
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

  // ── verification ──

  Widget _buildVerification() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mark_email_read, size: 48, color: _teal),
          const SizedBox(height: 16),
          Text(
            _staleState
                ? 'waiting for email verification...'
                : 'email verified!',
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
          ),
          if (_staleState) ...[
            const SizedBox(height: 8),
            const Text('check your notification and enter the code below',
                style: TextStyle(color: Colors.black54),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: TextField(
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
                onChanged: (v) {
                  if (v == _verifyCode) _handleVerify();
                },
              ),
            ),
            const SizedBox(height: 16),
            // Pull to refresh hint
            Text('if status doesn\'t update, pull down to refresh',
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade400)),
          ],
          if (!_staleState) ...[
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () =>
                  setState(() => _phase = _EntPhase.workspaceSetup),
              style: FilledButton.styleFrom(backgroundColor: _teal),
              child: const Text('CONTINUE'),
            ),
          ],
        ],
      ),
    );
  }

  // ── workspace setup ──

  Widget _buildWorkspaceSetup() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('set up your workspace',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 16),
          TextFormField(
            controller: _wsNameCtl,
            decoration: _entDeco('workspace name'),
          ),
          const SizedBox(height: 12),
          // Workspace URL — read-only looking but actually read-only
          TextFormField(
            readOnly: true,
            initialValue:
                '${_company.toLowerCase().replaceAll(' ', '')}.synergyos.com',
            decoration: _entDeco('workspace URL'),
            style: TextStyle(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _timezone,
            decoration: _entDeco('timezone'),
            items: const [
              DropdownMenuItem(value: 'UTC', child: Text('UTC')),
              DropdownMenuItem(
                  value: 'US/Eastern', child: Text('US/Eastern')),
              DropdownMenuItem(
                  value: 'US/Central', child: Text('US/Central')),
              DropdownMenuItem(
                  value: 'US/Pacific', child: Text('US/Pacific')),
              DropdownMenuItem(
                  value: 'Europe/London', child: Text('Europe/London')),
              DropdownMenuItem(
                  value: 'Europe/Berlin', child: Text('Europe/Berlin')),
              DropdownMenuItem(
                  value: 'Asia/Tokyo', child: Text('Asia/Tokyo')),
            ],
            onChanged: (v) => setState(() => _timezone = v),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _handleWorkspaceSetup,
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('CREATE WORKSPACE',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── login ──

  Widget _buildLogin() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('log in to SynergyOS',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 16),
          TextField(
            controller: _loginEmailCtl,
            decoration: _entDeco('work email'),
          ),
          // Password — only visible after first "Continue" click
          if (_passwordVisible) ...[
            const SizedBox(height: 12),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              builder: (_, opacity, child) =>
                  Opacity(opacity: opacity, child: child),
              child: Column(
                children: [
                  TextField(
                    controller: _loginPassCtl,
                    obscureText: _loginObscure,
                    decoration: _entDeco('password').copyWith(
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TRAP: "Forgot password?" ambiguously close to field
                          GestureDetector(
                            onTap: () => _snack(
                                'password reset email sent (not really)'),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Text('forgot?',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500)),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_loginObscure
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                            onPressed: () => setState(
                                () => _loginObscure = !_loginObscure),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loginLoading ? null : _handleLoginEmail,
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _loginLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(_passwordVisible ? 'LOG IN' : 'CONTINUE',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── workspace select ──

  Widget _buildWorkspaceSelect() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('select a workspace',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 16),
          _workspaceTile(0, _company, 'active', _teal),
          const SizedBox(height: 8),
          _workspaceTile(
              1,
              '${_company.split(' ').first} Corp',
              'archived',
              Colors.grey),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _handleWorkspaceSelect,
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('CONTINUE',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _workspaceTile(int idx, String name, String status, Color accent) {
    final selected = _selectedWorkspace == idx;
    return GestureDetector(
      onTap: () => setState(() => _selectedWorkspace = idx),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: selected ? accent : Colors.grey.shade300, width: 2),
          color: selected ? accent.withValues(alpha: 0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(Icons.workspaces, color: accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  Text(status,
                      style: TextStyle(
                          fontSize: 12,
                          color: status == 'archived'
                              ? Colors.orange
                              : Colors.green)),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: Colors.green),
          ],
        ),
      ),
    );
  }

  // ── 2FA ──

  Widget _build2FA() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security, size: 48, color: _teal),
          const SizedBox(height: 16),
          const Text('two-factor authentication',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87)),
          const SizedBox(height: 8),
          const Text('enter the 6-digit code from your notification',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          // TRAP: auto-formats with dash (XXX-XXX)
          SizedBox(
            width: 200,
            child: TextField(
              controller: _tfaCtl,
              maxLength: 7, // 6 digits + 1 dash
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 4, color: Colors.black87),
              inputFormatters: [
                _DashFormatter(), // auto-inserts dash after 3 digits
              ],
              decoration: InputDecoration(
                counterText: '',
                hintText: '___-___',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _handleTfa,
            style: FilledButton.styleFrom(
              backgroundColor: _teal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
            ),
            child: const Text('VERIFY',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── shared ──

  InputDecoration _entDeco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _teal, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
    );
  }
}

/// Input formatter that auto-inserts a dash after the 3rd digit.
class _DashFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = newValue.text.replaceAll('-', '').replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 6) {
      final trimmed = digits.substring(0, 6);
      final formatted = '${trimmed.substring(0, 3)}-${trimmed.substring(3)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    if (digits.length > 3) {
      final formatted =
          '${digits.substring(0, 3)}-${digits.substring(3)}';
      return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length),
      );
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}
