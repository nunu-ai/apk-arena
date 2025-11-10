import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelBombDefuse extends LevelWidget {
  const LevelBombDefuse({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelBombDefuse> createState() => _LevelBombDefuseState();
}

class _LevelBombDefuseState extends State<LevelBombDefuse> with TickerProviderStateMixin {
  late int _targetTaps;
  int _currentTaps = 0;
  bool _isExploding = false;
  bool _isDefused = false;
  late AnimationController _buttonController;
  late AnimationController _explosionController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _targetTaps = 5 + Random().nextInt(11); // 5-15

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut),
    );

    _explosionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _explosionController.dispose();
    super.dispose();
  }

  void _handleButtonPress() {
    if (_isExploding || _isDefused) return;

    setState(() {
      _currentTaps++;
    });

    _buttonController.forward().then((_) => _buttonController.reverse());
  }

  void _handleCutWire() {
    if (_isExploding || _isDefused) return;

    if (_currentTaps == _targetTaps) {
      // Success!
      setState(() {
        _isDefused = true;
      });

      Future.delayed(const Duration(milliseconds: 800), () {
        widget.onComplete(true);
      });
    } else {
      // Wrong! Explode and reset
      setState(() {
        _isExploding = true;
      });

      _explosionController.forward();

      Future.delayed(const Duration(milliseconds: 1000), () {
        setState(() {
          _isExploding = false;
          _currentTaps = 0;
          _targetTaps = 5 + Random().nextInt(11);
        });
        _explosionController.reset();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.grey.shade900,
            Colors.black,
          ],
        ),
      ),
      child: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hint at top - more compact
                  if (!_isDefused && !_isExploding)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade900.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.orange.shade700.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade400,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Press exactly $_targetTaps times, then cut green wire!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade200,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 12),

                  // Bomb casing - more compact
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _isDefused
                            ? Colors.green
                            : _isExploding
                            ? Colors.red
                            : Colors.grey.shade600,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isDefused
                              ? Colors.green.withValues(alpha: 0.3)
                              : _isExploding
                              ? Colors.red.withValues(alpha: 0.5)
                              : Colors.black.withValues(alpha: 0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Bomb emoji/icon - smaller
                        Text(
                          _isDefused ? '✅' : _isExploding ? '💥' : '💣',
                          style: const TextStyle(fontSize: 48),
                        ),

                        const SizedBox(height: 16),

                        // Display (shows coded message, not the count) - smaller
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: _isDefused
                                  ? Colors.green
                                  : _isExploding
                                  ? Colors.red
                                  : Colors.red.shade700,
                              width: 2,
                            ),
                          ),
                          child: Text(
                            _isDefused
                                ? 'DEFUSED'
                                : _isExploding
                                ? 'BOOM!'
                                : '▓▓:▓▓',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _isDefused
                                  ? Colors.green
                                  : _isExploding
                                  ? Colors.red
                                  : Colors.red.shade400,
                              fontFamily: 'monospace',
                              letterSpacing: 3,
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Big red button - smaller
                        GestureDetector(
                          onTap: _handleButtonPress,
                          child: ScaleTransition(
                            scale: _buttonScale,
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.red.shade400,
                                    Colors.red.shade700,
                                    Colors.red.shade900,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withValues(alpha: 0.5),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.red.shade300,
                                  width: 2,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: 85,
                                  height: 85,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.red.shade600,
                                  ),
                                  child: const Center(
                                    child: Text(
                                      'PRESS',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Wires section - smaller spacing
                        const Text(
                          'CUT THE WIRE',
                          style: TextStyle(
                            fontSize: 10,
                            color: NunuColors.textSecondary,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Wire buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildWire(Colors.red, false),
                            _buildWire(Colors.blue, false),
                            _buildWire(Colors.green, true), // Correct wire
                            _buildWire(Colors.yellow, false),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Explosion overlay
          if (_isExploding)
            AnimatedBuilder(
              animation: _explosionController,
              builder: (context, child) {
                return Container(
                  color: Colors.red.withValues(
                    alpha: (0.7 * (1 - _explosionController.value)),
                  ),
                  child: Center(
                    child: Transform.scale(
                      scale: 1 + (_explosionController.value * 2),
                      child: Text(
                        '💥',
                        style: TextStyle(
                          fontSize: 100,
                          shadows: [
                            Shadow(
                              color: Colors.orange.withValues(alpha: 0.8),
                              blurRadius: 50,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildWire(Color color, bool isCorrect) {
    final isCut = _isDefused && isCorrect;

    return GestureDetector(
      onTap: isCorrect ? _handleCutWire : null,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 4,
            decoration: BoxDecoration(
              color: isCut ? Colors.grey.shade700 : color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 6),
          if (isCorrect)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color, width: 2),
              ),
              child: Text(
                'CUT',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            )
          else
            const SizedBox(height: 20),
        ],
      ),
    );
  }
}