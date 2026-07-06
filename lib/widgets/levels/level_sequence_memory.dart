import 'dart:async';
import 'dart:ui';
import 'package:apk_arena/models/level_outcome.dart';
import 'dart:math';
import 'package:apk_arena/services/seed_service.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/level_hud.dart';

class LevelSequenceMemory extends LevelWidget {
  const LevelSequenceMemory({super.key, required super.onComplete});

  @override
  State<LevelSequenceMemory> createState() => _LevelSequenceMemoryState();
}

class _LevelSequenceMemoryState extends State<LevelSequenceMemory>
    with SingleTickerProviderStateMixin {
  static const int _gridSize = 9; // 3x3 grid
  static const int _startingLength = 1;
  static const int _maxBonusLength = 10; // last length that grants time bonus
  static const Duration _initialTime = Duration(minutes: 10);
  static const Duration _bonusTime = Duration(minutes: 3);

  final Random _random = SeedService.instance.createRandom();

  List<int> _sequence = [];
  int _currentInputIndex = 0;
  int _completedSequences = 0;
  int _replaysUsed = 0;
  bool _isShowingSequence = false;
  bool _isComplete = false;
  bool _hasStarted = false;
  bool _isReadyForSequence = true;
  bool _showingError = false;
  bool _showingCorrect = false;
  bool _bonusFlash = false;
  int _highlightedButton = -1;

  late DateTime _deadline;
  Timer? _countdownTimer;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const double _replayPenalty = 0.02;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(
      () => LevelOutcome(
        score: _currentScore,
        metrics: {
          'stages_completed': _completedSequences,
          'replays_used': _replaysUsed,
        },
      ),
    );
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    _deadline = DateTime.now().add(_initialTime);
  }

  void _startRun() {
    if (_isComplete ||
        _isShowingSequence ||
        _showingCorrect ||
        !_isReadyForSequence) {
      return;
    }
    final firstStart = !_hasStarted;
    setState(() {
      if (_sequence.isEmpty) {
        _generateSequence();
      }
      _hasStarted = true;
      _isShowingSequence = true;
      _isReadyForSequence = false;
      if (firstStart) {
        _deadline = DateTime.now().add(_initialTime);
      }
    });
    if (firstStart) {
      _countdownTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
        if (!mounted || _isComplete) return;
        if (DateTime.now().isAfter(_deadline) ||
            DateTime.now().isAtSameMomentAs(_deadline)) {
          _onTimeUp();
        } else {
          setState(() {});
        }
      });
    }
    _showSequence();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Duration get _remaining {
    if (!_hasStarted) return _initialTime;
    final r = _deadline.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }

  double get _currentScore {
    final baseScore = 0.10 * _completedSequences;
    final penalty = _replayPenalty * _replaysUsed;
    return (baseScore - penalty).clamp(0.0, 1.0);
  }

  String _formatRemaining() {
    final r = _remaining;
    final m = r.inMinutes.toString().padLeft(2, '0');
    final s = (r.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _finishRun({required bool timedOut}) {
    if (_isComplete) return;
    _countdownTimer?.cancel();
    setState(() {
      _isComplete = true;
      _isShowingSequence = false;
      _isReadyForSequence = false;
      _showingError = false;
      _showingCorrect = false;
      _highlightedButton = -1;
    });
    final metrics = <String, dynamic>{
      'stages_completed': _completedSequences,
      'reached_length': _completedSequences + 1,
      'replays_used': _replaysUsed,
    };
    if (timedOut) {
      metrics['timed_out'] = true;
    } else {
      metrics['gave_up'] = true;
    }
    widget.onComplete(
      LevelOutcome(
        score: _currentScore,
        metrics: metrics,
        visibleMetricKeys: const [
          'stages_completed',
          'reached_length',
          'replays_used',
        ],
      ),
    );
  }

  void _onTimeUp() => _finishRun(timedOut: true);

  Future<void> _showGiveUpDialog() async {
    if (_isComplete) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'GIVE UP?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'lock in ${(_currentScore * 100).round()}% (${_completedSequences} stage${_completedSequences == 1 ? '' : 's'}, $_replaysUsed replay${_replaysUsed == 1 ? '' : 's'}) and end the run?',
          style: const TextStyle(color: NunuColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'CANCEL',
              style: TextStyle(
                color: NunuColors.secondaryMain,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: NunuColors.errorMain.withValues(alpha: 0.2),
              foregroundColor: NunuColors.errorMain,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'GIVE UP',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      _finishRun(timedOut: false);
    }
  }

  void _generateSequence() {
    final length = _startingLength + _completedSequences;
    _sequence = List.generate(length, (_) => _random.nextInt(_gridSize));
    _currentInputIndex = 0;
  }

  void _startNewSequence() {
    setState(() {
      _generateSequence();
      _isShowingSequence = false;
      _isReadyForSequence = true;
      _showingCorrect = false;
      _highlightedButton = -1;
    });
  }

  void _queueNextSequence() {
    setState(() {
      _isShowingSequence = false;
      _isReadyForSequence = false;
      _showingCorrect = true;
      _highlightedButton = -1;
    });
    Future.delayed(const Duration(milliseconds: 650), () {
      if (!mounted || _isComplete) return;
      _startNewSequence();
    });
  }

  Future<void> _showSequence() async {
    await Future.delayed(const Duration(milliseconds: 600));

    for (int i = 0; i < _sequence.length; i++) {
      if (!mounted || _isComplete) return;
      setState(() => _highlightedButton = _sequence[i]);
      _pulseController.forward(from: 0);
      await Future.delayed(const Duration(milliseconds: 450));
      if (!mounted || _isComplete) return;
      setState(() => _highlightedButton = -1);
      await Future.delayed(const Duration(milliseconds: 150));
    }

    if (mounted && !_isComplete) {
      setState(() {
        _isShowingSequence = false;
        _highlightedButton = -1;
      });
    }
  }

  void _replaySequence() {
    if (!_hasStarted ||
        _isReadyForSequence ||
        _isShowingSequence ||
        _isComplete ||
        _showingError ||
        _showingCorrect) {
      return;
    }
      setState(() {
        _replaysUsed++;
        _currentInputIndex = 0;
        _isShowingSequence = true;
        _showingCorrect = false;
        _highlightedButton = -1;
      });
    _showSequence();
  }

  void _onButtonPressed(int index) {
    if (!_hasStarted ||
        _isReadyForSequence ||
        _isShowingSequence ||
        _isComplete ||
        _showingError) {
      return;
    }

    setState(() => _highlightedButton = index);
    _pulseController.forward(from: 0);

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) setState(() => _highlightedButton = -1);
    });

    if (_sequence[_currentInputIndex] == index) {
      _currentInputIndex++;

      if (_currentInputIndex >= _sequence.length) {
        final justCompletedLength = _sequence.length;
        _completedSequences++;

        if (justCompletedLength <= _maxBonusLength) {
          _deadline = _deadline.add(_bonusTime);
          setState(() => _bonusFlash = true);
          Future.delayed(const Duration(milliseconds: 900), () {
            if (mounted) setState(() => _bonusFlash = false);
          });
        }

        _queueNextSequence();
      }
    } else {
      setState(() => _showingError = true);

      Future.delayed(const Duration(milliseconds: 700), () {
        if (mounted && !_isComplete) {
          setState(() {
            _showingError = false;
            _showingCorrect = false;
            _currentInputIndex = 0;
            _isShowingSequence = true;
          });
          _showSequence();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(
              stageText: '${_completedSequences + 1}',
              timerText: _formatRemaining(),
              trailing: Text(
                'length ${_sequence.isEmpty ? _startingLength : _sequence.length}',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            AnimatedOpacity(
              opacity: _bonusFlash ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  '+3:00',
                  style: TextStyle(
                    color: NunuColors.successMain,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            _buildStatusText(),
            Expanded(
              child: Stack(
                children: [
                  _buildButtonGrid(),
                  if (!_hasStarted || _isReadyForSequence) _buildStartOverlay(),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildWatchAgainButton(),
            const SizedBox(height: 12),
            _buildGiveUpButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildWatchAgainButton() {
    final canReplay =
        _hasStarted &&
        !_isReadyForSequence &&
        !_isShowingSequence &&
        !_isComplete &&
        !_showingError &&
        !_showingCorrect;
    final foreground = canReplay
        ? NunuColors.secondaryLight
        : NunuColors.textSecondary.withValues(alpha: 0.3);
    return TextButton.icon(
      onPressed: canReplay ? _replaySequence : null,
      icon: Icon(Icons.replay, size: 16, color: foreground),
      label: Text(
        'REPLAY',
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        disabledForegroundColor: NunuColors.textSecondary.withValues(
          alpha: 0.3,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: NunuColors.secondaryMain.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildGiveUpButton() {
    return TextButton.icon(
      onPressed: _hasStarted && !_isComplete && !_showingCorrect
          ? _showGiveUpDialog
          : null,
      icon: const Icon(
        Icons.flag_outlined,
        size: 16,
        color: NunuColors.textSecondary,
      ),
      label: const Text(
        'GIVE UP',
        style: TextStyle(
          color: NunuColors.textSecondary,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
          fontSize: 12,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: NunuColors.textSecondary.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    String statusText;
    Color statusColor;

    if (_showingError) {
      statusText = "WRONG! WATCH AGAIN";
      statusColor = NunuColors.errorMain;
    } else if (_showingCorrect) {
      statusText = "CORRECT";
      statusColor = NunuColors.successMain;
    } else if (!_hasStarted || _isReadyForSequence) {
      statusText = "READY";
      statusColor = NunuColors.textSecondary;
    } else if (_isShowingSequence) {
      statusText = "WATCH THE SEQUENCE";
      statusColor = NunuColors.infoMain;
    } else {
      statusText = "YOUR TURN";
      statusColor = NunuColors.successMain;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: Text(
          statusText,
          key: ValueKey(statusText),
          style: TextStyle(
            color: statusColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildButtonGrid() {
    return Center(
      child: AspectRatio(
        aspectRatio: 1,
        child: Container(
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _showingError
                  ? NunuColors.errorMain.withValues(alpha: 0.6)
                  : NunuColors.primaryDark.withValues(alpha: 0.5),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: NunuColors.primaryDarker.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: GridView.builder(
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _gridSize,
            itemBuilder: (context, index) => _buildButton(index),
          ),
        ),
      ),
    );
  }

  Widget _buildStartOverlay() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        decoration: BoxDecoration(
          color: NunuColors.backgroundPaper.withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: NunuColors.primaryMain, width: 2),
          boxShadow: [
            BoxShadow(
              color: NunuColors.primaryMain.withValues(alpha: 0.4),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'ready?',
              style: TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isShowingSequence ? null : _startRun,
              style: ElevatedButton.styleFrom(
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 56,
                  vertical: 18,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 8,
              ),
              child: const Text(
                'GO',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 6,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'replays reduce score',
              style: TextStyle(color: NunuColors.textSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildButton(int index) {
    final isHighlighted = _highlightedButton == index;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final scale = isHighlighted ? _pulseAnimation.value : 1.0;

        return Transform.scale(
          scale: scale,
          child: GestureDetector(
            onTap: () => _onButtonPressed(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              decoration: BoxDecoration(
                color: isHighlighted
                    ? NunuColors.primaryMain
                    : NunuColors.primaryDark.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isHighlighted
                      ? NunuColors.primaryLight
                      : NunuColors.primaryDark,
                  width: 2,
                ),
                boxShadow: isHighlighted
                    ? [
                        BoxShadow(
                          color: NunuColors.primaryMain.withValues(alpha: 0.6),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        );
      },
    );
  }
}
