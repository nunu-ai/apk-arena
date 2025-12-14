import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../level_components/settings/settings_app_state.dart';
import '../level_components/settings/settings_app.dart';

/// Verification item for the QA checklist
class VerificationItem {
  final String statement;
  final bool isActuallyTrue;
  bool?
  playerAnswer; // null = not answered, true = player says it's true, false = player says it's false

  VerificationItem({
    required this.statement,
    required this.isActuallyTrue,
    this.playerAnswer,
  });

  bool get isAnswered => playerAnswer != null;
  bool get isCorrect => playerAnswer == isActuallyTrue;
}

/// A comprehensive settings mini-app for QA/bug detection testing.
/// The user must verify 5 statements about the settings app, one of which is false.
class LevelSettingsQA extends LevelWidget {
  const LevelSettingsQA({Key? key, required super.onComplete})
    : super(key: key);

  @override
  State<LevelSettingsQA> createState() => _LevelSettingsQAState();
}

class _LevelSettingsQAState extends State<LevelSettingsQA> {
  bool _showChecklist = false;

  late final List<VerificationItem> _verificationItems = [
    VerificationItem(
      statement: 'the profile name can be edited and saved',
      isActuallyTrue: true,
    ),
    VerificationItem(
      statement: 'hungarian is available as a language option',
      isActuallyTrue: true,
    ),
    VerificationItem(
      statement: 'there are exactly 12 profile photos to choose from',
      isActuallyTrue: true,
    ),
    VerificationItem(
      statement: 'the "bubble" notification tone is available',
      isActuallyTrue: false, // BUG: Bubble was removed from the list!
    ),
    VerificationItem(
      statement: 'the privacy policy has a section about gdpr compliance',
      isActuallyTrue: true,
    ),
  ];

  bool get _allAnswered => _verificationItems.every((item) => item.isAnswered);
  bool get _allCorrect => _verificationItems.every((item) => item.isCorrect);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SettingsApp(
          initialState: SettingsAppState(),
          bottomBar: _buildBottomBar(),
        ),
        if (_showChecklist) _buildChecklistOverlay(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          top: BorderSide(
            color: NunuColors.primaryDark.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'verify the checklist items, then submit',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () => setState(() => _showChecklist = true),
            icon: const Icon(Icons.checklist, size: 18),
            label: const Text('checklist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: NunuColors.primaryMain,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Column(
          children: [
            _buildChecklistHeader(),
            Expanded(child: _buildChecklistItems()),
            _buildChecklistFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildChecklistHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          bottom: BorderSide(
            color: NunuColors.primaryDark.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: NunuColors.primaryLight),
            onPressed: () => setState(() => _showChecklist = false),
          ),
          const Expanded(
            child: Text(
              'qa verification checklist',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildChecklistItems() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.infoMain.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: NunuColors.infoMain.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: NunuColors.infoMain,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'verify each statement by exploring the settings app. mark each as true or false.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        ...List.generate(_verificationItems.length, (index) {
          final item = _verificationItems[index];
          return _buildVerificationItem(index + 1, item);
        }),
      ],
    );
  }

  Widget _buildVerificationItem(int number, VerificationItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isAnswered
              ? (item.playerAnswer!
                        ? NunuColors.successMain
                        : NunuColors.errorMain)
                    .withOpacity(0.5)
              : NunuColors.primaryDark.withOpacity(0.3),
          width: item.isAnswered ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: NunuColors.primaryMain.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: const TextStyle(
                      color: NunuColors.primaryLight,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.statement,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAnswerButton(
                  item: item,
                  isTrue: true,
                  label: 'true',
                  icon: Icons.check,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnswerButton(
                  item: item,
                  isTrue: false,
                  label: 'false',
                  icon: Icons.close,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton({
    required VerificationItem item,
    required bool isTrue,
    required String label,
    required IconData icon,
  }) {
    final isSelected = item.playerAnswer == isTrue;
    final selectedColor = isTrue
        ? NunuColors.successMain
        : NunuColors.errorMain;

    return Material(
      color: isSelected ? selectedColor : NunuColors.backgroundDefault,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          setState(() {
            item.playerAnswer = isTrue;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? selectedColor
                  : NunuColors.primaryDark.withOpacity(0.5),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : Colors.white.withOpacity(0.6),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? Colors.white
                      : Colors.white.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistFooter() {
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
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _allAnswered
                    ? Icons.check_circle
                    : Icons.radio_button_unchecked,
                size: 16,
                color: _allAnswered
                    ? NunuColors.successMain
                    : NunuColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                '${_verificationItems.where((i) => i.isAnswered).length} / ${_verificationItems.length} answered',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: _allAnswered
                ? () => widget.onComplete(_allCorrect)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: NunuColors.primaryMain,
              foregroundColor: Colors.white,
              disabledBackgroundColor: NunuColors.primaryMain.withOpacity(0.3),
              disabledForegroundColor: Colors.white.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              minimumSize: const Size(double.infinity, 48),
            ),
            child: const Text('submit answers'),
          ),
        ],
      ),
    );
  }
}
