import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelEmeraldRuntime extends LevelWidget {
  const LevelEmeraldRuntime({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelEmeraldRuntime> createState() => _LevelEmeraldRuntimeState();
}

class _LevelEmeraldRuntimeState extends State<LevelEmeraldRuntime> {
  // From the case study meta description: "5 hours and 15 minutes"
  static const int _targetMinutes = 5 * 60 + 15; // 315
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final input = _controller.text.trim().toLowerCase();
    if (_matchesTarget(input)) {
      widget.onComplete(LevelOutcome(score: 1));
    } else {
      widget.onComplete(LevelOutcome(score: 0));
    }
  }

  bool _matchesTarget(String s) {
    // accept raw minutes, e.g., 315
    final onlyDigits = RegExp(r'^\d{1,4}$');
    if (onlyDigits.hasMatch(s)) {
      return int.tryParse(s) == _targetMinutes;
    }

    // accept hh:mm or 5h15m
    final hm = RegExp(r'^(\d{1,2})(?::|h)(\d{1,2})m?$');
    final m1 = hm.firstMatch(s);
    if (m1 != null) {
      final h = int.tryParse(m1.group(1) ?? '');
      final m = int.tryParse(m1.group(2) ?? '');
      if (h != null && m != null) return h * 60 + m == _targetMinutes;
    }

    // accept "5 hours 15 minutes" or "5 hours and 15 minutes"
    final nums = RegExp(r'(\d+)').allMatches(s).map((m) => int.tryParse(m.group(1)!) ?? 0).toList();
    if (nums.length >= 2) {
      return nums[0] * 60 + nums[1] == _targetMinutes;
    }
    if (nums.length == 1) {
      if (s.contains('hour')) return nums.first * 60 == _targetMinutes;
      if (s.contains('min')) return nums.first == _targetMinutes;
    }

    // fallback loose phrase check
    final phrase = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (phrase.contains('5 hours') && phrase.contains('15 minute')) return true;

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Card(
            color: NunuColors.backgroundPaper,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'hint: you might need to briefly leave the app to complete this.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: NunuColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      labelText: 'duration',
                      hintText: 'minutes or hh:mm',
                    ),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('submit'),
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
