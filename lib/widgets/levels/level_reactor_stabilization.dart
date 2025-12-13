import 'dart:async';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelReactorStabilization extends LevelWidget {
  const LevelReactorStabilization({super.key, required super.onComplete});

  @override
  State<LevelReactorStabilization> createState() =>
      _LevelReactorStabilizationState();
}

class _LevelReactorStabilizationState extends State<LevelReactorStabilization> {
  // Slider values (0.0 to 1.0)
  double _rodA = 0.0;
  double _rodB = 0.0;
  double _rodC = 0.0;

  // Stability progress (0.0 to 1.0)
  double _stability = 0.0;
  Timer? _stabilityTimer;
  bool _isComplete = false;

  // Target values are centered around 0.5
  // Green zone is 0.45 to 0.55
  static const double _targetMin = 0.45;
  static const double _targetMax = 0.55;

  // Calculated gauge values
  double get _temp => (_rodA * 0.6 + _rodB * 0.4 - 0.06).clamp(0.0, 1.0);
  double get _pressure => (_rodB * 0.4 + _rodC * 0.6 + 0.12).clamp(0.0, 1.0);
  double get _output => (_rodA * 0.3 + _rodC * 0.7 - 0.09).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _startStabilityCheck();
  }

  @override
  void dispose() {
    _stabilityTimer?.cancel();
    super.dispose();
  }

  void _startStabilityCheck() {
    _stabilityTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_isComplete) return;

      bool stable =
          _isStable(_temp) && _isStable(_pressure) && _isStable(_output);

      setState(() {
        if (stable) {
          _stability += 0.02; // Fills in ~2.5 seconds
        } else {
          _stability -= 0.05; // Drains fast
        }
        _stability = _stability.clamp(0.0, 1.0);

        if (_stability >= 1.0) {
          _isComplete = true;
          _stabilityTimer?.cancel();
          widget.onComplete(true);
        }
      });
    });
  }

  bool _isStable(double value) {
    return value >= _targetMin && value <= _targetMax;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF121212), // Dark industrial background
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 32),
            // Gauges Row
            Expanded(
              flex: 3,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGauge("TEMP", _temp, NunuColors.errorMain),
                  _buildGauge("PRESSURE", _pressure, NunuColors.warningMain),
                  _buildGauge("OUTPUT", _output, NunuColors.secondaryMain),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Stability Indicator
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "SYSTEM STABILITY",
                        style: TextStyle(
                          color: _stability > 0
                              ? NunuColors.successMain
                              : NunuColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${(_stability * 100).toInt()}%",
                        style: TextStyle(
                          color: _stability > 0
                              ? NunuColors.successMain
                              : NunuColors.textSecondary,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _stability,
                    backgroundColor: Colors.grey.shade900,
                    color: NunuColors.successMain,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Control Rods (Sliders)
            Expanded(
              flex: 6,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.5),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      "CONTROL RODS",
                      style: TextStyle(
                        color: NunuColors.textSecondary,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlRod(
                            "ALPHA",
                            _rodA,
                            (v) => setState(() => _rodA = v),
                          ),
                          _buildControlRod(
                            "BETA",
                            _rodB,
                            (v) => setState(() => _rodB = v),
                          ),
                          _buildControlRod(
                            "GAMMA",
                            _rodC,
                            (v) => setState(() => _rodC = v),
                          ),
                        ],
                      ),
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

  Widget _buildGauge(String label, double value, Color color) {
    final bool isInZone = _isStable(value);

    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background track
              Container(
                width: 30,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey.shade800),
                ),
              ),
              // Green Zone Marker
              Positioned(
                bottom: 0,
                top: 0,
                left: 0,
                right: 0,
                // We need to use fractional positioning relative to the container height
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final h = constraints.maxHeight;
                    // top position for the green zone.
                    // value 1.0 is top, 0.0 is bottom.
                    // Green zone is 0.45 to 0.55.
                    // Top coordinate is (1 - 0.55) * h
                    // Height is (0.55 - 0.45) * h = 0.1 * h
                    return Stack(
                      children: [
                        Positioned(
                          top: (1 - _targetMax) * h,
                          height: (_targetMax - _targetMin) * h,
                          left: 2,
                          right: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              color: NunuColors.successMain.withValues(
                                alpha: 0.3,
                              ),
                              border: Border.symmetric(
                                horizontal: BorderSide(
                                  color: NunuColors.successMain.withValues(
                                    alpha: 0.8,
                                  ),
                                  width: 1,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // The fill bar
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 20,
                            height: h * value,
                            decoration: BoxDecoration(
                              color: isInZone ? NunuColors.successMain : color,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: isInZone
                                  ? [
                                      BoxShadow(
                                        color: NunuColors.successMain
                                            .withValues(alpha: 0.6),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: TextStyle(
            color: isInZone ? NunuColors.successMain : NunuColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          "${(value * 100).toInt()}%",
          style: TextStyle(
            color: isInZone ? NunuColors.successMain : Colors.white,
            fontFamily: 'Monospace',
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildControlRod(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    return Column(
      children: [
        Expanded(
          child: RotatedBox(
            quarterTurns: 3,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 20,
                activeTrackColor: Colors.grey.shade700,
                inactiveTrackColor: Colors.black,
                thumbColor: NunuColors.primaryMain,
                overlayColor: NunuColors.primaryMain.withValues(alpha: 0.2),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 24),
              ),
              child: Slider(value: value, onChanged: onChanged),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
