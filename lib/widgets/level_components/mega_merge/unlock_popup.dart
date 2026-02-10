import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../theme/app_theme.dart';

/// Unlock celebration popup with ok/shop buttons
class UnlockPopup extends StatefulWidget {
  final String itemName;
  final IconData itemIcon;
  final Color itemColor;
  final int tier;
  final VoidCallback onOk;
  final VoidCallback onShop;

  const UnlockPopup({
    Key? key,
    required this.itemName,
    required this.itemIcon,
    required this.itemColor,
    required this.tier,
    required this.onOk,
    required this.onShop,
  }) : super(key: key);

  @override
  State<UnlockPopup> createState() => _UnlockPopupState();
}

class _UnlockPopupState extends State<UnlockPopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _rotateAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Transform.rotate(
              angle: _rotateAnimation.value,
              child: child,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.itemColor,
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.itemColor.withOpacity(0.4),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confetti-like decorations
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber.shade300, size: 12),
                  const SizedBox(width: 8),
                  Icon(Icons.star, color: Colors.amber, size: 16),
                ],
              ),
              const SizedBox(height: 16),

              // Title
              const Text(
                'new unlock!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // Item icon with glow
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: NunuColors.backgroundDefault,
                  border: Border.all(color: widget.itemColor, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: widget.itemColor.withOpacity(0.5),
                      blurRadius: 16,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  widget.itemIcon,
                  color: widget.itemColor,
                  size: 50,
                ),
              ),
              const SizedBox(height: 16),

              // Item name and tier
              Text(
                widget.itemName,
                style: TextStyle(
                  color: widget.itemColor,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.itemColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'tier ${widget.tier}',
                  style: TextStyle(
                    color: widget.itemColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'cell unlocked and ready to use!',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  // OK Button (green)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        widget.onOk();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NunuColors.successMain,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'ok',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Shop Button (yellow)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                        widget.onShop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NunuColors.warningMain,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.store, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'shop',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show the unlock popup as a dialog
Future<void> showUnlockPopup({
  required BuildContext context,
  required String itemName,
  required IconData itemIcon,
  required Color itemColor,
  required int tier,
  required VoidCallback onOk,
  required VoidCallback onShop,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => UnlockPopup(
      itemName: itemName,
      itemIcon: itemIcon,
      itemColor: itemColor,
      tier: tier,
      onOk: onOk,
      onShop: onShop,
    ),
  );
}

