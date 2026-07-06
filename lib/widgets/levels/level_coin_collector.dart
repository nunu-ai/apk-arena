import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelCoinCollector extends LevelWidget {
  const LevelCoinCollector({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelCoinCollector> createState() => _LevelCoinCollectorState();
}

class _LevelCoinCollectorState extends State<LevelCoinCollector> {
  final Random _random = SeedService.instance.createRandom();
  late int _targetCoinCount;
  late List<Offset> _coinPositions;
  late List<bool> _coinCollected;
  late List<_SpaceObject> _spaceObjects;
  final double _mapWidth = 2000.0;
  final double _mapHeight = 2000.0;

  int get _collectedCount => _coinCollected.where((c) => c).length;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
        () => LevelOutcome(score: _targetCoinCount == 0 ? 0.0 : (1.0 - sqrt((_targetCoinCount - _collectedCount).clamp(0, _targetCoinCount) / _targetCoinCount.toDouble())).clamp(0.0, 1.0)));
    _generateLevel();
  }

  void _generateLevel() {
    _spaceObjects = [];

    // 1. Generate Stars (Background, large amount)
    for (int i = 0; i < 200; i++) {
      double x = _random.nextDouble() * _mapWidth;
      double y = _random.nextDouble() * _mapHeight;
      double size = 2 + _random.nextDouble() * 4;
      _spaceObjects.add(
        _SpaceObject(
          position: Offset(x, y),
          size: size,
          color: Colors.white.withOpacity(0.3 + _random.nextDouble() * 0.5),
          type: _SpaceObjectType.star,
        ),
      );
    }

    // 2. Generate Planets (Large, background)
    for (int i = 0; i < 6; i++) {
      double x = 100 + _random.nextDouble() * (_mapWidth - 200);
      double y = 100 + _random.nextDouble() * (_mapHeight - 200);
      double size = 150 + _random.nextDouble() * 200;
      // Random greyish colors
      Color color = Color.lerp(
        Colors.grey[800],
        Colors.blueGrey[900],
        _random.nextDouble(),
      )!;

      _spaceObjects.add(
        _SpaceObject(
          position: Offset(x, y),
          size: size,
          color: color,
          type: _SpaceObjectType.planet,
        ),
      );
    }

    // 3. Generate Rockets
    for (int i = 0; i < 4; i++) {
      double x = _random.nextDouble() * (_mapWidth - 100);
      double y = _random.nextDouble() * (_mapHeight - 100);
      _spaceObjects.add(
        _SpaceObject(
          position: Offset(x, y),
          size: 60,
          color: Colors.white,
          type: _SpaceObjectType.rocket,
          rotation: _random.nextDouble() * 2 * pi,
        ),
      );
    }

    // 4. Generate Comets
    for (int i = 0; i < 4; i++) {
      double x = _random.nextDouble() * (_mapWidth - 100);
      double y = _random.nextDouble() * (_mapHeight - 100);
      _spaceObjects.add(
        _SpaceObject(
          position: Offset(x, y),
          size: 80,
          color: Colors.cyanAccent,
          type: _SpaceObjectType.comet,
          rotation: _random.nextDouble() * 2 * pi,
        ),
      );
    }

    // Generate between 15 and 20 coins
    _targetCoinCount = 15 + _random.nextInt(6); // 15 to 20 inclusive
    _coinPositions = [];
    _coinCollected = [];

    for (int i = 0; i < _targetCoinCount; i++) {
      // Keep coins away from the very edges
      double x = 50 + _random.nextDouble() * (_mapWidth - 100);
      double y = 50 + _random.nextDouble() * (_mapHeight - 100);

      // Basic collision avoidance
      bool tooClose = false;
      for (final pos in _coinPositions) {
        if ((pos - Offset(x, y)).distance < 60) {
          tooClose = true;
          break;
        }
      }

      if (tooClose) {
        i--; // Retry
      } else {
        _coinPositions.add(Offset(x, y));
        _coinCollected.add(false);
      }
    }
  }

  void _collectCoin(int index) {
    if (!_coinCollected[index]) {
      setState(() {
        _coinCollected[index] = true;
      });
    }
  }

  void _finish() {
    final missed = _targetCoinCount - _collectedCount;
    final score = missed == 0
        ? 1.0
        : (1.0 - sqrt(missed / _targetCoinCount)).clamp(0.0, 1.0);
    widget.onComplete(
      LevelOutcome(
        score: score,
        metrics: {
          'collected': _collectedCount,
          'total': _targetCoinCount,
          'missed': missed,
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NunuColors.backgroundDefault,
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          border: Border(
            top: BorderSide(color: NunuColors.primaryMain.withOpacity(0.3)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Collected: $_collectedCount',
                    style: TextStyle(
                      color: NunuColors.primaryMain,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    'tap done when you think you have them all',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
              ),
              child: Text('Done'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 1.0,
            maxScale: 2.0,
            constrained: false, // Allows the child to be larger than the screen
            child: Container(
              width: _mapWidth,
              height: _mapHeight,
              color: NunuColors.backgroundDefault,
              child: Stack(
                children: [
                  // Space Objects
                  ..._spaceObjects.map(
                    (obj) => Positioned(
                      left: obj.position.dx,
                      top: obj.position.dy,
                      child: _buildSpaceObject(obj),
                    ),
                  ),

                  // Map Border
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: NunuColors.primaryMain,
                          width: 4,
                        ),
                      ),
                    ),
                  ),

                  // Corner markers to help orientation
                  Positioned(
                    top: 20,
                    left: 20,
                    child: _buildMarker('Sector Alpha'),
                  ),
                  Positioned(
                    top: 20,
                    right: 20,
                    child: _buildMarker('Sector Beta'),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: _buildMarker('Sector Gamma'),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: _buildMarker('Sector Delta'),
                  ),
                  Positioned(
                    left: _mapWidth / 2 - 60,
                    top: _mapHeight / 2 - 20,
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        border: Border.all(color: NunuColors.primaryMain),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'GALACTIC CORE',
                        style: TextStyle(
                          color: NunuColors.primaryMain,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Coins
                  ...List.generate(_coinPositions.length, (index) {
                    if (_coinCollected[index])
                      return SizedBox.shrink(); // Don't show collected coins

                    final pos = _coinPositions[index];
                    return Positioned(
                      left: pos.dx - 24,
                      top: pos.dy - 24,
                      child: GestureDetector(
                        onTap: () => _collectCoin(index),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(0.4),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.monetization_on,
                            color: Colors.amber,
                            size: 48,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceObject(_SpaceObject obj) {
    switch (obj.type) {
      case _SpaceObjectType.planet:
        return Container(
          width: obj.size,
          height: obj.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: obj.color,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
            gradient: RadialGradient(
              colors: [obj.color.withOpacity(0.8), obj.color],
              center: Alignment(-0.3, -0.3),
            ),
          ),
        );
      case _SpaceObjectType.star:
        return Container(
          width: obj.size,
          height: obj.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: obj.color,
            boxShadow: [
              BoxShadow(color: obj.color, blurRadius: 4, spreadRadius: 1),
            ],
          ),
        );
      case _SpaceObjectType.rocket:
        return Transform.rotate(
          angle: obj.rotation,
          child: Icon(Icons.rocket_launch, size: obj.size, color: obj.color),
        );
      case _SpaceObjectType.comet:
        return Transform.rotate(
          angle: obj.rotation,
          child: Icon(Icons.moving, size: obj.size, color: obj.color),
        );
    }
  }

  Widget _buildMarker(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: NunuColors.primaryDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _SpaceObject {
  final Offset position;
  final double size;
  final Color color;
  final _SpaceObjectType type;
  final double rotation;

  _SpaceObject({
    required this.position,
    required this.size,
    required this.color,
    required this.type,
    this.rotation = 0,
  });
}

enum _SpaceObjectType { planet, star, rocket, comet }
