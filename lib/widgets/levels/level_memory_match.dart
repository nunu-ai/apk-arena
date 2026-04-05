import 'dart:math';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelMemoryMatch extends LevelWidget {
  const LevelMemoryMatch({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelMemoryMatch> createState() => _LevelMemoryMatchState();
}

class _LevelMemoryMatchState extends State<LevelMemoryMatch> {
  static const int _gridCount = 16; // 4x4 grid (not too small)
  static const int _crossAxisCount = 4;
  final Random _rand = Random();

  late final List<String> _deck; // length 16, 8 pairs
  final Set<int> _matched = {};
  final List<int> _revealed = [];
  bool _lock = false;

  static const List<String> _emojiPool = [
    '🍎','🍌','🍇','🍓','🍒','🍍','🍑','🥝',
    '🐶','🐱','🐼','🦊','🐵','🦁','🐸','🐨',
    '⭐','🌙','⚡','🔥','💧','❄️','🌈','🌟',
  ];

  @override
  void initState() {
    super.initState();
    _deck = _buildDeck();
  }

  List<String> _buildDeck() {
    // pick 8 random unique emojis, duplicate, and shuffle
    final pool = List<String>.from(_emojiPool)..shuffle(_rand);
    final selected = pool.take(_gridCount ~/ 2).toList();
    final deck = <String>[...selected, ...selected]..shuffle(_rand);
    return deck;
  }

  void _onCardTap(int index) async {
    if (_lock) return;
    if (_matched.contains(index)) return;
    if (_revealed.contains(index)) return;

    setState(() {
      _revealed.add(index);
    });

    if (_revealed.length == 2) {
      _lock = true;
      final i = _revealed[0];
      final j = _revealed[1];
      final match = _deck[i] == _deck[j];
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() {
        if (match) {
          _matched.addAll([i, j]);
        }
        _revealed.clear();
        _lock = false;
      });

      if (_matched.length == _gridCount) {
        widget.onComplete(LevelOutcome(score: 1));
      }
    }
  }

  bool _isFaceUp(int index) => _matched.contains(index) || _revealed.contains(index);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'memory match',
                style: TextStyle(fontSize: 16, color: NunuColors.textPrimary),
              ),
              Text(
                'pairs: ${_matched.length ~/ 2}/${_gridCount ~/ 2}',
                style: const TextStyle(fontSize: 14, color: NunuColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final spacing = 8.0;
                final totalSpacing = spacing * (_crossAxisCount - 1);
                final cardSize = (constraints.maxWidth - totalSpacing) / _crossAxisCount;
                return GridView.builder(
                  itemCount: _gridCount,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemBuilder: (context, index) {
                    final faceUp = _isFaceUp(index);
                    return GestureDetector(
                      onTap: () => _onCardTap(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: faceUp
                              ? NunuColors.backgroundPaper
                              : NunuColors.secondaryDark.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: faceUp
                                ? NunuColors.primaryMain.withOpacity(0.7)
                                : NunuColors.secondaryMain.withOpacity(0.4),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          faceUp ? _deck[index] : ' ',
                          style: TextStyle(fontSize: min(cardSize * 0.6, 42)),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

