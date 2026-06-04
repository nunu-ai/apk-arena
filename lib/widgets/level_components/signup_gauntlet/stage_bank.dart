import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../../../services/notification_service.dart';
import 'credentials_sheet.dart';

/// Stage 2 — "The Bank" (TrustVault)
///
/// Traps:
///  1. 4-step wizard with DOB as 3 dropdowns (year starts at 2025, scroll up)
///  2. Going back at any point invalidates the session → restart
///  3. Confirm-password has invisible trailing whitespace
///  4. Email verification via verbose notification (extract code)
///  5. Login: TWO notifications — correct code + decoy
///  6. Wrong 2FA clears password field too
class StageBank extends StatefulWidget {
  final void Function(double score, Map<String, dynamic> metrics) onComplete;
  const StageBank({super.key, required this.onComplete});
  @override
  State<StageBank> createState() => _StageBankState();
}

class _StageBankState extends State<StageBank> {
  // ── target credentials ──
  static const _email = 'jordan.mitchell@email.com';
  static const _phone = '555-0142';
  static const _street = '742 Evergreen Terrace';
  static const _apt = '3B';
  static const _city = 'Springfield';
  static const _state = 'IL';
  static const _zip = '62704';
  static const _password = 'Bank\$ecure99';
  static const _creds = {
    'name:': 'Jordan Mitchell',
    'dob:': 'march 15, 1990',
    'email:': _email,
    'phone:': _phone,
    'address:': '$_street, $_apt, $_city, $_state $_zip',
    'password:': _password,
    'q1 answer:': 'Linda Rose Henderson',
    'q2 answer:': 'Portland, OR 97201',
    'q3 answer:': 'Maximilian the Third',
  };

  // ── phase ──
  int _wizardStep = 0; // 0-3 for signup steps, 4 = verification, 5 = login
  bool _isLogin = false;
  bool _sessionInvalid = false;
  bool _wentBack = false;

  // ── signup step 1 ──
  final _step1Key = GlobalKey<FormState>();
  final _fnCtl = TextEditingController();
  final _lnCtl = TextEditingController();
  int? _dobMonth;
  int? _dobDay;
  int? _dobYear;

  // ── signup step 2 ──
  final _step2Key = GlobalKey<FormState>();
  final _emailCtl = TextEditingController();
  final _phoneCtl = TextEditingController();
  final _streetCtl = TextEditingController();
  final _aptCtl = TextEditingController();
  final _cityCtl = TextEditingController();
  String? _stateVal;
  final _zipCtl = TextEditingController();

  // ── signup step 3 ──
  final _step3Key = GlobalKey<FormState>();
  final _passCtl = TextEditingController();
  final _confirmCtl = TextEditingController();
  String? _sq1;
  String? _sq2;
  String? _sq3;
  final _sa1Ctl = TextEditingController();
  final _sa2Ctl = TextEditingController();
  final _sa3Ctl = TextEditingController();
  bool _obscure = true;

  // ── verification ──
  late String _verifyCode;
  final _verifyCtl = TextEditingController();
  bool _verifyLoading = false;
  bool _permissionsGranted = false;

  // ── login ──
  final _loginKey = GlobalKey<FormState>();
  final _loginEmailCtl = TextEditingController();
  final _loginPassCtl = TextEditingController();
  final _loginCodeCtl = TextEditingController();
  bool _loginObscure = true;
  bool _loginLoading = false;
  bool _show2FA = false;
  late String _loginCode;
  late String _decoyCode;

  // ── scoring ──
  bool _signupDone = false;
  bool _verifyDone = false;
  bool _loginDone = false;
  int _trapsFallen = 0;
  bool _usedDecoy = false;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _verifyCode = List.generate(6, (_) => rng.nextInt(10)).join();
    _loginCode = List.generate(5, (_) => rng.nextInt(10)).join();
    _decoyCode = List.generate(5, (_) => rng.nextInt(10)).join();
    while (_decoyCode == _loginCode) {
      _decoyCode = List.generate(5, (_) => rng.nextInt(10)).join();
    }
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final granted = await NotificationService().requestPermissions();
    setState(() => _permissionsGranted = granted);
  }

  @override
  void dispose() {
    _fnCtl.dispose();
    _lnCtl.dispose();
    _emailCtl.dispose();
    _phoneCtl.dispose();
    _streetCtl.dispose();
    _aptCtl.dispose();
    _cityCtl.dispose();
    _zipCtl.dispose();
    _passCtl.dispose();
    _confirmCtl.dispose();
    _sa1Ctl.dispose();
    _sa2Ctl.dispose();
    _sa3Ctl.dispose();
    _verifyCtl.dispose();
    _loginEmailCtl.dispose();
    _loginPassCtl.dispose();
    _loginCodeCtl.dispose();
    super.dispose();
  }

  // ── wizard navigation ──

  void _nextStep() {
    switch (_wizardStep) {
      case 0:
        if (!_step1Key.currentState!.validate()) return;
        if (_dobMonth == null || _dobDay == null || _dobYear == null) {
          _snack('please select your full date of birth');
          return;
        }
        break;
      case 1:
        if (!_step2Key.currentState!.validate()) return;
        if (_stateVal == null) {
          _snack('please select a state');
          return;
        }
        break;
      case 2:
        if (!_step3Key.currentState!.validate()) return;
        // Confirm password has trailing whitespace injected
        final pass = _passCtl.text;
        final confirm = _confirmCtl.text.trimRight();
        if (pass != confirm) {
          _snack('passwords do not match');
          return;
        }
        if (_sq1 == null || _sq2 == null || _sq3 == null) {
          _snack('please select all security questions');
          return;
        }
        break;
      case 3:
        // Submit — check session
        if (_wentBack) {
          setState(() => _sessionInvalid = true);
          return;
        }
        if (!_signupDetailsMatch()) {
          _snack('signup details do not match');
          return;
        }
        _signupDone = true;
        _sendVerification();
        break;
    }
    if (_wizardStep < 3) {
      setState(() => _wizardStep++);
    }
  }

  void _prevStep() {
    if (_wizardStep > 0) {
      _wentBack = true;
      _trapsFallen++;
      setState(() => _wizardStep--);
    }
  }

  bool _signupDetailsMatch() {
    return _fnCtl.text.trim() == 'Jordan' &&
        _lnCtl.text.trim() == 'Mitchell' &&
        _dobMonth == 3 &&
        _dobDay == 15 &&
        _dobYear == 1990 &&
        _emailCtl.text.trim() == _email &&
        _phoneCtl.text.trim() == _phone &&
        _streetCtl.text.trim() == _street &&
        _aptCtl.text.trim() == _apt &&
        _cityCtl.text.trim() == _city &&
        _stateVal == _state &&
        _zipCtl.text.trim() == _zip &&
        _passCtl.text == _password;
  }

  void _sendVerification() {
    setState(() => _wizardStep = 4);
    if (_permissionsGranted) {
      NotificationService().showGeneric(
        id: 10,
        title: 'TrustVault — Email Verification',
        body:
            'Your verification code is: $_verifyCode. If you did not request this, call 1-800-TRUSTVAULT immediately.',
        channelId: 'bank_verify',
        channelName: 'Bank Verification',
      );
    }
  }

  void _handleVerify() {
    if (_verifyCtl.text == _verifyCode) {
      setState(() {
        _verifyDone = true;
        _isLogin = true;
        _wizardStep = 5;
      });
    } else {
      _snack('invalid verification code');
    }
  }

  // ── login ──

  void _handleLogin() {
    if (!_loginKey.currentState!.validate()) return;
    if (_loginEmailCtl.text != _email || _loginPassCtl.text != _password) {
      _snack('invalid credentials');
      return;
    }
    setState(() => _loginLoading = true);

    // Send REAL code, then decoy 1.5s later
    if (_permissionsGranted) {
      NotificationService().showGeneric(
        id: 20,
        title: 'TrustVault Security',
        body: 'Your one-time code is $_loginCode',
        channelId: 'bank_2fa',
        channelName: 'Bank 2FA',
      );
      Future.delayed(const Duration(milliseconds: 1500), () {
        NotificationService().showGeneric(
          id: 21,
          title: 'TrustVault Security',
          body:
              'Reminder: never share your security code with anyone. Your code is $_decoyCode',
          channelId: 'bank_2fa',
          channelName: 'Bank 2FA',
        );
      });
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _loginLoading = false;
        _show2FA = true;
      });
    });
  }

  void _handleLoginCode() {
    final entered = _loginCodeCtl.text;
    if (entered == _loginCode) {
      _loginDone = true;
      _finish();
    } else if (entered == _decoyCode) {
      _usedDecoy = true;
      _trapsFallen++;
      // Wrong code clears password too
      setState(() {
        _loginCodeCtl.clear();
        _loginPassCtl.clear();
        _show2FA = false;
      });
      _snack('invalid code — please log in again');
    } else {
      // Wrong code clears password too
      setState(() {
        _loginCodeCtl.clear();
        _loginPassCtl.clear();
        _show2FA = false;
      });
      _snack('invalid code — please log in again');
    }
  }

  void _finish() {
    double score = 0;
    if (_signupDone) score += 0.35;
    if (_verifyDone) score += 0.15;
    if (_loginDone) score += 0.35;
    if (!_wentBack) score += 0.10;
    if (!_usedDecoy && _loginDone) score += 0.05;
    widget.onComplete(
        score.clamp(0.0, 1.0), {'traps_fallen': _trapsFallen});
  }

  void _resetAll() {
    setState(() {
      _wizardStep = 0;
      _sessionInvalid = false;
      _wentBack = false;
      _fnCtl.clear();
      _lnCtl.clear();
      _dobMonth = null;
      _dobDay = null;
      _dobYear = null;
      _emailCtl.clear();
      _phoneCtl.clear();
      _streetCtl.clear();
      _aptCtl.clear();
      _cityCtl.clear();
      _stateVal = null;
      _zipCtl.clear();
      _passCtl.clear();
      _confirmCtl.clear();
      _sq1 = null;
      _sq2 = null;
      _sq3 = null;
      _sa1Ctl.clear();
      _sa2Ctl.clear();
      _sa3Ctl.clear();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  // ── build ──

  static const _navy = Color(0xFF1A237E);
  static const _gold = Color(0xFFFFB300);

  @override
  Widget build(BuildContext context) {
    if (_sessionInvalid) return _buildSessionExpired();
    final baseTheme = ThemeData.light();
    return Theme(
      data: baseTheme.copyWith(
        colorScheme: const ColorScheme.light(
          primary: _navy,
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
            color: const Color(0xFFF8F8FC),
            child: SafeArea(
              child: Column(
                children: [
                  _buildHeader(),
                  if (_wizardStep < 4) _buildStepIndicator(),
                  Expanded(child: _buildCurrentStep()),
                  const CredentialsFab(credentials: _creds),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: _navy,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.shield, color: _gold, size: 24),
          const SizedBox(width: 8),
          const Text('TrustVault',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const Spacer(),
          Text(_isLogin ? 'LOG IN' : 'SIGN UP',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    final labels = ['personal', 'contact', 'security', 'review'];
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (i) {
          final active = i == _wizardStep;
          final done = i < _wizardStep;
          return Column(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor:
                    done ? Colors.green : active ? _navy : Colors.grey.shade300,
                child: done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text('${i + 1}',
                        style: TextStyle(
                            fontSize: 12,
                            color: active ? Colors.white : Colors.grey)),
              ),
              const SizedBox(height: 4),
              Text(labels[i],
                  style: TextStyle(
                      fontSize: 10,
                      color: active ? _navy : Colors.grey,
                      fontWeight:
                          active ? FontWeight.bold : FontWeight.normal)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_wizardStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4Review();
      case 4:
        return _buildVerification();
      default:
        return _buildLoginForm();
    }
  }

  // ── Step 1: Personal ──

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step1Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('personal information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _fnCtl,
              decoration: _deco('first name'),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _lnCtl,
              decoration: _deco('last name'),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 12),
            const Text('date of birth',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            Row(
              children: [
                // Month dropdown — full names
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _dobMonth,
                    decoration: _deco('month'),
                    isExpanded: true,
                    items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(_monthName(i + 1),
                                style: const TextStyle(fontSize: 13)))),
                    onChanged: (v) => setState(() => _dobMonth = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Day
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _dobDay,
                    decoration: _deco('day'),
                    isExpanded: true,
                    items: List.generate(
                        31,
                        (i) => DropdownMenuItem(
                            value: i + 1, child: Text('${i + 1}'))),
                    onChanged: (v) => setState(() => _dobDay = v),
                  ),
                ),
                const SizedBox(width: 8),
                // Year — starts at 2025, must scroll UP
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _dobYear,
                    decoration: _deco('year'),
                    isExpanded: true,
                    menuMaxHeight: 200,
                    items: List.generate(
                        126,
                        (i) => DropdownMenuItem(
                            value: 2025 - i,
                            child: Text('${2025 - i}'))),
                    onChanged: (v) => setState(() => _dobYear = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _navButtons(showBack: false),
          ],
        ),
      ),
    );
  }

  // ── Step 2: Contact ──

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step2Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('contact information',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtl,
              decoration: _deco('email'),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtl,
              decoration: _deco('phone'),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 16),
            const Text('address',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _streetCtl,
              decoration: _deco('street address'),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _aptCtl,
              decoration: _deco('apt / unit'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _cityCtl,
              decoration: _deco('city'),
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _stateVal,
              decoration: _deco('state'),
              isExpanded: true,
              menuMaxHeight: 200,
              items: _usStates
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _stateVal = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zipCtl,
              decoration: _deco('zip code'),
              keyboardType: TextInputType.number,
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 24),
            _navButtons(showBack: true),
          ],
        ),
      ),
    );
  }

  // ── Step 3: Security ──

  Widget _buildStep3() {
    const questions = [
      "what is your mother's maiden name?",
      'what city were you born in?',
      "what is your pet's name?",
      'what was your first car?',
      'what street did you grow up on?',
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _step3Key,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('security',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _passCtl,
              obscureText: _obscure,
              decoration: _deco('password').copyWith(
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
            const SizedBox(height: 12),
            // Confirm password — trailing whitespace injected
            TextFormField(
              controller: _confirmCtl,
              obscureText: _obscure,
              decoration: _deco('confirm password'),
              onChanged: (v) {
                // Silently append a trailing space on every change
                if (!v.endsWith(' ')) {
                  _confirmCtl.text = '$v ';
                  _confirmCtl.selection = TextSelection.collapsed(
                      offset: _confirmCtl.text.length - 1);
                }
              },
              validator: (v) => v!.isEmpty ? 'required' : null,
            ),
            const SizedBox(height: 16),
            const Text('suggested security questions',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            _securityQ('question 1', questions, _sq1,
                (v) => setState(() => _sq1 = v), _sa1Ctl, 15),
            const SizedBox(height: 12),
            _securityQ('question 2', questions, _sq2,
                (v) => setState(() => _sq2 = v), _sa2Ctl, 15),
            const SizedBox(height: 12),
            _securityQ('question 3', questions, _sq3,
                (v) => setState(() => _sq3 = v), _sa3Ctl, 15),
            const SizedBox(height: 24),
            _navButtons(showBack: true),
          ],
        ),
      ),
    );
  }

  Widget _securityQ(String label, List<String> options, String? value,
      ValueChanged<String?> onChanged, TextEditingController ctl, int maxLen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          value: value,
          decoration: _deco(label),
          isExpanded: true,
          items: options
              .map((q) => DropdownMenuItem(value: q, child: Text(q, style: const TextStyle(fontSize: 13))))
              .toList(),
          onChanged: onChanged,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: ctl,
          maxLength: maxLen, // silently truncates long answers
          decoration: _deco('answer').copyWith(counterText: ''),
          validator: (v) => v!.isEmpty ? 'required' : null,
        ),
      ],
    );
  }

  // ── Step 4: Review ──

  Widget _buildStep4Review() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('review your information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          _reviewRow('name', '${_fnCtl.text} ${_lnCtl.text}'),
          // DOB shown as numbers — agent might think it's wrong vs month name
          _reviewRow('date of birth',
              '${_dobMonth.toString().padLeft(2, '0')}/${_dobDay.toString().padLeft(2, '0')}/$_dobYear'),
          _reviewRow('email', _emailCtl.text),
          _reviewRow('phone', _phoneCtl.text),
          _reviewRow('address',
              '${_streetCtl.text}${_aptCtl.text.isEmpty ? '' : ', Apt ${_aptCtl.text}'}, ${_cityCtl.text}, $_stateVal ${_zipCtl.text}'),
          if (_aptCtl.text.isEmpty) _reviewRow('apt', '—'),
          _reviewRow('password', '••••••••'),
          _reviewRow('security q1', _sq1 ?? ''),
          _reviewRow('security q2', _sq2 ?? ''),
          _reviewRow('security q3', _sq3 ?? ''),
          const SizedBox(height: 24),
          _navButtons(showBack: true, isSubmit: true),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: Colors.black45)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ── Verification ──

  Widget _buildVerification() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.email_outlined, size: 48, color: _navy),
          const SizedBox(height: 16),
          const Text('verify your email',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          const SizedBox(height: 8),
          const Text('check your notifications for the 6-digit code',
              style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 24),
          // Input field is visually narrow (5 chars wide) but accepts 6
          SizedBox(
            width: 160,
            child: TextFormField(
              controller: _verifyCtl,
              maxLength: 6,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 28, letterSpacing: 6, fontWeight: FontWeight.bold),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _handleVerify,
            style: FilledButton.styleFrom(
              backgroundColor: _navy,
              padding:
                  const EdgeInsets.symmetric(horizontal: 48, vertical: 14),
            ),
            child: const Text('VERIFY'),
          ),
        ],
      ),
    );
  }

  // ── Login ──

  Widget _buildLoginForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!_show2FA) ...[
            Form(
              key: _loginKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _loginEmailCtl,
                    decoration: _deco('email'),
                    validator: (v) => v!.isEmpty ? 'required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _loginPassCtl,
                    obscureText: _loginObscure,
                    decoration: _deco('password').copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(_loginObscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined),
                        onPressed: () =>
                            setState(() => _loginObscure = !_loginObscure),
                      ),
                    ),
                    validator: (v) => v!.isEmpty ? 'required' : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loginLoading ? null : _handleLogin,
                    style: FilledButton.styleFrom(
                        backgroundColor: _navy,
                        padding: const EdgeInsets.symmetric(vertical: 14)),
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
          ] else ...[
            const Text('enter the code from your notification',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            const Text(
                'we sent a one-time security code to your device',
                style: TextStyle(color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _loginCodeCtl,
              maxLength: 5,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 6),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _handleLoginCode,
              style: FilledButton.styleFrom(
                  backgroundColor: _navy,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('VERIFY',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ],
      ),
    );
  }

  // ── session expired ──

  Widget _buildSessionExpired() {
    return Container(
      color: const Color(0xFFF8F8FC),
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline,
                    size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text('session expired',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20)),
                const SizedBox(height: 8),
                const Text('please start over',
                    style: TextStyle(color: Colors.black54)),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _resetAll,
                  style: FilledButton.styleFrom(backgroundColor: _navy),
                  child: const Text('START OVER'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── shared ──

  Widget _navButtons({required bool showBack, bool isSubmit = false}) {
    return Row(
      children: [
        if (showBack)
          OutlinedButton(
            onPressed: _prevStep,
            child: const Text('BACK'),
          ),
        if (showBack) const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            onPressed: _nextStep,
            style: FilledButton.styleFrom(
                backgroundColor: _navy,
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(isSubmit ? 'SUBMIT' : 'NEXT',
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  InputDecoration _deco(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _navy, width: 2)),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      labelStyle: TextStyle(fontSize: 13, color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.white,
    );
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m - 1];
  }

  static const _usStates = [
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
  ];
}
