import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

enum ModificationType {
  none,
  gradient,
  buttonShape,
  bellBorder,
}

class LevelSpotDifference extends LevelWidget {
  const LevelSpotDifference({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelSpotDifference> createState() => _LevelSpotDifferenceState();
}

class _LevelSpotDifferenceState extends State<LevelSpotDifference> {
  int _currentStep = 1;
  bool _isCompleted = false;

  ModificationType get _currentModification {
    switch (_currentStep) {
      case 1: return ModificationType.none;
      case 2: return ModificationType.gradient;
      case 3: return ModificationType.buttonShape;
      case 4: return ModificationType.none;
      case 5: return ModificationType.bellBorder;
      default: return ModificationType.none;
    }
  }

  bool get _isDifferent => _currentModification != ModificationType.none;

  void _checkAnswer(bool saidDifferent) {
    if (saidDifferent == _isDifferent) {
      if (_currentStep < 5) {
        setState(() {
          _currentStep++;
        });
      } else {
        setState(() {
          _isCompleted = true;
        });
        widget.onComplete(LevelOutcome(score: 1));
      }
    } else {
      widget.onComplete(LevelOutcome(score: 0));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Reference Design",
                      style: TextStyle(color: NunuColors.secondaryLight, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _FakeAppScreen(
                      modification: ModificationType.none,
                      orangeBell: _currentStep >= 4,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Production Build",
                      style: TextStyle(color: NunuColors.primaryMain, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _FakeAppScreen(
                      modification: _currentModification,
                      orangeBell: _currentStep >= 4,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (!_isCompleted)
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      "$_currentStep / 5",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NunuColors.successMain,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _checkAnswer(false),
                      child: const Text("SAME", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: NunuColors.errorMain,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _checkAnswer(true),
                      child: const Text("DIFFERENT", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FakeAppScreen extends StatelessWidget {
  final ModificationType modification;
  final bool orangeBell;

  const _FakeAppScreen({
    required this.modification,
    this.orangeBell = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark grey surface
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Fake AppBar
          Container(
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFF2D2D2D),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                const Icon(Icons.menu, color: Colors.white70, size: 20),
                const SizedBox(width: 12),
                const Text(
                  "Dashboard",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                ),
                const Spacer(),
                Icon(
                  Icons.notifications,
                  color: orangeBell ? Colors.orange : Colors.white70,
                  size: 20,
                  shadows: modification == ModificationType.bellBorder
                      ? [
                          const Shadow(color: Colors.red, offset: Offset(-1, -1)),
                          const Shadow(color: Colors.red, offset: Offset(1, -1)),
                          const Shadow(color: Colors.red, offset: Offset(1, 1)),
                          const Shadow(color: Colors.red, offset: Offset(-1, 1)),
                        ]
                      : null,
                ),
              ],
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Colorful detailed thing in the middle
                  Container(
                    height: 80,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: modification == ModificationType.gradient
                            ? [Colors.orange, Colors.purple, Colors.blue] // Reversed for gradient mod
                            : [Colors.blue, Colors.purple, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: -10,
                          top: -10,
                          child: Icon(Icons.circle, size: 50, color: Colors.white.withOpacity(0.2)),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 10,
                          child: Icon(Icons.star, size: 30, color: Colors.yellow.withOpacity(0.8)),
                        ),
                        const Center(
                          child: Icon(Icons.rocket_launch, size: 40, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // UI Elements (Text placeholders)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: Colors.white10,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        height: 12,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Buttons Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildButton(
                        label: "Cancel",
                        color: Colors.grey[700]!,
                        isTarget: false,
                      ),
                      _buildButton(
                        label: "Save",
                        color: Colors.blue[700]!,
                        isTarget: false,
                      ),
                      _buildButton(
                        label: "Export",
                        color: Colors.green[700]!,
                        isTarget: true, // This is the one that might change
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required String label,
    required Color color,
    required bool isTarget,
  }) {
    // If this is the target button AND we are in the modified screen, change the shape
    final bool showModifiedShape = isTarget && modification == ModificationType.buttonShape;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        color: color,
        shape: showModifiedShape
            ? BeveledRectangleBorder(borderRadius: BorderRadius.circular(10)) // Modified shape
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), // Normal shape
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}
