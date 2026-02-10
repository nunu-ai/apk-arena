import 'dart:async';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Loading screen for game apps
class GameLoadingScreen extends StatefulWidget {
  final String appName;
  final IconData appIcon;
  final Color appColor;
  final VoidCallback onLoadingComplete;
  final Duration loadingDuration;

  const GameLoadingScreen({
    Key? key,
    required this.appName,
    required this.appIcon,
    required this.appColor,
    required this.onLoadingComplete,
    this.loadingDuration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<String> _loadingMessages = [
    'loading assets...',
    'initializing game...',
    'preparing experience...',
    'almost ready...',
  ];
  int _messageIndex = 0;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.loadingDuration,
    );

    _controller.forward();
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onLoadingComplete();
      }
    });

    _messageTimer = Timer.periodic(const Duration(milliseconds: 800), (timer) {
      if (mounted) {
        setState(() {
          _messageIndex = (_messageIndex + 1) % _loadingMessages.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: widget.appColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: widget.appColor.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                widget.appIcon,
                color: Colors.white,
                size: 50,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: 200,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _controller.value,
                          backgroundColor: NunuColors.backgroundPaper,
                          valueColor: AlwaysStoppedAnimation(widget.appColor),
                          minHeight: 6,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _loadingMessages[_messageIndex],
                        style: const TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Terms of Service and Privacy Policy screen
class GameTosScreen extends StatefulWidget {
  final String appName;
  final String tosContent;
  final String privacyContent;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const GameTosScreen({
    Key? key,
    required this.appName,
    required this.tosContent,
    required this.privacyContent,
    required this.onAccept,
    required this.onDecline,
  }) : super(key: key);

  @override
  State<GameTosScreen> createState() => _GameTosScreenState();
}

class _GameTosScreenState extends State<GameTosScreen> {
  bool _tosAccepted = false;
  bool _privacyAccepted = false;
  int _currentTab = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    widget.appName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'please review and accept our terms',
                    style: TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Tab selector
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 0
                              ? NunuColors.primaryMain
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'terms of service',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentTab == 0
                                ? Colors.white
                                : NunuColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _currentTab = 1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _currentTab == 1
                              ? NunuColors.primaryMain
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'privacy policy',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _currentTab == 1
                                ? Colors.white
                                : NunuColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NunuColors.backgroundPaper,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _currentTab == 0 ? widget.tosContent : widget.privacyContent,
                    style: const TextStyle(
                      color: NunuColors.textPrimary,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Checkboxes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _tosAccepted = !_tosAccepted),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _tosAccepted
                                ? NunuColors.primaryMain
                                : Colors.transparent,
                            border: Border.all(
                              color: _tosAccepted
                                  ? NunuColors.primaryMain
                                  : NunuColors.textSecondary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _tosAccepted
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'i accept the terms of service',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _privacyAccepted = !_privacyAccepted),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: _privacyAccepted
                                ? NunuColors.primaryMain
                                : Colors.transparent,
                            border: Border.all(
                              color: _privacyAccepted
                                  ? NunuColors.primaryMain
                                  : NunuColors.textSecondary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _privacyAccepted
                              ? const Icon(Icons.check, color: Colors.white, size: 16)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'i accept the privacy policy',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: widget.onDecline,
                      child: const Text(
                        'decline',
                        style: TextStyle(
                          color: NunuColors.textSecondary,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed:
                          _tosAccepted && _privacyAccepted ? widget.onAccept : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NunuColors.primaryMain,
                        disabledBackgroundColor: NunuColors.backgroundPaper,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'accept & continue',
                        style: TextStyle(
                          color: _tosAccepted && _privacyAccepted
                              ? Colors.white
                              : NunuColors.textSecondary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Age gate popup dialog
class AgeGateDialog extends StatelessWidget {
  final String appName;
  final int requiredAge;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const AgeGateDialog({
    Key? key,
    required this.appName,
    required this.requiredAge,
    required this.onConfirm,
    required this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: NunuColors.backgroundPaper,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber_rounded,
              color: NunuColors.warningMain,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'age verification required',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'you must be at least $requiredAge years old to play $appName.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'are you $requiredAge or older?',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: NunuColors.textSecondary),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'no',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: NunuColors.primaryMain,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'yes',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

