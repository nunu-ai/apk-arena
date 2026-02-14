import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelRushHour extends LevelWidget {
  const LevelRushHour({super.key, required super.onComplete});

  @override
  State<LevelRushHour> createState() => _LevelRushHourState();
}

class _RHCar {
  final int id;
  int row, col;
  final int length;
  final bool horizontal;
  final Color color;
  final bool isTarget;

  _RHCar({
    required this.id,
    required this.row,
    required this.col,
    required this.length,
    required this.horizontal,
    required this.color,
    this.isTarget = false,
  });

  List<List<int>> get cells {
    return List.generate(length, (i) {
      return horizontal ? [row, col + i] : [row + i, col];
    });
  }
}

class _LevelRushHourState extends State<LevelRushHour> {
  static const int _gridSize = 6;

  late List<_RHCar> _cars;
  int? _selectedCarId;
  int _moves = 0;
  bool _done = false;

  // Predefined puzzle
  @override
  void initState() {
    super.initState();
    // Fixed puzzle - verified solvable (~9 moves)
    // Layout:
    //   A . B . . .
    //   A . B C C .
    //   R R B . . D
    //   . E . . . D
    //   . E F F . .
    //   . . . . G G
    _cars = [
      _RHCar(id: 0, row: 2, col: 0, length: 2, horizontal: true, color: NunuColors.errorMain, isTarget: true),
      _RHCar(id: 1, row: 0, col: 0, length: 2, horizontal: false, color: NunuColors.warningMain),
      _RHCar(id: 2, row: 0, col: 2, length: 3, horizontal: false, color: const Color(0xFF4FC3F7)),
      _RHCar(id: 3, row: 1, col: 3, length: 2, horizontal: true, color: NunuColors.successMain),
      _RHCar(id: 4, row: 2, col: 5, length: 2, horizontal: false, color: const Color(0xFF805CE5)),
      _RHCar(id: 5, row: 3, col: 1, length: 2, horizontal: false, color: const Color(0xFFE55CD8)),
      _RHCar(id: 6, row: 4, col: 2, length: 2, horizontal: true, color: const Color(0xFF00B8D9)),
      _RHCar(id: 7, row: 5, col: 4, length: 2, horizontal: true, color: const Color(0xFFBA68C8)),
    ];
  }

  bool _isOccupied(int row, int col, {int? excludeCarId}) {
    if (row < 0 || row >= _gridSize || col < 0 || col >= _gridSize) return true;
    for (final car in _cars) {
      if (car.id == excludeCarId) continue;
      for (final cell in car.cells) {
        if (cell[0] == row && cell[1] == col) return true;
      }
    }
    return false;
  }

  void _moveCar(int carId, int dr, int dc) {
    if (_done) return;
    final car = _cars.firstWhere((c) => c.id == carId);

    // Validate move direction matches orientation
    if (car.horizontal && dr != 0) return;
    if (!car.horizontal && dc != 0) return;

    // Check if move is valid
    final newRow = car.row + dr;
    final newCol = car.col + dc;

    // Check all cells of the car at new position
    for (int i = 0; i < car.length; i++) {
      final r = car.horizontal ? newRow : newRow + i;
      final c = car.horizontal ? newCol + i : newCol;
      if (_isOccupied(r, c, excludeCarId: carId)) return;
    }

    setState(() {
      car.row = newRow;
      car.col = newCol;
      _moves++;
      HapticFeedback.lightImpact();

      // Check win: target car reaches right edge
      if (car.isTarget && car.col + car.length >= _gridSize) {
        _done = true;
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete(true, metrics: {'moves': _moves});
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 16),
            Expanded(child: Center(child: _buildGrid())),
            _buildHint(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('moves', style: TextStyle(color: NunuColors.textSecondary, fontSize: 12)),
              Text('$_moves', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: NunuColors.errorMain,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                '→ exit',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = min(constraints.maxWidth - 24, constraints.maxHeight - 16);
        final cellSize = gridSize / _gridSize;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Grid background
            Container(
              width: gridSize,
              height: gridSize,
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: NunuColors.primaryDark.withOpacity(0.5),
                  width: 2,
                ),
              ),
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridSize,
                ),
                itemCount: _gridSize * _gridSize,
                itemBuilder: (_, i) {
                  return Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white.withOpacity(0.03),
                        width: 0.5,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Exit marker
            Positioned(
              top: 2 * cellSize + cellSize * 0.2,
              left: gridSize - 4,
              child: Container(
                width: 16,
                height: cellSize * 0.6,
                decoration: BoxDecoration(
                  color: NunuColors.successMain,
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(4)),
                ),
                child: const Icon(Icons.arrow_forward, color: Colors.white, size: 12),
              ),
            ),

            // Cars
            ..._cars.map((car) {
              final isSelected = _selectedCarId == car.id;
              return Positioned(
                left: car.col * cellSize + 3,
                top: car.row * cellSize + 3,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCarId = _selectedCarId == car.id ? null : car.id;
                    });
                  },
                  onPanUpdate: (details) {
                    if (car.horizontal) {
                      if (details.delta.dx > 5) _moveCar(car.id, 0, 1);
                      if (details.delta.dx < -5) _moveCar(car.id, 0, -1);
                    } else {
                      if (details.delta.dy > 5) _moveCar(car.id, 1, 0);
                      if (details.delta.dy < -5) _moveCar(car.id, -1, 0);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: car.horizontal
                        ? car.length * cellSize - 6
                        : cellSize - 6,
                    height: car.horizontal
                        ? cellSize - 6
                        : car.length * cellSize - 6,
                    decoration: BoxDecoration(
                      color: car.color,
                      borderRadius: BorderRadius.circular(8),
                      border: isSelected
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                      boxShadow: [
                        BoxShadow(
                          color: car.color.withOpacity(0.4),
                          blurRadius: isSelected ? 12 : 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: car.isTarget
                          ? const Icon(Icons.directions_car, color: Colors.white, size: 24)
                          : Icon(
                              car.horizontal
                                  ? Icons.swap_horiz
                                  : Icons.swap_vert,
                              color: Colors.white.withOpacity(0.6),
                              size: 18,
                            ),
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildHint() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        'drag cars to unblock the red car',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: NunuColors.textSecondary),
      ),
    );
  }
}
