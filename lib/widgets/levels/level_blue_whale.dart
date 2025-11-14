import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelBlueWhale extends LevelWidget {
  const LevelBlueWhale({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelBlueWhale> createState() => _LevelBlueWhaleState();
}

class _LevelBlueWhaleState extends State<LevelBlueWhale> {
  void _handleTap(String animal) {
    if (animal == 'mouse') {
      widget.onComplete(true);
    } else {
      widget.onComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Stack(
        children: [
          // Giant mouse (visually large but actually small animal)
          Positioned(
            left: 40,
            top: 140,
            child: GestureDetector(
              onTap: () => _handleTap('mouse'),
              child: Container(
                width: 280,
                height: 280,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🐁',
                      style: TextStyle(fontSize: 180),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tiny blue whale (visually tiny but actually largest animal)
          Positioned(
            right: 45,
            bottom: 120,
            child: GestureDetector(
              onTap: () => _handleTap('whale'),
              child: Container(
                width: 100,
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🐋',
                      style: TextStyle(fontSize: 50),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}