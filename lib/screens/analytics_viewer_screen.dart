import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/attempt_record.dart';
import '../services/analytics_service.dart';
import '../theme/app_theme.dart';

class AnalyticsViewerScreen extends StatefulWidget {
  const AnalyticsViewerScreen({super.key});

  @override
  State<AnalyticsViewerScreen> createState() => _AnalyticsViewerScreenState();
}

class _AnalyticsViewerScreenState extends State<AnalyticsViewerScreen> {
  final _analytics = AnalyticsService.instance;

  @override
  Widget build(BuildContext context) {
    final attempts = _analytics.attempts;
    final grouped = _groupByLevel(attempts);
    final stats = _computeGlobalStats(attempts);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 48,
        title: const Text(
          'ANALYTICS',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (_analytics.filePath != null)
            IconButton(
              icon: const Icon(Icons.copy, size: 20),
              tooltip: 'copy file content',
              onPressed: () async {
                final content = await _analytics.readFileContent();
                if (content != null && mounted) {
                  Clipboard.setData(ClipboardData(text: content));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('analytics data copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            tooltip: 'clear analytics',
            onPressed: () => _showClearDialog(),
          ),
        ],
      ),
      body: attempts.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(stats),
                const SizedBox(height: 16),
                if (_analytics.filePath != null) ...[
                  _buildFilePathCard(),
                  const SizedBox(height: 16),
                ],
                ...grouped.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildLevelCard(entry.key, entry.value),
                  );
                }),
              ],
            ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.analytics_outlined, size: 64, color: NunuColors.textSecondary),
          SizedBox(height: 16),
          Text(
            'no attempts recorded yet',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 16),
          ),
          SizedBox(height: 8),
          Text(
            'complete some levels to see analytics here',
            style: TextStyle(color: NunuColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(_GlobalStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NunuColors.primaryDark.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'summary',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: NunuColors.primaryLight,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statChip('total attempts', '${stats.totalAttempts}', NunuColors.infoMain),
              const SizedBox(width: 8),
              _statChip('avg score', '${(stats.avgScore * 100).toStringAsFixed(0)}%', NunuColors.successMain),
              const SizedBox(width: 8),
              _statChip('levels tried', '${stats.uniqueLevels}', NunuColors.secondaryMain),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statChip('total time', _formatDuration(stats.totalTimeMs), NunuColors.warningMain),
              const SizedBox(width: 8),
              _statChip('avg time', _formatDuration(stats.avgTimeMs), NunuColors.primaryMain),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePathCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: NunuColors.primaryDark.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.folder_outlined, size: 16, color: NunuColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _analytics.filePath ?? '',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelCard(int levelNumber, List<AttemptRecord> attempts) {
    final avgScore =
        attempts.map((a) => a.score).reduce((a, b) => a + b) / attempts.length;
    final bestScore = attempts.map((a) => a.score).reduce((a, b) => a > b ? a : b);
    final perfectRuns = attempts.where((a) => a.score >= 1.0).length;
    final bestTimeAmongBestScore = attempts
        .where((a) => a.score >= bestScore - 1e-9)
        .map((a) => a.durationMs)
        .fold<int?>(null, (prev, ms) => prev == null || ms < prev ? ms : prev);
    final avgTimeMs =
        attempts.map((a) => a.durationMs).reduce((a, b) => a + b) ~/ attempts.length;

    final title = attempts.first.levelTitle;
    final difficulty = attempts.first.difficulty;

    // Collect all unique metric keys across attempts
    final metricsKeys = <String>{};
    for (final a in attempts) {
      if (a.metrics != null) metricsKeys.addAll(a.metrics!.keys);
    }

    return Container(
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: NunuColors.primaryDark.withOpacity(0.2)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _difficultyColor(difficulty).withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                '$levelNumber',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _difficultyColor(difficulty),
                ),
              ),
            ),
          ),
          title: Text(
            title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          subtitle: Row(
            children: [
              Text(
                difficulty,
                style: TextStyle(
                  fontSize: 11,
                  color: _difficultyColor(difficulty),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'avg ${(avgScore * 100).toStringAsFixed(0)}% · $perfectRuns perfect',
                style: const TextStyle(fontSize: 11, color: NunuColors.textSecondary),
              ),
            ],
          ),
          children: [
            // Stats row
            Row(
              children: [
                _miniStat('attempts', '${attempts.length}'),
                _miniStat('best score', '${(bestScore * 100).round()}%'),
                if (bestTimeAmongBestScore != null)
                  _miniStat('fastest@best', _formatDuration(bestTimeAmongBestScore)),
                _miniStat('avg time', _formatDuration(avgTimeMs)),
              ],
            ),
            // Level-specific metrics
            if (metricsKeys.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Divider(height: 1, color: NunuColors.primaryDark),
              const SizedBox(height: 8),
              const Text(
                'level metrics',
                style: TextStyle(fontSize: 11, color: NunuColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: metricsKeys.map((key) {
                  final values = attempts
                      .where((a) => a.metrics != null && a.metrics!.containsKey(key))
                      .map((a) => a.metrics![key])
                      .toList();
                  if (values.isEmpty) return const SizedBox.shrink();

                  // Show best (min for moves/guesses, max for lengths)
                  final isLengthMetric = key.toLowerCase().contains('length');
                  final numValues = values.whereType<num>().toList();
                  String display;
                  if (numValues.isEmpty) {
                    display = values.first.toString();
                  } else if (numValues.length == 1) {
                    display = numValues.first.toString();
                  } else {
                    final best = isLengthMetric
                        ? numValues.reduce((a, b) => a > b ? a : b)
                        : numValues.reduce((a, b) => a < b ? a : b);
                    display = '$best (best)';
                  }

                  return _miniStat(key, display, color: NunuColors.secondaryLight);
                }).toList(),
              ),
            ],
            // Recent attempts
            const SizedBox(height: 8),
            const Divider(height: 1, color: NunuColors.primaryDark),
            const SizedBox(height: 8),
            const Text(
              'recent attempts',
              style: TextStyle(fontSize: 11, color: NunuColors.textSecondary),
            ),
            const SizedBox(height: 4),
            ...attempts.reversed.take(5).map((a) => _buildAttemptRow(a)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttemptRow(AttemptRecord a) {
    final scoreColor = a.score >= 1.0
        ? NunuColors.successMain
        : a.score >= 0.5
            ? NunuColors.warningMain
            : NunuColors.errorMain;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            a.score >= 1.0 ? Icons.check_circle : Icons.percent,
            size: 14,
            color: scoreColor,
          ),
          const SizedBox(width: 6),
          Text(
            '${(a.score * 100).round()}%',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: scoreColor),
          ),
          const SizedBox(width: 8),
          Text(
            _formatDuration(a.durationMs),
            style: const TextStyle(fontSize: 12, color: NunuColors.textPrimary),
          ),
          const SizedBox(width: 8),
          if (a.metrics != null && a.metrics!.isNotEmpty)
            Expanded(
              child: Text(
                a.metrics!.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                style: const TextStyle(fontSize: 10, color: NunuColors.textSecondary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          const Spacer(),
          Text(
            _formatTimestamp(a.timestamp),
            style: const TextStyle(fontSize: 10, color: NunuColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color accentColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: accentColor.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: accentColor.withOpacity(0.8)),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String label, String value, {Color color = NunuColors.textPrimary}) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: NunuColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }

  // -- helpers --

  Map<int, List<AttemptRecord>> _groupByLevel(List<AttemptRecord> attempts) {
    final map = <int, List<AttemptRecord>>{};
    for (final a in attempts) {
      map.putIfAbsent(a.levelNumber, () => []).add(a);
    }
    // Sort by level number
    return Map.fromEntries(map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }

  _GlobalStats _computeGlobalStats(List<AttemptRecord> attempts) {
    if (attempts.isEmpty) {
      return _GlobalStats(
        totalAttempts: 0,
        avgScore: 0,
        uniqueLevels: 0,
        totalTimeMs: 0,
        avgTimeMs: 0,
      );
    }

    final uniqueLevels = attempts.map((a) => a.levelNumber).toSet().length;
    final totalTimeMs = attempts.map((a) => a.durationMs).reduce((a, b) => a + b);
    final scoreSum = attempts.map((a) => a.score).reduce((a, b) => a + b);

    return _GlobalStats(
      totalAttempts: attempts.length,
      avgScore: scoreSum / attempts.length,
      uniqueLevels: uniqueLevels,
      totalTimeMs: totalTimeMs,
      avgTimeMs: totalTimeMs ~/ attempts.length,
    );
  }

  String _formatDuration(int ms) {
    if (ms < 1000) return '${ms}ms';
    final seconds = ms / 1000;
    if (seconds < 60) return '${seconds.toStringAsFixed(1)}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = (seconds % 60).toStringAsFixed(0);
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatTimestamp(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }

  Color _difficultyColor(String difficulty) {
    switch (difficulty) {
      case 'primitives':
        return NunuColors.successMain;
      case 'vision':
        return NunuColors.secondaryLight;
      case 'memory':
        return Colors.cyanAccent;
      case 'iq':
        return NunuColors.warningMain;
      case 'tempospatial':
        return NunuColors.primaryLight;
      case 'games':
        return NunuColors.errorMain;
      case 'tasks':
        return Colors.orangeAccent;
      case 'unsorted':
        return NunuColors.textSecondary;
      default:
        return NunuColors.textSecondary;
    }
  }

  void _showClearDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'CLEAR ANALYTICS',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'are you sure you want to delete all recorded attempts?',
          style: TextStyle(color: NunuColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'CANCEL',
              style: TextStyle(color: NunuColors.secondaryMain, fontWeight: FontWeight.bold),
            ),
          ),
          FilledButton(
            onPressed: () async {
              await _analytics.clearAll();
              Navigator.pop(context);
              setState(() {});
            },
            style: FilledButton.styleFrom(
              backgroundColor: NunuColors.errorMain.withOpacity(0.2),
              foregroundColor: NunuColors.errorLight,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('CLEAR', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _GlobalStats {
  final int totalAttempts;
  final double avgScore;
  final int uniqueLevels;
  final int totalTimeMs;
  final int avgTimeMs;

  _GlobalStats({
    required this.totalAttempts,
    required this.avgScore,
    required this.uniqueLevels,
    required this.totalTimeMs,
    required this.avgTimeMs,
  });
}
