import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelSwipeDirections extends LevelWidget {
  const LevelSwipeDirections({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelSwipeDirections> createState() => _LevelSwipeDirectionsState();
}

class _LevelSwipeDirectionsState extends State<LevelSwipeDirections> {
  final List<String> _directions = ['UP', 'DOWN', 'LEFT', 'RIGHT'];
  late List<String> _sequence;
  int _currentIndex = 0;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _sequence = List.from(_directions)..shuffle(Random());
  }

  void _handleSwipe(String direction) {
    if (direction == _sequence[_currentIndex]) {
      setState(() {
        _currentIndex++;
        if (_currentIndex >= _sequence.length) {
          // All swipes completed!
          widget.onComplete(true);
        }
      });
    } else {
      // Wrong direction - reset
      setState(() {
        _currentIndex = 0;
        _sequence.shuffle(Random());
      });
    }
  }

  String _getSwipeDirection(Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;

    if (dx.abs() > dy.abs()) {
      return dx > 0 ? 'RIGHT' : 'LEFT';
    } else {
      return dy > 0 ? 'DOWN' : 'UP';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentIndex >= _sequence.length) {
      return const SizedBox.shrink();
    }
    
    return GestureDetector(
      onPanStart: (details) {
        _dragStart = details.globalPosition;
      },
      onPanEnd: (details) {
        if (_dragStart != null) {
          final direction = _getSwipeDirection(
            _dragStart!,
            details.globalPosition,
          );
          _handleSwipe(direction);
        }
      },
      child: Container(
        color: Colors.transparent,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$_currentIndex / ${_sequence.length}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: NunuColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      _sequence[_currentIndex],
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: NunuColors.primaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}