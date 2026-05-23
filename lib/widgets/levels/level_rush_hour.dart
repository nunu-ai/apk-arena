import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelRushHour extends LevelWidget {
  const LevelRushHour({super.key, required super.onComplete});

  @override
  State<LevelRushHour> createState() => _LevelRushHourState();
}

class _RushHourStage {
  final String label;
  final int optimalMoves;
  final List<_RushHourVehicleSeed> vehicles;

  const _RushHourStage({
    required this.label,
    required this.optimalMoves,
    required this.vehicles,
  });
}

class _RushHourVehicleSeed {
  final int row;
  final int col;
  final int length;
  final bool horizontal;
  final bool isTarget;

  const _RushHourVehicleSeed({
    required this.row,
    required this.col,
    required this.length,
    required this.horizontal,
    this.isTarget = false,
  });
}

class _RushHourVehicle {
  final int id;
  int row;
  int col;
  final int length;
  final bool horizontal;
  final bool isTarget;
  final Color color;

  _RushHourVehicle({
    required this.id,
    required this.row,
    required this.col,
    required this.length,
    required this.horizontal,
    required this.isTarget,
    required this.color,
  });

  Iterable<Point<int>> get cells sync* {
    for (int i = 0; i < length; i++) {
      yield horizontal ? Point<int>(row, col + i) : Point<int>(row + i, col);
    }
  }
}

class _LevelRushHourState extends State<LevelRushHour> {
  static const int _gridSize = 6;

  static const List<_RushHourStage> _stages = [
    _RushHourStage(
      label: 'deck-1',
      optimalMoves: 8,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 0, col: 5, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 4, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 5, col: 2, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 3, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 0, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 4, col: 0, length: 2, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-2',
      optimalMoves: 9,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 3, col: 5, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 2, col: 3, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 5, col: 2, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 3, col: 1, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 1, length: 2, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-3',
      optimalMoves: 10,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 0, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 0, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 2, col: 5, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 4, col: 5, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 2, col: 4, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 2, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 3, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 1, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 2, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 1, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 0, length: 3, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-4',
      optimalMoves: 13,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 3, col: 3, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 5, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 3, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 5, col: 2, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 0, col: 1, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 3, col: 2, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 0, length: 3, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-5',
      optimalMoves: 17,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 2, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 1, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 2, col: 5, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 2, col: 4, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 4, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 3, col: 2, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 0, col: 2, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 4, col: 2, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 2, col: 0, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 5, col: 0, length: 2, horizontal: true),
      ],
    ),
    _RushHourStage(
      label: 'deck-6',
      optimalMoves: 23,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 2, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 0, col: 3, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 4, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 4, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 2, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 1, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 0, col: 2, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-7',
      optimalMoves: 29,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 5, col: 3, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 0, col: 3, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 1, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 0, col: 2, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 0, length: 3, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-8',
      optimalMoves: 32,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 0, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 5, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 4, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 5, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 2, col: 4, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 1, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 3, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 2, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 1, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 2, col: 0, length: 3, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-9',
      optimalMoves: 40,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 0, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 1, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 3, col: 5, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 3, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 2, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 0, col: 3, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 5, col: 2, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 0, col: 0, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 2, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 1, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 5, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 3, col: 0, length: 2, horizontal: false),
      ],
    ),
    _RushHourStage(
      label: 'deck-10',
      optimalMoves: 51,
      vehicles: [
        _RushHourVehicleSeed(row: 2, col: 1, length: 2, horizontal: true, isTarget: true),
        _RushHourVehicleSeed(row: 0, col: 3, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 4, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 2, col: 5, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 5, col: 3, length: 3, horizontal: true),
        _RushHourVehicleSeed(row: 3, col: 3, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 1, col: 3, length: 2, horizontal: false),
        _RushHourVehicleSeed(row: 3, col: 2, length: 3, horizontal: false),
        _RushHourVehicleSeed(row: 0, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 4, col: 0, length: 2, horizontal: true),
        _RushHourVehicleSeed(row: 2, col: 0, length: 2, horizontal: false),
      ],
    ),
  ];

  final List<int> _stageMoves = [];

  late List<_RushHourVehicle> _vehicles;
  int _stageIndex = 0;
  int _movesThisStage = 0;
  int _totalMoves = 0;
  int? _selectedVehicleId;
  int? _dragVehicleId;
  double _dragOffset = 0;
  bool _transitioning = false;

  @override
  void initState() {
    super.initState();
    widget.registerTimeoutBuilder(_buildOutcome);
    _validateStages();
    _loadStage(0);
  }

  @override
  void dispose() {
    widget.clearTimeoutBuilder();
    super.dispose();
  }

  _RushHourStage get _stage => _stages[_stageIndex];

  void _validateStages() {
    for (final stage in _stages) {
      final occupied = <String>{};
      for (final vehicle in stage.vehicles) {
        for (int i = 0; i < vehicle.length; i++) {
          final row = vehicle.horizontal ? vehicle.row : vehicle.row + i;
          final col = vehicle.horizontal ? vehicle.col + i : vehicle.col;
          if (row < 0 || row >= _gridSize || col < 0 || col >= _gridSize) {
            throw StateError('rush hour stage ${stage.label} has out-of-bounds vehicle data');
          }
          final key = '$row,$col';
          if (!occupied.add(key)) {
            throw StateError('rush hour stage ${stage.label} has overlapping vehicle data');
          }
        }
      }
    }
  }

  void _loadStage(int index) {
    final palette = <Color>[
      NunuColors.warningMain,
      NunuColors.infoMain,
      NunuColors.secondaryMain,
      NunuColors.successMain,
      NunuColors.primaryMain,
      NunuColors.secondaryLight,
      NunuColors.errorLight,
      const Color(0xFF5CD6FF),
      const Color(0xFFF973C5),
      const Color(0xFF8BE07D),
      const Color(0xFFFFD166),
      const Color(0xFF9B87F5),
      const Color(0xFF59C3C3),
    ];

    final seeds = _stages[index].vehicles;
    _vehicles = List.generate(seeds.length, (i) {
      final seed = seeds[i];
      return _RushHourVehicle(
        id: i,
        row: seed.row,
        col: seed.col,
        length: seed.length,
        horizontal: seed.horizontal,
        isTarget: seed.isTarget,
        color: seed.isTarget ? NunuColors.errorMain : palette[max(0, i - 1) % palette.length],
      );
    });
    _stageIndex = index;
    _movesThisStage = 0;
    _selectedVehicleId = null;
    _dragVehicleId = null;
    _dragOffset = 0;
  }

  bool _occupied(int row, int col, {int? excluding}) {
    if (row < 0 || row >= _gridSize || col < 0 || col >= _gridSize) {
      return true;
    }
    for (final vehicle in _vehicles) {
      if (vehicle.id == excluding) {
        continue;
      }
      for (final cell in vehicle.cells) {
        if (cell.x == row && cell.y == col) {
          return true;
        }
      }
    }
    return false;
  }

  bool _canMove(_RushHourVehicle vehicle, int delta) {
    if (delta == 0) {
      return false;
    }
    final nextRow = vehicle.row + (vehicle.horizontal ? 0 : delta);
    final nextCol = vehicle.col + (vehicle.horizontal ? delta : 0);

    for (int i = 0; i < vehicle.length; i++) {
      final row = vehicle.horizontal ? nextRow : nextRow + i;
      final col = vehicle.horizontal ? nextCol + i : nextCol;
      if (_occupied(row, col, excluding: vehicle.id)) {
        return false;
      }
    }
    return true;
  }

  void _moveVehicle(int vehicleId, int delta) {
    if (_transitioning || delta == 0) {
      return;
    }
    final vehicle = _vehicles.firstWhere((item) => item.id == vehicleId);
    if (!_canMove(vehicle, delta)) {
      return;
    }

    setState(() {
      if (vehicle.horizontal) {
        vehicle.col += delta;
      } else {
        vehicle.row += delta;
      }
      _selectedVehicleId = vehicleId;
      _movesThisStage++;
      _totalMoves++;
      HapticFeedback.selectionClick();
    });

    if (vehicle.isTarget && vehicle.col + vehicle.length == _gridSize) {
      _completeStage();
    }
  }

  void _completeStage() {
    if (_transitioning) {
      return;
    }
    _transitioning = true;
    _stageMoves.add(_movesThisStage);
    HapticFeedback.mediumImpact();

    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted) {
        return;
      }
      if (_stageIndex == _stages.length - 1) {
        _finishRun();
        return;
      }
      setState(() {
        _loadStage(_stageIndex + 1);
        _transitioning = false;
      });
    });
  }

  void _finishRun() {
    widget.onComplete(_buildOutcome());
  }

  LevelOutcome _buildOutcome() {
    final cleared = _stageMoves.length;
    final perfectStages = List.generate(
      cleared,
      (i) => _stageMoves[i] == _stages[i].optimalMoves ? 1 : 0,
    ).fold<int>(0, (sum, value) => sum + value);
    final parOverrun = List.generate(
      cleared,
      (i) => max(0, _stageMoves[i] - _stages[i].optimalMoves),
    ).fold<int>(0, (sum, value) => sum + value);
    final score = List.generate(_stages.length, (i) {
      if (i >= cleared) {
        return 0.0;
      }
      final optimal = _stages[i].optimalMoves.toDouble();
      final actual = _stageMoves[i].toDouble();
      return min(1.0, optimal / actual);
    }).fold<double>(0, (sum, value) => sum + value) /
        _stages.length;

    return LevelOutcome(
      score: score,
      metrics: {
        'stages_cleared': cleared,
        'total_moves': _totalMoves,
        'par_overrun': parOverrun,
        'perfect_stages': perfectStages,
      },
    );
  }

  void _resetStage() {
    if (_transitioning) {
      return;
    }
    setState(() {
      _loadStage(_stageIndex);
    });
  }

  void _handleDragStart(int vehicleId) {
    _selectedVehicleId = vehicleId;
    _dragVehicleId = vehicleId;
    _dragOffset = 0;
  }

  void _handleDragUpdate(_RushHourVehicle vehicle, DragUpdateDetails details, double cellSize) {
    if (_transitioning) {
      return;
    }
    if (_dragVehicleId != vehicle.id) {
      _handleDragStart(vehicle.id);
    }

    _dragOffset += vehicle.horizontal ? details.delta.dx : details.delta.dy;
    while (_dragOffset.abs() >= cellSize * 0.55) {
      final step = _dragOffset.isNegative ? -1 : 1;
      final movedBefore = _movesThisStage;
      _moveVehicle(vehicle.id, step);
      if (_movesThisStage == movedBefore) {
        _dragOffset = 0;
        return;
      }
      _dragOffset -= cellSize * 0.55 * step;
    }
  }

  void _handleDragEnd() {
    _dragVehicleId = null;
    _dragOffset = 0;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _stageMoves.length / _stages.length;

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(progress),
            const SizedBox(height: 12),
            _buildStageStrip(),
            const SizedBox(height: 16),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBoard(),
              ),
            ),
            const SizedBox(height: 16),
            _buildFooter(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(double progress) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_stage.label} / par ${_stage.optimalMoves}',
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: NunuColors.backgroundPaper,
              valueColor: const AlwaysStoppedAnimation(NunuColors.primaryMain),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStageStrip() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final cleared = index < _stageMoves.length;
          final current = index == _stageIndex;
          final moveCount = cleared ? _stageMoves[index] : null;
          final optimal = _stages[index].optimalMoves;
          final hitPar = moveCount == optimal;

          final Color borderColor;
          final Color fillColor;
          if (cleared && hitPar) {
            borderColor = NunuColors.successMain;
            fillColor = NunuColors.successMain.withOpacity(0.16);
          } else if (cleared) {
            borderColor = NunuColors.warningMain;
            fillColor = NunuColors.warningMain.withOpacity(0.12);
          } else if (current) {
            borderColor = NunuColors.primaryMain;
            fillColor = NunuColors.primaryMain.withOpacity(0.12);
          } else {
            borderColor = Colors.white.withOpacity(0.12);
            fillColor = NunuColors.backgroundPaper;
          }

          return Container(
            width: 58,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fillColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: _stages.length,
      ),
    );
  }

  Widget _buildBoard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = boardSize / _gridSize;

        return Center(
          child: SizedBox(
            width: boardSize,
            height: boardSize,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: NunuColors.backgroundPaper,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NunuColors.secondaryMain.withOpacity(0.35),
                      width: 2,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _gridSize,
                    ),
                    itemCount: _gridSize * _gridSize,
                    itemBuilder: (_, index) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white.withOpacity(0.04),
                            width: 0.5,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Positioned(
                  top: cellSize * 2.18,
                  right: -12,
                  child: Container(
                    width: 24,
                    height: cellSize * 0.64,
                    decoration: BoxDecoration(
                      color: NunuColors.successMain,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                for (final vehicle in _vehicles) _buildVehicle(vehicle, cellSize),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildVehicle(_RushHourVehicle vehicle, double cellSize) {
    final isSelected = _selectedVehicleId == vehicle.id;
    final width = vehicle.horizontal ? vehicle.length * cellSize - 6 : cellSize - 6;
    final height = vehicle.horizontal ? cellSize - 6 : vehicle.length * cellSize - 6;

    return Positioned(
      left: vehicle.col * cellSize + 3,
      top: vehicle.row * cellSize + 3,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedVehicleId = vehicle.id;
          });
        },
        onPanStart: (_) {
          setState(() {
            _handleDragStart(vehicle.id);
          });
        },
        onPanUpdate: (details) => _handleDragUpdate(vehicle, details, cellSize),
        onPanEnd: (_) => _handleDragEnd(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: vehicle.color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.12),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: vehicle.color.withOpacity(isSelected ? 0.45 : 0.25),
                blurRadius: isSelected ? 14 : 6,
              ),
            ],
          ),
          child: Center(
            child: vehicle.isTarget
                ? const Icon(Icons.directions_car_filled, color: Colors.white, size: 22)
                : Icon(
                    vehicle.horizontal ? Icons.swap_horiz : Icons.swap_vert,
                    color: Colors.white.withOpacity(0.75),
                    size: 18,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.route,
                    color: NunuColors.primaryLight,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$_movesThisStage',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'total $_totalMoves',
                    style: const TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          _IconControl(
            icon: Icons.refresh,
            enabled: !_transitioning,
            onTap: _resetStage,
          ),
        ],
      ),
    );
  }
}

class _IconControl extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _IconControl({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? NunuColors.backgroundPaper : NunuColors.backgroundPaper.withOpacity(0.45),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? NunuColors.primaryDark.withOpacity(0.6) : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : NunuColors.textSecondary.withOpacity(0.55),
        ),
      ),
    );
  }
}
