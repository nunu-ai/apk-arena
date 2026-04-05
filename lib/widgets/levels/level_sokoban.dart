import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelSokoban extends LevelWidget {
  const LevelSokoban({super.key, required super.onComplete});

  @override
  State<LevelSokoban> createState() => _LevelSokobanState();
}

class _LevelSokobanState extends State<LevelSokoban> {
  // Level layout: # = wall, . = goal, @ = player, B = box, space = floor
  // + = player on goal, * = box on goal
  static const List<String> _levelTemplate = [
    '########',
    '# .  . #',
    '#  #.  #',
    '# B  B #',
    '#  B   #',
    '#   @  #',
    '########',
  ];

  late List<List<int>> _walls;    // 1 = wall
  late List<List<int>> _goals;    // 1 = goal
  late List<List<int>> _boxes;    // 1 = box
  late int _playerR, _playerC;
  late int _rows, _cols;
  int _moves = 0;
  bool _done = false;
  final _history = <_SokobanState>[];

  @override
  void initState() {
    super.initState();
    _rows = _levelTemplate.length;
    _cols = _levelTemplate[0].length;
    _walls = List.generate(_rows, (_) => List.filled(_cols, 0));
    _goals = List.generate(_rows, (_) => List.filled(_cols, 0));
    _boxes = List.generate(_rows, (_) => List.filled(_cols, 0));

    for (int r = 0; r < _rows; r++) {
      for (int c = 0; c < _cols; c++) {
        final ch = r < _levelTemplate.length && c < _levelTemplate[r].length
            ? _levelTemplate[r][c]
            : ' ';
        switch (ch) {
          case '#':
            _walls[r][c] = 1;
            break;
          case '.':
            _goals[r][c] = 1;
            break;
          case '@':
            _playerR = r;
            _playerC = c;
            break;
          case '+':
            _playerR = r;
            _playerC = c;
            _goals[r][c] = 1;
            break;
          case 'B':
            _boxes[r][c] = 1;
            break;
          case '*':
            _boxes[r][c] = 1;
            _goals[r][c] = 1;
            break;
        }
      }
    }
  }

  void _move(int dr, int dc) {
    if (_done) return;
    final nr = _playerR + dr, nc = _playerC + dc;
    if (nr < 0 || nr >= _rows || nc < 0 || nc >= _cols) return;
    if (_walls[nr][nc] == 1) return;

    setState(() {
      if (_boxes[nr][nc] == 1) {
        // Try to push box
        final br = nr + dr, bc = nc + dc;
        if (br < 0 || br >= _rows || bc < 0 || bc >= _cols) return;
        if (_walls[br][bc] == 1 || _boxes[br][bc] == 1) return;

        // Save state for undo
        _history.add(_SokobanState(
          _playerR, _playerC,
          List.generate(_rows, (r) => List.of(_boxes[r])),
        ));

        _boxes[nr][nc] = 0;
        _boxes[br][bc] = 1;
        _playerR = nr;
        _playerC = nc;
        _moves++;
        HapticFeedback.lightImpact();
      } else {
        _history.add(_SokobanState(
          _playerR, _playerC,
          List.generate(_rows, (r) => List.of(_boxes[r])),
        ));
        _playerR = nr;
        _playerC = nc;
        _moves++;
      }

      // Check win
      bool allOnGoal = true;
      for (int r = 0; r < _rows && allOnGoal; r++) {
        for (int c = 0; c < _cols && allOnGoal; c++) {
          if (_goals[r][c] == 1 && _boxes[r][c] != 1) allOnGoal = false;
        }
      }
      if (allOnGoal) {
        _done = true;
        HapticFeedback.mediumImpact();
        Future.delayed(const Duration(milliseconds: 500), () {
          widget.onComplete(LevelOutcome(score: 1, metrics: {'moves': _moves}));
        });
      }
    });
  }

  void _undo() {
    if (_history.isEmpty || _done) return;
    setState(() {
      final prev = _history.removeLast();
      _playerR = prev.playerR;
      _playerC = prev.playerC;
      _boxes = prev.boxes;
      _moves++;
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
            const SizedBox(height: 12),
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
              const Text('moves', style: TextStyle(color: NunuColors.textSecondary, fontSize: 12)),
              Text('$_moves', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            ],
          ),
          GestureDetector(
            onTap: _undo,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: NunuColors.backgroundPaper,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.undo, color: NunuColors.primaryMain, size: 18),
                  SizedBox(width: 4),
                  Text('undo', style: TextStyle(color: NunuColors.primaryMain, fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellSize = (constraints.maxWidth - 24).clamp(0.0, constraints.maxHeight - 8) /
            (_rows > _cols ? _rows : _cols);

        return SizedBox(
          width: cellSize * _cols,
          height: cellSize * _rows,
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _cols,
            ),
            itemCount: _rows * _cols,
            itemBuilder: (_, i) {
              final r = i ~/ _cols, c = i % _cols;
              return _buildCell(r, c, cellSize);
            },
          ),
        );
      },
    );
  }

  Widget _buildCell(int r, int c, double size) {
    final isWall = _walls[r][c] == 1;
    final isGoal = _goals[r][c] == 1;
    final isBox = _boxes[r][c] == 1;
    final isPlayer = _playerR == r && _playerC == c;
    final isBoxOnGoal = isBox && isGoal;

    Color bg;
    if (isWall) {
      bg = const Color(0xFF2A2A4A);
    } else if (isGoal) {
      bg = NunuColors.successMain.withOpacity(0.1);
    } else {
      bg = NunuColors.backgroundPaper.withOpacity(0.2);
    }

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: isWall
            ? null
            : Border.all(color: Colors.white.withOpacity(0.04), width: 0.5),
      ),
      child: Center(
        child: isPlayer
            ? Container(
                width: size * 0.65,
                height: size * 0.65,
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: NunuColors.primaryMain.withOpacity(0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.person, color: Colors.white, size: 20),
              )
            : isBox
                ? Container(
                    width: size * 0.7,
                    height: size * 0.7,
                    decoration: BoxDecoration(
                      color: isBoxOnGoal ? NunuColors.successMain : NunuColors.warningMain,
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: (isBoxOnGoal ? NunuColors.successMain : NunuColors.warningMain)
                              .withOpacity(0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Icon(
                      isBoxOnGoal ? Icons.check : Icons.inventory_2,
                      color: Colors.white,
                      size: 18,
                    ),
                  )
                : isGoal
                    ? Container(
                        width: size * 0.3,
                        height: size * 0.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: NunuColors.successMain.withOpacity(0.6),
                            width: 2,
                          ),
                        ),
                      )
                    : isWall
                        ? Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF3A3A5A),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          )
                        : null,
      ),
    );
  }

  Widget _buildControls() {
    Widget btn(IconData icon, int dr, int dc) {
      return GestureDetector(
        onTap: () => _move(dr, dc),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NunuColors.primaryDark.withOpacity(0.5)),
          ),
          child: Icon(icon, color: NunuColors.primaryMain, size: 28),
        ),
      );
    }

    return Column(
      children: [
        btn(Icons.arrow_upward, -1, 0),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            btn(Icons.arrow_back, 0, -1),
            const SizedBox(width: 64),
            btn(Icons.arrow_forward, 0, 1),
          ],
        ),
        const SizedBox(height: 4),
        btn(Icons.arrow_downward, 1, 0),
      ],
    );
  }
}

class _SokobanState {
  final int playerR, playerC;
  final List<List<int>> boxes;
  _SokobanState(this.playerR, this.playerC, this.boxes);
}
