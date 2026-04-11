import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../../services/notification_service.dart';
import 'dart:math';

class Level2FALogin extends LevelWidget {
  const Level2FALogin({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<Level2FALogin> createState() => _Level2FALoginState();
}

class _Level2FALoginState extends State<Level2FALogin> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  final String _correctEmail = 'agi@apkarena.com';
  final String _correctPassword = 'Sup3rS3cur3P@ssw0rd!2025';
  late String _correct2FACode;

  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _showCodeInput = false;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    _correct2FACode = _generate2FACode();
    _requestNotificationPermissions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _requestNotificationPermissions() async {
    final granted = await NotificationService().requestPermissions();
    setState(() {
      _permissionsGranted = granted;
    });
  }

  String _generate2FACode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    // Simulate checking credentials
    await Future.delayed(const Duration(milliseconds: 1000));

    if (_emailController.text == _correctEmail &&
        _passwordController.text == _correctPassword) {
      // Send notification with 2FA code
      if (_permissionsGranted) {
        await NotificationService().show2FACode(_correct2FACode);
      }

      setState(() {
        _isLoading = false;
        _showCodeInput = true;
      });
    } else {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('invalid email or password'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleVerifyCode() async {
    if (_codeController.text == _correct2FACode) {
      // Success!
      setState(() {
        _isLoading = true;
      });

      await Future.delayed(const Duration(milliseconds: 500));
      widget.onComplete(LevelOutcome(score: 1));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('invalid verification code'),
          backgroundColor: Colors.red,
        ),
      );

      // Reset for new attempt
      setState(() {
        _codeController.clear();
        _showCodeInput = false;
        _emailController.clear();
        _passwordController.clear();
        _correct2FACode = _generate2FACode();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Credentials card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade900.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade700.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.sticky_note_2,
                              color: Colors.yellow.shade600,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'credentials',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildCredentialRow('email:', _correctEmail),
                        const SizedBox(height: 8),
                        _buildCredentialRow('password:', _correctPassword),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (!_showCodeInput) ...[
                    // Login form
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Email field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'email',
                              prefixIcon: const Icon(Icons.email_outlined, color: NunuColors.primaryMain),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: NunuColors.primaryMain, width: 2),
                              ),
                              labelStyle: const TextStyle(color: NunuColors.textSecondary),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'email is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              labelText: 'password',
                              prefixIcon: const Icon(Icons.lock_outline, color: NunuColors.primaryMain),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                  color: NunuColors.textSecondary,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade700),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: NunuColors.primaryMain, width: 2),
                              ),
                              labelStyle: const TextStyle(color: NunuColors.textSecondary),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'password is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),

                          // Login button
                          FilledButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: NunuColors.primaryMain,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                                : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    // 2FA code input
                    Column(
                      children: [
                        const Text(
                          'check your notifications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'enter the 6-digit code we sent',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(height: 24),

                        TextFormField(
                          controller: _codeController,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 6,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            letterSpacing: 8,
                            fontWeight: FontWeight.bold,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(
                            counterText: '',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade700),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: NunuColors.primaryMain, width: 2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        FilledButton(
                          onPressed: _codeController.text.length == 6 ? _handleVerifyCode : null,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: NunuColors.primaryMain,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'VERIFY',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade400,
            ),
          ),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}