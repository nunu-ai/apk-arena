import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

enum ScreenDesign { dashboard, musicPlayer, legacy, mission }

enum ModificationType {
  none,
  // dashboard
  gradient,
  buttonShape,
  bellBorder,
  // music player (very hard, subtle)
  musicTimeOff,
  musicArtistTypo,
  musicProgressOff,
  musicShuffleTint,
  // legacy enterprise system (very convoluted, messy)
  legacyCustId,
  legacyExtraTab,
  legacyIcon,
  legacyServer,
  legacyVersion,
  // mission control (animated)
  missionNameTypo,
  missionLedColor,
  missionAltitude,
  missionThrusterDirection,
  missionLifeBlinkRate,
}

class _StageConfig {
  final ScreenDesign design;
  final ModificationType modification;
  final bool orangeBell; // dashboard-only flag

  const _StageConfig({
    required this.design,
    required this.modification,
    this.orangeBell = false,
  });

  bool get isDifferent => modification != ModificationType.none;
}

class LevelSpotDifference extends LevelWidget {
  const LevelSpotDifference({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelSpotDifference> createState() => _LevelSpotDifferenceState();
}

class _LevelSpotDifferenceState extends State<LevelSpotDifference> {
  // ── Super-stages ──
  // 1: 5 binary rounds on the dashboard
  // 2: 5 binary rounds on the music player
  // 3: find 4 differences on the legacy system (misclicks penalised)
  // 4: find 4 differences on the animated mission control (misclicks penalised)
  // Each super-stage contributes 25% to the final score.

  static const List<_StageConfig> _binaryStages = [
    // ── super-stage 1: dashboard ──
    _StageConfig(
      design: ScreenDesign.dashboard,
      modification: ModificationType.none,
    ),
    _StageConfig(
      design: ScreenDesign.dashboard,
      modification: ModificationType.gradient,
    ),
    _StageConfig(
      design: ScreenDesign.dashboard,
      modification: ModificationType.buttonShape,
    ),
    _StageConfig(
      design: ScreenDesign.dashboard,
      modification: ModificationType.none,
      orangeBell: true,
    ),
    _StageConfig(
      design: ScreenDesign.dashboard,
      modification: ModificationType.bellBorder,
      orangeBell: true,
    ),
    // ── super-stage 2: music player ──
    _StageConfig(
      design: ScreenDesign.musicPlayer,
      modification: ModificationType.musicTimeOff,
    ),
    _StageConfig(
      design: ScreenDesign.musicPlayer,
      modification: ModificationType.none,
    ),
    _StageConfig(
      design: ScreenDesign.musicPlayer,
      modification: ModificationType.musicArtistTypo,
    ),
    _StageConfig(
      design: ScreenDesign.musicPlayer,
      modification: ModificationType.musicProgressOff,
    ),
    _StageConfig(
      design: ScreenDesign.musicPlayer,
      modification: ModificationType.musicShuffleTint,
    ),
  ];

  static const int _binaryRoundsPerStage = 5;
  static const Set<ModificationType> _legacyDiffs = {
    ModificationType.legacyCustId,
    ModificationType.legacyExtraTab,
    ModificationType.legacyIcon,
    ModificationType.legacyServer,
    ModificationType.legacyVersion,
  };
  static const Set<ModificationType> _missionDiffs = {
    ModificationType.missionNameTypo,
    ModificationType.missionLedColor,
    ModificationType.missionAltitude,
    ModificationType.missionThrusterDirection,
    ModificationType.missionLifeBlinkRate,
  };
  static const int _superStageCount = 4;

  int _superStage = 0; // 0..3
  int _binaryIndex = 0; // 0..9 across binary stages (super 1+2)
  int _binaryS1Correct = 0;
  int _binaryS2Correct = 0;
  final Set<ModificationType> _legacyFound = {};
  int _legacyMisclicks = 0;
  final Set<ModificationType> _missionFound = {};
  int _missionMisclicks = 0;
  bool _isCompleted = false;

  _StageConfig get _binaryStage => _binaryStages[_binaryIndex];
  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: () {
            final s1 = _binaryRoundsPerStage == 0 ? 0.0 : _binaryS1Correct / _binaryRoundsPerStage;
            final s2 = _binaryRoundsPerStage == 0 ? 0.0 : _binaryS2Correct / _binaryRoundsPerStage;
            final s3 = _legacyDiffs.isEmpty ? 0.0 : _legacyFound.length / _legacyDiffs.length;
            final s4 = _missionDiffs.isEmpty ? 0.0 : _missionFound.length / _missionDiffs.length;
            return ((s1 + s2 + s3 + s4) / _superStageCount).clamp(0.0, 1.0);
          }(),
          metrics: {'super_stage_reached': _superStage + 1},
        ));
  }

  bool get _isBinarySuperStage => _superStage == 0 || _superStage == 1;
  bool get _isLegacySuperStage => _superStage == 2;
  bool get _isMissionSuperStage => _superStage == 3;

  ScreenDesign get _currentDesign {
    switch (_superStage) {
      case 0:
      case 1:
        return _binaryStage.design;
      case 2:
        return ScreenDesign.legacy;
      default:
        return ScreenDesign.mission;
    }
  }

  // ── binary handlers ──
  void _onBinaryAnswer(bool saidDifferent) {
    if (_isCompleted || !_isBinarySuperStage) return;
    final correct = saidDifferent == _binaryStage.isDifferent;
    setState(() {
      if (correct) {
        if (_superStage == 0) {
          _binaryS1Correct++;
        } else {
          _binaryS2Correct++;
        }
      }
      _binaryIndex++;
      if (_binaryIndex == _binaryRoundsPerStage) {
        _superStage = 1;
      } else if (_binaryIndex == _binaryStages.length) {
        _superStage = 2;
      }
    });
  }

  // ── find-all handlers (super-stages 3 & 4) ──
  void _onDifferenceTapped(ModificationType diff) {
    if (_isCompleted) return;
    if (_isLegacySuperStage) {
      if (_legacyFound.contains(diff)) return;
      setState(() => _legacyFound.add(diff));
      if (_legacyFound.length == _legacyDiffs.length) {
        Future.delayed(const Duration(milliseconds: 600), _advanceFromLegacy);
      }
    } else if (_isMissionSuperStage) {
      if (_missionFound.contains(diff)) return;
      setState(() => _missionFound.add(diff));
      if (_missionFound.length == _missionDiffs.length) {
        Future.delayed(const Duration(milliseconds: 600), _finishLevel);
      }
    }
  }

  void _onMisclick() {
    if (_isCompleted) return;
    if (_isLegacySuperStage) {
      setState(() => _legacyMisclicks++);
    } else if (_isMissionSuperStage) {
      setState(() => _missionMisclicks++);
    }
  }

  void _onFindAllDone() {
    if (_isCompleted) return;
    if (_isLegacySuperStage) {
      _advanceFromLegacy();
    } else if (_isMissionSuperStage) {
      _finishLevel();
    }
  }

  void _advanceFromLegacy() {
    if (_isCompleted || !_isLegacySuperStage) return;
    setState(() {
      _superStage = 3;
    });
  }

  void _finishLevel() {
    if (_isCompleted) return;
    setState(() {
      _isCompleted = true;
    });
    final s1 = _binaryS1Correct / _binaryRoundsPerStage;
    final s2 = _binaryS2Correct / _binaryRoundsPerStage;
    // For find-all stages: misclicks subtract a found, BUT each found diff
    // guarantees at least 1% of the total score (= 4% of the stage's score,
    // since each stage contributes 25% to the total).
    final s3Net = (_legacyFound.length - _legacyMisclicks).clamp(
      0,
      _legacyDiffs.length,
    );
    final s3FromNet = s3Net / _legacyDiffs.length;
    final s3Floor = (0.04 * _legacyFound.length).clamp(0.0, 1.0);
    final s3 = math.max(s3FromNet, s3Floor);
    final s4Net = (_missionFound.length - _missionMisclicks).clamp(
      0,
      _missionDiffs.length,
    );
    final s4FromNet = s4Net / _missionDiffs.length;
    final s4Floor = (0.04 * _missionFound.length).clamp(0.0, 1.0);
    final s4 = math.max(s4FromNet, s4Floor);
    final score = (s1 + s2 + s3 + s4) / _superStageCount;
    widget.onComplete(
      LevelOutcome(
        score: score,
        metrics: {
          'stage_1_pct': (s1 * 100).round(),
          'stage_2_pct': (s2 * 100).round(),
          'stage_3_pct': (s3 * 100).round(),
          'stage_4_pct': (s4 * 100).round(),
        },
        visibleMetricKeys: const [
          'stage_1_pct',
          'stage_2_pct',
          'stage_3_pct',
          'stage_4_pct',
        ],
      ),
    );
  }

  Widget _renderScreen({required bool isReference}) {
    switch (_currentDesign) {
      case ScreenDesign.dashboard:
        final mod = isReference
            ? ModificationType.none
            : _binaryStage.modification;
        return _DashboardScreen(
          modification: mod,
          orangeBell: _binaryStage.orangeBell,
        );
      case ScreenDesign.musicPlayer:
        final mod = isReference
            ? ModificationType.none
            : _binaryStage.modification;
        return _MusicPlayerScreen(modification: mod);
      case ScreenDesign.legacy:
        return _wrapWithMisclickCatcher(
          isReference: isReference,
          child: _LegacyScreen(
            isProduction: !isReference,
            foundDiffs: _legacyFound,
            onDifferenceTapped: (isReference || _isCompleted)
                ? null
                : _onDifferenceTapped,
          ),
        );
      case ScreenDesign.mission:
        return _wrapWithMisclickCatcher(
          isReference: isReference,
          child: _MissionControlScreen(
            isProduction: !isReference,
            foundDiffs: _missionFound,
            onDifferenceTapped: (isReference || _isCompleted)
                ? null
                : _onDifferenceTapped,
          ),
        );
    }
  }

  Widget _wrapWithMisclickCatcher({
    required bool isReference,
    required Widget child,
  }) {
    if (isReference || _isCompleted) return child;
    return GestureDetector(
      onTap: _onMisclick,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          LevelHud(
            stageText: _isBinarySuperStage
                ? '${_superStage + 1}/$_superStageCount  ·  r${(_binaryIndex % _binaryRoundsPerStage) + 1}/$_binaryRoundsPerStage'
                : '${_superStage + 1}/$_superStageCount',
            trailing: Text(
              _isLegacySuperStage
                  ? 'found ${_legacyFound.length}/${_legacyDiffs.length}'
                  : _isMissionSuperStage
                  ? 'found ${_missionFound.length}/${_missionDiffs.length}'
                  : '',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      "Reference Design",
                      style: TextStyle(
                        color: NunuColors.secondaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _renderScreen(isReference: true),
                    const SizedBox(height: 12),
                    Text(
                      _isLegacySuperStage
                          ? "Production Build — tap each of the ${_legacyDiffs.length} differences"
                          : _isMissionSuperStage
                          ? "Production Build — tap each of the ${_missionDiffs.length} differences"
                          : "Production Build",
                      style: const TextStyle(
                        color: NunuColors.primaryMain,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _renderScreen(isReference: false),
                  ],
                ),
              ),
            ),
          ),
          if (!_isCompleted) _buildBottomBar(),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
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
      child: _isBinarySuperStage ? _binaryControls() : _findAllControls(),
    );
  }

  Widget _missesIndicator(int misses) {
    final isHot = misses > 0;
    final color = isHot ? NunuColors.errorMain : Colors.white24;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: isHot
            ? NunuColors.errorMain.withOpacity(0.15)
            : Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$misses",
            style: TextStyle(
              color: isHot ? NunuColors.errorMain : Colors.white54,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "MISSES",
            style: TextStyle(
              color: isHot ? NunuColors.errorMain : Colors.white38,
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _binaryControls() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NunuColors.successMain,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _onBinaryAnswer(false),
            child: const Text(
              "SAME",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NunuColors.errorMain,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => _onBinaryAnswer(true),
            child: const Text(
              "DIFFERENT",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _findAllControls() {
    final misses = _isLegacySuperStage ? _legacyMisclicks : _missionMisclicks;
    return Row(
      children: [
        _missesIndicator(misses),
        const SizedBox(width: 8),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: NunuColors.primaryMain,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: _onFindAllDone,
            child: const Text(
              "DONE",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Design 1: Dashboard
// ──────────────────────────────────────────────────────────────────────────────

class _DashboardScreen extends StatelessWidget {
  final ModificationType modification;
  final bool orangeBell;

  const _DashboardScreen({required this.modification, this.orangeBell = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
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
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.notifications,
                  color: orangeBell ? Colors.orange : Colors.white70,
                  size: 20,
                  shadows: modification == ModificationType.bellBorder
                      ? [
                          const Shadow(
                            color: Colors.red,
                            offset: Offset(-1, -1),
                          ),
                          const Shadow(
                            color: Colors.red,
                            offset: Offset(1, -1),
                          ),
                          const Shadow(color: Colors.red, offset: Offset(1, 1)),
                          const Shadow(
                            color: Colors.red,
                            offset: Offset(-1, 1),
                          ),
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
                            ? [Colors.orange, Colors.purple, Colors.blue]
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
                          child: Icon(
                            Icons.circle,
                            size: 50,
                            color: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        Positioned(
                          left: 20,
                          bottom: 10,
                          child: Icon(
                            Icons.star,
                            size: 30,
                            color: Colors.yellow.withOpacity(0.8),
                          ),
                        ),
                        const Center(
                          child: Icon(
                            Icons.rocket_launch,
                            size: 40,
                            color: Colors.white,
                          ),
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
                        isTarget: true,
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
    final bool showModifiedShape =
        isTarget && modification == ModificationType.buttonShape;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: ShapeDecoration(
        color: color,
        shape: showModifiedShape
            ? BeveledRectangleBorder(borderRadius: BorderRadius.circular(10))
            : RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Design 2: Music Player (very hard subtle differences)
// ──────────────────────────────────────────────────────────────────────────────

class _MusicPlayerScreen extends StatelessWidget {
  final ModificationType modification;

  const _MusicPlayerScreen({required this.modification});

  @override
  Widget build(BuildContext context) {
    final isTimeMod = modification == ModificationType.musicTimeOff;
    final isTypoMod = modification == ModificationType.musicArtistTypo;
    final isProgressMod = modification == ModificationType.musicProgressOff;
    final isShuffleMod = modification == ModificationType.musicShuffleTint;

    return Container(
      height: 250,
      decoration: BoxDecoration(
        color: const Color(0xFF12121C),
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
          // Top bar
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFF1B1B2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: const Row(
              children: [
                Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white70,
                  size: 20,
                ),
                SizedBox(width: 12),
                Text(
                  "now playing",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                    letterSpacing: 1.5,
                  ),
                ),
                Spacer(),
                Icon(Icons.more_vert, color: Colors.white70, size: 20),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Album row: art + title + artist + heart
                  Row(
                    children: [
                      // Album art
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFE55CD8),
                              Color(0xFF805CE5),
                              Color(0xFF22B8FF),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.music_note,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "neon highway",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isTypoMod
                                  ? "synthwave collevtive"
                                  : "synthwave collective",
                              style: const TextStyle(
                                color: Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.favorite,
                        color: Color(0xFFE55CD8),
                        size: 20,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Stack(
                      children: [
                        Container(height: 4, color: Colors.white12),
                        FractionallySizedBox(
                          widthFactor: isProgressMod ? 0.52 : 0.45,
                          child: Container(
                            height: 4,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFFE55CD8), Color(0xFF805CE5)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Time row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isTimeMod ? "1:43" : "1:42",
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      const Text(
                        "3:48",
                        style: TextStyle(color: Colors.white60, fontSize: 11),
                      ),
                    ],
                  ),

                  const Spacer(),

                  // Controls row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.shuffle,
                        // shade shift on the shuffle icon
                        color: isShuffleMod
                            ? Colors.white.withOpacity(0.3)
                            : Colors.white.withOpacity(0.7),
                        size: 18,
                      ),
                      const Icon(
                        Icons.skip_previous,
                        color: Colors.white,
                        size: 26,
                      ),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFFE55CD8), Color(0xFF805CE5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Icon(
                          Icons.pause,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const Icon(
                        Icons.skip_next,
                        color: Colors.white,
                        size: 26,
                      ),
                      const Icon(Icons.repeat, color: Colors.white70, size: 18),
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
}

// ──────────────────────────────────────────────────────────────────────────────
// Design 3: Legacy Enterprise System (Win9x style, messy, lots to scan)
// ──────────────────────────────────────────────────────────────────────────────

class _LegacyScreen extends StatelessWidget {
  final bool isProduction;
  final Set<ModificationType> foundDiffs;
  final void Function(ModificationType)? onDifferenceTapped;

  const _LegacyScreen({
    required this.isProduction,
    this.foundDiffs = const {},
    this.onDifferenceTapped,
  });

  static const _bg = Color(0xFFC0C0C0);
  static const _shadow = Color(0xFF404040);
  static const _darkGray = Color(0xFF808080);

  Widget _wrap(Widget child, ModificationType diff) {
    if (!isProduction) return child;
    final isFound = foundDiffs.contains(diff);
    return GestureDetector(
      onTap: onDifferenceTapped == null
          ? null
          : () => onDifferenceTapped!(diff),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (isFound)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x5500FF00),
                    border: Border.all(
                      color: const Color(0xFF00AA00),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProd = isProduction;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: _bg,
        border: const Border(
          top: BorderSide(color: Colors.white, width: 1),
          left: BorderSide(color: Colors.white, width: 1),
          bottom: BorderSide(color: _shadow, width: 1),
          right: BorderSide(color: _shadow, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Title bar ──
          Container(
            height: 22,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000080), Color(0xFF1084D0)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  color: const Color(0xFFFFEE00),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.star,
                    size: 9,
                    color: Color(0xFFCC0000),
                  ),
                ),
                const SizedBox(width: 4),
                // Only the version chunk is tappable.
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    children: [
                      const TextSpan(text: "AcmeCorp\u2122 Customer Mgr "),
                      WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: _wrap(
                          Text(
                            isProd ? "v3.27" : "v3.21",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          ModificationType.legacyVersion,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                _windowBtn("_"),
                const SizedBox(width: 1),
                _windowBtn("\u25A1"),
                const SizedBox(width: 1),
                _windowBtn("\u00D7"),
              ],
            ),
          ),

          // ── Menu bar ──
          Container(
            height: 18,
            color: _bg,
            padding: const EdgeInsets.only(left: 4),
            child: const Row(
              children: [
                _MenuItem(label: "File"),
                _MenuItem(label: "Edit"),
                _MenuItem(label: "View"),
                _MenuItem(label: "Tools"),
                _MenuItem(label: "Reports"),
                _MenuItem(label: "Window"),
                _MenuItem(label: "Help"),
              ],
            ),
          ),

          // ── Toolbar ──
          // Production swaps the "save" icon for "cloud_upload" — a subtle,
          // easy-to-miss diff among 14 toolbar buttons.
          Container(
            height: 22,
            color: _bg,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Row(
              children: [
                _toolBtn(Icons.folder_open),
                _wrap(
                  _toolBtn(isProd ? Icons.cloud_upload : Icons.save),
                  ModificationType.legacyIcon,
                ),
                _toolBtn(Icons.print),
                const _ToolSep(),
                _toolBtn(Icons.add_box_outlined),
                _toolBtn(Icons.edit),
                _toolBtn(Icons.delete_outline),
                _toolBtn(Icons.refresh),
                const _ToolSep(),
                _toolBtn(Icons.search),
                _toolBtn(Icons.filter_alt_outlined),
                _toolBtn(Icons.import_export),
                const _ToolSep(),
                _toolBtn(Icons.play_arrow),
                _toolBtn(Icons.stop),
                const Spacer(),
                _toolBtn(Icons.help_outline),
              ],
            ),
          ),

          // ── Tab strip ──
          // Production has an extra "Reports" tab.
          Container(
            color: _bg,
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 0),
            child: Row(
              children: [
                const _LegacyTab(label: "Customers", active: true),
                const _LegacyTab(label: "Orders", active: false),
                const _LegacyTab(label: "Invoices", active: false),
                const _LegacyTab(label: "Audit", active: false),
                if (isProd)
                  _wrap(
                    const _LegacyTab(label: "Reports", active: false),
                    ModificationType.legacyExtraTab,
                  ),
              ],
            ),
          ),

          // ── Content panel (sunken inset) ──
          Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(4, 0, 4, 4),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: _shadow, width: 1),
                  left: BorderSide(color: _shadow, width: 1),
                  bottom: BorderSide(color: Colors.white, width: 1),
                  right: BorderSide(color: Colors.white, width: 1),
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CUST-ID + STATUS + VIP
                  Row(
                    children: [
                      const _Label(text: "CUST-ID:"),
                      const SizedBox(width: 4),
                      _wrap(
                        _Field(
                          text: isProd ? "00184279" : "00184729",
                          width: 70,
                        ),
                        ModificationType.legacyCustId,
                      ),
                      const SizedBox(width: 6),
                      const _Label(text: "STATUS:"),
                      const SizedBox(width: 4),
                      const _Field(text: "ACTIVE", width: 60, hasArrow: true),
                      const SizedBox(width: 6),
                      const _Checkbox(checked: true, label: "VIP"),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // NAME + DOB
                  Row(
                    children: const [
                      _Label(text: "NAME:"),
                      SizedBox(width: 4),
                      _Field(text: "JOHN K. DOE", width: 130),
                      SizedBox(width: 6),
                      _Label(text: "DOB:"),
                      SizedBox(width: 4),
                      _Field(text: "1978-04-12", width: 78),
                    ],
                  ),
                  const SizedBox(height: 3),
                  // REF# + TIER + flag (no diffs in this row anymore)
                  Row(
                    children: const [
                      _Label(text: "REF#:"),
                      SizedBox(width: 4),
                      _Mono(text: "4729-A"),
                      SizedBox(width: 10),
                      _Label(text: "TIER:"),
                      SizedBox(width: 4),
                      Text(
                        "GOLD",
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 10,
                          color: Color(0xFFB58900),
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(
                        Icons.warning_amber,
                        size: 12,
                        color: Color(0xFFCC8800),
                      ),
                      SizedBox(width: 2),
                      _Mono(text: "flagged"),
                      Spacer(),
                      _Mono(text: "BAL: \$2,184.50", fontSize: 9),
                    ],
                  ),

                  const SizedBox(height: 4),

                  // ── Recent Activity log table ──
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F0),
                      border: Border.all(color: _darkGray, width: 1),
                    ),
                    padding: const EdgeInsets.fromLTRB(3, 2, 3, 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            _Mono(
                              text: "Recent Activity",
                              bold: true,
                              fontSize: 9,
                            ),
                            Spacer(),
                            _Mono(text: "[F5=refresh]", fontSize: 8),
                          ],
                        ),
                        Container(
                          height: 1,
                          color: _darkGray,
                          margin: const EdgeInsets.symmetric(vertical: 1),
                        ),
                        const _LogRow(
                          date: "2024-11-03",
                          action: "LOGIN  ",
                          status: "OK ",
                          info: Text("192.0.2.14"),
                        ),
                        const _LogRow(
                          date: "2024-11-03",
                          action: "ORDER  ",
                          status: "OK ",
                          info: Text("#00831 SHIPPED"),
                        ),
                        const _LogRow(
                          date: "2024-11-02",
                          action: "PAYMENT",
                          status: "ERR",
                          info: Text("\$128.50"),
                          isError: true,
                        ),
                        const _LogRow(
                          date: "2024-11-01",
                          action: "UPDATE ",
                          status: "OK ",
                          info: Text("addr ln2"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Status bar ──
          Container(
            height: 18,
            decoration: const BoxDecoration(
              color: _bg,
              border: Border(top: BorderSide(color: Colors.white, width: 1)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF008000),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const _Mono(text: "Connected", fontSize: 9),
                const _StatusSep(),
                // Only the host name (PROD-03 / DEV-03) is tappable.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const _Mono(text: "Server: ", fontSize: 9),
                    _wrap(
                      _Mono(text: isProd ? "DEV-03" : "PROD-03", fontSize: 9),
                      ModificationType.legacyServer,
                    ),
                  ],
                ),
                const _StatusSep(),
                const _Mono(text: "DB: ACME01", fontSize: 9),
                const Spacer(),
                const _Mono(text: "USR: ADMIN", fontSize: 9),
                const SizedBox(width: 8),
                const _Mono(text: "14:32:47", fontSize: 9),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _windowBtn(String label) {
    return Container(
      width: 16,
      height: 14,
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(color: Colors.white, width: 1),
          left: BorderSide(color: Colors.white, width: 1),
          bottom: BorderSide(color: _shadow, width: 1),
          right: BorderSide(color: _shadow, width: 1),
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 9,
          color: Colors.black,
          fontWeight: FontWeight.bold,
          height: 1,
        ),
      ),
    );
  }

  Widget _toolBtn(IconData icon) {
    return Container(
      width: 18,
      height: 18,
      margin: const EdgeInsets.symmetric(horizontal: 1),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(
          top: BorderSide(color: Colors.white, width: 1),
          left: BorderSide(color: Colors.white, width: 1),
          bottom: BorderSide(color: _shadow, width: 1),
          right: BorderSide(color: _shadow, width: 1),
        ),
      ),
      child: Icon(icon, size: 11, color: Colors.black87),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final String label;
  const _MenuItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: label[0],
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 11,
                color: Colors.black,
                decoration: TextDecoration.underline,
              ),
            ),
            TextSpan(
              text: label.substring(1),
              style: const TextStyle(
                fontFamily: 'sans-serif',
                fontSize: 11,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolSep extends StatelessWidget {
  const _ToolSep();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 14,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF808080), width: 1),
          right: BorderSide(color: Colors.white, width: 1),
        ),
      ),
    );
  }
}

class _StatusSep extends StatelessWidget {
  const _StatusSep();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: const BoxDecoration(
        border: Border(
          left: BorderSide(color: Color(0xFF808080), width: 1),
          right: BorderSide(color: Colors.white, width: 1),
        ),
      ),
    );
  }
}

class _LegacyTab extends StatelessWidget {
  final String label;
  final bool active;
  const _LegacyTab({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      margin: const EdgeInsets.only(right: 1, top: 2),
      decoration: BoxDecoration(
        color: active ? const Color(0xFFC0C0C0) : const Color(0xFFA0A0A0),
        border: const Border(
          top: BorderSide(color: Colors.white, width: 1),
          left: BorderSide(color: Colors.white, width: 1),
          right: BorderSide(color: Color(0xFF404040), width: 1),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'sans-serif',
          fontSize: 10,
          color: Colors.black,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 10,
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _Mono extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool bold;
  const _Mono({required this.text, this.fontSize = 10, this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        color: Colors.black,
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String text;
  final double width;
  final bool hasArrow;
  const _Field({
    required this.text,
    required this.width,
    this.hasArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 14,
      padding: const EdgeInsets.only(left: 3, right: 1),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Color(0xFF404040), width: 1),
          left: BorderSide(color: Color(0xFF404040), width: 1),
          bottom: BorderSide(color: Colors.white, width: 1),
          right: BorderSide(color: Colors.white, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.black,
                height: 1.2,
              ),
              overflow: TextOverflow.clip,
            ),
          ),
          if (hasArrow)
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(
                color: Color(0xFFC0C0C0),
                border: Border(
                  top: BorderSide(color: Colors.white, width: 1),
                  left: BorderSide(color: Colors.white, width: 1),
                  bottom: BorderSide(color: Color(0xFF404040), width: 1),
                  right: BorderSide(color: Color(0xFF404040), width: 1),
                ),
              ),
              child: const Icon(
                Icons.arrow_drop_down,
                size: 10,
                color: Colors.black,
              ),
            ),
        ],
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  final bool checked;
  final String label;
  const _Checkbox({required this.checked, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 11,
          height: 11,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFF404040), width: 1),
              left: BorderSide(color: Color(0xFF404040), width: 1),
              bottom: BorderSide(color: Colors.white, width: 1),
              right: BorderSide(color: Colors.white, width: 1),
            ),
          ),
          child: checked
              ? const Icon(Icons.check, size: 9, color: Colors.black)
              : null,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10,
            color: Colors.black,
          ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  final String date;
  final String action;
  final String status;
  final Widget info;
  final bool isError;
  const _LogRow({
    required this.date,
    required this.action,
    required this.status,
    required this.info,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isError ? const Color(0xFFCC0000) : Colors.black;
    final statusBg = isError
        ? const Color(0xFFFFE0E0)
        : const Color(0xFFD8FFD8);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            date,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            action,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 9,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            color: statusBg,
            child: Text(
              status,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: DefaultTextStyle.merge(
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 9,
                color: color,
              ),
              overflow: TextOverflow.clip,
              child: info,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Design 4: Mission Control HUD (animated; tap-the-differences)
// ──────────────────────────────────────────────────────────────────────────────

class _MissionControlScreen extends StatefulWidget {
  final bool isProduction;
  final Set<ModificationType> foundDiffs;
  final void Function(ModificationType)? onDifferenceTapped;

  const _MissionControlScreen({
    required this.isProduction,
    this.foundDiffs = const {},
    this.onDifferenceTapped,
  });

  @override
  State<_MissionControlScreen> createState() => _MissionControlScreenState();
}

class _MissionControlScreenState extends State<_MissionControlScreen>
    with TickerProviderStateMixin {
  static const _green = Color(0xFF22FF88);
  static const _greenDim = Color(0xFF0A2520);
  static const _amber = Color(0xFFFFAA00);
  static const _bg = Color(0xFF050810);

  late final AnimationController _spin;
  late final AnimationController _led;
  late final AnimationController _fastLed; // production-only LIFE LED rate
  late final AnimationController _gauge;
  Timer? _countdownTimer;
  int _countdown = 23;

  @override
  void initState() {
    super.initState();
    _spin = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _led = AnimationController(
      duration: const Duration(milliseconds: 1100),
      vsync: this,
    )..repeat(reverse: true);
    _fastLed = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    )..repeat(reverse: true);
    _gauge = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat(reverse: true);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _countdown--;
        if (_countdown < 0) _countdown = 30;
      });
    });
  }

  @override
  void dispose() {
    _spin.dispose();
    _led.dispose();
    _fastLed.dispose();
    _gauge.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  Widget _wrap(Widget child, ModificationType diff) {
    if (!widget.isProduction) return child;
    final isFound = widget.foundDiffs.contains(diff);
    return GestureDetector(
      onTap: widget.onDifferenceTapped == null
          ? null
          : () => widget.onDifferenceTapped!(diff),
      behavior: HitTestBehavior.opaque,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          child,
          if (isFound)
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: const Color(0x5500FF00),
                    border: Border.all(
                      color: const Color(0xFF00CC44),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isProd = widget.isProduction;

    return Container(
      height: 280,
      decoration: BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _green.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: _green.withOpacity(0.25),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
          children: [
            // ── Header ──
            Container(
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF0A1224),
                border: Border(bottom: BorderSide(color: _green, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFCC00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.bolt,
                      size: 11,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    // Only "STARLINE/STARLIME" is tappable — the rest of
                    // "MISSION CONTROL — … 7" is plain text.
                    child: Text.rich(
                      TextSpan(
                        style: const TextStyle(
                          color: _green,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.4,
                          fontFamily: 'monospace',
                        ),
                        children: [
                          const TextSpan(text: "MISSION CONTROL — "),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: _wrap(
                              Text(
                                isProd ? "STARLIME" : "STARLINE",
                                style: const TextStyle(
                                  color: _green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.4,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              ModificationType.missionNameTypo,
                            ),
                          ),
                          const TextSpan(text: " 7"),
                        ],
                      ),
                      overflow: TextOverflow.clip,
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _led,
                    builder: (context, _) {
                      final pulse = 0.5 + _led.value * 0.5;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4444).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(2),
                          border: Border.all(
                            color: const Color(
                              0xFFFF4444,
                            ).withOpacity(0.4 + pulse * 0.6),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          "T-${_countdown.toString().padLeft(2, '0')}",
                          style: const TextStyle(
                            color: Color(0xFFFF6666),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'monospace',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // ── Stats grid ──
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    // ALT block: only the value text is tappable.
                    child: _statBlock(
                      label: "ALT",
                      value: isProd ? "42,810" : "42,180",
                      unit: "ft",
                      diff: ModificationType.missionAltitude,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _statBlock(
                      label: "VEL",
                      value: "17,500",
                      unit: "m/s",
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _statBlock(label: "FUEL", value: "67", unit: "%"),
                  ),
                ],
              ),
            ),

            // ── LED bank ──
            // GUIDANCE: only the dot color differs → only the dot is tappable.
            // LIFE: production blinks at ~4× rate → only the dot is tappable.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _ledIndicator("THRUST", _green, animation: _led),
                  _ledIndicator(
                    "GUIDANCE",
                    isProd ? _amber : _green,
                    animation: _led,
                    diff: ModificationType.missionLedColor,
                    // Both the dot and label colour change → whole unit is the diff.
                    wrapEntireIndicator: true,
                  ),
                  _ledIndicator("COMMS", _green, animation: _led),
                  _ledIndicator(
                    "LIFE",
                    _green,
                    animation: isProd ? _fastLed : _led,
                    diff: isProd ? ModificationType.missionLifeBlinkRate : null,
                  ),
                ],
              ),
            ),

            // ── Thruster + gauges ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _wrap(
                      _thruster(rotateClockwise: !isProd),
                      ModificationType.missionThrusterDirection,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: AnimatedBuilder(
                        animation: _gauge,
                        builder: (context, _) {
                          final t = _gauge.value;
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _gaugeBar(
                                "THRUST",
                                (0.55 + t * 0.4).clamp(0.0, 1.0),
                                _green,
                              ),
                              const SizedBox(height: 3),
                              _gaugeBar(
                                "YAW",
                                (0.30 + t * 0.5).clamp(0.0, 1.0),
                                _amber,
                              ),
                              const SizedBox(height: 3),
                              _gaugeBar(
                                "PITCH",
                                (0.65 - t * 0.4).clamp(0.0, 1.0),
                                const Color(0xFF22B8FF),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Status bar ──
            Container(
              height: 22,
              decoration: const BoxDecoration(
                color: Color(0xFF0A1224),
                border: Border(top: BorderSide(color: _green, width: 1)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  AnimatedBuilder(
                    animation: _led,
                    builder: (context, _) {
                      final pulse = 0.4 + _led.value * 0.6;
                      return Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: _green.withOpacity(pulse),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _green.withOpacity(_led.value * 0.6),
                              blurRadius: 4,
                              spreadRadius: 0.5,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "NOMINAL",
                    style: TextStyle(
                      color: _green,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    "BAT 87% · LINK STRONG",
                    style: TextStyle(
                      color: _green,
                      fontSize: 9,
                      fontFamily: 'monospace',
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBlock({
    required String label,
    required String value,
    required String unit,
    ModificationType? diff,
  }) {
    Widget valueWidget = FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
    if (diff != null) {
      valueWidget = _wrap(valueWidget, diff);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: _greenDim,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: _green.withOpacity(0.4), width: 1),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: _green,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(width: 3),
          Expanded(child: valueWidget),
          if (unit.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 2),
              child: Text(
                unit,
                style: const TextStyle(
                  color: _green,
                  fontSize: 8,
                  fontFamily: 'monospace',
                ),
              ),
            ),
        ],
      ),
    );
  }

  // The dot animates from `animation`. By default, when `diff` is provided
  // only the dot is tappable. Set `wrapEntireIndicator: true` when the label
  // also reflects the difference (e.g. GUIDANCE's color affects both).
  Widget _ledIndicator(
    String label,
    Color color, {
    required Animation<double> animation,
    ModificationType? diff,
    bool wrapEntireIndicator = false,
  }) {
    Widget dot = SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            final t = animation.value;
            return Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color.withOpacity(0.35 + t * 0.65),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(t * 0.7),
                    blurRadius: 5,
                    spreadRadius: 1,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
    if (diff != null && !wrapEntireIndicator) {
      dot = _wrap(dot, diff);
    }
    Widget result = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 2),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 9,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
    if (diff != null && wrapEntireIndicator) {
      result = _wrap(result, diff);
    }
    return result;
  }

  Widget _gaugeBar(String label, double value, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2A),
              border: Border.all(color: color.withOpacity(0.5), width: 1),
              borderRadius: BorderRadius.circular(2),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: value,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(color: color.withOpacity(0.6), blurRadius: 3),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 28,
          child: Text(
            "${(value * 100).toStringAsFixed(0)}%",
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color,
              fontSize: 8,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }

  Widget _thruster({required bool rotateClockwise}) {
    return SizedBox(
      width: 80,
      height: 80,
      child: AnimatedBuilder(
        animation: _spin,
        builder: (context, _) {
          final base = _spin.value * 2 * math.pi;
          final angle = rotateClockwise ? base : -base;
          return Stack(
            alignment: Alignment.center,
            children: [
              // outer ring
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _green.withOpacity(0.6), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: _green.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0.5,
                    ),
                  ],
                ),
              ),
              // tick marks (static)
              for (int i = 0; i < 12; i++)
                Transform.rotate(
                  angle: i * math.pi / 6,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: 1.5,
                      height: 4,
                      margin: const EdgeInsets.only(top: 2),
                      color: _green.withOpacity(0.5),
                    ),
                  ),
                ),
              // rotating fan blades
              Transform.rotate(
                angle: angle,
                child: SizedBox(
                  width: 60,
                  height: 60,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (int i = 0; i < 3; i++)
                        Transform.rotate(
                          angle: i * 2 * math.pi / 3,
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 5,
                              height: 24,
                              margin: const EdgeInsets.only(top: 2),
                              decoration: BoxDecoration(
                                color: _green,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: _green.withOpacity(0.6),
                                    blurRadius: 4,
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
              // center hub
              Container(
                width: 14,
                height: 14,
                decoration: const BoxDecoration(
                  color: _green,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
