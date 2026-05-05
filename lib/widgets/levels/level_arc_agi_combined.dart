import 'package:apk_arena/models/level_outcome.dart';
import 'package:apk_arena/widgets/levels/level_arc_agi.dart';
import 'package:apk_arena/widgets/levels/level_arc_agi_2.dart';
import 'package:apk_arena/widgets/levels/level_arc_agi_3_pattern.dart';
import 'package:flutter/material.dart';

import '../level_widget.dart';

class LevelArcAgiCombined extends LevelWidget {
  const LevelArcAgiCombined({super.key, required super.onComplete});

  @override
  State<LevelArcAgiCombined> createState() => _LevelArcAgiCombinedState();
}

class _LevelArcAgiCombinedState extends State<LevelArcAgiCombined> {
  static const int _stageCount = 3;

  int _stage = 0;

  void _handleStageComplete(LevelOutcome outcome) {
    if (outcome.score < 1) {
      widget.onComplete(
        LevelOutcome(
          score: _stage / _stageCount,
          metrics: {'completed_stages': _stage, 'failed_stage': _stage + 1},
        ),
      );
      return;
    }

    if (_stage >= _stageCount - 1) {
      widget.onComplete(
        LevelOutcome(
          score: 1,
          metrics: const {'completed_stages': _stageCount},
        ),
      );
      return;
    }

    setState(() => _stage++);
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: ValueKey(_stage),
      child: switch (_stage) {
        0 => LevelArcAgi(onComplete: _handleStageComplete),
        1 => LevelArcAgi2(onComplete: _handleStageComplete),
        _ => LevelArcAgi3Pattern(onComplete: _handleStageComplete),
      },
    );
  }
}
