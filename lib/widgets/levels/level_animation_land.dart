import 'dart:async';
import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

/// Animation comprehension benchmark — 13 stages across 7 categories.
class LevelAnimationLand extends LevelWidget {
  const LevelAnimationLand({super.key, required super.onComplete});

  @override
  State<LevelAnimationLand> createState() => _LevelAnimationLandState();
}

enum _RotationDir { clockwise, counterClockwise }

class _SceneFrame {
  const _SceneFrame(this.emoji, this.color, this.label);
  final String emoji;
  final Color color;
  final String label;
}

class _CRotationItem {
  _CRotationItem({required this.emoji, required this.direction});

  final String emoji;
  final _RotationDir direction;
  int replays = 0;
  bool played = false;
  _RotationDir? answer;
}

class _ColorOption {
  const _ColorOption(this.label, this.color);
  final String label;
  final Color color;
}

class _LevelAnimationLandState extends State<LevelAnimationLand>
    with TickerProviderStateMixin {
  static const _totalStages = 13;
  static const _categoryAButtonMax = 0.06;
  static const _categoryAProbeMax = 0.04;
  static const _categoryBMax = 0.15;
  static const _categoryCMax = 0.15;
  static const _categoryFMax = 0.10;
  static const _categoryDMax = 0.075;
  static const _categoryEMax = 0.05;
  static const _categoryGMax = 0.05;

  static const _colorOptions = [
    _ColorOption('green', Color(0xFF22C55E)),
    _ColorOption('red', Color(0xFFFF5630)),
    _ColorOption('blue', Color(0xFF1E88E5)),
    _ColorOption('yellow', Color(0xFFF9A825)),
  ];

  static const _runnerEmojis = ['🐇', '🐢', '🦊', '🐸', '🐌', '🦅'];

  final Random _rng = Random();

  int _stage = 0;
  double _score = 0;
  int _stagesPerfect = 0;
  int _rewatches = 0;
  int _wrongAnswers = 0;
  bool _transitioning = false;
  bool _lastCorrect = false;

  // --- Category A: which button animated ---
  late int _aButtonCount;
  late int _aTargetIdx;
  int _aReplays = 0;
  bool _aAnimating = false;
  bool _aPlayed = false;
  int? _aSelectedIdx;
  late AnimationController _aPulseCtrl;

  // --- Category A3: one button animates ---
  late int _a3TargetIdx;
  final Map<int, int> _a3PressCounts = {};
  int _a3Replays = 0;
  bool _a3Playing = false;
  bool _a3AnimSeen = false;
  late AnimationController _a3LoopCtrl;
  final TextEditingController _a3Controller = TextEditingController();

  // --- Category B: score race recap ---
  static const _playerName = 'nova';
  late String _bEnemyName;
  int _bPlayerScore = 0;
  int _bEnemyScore = 0;
  bool _bRaceRunning = false;
  bool _bRaceDone = false;
  bool _bShowingAnim = false;
  bool _bQuiz = false;
  late bool _bPlayerWon;
  late Color _bAnimColor;
  late String _bAnimSymbol;
  late List<_QuizQuestion> _bQuestions;
  final Map<int, dynamic> _bAnswers = {};
  late AnimationController _bRevealCtrl;

  // --- Category C: rotation direction (4 emojis, one stage) ---
  late List<_CRotationItem> _cItems;
  int _cActiveIdx = -1;
  late AnimationController _cRotateCtrl;

  // --- Category F: scene animation quiz ---
  late List<_SceneFrame> _fScenes;
  bool _fShowingAnim = false;
  bool _fQuiz = false;
  int _fSceneIdx = 0;
  int _fReplays = 0;
  bool _fPlayed = false;
  Timer? _fSceneTimer;
  late List<_QuizQuestion> _fQuestions;
  final Map<int, dynamic> _fAnswers = {};

  // --- Category D: fast counter ---
  late int _dTarget;
  int _dReplays = 0;
  bool _dAnimating = false;
  bool _dPlayed = false;
  bool _dShowing = false;
  int _dDisplayValue = 0;
  late Duration _dCountDuration;
  late Duration _dHoldDuration;
  final TextEditingController _dController = TextEditingController();
  Timer? _dTimer;

  // --- Category E: race finish order ---
  late int _eRunnerCount;
  late List<String> _eRunners;
  late List<Curve> _eCurves;
  late List<int> _eDurationsMs;
  late List<int> _eFinishOrder;
  int _eReplays = 0;
  bool _eAnimating = false;
  bool _ePlayed = false;
  bool _eFinished = false;
  bool _eShowingRace = false;
  int? _eWinnerPick;
  late List<AnimationController> _eRunnerCtrls;

  // --- Category G: bouncing ball count ---
  late int _gBounceCount;
  int _gReplays = 0;
  bool _gAnimating = false;
  bool _gPlayed = false;
  late AnimationController _gBounceCtrl;
  final TextEditingController _gController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
      () => LevelOutcome(
        score: _score.clamp(0.0, 1.0),
        metrics: {
          'stages_perfect': _stagesPerfect,
          'rewatches': _rewatches,
          'wrong_answers': _wrongAnswers,
        },
      ),
    );
    _aPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _a3LoopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _bRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _cRotateCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _gBounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    );
    _eRunnerCtrls = [];
    _prepareStage(0);
  }

  void _initStageA(int count) {
    _aButtonCount = count;
    _aTargetIdx = _rng.nextInt(count);
    _aReplays = 0;
    _aAnimating = false;
    _aPlayed = false;
    _aSelectedIdx = null;
    _aPulseCtrl.duration = _stage == 0
        ? const Duration(seconds: 5)
        : const Duration(seconds: 3);
    _aPulseCtrl.reset();
  }

  void _initStageA3() {
    _a3TargetIdx = _rng.nextInt(5);
    _a3PressCounts.clear();
    _a3Replays = 0;
    _a3Playing = false;
    _a3AnimSeen = false;
    _a3Controller.clear();
    _a3LoopCtrl.reset();
  }

  void _initStageB() {
    _bEnemyName = _randomEnemyName();
    _bPlayerScore = 0;
    _bEnemyScore = 0;
    _bRaceRunning = false;
    _bRaceDone = false;
    _bShowingAnim = false;
    _bQuiz = false;
    _bAnswers.clear();
    _bRevealCtrl.reset();
  }

  void _initStageC() {
    final emojis = List<String>.from(_runnerEmojis)..shuffle(_rng);
    _cItems = List.generate(4, (i) {
      return _CRotationItem(
        emoji: emojis[i],
        direction: _rng.nextBool()
            ? _RotationDir.clockwise
            : _RotationDir.counterClockwise,
      );
    });
    _cActiveIdx = -1;
    _cRotateCtrl.reset();
  }

  void _initStageF() {
    final pool = [
      const _SceneFrame('🌙', Color(0xFF1E3A8A), 'night'),
      const _SceneFrame('☀️', Color(0xFFF9A825), 'day'),
      const _SceneFrame('🌧️', Color(0xFF1E88E5), 'rain'),
      const _SceneFrame('❄️', Color(0xFFBAE6FD), 'snow'),
      const _SceneFrame('🔥', Color(0xFFFF5630), 'fire'),
      const _SceneFrame('🌿', Color(0xFF22C55E), 'forest'),
    ]..shuffle(_rng);

    final sub = _stage - 6;
    final sceneCount = sub == 0 ? 4 : 5;
    _fScenes = pool.sublist(0, sceneCount);
    _fShowingAnim = false;
    _fQuiz = false;
    _fSceneIdx = 0;
    _fReplays = 0;
    _fPlayed = false;
    _fAnswers.clear();
    _fSceneTimer?.cancel();
  }

  void _initStageD() {
    final sub = _stage - 8;
    if (sub == 0) {
      _dTarget = 10 + _rng.nextInt(90);
      _dCountDuration = const Duration(seconds: 8);
      _dHoldDuration = const Duration(seconds: 5);
    } else {
      _dTarget = 100 + _rng.nextInt(900);
      _dCountDuration = const Duration(seconds: 2);
      _dHoldDuration = const Duration(milliseconds: 1500);
    }
    _dReplays = 0;
    _dAnimating = false;
    _dPlayed = false;
    _dShowing = false;
    _dDisplayValue = 0;
    _dController.clear();
    _dTimer?.cancel();
  }

  void _initStageE() {
    for (final c in _eRunnerCtrls) {
      c.dispose();
    }
    _eRunnerCtrls = [];

    final sub = _stage - 10;
    _eRunnerCount = sub == 0 ? 3 : 4;

    final pool = List<String>.from(_runnerEmojis)..shuffle(_rng);
    _eRunners = pool.sublist(0, _eRunnerCount);

    const curvePool = [
      Curves.easeInCubic,
      Curves.easeOutQuart,
      Curves.easeInOutCubic,
      Curves.easeInOutBack,
    ];
    if (sub == 1) {
      final slowStartWinner = _rng.nextInt(_eRunnerCount);
      _eCurves = List.generate(
        _eRunnerCount,
        (i) => curvePool[(i + 1) % curvePool.length],
      );
      _eCurves[slowStartWinner] = Curves.easeInCubic;
      _eDurationsMs = List.generate(
        _eRunnerCount,
        (i) => 4600 + i * 550 + _rng.nextInt(420),
      );
      _eDurationsMs[slowStartWinner] = 3300 + _rng.nextInt(220);
    } else {
      _eCurves = List.generate(
        _eRunnerCount,
        (i) => curvePool[i % curvePool.length],
      )..shuffle(_rng);

      _eDurationsMs = List.generate(
        _eRunnerCount,
        (i) => 3200 + i * 680 + _rng.nextInt(420),
      )..shuffle(_rng);
    }
    _eFinishOrder = List.generate(_eRunnerCount, (i) => i)
      ..sort((a, b) => _eDurationsMs[a].compareTo(_eDurationsMs[b]));

    _eReplays = 0;
    _eAnimating = false;
    _ePlayed = false;
    _eFinished = false;
    _eShowingRace = false;
    _eWinnerPick = null;

    for (var i = 0; i < _eRunnerCount; i++) {
      _eRunnerCtrls.add(
        AnimationController(
          vsync: this,
          duration: Duration(milliseconds: _eDurationsMs[i]),
        ),
      );
    }
  }

  void _initStageG() {
    _gBounceCount = 4 + _rng.nextInt(4);
    _gReplays = 0;
    _gAnimating = false;
    _gPlayed = false;
    _gController.clear();
    _gBounceCtrl.reset();
  }

  String _randomEnemyName() {
    const names = ['glitch', 'pixel', 'byte', 'shadow', 'echo', 'void'];
    return names[_rng.nextInt(names.length)];
  }

  @override
  void dispose() {
    _aPulseCtrl.dispose();
    _a3LoopCtrl.dispose();
    _a3Controller.dispose();
    _bRevealCtrl.dispose();
    _cRotateCtrl.dispose();
    _dController.dispose();
    _dTimer?.cancel();
    _fSceneTimer?.cancel();
    _gBounceCtrl.dispose();
    _gController.dispose();
    for (final c in _eRunnerCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _completeStage({
    required double points,
    required bool perfect,
    bool countWrong = false,
  }) {
    _score = (_score + points).clamp(0.0, 1.0);
    if (perfect) _stagesPerfect++;
    if (countWrong && points <= 0) _wrongAnswers++;

    setState(() {
      _lastCorrect = perfect || points > 0;
      _transitioning = true;
    });

    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      if (_stage >= _totalStages - 1) {
        widget.onComplete(
          LevelOutcome(
            score: _score.clamp(0.0, 1.0),
            metrics: {
              'stages_perfect': _stagesPerfect,
              'rewatches': _rewatches,
              'wrong_answers': _wrongAnswers,
            },
          ),
        );
        return;
      }
      setState(() {
        _stage++;
        _transitioning = false;
        _prepareStage(_stage);
      });
    });
  }

  void _prepareStage(int stage) {
    if (stage == 0) {
      _initStageA(5);
    } else if (stage == 1) {
      _initStageA(10);
    } else if (stage == 2 || stage == 3) {
      _initStageA3();
    } else if (stage == 4) {
      _initStageB();
    } else if (stage == 5) {
      _initStageC();
    } else if (stage == 6 || stage == 7) {
      _initStageF();
    } else if (stage == 8 || stage == 9) {
      _initStageD();
    } else if (stage == 10 || stage == 11) {
      _initStageE();
    } else if (stage == 12) {
      _initStageG();
    }
  }

  // ===================== CATEGORY A =====================

  Future<void> _playCategoryA() async {
    if (_aAnimating) return;
    if (_aPlayed) {
      _aReplays++;
      _rewatches++;
    }
    setState(() {
      _aAnimating = true;
      _aPlayed = true;
      _aSelectedIdx = null;
    });
    _aPulseCtrl.reset();
    _aPulseCtrl.repeat();
    await Future.delayed(_aPulseCtrl.duration ?? const Duration(seconds: 3));
    if (!mounted) return;
    _aPulseCtrl.stop();
    _aPulseCtrl.reset();
    setState(() => _aAnimating = false);
  }

  void _submitCategoryA(int idx) {
    if (!_aPlayed || _aAnimating) return;
    setState(() => _aSelectedIdx = idx);
    final correct = idx == _aTargetIdx;
    double points = 0;
    if (correct) {
      points = max(0.02, _categoryAButtonMax - 0.02 * _aReplays);
    } else {
      _wrongAnswers++;
    }
    _completeStage(
      points: points,
      perfect: correct && _aReplays == 0,
      countWrong: !correct,
    );
  }

  // ===================== CATEGORY A3 =====================

  Future<void> _pressCategoryA3(int idx) async {
    if (_a3Playing) return;
    _a3PressCounts[idx] = (_a3PressCounts[idx] ?? 0) + 1;
    if (_a3PressCounts[idx]! > 1) {
      _a3Replays++;
      _rewatches++;
    }

    if (idx != _a3TargetIdx) {
      setState(() {});
      return;
    }

    setState(() {
      _a3Playing = true;
      _a3AnimSeen = true;
    });
    _a3LoopCtrl.repeat();
    await Future.delayed(const Duration(seconds: 5));
    if (!mounted) return;
    _a3LoopCtrl.stop();
    _a3LoopCtrl.reset();
    setState(() => _a3Playing = false);
  }

  void _submitCategoryA3() {
    if (!_a3AnimSeen) return;
    final entered = int.tryParse(_a3Controller.text.trim());
    final correct = entered != null && entered - 1 == _a3TargetIdx;
    double points = 0;
    if (correct) {
      points = _a3Replays == 0
          ? _categoryAProbeMax
          : max(0.015, _categoryAProbeMax * 0.5);
    } else {
      _wrongAnswers++;
    }
    _completeStage(
      points: points,
      perfect: correct && _a3Replays == 0,
      countWrong: !correct,
    );
  }

  // ===================== CATEGORY B =====================

  void _playCategoryBRound() {
    if (_bRaceDone || _bRaceRunning) return;
    setState(() => _bRaceRunning = true);

    final playerRoll = 15 + _rng.nextInt(26); // avg ~28, range 15-40
    Future.delayed(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _bPlayerScore = (_bPlayerScore + playerRoll).clamp(0, 100);
      });

      if (_bPlayerScore >= 100) {
        _finishCategoryBRace();
        return;
      }

      final enemyRoll = 15 + _rng.nextInt(26);
      Future.delayed(const Duration(milliseconds: 450), () {
        if (!mounted) return;
        setState(() {
          _bEnemyScore = (_bEnemyScore + enemyRoll).clamp(0, 100);
          _bRaceRunning = false;
        });
        if (_bEnemyScore >= 100) {
          _finishCategoryBRace();
        }
      });
    });
  }

  void _finishCategoryBRace() {
    if (_bRaceDone) return;
    setState(() {
      _bRaceRunning = false;
      _bRaceDone = true;
    });
    _startCategoryBAnimation();
  }

  void _startCategoryBAnimation() {
    _bPlayerWon = _bPlayerScore >= _bEnemyScore;
    _bAnimColor = _bPlayerWon
        ? const Color(0xFF22C55E)
        : const Color(0xFFFF5630);
    _bAnimSymbol = _bPlayerWon ? '🏆' : '💀';

    setState(() => _bShowingAnim = true);
    _bRevealCtrl.forward(from: 0).then((_) {
      if (!mounted) return;
      Future.delayed(const Duration(milliseconds: 2200), () {
        if (!mounted) return;
        _setupCategoryBQuiz();
        setState(() {
          _bShowingAnim = false;
          _bQuiz = true;
        });
      });
    });
  }

  void _setupCategoryBQuiz() {
    final correctColor = _bPlayerWon ? 0 : 1; // green win, red lose

    final facts = <_YesNoFact>[
      _YesNoFact('was "$_playerName" shown?', true),
      _YesNoFact('was "$_bEnemyName" shown?', true),
      _YesNoFact('was your score $_bPlayerScore shown?', true),
      _YesNoFact('was enemy score $_bEnemyScore shown?', true),
      _YesNoFact('was the symbol 🎈 shown?', false),
      _YesNoFact('was the symbol $_bAnimSymbol shown?', true),
      _YesNoFact('did you win the race?', _bPlayerWon),
    ]..shuffle(_rng);

    _bQuestions = [
      _QuizQuestion.color(correctColor),
      ...facts.take(4).map(_QuizQuestion.yesNo),
      _QuizQuestion.symbol(_bAnimSymbol),
    ];
    _bAnswers.clear();
  }

  void _submitCategoryB() {
    var correct = 0;
    for (var i = 0; i < _bQuestions.length; i++) {
      if (_bQuestions[i].isCorrect(_bAnswers[i])) correct++;
    }
    final wrong = _bQuestions.length - correct;
    _wrongAnswers += wrong;
    final points = _categoryBMax * (correct / _bQuestions.length);
    _completeStage(points: points, perfect: correct == _bQuestions.length);
  }

  // ===================== CATEGORY C =====================

  Future<void> _playCategoryCItem(int idx) async {
    if (_cActiveIdx >= 0 && _cRotateCtrl.isAnimating) return;
    final item = _cItems[idx];
    if (item.played) {
      item.replays++;
      _rewatches++;
    }
    setState(() {
      _cActiveIdx = idx;
      item.played = true;
      item.answer = null;
    });
    _cRotateCtrl.reset();
    await _cRotateCtrl.forward();
    if (!mounted) return;
    setState(() => _cActiveIdx = -1);
  }

  void _answerCategoryCItem(int idx, _RotationDir dir) {
    final item = _cItems[idx];
    if (!item.played || _cActiveIdx == idx) return;
    setState(() => item.answer = dir);
  }

  void _submitCategoryC() {
    if (!_cItems.every((item) => item.answer != null)) return;

    var correct = 0;
    for (final item in _cItems) {
      if (item.answer == item.direction) correct++;
    }
    final wrong = _cItems.length - correct;
    _wrongAnswers += wrong;

    var points = 0.0;
    for (final item in _cItems) {
      final itemMax = _categoryCMax / _cItems.length;
      if (item.answer == item.direction) {
        points += item.replays == 0 ? itemMax : itemMax * 0.5;
      }
    }

    _completeStage(
      points: points,
      perfect:
          correct == _cItems.length &&
          _cItems.every((item) => item.replays == 0),
    );
  }

  // ===================== CATEGORY F =====================

  void _playCategoryF() {
    if (_fShowingAnim) return;
    if (_fPlayed) {
      _fReplays++;
      _rewatches++;
    }
    _fSceneTimer?.cancel();
    setState(() {
      _fShowingAnim = true;
      _fPlayed = true;
      _fQuiz = false;
      _fSceneIdx = 0;
      _fAnswers.clear();
    });

    const totalMs = 10000;
    const tickMs = 100;
    var elapsed = 0;
    _fSceneTimer = Timer.periodic(const Duration(milliseconds: tickMs), (
      timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      elapsed += tickMs;
      final nextIdx = ((elapsed / totalMs) * _fScenes.length).floor().clamp(
        0,
        _fScenes.length - 1,
      );
      if (nextIdx != _fSceneIdx) {
        setState(() => _fSceneIdx = nextIdx);
      }
      if (elapsed >= totalMs) {
        timer.cancel();
        _setupCategoryFQuiz();
        setState(() {
          _fShowingAnim = false;
          _fQuiz = true;
        });
      }
    });
  }

  void _setupCategoryFQuiz() {
    final first = _fScenes.first;
    final last = _fScenes.last;
    final mid = _fScenes[_fScenes.length ~/ 2];

    final facts = <_YesNoFact>[
      _YesNoFact('did the animation start with "${first.label}"?', true),
      _YesNoFact('did the animation end with "${last.label}"?', true),
      _YesNoFact('was ${mid.emoji} shown at some point?', true),
      _YesNoFact('was 🎈 shown at any point?', false),
      _YesNoFact('did "${first.label}" appear before "${last.label}"?', true),
      _YesNoFact('was "volcano" shown?', false),
    ]..shuffle(_rng);

    _fQuestions = [
      _QuizQuestion.symbol(
        first.emoji,
        prompt: 'which symbol appeared first?',
        options: _sceneSymbolOptions(first.emoji),
      ),
      _QuizQuestion.symbol(
        last.emoji,
        prompt: 'which symbol appeared last?',
        options: _sceneSymbolOptions(last.emoji),
      ),
      ...facts.take(3).map(_QuizQuestion.yesNo),
    ];
    if (_fQuestions.length < 4) {
      _fQuestions.add(
        _QuizQuestion.symbol(
          mid.emoji,
          prompt: 'which symbol appeared in the middle?',
          options: _sceneSymbolOptions(mid.emoji),
        ),
      );
    }
    _fAnswers.clear();
  }

  List<String> _sceneSymbolOptions(String answer) {
    final options = _fScenes.map((scene) => scene.emoji).toSet().toList();
    options.addAll(['🎈', '⭐', '🏆']);
    options.remove(answer);
    options.shuffle(_rng);
    return ([answer, ...options.take(3)]..shuffle(_rng));
  }

  void _submitCategoryF() {
    var correct = 0;
    for (var i = 0; i < _fQuestions.length; i++) {
      if (_fQuestions[i].isCorrect(_fAnswers[i])) correct++;
    }
    _wrongAnswers += _fQuestions.length - correct;
    var points = _categoryFMax * (correct / _fQuestions.length);
    if (_fReplays > 0) points *= 0.5;
    _completeStage(
      points: points,
      perfect: correct == _fQuestions.length && _fReplays == 0,
    );
  }

  // ===================== CATEGORY D =====================

  void _playCategoryD() {
    if (_dAnimating) return;
    if (_dPlayed) {
      _dReplays++;
      _rewatches++;
    }
    _dTimer?.cancel();
    setState(() {
      _dAnimating = true;
      _dPlayed = true;
      _dShowing = true;
      _dDisplayValue = 0;
    });

    final start = DateTime.now();
    _dTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(start);
      if (elapsed < _dCountDuration) {
        final t = elapsed.inMilliseconds / _dCountDuration.inMilliseconds;
        setState(() {
          _dDisplayValue = (_dTarget * t).round().clamp(0, _dTarget);
        });
      } else if (elapsed < _dCountDuration + _dHoldDuration) {
        setState(() => _dDisplayValue = _dTarget);
      } else {
        timer.cancel();
        setState(() {
          _dShowing = false;
          _dAnimating = false;
        });
      }
    });
  }

  void _submitCategoryD() {
    if (!_dPlayed || _dAnimating) return;
    final entered = int.tryParse(_dController.text.trim());
    final correct = entered == _dTarget;
    double points = 0;
    if (correct) {
      points = _dReplays == 0 ? _categoryDMax : _categoryDMax * 0.5;
    } else {
      _wrongAnswers++;
    }
    _completeStage(
      points: points,
      perfect: correct && _dReplays == 0,
      countWrong: !correct,
    );
  }

  // ===================== CATEGORY E =====================

  Future<void> _playCategoryE() async {
    if (_eAnimating) return;
    if (_ePlayed) {
      _eReplays++;
      _rewatches++;
    }
    setState(() {
      _eAnimating = true;
      _ePlayed = true;
      _eFinished = false;
      _eShowingRace = true;
      _eWinnerPick = null;
    });

    for (final c in _eRunnerCtrls) {
      c.reset();
    }
    await Future.wait(_eRunnerCtrls.map((c) => c.forward()));
    if (!mounted) return;
    setState(() {
      _eAnimating = false;
      _eFinished = true;
    });
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;
    setState(() => _eShowingRace = false);
  }

  double _runnerProgress(int runnerIdx, double linearT) {
    if (_stage == 11) {
      final winner = _eFinishOrder.first;
      final t = linearT.clamp(0.0, 1.0);
      if (runnerIdx == winner) {
        if (t < 0.56) {
          return 0.26 * Curves.easeInCubic.transform(t / 0.56);
        }
        final lateT = ((t - 0.56) / 0.44).clamp(0.0, 1.0);
        return 0.26 + 0.88 * Curves.easeOutCubic.transform(lateT);
      }
      if (t < 0.48) {
        return 0.72 * Curves.easeOutQuart.transform(t / 0.48);
      }
      final slowT = ((t - 0.48) / 0.52).clamp(0.0, 1.0);
      return 0.72 + 0.13 * Curves.easeOutCubic.transform(slowT);
    }
    return _eCurves[runnerIdx].transform(linearT.clamp(0.0, 1.0));
  }

  void _submitCategoryE() {
    if (!_ePlayed || _eAnimating) return;

    final winner = _eFinishOrder.first;
    final correct = _eWinnerPick == winner;
    double points = 0;
    var perfect = false;
    if (correct) {
      points = _eReplays == 0 ? _categoryEMax : _categoryEMax * 0.5;
      perfect = _eReplays == 0;
    } else {
      _wrongAnswers++;
    }

    _completeStage(points: points, perfect: perfect, countWrong: points <= 0);
  }

  // ===================== CATEGORY G =====================

  Future<void> _playCategoryG() async {
    if (_gAnimating) return;
    if (_gPlayed) {
      _gReplays++;
      _rewatches++;
    }
    setState(() {
      _gAnimating = true;
      _gPlayed = true;
    });
    _gBounceCtrl.reset();
    await _gBounceCtrl.forward();
    if (!mounted) return;
    setState(() => _gAnimating = false);
  }

  void _submitCategoryG() {
    if (!_gPlayed || _gAnimating) return;
    final entered = int.tryParse(_gController.text.trim());
    final correct = entered == _gBounceCount;
    double points = 0;
    if (correct) {
      points = _gReplays == 0 ? _categoryGMax : _categoryGMax * 0.5;
    } else {
      _wrongAnswers++;
    }
    _completeStage(
      points: points,
      perfect: correct && _gReplays == 0,
      countWrong: !correct,
    );
  }

  // ===================== BUILD =====================

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(stageText: '${_stage + 1}/$_totalStages'),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_transitioning) return _buildTransition();
    if (_stage <= 1) return _buildCategoryA();
    if (_stage == 2 || _stage == 3) {
      if (_a3Playing) return _buildCategoryA3Animation();
      return _buildCategoryA3();
    }
    if (_stage == 4) {
      if (_bShowingAnim) return _buildCategoryBAnimation();
      if (_bQuiz) return _buildCategoryBQuiz();
      return _buildCategoryBRace();
    }
    if (_stage == 5) return _buildCategoryC();
    if (_stage == 6 || _stage == 7) {
      if (_fShowingAnim) return _buildCategoryFAnimation();
      if (_fQuiz) return _buildCategoryFQuiz();
      return _buildCategoryFIntro();
    }
    if (_stage == 8 || _stage == 9) return _buildCategoryD();
    if (_eShowingRace) return _buildCategoryERace();
    if (_stage == 12) return _buildCategoryG();
    return _buildCategoryE();
  }

  Widget _buildTransition() {
    return Center(
      child: Container(
        width: 96,
        height: 96,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: (_lastCorrect ? NunuColors.successMain : NunuColors.errorMain)
              .withValues(alpha: 0.12),
        ),
        child: Icon(
          _lastCorrect ? Icons.check_rounded : Icons.close_rounded,
          color: _lastCorrect ? NunuColors.successMain : NunuColors.errorMain,
          size: 48,
        ),
      ),
    );
  }

  // ---- Category A UI ----

  Widget _buildCategoryA() {
    final cols = _aButtonCount <= 5 ? _aButtonCount : 5;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'press play, watch which button animates, then tap that button.',
          ),
          if (_aReplays > 0) ...[
            const SizedBox(height: 12),
            _miniStatusCard('replays: $_aReplays (costs points)'),
          ],
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_aButtonCount, (i) {
              final animating = _aAnimating && i == _aTargetIdx;
              return SizedBox(
                width:
                    (MediaQuery.sizeOf(context).width - 48 - (cols - 1) * 12) /
                    cols,
                child: AnimatedBuilder(
                  animation: _aPulseCtrl,
                  builder: (context, child) {
                    final wave = (sin(_aPulseCtrl.value * pi * 2) + 1) / 2;
                    final stageOne = _stage == 0;
                    final scale = animating
                        ? (stageOne ? 1.08 : 1.0 + 0.28 * wave)
                        : 1.0;
                    final glow = animating ? wave : 0.0;
                    final xOffset = animating && stageOne
                        ? sin(_aPulseCtrl.value * pi * 8) * 16
                        : 0.0;
                    final yOffset = animating && stageOne
                        ? cos(_aPulseCtrl.value * pi * 4) * 6
                        : 0.0;
                    final angle = animating && stageOne
                        ? sin(_aPulseCtrl.value * pi * 8) * 0.16
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(xOffset, yOffset),
                      child: Transform.rotate(
                        angle: angle,
                        child: Transform.scale(
                          scale: scale,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: animating && stageOne
                                  ? Border.all(
                                      color: Colors.white.withValues(
                                        alpha: 0.65 + 0.35 * glow,
                                      ),
                                      width: 3,
                                    )
                                  : null,
                              boxShadow: glow > 0
                                  ? [
                                      BoxShadow(
                                        color:
                                            (stageOne
                                                    ? NunuColors.warningMain
                                                    : NunuColors.primaryMain)
                                                .withValues(
                                                  alpha:
                                                      (stageOne ? 0.85 : 0.5) *
                                                      glow,
                                                ),
                                        blurRadius: (stageOne ? 36 : 20) * glow,
                                        spreadRadius:
                                            (stageOne ? 10 : 4) * glow,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: _stageButton(
                    label: '${i + 1}',
                    onTap: () => _submitCategoryA(i),
                    highlighted: _aSelectedIdx == i,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          _actionBtn(
            label: _aPlayed ? 'replay' : 'play',
            icon: Icons.play_arrow_rounded,
            onPressed: _aAnimating ? null : _playCategoryA,
            expand: true,
          ),
        ],
      ),
    );
  }

  // ---- Category A3 UI ----

  Widget _buildCategoryA3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'press the buttons. only one button opens an animation. enter which button it was.',
          ),
          if (_a3Replays > 0) ...[
            const SizedBox(height: 12),
            _miniStatusCard(
              'repeated button presses: $_a3Replays (costs points)',
            ),
          ],
          const SizedBox(height: 28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(5, (i) {
              final width =
                  (MediaQuery.sizeOf(context).width - 48 - 4 * 12) / 5;
              return SizedBox(
                width: width.clamp(56.0, 120.0),
                child: _stageButton(
                  label: '${i + 1}',
                  onTap: () => _pressCategoryA3(i),
                  highlighted: _a3PressCounts[i] != null,
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          _singleAnswerField(
            controller: _a3Controller,
            label: 'animated button (1-5)',
            hintText: '1',
            digitsOnly: true,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  label: 'clear',
                  icon: Icons.backspace_rounded,
                  onPressed: () => setState(() => _a3Controller.clear()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  label: 'submit',
                  onPressed: _a3AnimSeen ? _submitCategoryA3 : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryA3Animation() {
    return AnimatedBuilder(
      animation: _a3LoopCtrl,
      builder: (context, child) {
        final pulse = 1.0 + 0.22 * sin(_a3LoopCtrl.value * pi * 2);
        final glow = (sin(_a3LoopCtrl.value * pi * 2) + 1) / 2;
        return Container(
          color: NunuColors.backgroundDefault,
          child: Center(
            child: Transform.scale(
              scale: pulse,
              child: Container(
                width: 140,
                height: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: NunuColors.primaryMain.withValues(
                        alpha: 0.35 + 0.4 * glow,
                      ),
                      blurRadius: 28 + 22 * glow,
                      spreadRadius: 8 + 8 * glow,
                    ),
                  ],
                ),
                child: Text(
                  '⚡',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ---- Category B UI ----

  Widget _buildCategoryBRace() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard('press play to win. lets see who wins.'),
          const SizedBox(height: 18),
          _miniStatusCard(
            '$_playerName: $_bPlayerScore  ·  $_bEnemyName: $_bEnemyScore',
          ),
          const SizedBox(height: 8),
          _miniStatusCard(
            _bRaceDone ? 'race over — watch the recap' : 'first to 100 wins',
          ),
          const SizedBox(height: 28),
          _actionBtn(
            label: 'play',
            icon: Icons.casino_rounded,
            onPressed: (_bRaceDone || _bRaceRunning)
                ? null
                : _playCategoryBRound,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBAnimation() {
    return AnimatedBuilder(
      animation: _bRevealCtrl,
      builder: (context, child) {
        final t = Curves.easeOutBack.transform(_bRevealCtrl.value);
        return Container(
          color: _bAnimColor.withValues(alpha: 0.92),
          child: Center(
            child: Transform.scale(
              scale: 0.5 + 0.5 * t,
              child: Opacity(opacity: t.clamp(0.0, 1.0), child: child),
            ),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_bAnimSymbol, style: const TextStyle(fontSize: 72)),
          const SizedBox(height: 16),
          Text(
            _bPlayerWon ? 'you win!' : 'you lose!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '$_playerName: $_bPlayerScore',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$_bEnemyName: $_bEnemyScore',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBQuiz() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'answer every question about the animation you saw.',
          ),
          const SizedBox(height: 24),
          for (var i = 0; i < _bQuestions.length; i++) ...[
            _buildQuizQuestion(i, _bQuestions[i], _bAnswers),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          _actionBtn(
            label: 'submit answers',
            onPressed: _bAnswers.length == _bQuestions.length
                ? _submitCategoryB
                : null,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildQuizQuestion(
    int idx,
    _QuizQuestion q,
    Map<int, dynamic> answers,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NunuColors.primaryMain.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q.prompt,
            style: const TextStyle(
              color: NunuColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 12),
          if (q.kind == _QuizKind.color)
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_colorOptions.length, (ci) {
                final opt = _colorOptions[ci];
                final selected = answers[idx] == ci;
                return GestureDetector(
                  onTap: () => setState(() => answers[idx] = ci),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: opt.color.withValues(
                        alpha: selected ? 0.95 : 0.25,
                      ),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected ? Colors.white : opt.color,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      opt.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              }),
            )
          else if (q.kind == _QuizKind.yesNo)
            Row(
              children: [
                Expanded(
                  child: _choiceChip(
                    label: 'yes',
                    selected: answers[idx] == true,
                    onTap: () => setState(() => answers[idx] = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _choiceChip(
                    label: 'no',
                    selected: answers[idx] == false,
                    onTap: () => setState(() => answers[idx] = false),
                  ),
                ),
              ],
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: q.symbolOptions.map((emoji) {
                final selected = answers[idx] == emoji;
                return GestureDetector(
                  onTap: () => setState(() => answers[idx] = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: selected
                          ? NunuColors.primaryMain
                          : NunuColors.backgroundDefault,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? Colors.white
                            : NunuColors.primaryMain.withValues(alpha: 0.3),
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Text(emoji, style: const TextStyle(fontSize: 28)),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ---- Category C UI ----

  Widget _buildCategoryC() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'for each emoji press go, watch the spin, then pick clockwise or counter-clockwise.',
          ),
          const SizedBox(height: 20),
          for (var i = 0; i < _cItems.length; i++) ...[
            _buildCategoryCRow(i),
            if (i < _cItems.length - 1) const SizedBox(height: 14),
          ],
          const SizedBox(height: 24),
          _actionBtn(
            label: 'submit all',
            onPressed: _cItems.every((item) => item.answer != null)
                ? _submitCategoryC
                : null,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCRow(int idx) {
    final item = _cItems[idx];
    final active = _cActiveIdx == idx;
    final turns = item.direction == _RotationDir.clockwise ? 2.0 : -2.0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NunuColors.primaryMain.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                height: 72,
                child: Center(
                  child: active
                      ? RotationTransition(
                          turns: Tween<double>(begin: 0, end: turns).animate(
                            CurvedAnimation(
                              parent: _cRotateCtrl,
                              curve: Curves.linear,
                            ),
                          ),
                          child: Text(
                            item.emoji,
                            style: const TextStyle(fontSize: 44),
                          ),
                        )
                      : Text(item.emoji, style: const TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  label: item.played ? 'replay' : 'go',
                  icon: Icons.rotate_right_rounded,
                  onPressed: active ? null : () => _playCategoryCItem(idx),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _choiceChip(
                  label: 'clockwise',
                  selected: item.answer == _RotationDir.clockwise,
                  onTap: item.played && !active
                      ? () => _answerCategoryCItem(idx, _RotationDir.clockwise)
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _choiceChip(
                  label: 'counter-clockwise',
                  selected: item.answer == _RotationDir.counterClockwise,
                  onTap: item.played && !active
                      ? () => _answerCategoryCItem(
                          idx,
                          _RotationDir.counterClockwise,
                        )
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Category F UI ----

  Widget _buildCategoryFIntro() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'press go and watch the full-screen scene animation for 10 seconds, then answer the quiz.',
          ),
          if (_fReplays > 0) ...[
            const SizedBox(height: 12),
            _miniStatusCard('replays: $_fReplays'),
          ],
          const SizedBox(height: 40),
          _actionBtn(
            label: _fPlayed ? 'replay' : 'go',
            icon: Icons.play_arrow_rounded,
            onPressed: _playCategoryF,
            expand: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFAnimation() {
    final scene = _fScenes[_fSceneIdx];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
      color: scene.color.withValues(alpha: 0.95),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(scene.emoji, style: const TextStyle(fontSize: 96)),
            const SizedBox(height: 20),
            Text(
              scene.label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryFQuiz() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard('answer every question about the scene animation.'),
          const SizedBox(height: 24),
          for (var i = 0; i < _fQuestions.length; i++) ...[
            _buildQuizQuestion(i, _fQuestions[i], _fAnswers),
            const SizedBox(height: 14),
          ],
          const SizedBox(height: 14),
          _actionBtn(
            label: 'submit answers',
            onPressed: _fAnswers.length == _fQuestions.length
                ? _submitCategoryF
                : null,
            expand: true,
          ),
        ],
      ),
    );
  }

  // ---- Category D UI ----

  Widget _buildCategoryD() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'press go, watch the counter, then enter the final number. rewatch halves your score.',
          ),
          if (_dReplays > 0) ...[
            const SizedBox(height: 12),
            _miniStatusCard('replays: $_dReplays'),
          ],
          const SizedBox(height: 40),
          Container(
            width: double.infinity,
            height: 120,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: NunuColors.primaryMain.withValues(alpha: 0.25),
              ),
            ),
            child: _dShowing
                ? Text(
                    '$_dDisplayValue',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  )
                : Text(
                    _dPlayed ? '???' : 'press go',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
          const SizedBox(height: 28),
          _singleAnswerField(
            controller: _dController,
            label: 'final count',
            hintText: '0',
            digitsOnly: true,
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  label: _dPlayed ? 'replay' : 'go',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _dAnimating ? null : _playCategoryD,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  label: 'submit',
                  onPressed: (_dPlayed && !_dAnimating)
                      ? _submitCategoryD
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---- Category E UI ----

  Widget _buildCategoryERace() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth * 0.72;
        final laneHeight = max(
          72.0,
          constraints.maxHeight / (_eRunnerCount + 1),
        );
        return Container(
          color: NunuColors.backgroundDefault,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'race!',
                style: TextStyle(
                  color: NunuColors.primaryLight,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'watch who finishes first',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Stack(
                  children: [
                    Positioned(
                      left: 16,
                      right: 16,
                      top: 0,
                      bottom: 24,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: NunuColors.primaryMain.withValues(
                              alpha: 0.25,
                            ),
                          ),
                          color: NunuColors.backgroundPaper.withValues(
                            alpha: 0.45,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: constraints.maxWidth * 0.86,
                      top: 0,
                      bottom: 24,
                      child: Container(
                        width: 4,
                        decoration: BoxDecoration(
                          color: NunuColors.successMain.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    for (var i = 0; i < _eRunnerCount; i++)
                      AnimatedBuilder(
                        animation: _eRunnerCtrls[i],
                        builder: (context, child) {
                          final progress = _runnerProgress(
                            i,
                            _eRunnerCtrls[i].value,
                          );
                          final x = 24 + trackWidth * progress;
                          return Positioned(
                            left: x,
                            top: 18 + i * laneHeight,
                            child: child!,
                          );
                        },
                        child: Text(
                          _eRunners[i],
                          style: TextStyle(
                            fontSize: 42,
                            shadows: _eFinished && i == _eFinishOrder.first
                                ? [
                                    Shadow(
                                      color: NunuColors.successMain.withValues(
                                        alpha: 0.95,
                                      ),
                                      blurRadius: 22,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    if (_eFinished && _stage == 10)
                      Positioned(
                        left: 24,
                        right: 24,
                        bottom: 36,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: NunuColors.successMain.withValues(
                              alpha: 0.94,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: NunuColors.successMain.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 24,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Text(
                            '${_eRunners[_eFinishOrder.first]} wins!',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    if (_eFinished && _stage == 11)
                      Positioned(
                        left:
                            24 +
                            trackWidth *
                                _runnerProgress(
                                  _eFinishOrder.first,
                                  _eRunnerCtrls[_eFinishOrder.first].value,
                                ) -
                            11,
                        top: 18 + _eFinishOrder.first * laneHeight - 8,
                        child: Container(
                          width: 66,
                          height: 66,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: NunuColors.successMain,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: NunuColors.successMain.withValues(
                                  alpha: 0.55,
                                ),
                                blurRadius: 22,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryE() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'press go, watch the full-screen race, then pick who finished first.',
          ),
          if (_eReplays > 0) ...[
            const SizedBox(height: 12),
            _miniStatusCard('replays: $_eReplays'),
          ],
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: List.generate(_eRunnerCount, (i) {
              final selected = _eWinnerPick == i;
              return GestureDetector(
                onTap: _eFinished
                    ? () => setState(() => _eWinnerPick = i)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? NunuColors.primaryMain
                        : NunuColors.backgroundPaper,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? Colors.white
                          : NunuColors.primaryMain.withValues(alpha: 0.3),
                      width: selected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    _eRunners[i],
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  label: _ePlayed ? 'replay' : 'go',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _eAnimating ? null : _playCategoryE,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  label: 'submit',
                  onPressed: _canSubmitCategoryE() ? _submitCategoryE : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _canSubmitCategoryE() {
    if (!_eFinished || _eAnimating) return false;
    return _eWinnerPick != null;
  }

  // ---- Category G UI ----

  Widget _buildCategoryG() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        children: [
          _instructionCard(
            'press go, watch the ball, then enter how many times it hit the ground.',
          ),
          if (_gReplays > 0) ...[
            const SizedBox(height: 12),
            _miniStatusCard('replays: $_gReplays'),
          ],
          const SizedBox(height: 24),
          Container(
            height: 260,
            decoration: BoxDecoration(
              color: NunuColors.backgroundPaper,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: NunuColors.primaryMain.withValues(alpha: 0.25),
              ),
            ),
            child: AnimatedBuilder(
              animation: _gBounceCtrl,
              builder: (context, child) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final t = _gBounceCtrl.value;
                    final segment = (t * _gBounceCount).clamp(
                      0.0,
                      _gBounceCount.toDouble(),
                    );
                    final phase = segment - segment.floorToDouble();
                    final arc = sin(pi * phase);
                    final x = 24 + (constraints.maxWidth - 72) * t;
                    final groundY = constraints.maxHeight - 54;
                    final y = groundY - arc * 150 * (1 - 0.05 * segment);
                    return Stack(
                      children: [
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 34,
                          child: Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: NunuColors.successMain.withValues(
                                alpha: 0.55,
                              ),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        Positioned(
                          left: x,
                          top: y,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: NunuColors.primaryMain,
                              boxShadow: [
                                BoxShadow(
                                  color: NunuColors.primaryMain.withValues(
                                    alpha: 0.55,
                                  ),
                                  blurRadius: 16,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          _singleAnswerField(
            controller: _gController,
            label: 'ground hits',
            hintText: '0',
            digitsOnly: true,
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  label: _gPlayed ? 'replay' : 'go',
                  icon: Icons.play_arrow_rounded,
                  onPressed: _gAnimating ? null : _playCategoryG,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _actionBtn(
                  label: 'submit',
                  onPressed: (_gPlayed && !_gAnimating)
                      ? _submitCategoryG
                      : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ===================== SHARED WIDGETS =====================

  Widget _instructionCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NunuColors.primaryDark.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: NunuColors.primaryLight,
          fontWeight: FontWeight.w600,
          fontSize: 15,
          height: 1.45,
        ),
      ),
    );
  }

  Widget _miniStatusCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: NunuColors.primaryMain.withValues(alpha: 0.2),
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _stageButton({
    required String label,
    required VoidCallback onTap,
    bool highlighted = false,
  }) {
    return Material(
      color: highlighted ? NunuColors.primaryMain : NunuColors.backgroundPaper,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted
                  ? Colors.white
                  : NunuColors.primaryMain.withValues(alpha: 0.3),
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceChip({
    required String label,
    bool selected = false,
    VoidCallback? onTap,
  }) {
    return Material(
      color: selected ? NunuColors.primaryMain : NunuColors.backgroundPaper,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.white
                  : NunuColors.primaryMain.withValues(alpha: 0.3),
              width: selected ? 2 : 1,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onTap == null ? Colors.white38 : Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _singleAnswerField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    bool digitsOnly = false,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NunuColors.primaryMain.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: NunuColors.primaryLight,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.18)),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 12,
              ),
              filled: true,
              fillColor: NunuColors.backgroundDefault,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: NunuColors.primaryMain.withValues(alpha: 0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: NunuColors.primaryMain.withValues(alpha: 0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: NunuColors.primaryMain,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    VoidCallback? onPressed,
    String label = 'submit',
    IconData icon = Icons.check_rounded,
    bool expand = false,
  }) {
    final enabled = onPressed != null;
    final btn = FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
        backgroundColor: enabled
            ? NunuColors.successMain
            : NunuColors.successMain.withValues(alpha: 0.2),
        foregroundColor: enabled ? Colors.white : Colors.white38,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    return expand
        ? SizedBox(width: double.infinity, height: 50, child: btn)
        : btn;
  }
}

// ===================== QUIZ HELPERS =====================

enum _QuizKind { color, yesNo, symbol }

class _YesNoFact {
  const _YesNoFact(this.prompt, this.answer);
  final String prompt;
  final bool answer;
}

class _QuizQuestion {
  _QuizQuestion._(
    this.kind,
    this.prompt,
    this.answer, {
    this.symbolOptions = const ['🏆', '💀', '🎈', '⭐'],
  });

  factory _QuizQuestion.color(int correctIdx) => _QuizQuestion._(
    _QuizKind.color,
    'what was the overall color of the animation?',
    correctIdx,
  );

  factory _QuizQuestion.yesNo(_YesNoFact fact) =>
      _QuizQuestion._(_QuizKind.yesNo, fact.prompt, fact.answer);

  factory _QuizQuestion.symbol(
    String symbol, {
    String prompt = 'which symbol was shown?',
    List<String>? options,
  }) => _QuizQuestion._(
    _QuizKind.symbol,
    prompt,
    symbol,
    symbolOptions: options ?? const ['🏆', '💀', '🎈', '⭐'],
  );

  final _QuizKind kind;
  final String prompt;
  final dynamic answer;
  final List<String> symbolOptions;

  bool isCorrect(dynamic response) => response == answer;
}
