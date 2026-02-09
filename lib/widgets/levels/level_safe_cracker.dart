import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSafeCracker extends LevelWidget {
  const LevelSafeCracker({super.key, required super.onComplete});

  @override
  State<LevelSafeCracker> createState() => _LevelSafeCrackerState();
}

class _LevelSafeCrackerState extends State<LevelSafeCracker> {
  late List<int> _combination;
  int _currentStep = 0;
  int _dialNumber = 0;
  bool _done = false;
  String? _feedbackMessage;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    _combination = List.generate(3, (_) => rng.nextInt(40));
    while (_combination[1] == _combination[0]) {
      _combination[1] = rng.nextInt(40);
    }
    while (_combination[2] == _combination[1] ||
        _combination[2] == _combination[0]) {
      _combination[2] = rng.nextInt(40);
    }
  }

  void _onDialTap(TapDownDetails details, double dialSize) {
    if (_done) return;
    final center = Offset(dialSize / 2, dialSize / 2);
    final tap = details.localPosition;
    final dx = tap.dx - center.dx;
    final dy = tap.dy - center.dy;

    // Check if tap is in the dial ring (not in center display area)
    final distance = sqrt(dx * dx + dy * dy);
    final radius = dialSize / 2 - 10;
    if (distance < radius * 0.38 || distance > radius + 10) return;

    // Calculate angle: 0° at top, clockwise
    var angle = atan2(dy, dx) * 180 / pi + 90;
    if (angle < 0) angle += 360;

    // Convert to number (0-39, each 9 degrees apart)
    final number = ((angle / 9).round()) % 40;

    setState(() {
      _dialNumber = number;
      _feedbackMessage = null;
    });
    HapticFeedback.selectionClick();
  }

  void _confirm() {
    if (_done) return;
    setState(() {
      if (_dialNumber == _combination[_currentStep]) {
        _currentStep++;
        HapticFeedback.lightImpact();
        _feedbackMessage = null;

        if (_currentStep == 3) {
          _done = true;
          _feedbackMessage = 'unlocked!';
          HapticFeedback.mediumImpact();
          Future.delayed(const Duration(milliseconds: 600), () {
            widget.onComplete(true);
          });
        }
      } else {
        HapticFeedback.heavyImpact();
        _feedbackMessage = 'wrong! try again.';
        _currentStep = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF0A0A1C)],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildCombinationHint(),
            const SizedBox(height: 8),
            _buildProgress(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'tap a number on the dial, then confirm',
                style: TextStyle(
                  color: NunuColors.textSecondary.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _buildDial()),
            if (_feedbackMessage != null) ...[
              Text(
                _feedbackMessage!,
                style: TextStyle(
                  fontSize: 16,
                  color: _feedbackMessage == 'unlocked!'
                      ? NunuColors.successMain
                      : NunuColors.errorMain,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
            ],
            _buildConfirmButton(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildCombinationHint() {
    return Column(
      children: [
        const Text(
          'combination',
          style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            final isActive = _currentStep == i;
            final isDone = i < _currentStep;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDone
                    ? NunuColors.successMain.withOpacity(0.2)
                    : isActive
                        ? NunuColors.primaryMain.withOpacity(0.2)
                        : NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDone
                      ? NunuColors.successMain
                      : isActive
                          ? NunuColors.primaryMain
                          : NunuColors.primaryDark.withOpacity(0.3),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Text(
                '${_combination[i]}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isDone
                      ? NunuColors.successMain
                      : isActive
                          ? Colors.white
                          : NunuColors.textSecondary,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildProgress() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          return Expanded(
            child: Container(
              height: 4,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: i < _currentStep
                    ? NunuColors.successMain
                    : NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildDial() {
    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dialSize = min(
            constraints.maxWidth - 40,
            constraints.maxHeight - 20,
          );
          return GestureDetector(
            onTapDown: (details) => _onDialTap(details, dialSize),
            child: SizedBox(
              width: dialSize,
              height: dialSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(dialSize, dialSize),
                    painter: _DialPainter(
                      currentNumber: _dialNumber,
                    ),
                  ),
                  // Big center number
                  Text(
                    '$_dialNumber',
                    style: const TextStyle(
                      fontSize: 56,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton() {
    return GestureDetector(
      onTap: _confirm,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        decoration: BoxDecoration(
          color: NunuColors.primaryMain,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Text(
          'confirm',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _DialPainter extends CustomPainter {
  final int currentNumber;

  _DialPainter({required this.currentNumber});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Outer ring
    final ringPaint = Paint()
      ..color = NunuColors.backgroundPaper
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, ringPaint);

    final borderPaint = Paint()
      ..color = NunuColors.primaryDark.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawCircle(center, radius, borderPaint);

    // Number ticks
    for (int i = 0; i < 40; i++) {
      final tickAngle = (i * 9 - 90) * pi / 180;
      final isMajor = i % 5 == 0;
      final innerR = isMajor ? radius - 30 : radius - 18;
      final outerR = radius - 8;

      final p1 = Offset(
        center.dx + innerR * cos(tickAngle),
        center.dy + innerR * sin(tickAngle),
      );
      final p2 = Offset(
        center.dx + outerR * cos(tickAngle),
        center.dy + outerR * sin(tickAngle),
      );

      final tickPaint = Paint()
        ..color = i == currentNumber
            ? NunuColors.primaryMain
            : isMajor
                ? Colors.white.withOpacity(0.8)
                : Colors.white.withOpacity(0.3)
        ..strokeWidth = i == currentNumber ? 3 : (isMajor ? 2 : 1)
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(p1, p2, tickPaint);

      // Draw numbers for major ticks
      if (isMajor) {
        final textR = radius - 42;
        final textOffset = Offset(
          center.dx + textR * cos(tickAngle) - 8,
          center.dy + textR * sin(tickAngle) - 7,
        );
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$i',
            style: TextStyle(
              color: i == currentNumber
                  ? NunuColors.primaryMain
                  : Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(canvas, textOffset);
      }
    }

    // Pointer (from center toward current number)
    final pointerAngle = (currentNumber * 9 - 90) * pi / 180;
    final pointerEnd = Offset(
      center.dx + (radius - 52) * cos(pointerAngle),
      center.dy + (radius - 52) * sin(pointerAngle),
    );
    final pointerPaint = Paint()
      ..color = NunuColors.errorMain
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, pointerEnd, pointerPaint);

    // Center circle (background for number display)
    final centerBg = Paint()
      ..color = const Color(0xFF16122F)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, centerBg);
    final centerBorder = Paint()
      ..color = NunuColors.primaryDark.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius * 0.35, centerBorder);

    // Top marker
    final markerPaint = Paint()
      ..color = NunuColors.errorMain
      ..style = PaintingStyle.fill;
    final markerPath = Path()
      ..moveTo(center.dx, center.dy - radius + 2)
      ..lineTo(center.dx - 6, center.dy - radius - 10)
      ..lineTo(center.dx + 6, center.dy - radius - 10)
      ..close();
    canvas.drawPath(markerPath, markerPaint);
  }

  @override
  bool shouldRepaint(covariant _DialPainter old) =>
      old.currentNumber != currentNumber;
}
