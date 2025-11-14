import 'package:flutter/material.dart';
import 'dart:math';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelHold extends LevelWidget {
  const LevelHold({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelHold> createState() => _LevelHoldState();
}

class _LevelHoldState extends State<LevelHold> with SingleTickerProviderStateMixin {
  bool _isPressing = false;
  double _progress = 0.0;
  late double _targetDuration;
  double _tolerance = 0.15; // ±0.15 seconds tolerance
  late Stopwatch _stopwatch;
  bool _hasFailed = false;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _progressController = AnimationController(vsync: this);
    _generateNewTarget();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  void _generateNewTarget() {
    final random = Random();
    setState(() {
      _targetDuration = (random.nextInt(10) + 1).toDouble(); // 1-10 seconds
      _hasFailed = false;
      _progress = 0.0;
    });
  }

  void _onLongPressStart(LongPressStartDetails details) {
    setState(() {
      _isPressing = true;
      _progress = 0.0;
      _hasFailed = false;
    });
    _stopwatch.reset();
    _stopwatch.start();
    _startProgress();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _stopwatch.stop();

    if (_isPressing && !_hasFailed) {
      final holdDuration = _stopwatch.elapsedMilliseconds / 1000.0;
      final difference = (holdDuration - _targetDuration).abs();

      if (difference <= _tolerance) {
        // Success!
        widget.onComplete(true);
      } else {
        // Failed - generate new target
        _showFailure(holdDuration);
      }
    }

    setState(() {
      _isPressing = false;
      _progress = 0.0;
    });
  }

  void _showFailure(double actualDuration) {
    setState(() {
      _hasFailed = true;
    });

    // Show failure briefly, then generate new target
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        _generateNewTarget();
      }
    });
  }

  void _startProgress() {
    void updateProgress() {
      if (!_isPressing || !mounted) return;

      final elapsed = _stopwatch.elapsedMilliseconds / 1000.0;
      setState(() {
        _progress = elapsed / _targetDuration;
      });

      if (_isPressing) {
        Future.delayed(const Duration(milliseconds: 16), updateProgress);
      }
    }

    updateProgress();
  }

  @override
  Widget build(BuildContext context) {
    final isOverTarget = _progress > 1.0;
    final displayColor = _hasFailed
        ? Colors.red
        : isOverTarget
        ? Colors.orange
        : NunuColors.primaryLight;

    final currentTime = _isPressing
        ? _stopwatch.elapsedMilliseconds / 1000.0
        : 0.0;

    return Container(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onPanDown: (details) {
            _stopwatch.reset();
            _stopwatch.start();
            setState(() {
              _isPressing = true;
              _progress = 0.0;
              _hasFailed = false;
            });
            _startProgress();
          },
          onPanEnd: (details) {
            _onLongPressEnd(LongPressEndDetails());
          },
          onPanCancel: () {
            _stopwatch.stop();
            setState(() {
              _isPressing = false;
              _progress = 0.0;
            });
          },
          child: Transform.scale(
            scale: _isPressing ? 0.95 : 1.0,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: displayColor.withValues(alpha: 0.3),
                border: Border.all(
                  color: displayColor,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: displayColor.withValues(alpha: 0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Progress circle
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 180,
                      child: CircularProgressIndicator(
                        value: _progress.clamp(0.0, 1.0),
                        strokeWidth: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation<Color>(displayColor),
                      ),
                    ),
                  ),
                  // Center content
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasFailed
                              ? Icons.close
                              : _isPressing
                              ? Icons.touch_app
                              : Icons.pan_tool_outlined,
                          size: 60,
                          color: displayColor,
                        ),
                        const SizedBox(height: 12),
                        if (_hasFailed)
                          const Text(
                            'FAILED',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              letterSpacing: 2,
                            ),
                          )
                        else
                          Text(
                            _isPressing ? 'HOLDING...' : 'HOLD FOR',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: displayColor,
                              letterSpacing: 2,
                            ),
                          ),
                        const SizedBox(height: 8),
                        if (!_hasFailed)
                          Text(
                            '${_targetDuration.toStringAsFixed(1)}s',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: displayColor,
                            ),
                          ),
                        if (_isPressing && !_hasFailed)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${currentTime.toStringAsFixed(2)}s',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: NunuColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}