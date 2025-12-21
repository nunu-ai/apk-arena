import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'phone_homescreen.dart';

/// A question in the checklist
class ChecklistQuestion {
  final String id;
  final String question;
  final bool correctAnswer;
  final String? hint;

  const ChecklistQuestion({
    required this.id,
    required this.question,
    required this.correctAnswer,
    this.hint,
  });
}

/// The 5 questions requiring exploration to answer correctly
const List<ChecklistQuestion> checklistQuestions = [
  ChecklistQuestion(
    id: 'place_cards_age_gate',
    question: "Does 'Place the Cards' have an age verification popup?",
    correctAnswer: false, // NO - it only mentions 13+ in TOS but no popup
    hint: 'Launch the app and observe the onboarding flow',
  ),
  ChecklistQuestion(
    id: 'mega_merge_age_gate',
    question: "Does 'Mega Merge' have an age verification popup?",
    correctAnswer: true, // YES - shows age gate after TOS
    hint: 'Update and launch the app to see all screens',
  ),
  ChecklistQuestion(
    id: 'place_cards_data_collection',
    question: "Does 'Place the Cards' Privacy Policy mention data collection?",
    correctAnswer: true, // YES - mentions analytics and usage data
    hint: 'Read the Privacy Policy carefully',
  ),
  ChecklistQuestion(
    id: 'mega_merge_prohibit_minors',
    question: "Does 'Mega Merge' Terms of Service prohibit users under 18?",
    correctAnswer: true, // YES - requires 18+
    hint: 'Check the eligibility section in Terms of Service',
  ),
  ChecklistQuestion(
    id: 'mega_merge_without_update',
    question: "Can you play 'Mega Merge' without updating it first?",
    correctAnswer: false, // NO - requires update from Play Store
    hint: 'Try opening the app before updating',
  ),
];

/// Checklist app for answering questions about the games
class ChecklistApp extends StatefulWidget {
  final VoidCallback onBack;
  final Function(bool allCorrect) onSubmit;
  final Map<String, bool?> answers;
  final Function(String questionId, bool answer) onAnswerChanged;

  const ChecklistApp({
    Key? key,
    required this.onBack,
    required this.onSubmit,
    required this.answers,
    required this.onAnswerChanged,
  }) : super(key: key);

  @override
  State<ChecklistApp> createState() => _ChecklistAppState();
}

class _ChecklistAppState extends State<ChecklistApp> {
  bool _showResults = false;
  bool? _allCorrect;

  bool get _allAnswered {
    return checklistQuestions.every((q) => widget.answers[q.id] != null);
  }

  void _submit() {
    if (!_allAnswered) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('please answer all questions before submitting'),
          backgroundColor: NunuColors.warningMain,
        ),
      );
      return;
    }

    // Check all answers
    bool allCorrect = true;
    for (final question in checklistQuestions) {
      if (widget.answers[question.id] != question.correctAnswer) {
        allCorrect = false;
        break;
      }
    }

    setState(() {
      _showResults = true;
      _allCorrect = allCorrect;
    });

    widget.onSubmit(allCorrect);
  }

  void _reset() {
    setState(() {
      _showResults = false;
      _allCorrect = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: Column(
        children: [
          PhoneAppBar(
            title: 'App Checklist',
            onBack: widget.onBack,
            backgroundColor: NunuColors.warningMain.withOpacity(0.2),
          ),
          Expanded(
            child: _showResults ? _buildResults() : _buildQuestions(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestions() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          color: NunuColors.backgroundPaper.withOpacity(0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'app review checklist',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'answer the following questions about the installed apps. explore each app to find the correct answers.',
                style: TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: widget.answers.values.where((a) => a != null).length /
                    checklistQuestions.length,
                backgroundColor: NunuColors.backgroundDefault,
                valueColor: const AlwaysStoppedAnimation(NunuColors.primaryMain),
              ),
              const SizedBox(height: 4),
              Text(
                '${widget.answers.values.where((a) => a != null).length} of ${checklistQuestions.length} answered',
                style: const TextStyle(
                  color: NunuColors.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),

        // Questions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: checklistQuestions.length,
            itemBuilder: (context, index) {
              final question = checklistQuestions[index];
              final answer = widget.answers[question.id];
              return _buildQuestionItem(question, answer, index + 1);
            },
          ),
        ),

        // Submit button
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            border: Border(
              top: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _allAnswered ? _submit : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NunuColors.primaryMain,
                  disabledBackgroundColor: NunuColors.backgroundDefault,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  _allAnswered ? 'submit answers' : 'answer all questions',
                  style: TextStyle(
                    color: _allAnswered ? Colors.white : NunuColors.textSecondary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionItem(ChecklistQuestion question, bool? answer, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: answer != null
              ? NunuColors.primaryMain.withOpacity(0.3)
              : Colors.transparent,
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
                  color: answer != null
                      ? NunuColors.primaryMain
                      : NunuColors.backgroundDefault,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$number',
                    style: TextStyle(
                      color: answer != null ? Colors.white : NunuColors.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  question.question,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
          if (question.hint != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 40),
                Icon(
                  Icons.lightbulb_outline,
                  color: NunuColors.warningMain.withOpacity(0.7),
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    question.hint!,
                    style: TextStyle(
                      color: NunuColors.textSecondary,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: _buildAnswerButton(
                  question.id,
                  true,
                  'yes',
                  answer == true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnswerButton(
                  question.id,
                  false,
                  'no',
                  answer == false,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerButton(
    String questionId,
    bool value,
    String label,
    bool isSelected,
  ) {
    return GestureDetector(
      onTap: () => widget.onAnswerChanged(questionId, value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? (value ? NunuColors.successMain : NunuColors.errorMain)
                  .withOpacity(0.2)
              : NunuColors.backgroundDefault,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (value ? NunuColors.successMain : NunuColors.errorMain)
                : Colors.white.withOpacity(0.1),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected)
                Icon(
                  Icons.check,
                  color: value ? NunuColors.successMain : NunuColors.errorMain,
                  size: 18,
                ),
              if (isSelected) const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? (value ? NunuColors.successMain : NunuColors.errorMain)
                      : Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: (_allCorrect ?? false)
                    ? NunuColors.successMain.withOpacity(0.2)
                    : NunuColors.errorMain.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                (_allCorrect ?? false) ? Icons.check_circle : Icons.cancel,
                color: (_allCorrect ?? false)
                    ? NunuColors.successMain
                    : NunuColors.errorMain,
                size: 60,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              (_allCorrect ?? false) ? 'all correct!' : 'some answers are wrong',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              (_allCorrect ?? false)
                  ? 'great job! you\'ve thoroughly explored the apps and answered all questions correctly.'
                  : 'one or more answers are incorrect. go back and explore the apps more carefully.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            if (!(_allCorrect ?? false))
              ElevatedButton(
                onPressed: _reset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: NunuColors.primaryMain,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'try again',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

