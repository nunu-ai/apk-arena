import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/settings/settings_app_state.dart';
import '../level_components/settings/settings_app.dart';

/// A comprehensive settings mini-app for QA/bug detection testing.
/// The user must thoroughly explore all settings and determine if there's a bug.
class LevelSettingsQA extends LevelWidget {
  const LevelSettingsQA({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelSettingsQA> createState() => _LevelSettingsQAState();
}

class _LevelSettingsQAState extends State<LevelSettingsQA> {
  @override
  Widget build(BuildContext context) {
    return SettingsApp(
      initialState: SettingsAppState(),
      bottomBar: _buildVerdictBar(),
    );
  }
  
  Widget _buildVerdictBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          top: BorderSide(
            color: NunuColors.primaryDark.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'after reviewing all settings, what is your verdict?',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: NunuColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onComplete(true),
                  icon: const Icon(Icons.check_circle, size: 18),
                  label: const Text('no bug found'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NunuColors.successMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => widget.onComplete(false),
                  icon: const Icon(Icons.bug_report, size: 18),
                  label: const Text('bug detected'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: NunuColors.errorMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
