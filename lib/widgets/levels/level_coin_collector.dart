import 'dart:math';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelCoinCollector extends LevelWidget {
  const LevelCoinCollector({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelCoinCollector> createState() => _LevelCoinCollectorState();
}

class _LevelCoinCollectorState extends State<LevelCoinCollector> {
  final Random _random = Random();
  late int _targetCoinCount;
  late List<Offset> _coinPositions;
  late List<bool> _coinCollected;
  late List<_SpaceObject> _spaceObjects;
  final double _mapWidth = 2000.0;
  final double _mapHeight = 2000.0;
  final TextEditingController _controller = TextEditingController();
  
  int get _collectedCount => _coinCollected.where((c) => c).length;

  @override
  void initState() {
    super.initState();
    _generateLevel();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _generateLevel() {
    _spaceObjects = [];

    // 1. Generate Stars (Background, large amount)
    for (int i = 0; i < 200; i++) {
      double x = _random.nextDouble() * _mapWidth;
      double y = _random.nextDouble() * _mapHeight;
      double size = 2 + _random.nextDouble() * 4;
      _spaceObjects.add(_SpaceObject(
        position: Offset(x, y),
        size: size,
        color: Colors.white.withOpacity(0.3 + _random.nextDouble() * 0.5),
        type: _SpaceObjectType.star,
      ));
    }

    // 2. Generate Planets (Large, background)
    for (int i = 0; i < 6; i++) {
      double x = 100 + _random.nextDouble() * (_mapWidth - 200);
      double y = 100 + _random.nextDouble() * (_mapHeight - 200);
      double size = 150 + _random.nextDouble() * 200;
      // Random greyish colors
      Color color = Color.lerp(Colors.grey[800], Colors.blueGrey[900], _random.nextDouble())!;
      
      _spaceObjects.add(_SpaceObject(
        position: Offset(x, y),
        size: size,
        color: color,
        type: _SpaceObjectType.planet,
      ));
    }

    // 3. Generate Rockets
    for (int i = 0; i < 4; i++) {
      double x = _random.nextDouble() * (_mapWidth - 100);
      double y = _random.nextDouble() * (_mapHeight - 100);
      _spaceObjects.add(_SpaceObject(
        position: Offset(x, y),
        size: 60,
        color: Colors.white,
        type: _SpaceObjectType.rocket,
        rotation: _random.nextDouble() * 2 * pi,
      ));
    }

    // 4. Generate Comets
    for (int i = 0; i < 4; i++) {
      double x = _random.nextDouble() * (_mapWidth - 100);
      double y = _random.nextDouble() * (_mapHeight - 100);
      _spaceObjects.add(_SpaceObject(
        position: Offset(x, y),
        size: 80,
        color: Colors.cyanAccent,
        type: _SpaceObjectType.comet,
        rotation: _random.nextDouble() * 2 * pi,
      ));
    }

    // Generate between 8 and 20 coins
    _targetCoinCount = 8 + _random.nextInt(13); // 8 to 20
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

  void _checkAnswer() {
    final input = int.tryParse(_controller.text);
    if (input == _targetCoinCount) {
      widget.onComplete(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Incorrect! Count again.'),
          backgroundColor: NunuColors.errorMain,
          duration: const Duration(seconds: 1),
        ),
      );
      widget.onComplete(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NunuColors.backgroundDefault,
      // Input area at the bottom, fixed
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          left: 16,
          right: 16,
          top: 16,
        ),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper,
          border: Border(top: BorderSide(color: NunuColors.primaryMain.withOpacity(0.3))),
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
                    'Total coins on map?',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            SizedBox(width: 16),
            SizedBox(
              width: 80,
              child: TextField(
                controller: _controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '#',
                  hintStyle: TextStyle(color: Colors.white30),
                  filled: true,
                  fillColor: NunuColors.backgroundDefault,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: NunuColors.primaryMain),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                onSubmitted: (_) => _checkAnswer(),
              ),
            ),
            SizedBox(width: 16),
            ElevatedButton(
              onPressed: _checkAnswer,
              style: ElevatedButton.styleFrom(
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
              ),
              child: Text('Submit'),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          InteractiveViewer(
            boundaryMargin: const EdgeInsets.all(double.infinity),
            minScale: 0.1,
            maxScale: 2.0,
            constrained: false, // Allows the child to be larger than the screen
            child: Container(
              width: _mapWidth,
              height: _mapHeight,
              color: NunuColors.backgroundDefault,
              child: Stack(
                children: [
                  // Space Objects
                  ..._spaceObjects.map((obj) => Positioned(
                    left: obj.position.dx,
                    top: obj.position.dy,
                    child: _buildSpaceObject(obj),
                  )),
                  
                  // Map Border
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: NunuColors.primaryMain, width: 4),
                      ),
                    ),
                  ),

                  // Corner markers to help orientation
                  Positioned(top: 20, left: 20, child: _buildMarker('Sector Alpha')),
                  Positioned(top: 20, right: 20, child: _buildMarker('Sector Beta')),
                  Positioned(bottom: 20, left: 20, child: _buildMarker('Sector Gamma')),
                  Positioned(bottom: 20, right: 20, child: _buildMarker('Sector Delta')),
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
                    if (_coinCollected[index]) return SizedBox.shrink(); // Don't show collected coins
                    
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
          
          // Floating counter overlay (optional, but requested "somewhere")
          // I put it in the bottom bar, but having it floating is also nice.
          // Let's stick to the bottom bar as it's cleaner.
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
              )
            ],
            gradient: RadialGradient(
              colors: [
                obj.color.withOpacity(0.8),
                obj.color,
              ],
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
              BoxShadow(
                color: obj.color,
                blurRadius: 4,
                spreadRadius: 1,
              )
            ],
          ),
        );
      case _SpaceObjectType.rocket:
        return Transform.rotate(
          angle: obj.rotation,
          child: Icon(
            Icons.rocket_launch,
            size: obj.size,
            color: obj.color,
          ),
        );
      case _SpaceObjectType.comet:
        return Transform.rotate(
          angle: obj.rotation,
          child: Icon(
            Icons.moving,
            size: obj.size,
            color: obj.color,
          ),
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

enum _SpaceObjectType {
  planet,
  star,
  rocket,
  comet,
}

