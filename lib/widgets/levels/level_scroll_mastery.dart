import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/contact_list_item.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

/// Five scrolling challenges: list, document bottom, speed find, horizontal, 2d grid.
class LevelScrollMastery extends LevelWidget {
  const LevelScrollMastery({super.key, required super.onComplete});

  @override
  State<LevelScrollMastery> createState() => _LevelScrollMasteryState();
}

class _LevelScrollMasteryState extends State<LevelScrollMastery> {
  static const int _levelSeed = 1234;
  static const int _speedRowCount = 220;
  static const List<int> _perfectSwipesByStage = [3, 2, 6, 7, 6];
  int _stage = 0;
  int _wrongTaps = 0;
  final List<int> _stageWrongTaps = List.filled(5, 0);
  final List<int> _stageSwipes = List.filled(5, 0);
  final List<double> _stageScores = [];
  final Stopwatch _sw = Stopwatch();

  // Scroll efficiency tracking (per stage, vertical axis; stage 4 also has H)
  final List<double> _stageTotalScrolled = List.filled(5, 0.0);
  final List<double> _stageRangeMin = List.filled(5, double.infinity);
  final List<double> _stageRangeMax = List.filled(5, double.negativeInfinity);
  final List<double> _stageViewport = List.filled(5, 1.0);
  double _gridHTotalScrolled = 0.0;
  double _gridHRangeMin = double.infinity;
  double _gridHRangeMax = double.negativeInfinity;
  double _gridHViewport = 1.0;

  // Stage 0: contacts
  late List<Map<String, String>> _contacts;
  late int _saulIndex;

  // Stage 1: tos
  final ScrollController _tosCtrl = ScrollController();
  bool _tosBottom = false;
  bool _tosChecked = false;

  // Stage 2: speed list
  late List<int> _speedIndices;
  late int _highlightPosition;
  // Stage 3: horizontal
  late List<String> _carousel;
  late int _carouselTarget;

  // Stage 4: grid
  late int _gridW;
  late int _gridH;
  late int _gx;
  late int _gy;
  final ScrollController _gridHCtrl = ScrollController();
  final ScrollController _gridVCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.registerTimeoutBuilder(_buildOutcome);
    _sw.start();
    _initContacts();
    _initSpeed();
    _initCarousel();
    _initGrid();
    _tosCtrl.addListener(_tosListen);
  }

  Random _rngForStage(int offset) => Random(_levelSeed + offset);

  void _initContacts() {
    final rng = _rngForStage(0);
    const firstNames = [
      'Alex',
      'Casey',
      'Jordan',
      'Sam',
      'Taylor',
      'Uma',
      'Victor',
      'Wesley',
      'Xavier',
      'Yara',
      'Zane',
    ];
    const lastNames = ['Smith', 'Lee', 'Kim', 'Brown', 'Davis'];
    _contacts = [];
    for (var i = 0; i < 80; i++) {
      _contacts.add({
        'name':
            '${firstNames[rng.nextInt(firstNames.length)]} ${lastNames[rng.nextInt(lastNames.length)]} $i',
        'phone': '(555) ${rng.nextInt(900) + 100}-${rng.nextInt(9000) + 1000}',
      });
    }
    _contacts.add({'name': 'Saul Goodman', 'phone': '(505) CALL-SAUL'});
    _contacts.sort((a, b) => a['name']!.compareTo(b['name']!));
    _saulIndex = _contacts.indexWhere((c) => c['name'] == 'Saul Goodman');
  }

  void _initSpeed() {
    final rng = _rngForStage(1);
    _speedIndices = List.generate(_speedRowCount, (i) => i);
    _highlightPosition = 180 + rng.nextInt(24);
  }

  void _initCarousel() {
    final rng = _rngForStage(2);
    _carousel = List.generate(
      52,
      (i) => 'item ${String.fromCharCode(65 + (i % 26))}-$i',
    )..shuffle(rng);
    _carouselTarget = 24 + rng.nextInt(8);
  }

  void _initGrid() {
    _gridW = 14;
    _gridH = 16;
    _gx = 7;
    _gy = 10;
  }

  @override
  void dispose() {
    _tosCtrl.removeListener(_tosListen);
    _tosCtrl.dispose();
    _gridHCtrl.dispose();
    _gridVCtrl.dispose();
    widget.clearTimeoutBuilder();
    super.dispose();
  }

  void _tosListen() {
    if (!_tosCtrl.hasClients) return;
    final max = _tosCtrl.position.maxScrollExtent;
    final cur = _tosCtrl.position.pixels;
    if (max - cur < 12 && !_tosBottom) {
      setState(() => _tosBottom = true);
    }
  }

  void _bumpWrong() {
    _wrongTaps++;
    _stageWrongTaps[_stage]++;
    setState(() {});
  }

  bool _onScrollStart(ScrollStartNotification n, int stage) {
    _stageSwipes[stage]++;
    return false;
  }

  bool _onScrollStartH(ScrollStartNotification n) {
    // grid H swipes counted together with V in stage 4
    _stageSwipes[4]++;
    return false;
  }

  bool _onScrollUpdate(ScrollUpdateNotification n, int stage) {
    final delta = n.scrollDelta ?? 0.0;
    final pos = n.metrics.pixels;
    final viewport = n.metrics.viewportDimension;
    _stageTotalScrolled[stage] += delta.abs();
    _stageViewport[stage] = viewport;
    _stageRangeMin[stage] = min(_stageRangeMin[stage], pos);
    _stageRangeMax[stage] = max(_stageRangeMax[stage], pos);
    setState(() {});
    return false;
  }

  bool _onScrollUpdateH(ScrollUpdateNotification n) {
    final delta = n.scrollDelta ?? 0.0;
    final pos = n.metrics.pixels;
    _gridHTotalScrolled += delta.abs();
    _gridHViewport = n.metrics.viewportDimension;
    _gridHRangeMin = min(_gridHRangeMin, pos);
    _gridHRangeMax = max(_gridHRangeMax, pos);
    setState(() {});
    return false;
  }

  double _scrollEfficiency(
    double totalScrolled,
    double rangeMin,
    double rangeMax,
    double viewport,
  ) {
    if (totalScrolled == 0) return 1.0;
    final range = (rangeMax - rangeMin).clamp(0.0, double.infinity) + viewport;
    return (range / (totalScrolled + viewport)).clamp(0.0, 1.0);
  }

  double _scoreForStage(int stage) {
    double efficiency;
    if (stage == 4) {
      final vEff = _scrollEfficiency(
        _stageTotalScrolled[4],
        _stageRangeMin[4],
        _stageRangeMax[4],
        _stageViewport[4],
      );
      final hEff = _scrollEfficiency(
        _gridHTotalScrolled,
        _gridHRangeMin,
        _gridHRangeMax,
        _gridHViewport,
      );
      efficiency = (vEff + hEff) / 2;
    } else {
      efficiency = _scrollEfficiency(
        _stageTotalScrolled[stage],
        _stageRangeMin[stage],
        _stageRangeMax[stage],
        _stageViewport[stage],
      );
    }
    final perfect = _perfectSwipesByStage[stage];
    final swipes = _stageSwipes[stage];
    final swipeEconomy =
        swipes == 0 ? 1.0 : (perfect / swipes).clamp(0.0, 1.0);
    final scrollScore = efficiency * 0.85 + swipeEconomy * 0.15;
    return (scrollScore - _stageWrongTaps[stage] * 0.1).clamp(0.0, 1.0);
  }

  LevelOutcome _buildOutcome() {
    final score =
        _stageScores.fold<double>(0, (sum, score) => sum + score) / 5;

    return LevelOutcome(
      score: score,
      metrics: {
        'stages_cleared': _stageScores.length,
        'wrong_taps': _wrongTaps,
        'efficiency_pct': (score * 100).round(),
      },
    );
  }

  void _nextStage() {
    if (_stageScores.length <= _stage) {
      _stageScores.add(_scoreForStage(_stage));
    }

    if (_stage >= 4) {
      _sw.stop();
      widget.onComplete(_buildOutcome());
      return;
    }
    setState(() {
      _stage++;
    });
  }

  void _onContactTap(int i) {
    if (i == _saulIndex) {
      _nextStage();
    } else {
      _bumpWrong();
      setState(() {});
    }
  }

  void _stage1Accept() {
    if (_tosBottom && _tosChecked) {
      _nextStage();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case 0:
        return _buildContacts();
      case 1:
        return _buildTos();
      case 2:
        return _buildSpeedList();
      case 3:
        return _buildCarousel();
      case 4:
        return _buildGrid();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContacts() {
    return Column(
      children: [
        _header('find Saul Goodman'),
        Expanded(
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (n) => _onScrollUpdate(n, 0),
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) => _onScrollStart(n, 0),
              child: ListView.builder(
                itemCount: _contacts.length,
                itemBuilder: (context, i) {
                  final c = _contacts[i];
                  final isSaul = i == _saulIndex;
                  return ContactListItem(
                    name: c['name']!,
                    subtitle: c['phone'],
                    avatarText: isSaul ? '👔' : null,
                    avatarColor: isSaul ? Colors.blue.shade700 : null,
                    isSpecial: isSaul,
                    onTap: () => _onContactTap(i),
                    trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTos() {
    return Column(
      children: [
        _header('scroll to the bottom, then check and accept'),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 140,
                  child: Scrollbar(
                    controller: _tosCtrl,
                    thumbVisibility: true,
                    child: NotificationListener<ScrollUpdateNotification>(
                      onNotification: (n) => _onScrollUpdate(n, 1),
                      child: NotificationListener<ScrollStartNotification>(
                      onNotification: (n) => _onScrollStart(n, 1),
                      child: SingleChildScrollView(
                        controller: _tosCtrl,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(
                            36,
                            (i) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                'Section ${i + 1}. Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                                'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                                'Ut enim ad minim veniam, quis nostrud exercitation.',
                                style: TextStyle(
                                  color: Colors.grey.shade900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _tosBottom
                      ? () => setState(() => _tosChecked = !_tosChecked)
                      : null,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _tosChecked
                              ? Colors.blue.shade700
                              : Colors.white,
                          border: Border.all(color: Colors.blue.shade700),
                        ),
                        child: _tosChecked
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'i agree',
                          style: TextStyle(
                            color: _tosBottom ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: (_tosBottom && _tosChecked) ? _stage1Accept : null,
                  child: const Text('accept'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedList() {
    return Column(
      children: [
        _header('scroll down to the row marked TARGET and tap it'),
        Expanded(
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (n) => _onScrollUpdate(n, 2),
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) => _onScrollStart(n, 2),
              child: ListView.builder(
                itemCount: _speedIndices.length,
                itemBuilder: (context, i) {
                  final idx = _speedIndices[i];
                  final isTarget = i == _highlightPosition;
                  return ListTile(
                    tileColor: isTarget
                        ? NunuColors.primaryMain.withValues(alpha: 0.25)
                        : null,
                    title: Text(
                      isTarget ? '★ TARGET ★' : 'row $idx',
                      style: TextStyle(
                        color: isTarget
                            ? NunuColors.primaryLight
                            : Colors.white70,
                        fontWeight: isTarget
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      if (isTarget) {
                        _nextStage();
                      } else {
                        _bumpWrong();
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        _header('scroll horizontally and tap: ${_carousel[_carouselTarget]}'),
        SizedBox(
          height: 120,
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (n) => _onScrollUpdate(n, 3),
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) => _onScrollStart(n, 3),
              child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
              itemCount: _carousel.length,
              itemBuilder: (context, i) {
                final label = _carousel[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Material(
                    color: NunuColors.backgroundPaper,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: () {
                        if (i == _carouselTarget) {
                          _nextStage();
                        } else {
                          _bumpWrong();
                          setState(() {});
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 100,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: NunuColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
              ),
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildGrid() {
    return Column(
      children: [
        _header('scroll both axes; tap the cell that says HERE'),
        Expanded(
          child: NotificationListener<ScrollUpdateNotification>(
            onNotification: (n) {
              if (n.metrics.axis == Axis.vertical) return _onScrollUpdate(n, 4);
              return _onScrollUpdateH(n);
            },
            child: NotificationListener<ScrollStartNotification>(
              onNotification: (n) {
                if (n.metrics.axis == Axis.vertical) return _onScrollStart(n, 4);
                return _onScrollStartH(n);
              },
              child: Scrollbar(
              controller: _gridVCtrl,
              thumbVisibility: true,
              child: SingleChildScrollView(
                controller: _gridVCtrl,
                child: Scrollbar(
                  controller: _gridHCtrl,
                  thumbVisibility: true,
                  notificationPredicate: (n) =>
                      n.metrics.axis == Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _gridHCtrl,
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(_gridH, (y) {
                        return Row(
                          children: List.generate(_gridW, (x) {
                            final here = x == _gx && y == _gy;
                            return GestureDetector(
                              onTap: () {
                                if (here) {
                                  _nextStage();
                                } else {
                                  _bumpWrong();
                                  setState(() {});
                                }
                              },
                              child: Container(
                                width: 88,
                                height: 64,
                                margin: const EdgeInsets.all(5),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: here
                                      ? NunuColors.secondaryMain.withValues(
                                          alpha: 0.35,
                                        )
                                      : NunuColors.backgroundPaper,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: NunuColors.primaryDark.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  here ? 'HERE' : '$x,$y',
                                  style: TextStyle(
                                    fontSize: here ? 13 : 11,
                                    fontWeight: here
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: NunuColors.textPrimary,
                                  ),
                                ),
                              ),
                            );
                          }),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(String subtitle) {
    return Column(
      children: [
        LevelHud(stageText: '${_stage + 1}/5'),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          color: NunuColors.backgroundPaper,
          child: Text(
            subtitle,
            style: const TextStyle(color: NunuColors.textPrimary, fontSize: 13),
          ),
        ),
      ],
    );
  }
}
