import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelWhackAMole extends LevelWidget {
  const LevelWhackAMole({super.key, required super.onComplete});

  @override
  State<LevelWhackAMole> createState() => _LevelWhackAMoleState();
}

class _LevelWhackAMoleState extends State<LevelWhackAMole> {
  static const int _rows = 4;
  static const int _cols = 4;
  static const int _timeLimitSeconds = 300; // 5 minutes
  static const Duration _spawnInterval = Duration(milliseconds: 900);

  // Bombs never speed up: they sit on the board long enough that tapping one
  // is a deliberate mistake rather than bad luck. Spawn rate and lifetime set
  // the resting count (~8 bombs); the cap only bites during bursts.
  static const Duration _bombSpawnInterval = Duration(milliseconds: 1200);
  static const Duration _bombLifetime = Duration(seconds: 10);
  static const int _maxActiveBombs = 10;

  /// A bomb hit cancels out this many mole hits.
  static const double _bombPenalty = 5.0;

  // Mole lifetime curve: (elapsed_seconds, lifetime_seconds).
  // Linearly interpolated between waypoints. Past the last point we hold
  // the final value (0.5s) until the run ends.
  static const List<List<double>> _lifetimeCurve = [
    [0, 10.0],
    [60, 5.0],
    [120, 2.5],
    [180, 1.75],
    [240, 1.0],
    [300, 0.5],
  ];

  Timer? _gameTimer;
  Timer? _spawnTimer;
  Timer? _bombSpawnTimer;
  int _secondsRemaining = _timeLimitSeconds;
  bool _started = false;
  bool _done = false;

  final Map<int, DateTime> _activeMoles = {};
  final Map<int, Timer> _removalTimers = {};

  final Set<int> _activeBombs = {};
  final Map<int, Timer> _bombRemovalTimers = {};

  int _hits = 0;
  int _missed = 0;
  int _totalSpawned = 0;
  int _bombsHit = 0;

  int? _lastWhackedIndex;
  Timer? _whackFeedbackTimer;

  int? _lastBombedIndex;
  Timer? _bombFeedbackTimer;

  final _rng = SeedService.instance.createRandom();

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _bombSpawnTimer?.cancel();
    _whackFeedbackTimer?.cancel();
    _bombFeedbackTimer?.cancel();
    for (final t in _removalTimers.values) {
      t.cancel();
    }
    for (final t in _bombRemovalTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  double _computeScore() {
    if (_totalSpawned == 0) return 0.0;
    final effective = _hits - _bombPenalty * _bombsHit;
    return (effective / _totalSpawned).clamp(0.0, 1.0);
  }

  Duration _currentMoleLifetime() {
    final elapsed = (_timeLimitSeconds - _secondsRemaining)
        .clamp(0, _timeLimitSeconds)
        .toDouble();
    // Before the first keyframe.
    if (elapsed <= _lifetimeCurve.first[0]) {
      return Duration(milliseconds: (_lifetimeCurve.first[1] * 1000).round());
    }
    // Past the last keyframe — hold the final value.
    if (elapsed >= _lifetimeCurve.last[0]) {
      return Duration(milliseconds: (_lifetimeCurve.last[1] * 1000).round());
    }
    for (int i = 0; i < _lifetimeCurve.length - 1; i++) {
      final t0 = _lifetimeCurve[i][0];
      final t1 = _lifetimeCurve[i + 1][0];
      if (elapsed >= t0 && elapsed <= t1) {
        final frac = (elapsed - t0) / (t1 - t0);
        final lifeSec =
            _lifetimeCurve[i][1] +
            (_lifetimeCurve[i + 1][1] - _lifetimeCurve[i][1]) * frac;
        return Duration(milliseconds: (lifeSec * 1000).round());
      }
    }
    return Duration(milliseconds: (_lifetimeCurve.last[1] * 1000).round());
  }

  void _startGame() {
    if (_started || _done) return;
    setState(() => _started = true);

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) _finish();
      });
    });

    _spawnTimer = Timer.periodic(_spawnInterval, (_) => _spawnMole());
    _bombSpawnTimer = Timer.periodic(_bombSpawnInterval, (_) => _spawnBomb());
    _spawnMole();
  }

  List<int> _freeCells() {
    final available = <int>[];
    for (int i = 0; i < _rows * _cols; i++) {
      if (!_activeMoles.containsKey(i) && !_activeBombs.contains(i)) {
        available.add(i);
      }
    }
    return available;
  }

  void _spawnMole() {
    if (_done || !mounted) return;

    final available = _freeCells();
    if (available.isEmpty) return;

    final pos = available[_rng.nextInt(available.length)];
    _totalSpawned++;

    setState(() {
      _activeMoles[pos] = DateTime.now();
    });

    final lifetime = _currentMoleLifetime();
    _removalTimers[pos]?.cancel();
    _removalTimers[pos] = Timer(lifetime, () {
      if (_activeMoles.containsKey(pos) && mounted) {
        setState(() {
          _activeMoles.remove(pos);
          _missed++;
        });
      }
    });
  }

  void _spawnBomb() {
    if (_done || !mounted) return;
    if (_activeBombs.length >= _maxActiveBombs) return;

    final available = _freeCells();
    if (available.isEmpty) return;

    final pos = available[_rng.nextInt(available.length)];

    setState(() {
      _activeBombs.add(pos);
    });

    _bombRemovalTimers[pos]?.cancel();
    _bombRemovalTimers[pos] = Timer(_bombLifetime, () {
      if (!mounted) return;
      setState(() {
        _activeBombs.remove(pos);
      });
      _bombRemovalTimers.remove(pos);
    });
  }

  void _whack(int pos) {
    if (!_started || _done) return;

    if (_activeBombs.contains(pos)) {
      _bombsHit++;
      _activeBombs.remove(pos);
      _bombRemovalTimers[pos]?.cancel();
      _bombRemovalTimers.remove(pos);

      _lastBombedIndex = pos;
      _bombFeedbackTimer?.cancel();
      _bombFeedbackTimer = Timer(const Duration(milliseconds: 500), () {
        if (mounted) setState(() => _lastBombedIndex = null);
      });

      HapticFeedback.heavyImpact();
      setState(() {});
      return;
    }

    if (_activeMoles.containsKey(pos)) {
      _hits++;
      _activeMoles.remove(pos);
      _removalTimers[pos]?.cancel();
      _removalTimers.remove(pos);

      _lastWhackedIndex = pos;
      _whackFeedbackTimer?.cancel();
      _whackFeedbackTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) setState(() => _lastWhackedIndex = null);
      });

      HapticFeedback.mediumImpact();
      setState(() {});
    }
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _bombSpawnTimer?.cancel();
    for (final t in _removalTimers.values) {
      t.cancel();
    }
    for (final t in _bombRemovalTimers.values) {
      t.cancel();
    }

    final score = _computeScore();

    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onComplete(
        LevelOutcome(
          score: score,
          metrics: {'hits': _hits, 'missed': _missed, 'bombs_hit': _bombsHit},
        ),
      );
    });
  }

  String _formatTime(int seconds) {
    final s = seconds.clamp(0, _timeLimitSeconds);
    final m = s ~/ 60;
    final r = s % 60;
    return '$m:${r.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
      () => LevelOutcome(
        score: _computeScore(),
        metrics: {'hits': _hits, 'bombs_hit': _bombsHit},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          LevelHud(
            timerText: _formatTime(_secondsRemaining),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'hits $_hits',
                  style: const TextStyle(
                    color: NunuColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_bombsHit > 0) ...[
                  const SizedBox(width: 10),
                  Text(
                    '💣 $_bombsHit',
                    style: const TextStyle(
                      color: NunuColors.errorMain,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: _buildTimerBar(),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Stack(
                children: [_buildGrid(), if (!_started) _buildStartOverlay()],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTimerBar() {
    final pct = _secondsRemaining / _timeLimitSeconds;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: NunuColors.backgroundPaper),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      pct < 0.1 ? NunuColors.errorMain : NunuColors.primaryMain,
                      NunuColors.secondaryMain,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellW = (constraints.maxWidth - (_cols - 1) * 8) / _cols;
        final cellH = (constraints.maxHeight - (_rows - 1) * 8) / _rows;
        final cellSize = min(cellW, cellH);

        return Center(
          child: SizedBox(
            width: cellSize * _cols + (_cols - 1) * 8,
            height: cellSize * _rows + (_rows - 1) * 8,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _cols,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _rows * _cols,
              itemBuilder: (_, i) {
                final hasMole = _activeMoles.containsKey(i);
                final hasBomb = _activeBombs.contains(i);
                final wasJustWhacked = _lastWhackedIndex == i;
                final wasJustBombed = _lastBombedIndex == i;

                final Color borderColor;
                if (hasBomb) {
                  borderColor = NunuColors.errorMain;
                } else if (hasMole) {
                  borderColor = NunuColors.warningMain;
                } else {
                  borderColor = NunuColors.primaryDark.withOpacity(0.3);
                }

                final Color? glowColor = hasBomb
                    ? NunuColors.errorMain
                    : hasMole
                    ? NunuColors.warningMain
                    : null;

                final Color fillColor;
                if (wasJustBombed) {
                  fillColor = NunuColors.errorMain.withOpacity(0.35);
                } else if (wasJustWhacked) {
                  fillColor = NunuColors.successMain.withOpacity(0.3);
                } else {
                  fillColor = NunuColors.backgroundPaper;
                }

                return GestureDetector(
                  onTap: _started && !_done ? () => _whack(i) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: fillColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor,
                        width: hasMole || hasBomb ? 3 : 1,
                      ),
                      boxShadow: glowColor != null
                          ? [
                              BoxShadow(
                                color: glowColor.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: hasBomb
                            ? const Text(
                                '💣',
                                key: ValueKey('bomb'),
                                style: TextStyle(fontSize: 36),
                              )
                            : hasMole
                            ? const Text(
                                '🐹',
                                key: ValueKey('mole'),
                                style: TextStyle(fontSize: 36),
                              )
                            : wasJustBombed
                            ? const Text(
                                '☠️',
                                key: ValueKey('boom'),
                                style: TextStyle(fontSize: 28),
                              )
                            : wasJustWhacked
                            ? const Text(
                                '💥',
                                key: ValueKey('hit'),
                                style: TextStyle(fontSize: 28),
                              )
                            : Container(
                                key: const ValueKey('empty'),
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: NunuColors.backgroundDefault
                                      .withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildStartOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NunuColors.primaryMain, width: 2),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withOpacity(0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ready?',
              style: TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Text(
                'GO',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              '5 minutes — moles get faster',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            const Text(
              'every 💣 you tap costs you 5 moles',
              style: TextStyle(color: NunuColors.errorMain, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
