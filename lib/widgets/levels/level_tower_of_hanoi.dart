import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelTowerOfHanoi extends LevelWidget {
  const LevelTowerOfHanoi({super.key, required super.onComplete});

  @override
  State<LevelTowerOfHanoi> createState() => _LevelTowerOfHanoiState();
}

class _LevelTowerOfHanoiState extends State<LevelTowerOfHanoi> {
  static const int _numDiscs = 5;
  static const List<Color> _discColors = [
    NunuColors.errorMain,
    NunuColors.warningMain,
    NunuColors.successMain,
    NunuColors.infoMain,
    NunuColors.primaryMain,
  ];

  // pegs[0], pegs[1], pegs[2] - each is a stack of disc sizes (1=smallest)
  late List<List<int>> _pegs;
  int? _selectedPeg;
  int _moves = 0;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _pegs = [
      List.generate(_numDiscs, (i) => i + 1), // [1,2,3,4,5] top to bottom
      [],
      [],
    ];
  }

  void _onPegTap(int pegIndex) {
    if (_done) return;

    setState(() {
      if (_selectedPeg == null) {
        // Pick up from this peg
        if (_pegs[pegIndex].isNotEmpty) {
          _selectedPeg = pegIndex;
        }
      } else {
        if (_selectedPeg == pegIndex) {
          // Deselect
          _selectedPeg = null;
        } else {
          // Try to place
          final disc = _pegs[_selectedPeg!].first;
          if (_pegs[pegIndex].isEmpty || _pegs[pegIndex].first > disc) {
            // Valid move
            _pegs[_selectedPeg!].removeAt(0);
            _pegs[pegIndex].insert(0, disc);
            _moves++;
            HapticFeedback.lightImpact();

            // Check win - all discs on rightmost peg
            if (_pegs[2].length == _numDiscs) {
              _done = true;
              HapticFeedback.mediumImpact();
              Future.delayed(const Duration(milliseconds: 500), () {
                widget.onComplete(true);
              });
            }
          } else {
            // Invalid move - buzz
            HapticFeedback.heavyImpact();
          }
          _selectedPeg = null;
        }
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
            const SizedBox(height: 8),
            Expanded(child: _buildPegs()),
            const SizedBox(height: 20),
            _buildHint(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final optimal = (1 << _numDiscs) - 1; // 2^n - 1
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'moves',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$_moves',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'optimal',
                style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
              ),
              Text(
                '$optimal',
                style: const TextStyle(
                  color: NunuColors.primaryMain,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPegs() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final pegWidth = constraints.maxWidth / 3;
        final maxDiscWidth = pegWidth * 0.85;
        final discHeight = min(28.0, (constraints.maxHeight - 100) / (_numDiscs + 1));

        return Row(
          children: List.generate(3, (i) {
            return Expanded(
              child: GestureDetector(
                onTap: () => _onPegTap(i),
                behavior: HitTestBehavior.opaque,
                child: _buildPeg(i, maxDiscWidth, discHeight, constraints.maxHeight - 60),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildPeg(int pegIndex, double maxWidth, double discHeight, double height) {
    final isSelected = _selectedPeg == pegIndex;
    final discs = _pegs[pegIndex];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Peg label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isSelected
                  ? NunuColors.primaryMain.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(color: NunuColors.primaryMain, width: 2)
                  : null,
            ),
            child: Text(
              pegIndex == 0 ? 'A' : pegIndex == 1 ? 'B' : 'C',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isSelected ? NunuColors.primaryMain : NunuColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Peg + discs area
          SizedBox(
            height: height * 0.6,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Peg rod
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: 6,
                    height: height * 0.5,
                    decoration: BoxDecoration(
                      color: NunuColors.primaryDark.withOpacity(0.6),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(3)),
                    ),
                  ),
                ),
                // Base
                Positioned(
                  bottom: 0,
                  child: Container(
                    width: maxWidth,
                    height: 6,
                    decoration: BoxDecoration(
                      color: NunuColors.primaryDark.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                // Discs
                ...List.generate(discs.length, (di) {
                  final discSize = discs[discs.length - 1 - di]; // bottom-up
                  final width = maxWidth * (0.3 + 0.7 * discSize / _numDiscs);
                  final bottom = 8.0 + di * (discHeight + 3);
                  final isTop = di == discs.length - 1;

                  return Positioned(
                    bottom: bottom,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: width,
                      height: discHeight,
                      decoration: BoxDecoration(
                        color: _discColors[discSize - 1],
                        borderRadius: BorderRadius.circular(discHeight / 2),
                        border: isSelected && isTop
                            ? Border.all(color: Colors.white, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: _discColors[discSize - 1].withOpacity(0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '$discSize',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHint() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        _selectedPeg != null
            ? 'tap a peg to place the disc'
            : 'tap a peg to pick up the top disc',
        style: const TextStyle(
          fontSize: 13,
          color: NunuColors.textSecondary,
        ),
      ),
    );
  }
}
