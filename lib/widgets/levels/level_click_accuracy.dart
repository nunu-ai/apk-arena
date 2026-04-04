import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Four stages × 3 hits; targets move each hit; smooth shrink (no easy opener).
class LevelClickAccuracy extends LevelWidget {
  const LevelClickAccuracy({super.key, required super.onComplete});

  @override
  State<LevelClickAccuracy> createState() => _LevelClickAccuracyState();
}

class _LevelClickAccuracyState extends State<LevelClickAccuracy> {
  static const int maxTotalTaps = 40;
  static const int stageCount = 4;
  static const int hitsPerStage = 3;

  final Random _rng = Random();
  int _stageIndex = 0;
  int _hitsInStage = 0;
  int _totalTaps = 0;
  int _hitsTotal = 0;
  Alignment _targetAlign = Alignment.center;

  /// Horizontal padding — smooth ramp (was old stages 1→4, smaller final).
  double get _buttonHorizontalPadding {
    const p = [30.0, 22.0, 14.0, 5.0];
    return p[_stageIndex.clamp(0, stageCount - 1)];
  }

  double get _verticalPadding {
    const p = [13.0, 11.0, 8.0, 5.0];
    return p[_stageIndex.clamp(0, stageCount - 1)];
  }

  double get _fontSize {
    const f = [16.0, 14.0, 12.0, 10.0];
    return f[_stageIndex.clamp(0, stageCount - 1)];
  }

  @override
  void initState() {
    super.initState();
    _targetAlign = _randomAlign();
  }

  Alignment _randomAlign() {
    final x = (_rng.nextDouble() * 2 - 1) * 0.85;
    final y = (_rng.nextDouble() * 2 - 1) * 0.75;
    return Alignment(x, y);
  }

  void _fail() {
    widget.onComplete(
      false,
      metrics: {
        'total_taps': _totalTaps,
        'accuracy_pct': _accuracyPct,
        'stages_cleared': _stageIndex,
      },
    );
  }

  int get _accuracyPct {
    if (_totalTaps == 0) return 0;
    return ((_hitsTotal / _totalTaps) * 100).round();
  }

  void _onTargetHit() {
    _totalTaps++;
    _hitsTotal++;
    _hitsInStage++;
    if (_hitsInStage >= hitsPerStage) {
      if (_stageIndex >= stageCount - 1) {
        widget.onComplete(
          true,
          metrics: {
            'total_taps': _totalTaps,
            'accuracy_pct': _accuracyPct,
            'stages_cleared': stageCount,
          },
        );
        return;
      }
      setState(() {
        _stageIndex++;
        _hitsInStage = 0;
        _targetAlign = _randomAlign();
      });
    } else {
      setState(() {
        _targetAlign = _randomAlign();
      });
    }
    if (_totalTaps > maxTotalTaps) {
      _fail();
    }
  }

  void _onMiss() {
    _totalTaps++;
    if (_totalTaps > maxTotalTaps) {
      _fail();
      return;
    }
    setState(() {
      _targetAlign = _randomAlign();
      if (_stageIndex >= 2) {
        _hitsInStage = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: _onMiss,
          ),
        ),
        Align(
          alignment: _targetAlign,
          child: FilledButton(
            onPressed: _onTargetHit,
            style: FilledButton.styleFrom(
              padding: EdgeInsets.symmetric(
                horizontal: _buttonHorizontalPadding,
                vertical: _verticalPadding,
              ),
              backgroundColor:
                  NunuColors.primaryMain.withValues(alpha: 0.45),
              foregroundColor: NunuColors.primaryLight,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              'click',
              style: TextStyle(
                fontSize: _fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
