import 'dart:async';
import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';

class LevelScrabble extends LevelWidget {
  const LevelScrabble({super.key, required super.onComplete});

  @override
  State<LevelScrabble> createState() => _LevelScrabbleState();
}

class _LevelScrabbleState extends State<LevelScrabble> {
  static const int _size = 15;
  static const int _rackSize = 7;
  static const int _targetScore = 450;
  static const Duration _runDuration = Duration(minutes: 30);

  final Random _rng = SeedService.instance.createRandom();
  final TransformationController _boardController = TransformationController();
  final List<List<_PlacedTile?>> _board = List.generate(
    _size,
    (_) => List<_PlacedTile?>.filled(_size, null),
  );

  Set<String> _dictionary = {};
  List<String> _bag = [];
  List<_RackTile> _playerRack = [];
  Size _boardViewportSize = Size.zero;
  Offset _boardOrigin = Offset.zero;
  double _boardPixelSize = 0;
  Timer? _ticker;
  Duration _timeLeft = _runDuration;
  int _nextTileId = 0;
  int _playerScore = 0;
  int _turns = 0;
  bool _loading = true;
  bool _completed = false;
  String _message = 'loading dictionary...';

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(_buildOutcome);
    _start();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    widget.clearPartialScoreGetter();
    _boardController.dispose();
    super.dispose();
  }

  Future<void> _start() async {
    await _loadDictionary();
    _bag = _buildBag()..shuffle(_rng);
    _playerRack = _drawTiles(_rackSize);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _completed) return;
      setState(() {
        _timeLeft -= const Duration(seconds: 1);
        if (_timeLeft <= Duration.zero) {
          _timeLeft = Duration.zero;
          _finish();
        }
      });
    });
    if (!mounted) return;
    setState(() {
      _loading = false;
      _message = 'your move: drag tiles to the board and submit a word';
    });
  }

  Future<void> _loadDictionary() async {
    final raw = await rootBundle.loadString('assets/words/enable1.txt');
    final words = raw
        .split(RegExp(r'\s+'))
        .map((word) => word.trim().toUpperCase())
        .where((word) => RegExp(r'^[A-Z]{2,15}$').hasMatch(word))
        .toSet();

    _dictionary = words;
  }

  List<String> _buildBag() {
    const distribution = {
      'A': 9,
      'B': 2,
      'C': 2,
      'D': 4,
      'E': 12,
      'F': 2,
      'G': 3,
      'H': 2,
      'I': 9,
      'J': 1,
      'K': 1,
      'L': 4,
      'M': 2,
      'N': 6,
      'O': 8,
      'P': 2,
      'Q': 1,
      'R': 6,
      'S': 4,
      'T': 6,
      'U': 4,
      'V': 2,
      'W': 2,
      'X': 1,
      'Y': 2,
      'Z': 1,
    };
    return [
      for (final entry in distribution.entries)
        for (var i = 0; i < entry.value; i++) entry.key,
    ];
  }

  List<_RackTile> _drawTiles(int count) {
    final tiles = <_RackTile>[];
    while (tiles.length < count && _bag.isNotEmpty) {
      tiles.add(_RackTile(id: _nextTileId++, letter: _bag.removeLast()));
    }
    return tiles;
  }

  List<_CellPos> get _pendingCells {
    final cells = <_CellPos>[];
    for (var r = 0; r < _size; r++) {
      for (var c = 0; c < _size; c++) {
        final tile = _board[r][c];
        if (tile != null && !tile.locked) cells.add(_CellPos(r, c));
      }
    }
    return cells;
  }

  void _placeFromRack(int row, int col, _DragTile drag) {
    if (_completed || _board[row][col] != null) return;
    final rackIndex = _playerRack.indexWhere((tile) => tile.id == drag.id);
    if (rackIndex == -1) return;
    final shouldZoom = _pendingCells.isEmpty;

    setState(() {
      _playerRack.removeAt(rackIndex);
      _board[row][col] = _PlacedTile(
        id: drag.id,
        letter: drag.letter,
        locked: false,
      );
      _message = 'placed ${drag.letter}; submit when your word is ready';
    });
    if (shouldZoom) _zoomToCell(row, col);
    HapticFeedback.selectionClick();
  }

  void _movePendingTile(int row, int col, _DragTile drag) {
    if (_completed ||
        drag.row == null ||
        drag.col == null ||
        _board[row][col] != null) {
      return;
    }
    final source = _board[drag.row!][drag.col!];
    if (source == null || source.locked) return;

    setState(() {
      _board[drag.row!][drag.col!] = null;
      _board[row][col] = source;
      _message = 'moved ${drag.letter}';
    });
    HapticFeedback.selectionClick();
  }

  void _returnPendingTile(int row, int col) {
    final tile = _board[row][col];
    if (tile == null || tile.locked) return;
    setState(() {
      _board[row][col] = null;
      _playerRack.add(_RackTile(id: tile.id, letter: tile.letter));
      _message = 'returned ${tile.letter} to rack';
    });
  }

  void _resetPendingTiles() {
    final pending = _pendingCells;
    if (pending.isEmpty) return;
    setState(() {
      for (final cell in pending) {
        final tile = _board[cell.row][cell.col]!;
        _playerRack.add(_RackTile(id: tile.id, letter: tile.letter));
        _board[cell.row][cell.col] = null;
      }
      _message = 'move reset';
    });
  }

  void _reshuffleRack() {
    final pending = _pendingCells;
    if (_playerRack.isEmpty && pending.isEmpty) {
      setState(() => _message = 'no tiles to reshuffle');
      return;
    }

    setState(() {
      for (final cell in pending) {
        final tile = _board[cell.row][cell.col]!;
        _playerRack.add(_RackTile(id: tile.id, letter: tile.letter));
        _board[cell.row][cell.col] = null;
      }

      _bag.addAll(_playerRack.map((tile) => tile.letter));
      _bag.shuffle(_rng);
      _playerRack = _drawTiles(_rackSize);
      _playerScore = max(0, _playerScore - 1);
      _message = 'rack reshuffled (-1 point)';
    });
    HapticFeedback.mediumImpact();
  }

  Future<void> _confirmReshuffle() async {
    if (_completed) return;
    final shouldReshuffle = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('reshuffle rack?'),
          content: const Text(
            'return your current move, draw new letters, and lose 1 point?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('reshuffle'),
            ),
          ],
        );
      },
    );
    if (shouldReshuffle == true && mounted) _reshuffleRack();
  }

  void _submitPlayerMove() {
    if (_loading || _completed) return;
    final pending = _pendingCells;
    if (pending.isEmpty) {
      setState(() => _message = 'place at least one tile first');
      return;
    }

    final result = _evaluateMove(_board, pending);
    if (!result.valid) {
      setState(() => _message = result.error ?? 'not a legal word');
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      for (final cell in pending) {
        _board[cell.row][cell.col] = _board[cell.row][cell.col]!.lockedCopy();
      }
      _playerScore += result.score;
      _turns++;
      _playerRack.addAll(_drawTiles(_rackSize - _playerRack.length));
      _message = '+${result.score}: ${result.words.join(', ')}';
    });
    HapticFeedback.mediumImpact();
    _checkGameOver();
  }

  void _checkGameOver() {
    if (_bag.isEmpty && _playerRack.isEmpty) {
      _finish();
    }
  }

  _MoveResult _evaluateMove(
    List<List<_PlacedTile?>> board,
    List<_CellPos> placed,
  ) {
    if (placed.isEmpty) return _MoveResult.invalid('place at least one tile');

    final rows = placed.map((cell) => cell.row).toSet();
    final cols = placed.map((cell) => cell.col).toSet();
    if (rows.length > 1 && cols.length > 1) {
      return _MoveResult.invalid('tiles must be in one row or one column');
    }

    final direction = _resolveDirection(board, placed);
    final mainWord = _wordAt(board, placed.first, direction);
    if (mainWord.cells.length < 2) {
      return _MoveResult.invalid('make a word with at least two letters');
    }

    for (final cell in mainWord.cells) {
      if (board[cell.row][cell.col] == null) {
        return _MoveResult.invalid('words cannot have gaps');
      }
    }

    final firstMove = !_hasAnyLockedTiles(board);
    if (firstMove && !mainWord.cells.contains(const _CellPos(7, 7))) {
      return _MoveResult.invalid('first word must cross the center star');
    }
    if (!firstMove && !_touchesLockedTile(board, placed, mainWord.cells)) {
      return _MoveResult.invalid('new words must connect to the board');
    }

    final words = <_ScoredWord>[mainWord];
    final crossDirection = direction == _Direction.horizontal
        ? _Direction.vertical
        : _Direction.horizontal;
    for (final cell in placed) {
      final cross = _wordAt(board, cell, crossDirection);
      if (cross.cells.length > 1) words.add(cross);
    }

    final unique = <String, _ScoredWord>{};
    for (final word in words) {
      unique[word.key] = word;
    }

    var score = 0;
    final wordTexts = <String>[];
    for (final word in unique.values) {
      if (!_dictionary.contains(word.text)) {
        return _MoveResult.invalid('"${word.text}" is not in the dictionary');
      }
      score += _scoreWord(board, word.cells);
      wordTexts.add(word.text);
    }
    if (placed.length == _rackSize) score += 50;

    return _MoveResult.valid(score: score, words: wordTexts);
  }

  _Direction _resolveDirection(
    List<List<_PlacedTile?>> board,
    List<_CellPos> placed,
  ) {
    final rows = placed.map((cell) => cell.row).toSet();
    final cols = placed.map((cell) => cell.col).toSet();
    if (rows.length == 1 && cols.length > 1) return _Direction.horizontal;
    if (cols.length == 1 && rows.length > 1) return _Direction.vertical;

    final cell = placed.first;
    if (_neighborHasTile(board, cell.row, cell.col - 1) ||
        _neighborHasTile(board, cell.row, cell.col + 1)) {
      return _Direction.horizontal;
    }
    if (_neighborHasTile(board, cell.row - 1, cell.col) ||
        _neighborHasTile(board, cell.row + 1, cell.col)) {
      return _Direction.vertical;
    }
    return _Direction.horizontal;
  }

  bool _neighborHasTile(List<List<_PlacedTile?>> board, int row, int col) {
    return row >= 0 &&
        row < _size &&
        col >= 0 &&
        col < _size &&
        board[row][col] != null;
  }

  _ScoredWord _wordAt(
    List<List<_PlacedTile?>> board,
    _CellPos origin,
    _Direction direction,
  ) {
    var row = origin.row;
    var col = origin.col;
    final dr = direction == _Direction.vertical ? 1 : 0;
    final dc = direction == _Direction.horizontal ? 1 : 0;

    while (row - dr >= 0 &&
        col - dc >= 0 &&
        board[row - dr][col - dc] != null) {
      row -= dr;
      col -= dc;
    }

    final cells = <_CellPos>[];
    final buffer = StringBuffer();
    while (row < _size && col < _size && board[row][col] != null) {
      cells.add(_CellPos(row, col));
      buffer.write(board[row][col]!.letter);
      row += dr;
      col += dc;
    }
    return _ScoredWord(buffer.toString(), cells);
  }

  bool _hasAnyLockedTiles(List<List<_PlacedTile?>> board) {
    for (final row in board) {
      for (final tile in row) {
        if (tile?.locked == true) return true;
      }
    }
    return false;
  }

  bool _touchesLockedTile(
    List<List<_PlacedTile?>> board,
    List<_CellPos> placed,
    List<_CellPos> mainCells,
  ) {
    for (final cell in mainCells) {
      final tile = board[cell.row][cell.col];
      if (tile != null && tile.locked) return true;
    }
    for (final cell in placed) {
      const deltas = [
        _CellPos(-1, 0),
        _CellPos(1, 0),
        _CellPos(0, -1),
        _CellPos(0, 1),
      ];
      for (final delta in deltas) {
        final row = cell.row + delta.row;
        final col = cell.col + delta.col;
        if (row < 0 || row >= _size || col < 0 || col >= _size) continue;
        if (board[row][col]?.locked == true) return true;
      }
    }
    return false;
  }

  int _scoreWord(List<List<_PlacedTile?>> board, List<_CellPos> cells) {
    var total = 0;
    var wordMultiplier = 1;
    for (final cell in cells) {
      final tile = board[cell.row][cell.col]!;
      var letterScore = _letterValues[tile.letter]!;
      if (!tile.locked) {
        letterScore *= _letterMultiplier(cell.row, cell.col);
        wordMultiplier *= _wordMultiplier(cell.row, cell.col);
      }
      total += letterScore;
    }
    return total * wordMultiplier;
  }

  int _letterMultiplier(int row, int col) {
    final key = _premiumKey(row, col);
    if (_tripleLetter.contains(key)) return 3;
    if (_doubleLetter.contains(key)) return 2;
    return 1;
  }

  int _wordMultiplier(int row, int col) {
    final key = _premiumKey(row, col);
    if (_tripleWord.contains(key)) return 3;
    if (_doubleWord.contains(key) || (row == 7 && col == 7)) {
      return 2;
    }
    return 1;
  }

  void _zoomToCell(int row, int col) {
    if (_boardViewportSize == Size.zero || _boardPixelSize == 0) return;
    final scale = 1.65;
    final cellSize = _boardPixelSize / _size;
    final cellCenter =
        _boardOrigin + Offset((col + 0.5) * cellSize, (row + 0.5) * cellSize);
    final viewportCenter = Offset(
      _boardViewportSize.width / 2,
      _boardViewportSize.height / 2,
    );
    final dx = viewportCenter.dx - cellCenter.dx * scale;
    final dy = viewportCenter.dy - cellCenter.dy * scale;
    _boardController.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, dx)
      ..setEntry(1, 3, dy);
  }

  void _resetZoom() {
    _boardController.value = Matrix4.identity();
  }

  LevelOutcome _buildOutcome() {
    final normalized = (_playerScore / _targetScore).clamp(0.0, 1.0);
    return LevelOutcome(
      score: normalized,
      metrics: {
        'player_score': _playerScore,
        'turns': _turns,
        'tiles_left': _bag.length,
      },
      visibleMetricKeys: const {'player_score', 'turns', 'tiles_left'},
    );
  }

  void _finish() {
    if (_completed) return;
    _completed = true;
    _ticker?.cancel();
    Future<void>.delayed(const Duration(milliseconds: 250), () {
      if (!mounted) return;
      widget.onComplete(_buildOutcome());
    });
  }

  Future<void> _confirmFinish() async {
    if (_completed) return;
    final shouldFinish = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('end game?'),
          content: const Text('finish this run and submit your current score?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('keep playing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('finish'),
            ),
          ],
        );
      },
    );
    if (shouldFinish == true && mounted) _finish();
  }

  String _formatTime(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: _loading
            ? const Center(
                child: CircularProgressIndicator(color: NunuColors.primaryMain),
              )
            : Column(
                children: [
                  _buildHud(),
                  Expanded(child: _buildBoardArea()),
                  _buildBottomPanel(),
                ],
              ),
      ),
    );
  }

  Widget _buildHud() {
    return Column(
      children: [
        LevelHud(
          timerText: _formatTime(_timeLeft),
          stageText: 'score $_playerScore/$_targetScore',
          trailing: Text(
            'bag ${_bag.length}',
            style: const TextStyle(
              color: NunuColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          infoTitle: 'scrabble',
          infoItems: const [
            LevelHudBullet('🔤', 'drag rack tiles onto the board and submit valid words'),
            LevelHudBullet('⭐', 'your first word must cross the center star'),
            LevelHudBullet('🔗', 'every later word must connect to a locked tile'),
            LevelHudBullet('✖️', 'board multipliers (2× / 3× letter and word) apply on submission'),
            LevelHudBullet('🎯', 'use all 7 rack tiles to earn a bingo bonus'),
            LevelHudBullet('🔄', 'reshuffling your rack costs 1 point'),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
          child: Text(
            _message,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(color: NunuColors.textSecondary),
          ),
        ),
      ],
    );
  }

  Widget _buildBoardArea() {
    return LayoutBuilder(
      builder: (context, constraints) {
        _boardViewportSize = Size(constraints.maxWidth, constraints.maxHeight);
        _boardPixelSize = max(0, constraints.maxWidth - 16);
        _boardOrigin = Offset((constraints.maxWidth - _boardPixelSize) / 2, 0);

        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: InteractiveViewer(
              transformationController: _boardController,
              minScale: 1,
              maxScale: 2.15,
              boundaryMargin: const EdgeInsets.all(80),
              child: SizedBox(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                child: Stack(
                  children: [
                    Positioned(
                      left: _boardOrigin.dx,
                      top: _boardOrigin.dy,
                      width: _boardPixelSize,
                      height: _boardPixelSize,
                      child: _buildBoard(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBoard() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: NunuColors.primaryDark.withValues(alpha: 0.65),
        ),
      ),
      child: Column(
        children: List.generate(_size, (row) {
          return Expanded(
            child: Row(
              children: List.generate(_size, (col) {
                return Expanded(child: _buildCell(row, col));
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCell(int row, int col) {
    final tile = _board[row][col];
    return DragTarget<_DragTile>(
      onWillAcceptWithDetails: (details) => tile == null && !_completed,
      onAcceptWithDetails: (details) {
        final drag = details.data;
        if (drag.fromRack) {
          _placeFromRack(row, col, drag);
        } else {
          _movePendingTile(row, col, drag);
        }
      },
      builder: (context, candidate, rejected) {
        final active = candidate.isNotEmpty;
        return GestureDetector(
          onTap: () => _returnPendingTile(row, col),
          child: Container(
            margin: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              color: active ? NunuColors.primaryDark : _cellColor(row, col),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: row == 7 && col == 7
                    ? NunuColors.warningLight
                    : Colors.white.withValues(alpha: 0.08),
                width: row == 7 && col == 7 ? 1.4 : 0.5,
              ),
            ),
            child: tile == null
                ? _BonusLabel(row: row, col: col)
                : _BoardTileWidget(
                    tile: tile,
                    row: row,
                    col: col,
                    draggable: !tile.locked,
                  ),
          ),
        );
      },
    );
  }

  Color _cellColor(int row, int col) {
    final pos = _premiumKey(row, col);
    if (_tripleWord.contains(pos)) return const Color(0xFF6D1F4E);
    if (_doubleWord.contains(pos) || (row == 7 && col == 7)) {
      return const Color(0xFF5B2C83);
    }
    if (_tripleLetter.contains(pos)) return const Color(0xFF173F73);
    if (_doubleLetter.contains(pos)) return const Color(0xFF15515E);
    return const Color(0xFF231A3F);
  }

  Widget _buildBottomPanel() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: NunuColors.primaryDark.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildRack(), const SizedBox(height: 8), _buildControls()],
      ),
    );
  }

  Widget _buildRack() {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 7,
      runSpacing: 7,
      children: _playerRack
          .map(
            (tile) => Draggable<_DragTile>(
              data: _DragTile.fromRack(tile),
              feedback: _RackTileWidget(letter: tile.letter, floating: true),
              childWhenDragging: Opacity(
                opacity: 0.28,
                child: _RackTileWidget(letter: tile.letter),
              ),
              maxSimultaneousDrags: _completed ? 0 : 1,
              child: _RackTileWidget(letter: tile.letter),
            ),
          )
          .toList(),
    );
  }

  Widget _buildControls() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final submitWidth = (constraints.maxWidth - 210).clamp(128.0, 172.0);

        return SizedBox(
          height: 48,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton.outlined(
                      onPressed: _resetPendingTiles,
                      tooltip: 'return placed tiles',
                      style: IconButton.styleFrom(
                        fixedSize: const Size(58, 44),
                        minimumSize: const Size(58, 44),
                      ),
                      icon: const _ReturnTilesIcon(),
                    ),
                    IconButton(
                      onPressed: _confirmReshuffle,
                      tooltip: 'reshuffle rack',
                      icon: const Icon(Icons.shuffle),
                    ),
                  ],
                ),
              ),
              Center(
                child: SizedBox(
                  width: submitWidth,
                  child: FilledButton(
                    onPressed: _submitPlayerMove,
                    child: const Text('submit'),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _resetZoom,
                      tooltip: 'show full board',
                      icon: const Icon(Icons.fullscreen),
                    ),
                    IconButton(
                      onPressed: _confirmFinish,
                      tooltip: 'finish run',
                      icon: const Icon(Icons.flag_outlined),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

enum _Direction { horizontal, vertical }

class _RackTile {
  final int id;
  final String letter;

  const _RackTile({required this.id, required this.letter});
}

class _PlacedTile {
  final int id;
  final String letter;
  final bool locked;

  const _PlacedTile({
    required this.id,
    required this.letter,
    required this.locked,
  });

  _PlacedTile lockedCopy() {
    return _PlacedTile(id: id, letter: letter, locked: true);
  }
}

class _DragTile {
  final int id;
  final String letter;
  final int? row;
  final int? col;

  const _DragTile({required this.id, required this.letter, this.row, this.col});

  factory _DragTile.fromRack(_RackTile tile) {
    return _DragTile(id: tile.id, letter: tile.letter);
  }

  bool get fromRack => row == null || col == null;
}

class _CellPos {
  final int row;
  final int col;

  const _CellPos(this.row, this.col);

  @override
  bool operator ==(Object other) {
    return other is _CellPos && other.row == row && other.col == col;
  }

  @override
  int get hashCode => Object.hash(row, col);
}

class _ScoredWord {
  final String text;
  final List<_CellPos> cells;

  const _ScoredWord(this.text, this.cells);

  String get key => cells.map((cell) => '${cell.row},${cell.col}').join('|');
}

class _MoveResult {
  final bool valid;
  final int score;
  final List<String> words;
  final String? error;

  const _MoveResult._({
    required this.valid,
    this.score = 0,
    this.words = const [],
    this.error,
  });

  factory _MoveResult.valid({required int score, required List<String> words}) {
    return _MoveResult._(valid: true, score: score, words: words);
  }

  factory _MoveResult.invalid(String error) {
    return _MoveResult._(valid: false, error: error);
  }
}

class _ReturnTilesIcon extends StatelessWidget {
  const _ReturnTilesIcon();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 24,
      child: Stack(
        alignment: Alignment.center,
        children: const [
          Positioned(left: 4, child: Icon(Icons.arrow_downward, size: 20)),
          Positioned(right: 4, child: Icon(Icons.arrow_downward, size: 20)),
        ],
      ),
    );
  }
}

class _BonusLabel extends StatelessWidget {
  final int row;
  final int col;

  const _BonusLabel({required this.row, required this.col});

  @override
  Widget build(BuildContext context) {
    final pos = _premiumKey(row, col);
    String label = '';
    if (row == 7 && col == 7) {
      label = '*';
    } else if (_tripleWord.contains(pos)) {
      label = 'tw';
    } else if (_doubleWord.contains(pos)) {
      label = 'dw';
    } else if (_tripleLetter.contains(pos)) {
      label = 'tl';
    } else if (_doubleLetter.contains(pos)) {
      label = 'dl';
    }
    return Center(
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: label == '*' ? 13 : 7,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BoardTileWidget extends StatelessWidget {
  final _PlacedTile tile;
  final int row;
  final int col;
  final bool draggable;

  const _BoardTileWidget({
    required this.tile,
    required this.row,
    required this.col,
    required this.draggable,
  });

  @override
  Widget build(BuildContext context) {
    final child = _TileFace(
      letter: tile.letter,
      color: const Color(0xFFE9C46A),
      pending: !tile.locked,
    );
    if (!draggable) return child;
    return Draggable<_DragTile>(
      data: _DragTile(id: tile.id, letter: tile.letter, row: row, col: col),
      feedback: SizedBox(width: 34, height: 34, child: child),
      childWhenDragging: const SizedBox.shrink(),
      child: child,
    );
  }
}

class _RackTileWidget extends StatelessWidget {
  final String letter;
  final bool floating;

  const _RackTileWidget({required this.letter, this.floating = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 48,
      child: _TileFace(
        letter: letter,
        color: floating ? NunuColors.primaryMain : const Color(0xFFE9C46A),
        pending: false,
      ),
    );
  }
}

class _TileFace extends StatelessWidget {
  final String letter;
  final Color color;
  final bool pending;

  const _TileFace({
    required this.letter,
    required this.color,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileSize = min(constraints.maxWidth, constraints.maxHeight);
        final letterSize = (tileSize * 0.54).clamp(10.0, 24.0);
        final scoreSize = (tileSize * 0.22).clamp(5.0, 9.0);
        final inset = (tileSize * 0.08).clamp(1.0, 4.0);

        return Container(
          margin: EdgeInsets.all((tileSize * 0.06).clamp(0.5, 1.5)),
          clipBehavior: Clip.hardEdge,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular((tileSize * 0.15).clamp(3, 7)),
            border: Border.all(
              color: pending ? NunuColors.warningLight : Colors.black26,
              width: pending ? 1.4 : 0.8,
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black38,
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: const Color(0xFF231A1A),
                    fontSize: letterSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              Positioned(
                right: inset,
                bottom: inset * 0.5,
                child: Text(
                  '${_letterValues[letter]}',
                  style: TextStyle(
                    color: const Color(0xFF3B2929),
                    fontSize: scoreSize,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

const Map<String, int> _letterValues = {
  'A': 1,
  'B': 3,
  'C': 3,
  'D': 2,
  'E': 1,
  'F': 4,
  'G': 2,
  'H': 4,
  'I': 1,
  'J': 8,
  'K': 5,
  'L': 1,
  'M': 3,
  'N': 1,
  'O': 1,
  'P': 3,
  'Q': 10,
  'R': 1,
  'S': 1,
  'T': 1,
  'U': 1,
  'V': 4,
  'W': 4,
  'X': 8,
  'Y': 4,
  'Z': 10,
};

int _premiumKey(int row, int col) => row * 15 + col;

final Set<int> _tripleWord = {
  _premiumKey(0, 0),
  _premiumKey(0, 7),
  _premiumKey(0, 14),
  _premiumKey(7, 0),
  _premiumKey(7, 14),
  _premiumKey(14, 0),
  _premiumKey(14, 7),
  _premiumKey(14, 14),
};

final Set<int> _doubleWord = {
  _premiumKey(1, 1),
  _premiumKey(2, 2),
  _premiumKey(3, 3),
  _premiumKey(4, 4),
  _premiumKey(10, 10),
  _premiumKey(11, 11),
  _premiumKey(12, 12),
  _premiumKey(13, 13),
  _premiumKey(1, 13),
  _premiumKey(2, 12),
  _premiumKey(3, 11),
  _premiumKey(4, 10),
  _premiumKey(10, 4),
  _premiumKey(11, 3),
  _premiumKey(12, 2),
  _premiumKey(13, 1),
};

final Set<int> _tripleLetter = {
  _premiumKey(1, 5),
  _premiumKey(1, 9),
  _premiumKey(5, 1),
  _premiumKey(5, 5),
  _premiumKey(5, 9),
  _premiumKey(5, 13),
  _premiumKey(9, 1),
  _premiumKey(9, 5),
  _premiumKey(9, 9),
  _premiumKey(9, 13),
  _premiumKey(13, 5),
  _premiumKey(13, 9),
};

final Set<int> _doubleLetter = {
  _premiumKey(0, 3),
  _premiumKey(0, 11),
  _premiumKey(2, 6),
  _premiumKey(2, 8),
  _premiumKey(3, 0),
  _premiumKey(3, 7),
  _premiumKey(3, 14),
  _premiumKey(6, 2),
  _premiumKey(6, 6),
  _premiumKey(6, 8),
  _premiumKey(6, 12),
  _premiumKey(7, 3),
  _premiumKey(7, 11),
  _premiumKey(8, 2),
  _premiumKey(8, 6),
  _premiumKey(8, 8),
  _premiumKey(8, 12),
  _premiumKey(11, 0),
  _premiumKey(11, 7),
  _premiumKey(11, 14),
  _premiumKey(12, 6),
  _premiumKey(12, 8),
  _premiumKey(14, 3),
  _premiumKey(14, 11),
};
