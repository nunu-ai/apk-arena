import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelRhythm extends LevelWidget {
  const LevelRhythm({super.key, required super.onComplete});

  @override
  State<LevelRhythm> createState() => _LevelRhythmState();
}

class _LevelRhythmState extends State<LevelRhythm> {
  static const int _numLanes = 4;
  static const int _totalNotes = 16;
  static const int _requiredHits = 10;
  static const double _noteSpeed = 1.4; // gentle fall speed
  static const double _hitZoneY = 0.78; // fraction of height
  static const double _hitTolerance = 0.10; // generous tolerance
  static const double _hitZoneHeight = 0.12; // visible hit band

  Timer? _gameTimer;
  final List<_Note> _notes = [];
  int _spawnedCount = 0;
  int _hits = 0;
  int _combo = 0;
  int _maxCombo = 0;
  bool _done = false;
  Timer? _spawnTimer;
  double _screenHeight = 600;

  final List<Color> _laneColors = [
    NunuColors.errorMain,
    NunuColors.infoMain,
    NunuColors.successMain,
    NunuColors.warningMain,
  ];

  final List<String> _laneLabels = ['←', '↑', '↓', '→'];

  @override
  void initState() {
    super.initState();
    // Use a fixed-rate timer instead of AnimationController to avoid per-frame rebuilds
    _gameTimer = Timer.periodic(const Duration(milliseconds: 50), (_) => _tick());
    _startSpawning();
  }

  void _startSpawning() {
    final rng = Random();
    _spawnTimer = Timer.periodic(const Duration(milliseconds: 1800), (_) {
      if (_done || _spawnedCount >= _totalNotes) {
        _spawnTimer?.cancel();
        return;
      }
      setState(() {
        final lane = rng.nextInt(_numLanes);
        _notes.add(_Note(lane: lane, y: -0.08));
        _spawnedCount++;
      });
    });
  }

  void _tick() {
    if (_done || !mounted) return;

    setState(() {
      for (final note in _notes) {
        if (!note.hit && !note.missed) {
          note.y += _noteSpeed / _screenHeight;

          // Miss detection
          if (note.y > _hitZoneY + _hitTolerance + 0.02) {
            note.missed = true;
            _combo = 0;
          }
        }
      }

      // Remove old notes
      _notes.removeWhere((n) => n.y > 1.1 || (n.hit && n.hitAge > 30));

      for (final n in _notes) {
        if (n.hit) n.hitAge++;
      }

      // Game over check
      if (_spawnedCount >= _totalNotes &&
          _notes.every((n) => n.hit || n.missed)) {
        _endGame();
      }
    });
  }

  void _onLaneTap(int lane) {
    if (_done) return;

    // Find closest unhit note in this lane within tolerance
    _Note? closest;
    double closestDist = double.infinity;
    for (final note in _notes) {
      if (note.lane == lane && !note.hit && !note.missed) {
        final dist = (note.y - _hitZoneY).abs();
        if (dist < _hitTolerance && dist < closestDist) {
          closest = note;
          closestDist = dist;
        }
      }
    }

    if (closest != null) {
      setState(() {
        closest!.hit = true;
        _hits++;
        _combo++;
        if (_combo > _maxCombo) _maxCombo = _combo;
        HapticFeedback.lightImpact();
      });
    } else {
      setState(() {
        _combo = 0;
      });
      HapticFeedback.heavyImpact();
    }
  }

  void _endGame() {
    if (_done) return;
    _done = true;
    final won = _hits >= _requiredHits;
    if (won) HapticFeedback.mediumImpact();
    Future.delayed(const Duration(milliseconds: 600), () {
      widget.onComplete(won);
    });
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _spawnTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _screenHeight = constraints.maxHeight;
        final laneWidth = constraints.maxWidth / _numLanes;
        final hitBandTop =
            constraints.maxHeight * (_hitZoneY - _hitZoneHeight / 2);
        final hitBandHeight = constraints.maxHeight * _hitZoneHeight;

        return Container(
          color: const Color(0xFF050510),
          child: Stack(
            children: [
              // Lane dividers
              ...List.generate(_numLanes - 1, (i) {
                return Positioned(
                  left: laneWidth * (i + 1),
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 1,
                    color: Colors.white.withOpacity(0.05),
                  ),
                );
              }),

              // Hit zone band (visible target area)
              Positioned(
                top: hitBandTop,
                left: 0,
                right: 0,
                height: hitBandHeight,
                child: Container(
                  decoration: BoxDecoration(
                    color: NunuColors.primaryMain.withOpacity(0.08),
                    border: Border(
                      top: BorderSide(
                        color: NunuColors.primaryMain.withOpacity(0.4),
                        width: 2,
                      ),
                      bottom: BorderSide(
                        color: NunuColors.primaryMain.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            NunuColors.primaryMain.withOpacity(0.1),
                            NunuColors.primaryMain.withOpacity(0.6),
                            NunuColors.primaryMain.withOpacity(0.1),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: NunuColors.primaryMain.withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Notes (falling)
              ..._notes.where((n) => !n.hit && !n.missed).map((note) {
                return Positioned(
                  left: note.lane * laneWidth + laneWidth * 0.15,
                  top: note.y * constraints.maxHeight - 25,
                  child: Container(
                    width: laneWidth * 0.7,
                    height: 50,
                    decoration: BoxDecoration(
                      color: _laneColors[note.lane].withOpacity(0.85),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _laneColors[note.lane].withOpacity(0.5),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _laneLabels[note.lane],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }),

              // Hit effects
              ..._notes.where((n) => n.hit && n.hitAge < 15).map((note) {
                final opacity = 1.0 - (note.hitAge / 15.0);
                return Positioned(
                  left: note.lane * laneWidth + laneWidth * 0.2,
                  top: hitBandTop + hitBandHeight * 0.1,
                  child: Container(
                    width: laneWidth * 0.6,
                    height: hitBandHeight * 0.8,
                    decoration: BoxDecoration(
                      color: NunuColors.successMain.withOpacity(0.3 * opacity),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.check,
                      color: NunuColors.successMain.withOpacity(opacity),
                      size: 28,
                    ),
                  ),
                );
              }),

              // Lane tap targets (bottom area + hit zone)
              Positioned(
                top: hitBandTop - 20,
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  children: List.generate(_numLanes, (lane) {
                    return Expanded(
                      child: GestureDetector(
                        onTapDown: (_) => _onLaneTap(lane),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          color: Colors.transparent,
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Lane labels at bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: constraints.maxHeight * 0.12,
                child: Row(
                  children: List.generate(_numLanes, (lane) {
                    return Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: _laneColors[lane].withOpacity(0.08),
                          border: Border(
                            top: BorderSide(
                              color: _laneColors[lane].withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _laneLabels[lane],
                            style: TextStyle(
                              color: _laneColors[lane].withOpacity(0.6),
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // HUD
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'combo $_combo',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _combo >= 5
                                ? NunuColors.warningMain
                                : Colors.white,
                          ),
                        ),
                        Text(
                          '$_hits / $_requiredHits',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_totalNotes - _spawnedCount + _notes.where((n) => !n.hit && !n.missed).length} left',
                          style: const TextStyle(
                            fontSize: 14,
                            color: NunuColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Note {
  final int lane;
  double y;
  bool hit;
  bool missed;
  int hitAge;

  _Note({
    required this.lane,
    required this.y,
  })  : hit = false,
        missed = false,
        hitAge = 0;
}
