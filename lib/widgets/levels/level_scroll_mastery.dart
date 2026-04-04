import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_components/contact_list_item.dart';
import '../level_widget.dart';

/// Five scrolling challenges: list, document bottom, speed find, horizontal, 2d grid.
class LevelScrollMastery extends LevelWidget {
  const LevelScrollMastery({super.key, required super.onComplete});

  @override
  State<LevelScrollMastery> createState() => _LevelScrollMasteryState();
}

class _LevelScrollMasteryState extends State<LevelScrollMastery> {
  static const int maxWrongTaps = 12;
  int _stage = 0;
  int _wrongTaps = 0;
  int _totalTaps = 0;
  final Stopwatch _sw = Stopwatch();

  // Stage 0: contacts
  late List<Map<String, String>> _contacts;
  late int _saulIndex;

  // Stage 1: tos
  final ScrollController _tosCtrl = ScrollController();
  bool _tosBottom = false;
  bool _tosChecked = false;

  // Stage 2: speed list
  late List<int> _speedIndices;
  late int _highlightIndex;
  // Stage 3: horizontal
  late List<String> _carousel;
  late int _carouselTarget;

  // Stage 4: grid
  late int _gridW;
  late int _gridH;
  late int _gx;
  late int _gy;
  final ScrollController _gridHCtrl = ScrollController();
  final ScrollController _gridVCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _sw.start();
    _initContacts();
    _initSpeed();
    _initCarousel();
    _initGrid();
    _tosCtrl.addListener(_tosListen);
  }

  void _initContacts() {
    final rng = Random();
    const firstNames = ['Alex', 'Sam', 'Jordan', 'Taylor', 'Casey'];
    const lastNames = ['Smith', 'Lee', 'Kim', 'Brown', 'Davis'];
    _contacts = [];
    for (var i = 0; i < 80; i++) {
      _contacts.add({
        'name':
            '${firstNames[rng.nextInt(firstNames.length)]} ${lastNames[rng.nextInt(lastNames.length)]} $i',
        'phone': '(555) ${rng.nextInt(900) + 100}-${rng.nextInt(9000) + 1000}',
      });
    }
    _contacts.sort((a, b) => a['name']!.compareTo(b['name']!));
    _saulIndex = 35 + rng.nextInt(25);
    _contacts.insert(_saulIndex, {
      'name': 'Saul Goodman',
      'phone': '(505) CALL-SAUL',
    });
  }

  void _initSpeed() {
    final rng = Random();
    _speedIndices = List.generate(60, (i) => i)..shuffle(rng);
    _highlightIndex = 15 + rng.nextInt(35);
  }

  void _initCarousel() {
    final rng = Random();
    _carousel = List.generate(
      24,
      (i) => 'item ${String.fromCharCode(65 + (i % 26))}-$i',
    )..shuffle(rng);
    _carouselTarget = 5 + rng.nextInt(14);
  }

  void _initGrid() {
    final rng = Random();
    _gridW = 14;
    _gridH = 16;
    _gx = 3 + rng.nextInt(_gridW - 6);
    _gy = 3 + rng.nextInt(_gridH - 6);
  }

  @override
  void dispose() {
    _tosCtrl.removeListener(_tosListen);
    _tosCtrl.dispose();
    _gridHCtrl.dispose();
    _gridVCtrl.dispose();
    super.dispose();
  }

  void _tosListen() {
    if (!_tosCtrl.hasClients) return;
    final max = _tosCtrl.position.maxScrollExtent;
    final cur = _tosCtrl.position.pixels;
    if (max - cur < 12 && !_tosBottom) {
      setState(() => _tosBottom = true);
    }
  }

  void _bumpWrong() {
    _wrongTaps++;
    _totalTaps++;
    if (_wrongTaps >= maxWrongTaps) {
      _fail();
    }
  }

  void _fail() {
    widget.onComplete(
      false,
      metrics: {
        'total_taps': _totalTaps,
        'time_ms': _sw.elapsedMilliseconds,
        'stages_cleared': _stage,
      },
    );
  }

  void _nextStage() {
    if (_stage >= 4) {
      widget.onComplete(
        true,
        metrics: {
          'total_taps': _totalTaps,
          'time_ms': _sw.elapsedMilliseconds,
          'stages_cleared': 5,
        },
      );
      return;
    }
    setState(() {
      _stage++;
    });
  }

  void _onContactTap(int i) {
    _totalTaps++;
    if (i == _saulIndex) {
      _nextStage();
    } else {
      _bumpWrong();
      setState(() {});
    }
  }

  void _stage1Accept() {
    if (_tosBottom && _tosChecked) {
      _nextStage();
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (_stage) {
      case 0:
        return _buildContacts();
      case 1:
        return _buildTos();
      case 2:
        return _buildSpeedList();
      case 3:
        return _buildCarousel();
      case 4:
        return _buildGrid();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildContacts() {
    return Column(
      children: [
        _header('find Saul Goodman'),
        Expanded(
          child: ListView.builder(
            itemCount: _contacts.length,
            itemBuilder: (context, i) {
              final c = _contacts[i];
              final isSaul = i == _saulIndex;
              return ContactListItem(
                name: c['name']!,
                subtitle: c['phone'],
                avatarText: isSaul ? '👔' : null,
                avatarColor: isSaul ? Colors.blue.shade700 : null,
                isSpecial: isSaul,
                onTap: () => _onContactTap(i),
                trailing: const Icon(Icons.chevron_right, color: Colors.grey),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTos() {
    return Column(
      children: [
        _header('scroll to the bottom, then check and accept'),
        Expanded(
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: 140,
                  child: Scrollbar(
                    controller: _tosCtrl,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _tosCtrl,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          12,
                          (i) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              'Section ${i + 1}. Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                              'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. '
                              'Ut enim ad minim veniam, quis nostrud exercitation.',
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _tosBottom
                      ? () => setState(() => _tosChecked = !_tosChecked)
                      : null,
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: _tosChecked ? Colors.blue.shade700 : Colors.white,
                          border: Border.all(color: Colors.blue.shade700),
                        ),
                        child: _tosChecked
                            ? const Icon(Icons.check, color: Colors.white, size: 16)
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'i agree',
                          style: TextStyle(
                            color: _tosBottom ? Colors.black : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: (_tosBottom && _tosChecked) ? _stage1Accept : null,
                  child: const Text('accept'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeedList() {
    return Column(
      children: [
        _header('tap the row marked TARGET'),
        Expanded(
          child: ListView.builder(
            itemCount: _speedIndices.length,
            itemBuilder: (context, i) {
              final idx = _speedIndices[i];
              final isTarget = idx == _highlightIndex;
              return ListTile(
                tileColor: isTarget
                    ? NunuColors.primaryMain.withValues(alpha: 0.25)
                    : null,
                title: Text(
                  isTarget ? '★ TARGET ★' : 'row $idx',
                  style: TextStyle(
                    color: isTarget ? NunuColors.primaryLight : Colors.white70,
                    fontWeight: isTarget ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                onTap: () {
                  _totalTaps++;
                  if (isTarget) {
                    _nextStage();
                  } else {
                    _bumpWrong();
                    setState(() {});
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCarousel() {
    return Column(
      children: [
        _header('scroll horizontally and tap: ${_carousel[_carouselTarget]}'),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            itemCount: _carousel.length,
            itemBuilder: (context, i) {
              final label = _carousel[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Material(
                  color: NunuColors.backgroundPaper,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: () {
                      _totalTaps++;
                      if (i == _carouselTarget) {
                        _nextStage();
                      } else {
                        _bumpWrong();
                        setState(() {});
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 100,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: NunuColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildGrid() {
    return Column(
      children: [
        _header('scroll both axes; tap the cell that says HERE'),
        Expanded(
          child: Scrollbar(
            controller: _gridVCtrl,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _gridVCtrl,
              child: Scrollbar(
                controller: _gridHCtrl,
                thumbVisibility: true,
                notificationPredicate: (n) =>
                    n.metrics.axis == Axis.horizontal,
                child: SingleChildScrollView(
                  controller: _gridHCtrl,
                  scrollDirection: Axis.horizontal,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(_gridH, (y) {
                      return Row(
                        children: List.generate(_gridW, (x) {
                          final here = x == _gx && y == _gy;
                          return GestureDetector(
                            onTap: () {
                              _totalTaps++;
                              if (here) {
                                _nextStage();
                              } else {
                                _bumpWrong();
                                setState(() {});
                              }
                            },
                            child: Container(
                              width: 88,
                              height: 64,
                              margin: const EdgeInsets.all(5),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: here
                                    ? NunuColors.secondaryMain.withValues(alpha: 0.35)
                                    : NunuColors.backgroundPaper,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: NunuColors.primaryDark.withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                here ? 'HERE' : '$x,$y',
                                style: TextStyle(
                                  fontSize: here ? 13 : 11,
                                  fontWeight:
                                      here ? FontWeight.bold : FontWeight.normal,
                                  color: NunuColors.textPrimary,
                                ),
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _header(String subtitle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: NunuColors.backgroundPaper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subtitle,
            style: const TextStyle(color: NunuColors.textPrimary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
