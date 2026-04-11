import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

/// Spot-the-difference: two generated scenes, tap the difference. 5 rounds.
class LevelEagleEye extends LevelWidget {
  const LevelEagleEye({super.key, required super.onComplete});

  @override
  State<LevelEagleEye> createState() => _LevelEagleEyeState();
}

class _ShapeItem {
  final double x, y; // 0-1 normalised
  final double size; // radius, normalised
  final Color color;
  final int type; // 0 circle  1 square  2 triangle  3 diamond

  const _ShapeItem({
    required this.x,
    required this.y,
    required this.size,
    required this.color,
    required this.type,
  });

  _ShapeItem copyWith({
    double? x,
    double? y,
    double? size,
    Color? color,
    int? type,
  }) =>
      _ShapeItem(
        x: x ?? this.x,
        y: y ?? this.y,
        size: size ?? this.size,
        color: color ?? this.color,
        type: type ?? this.type,
      );
}

class _Round {
  final List<_ShapeItem> original;
  final int diffIndex;
  final _ShapeItem modified; // replacement for original[diffIndex]

  const _Round({
    required this.original,
    required this.diffIndex,
    required this.modified,
  });
}

class _LevelEagleEyeState extends State<LevelEagleEye> {
  static const int _totalRounds = 5;
  static const int _maxLives = 3;

  late final List<_Round> _rounds;
  int _currentRound = 0;
  int _correctCount = 0;
  int _livesLeft = _maxLives;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _rounds = _generateRounds();
  }

  // ---------- scene generation ----------

  static const _palette = [
    Color(0xFFE53935), // red
    Color(0xFF1E88E5), // blue
    Color(0xFF43A047), // green
    Color(0xFFFFB300), // amber
    Color(0xFF8E24AA), // purple
    Color(0xFF00BCD4), // cyan
    Color(0xFFFF7043), // deep orange
    Color(0xFFAB47BC), // light purple
    Color(0xFF26A69A), // teal
    Color(0xFFFDD835), // yellow
  ];

  List<_Round> _generateRounds() {
    final rounds = <_Round>[];
    for (int r = 0; r < _totalRounds; r++) {
      final rng = Random(42 + r * 137);
      final count = 12 + r * 3; // 12 → 24

      final items = <_ShapeItem>[];
      for (int i = 0; i < count; i++) {
        items.add(_ShapeItem(
          x: 0.08 + rng.nextDouble() * 0.84,
          y: 0.08 + rng.nextDouble() * 0.84,
          size: 0.04 + rng.nextDouble() * 0.04,
          color: _palette[rng.nextInt(_palette.length)],
          type: rng.nextInt(4),
        ));
      }

      final diffIdx = rng.nextInt(count);
      final orig = items[diffIdx];
      _ShapeItem mod;

      switch (r % 4) {
        case 0: // colour change
          Color newCol;
          do {
            newCol = _palette[rng.nextInt(_palette.length)];
          } while (newCol == orig.color);
          mod = orig.copyWith(color: newCol);
          break;
        case 1: // shape type change
          mod = orig.copyWith(type: (orig.type + 1 + rng.nextInt(3)) % 4);
          break;
        case 2: // size change
          mod = orig.copyWith(size: orig.size * (rng.nextBool() ? 1.6 : 0.55));
          break;
        default: // position shift
          mod = orig.copyWith(
            x: (orig.x + 0.07 + rng.nextDouble() * 0.05).clamp(0.05, 0.95),
            y: (orig.y + 0.07 + rng.nextDouble() * 0.05).clamp(0.05, 0.95),
          );
      }

      rounds.add(_Round(original: items, diffIndex: diffIdx, modified: mod));
    }
    return rounds;
  }

  // ---------- interaction ----------

  void _onTapModified(Offset normalised) {
    if (_completed) return;
    final round = _rounds[_currentRound];
    final target = round.modified;
    final dx = normalised.dx - target.x;
    final dy = normalised.dy - target.y;
    final dist = sqrt(dx * dx + dy * dy);
    final hitRadius = target.size * 2.5 + 0.04; // generous tolerance

    if (dist <= hitRadius) {
      _correctCount++;
      if (_currentRound + 1 >= _totalRounds) {
        setState(() => _completed = true);
        widget.onComplete(LevelOutcome(score: 1, metrics: {
          'correct': _correctCount,
          'total': _totalRounds,
          'livesLost': _maxLives - _livesLeft,
        }));
      } else {
        setState(() => _currentRound++);
      }
    } else {
      // wrong tap — lose a life
      setState(() {
        _livesLeft--;
        if (_livesLeft <= 0) {
          _completed = true;
          widget.onComplete(LevelOutcome(score: 0, metrics: {
            'correct': _correctCount,
            'total': _totalRounds,
            'livesLost': _maxLives,
            'failedRound': _currentRound + 1,
          }));
        }
      });
    }
  }

  // ---------- build ----------

  @override
  Widget build(BuildContext context) {
    final round = _rounds[_currentRound];

    // build modified list
    final modItems = List<_ShapeItem>.from(round.original);
    modItems[round.diffIndex] = round.modified;

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            // HUD
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'round ${_currentRound + 1} / $_totalRounds',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'correct: $_correctCount',
                        style: const TextStyle(
                          color: NunuColors.successMain,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${'♥' * _livesLeft}${'♡' * (_maxLives - _livesLeft)}',
                        style: TextStyle(
                          color: _livesLeft <= 1
                              ? NunuColors.errorMain
                              : NunuColors.primaryMain,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),

            // original panel
            const Text(
              'reference',
              style: TextStyle(
                color: NunuColors.secondaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    color: const Color(0xFF0E0E24),
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _ScenePainter(items: round.original),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),

            // modified panel (tappable)
            const Text(
              'find the difference',
              style: TextStyle(
                color: NunuColors.primaryLight,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      return GestureDetector(
                        onTapUp: (details) {
                          final norm = Offset(
                            details.localPosition.dx / box.maxWidth,
                            details.localPosition.dy / box.maxHeight,
                          );
                          _onTapModified(norm);
                        },
                        child: Container(
                          color: const Color(0xFF0E0E24),
                          child: CustomPaint(
                            size: Size.infinite,
                            painter: _ScenePainter(items: modItems),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}

// ---------- painter ----------

class _ScenePainter extends CustomPainter {
  final List<_ShapeItem> items;
  const _ScenePainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    for (final item in items) {
      final cx = item.x * size.width;
      final cy = item.y * size.height;
      final r = item.size * min(size.width, size.height);
      final paint = Paint()..color = item.color;

      switch (item.type) {
        case 0: // circle
          canvas.drawCircle(Offset(cx, cy), r, paint);
          // highlight
          canvas.drawCircle(
            Offset(cx - r * 0.25, cy - r * 0.3),
            r * 0.3,
            Paint()..color = Colors.white.withValues(alpha: 0.3),
          );
          break;
        case 1: // square
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset(cx, cy), width: r * 2, height: r * 2),
              Radius.circular(r * 0.15),
            ),
            paint,
          );
          break;
        case 2: // triangle
          final path = Path()
            ..moveTo(cx, cy - r)
            ..lineTo(cx - r * 0.87, cy + r * 0.5)
            ..lineTo(cx + r * 0.87, cy + r * 0.5)
            ..close();
          canvas.drawPath(path, paint);
          break;
        case 3: // diamond
          final path = Path()
            ..moveTo(cx, cy - r * 1.2)
            ..lineTo(cx + r * 0.8, cy)
            ..lineTo(cx, cy + r * 1.2)
            ..lineTo(cx - r * 0.8, cy)
            ..close();
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ScenePainter old) =>
      !identical(items, old.items);
}
