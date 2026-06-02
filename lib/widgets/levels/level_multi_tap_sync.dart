import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

class LevelMultiTapSync extends LevelWidget {
  const LevelMultiTapSync({super.key, required super.onComplete});

  @override
  State<LevelMultiTapSync> createState() => _LevelMultiTapSyncState();
}

class _LevelMultiTapSyncState extends State<LevelMultiTapSync>
    with TickerProviderStateMixin {
  static const Duration _syncWindow = Duration(milliseconds: 260);
  static const Duration _holdWindow = Duration(milliseconds: 340);
  static const Duration _tapWindow = Duration(milliseconds: 500);
  static const Duration _buttonHoldDuration = Duration(seconds: 3);
  static const Duration _buttonHoldMaxDuration = Duration(milliseconds: 3600);
  static const Duration _hiddenWaitDuration = Duration(seconds: 60);

  static const int _livesPerStage = 3;
  static const double _laneSyncSlack = 52;
  static const int _totalStages = 8;
  static const double _scorePerStagePerfect = 0.125;
  static const double _scorePerStageOneLifeLost = 0.08;
  static const double _scorePerStageTwoLivesLost = 0.04;
  static const int _doubleTapPhase = 0;
  static const int _tripleTapPhase = 1;
  static const int _holdButtonPhase = 2;
  static const int _dontClickPhase = 3;
  static const int _syncPadsPhase = 4;
  static const int _syncDoubleTapPhase = 5;
  static const int _tripleLiftPhase = 6;
  static const int _dualBindPhase = 7;

  final Set<int> _pressedPads = <int>{};
  final Map<int, int> _pointerToPad = <int, int>{};
  final Map<int, int> _lanePointerToLane = <int, int>{};
  final Set<int> _syncTapPressedButtons = <int>{};
  final Map<int, int> _syncTapPointerToButton = <int, int>{};
  DateTime? _firstPressAt;
  Timer? _holdTimer;
  Timer? _tapStageTimer;
  Timer? _buttonHoldTimer;
  Timer? _buttonHoldProgressTimer;
  Timer? _syncTapTimer;
  Timer? _syncTapWindowTimer;
  Timer? _laneSyncWindowTimer;
  Timer? _hiddenWaitTimer;
  DateTime? _buttonHoldStartedAt;
  DateTime? _syncTapFirstDownAt;
  int _tapCount = 0;
  int _syncTapCyclesCompleted = 0;
  bool _syncTapChordCompleted = false;
  bool _laneChordCompleted = false;
  bool _buttonHeld = false;
  double _buttonHoldProgress = 0;

  /// 0 = double tap, 1 = triple tap, 2 = hold button, 3 = don't click,
  /// 4 = hold three pads, 5 = swipe up on three lanes together,
  /// 6 = hold + swipe elsewhere
  int _phase = _doubleTapPhase;
  int _lives = _livesPerStage;
  final List<double> _laneUpAccum = [0, 0, 0];
  bool _anchorHeld = false;
  int? _anchorPointerId;
  double _dualSwipeAccum = 0;
  final List<double> _stageScores = List<double>.filled(_totalStages, 0);
  final List<int> _stageLivesLost = List<int>.filled(_totalStages, 0);
  final List<bool> _stagePassed = List<bool>.filled(_totalStages, false);
  late final AnimationController _pulse;
  late final AnimationController _spin;
  late final AnimationController _energyFlow;
  String _status = 'double tap the ignition key';

  // Neon colors for the reactor
  static const Color _cyanNeon = Color(0xFF00F5FF);
  static const Color _magentaNeon = Color(0xFFFF00FF);
  static const Color _coreGlow = Color(0xFF00FFAA);

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: _stageScores.fold(0.0, (s, v) => s + v).clamp(0.0, 1.0)));
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..repeat(reverse: true);
    _spin = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _energyFlow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    _tapStageTimer?.cancel();
    _buttonHoldTimer?.cancel();
    _buttonHoldProgressTimer?.cancel();
    _syncTapTimer?.cancel();
    _syncTapWindowTimer?.cancel();
    _laneSyncWindowTimer?.cancel();
    _hiddenWaitTimer?.cancel();
    _pulse.dispose();
    _spin.dispose();
    _energyFlow.dispose();
    super.dispose();
  }

  void _resetCurrentStageInputs() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _tapStageTimer?.cancel();
    _tapStageTimer = null;
    _buttonHoldTimer?.cancel();
    _buttonHoldTimer = null;
    _buttonHoldProgressTimer?.cancel();
    _buttonHoldProgressTimer = null;
    _syncTapTimer?.cancel();
    _syncTapTimer = null;
    _syncTapWindowTimer?.cancel();
    _syncTapWindowTimer = null;
    _laneSyncWindowTimer?.cancel();
    _laneSyncWindowTimer = null;
    _hiddenWaitTimer?.cancel();
    _hiddenWaitTimer = null;
    _pressedPads.clear();
    _pointerToPad.clear();
    _lanePointerToLane.clear();
    _syncTapPressedButtons.clear();
    _syncTapPointerToButton.clear();
    _firstPressAt = null;
    _syncTapFirstDownAt = null;
    _tapCount = 0;
    _syncTapCyclesCompleted = 0;
    _syncTapChordCompleted = false;
    _laneChordCompleted = false;
    _buttonHoldStartedAt = null;
    _buttonHeld = false;
    _buttonHoldProgress = 0;
    _laneUpAccum[0] = _laneUpAccum[1] = _laneUpAccum[2] = 0;
    _anchorHeld = false;
    _anchorPointerId = null;
    _dualSwipeAccum = 0;
  }

  String _defaultStatusForPhase(int phase) {
    switch (phase) {
      case _doubleTapPhase:
        return 'double tap the ignition key';
      case _tripleTapPhase:
        return 'triple tap the ignition key';
      case _holdButtonPhase:
        return 'hold the button for ${_buttonHoldDuration.inSeconds} seconds';
      case _dontClickPhase:
        return "don't click the button";
      case _syncPadsPhase:
        return 'press and hold all 3 pads at once';
      case _syncDoubleTapPhase:
        return 'double tap both switches together';
      case _tripleLiftPhase:
        return 'swipe up on all three lanes at the same time';
      case _dualBindPhase:
        return 'hold the anchor with one finger; swipe right on the conduit with another';
      default:
        return '';
    }
  }

  void _enterPhase(
    int phase, {
    bool resetLives = true,
    String? statusOverride,
  }) {
    _resetCurrentStageInputs();
    if (!mounted) return;
    setState(() {
      _phase = phase;
      if (resetLives) {
        _lives = _livesPerStage;
      }
      _status = statusOverride ?? _defaultStatusForPhase(phase);
    });
    if (phase == _dontClickPhase) {
      _hiddenWaitTimer = Timer(_hiddenWaitDuration, () {
        if (!mounted || _phase != _dontClickPhase) return;
        _completeCurrentPhase(passed: true);
      });
    }
  }

  double _scoreForCurrentStage() {
    final lost = (_livesPerStage - _lives).clamp(0, _livesPerStage);
    switch (lost) {
      case 0:
        return _scorePerStagePerfect;
      case 1:
        return _scorePerStageOneLifeLost;
      case 2:
        return _scorePerStageTwoLivesLost;
      default:
        return 0.0;
    }
  }

  void _completeCurrentPhase({required bool passed}) {
    final stageIndex = _phase.clamp(0, _totalStages - 1);
    _stageScores[stageIndex] = _scoreForCurrentStage();
    _stageLivesLost[stageIndex] = (_livesPerStage - _lives).clamp(
      0,
      _livesPerStage,
    );
    _stagePassed[stageIndex] = passed;

    if (stageIndex >= _totalStages - 1) {
      widget.onComplete(
        LevelOutcome(
          score: _stageScores
              .fold(0.0, (sum, value) => sum + value)
              .clamp(0.0, 1.0),
          metrics: {
            'stages_passed': _stagePassed.where((passed) => passed).length,
            'lives_lost_total': _stageLivesLost.fold(
              0,
              (sum, value) => sum + value,
            ),
          },
        ),
      );
      return;
    }

    _enterPhase(stageIndex + 1);
  }

  void _loseLife(String statusAfterReset) {
    _lives = (_lives - 1).clamp(0, _livesPerStage);
    if (_lives <= 0) {
      _completeCurrentPhase(passed: false);
      return;
    }
    _enterPhase(
      _phase,
      resetLives: false,
      statusOverride: '$statusAfterReset ($_lives lives left)',
    );
  }

  static const double _laneUpNeeded = 56;
  static const double _dualSwipeNeeded = 80;

  void _startHoldCheck() {
    _holdTimer?.cancel();
    _holdTimer = Timer(_holdWindow, () {
      if (!mounted) return;
      if (_pressedPads.length == 3) {
        _completeCurrentPhase(passed: true);
      }
    });
  }

  void _onLanePointerDown(int lane, int pointerId) {
    if (_phase != _tripleLiftPhase) return;
    final wasEmpty = _lanePointerToLane.isEmpty;
    _lanePointerToLane[pointerId] = lane;
    if (wasEmpty) {
      _laneChordCompleted = false;
      _laneSyncWindowTimer?.cancel();
      _laneSyncWindowTimer = Timer(_syncWindow, () {
        if (!mounted || _phase != _tripleLiftPhase) return;
        if (_lanePointerToLane.values.toSet().length < 3 &&
            !_laneChordCompleted) {
          _loseLife('lanes desynced. start all three together.');
        }
      });
    }
    if (_lanePointerToLane.values.toSet().length == 3) {
      _laneSyncWindowTimer?.cancel();
      _laneSyncWindowTimer = null;
      _laneChordCompleted = true;
    }
  }

  void _onLanePointerMove(int lane, int pointerId, Offset delta) {
    if (_phase != _tripleLiftPhase) return;
    if (_lanePointerToLane[pointerId] != lane) return;
    if (_lanePointerToLane.values.toSet().length < 3) {
      if (delta.dy < -6) {
        _loseLife('all three lanes must lift together.');
      }
      return;
    }
    if (delta.dy >= 0) return;
    final double nextLane = _laneUpAccum[lane] - delta.dy;
    final double n0 = lane == 0 ? nextLane : _laneUpAccum[0];
    final double n1 = lane == 1 ? nextLane : _laneUpAccum[1];
    final double n2 = lane == 2 ? nextLane : _laneUpAccum[2];
    final double nextMax = math.max(math.max(n0, n1), n2);
    final double nextMin = math.min(math.min(n0, n1), n2);
    if (nextMax - nextMin > _laneSyncSlack && nextMax > 10) {
      _loseLife('lanes desynced. lift together.');
      return;
    }
    setState(() {
      _laneUpAccum[lane] = nextLane;
    });
    if (n0 >= _laneUpNeeded && n1 >= _laneUpNeeded && n2 >= _laneUpNeeded) {
      _completeCurrentPhase(passed: true);
    }
  }

  void _onLanePointerUp(int pointerId) {
    if (_phase != _tripleLiftPhase) return;
    _lanePointerToLane.remove(pointerId);
    if (_lanePointerToLane.isEmpty) {
      _laneSyncWindowTimer?.cancel();
      _laneSyncWindowTimer = null;
      if (!_laneChordCompleted) {
        _loseLife('lanes released too soon. use all three together.');
        return;
      }
      _laneChordCompleted = false;
    }
  }

  void _onDualAnchorDown(PointerDownEvent e) {
    if (_phase != _dualBindPhase) return;
    if (_anchorHeld) return;
    setState(() {
      _anchorHeld = true;
      _anchorPointerId = e.pointer;
      _status =
          'keep anchor down — swipe right on the conduit (${_dualSwipeAccum.toStringAsFixed(0)}/${_dualSwipeNeeded.toStringAsFixed(0)})';
    });
  }

  void _onDualAnchorUp(PointerEvent e) {
    if (_phase != _dualBindPhase) return;
    if (e.pointer != _anchorPointerId) return;
    final bool incomplete = _dualSwipeAccum < _dualSwipeNeeded;
    if (incomplete && (_anchorHeld || _dualSwipeAccum > 0)) {
      _loseLife('anchor dropped before conduit synced.');
      return;
    }
    setState(() {
      _anchorHeld = false;
      _anchorPointerId = null;
    });
  }

  void _onDualSwipeMove(PointerMoveEvent e) {
    if (_phase != _dualBindPhase) return;
    if (!_anchorHeld) return;
    if (e.delta.dx <= 0) return;
    final double nextAccum = _dualSwipeAccum + e.delta.dx;
    setState(() {
      _dualSwipeAccum = nextAccum;
      _status =
          'keep anchor — swipe right (${nextAccum.toStringAsFixed(0)}/${_dualSwipeNeeded.toStringAsFixed(0)})';
    });
    if (nextAccum >= _dualSwipeNeeded) {
      _completeCurrentPhase(passed: true);
    }
  }

  void _onPadDown(int padId, int pointerId) {
    if (_phase != _syncPadsPhase) return;
    final DateTime now = DateTime.now();
    if (_pressedPads.isEmpty) {
      _firstPressAt = now;
    } else if (!_pressedPads.contains(padId) &&
        _firstPressAt != null &&
        now.difference(_firstPressAt!) > _syncWindow) {
      _loseLife('desynced. retry the ritual.');
      return;
    }

    setState(() {
      _pointerToPad[pointerId] = padId;
      _pressedPads.add(padId);
      _status = _pressedPads.length == 3
          ? 'perfect sync... hold...'
          : 'sync the remaining pads';
    });

    if (_pressedPads.length == 3) {
      _startHoldCheck();
    }
  }

  void _onPadUp(int pointerId) {
    if (_phase != _syncPadsPhase) return;
    final int? padId = _pointerToPad.remove(pointerId);
    if (padId == null) return;

    final bool padStillPressed = _pointerToPad.containsValue(padId);
    if (!padStillPressed) {
      _loseLife('channel released too soon. restart the sync.');
      return;
    }

    setState(() {
      if (!padStillPressed) {
        _pressedPads.remove(padId);
      }

      if (_pressedPads.length < 3) {
        _holdTimer?.cancel();
        _holdTimer = null;
      }

      if (_pressedPads.isEmpty) {
        _firstPressAt = null;
        _status = 'press and hold all 3 pads at once';
      } else {
        _status = 'sync the remaining pads';
      }
    });
  }

  void _onCorePointerDown() {
    if (_phase != _syncPadsPhase) return;
    _loseLife('reactor core is locked. sync the outer pads.');
  }

  void _onTapStagePressed(int requiredTaps) {
    if (_phase != _doubleTapPhase && _phase != _tripleTapPhase) return;
    _tapStageTimer?.cancel();
    _tapCount++;
    if (_tapCount > requiredTaps) {
      _loseLife('too many taps. start over.');
      return;
    }
    if (_tapCount == requiredTaps) {
      _completeCurrentPhase(passed: true);
      return;
    }
    _tapStageTimer = Timer(_tapWindow, () {
      if (!mounted) return;
      _loseLife('tap chain broken. try again.');
    });
  }

  void _onHoldButtonDown(PointerDownEvent event) {
    if (_phase != _holdButtonPhase || _buttonHeld) return;
    _buttonHoldStartedAt = DateTime.now();
    _buttonHeld = true;
    _buttonHoldTimer?.cancel();
    _buttonHoldProgressTimer?.cancel();
    setState(() {
      _status = 'hold steady...';
      _buttonHoldProgress = 0;
    });
    _buttonHoldProgressTimer = Timer.periodic(
      const Duration(milliseconds: 50),
      (_) {
        final startedAt = _buttonHoldStartedAt;
        if (!mounted || startedAt == null || !_buttonHeld) return;
        final progress =
            DateTime.now().difference(startedAt).inMilliseconds /
            _buttonHoldDuration.inMilliseconds;
        setState(() {
          _buttonHoldProgress = progress.clamp(0.0, 1.0);
          if (DateTime.now().difference(startedAt) >= _buttonHoldDuration) {
            _status = 'release now';
          }
        });
      },
    );
    _buttonHoldTimer = Timer(_buttonHoldMaxDuration, () {
      if (!mounted || !_buttonHeld || _phase != _holdButtonPhase) return;
      _buttonHeld = false;
      _buttonHoldStartedAt = null;
      _loseLife('held too long. be precise.');
    });
  }

  void _onHoldButtonUp(PointerEvent event) {
    if (_phase != _holdButtonPhase || !_buttonHeld) return;
    final startedAt = _buttonHoldStartedAt;
    final elapsed = startedAt == null
        ? Duration.zero
        : DateTime.now().difference(startedAt);
    _buttonHoldTimer?.cancel();
    _buttonHoldTimer = null;
    _buttonHoldProgressTimer?.cancel();
    _buttonHoldProgressTimer = null;
    _buttonHeld = false;
    _buttonHoldStartedAt = null;
    if (elapsed < _buttonHoldDuration) {
      _loseLife('released too soon. hold it longer.');
      return;
    }
    if (elapsed > _buttonHoldMaxDuration) {
      _loseLife('held too long. be precise.');
      return;
    }
    _completeCurrentPhase(passed: true);
  }

  void _onDontClickPressed() {
    if (_phase != _dontClickPhase) return;
    _loseLife("you clicked it. don't.");
  }

  void _onSyncTapDown(int buttonId, int pointerId) {
    if (_phase != _syncDoubleTapPhase) return;
    final now = DateTime.now();
    final wasEmpty = _syncTapPressedButtons.isEmpty;
    if (_syncTapPressedButtons.isEmpty) {
      _syncTapFirstDownAt = now;
      _syncTapChordCompleted = false;
      _syncTapWindowTimer?.cancel();
      _syncTapWindowTimer = Timer(_syncWindow, () {
        if (!mounted || _phase != _syncDoubleTapPhase) return;
        if (_syncTapPressedButtons.length < 2 && !_syncTapChordCompleted) {
          _loseLife('switches desynced. tap both together.');
        }
      });
    } else if (!_syncTapPressedButtons.contains(buttonId) &&
        _syncTapFirstDownAt != null &&
        now.difference(_syncTapFirstDownAt!) > _syncWindow) {
      _loseLife('buttons desynced. tap them together.');
      return;
    }

    final alreadyBothPressed = _syncTapPressedButtons.length == 2;
    setState(() {
      _syncTapPointerToButton[pointerId] = buttonId;
      _syncTapPressedButtons.add(buttonId);
      _status = 'double tap both switches together';
    });

    final nowBothPressed = _syncTapPressedButtons.length == 2;
    if (!alreadyBothPressed && nowBothPressed) {
      _syncTapWindowTimer?.cancel();
      _syncTapWindowTimer = null;
      _syncTapChordCompleted = true;
      _syncTapCyclesCompleted++;
      if (_syncTapCyclesCompleted >= 2) {
        _completeCurrentPhase(passed: true);
        return;
      }
      _syncTapTimer?.cancel();
      _syncTapTimer = Timer(_tapWindow, () {
        if (!mounted || _phase != _syncDoubleTapPhase) return;
        _loseLife('second tap was too slow.');
      });
      return;
    }

    if (wasEmpty) {
      setState(() {
        _status = 'tap the other switch too';
      });
    }
  }

  void _onSyncTapUp(int pointerId) {
    if (_phase != _syncDoubleTapPhase) return;
    final buttonId = _syncTapPointerToButton.remove(pointerId);
    if (buttonId == null) return;
    final hadChordCompleted = _syncTapChordCompleted;
    if (!_syncTapPointerToButton.containsValue(buttonId)) {
      _syncTapPressedButtons.remove(buttonId);
    }
    if (_syncTapPressedButtons.isEmpty) {
      _syncTapWindowTimer?.cancel();
      _syncTapWindowTimer = null;
      _syncTapFirstDownAt = null;
      if (!hadChordCompleted) {
        _loseLife('switches released too soon. tap both together.');
        return;
      }
      _syncTapChordCompleted = false;
    }
  }

  Widget _stagePanel({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _cyanNeon.withValues(alpha: 0.22),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildStageScaffold({
    required int stageIndex,
    required String title,
    required Widget body,
    Color accentColor = _cyanNeon,
    bool uppercaseStatus = true,
  }) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _GridPainter(animation: _spin)),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(painter: _ScanlinePainter()),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                LevelHud(
                  stageText: '$stageIndex/$_totalStages',
                  lives: LevelHud.emojiLives(_lives, _livesPerStage),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [accentColor, _magentaNeon],
                          ).createShader(bounds),
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          uppercaseStatus ? _status.toUpperCase() : _status,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: accentColor.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Expanded(child: body),
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
  }

  Widget _buildTapPrelude({
    required int stageIndex,
    required String title,
    required int tapsRequired,
  }) {
    return _buildStageScaffold(
      stageIndex: stageIndex,
      title: title,
      body: Center(
        child: GestureDetector(
          onTap: () => _onTapStagePressed(tapsRequired),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _magentaNeon.withValues(alpha: 0.12),
              border: Border.all(color: _cyanNeon, width: 3),
              boxShadow: [
                BoxShadow(
                  color: _cyanNeon.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.power_settings_new_rounded,
                  size: 68,
                  color: _cyanNeon,
                ),
                const SizedBox(height: 16),
                Text(
                  '$_tapCount / $tapsRequired',
                  style: TextStyle(
                    color: _cyanNeon,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHoldButtonStage() {
    return _buildStageScaffold(
      stageIndex: 3,
      title: 'STEADY HAND',
      body: Center(
        child: Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: _onHoldButtonDown,
          onPointerUp: _onHoldButtonUp,
          onPointerCancel: _onHoldButtonUp,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 250,
            height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _buttonHeld
                  ? _coreGlow.withValues(alpha: 0.18)
                  : _magentaNeon.withValues(alpha: 0.12),
              border: Border.all(
                color: _buttonHeld ? _coreGlow : _cyanNeon,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: (_buttonHeld ? _coreGlow : _cyanNeon).withValues(
                    alpha: 0.28,
                  ),
                  blurRadius: 28,
                  spreadRadius: 6,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'hold',
                  style: TextStyle(
                    color: _cyanNeon,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 140,
                  child: LinearProgressIndicator(
                    value: _buttonHoldProgress,
                    minHeight: 10,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    color: _buttonHoldProgress >= 1 ? _magentaNeon : _coreGlow,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${_buttonHoldDuration.inSeconds}s target',
                  style: TextStyle(
                    color: _magentaNeon.withValues(alpha: 0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDontClickStage() {
    return _buildStageScaffold(
      stageIndex: 4,
      title: 'PATIENCE TEST',
      accentColor: _magentaNeon,
      body: Center(
        child: ElevatedButton(
          onPressed: _onDontClickPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade700,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 26),
            textStyle: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          child: const Text("DON'T CLICK ME"),
        ),
      ),
    );
  }

  Widget _buildSyncDoubleTapStage() {
    Widget syncButton({
      required int buttonId,
      required String label,
      required Color color,
    }) {
      final isActive = _syncTapPressedButtons.contains(buttonId);
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (event) => _onSyncTapDown(buttonId, event.pointer),
            onPointerUp: (event) => _onSyncTapUp(event.pointer),
            onPointerCancel: (event) => _onSyncTapUp(event.pointer),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: isActive
                    ? color.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.04),
                border: Border.all(
                  color: isActive ? color : color.withValues(alpha: 0.45),
                  width: isActive ? 3 : 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.28),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ]
                    : [],
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return _buildStageScaffold(
      stageIndex: 6,
      title: 'TWIN PULSE',
      body: Center(
        child: _stagePanel(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              height: 220,
              child: Row(
                children: [
                  syncButton(buttonId: 0, label: 'L', color: _cyanNeon),
                  syncButton(buttonId: 1, label: 'R', color: _magentaNeon),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_phase == _doubleTapPhase) {
      return _buildTapPrelude(
        stageIndex: 1,
        title: 'DOUBLE TAP',
        tapsRequired: 2,
      );
    }
    if (_phase == _tripleTapPhase) {
      return _buildTapPrelude(
        stageIndex: 2,
        title: 'TRIPLE TAP',
        tapsRequired: 3,
      );
    }
    if (_phase == _holdButtonPhase) {
      return _buildHoldButtonStage();
    }
    if (_phase == _dontClickPhase) {
      return _buildDontClickStage();
    }
    if (_phase == _syncDoubleTapPhase) {
      return _buildSyncDoubleTapStage();
    }
    if (_phase == _tripleLiftPhase) {
      return _buildTripleSwipePhase();
    }
    if (_phase == _dualBindPhase) {
      return _buildDualBindPhase();
    }

    final bool allSynced = _pressedPads.length == 3;

    return _buildStageScaffold(
      stageIndex: 5,
      title: 'SYNC REACTOR',
      accentColor: allSynced ? _coreGlow : _cyanNeon,
      body: Center(
        child: _stagePanel(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: AnimatedBuilder(
              animation: Listenable.merge([_pulse, _spin, _energyFlow]),
              builder: (context, child) {
                return SizedBox(
                  width: 340,
                  height: 340,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ...List.generate(3, (i) {
                        return Transform.rotate(
                          angle:
                              _spin.value * 2 * math.pi * (i.isEven ? 1 : -1),
                          child: CustomPaint(
                            size: Size(280 - i * 30, 280 - i * 30),
                            painter: _RingPainter(
                              color: i == 0
                                  ? _cyanNeon
                                  : i == 1
                                  ? _magentaNeon
                                  : _coreGlow,
                              dashCount: 12 + i * 4,
                              strokeWidth: 2 - i * 0.3,
                              opacity: 0.3 + (_pulse.value * 0.2),
                            ),
                          ),
                        );
                      }),
                      CustomPaint(
                        size: const Size(340, 340),
                        painter: _EnergyLinesPainter(
                          activePads: _pressedPads,
                          flowProgress: _energyFlow.value,
                          pulseValue: _pulse.value,
                        ),
                      ),
                      _buildCore(allSynced),
                      Positioned(
                        top: 20,
                        child: _SyncPad(
                          label: 'A',
                          sublabel: 'ALPHA',
                          isActive: _pressedPads.contains(0),
                          color: _cyanNeon,
                          onPointerDown: (p) => _onPadDown(0, p),
                          onPointerUp: _onPadUp,
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 40,
                        child: _SyncPad(
                          label: 'B',
                          sublabel: 'BETA',
                          isActive: _pressedPads.contains(1),
                          color: _magentaNeon,
                          onPointerDown: (p) => _onPadDown(1, p),
                          onPointerUp: _onPadUp,
                        ),
                      ),
                      Positioned(
                        right: 20,
                        bottom: 40,
                        child: _SyncPad(
                          label: 'G',
                          sublabel: 'GAMMA',
                          isActive: _pressedPads.contains(2),
                          color: _coreGlow,
                          onPointerDown: (p) => _onPadDown(2, p),
                          onPointerUp: _onPadUp,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripleSwipePhase() {
    return _buildStageScaffold(
      stageIndex: 7,
      title: 'TRIPLE LIFT',
      body: _stagePanel(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(3, (i) {
              const labels = ['I', 'II', 'III'];
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (e) => _onLanePointerDown(i, e.pointer),
                    onPointerMove: (e) =>
                        _onLanePointerMove(i, e.pointer, e.delta),
                    onPointerUp: (e) => _onLanePointerUp(e.pointer),
                    onPointerCancel: (e) => _onLanePointerUp(e.pointer),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _laneUpAccum[i] >= _laneUpNeeded
                              ? _coreGlow
                              : _cyanNeon.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_upward_rounded,
                            size: 42,
                            color: _magentaNeon.withValues(alpha: 0.9),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            labels[i],
                            style: TextStyle(
                              color: _cyanNeon.withValues(alpha: 0.8),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildDualBindPhase() {
    return _buildStageScaffold(
      stageIndex: 8,
      title: 'DUAL BIND',
      accentColor: _magentaNeon,
      uppercaseStatus: false,
      body: _stagePanel(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 2,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerDown: _onDualAnchorDown,
                  onPointerUp: _onDualAnchorUp,
                  onPointerCancel: _onDualAnchorUp,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _anchorHeld
                            ? _coreGlow
                            : _magentaNeon.withValues(alpha: 0.5),
                        width: _anchorHeld ? 3 : 2,
                      ),
                      color: _anchorHeld
                          ? _magentaNeon.withValues(alpha: 0.12)
                          : Colors.white.withValues(alpha: 0.04),
                      boxShadow: _anchorHeld
                          ? [
                              BoxShadow(
                                color: _magentaNeon.withValues(alpha: 0.35),
                                blurRadius: 24,
                              ),
                            ]
                          : [],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          size: 48,
                          color: _anchorHeld
                              ? _coreGlow
                              : _magentaNeon.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'anchor',
                          style: TextStyle(
                            color: _cyanNeon.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'hold',
                          style: TextStyle(
                            color: _cyanNeon.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 3,
                child: Listener(
                  behavior: HitTestBehavior.opaque,
                  onPointerMove: _onDualSwipeMove,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _dualSwipeAccum >= _dualSwipeNeeded
                            ? _coreGlow
                            : _cyanNeon.withValues(alpha: 0.5),
                        width: 2,
                      ),
                      color: Colors.white.withValues(alpha: 0.04),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 44,
                          color: _cyanNeon.withValues(alpha: 0.9),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'conduit',
                          style: TextStyle(
                            color: _cyanNeon.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'swipe right (other finger)',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _cyanNeon.withValues(alpha: 0.45),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCore(bool allSynced) {
    final double pulseScale = 1.0 + (_pulse.value * 0.15);
    final Color coreColor = allSynced ? _coreGlow : _cyanNeon;

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (_) => _onCorePointerDown(),
      child: SizedBox(
        width: 140,
        height: 140,
        child: Center(
          child: Transform.scale(
            scale: pulseScale,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    coreColor.withValues(alpha: allSynced ? 0.9 : 0.5),
                    coreColor.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: coreColor.withValues(alpha: allSynced ? 0.8 : 0.4),
                    blurRadius: allSynced ? 40 : 20,
                    spreadRadius: allSynced ? 8 : 2,
                  ),
                ],
              ),
              child: Center(
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: coreColor,
                    boxShadow: [BoxShadow(color: coreColor, blurRadius: 10)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Grid background painter
class _GridPainter extends CustomPainter {
  final Animation<double> animation;

  _GridPainter({required this.animation}) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF00F5FF).withValues(alpha: 0.05)
      ..strokeWidth = 0.5;

    const spacing = 40.0;
    final offset = (animation.value * spacing) % spacing;

    // Vertical lines
    for (double x = offset; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    // Horizontal lines
    for (double y = offset; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPainter oldDelegate) => true;
}

// Scanline effect
class _ScanlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.black.withValues(alpha: 0.1);

    for (double y = 0; y < size.height; y += 3) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 1), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Spinning ring painter
class _RingPainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;
  final double opacity;

  _RingPainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final dashAngle = (2 * math.pi) / dashCount;
    final gapAngle = dashAngle * 0.3;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * dashAngle;
      final sweepAngle = dashAngle - gapAngle;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      opacity != oldDelegate.opacity;
}

// Energy lines connecting pads to center
class _EnergyLinesPainter extends CustomPainter {
  final Set<int> activePads;
  final double flowProgress;
  final double pulseValue;

  static const Color _cyanNeon = Color(0xFF00F5FF);
  static const Color _magentaNeon = Color(0xFFFF00FF);
  static const Color _coreGlow = Color(0xFF00FFAA);

  _EnergyLinesPainter({
    required this.activePads,
    required this.flowProgress,
    required this.pulseValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Pad positions (approximate)
    final padPositions = [
      Offset(size.width / 2, 65), // Alpha (top)
      Offset(65, size.height - 85), // Beta (bottom left)
      Offset(size.width - 65, size.height - 85), // Gamma (bottom right)
    ];

    final colors = [_cyanNeon, _magentaNeon, _coreGlow];

    for (int i = 0; i < 3; i++) {
      final isActive = activePads.contains(i);
      final color = colors[i];
      final alpha = isActive ? 0.8 : 0.15;

      // Draw line from pad to center
      final paint = Paint()
        ..shader = LinearGradient(
          colors: [
            color.withValues(alpha: alpha),
            color.withValues(alpha: alpha * 0.3),
          ],
        ).createShader(Rect.fromPoints(padPositions[i], center))
        ..strokeWidth = isActive ? 3 : 1
        ..style = PaintingStyle.stroke;

      canvas.drawLine(padPositions[i], center, paint);

      // Draw flowing energy particles when active
      if (isActive) {
        final particlePaint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

        for (int p = 0; p < 3; p++) {
          final t = (flowProgress + p * 0.33) % 1.0;
          final pos = Offset.lerp(padPositions[i], center, t)!;
          canvas.drawCircle(pos, 3 - p * 0.5, particlePaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _EnergyLinesPainter oldDelegate) => true;
}

class _SyncPad extends StatelessWidget {
  final String label;
  final String sublabel;
  final bool isActive;
  final Color color;
  final ValueChanged<int> onPointerDown;
  final ValueChanged<int> onPointerUp;

  const _SyncPad({
    required this.label,
    required this.sublabel,
    required this.isActive,
    required this.color,
    required this.onPointerDown,
    required this.onPointerUp,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: (event) => onPointerDown(event.pointer),
      onPointerUp: (event) => onPointerUp(event.pointer),
      onPointerCancel: (event) => onPointerUp(event.pointer),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF0D1B2A),
          border: Border.all(
            width: isActive ? 3 : 2,
            color: isActive ? color : color.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: isActive
                  ? color.withValues(alpha: 0.6)
                  : color.withValues(alpha: 0.1),
              blurRadius: isActive ? 30 : 10,
              spreadRadius: isActive ? 4 : 0,
            ),
            if (isActive)
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 50,
                spreadRadius: 10,
              ),
          ],
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? color : color.withValues(alpha: 0.6),
                fontWeight: FontWeight.w900,
                fontSize: 28,
                shadows: isActive ? [Shadow(color: color, blurRadius: 15)] : [],
              ),
            ),
            Text(
              sublabel,
              style: TextStyle(
                color: isActive
                    ? color.withValues(alpha: 0.9)
                    : color.withValues(alpha: 0.4),
                fontWeight: FontWeight.w600,
                fontSize: 8,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
