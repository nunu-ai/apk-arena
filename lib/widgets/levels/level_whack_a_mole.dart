import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelWhackAMole extends LevelWidget {
  const LevelWhackAMole({super.key, required super.onComplete});

  @override
  State<LevelWhackAMole> createState() => _LevelWhackAMoleState();
}

class _LevelWhackAMoleState extends State<LevelWhackAMole> {
  static const int _rows = 4;
  static const int _cols = 4;
  static const int _timeLimitSeconds = 30;
  static const Duration _moleLifetime = Duration(milliseconds: 1800);
  static const Duration _spawnInterval = Duration(milliseconds: 900);

  Timer? _gameTimer;
  Timer? _spawnTimer;
  int _secondsRemaining = _timeLimitSeconds;
  bool _started = false;
  bool _done = false;

  // Track active moles: cell index -> spawn timestamp
  final Map<int, DateTime> _activeMoles = {};
  // Track scheduled removals
  final Map<int, Timer> _removalTimers = {};

  int _hits = 0;
  int _missed = 0; // moles that expired without being whacked
  int _totalSpawned = 0;
  double _totalReactionMs = 0;

  // Whack feedback
  int? _lastWhackedIndex;
  Timer? _whackFeedbackTimer;

  final _rng = Random();

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    _whackFeedbackTimer?.cancel();
    for (final t in _removalTimers.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _startGame() {
    if (_started) return;
    _started = true;

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) _finish();
      });
    });

    _spawnTimer = Timer.periodic(_spawnInterval, (_) => _spawnMole());
    _spawnMole();
  }

  void _spawnMole() {
    if (_done || !mounted) return;

    // Find an empty cell
    final occupied = _activeMoles.keys.toSet();
    final available = <int>[];
    for (int i = 0; i < _rows * _cols; i++) {
      if (!occupied.contains(i)) available.add(i);
    }
    if (available.isEmpty) return;

    final pos = available[_rng.nextInt(available.length)];
    _totalSpawned++;

    setState(() {
      _activeMoles[pos] = DateTime.now();
    });

    // Schedule auto-removal
    _removalTimers[pos]?.cancel();
    _removalTimers[pos] = Timer(_moleLifetime, () {
      if (_activeMoles.containsKey(pos) && mounted) {
        setState(() {
          _activeMoles.remove(pos);
          _missed++;
        });
      }
    });
  }

  void _whack(int pos) {
    if (!_started) _startGame();
    if (_done) return;

    if (_activeMoles.containsKey(pos)) {
      final spawnTime = _activeMoles[pos]!;
      final reactionMs =
          DateTime.now().difference(spawnTime).inMilliseconds.toDouble();
      _totalReactionMs += reactionMs;
      _hits++;
      _activeMoles.remove(pos);
      _removalTimers[pos]?.cancel();
      _removalTimers.remove(pos);

      // Visual feedback
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
    for (final t in _removalTimers.values) {
      t.cancel();
    }

    final avgReaction = _hits > 0 ? (_totalReactionMs / _hits).round() : 0;
    final accuracy =
        _totalSpawned > 0 ? (_hits / _totalSpawned * 100) : 0.0;
    final success = _hits >= 1;

    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onComplete(LevelOutcome(score: success ? 1 : 0, metrics: {
        'score': _hits,
        'accuracy': '${accuracy.toStringAsFixed(1)}%',
        'avg_reaction': '${avgReaction}ms',
        'total_moles': _totalSpawned,
      }));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildTimerBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildGrid()),
            const SizedBox(height: 12),
            _buildStats(),
            const SizedBox(height: 8),
            if (!_started)
              const Text(
                'tap any hole to start!',
                style: TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_secondsRemaining}s',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: _secondsRemaining <= 5
                ? NunuColors.errorMain
                : NunuColors.primaryMain,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: NunuColors.primaryDark.withOpacity(0.5),
            ),
          ),
          child: Row(
            children: [
              const Text('🔨', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Text(
                '$_hits',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
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
                      pct < 0.2 ? NunuColors.errorMain : NunuColors.primaryMain,
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
                final wasJustWhacked = _lastWhackedIndex == i;

                return GestureDetector(
                  onTap: () => _whack(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: wasJustWhacked
                          ? NunuColors.successMain.withOpacity(0.3)
                          : NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: hasMole
                            ? NunuColors.warningMain
                            : NunuColors.primaryDark.withOpacity(0.3),
                        width: hasMole ? 3 : 1,
                      ),
                      boxShadow: hasMole
                          ? [
                              BoxShadow(
                                color: NunuColors.warningMain.withOpacity(0.3),
                                blurRadius: 12,
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 150),
                        child: hasMole
                            ? const Text(
                                '🐹',
                                key: ValueKey('mole'),
                                style: TextStyle(fontSize: 36),
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

  Widget _buildStats() {
    final avgReaction = _hits > 0 ? (_totalReactionMs / _hits).round() : 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _statChip('hits', '$_hits'),
        _statChip('missed', '$_missed'),
        _statChip('avg speed', '${avgReaction}ms'),
      ],
    );
  }

  Widget _statChip(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(
                color: NunuColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: NunuColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
