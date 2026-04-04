import 'dart:math';

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

/// Multi-step captcha flow: emoji grid, distorted text, slider align, rotate, 4x4 pick.
class LevelCaptcha extends LevelWidget {
  const LevelCaptcha({super.key, required super.onComplete});

  @override
  State<LevelCaptcha> createState() => _LevelCaptchaState();
}

enum _CaptchaStep {
  gate,
  emojiGrid,
  distortedText,
  sliderAlign,
  rotateAlign,
  imageGrid,
}

class _LevelCaptchaState extends State<LevelCaptcha> {
  _CaptchaStep _step = _CaptchaStep.gate;
  bool _isVerifying = false;

  final Random _rng = Random();
  final Stopwatch _playSw = Stopwatch();

  // Emoji grid (cars)
  final List<String> _allEmojis = [
    '🚗', '🚕', '🚙', '🚌',
    '🚦', '🚥',
    '🚲', '🛴', '🛵',
    '🌳', '🌲', '🌴',
    '🏠', '🏢', '🏪',
    '🔥', '💧', '⚡',
  ];
  final Set<String> _carEmojis = {'🚗', '🚕', '🚙', '🚌'};
  final Set<int> _selectedIndices = {};
  late List<String> _gridItems;
  late Set<int> _correctIndices;

  // Distorted text
  late String _textChallenge;
  late List<String> _textNoiseTop;
  late List<String> _textNoiseBottom;
  final TextEditingController _textCtrl = TextEditingController();

  // Slider align
  double _sliderX = 0.5;

  // Rotate
  double _rotateTurns = 0;
  late double _targetTurns;

  // 4x4 image grid (emoji “trees”)
  final Set<String> _treeEmojis = {'🌳', '🌲', '🌴'};
  final Set<int> _imgSelected = {};
  late List<String> _imgGrid;
  late Set<int> _imgCorrect;

  @override
  void initState() {
    super.initState();
    _initEmojiGrid();
    _initTextChallenge();
    _targetTurns = _rng.nextInt(3) / 4.0;
    _initImageGrid();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _initEmojiGrid() {
    _gridItems = [];
    _correctIndices = {};
    final numCars = 3 + _rng.nextInt(2);
    final carList = _carEmojis.toList()..shuffle(_rng);
    for (var i = 0; i < numCars; i++) {
      _gridItems.add(carList[i]);
    }
    final nonCars = _allEmojis.where((e) => !_carEmojis.contains(e)).toList()
      ..shuffle(_rng);
    for (var i = 0; i < 9 - numCars; i++) {
      _gridItems.add(nonCars[i]);
    }
    _gridItems.shuffle(_rng);
    for (var i = 0; i < _gridItems.length; i++) {
      if (_carEmojis.contains(_gridItems[i])) _correctIndices.add(i);
    }
  }

  void _initTextChallenge() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    _textChallenge = String.fromCharCodes(
      List.generate(5, (_) => chars.codeUnitAt(_rng.nextInt(chars.length))),
    );
    _textNoiseTop = List.generate(
      36,
      (i) =>
          'noise line ${i + 1}: the quick brown fox jumps over lazy CAPTCHA bytes '
          '${String.fromCharCodes(List.generate(8, (_) => 65 + _rng.nextInt(26)))}',
    );
    _textNoiseBottom = List.generate(
      14,
      (i) => 'footer clutter ${i + 1}: verify human presence module v2',
    );
  }

  void _initImageGrid() {
    _imgGrid = [];
    _imgCorrect = {};
    final trees = _treeEmojis.toList()..shuffle(_rng);
    final others = _allEmojis.where((e) => !_treeEmojis.contains(e)).toList()
      ..shuffle(_rng);
    const cols = 6;
    const rows = 9;
    const total = cols * rows;
    final nTree = 10 + _rng.nextInt(8);
    for (var i = 0; i < nTree; i++) {
      _imgGrid.add(trees[i % trees.length]);
    }
    while (_imgGrid.length < total) {
      _imgGrid.add(others[_rng.nextInt(others.length)]);
    }
    _imgGrid.shuffle(_rng);
    for (var i = 0; i < _imgGrid.length; i++) {
      if (_treeEmojis.contains(_imgGrid[i])) _imgCorrect.add(i);
    }
  }

  void _nextStep() {
    if (_step == _CaptchaStep.gate) {
      setState(() => _step = _CaptchaStep.emojiGrid);
      return;
    }
    if (_step == _CaptchaStep.emojiGrid) {
      setState(() {
        _step = _CaptchaStep.distortedText;
        _textCtrl.clear();
      });
      return;
    }
    if (_step == _CaptchaStep.distortedText) {
      setState(() => _step = _CaptchaStep.sliderAlign);
      return;
    }
    if (_step == _CaptchaStep.sliderAlign) {
      setState(() => _step = _CaptchaStep.rotateAlign);
      return;
    }
    if (_step == _CaptchaStep.rotateAlign) {
      setState(() {
        _step = _CaptchaStep.imageGrid;
        _imgSelected.clear();
        _initImageGrid();
      });
      return;
    }
  }

  void _gateTap() {
    if (_isVerifying) return;
    setState(() => _isVerifying = true);
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      _playSw
        ..reset()
        ..start();
      setState(() => _isVerifying = false);
      _nextStep();
    });
  }

  void _verifyEmoji() {
    if (_selectedIndices.length == _correctIndices.length &&
        _selectedIndices.containsAll(_correctIndices)) {
      _nextStep();
    } else {
      setState(() {
        _selectedIndices.clear();
        _initEmojiGrid();
      });
      _snack('try again');
    }
  }

  void _verifyText() {
    if (_textCtrl.text.trim().toUpperCase() == _textChallenge) {
      _nextStep();
    } else {
      _snack('text does not match');
    }
  }

  void _verifySlider() {
    if ((_sliderX - 0.5).abs() <= 0.06) {
      _nextStep();
    } else {
      _snack('align the bars');
    }
  }

  void _verifyRotate() {
    final d = (_rotateTurns - _targetTurns + 10) % 1.0;
    final err = d > 0.5 ? 1.0 - d : d;
    if (err <= 0.08) {
      _nextStep();
    } else {
      _snack('rotate to upright');
    }
  }

  void _verifyImageGrid() {
    if (_imgSelected.length == _imgCorrect.length &&
        _imgSelected.containsAll(_imgCorrect)) {
      _playSw.stop();
      widget.onComplete(
        true,
        metrics: {'duration_ms': _playSw.elapsedMilliseconds},
      );
    } else {
      setState(() {
        _imgSelected.clear();
        _initImageGrid();
      });
      _snack('incorrect selection');
    }
  }

  void _snack(String m) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(m),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey.shade900, Colors.black],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 420),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade800.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade700),
            ),
            child: _buildStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _CaptchaStep.gate:
        return _buildGate();
      case _CaptchaStep.emojiGrid:
        return _buildEmoji();
      case _CaptchaStep.distortedText:
        return _buildText();
      case _CaptchaStep.sliderAlign:
        return _buildSlider();
      case _CaptchaStep.rotateAlign:
        return _buildRotate();
      case _CaptchaStep.imageGrid:
        return _buildImgGrid();
    }
  }

  Widget _buildGate() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'before you continue!',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: _gateTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade500, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _isVerifying
                      ? const Padding(
                          padding: EdgeInsets.all(3),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                const Text(
                  "i'm not a robot",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmoji() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'select all squares with cars',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 12),
        AspectRatio(
          aspectRatio: 1,
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: 9,
            itemBuilder: (context, index) {
              final sel = _selectedIndices.contains(index);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _selectedIndices.remove(index);
                    } else {
                      _selectedIndices.add(index);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    border: Border.all(
                      color: sel ? NunuColors.primaryMain : Colors.grey.shade600,
                      width: sel ? 3 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(_gridItems[index], style: const TextStyle(fontSize: 36)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _selectedIndices.isEmpty ? null : _verifyEmoji,
          child: const Text('verify'),
        ),
      ],
    );
  }

  Widget _buildText() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'scroll, then type the characters you see',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...List.generate(
                    _textNoiseTop.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Text(
                        _textNoiseTop[i],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.22),
                          fontSize: 11,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                  Transform(
                    transform: Matrix4.identity()
                      ..rotateZ(-0.12)
                      ..scaleByDouble(1.05, 0.92, 1.0, 1.0),
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.black45, width: 2),
                      ),
                      child: Text(
                        _textChallenge,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 6,
                          color: Colors.blueGrey.shade900,
                          shadows: [
                            Shadow(
                              offset: const Offset(2, 1),
                              blurRadius: 0,
                              color: Colors.red.shade300,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
                  ...List.generate(
                    _textNoiseBottom.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _textNoiseBottom[i],
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.15),
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _textCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'type here',
            hintStyle: TextStyle(color: Colors.grey.shade500),
            filled: true,
            fillColor: Colors.black38,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _verifyText,
          child: const Text('submit text'),
        ),
      ],
    );
  }

  Widget _buildSlider() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'slide until stripes line up',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: (_sliderX * 100).round().clamp(1, 99),
                    child: Container(color: NunuColors.secondaryMain.withValues(alpha: 0.6)),
                  ),
                  Expanded(
                    flex: ((1 - _sliderX) * 100).round().clamp(1, 99),
                    child: Container(color: NunuColors.primaryDark.withValues(alpha: 0.5)),
                  ),
                ],
              ),
              Container(
                width: 4,
                height: 56,
                color: Colors.white,
              ),
            ],
          ),
        ),
        Slider(
          value: _sliderX,
          onChanged: (v) => setState(() => _sliderX = v),
        ),
        FilledButton(onPressed: _verifySlider, child: const Text('lock in')),
      ],
    );
  }

  Widget _buildRotate() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'rotate until the arrow points up',
          style: TextStyle(color: Colors.white70),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Transform.rotate(
          angle: (_rotateTurns - _targetTurns) * 2 * pi,
          child: const Icon(
            Icons.navigation,
            size: 80,
            color: Colors.cyanAccent,
          ),
        ),
        Slider(
          value: _rotateTurns,
          min: 0,
          max: 1,
          divisions: 48,
          label: _rotateTurns.toStringAsFixed(2),
          onChanged: (v) => setState(() => _rotateTurns = v),
        ),
        FilledButton(onPressed: _verifyRotate, child: const Text('confirm rotation')),
      ],
    );
  }

  Widget _buildImgGrid() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'select every tile with a tree (scroll to see all)',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 420,
          child: GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 6,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              childAspectRatio: 1,
            ),
            itemCount: _imgGrid.length,
            itemBuilder: (context, i) {
              final sel = _imgSelected.contains(i);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _imgSelected.remove(i);
                    } else {
                      _imgSelected.add(i);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    border: Border.all(
                      color: sel ? NunuColors.primaryMain : Colors.grey.shade600,
                      width: sel ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      _imgGrid[i],
                      style: const TextStyle(fontSize: 26),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _imgSelected.isEmpty ? null : _verifyImageGrid,
          child: const Text('verify'),
        ),
      ],
    );
  }
}
