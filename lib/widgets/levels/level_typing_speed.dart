import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelTypingSpeed extends LevelWidget {
  const LevelTypingSpeed({super.key, required super.onComplete});

  @override
  State<LevelTypingSpeed> createState() => _LevelTypingSpeedState();
}

class _LevelTypingSpeedState extends State<LevelTypingSpeed> {
  static const String _targetText =
      'the cake is a lie. glados watches from above as test subjects navigate '
      'the enrichment center. cave johnson here. i am the man who is gonna '
      'burn your house down with the lemons. science is not about why. it is '
      'about why not. we do what we must because we can.';

  static const int _timeLimitSeconds = 90;

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _timer;
  int _secondsRemaining = _timeLimitSeconds;
  bool _started = false;
  bool _done = false;
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _startTimer() {
    if (_started) return;
    _started = true;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        _secondsRemaining--;
        if (_secondsRemaining <= 0) {
          _finish();
        }
      });
    });
  }

  void _finish() {
    if (_done) return;
    _done = true;
    _timer?.cancel();
    _stopwatch.stop();

    final typed = _controller.text;
    int correctChars = 0;
    for (int i = 0; i < typed.length && i < _targetText.length; i++) {
      if (typed[i] == _targetText[i]) correctChars++;
    }

    final accuracy =
        typed.isEmpty ? 0.0 : (correctChars / typed.length * 100);
    final elapsedMinutes = _stopwatch.elapsedMilliseconds / 60000.0;
    final wpm =
        elapsedMinutes > 0 ? (correctChars / 5.0) / elapsedMinutes : 0.0;
    final progress =
        (typed.length / _targetText.length * 100).clamp(0.0, 100.0);

    Future.delayed(const Duration(milliseconds: 400), () {
      widget.onComplete(LevelOutcome(score: 1, metrics: {
        'wpm': wpm.round(),
        'accuracy': '${accuracy.toStringAsFixed(1)}%',
        'progress': '${progress.toStringAsFixed(0)}%',
        'correct': correctChars,
      }));
    });
  }

  void _onTextChanged(String value) {
    _startTimer();
    setState(() {});
    if (value.length >= _targetText.length) {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 12),
            _buildProgressBar(),
            const SizedBox(height: 16),
            Expanded(child: _buildTargetText()),
            const SizedBox(height: 12),
            _buildInput(),
            const SizedBox(height: 8),
            if (_started)
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _done ? null : _finish,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: NunuColors.primaryMain,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'SUBMIT',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final typed = _controller.text;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'time left',
              style:
                  TextStyle(color: NunuColors.textSecondary, fontSize: 12),
            ),
            Text(
              '${_secondsRemaining}s',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _secondsRemaining <= 10
                    ? NunuColors.errorMain
                    : NunuColors.primaryMain,
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text(
              'typed',
              style:
                  TextStyle(color: NunuColors.textSecondary, fontSize: 12),
            ),
            Text(
              '${typed.length} / ${_targetText.length}',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: NunuColors.secondaryMain,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressBar() {
    final pct = _controller.text.length / _targetText.length;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 6,
        child: Stack(
          children: [
            Container(color: NunuColors.backgroundPaper),
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [NunuColors.primaryMain, NunuColors.successMain],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: NunuColors.primaryDark.withOpacity(0.3)),
      ),
      child: SingleChildScrollView(
        child: RichText(
          text: TextSpan(
            children: _buildHighlightedText(),
            style: const TextStyle(
              fontSize: 18,
              height: 1.7,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ),
    );
  }

  List<TextSpan> _buildHighlightedText() {
    final typed = _controller.text;
    final spans = <TextSpan>[];

    for (int i = 0; i < _targetText.length; i++) {
      Color color;
      Color? bgColor;
      if (i < typed.length) {
        if (typed[i] == _targetText[i]) {
          color = NunuColors.successMain;
        } else {
          color = Colors.white;
          bgColor = NunuColors.errorMain.withOpacity(0.6);
        }
      } else if (i == typed.length) {
        color = NunuColors.textPrimary;
        bgColor = NunuColors.primaryMain.withOpacity(0.3);
      } else {
        color = NunuColors.textSecondary.withOpacity(0.4);
      }

      spans.add(TextSpan(
        text: _targetText[i],
        style: TextStyle(color: color, backgroundColor: bgColor),
      ));
    }

    return spans;
  }

  Widget _buildInput() {
    return TextField(
      controller: _controller,
      focusNode: _focusNode,
      onChanged: _onTextChanged,
      enabled: !_done,
      maxLines: 3,
      style: const TextStyle(fontSize: 16, fontFamily: 'monospace'),
      decoration: InputDecoration(
        hintText: 'start typing...',
        hintStyle:
            TextStyle(color: NunuColors.textSecondary.withOpacity(0.5)),
        filled: true,
        fillColor: NunuColors.backgroundPaper,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: NunuColors.primaryDark),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              BorderSide(color: NunuColors.primaryDark.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: NunuColors.primaryMain, width: 2),
        ),
      ),
    );
  }
}
