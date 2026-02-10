import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSnake extends LevelWidget {
  const LevelSnake({super.key, required super.onComplete});

  @override
  State<LevelSnake> createState() => _LevelSnakeState();
}

class _LevelSnakeState extends State<LevelSnake> {
  static const int _gridSize = 15;
  static const int _targetLength = 15;
  static const Duration _tickDuration = Duration(milliseconds: 300);

  final List<List<int>> _snake = [];
  List<int> _food = [0, 0];
  int _dx = 1, _dy = 0;
  int _nextDx = 1, _nextDy = 0;
  Timer? _timer;
  bool _gameOver = false;
  bool _started = false;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    final mid = _gridSize ~/ 2;
    _snake.addAll([
      [mid, mid],
      [mid, mid - 1],
      [mid, mid - 2],
    ]);
    _spawnFood();
  }

  void _startGame() {
    if (_started) return;
    _started = true;
    _timer = Timer.periodic(_tickDuration, (_) => _tick());
  }

  void _spawnFood() {
    while (true) {
      final r = _rng.nextInt(_gridSize);
      final c = _rng.nextInt(_gridSize);
      if (!_snake.any((s) => s[0] == r && s[1] == c)) {
        _food = [r, c];
        break;
      }
    }
  }

  void _tick() {
    if (_gameOver || !mounted) return;

    setState(() {
      _dx = _nextDx;
      _dy = _nextDy;

      final head = _snake.first;
      final newHead = [head[0] + _dy, head[1] + _dx];

      // Wall collision
      if (newHead[0] < 0 ||
          newHead[0] >= _gridSize ||
          newHead[1] < 0 ||
          newHead[1] >= _gridSize) {
        _endGame(false);
        return;
      }

      // Self collision
      if (_snake.any((s) => s[0] == newHead[0] && s[1] == newHead[1])) {
        _endGame(false);
        return;
      }

      _snake.insert(0, newHead);

      // Eat food?
      if (newHead[0] == _food[0] && newHead[1] == _food[1]) {
        HapticFeedback.lightImpact();
        if (_snake.length >= _targetLength) {
          _endGame(true);
          return;
        }
        _spawnFood();
      } else {
        _snake.removeLast();
      }
    });
  }

  void _endGame(bool won) {
    _gameOver = true;
    _timer?.cancel();
    if (won) HapticFeedback.mediumImpact();
    else HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 600), () {
      widget.onComplete(won);
    });
  }

  void _setDirection(int dx, int dy) {
    // Prevent 180-degree turns
    if (_dx == -dx && _dy == -dy) return;
    _nextDx = dx;
    _nextDy = dy;
    _startGame();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: Center(child: _buildGrid())),
            const SizedBox(height: 8),
            _buildControls(),
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
              const Text(
                'length',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '${_snake.length}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.primaryMain,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'target',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              const Text(
                '$_targetLength',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: NunuColors.secondaryMain,
                ),
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
        final cellSize = min(
          (constraints.maxWidth - 16) / _gridSize,
          (constraints.maxHeight - 8) / _gridSize,
        );

        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: SizedBox(
              width: cellSize * _gridSize,
              height: cellSize * _gridSize,
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _gridSize,
                ),
                itemCount: _gridSize * _gridSize,
                itemBuilder: (_, i) {
                  final r = i ~/ _gridSize, c = i % _gridSize;
                  final isHead =
                      _snake.isNotEmpty && _snake.first[0] == r && _snake.first[1] == c;
                  final snakeIndex = _snake.indexWhere((s) => s[0] == r && s[1] == c);
                  final isSnake = snakeIndex >= 0;
                  final isFood = _food[0] == r && _food[1] == c;

                  Color bg;
                  if (isHead) {
                    bg = NunuColors.primaryMain;
                  } else if (isSnake) {
                    // Gradient from primary to secondary along body
                    final t = snakeIndex / max(_snake.length - 1, 1);
                    bg = Color.lerp(NunuColors.primaryLight, NunuColors.secondaryMain, t)!;
                  } else if (isFood) {
                    bg = NunuColors.warningMain;
                  } else {
                    bg = (r + c) % 2 == 0
                        ? NunuColors.backgroundDefault
                        : NunuColors.backgroundPaper.withOpacity(0.3);
                  }

                  return Container(
                    decoration: BoxDecoration(
                      color: bg,
                      borderRadius: isHead
                          ? BorderRadius.circular(cellSize * 0.3)
                          : isFood
                              ? BorderRadius.circular(cellSize * 0.5)
                              : null,
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildControls() {
    Widget btn(IconData icon, int dx, int dy) {
      return GestureDetector(
        onTap: () => _setDirection(dx, dy),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5)),
          ),
          child: Icon(icon, color: NunuColors.primaryMain, size: 32),
        ),
      );
    }

    return Column(
      children: [
        btn(Icons.arrow_upward, 0, -1),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btn(Icons.arrow_back, -1, 0),
            const SizedBox(width: 68),
            btn(Icons.arrow_forward, 1, 0),
          ],
        ),
        const SizedBox(height: 4),
        btn(Icons.arrow_downward, 0, 1),
      ],
    );
  }
}
