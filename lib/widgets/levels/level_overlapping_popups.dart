import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelOverlappingPopups extends LevelWidget {
  const LevelOverlappingPopups({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelOverlappingPopups> createState() => _LevelOverlappingPopupsState();
}

class _LevelOverlappingPopupsState extends State<LevelOverlappingPopups> {
  bool _showOuterPopup = true;
  bool _showMiddlePopup = true;
  bool _showInnerPopup = true;

  void _handleCloseAttempt(String popup) {
    // Can only close popups from innermost to outermost
    if (popup == 'inner' && _showInnerPopup) {
      setState(() {
        _showInnerPopup = false;
      });
    } else if (popup == 'middle' && !_showInnerPopup && _showMiddlePopup) {
      setState(() {
        _showMiddlePopup = false;
      });
    } else if (popup == 'outer' && !_showInnerPopup && !_showMiddlePopup && _showOuterPopup) {
      setState(() {
        _showOuterPopup = false;
      });
      // All popups closed!
      Future.delayed(const Duration(milliseconds: 300), () {
        widget.onComplete(LevelOutcome(score: 1));
      });
    }
    // If wrong order, silently ignore the click
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault.withValues(alpha: 0.9),
      child: Stack(
        children: [
          // Background content
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.layers,
                    size: 80,
                    color: NunuColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Close all popups',
                    style: TextStyle(
                      fontSize: 20,
                      color: NunuColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Nested popups
          if (_showOuterPopup)
            Center(
              child: _NestedPopup(
                width: 320,
                height: 380,
                title: 'Special Offer!',
                backgroundColor: Colors.grey.shade800,
                headerColor: Colors.grey.shade700,
                borderColor: Colors.grey.shade600,
                closeButtonSize: 28,
                onClose: () => _handleCloseAttempt('outer'),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Get 50% OFF!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Limited time offer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade300,
                      ),
                    ),
                  ],
                ),
                nestedPopup: _showMiddlePopup
                    ? _NestedPopup(
                  width: 260,
                  height: 300,
                  title: 'Subscribe Now!',
                  backgroundColor: Colors.grey.shade700,
                  headerColor: Colors.grey.shade600,
                  borderColor: Colors.grey.shade500,
                  closeButtonSize: 26,
                  onClose: () => _handleCloseAttempt('middle'),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Join our newsletter',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Get exclusive deals',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                  nestedPopup: _showInnerPopup
                      ? _NestedPopup(
                    width: 200,
                    height: 220,
                    title: 'One More Thing!',
                    backgroundColor: Colors.grey.shade600,
                    headerColor: Colors.grey.shade500,
                    borderColor: Colors.grey.shade400,
                    closeButtonSize: 24,
                    onClose: () => _handleCloseAttempt('inner'),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.celebration,
                          size: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Flash Sale!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Act now!',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade300,
                          ),
                        ),
                      ],
                    ),
                  )
                      : null,
                )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}

class _NestedPopup extends StatelessWidget {
  final double width;
  final double height;
  final String title;
  final Color backgroundColor;
  final Color headerColor;
  final Color borderColor;
  final double closeButtonSize;
  final VoidCallback onClose;
  final Widget child;
  final Widget? nestedPopup;

  const _NestedPopup({
    required this.width,
    required this.height,
    required this.title,
    required this.backgroundColor,
    required this.headerColor,
    required this.borderColor,
    required this.closeButtonSize,
    required this.onClose,
    required this.child,
    this.nestedPopup,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5 + (nestedPopup != null ? 0.1 : 0)),
            blurRadius: 20 + (nestedPopup != null ? 5 : 0),
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: headerColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: closeButtonSize,
                    height: closeButtonSize,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade900,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.close,
                      color: Colors.white,
                      size: closeButtonSize * 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Body
          Expanded(
            child: Stack(
              children: [
                // Content
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: child,
                  ),
                ),
                // Nested popup (if any)
                if (nestedPopup != null)
                  Center(
                    child: nestedPopup!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}