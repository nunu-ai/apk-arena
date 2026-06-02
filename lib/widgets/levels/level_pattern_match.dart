import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelPatternMatch extends LevelWidget {
  const LevelPatternMatch({super.key, required super.onComplete});

  @override
  State<LevelPatternMatch> createState() => _LevelPatternMatchState();
}

class _LevelPatternMatchState extends State<LevelPatternMatch> {
  static const List<int> _stageGridSizes = [5, 8, 8, 8, 11];
  static const List<int> _seededMistakes = [2, 3, 4, 4, 5];
  static const List<double> _stageScoresByMistakes = [
    0.2,
    0.1,
    0.05,
    0.03,
    0.01,
  ];

  final Random _random = Random();

  int _stageIndex = 0;
  double _score = 0;
  bool _referenceSpent = false;
  final List<int> _stageMistakes = [];
  final List<int> _stagePercentages = [];
  late List<List<bool>> _targetPattern;
  late List<List<bool>> _draftPattern;
  late List<List<bool>> _playerPattern;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(() => LevelOutcome(
          score: _score.clamp(0.0, 1.0),
          metrics: {'stage_reached': _stageIndex + 1},
        ));
    _startStage();
  }

  int get _gridSize => _stageGridSizes[_stageIndex];

  bool get _needsManualReference => _stageIndex == 2;

  bool get _hasOneLookReference => _stageIndex == 3;

  void _startStage() {
    final size = _gridSize;
    _targetPattern = _generateRandomPattern(size);
    _draftPattern = _copyPattern(_targetPattern);
    _addSeededMistakes(_draftPattern, _seededMistakes[_stageIndex]);
    _playerPattern = _copyPattern(_draftPattern);
    _referenceSpent = false;
  }

  List<List<bool>> _generateRandomPattern(int size) {
    final density = 0.38 + _random.nextDouble() * 0.24;
    return List.generate(
      size,
      (_) => List.generate(size, (_) => _random.nextDouble() < density),
    );
  }

  List<List<bool>> _copyPattern(List<List<bool>> pattern) {
    return pattern.map((row) => List<bool>.from(row)).toList();
  }

  void _addSeededMistakes(List<List<bool>> pattern, int mistakeCount) {
    final cells = [
      for (var row = 0; row < pattern.length; row++)
        for (var col = 0; col < pattern.length; col++) Point(row, col),
    ]..shuffle(_random);

    for (final cell in cells.take(mistakeCount)) {
      pattern[cell.x][cell.y] = !pattern[cell.x][cell.y];
    }
  }

  void _toggleCell(int row, int col) {
    setState(() {
      _playerPattern[row][col] = !_playerPattern[row][col];
    });
  }

  int _countMistakes() {
    var mistakes = 0;
    for (int row = 0; row < _gridSize; row++) {
      for (int col = 0; col < _gridSize; col++) {
        if (_targetPattern[row][col] != _playerPattern[row][col]) {
          mistakes++;
        }
      }
    }
    return mistakes;
  }

  double _scoreForMistakes(int mistakes) {
    if (mistakes >= _stageScoresByMistakes.length) return 0;
    return _stageScoresByMistakes[mistakes];
  }

  void _onSubmit() {
    final mistakes = _countMistakes();
    final stageScore = _scoreForMistakes(mistakes);
    _score += stageScore;
    _stageMistakes.add(mistakes);
    _stagePercentages.add((stageScore * 100).round());

    if (_stageIndex == _stageGridSizes.length - 1) {
      widget.onComplete(
        LevelOutcome(
          score: _score,
          metrics: {
            'stage_mistakes': _stageMistakes,
            'stage_percentages': _stagePercentages,
            'stages': _stageGridSizes.length,
          },
        ),
      );
      return;
    }

    setState(() {
      _stageIndex++;
      _startStage();
    });
  }

  void _onResetDraft() {
    setState(() {
      _playerPattern = _copyPattern(_draftPattern);
    });
  }

  Future<void> _openReferencePopup() async {
    if (_hasOneLookReference) {
      setState(() {
        _referenceSpent = true;
      });
    }

    await showDialog<void>(
      context: context,
      barrierDismissible: !_hasOneLookReference,
      builder: (context) {
        return Dialog(
          backgroundColor: NunuColors.backgroundPaper,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: NunuColors.primaryDark.withValues(alpha: 0.6),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'reference',
                  style: TextStyle(
                    color: NunuColors.primaryLight,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildReferenceGrid(maxSize: 320, widthFraction: 1),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NunuColors.primaryMain,
                  ),
                  child: Text(_hasOneLookReference ? 'close forever' : 'close'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(
              stageText: '${_stageIndex + 1}/${_stageGridSizes.length}',
              trailing: Text(
                '${_gridSize}x$_gridSize',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildReferencePanel(),
                    const SizedBox(height: 20),
                    const Text(
                      'fix the submitted draft',
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(child: _buildPlayerGrid()),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _onResetDraft,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(
                                color: NunuColors.textSecondary,
                              ),
                              foregroundColor: NunuColors.textSecondary,
                            ),
                            child: const Text('reset'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: NunuColors.primaryMain,
                            ),
                            child: Text(
                              _stageIndex == _stageGridSizes.length - 1
                                  ? 'submit run'
                                  : 'submit stage',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReferencePanel() {
    final showToggle = _needsManualReference || _hasOneLookReference;
    final disabled = _hasOneLookReference && _referenceSpent;

    if (showToggle) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          OutlinedButton(
            onPressed: disabled ? null : _openReferencePopup,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: NunuColors.primaryDark),
              foregroundColor: NunuColors.primaryLight,
              disabledForegroundColor: NunuColors.textSecondary,
            ),
            child: Text(_referenceButtonLabel(disabled)),
          ),
        ],
      );
    }

    return Column(
      children: [
        const Text(
          'reference',
          style: TextStyle(color: NunuColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        _buildReferenceGrid(),
      ],
    );
  }

  String _referenceButtonLabel(bool disabled) {
    if (disabled) return 'reference spent';
    return 'open reference';
  }

  Widget _buildReferenceGrid({
    double maxSize = 160,
    double widthFraction = 0.5,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Reference grid is smaller - about 40% of available width
        final gridSize = min(constraints.maxWidth * widthFraction, maxSize);

        return SizedBox(
          key: ValueKey('reference-$_stageIndex'),
          width: gridSize,
          height: gridSize,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridSize,
              mainAxisSpacing: 2,
              crossAxisSpacing: 2,
            ),
            itemCount: _gridSize * _gridSize,
            itemBuilder: (context, index) {
              final row = index ~/ _gridSize;
              final col = index % _gridSize;
              final isFilled = _targetPattern[row][col];

              return Container(
                decoration: BoxDecoration(
                  color: isFilled
                      ? NunuColors.primaryMain
                      : NunuColors.backgroundPaper,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildPlayerGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gridSize = min(constraints.maxWidth, constraints.maxHeight);

        return Center(
          child: SizedBox(
            width: gridSize,
            height: gridSize,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _gridSize,
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
              ),
              itemCount: _gridSize * _gridSize,
              itemBuilder: (context, index) {
                final row = index ~/ _gridSize;
                final col = index % _gridSize;
                final isFilled = _playerPattern[row][col];

                return GestureDetector(
                  onTap: () => _toggleCell(row, col),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isFilled
                          ? NunuColors.secondaryMain
                          : NunuColors.backgroundPaper,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: isFilled
                            ? NunuColors.secondaryLight.withValues(alpha: 0.5)
                            : NunuColors.primaryDark.withValues(alpha: 0.3),
                        width: 1,
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
}
