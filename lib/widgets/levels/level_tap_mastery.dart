import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Stages: single, double, triple, 5-tap, 10-tap burst.
class LevelTapMastery extends LevelWidget {
  const LevelTapMastery({super.key, required super.onComplete});

  @override
  State<LevelTapMastery> createState() => _LevelTapMasteryState();
}

class _LevelTapMasteryState extends State<LevelTapMastery> {
  static const int maxTotalTaps = 80;
  static const int maxWrongSequences = 8;

  int _stageIndex = 0;
  int _tapCountInWindow = 0;
  int _totalTaps = 0;
  int _wrongSequences = 0;
  Timer? _resetTimer;

  final List<int> _requiredTaps = [1, 2, 3, 5, 10];
  static const List<Duration> _windows = [
    Duration(milliseconds: 800),
    Duration(milliseconds: 1000),
    Duration(milliseconds: 1200),
    Duration(milliseconds: 2000),
    Duration(milliseconds: 3500),
  ];

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  int get _need => _requiredTaps[_stageIndex];

  void _fail() {
    _resetTimer?.cancel();
    widget.onComplete(
      false,
      metrics: {
        'total_taps': _totalTaps,
        'stages_cleared': _stageIndex,
      },
    );
  }

  void _scheduleReset() {
    _resetTimer?.cancel();
    _resetTimer = Timer(_windows[_stageIndex], () {
      if (!mounted) return;
      if (_tapCountInWindow > 0 && _tapCountInWindow != _need) {
        setState(() {
          _wrongSequences++;
          _tapCountInWindow = 0;
        });
        if (_wrongSequences >= maxWrongSequences) {
          _fail();
        }
      }
    });
  }

  void _onTargetTap() {
    _totalTaps++;
    if (_totalTaps > maxTotalTaps) {
      _fail();
      return;
    }

    _resetTimer?.cancel();
    setState(() {
      _tapCountInWindow++;
    });

    if (_tapCountInWindow == _need) {
      _resetTimer?.cancel();
      if (_stageIndex >= _requiredTaps.length - 1) {
        widget.onComplete(
          true,
          metrics: {
            'total_taps': _totalTaps,
            'stages_cleared': _requiredTaps.length,
          },
        );
        return;
      }
      setState(() {
        _stageIndex++;
        _tapCountInWindow = 0;
      });
    } else {
      _scheduleReset();
    }
  }

  String get _hint {
    switch (_stageIndex) {
      case 0:
        return 'tap once';
      case 1:
        return 'double-tap (2 in quick succession)';
      case 2:
        return 'triple-tap (3 quick)';
      case 3:
        return '5 quick taps';
      case 4:
        return '10 quick taps';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _hint,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NunuColors.textPrimary,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 32),
            Material(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: _onTargetTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 160,
                  height: 160,
                  alignment: Alignment.center,
                  child: Text(
                    'tap',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: NunuColors.primaryMain,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
