import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Press target color N times; buttons shuffle after each press; then submit.
class LevelActionCounter extends LevelWidget {
  const LevelActionCounter({super.key, required super.onComplete});

  @override
  State<LevelActionCounter> createState() => _LevelActionCounterState();
}

class _ButtonSpec {
  _ButtonSpec({required this.color, required this.label});
  final Color color;
  final String label;
}

class _LevelActionCounterState extends State<LevelActionCounter> {
  final Random _rng = Random();
  late int _targetCount;
  late int _targetIndex; // 0-3
  int _pressedTarget = 0;
  late List<int> _order; // permutation of 0..3 for layout

  final List<_ButtonSpec> _specs = [
    _ButtonSpec(color: Colors.red.shade600, label: 'red'),
    _ButtonSpec(color: Colors.blue.shade600, label: 'blue'),
    _ButtonSpec(color: Colors.green.shade600, label: 'green'),
    _ButtonSpec(color: Colors.amber.shade700, label: 'yellow'),
  ];

  @override
  void initState() {
    super.initState();
    _targetCount = 4 + _rng.nextInt(6); // 4–9
    _targetIndex = _rng.nextInt(4);
    _order = List.generate(4, (i) => i)..shuffle(_rng);
  }

  void _shuffleOrder() {
    setState(() {
      _order.shuffle(_rng);
    });
  }

  void _onColorTap(int logicalIndex) {
    if (logicalIndex == _targetIndex) {
      setState(() {
        _pressedTarget++;
      });
    }
    _shuffleOrder();
  }

  void _onSubmit() {
    if (_pressedTarget == _targetCount) {
      widget.onComplete(
        true,
        metrics: {
          'target_presses': _pressedTarget,
          'expected': _targetCount,
        },
      );
    } else {
      widget.onComplete(
        false,
        metrics: {
          'target_presses': _pressedTarget,
          'expected': _targetCount,
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final targetLabel = _specs[_targetIndex].label;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: NunuColors.primaryMain.withValues(alpha: 0.45),
                ),
              ),
              child: Text(
                'press $targetLabel exactly $_targetCount times.\n'
                'positions shuffle after every tap. keep your own count — submit when ready.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: NunuColors.primaryLight,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _order.map((logicalIdx) {
                final s = _specs[logicalIdx];
                return _ColorChip(
                  spec: s,
                  onTap: () => _onColorTap(logicalIdx),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _onSubmit,
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: NunuColors.successMain,
                foregroundColor: Colors.black,
              ),
              child: const Text(
                'submit',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.spec, required this.onTap});

  final _ButtonSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: spec.color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 100,
          height: 56,
          child: Center(
            child: Text(
              spec.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
