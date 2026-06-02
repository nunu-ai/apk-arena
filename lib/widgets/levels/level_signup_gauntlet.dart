import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_components/level_hud.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/signup_gauntlet/stage_airline.dart';
import '../level_components/signup_gauntlet/stage_bank.dart';
import '../level_components/signup_gauntlet/stage_government.dart';
import '../level_components/signup_gauntlet/stage_social.dart';
import '../level_components/signup_gauntlet/stage_enterprise.dart';

class LevelSignupGauntlet extends LevelWidget {
  const LevelSignupGauntlet({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelSignupGauntlet> createState() => _LevelSignupGauntletState();
}

class _StageInfo {
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;
  final Widget Function(void Function(double, Map<String, dynamic>)) builder;

  const _StageInfo({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
    required this.builder,
  });
}

enum _Phase { intro, playing, results }

class _LevelSignupGauntletState extends State<LevelSignupGauntlet> {
  int _currentStage = 0;
  _Phase _phase = _Phase.intro;
  final List<double> _stageScores = [];
  int _totalTraps = 0;

  @override
  void initState() {
    super.initState();
    widget.registerPartialScoreGetter(_buildTimeoutOutcome);
  }

  @override
  void dispose() {
    widget.clearPartialScoreGetter();
    super.dispose();
  }

  static final List<_StageInfo> _stages = [
    _StageInfo(
      name: 'FlyBudget',
      tagline: 'we get you there. eventually.',
      icon: Icons.flight,
      color: const Color(0xFF1565C0),
      builder: (cb) => StageAirline(onComplete: cb),
    ),
    _StageInfo(
      name: 'TrustVault',
      tagline: 'your money. our rules.',
      icon: Icons.account_balance,
      color: const Color(0xFF1A237E),
      builder: (cb) => StageBank(onComplete: cb),
    ),
    _StageInfo(
      name: 'MyGov Portal',
      tagline: 'built to last. in 2009.',
      icon: Icons.assured_workload,
      color: const Color(0xFF37474F),
      builder: (cb) => StageGovernment(onComplete: cb),
    ),
    _StageInfo(
      name: 'Vibes',
      tagline: 'share your moment',
      icon: Icons.auto_awesome,
      color: const Color(0xFF7B1FA2),
      builder: (cb) => StageSocial(onComplete: cb),
    ),
    _StageInfo(
      name: 'SynergyOS',
      tagline: 'enterprise solutions for enterprise problems.',
      icon: Icons.hub,
      color: const Color(0xFF00695C),
      builder: (cb) => StageEnterprise(onComplete: cb),
    ),
  ];

  void _onStageComplete(double score, Map<String, dynamic> metrics) {
    _stageScores.add(score.clamp(0.0, 1.0));
    _totalTraps += (metrics['traps_fallen'] as int?) ?? 0;
    setState(() => _phase = _Phase.results);
  }

  void _advance() {
    if (_currentStage < 4) {
      setState(() {
        _currentStage++;
        _phase = _Phase.intro;
      });
    } else {
      final avg = _stageScores.reduce((a, b) => a + b) / 5.0;
      widget.onComplete(
        LevelOutcome(
          score: avg,
          metrics: {
            'stages_completed': _stageScores.length,
            'traps_fallen': _totalTraps,
          },
        ),
      );
    }
  }

  LevelOutcome _buildTimeoutOutcome() {
    final completedScore = _stageScores.fold<double>(0, (sum, s) => sum + s);
    return LevelOutcome(
      score: completedScore / _stages.length,
      metrics: {
        'stages_completed': _stageScores.length,
        'traps_fallen': _totalTraps,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_phase) {
      case _Phase.intro:
        return _buildIntro();
      case _Phase.playing:
        return Column(
          children: [
            LevelHud(stageText: '${_currentStage + 1}/${_stages.length}'),
            Expanded(child: _stages[_currentStage].builder(_onStageComplete)),
          ],
        );
      case _Phase.results:
        return _buildResults();
    }
  }

  Widget _buildIntro() {
    final s = _stages[_currentStage];
    return Container(
      color: s.color,
      child: SafeArea(
        child: Column(
          children: [
            LevelHud(stageText: '${_currentStage + 1}/${_stages.length}'),
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(s.icon, size: 80, color: Colors.white),
                      const SizedBox(height: 20),
                      Text(
                        s.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        s.tagline,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Progress dots
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (i) {
                          final done = i < _currentStage;
                          final current = i == _currentStage;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: current ? 12 : 8,
                            height: current ? 12 : 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? Colors.white
                                  : current
                                  ? Colors.white
                                  : Colors.white30,
                              border: current
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 48),
                      FilledButton(
                        onPressed: () =>
                            setState(() => _phase = _Phase.playing),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: s.color,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 48,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'BEGIN',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final s = _stages[_currentStage];
    final score = _stageScores.last;
    final pct = (score * 100).toStringAsFixed(0);
    final isLast = _currentStage == 4;

    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(s.icon, size: 48, color: s.color),
                const SizedBox(height: 16),
                Text(
                  s.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'complete',
                  style: TextStyle(color: Colors.white60, fontSize: 16),
                ),
                const SizedBox(height: 32),
                Text(
                  '$pct%',
                  style: TextStyle(
                    color: score >= 0.8
                        ? NunuColors.successMain
                        : score >= 0.5
                        ? NunuColors.warningMain
                        : NunuColors.errorMain,
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 48),
                // Running totals
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _stat('${_stageScores.length}/5', 'stages'),
                      _stat('$_totalTraps', 'traps hit'),
                      _stat(
                        '${(_stageScores.reduce((a, b) => a + b) / _stageScores.length * 100).toStringAsFixed(0)}%',
                        'avg score',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _advance,
                  style: FilledButton.styleFrom(
                    backgroundColor: NunuColors.primaryMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 48,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    isLast ? 'SEE RESULTS' : 'NEXT STAGE',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }
}
