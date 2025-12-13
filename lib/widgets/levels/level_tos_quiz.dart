import 'package:flutter/material.dart';
import 'dart:math';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelTosQuiz extends LevelWidget {
  const LevelTosQuiz({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelTosQuiz> createState() => _LevelTosMemoryState();
}

class _LevelTosMemoryState extends State<LevelTosQuiz> {
  bool _showQuestions = false;
  int _currentQuestionIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  // Shuffled option orders and derived correct indices per question
  late final List<List<int>> _optionOrderPerQuestion;
  late final List<int> _shuffledCorrectIndex;

  // Dynamic quiz data, built in initState for added randomness
  late List<Question> _questions;

  // Dynamic TOS parameters used in both the text and the quiz
  late String _contactLocalPart; // e.g., legal, support, help
  final String _contactDomain = 'apkarena.com';
  late int _noticeDays; // e.g., 15, 30, 60, 90
  late String _governingState; // e.g., California, New York, etc.
  late List<String> _prohibitedIncluded; // 3 included items
  late String _prohibitedExcluded; // the one NOT listed

  @override
  void initState() {
    super.initState();

    // Track scroll-to-bottom to unlock the quiz continue button
    _scrollController.addListener(() {
      if (!_hasScrolledToBottom &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 12) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    });

    // Build dynamic TOS parameters
    final rand = Random();

    // Email local part
    final emailLocals = ['legal', 'support', 'help', 'compliance', 'privacy', 'info'];
    emailLocals.shuffle(rand);
    _contactLocalPart = emailLocals.first;

    // Notice days
    final possibleDays = [15, 30, 60, 90];
    _noticeDays = possibleDays[rand.nextInt(possibleDays.length)];

    // Governing law state
    final states = ['California', 'New York', 'Texas', 'Washington', 'Florida', 'Illinois'];
    _governingState = states[rand.nextInt(states.length)];

    // Prohibited uses pool (choose 3 to include, 1 to exclude)
    final prohibitedPool = [
      'Using the service for illegal purposes',
      'Harassing other users',
      'Infringing on intellectual property rights',
      'Creating multiple accounts',
    ];
    prohibitedPool.shuffle(rand);
    _prohibitedIncluded = prohibitedPool.take(3).toList();
    _prohibitedExcluded = prohibitedPool.last;

    // Build questions based on dynamic parameters
    _questions = _buildDynamicQuestions(rand);

    // Shuffle question order for extra randomness
    _questions.shuffle(rand);

    // Precompute shuffled option orders and the visible correct index
    _optionOrderPerQuestion = _questions.map((q) {
      final order = List<int>.generate(q.options.length, (i) => i);
      order.shuffle(rand);
      return order;
    }).toList();
    _shuffledCorrectIndex = List<int>.generate(_questions.length, (qi) {
      return _optionOrderPerQuestion[qi].indexOf(_questions[qi].correctIndex);
    });
  }

  void _handleContinueToQuestions() {
    if (!_hasScrolledToBottom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('scroll to the bottom first'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    setState(() {
      _showQuestions = true;
    });
  }

  void _handleAnswer(int selectedIndex) {
    final currentQuestion = _questions[_currentQuestionIndex];

    // Map the tapped option (in shuffled order) to the visible correct index
    final isCorrect = selectedIndex == _shuffledCorrectIndex[_currentQuestionIndex];

    if (isCorrect) {
      // Correct answer
      if (_currentQuestionIndex < _questions.length - 1) {
        // Move to next question
        setState(() {
          _currentQuestionIndex++;
        });
      } else {
        // All questions answered correctly!
        widget.onComplete(true);
      }
    } else {
      // Wrong answer - fail the level
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect! You should have read more carefully.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );

      Future.delayed(const Duration(milliseconds: 2000), () {
        widget.onComplete(false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
      ),
      child: SafeArea(
        child: _showQuestions ? _buildQuestionScreen() : _buildTosScreen(),
      ),
    );
  }

  Widget _buildTosScreen() {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade700,
                width: 1,
              ),
            ),
          ),
          child: const Row(
            children: [
              Icon(Icons.description_outlined, color: NunuColors.primaryMain),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),

        // Scrollable content
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection('1. Acceptance of Terms',
                      'By accessing or using APK Arena (the "Service"), you agree to be bound by these Terms of Service. If you disagree with any part of these terms, you may not access the Service.'),

                  _buildSection('2. User Accounts',
                      'When you create an account with us, you must provide information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account on our Service.'),

                  _buildSection('3. Intellectual Property',
                      'The Service and its original content, features, and functionality are and will remain the exclusive property of APK Arena and its licensors. The Service is protected by copyright, trademark, and other laws of both the United States and foreign countries.'),

                  _buildSection('4. User Content',
                      'Our Service may allow you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material. You are responsible for the content that you post to the Service, including its legality, reliability, and appropriateness.'),

                  _buildSection('5. Prohibited Uses', _buildProhibitedUsesText()),

                  _buildSection('6. Limitation of Liability',
                      'In no event shall APK Arena, nor its directors, employees, partners, agents, suppliers, or affiliates, be liable for any indirect, incidental, special, consequential or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses, resulting from your access to or use of or inability to access or use the Service.'),

                  _buildSection('7. Disclaimer',
                      'Your use of the Service is at your sole risk. The Service is provided on an "AS IS" and "AS AVAILABLE" basis. The Service is provided without warranties of any kind, whether express or implied, including, but not limited to, implied warranties of merchantability, fitness for a particular purpose, non-infringement or course of performance.'),

                  _buildSection('8. Governing Law',
                      'These Terms shall be governed and construed in accordance with the laws of ${_governingState}, United States, without regard to its conflict of law provisions. Our failure to enforce any right or provision of these Terms will not be considered a waiver of those rights.'),

                  _buildSection('9. Changes to Terms',
                      'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. If a revision is material we will try to provide at least ${_noticeDays} days notice prior to any new terms taking effect. What constitutes a material change will be determined at our sole discretion.'),

                  _buildSection('10. Contact Us',
                      'If you have any questions about these Terms, please contact us at ${_contactLocalPart}@${_contactDomain}. We will respond to your inquiry within 5 business days.'),
                ],
              ),
            ),
          ),
        ),

        // Continue button
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha: 0.5),
            border: Border(
              top: BorderSide(
                color: Colors.grey.shade700,
                width: 1,
              ),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _hasScrolledToBottom ? _handleContinueToQuestions : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'I\'VE READ IT - CONTINUE',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final order = _optionOrderPerQuestion[_currentQuestionIndex];

    return Column(
      children: [
        // Progress header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade700,
                width: 1,
              ),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOS Quiz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: NunuColors.primaryMain.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: NunuColors.primaryMain,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'Question ${_currentQuestionIndex + 1}/${_questions.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: NunuColors.primaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / _questions.length,
                  backgroundColor: Colors.grey.shade700,
                  valueColor: const AlwaysStoppedAnimation<Color>(NunuColors.primaryMain),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),

        // Question content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: NunuColors.primaryMain.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: NunuColors.primaryMain.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.4,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Answer options
                ...List.generate(
                  currentQuestion.options.length,
                      (index) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildAnswerOption(
                      currentQuestion.options[order[index]],
                      index,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerOption(String text, int index) {
    return InkWell(
      onTap: () => _handleAnswer(index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey.shade700,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(
                  color: NunuColors.primaryMain,
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index), // A, B, C, D
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: NunuColors.primaryLight,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Build dynamic prohibited uses text section based on included items
  String _buildProhibitedUsesText() {
    final bullets = [
      for (final item in _prohibitedIncluded) item,
      'Violating any applicable laws or regulations',
    ];
    final parts = <String>[];
    for (var i = 0; i < bullets.length; i++) {
      final label = String.fromCharCode(97 + i); // a, b, c, ...
      parts.add('($label) ${bullets[i]}');
    }
    return 'You may not use the Service: ' + parts.join('; ') + '.';
  }

  // Construct questions reflecting the dynamic TOS content
  List<Question> _buildDynamicQuestions(Random rand) {
    // Email question
    final allLocals = ['legal', 'support', 'help', 'compliance', 'privacy', 'info'];
    final distractors = allLocals.where((l) => l != _contactLocalPart).toList()..shuffle(rand);
    final emailOptions = [
      '${distractors[0]}@$_contactDomain',
      '${_contactLocalPart}@$_contactDomain', // correct
      '${distractors[1]}@$_contactDomain',
      '${distractors[2]}@$_contactDomain',
    ];
    const emailCorrect = 1;

    // Governing law question
    final statesOptions = ['California', 'New York', 'Texas', 'Washington'];
    if (!statesOptions.contains(_governingState)) {
      statesOptions[0] = _governingState; // ensure the set contains the chosen state
    }
    statesOptions.shuffle(rand);
    final stateCorrect = statesOptions.indexOf(_governingState);

    // Notice days
    final daysOptionsRaw = [15, 30, 60, 90];
    final daysOptions = daysOptionsRaw.map((d) => '$d days').toList();
    final daysCorrect = daysOptions.indexOf('$_noticeDays days');

    // Prohibited uses (NOT listed)
    final prohibitedOptions = [
      ..._prohibitedIncluded,
      _prohibitedExcluded,
    ];
    final prohibitedCorrect = prohibitedOptions.length - 1; // excluded one

    // Warranties (kept static, still shuffled by option order)
    final warrantiesOptions = [
      'Limited warranties',
      'Express warranties only',
      'Implied warranties only',
      'No warranties of any kind',
    ];
    const warrantiesCorrect = 3;

    return [
      Question(
        question: 'What email should you contact for questions about the Terms?',
        options: emailOptions,
        correctIndex: emailCorrect,
      ),
      Question(
        question: 'Under which state\'s laws are these Terms governed?',
        options: statesOptions,
        correctIndex: stateCorrect,
      ),
      Question(
        question: 'How many days notice will APK Arena try to provide for material changes to the Terms?',
        options: daysOptions,
        correctIndex: daysCorrect,
      ),
      Question(
        question: 'Which of the following is NOT listed as a prohibited use?',
        options: prohibitedOptions,
        correctIndex: prohibitedCorrect,
      ),
      Question(
        question: 'What type of warranties does the Service provide?',
        options: warrantiesOptions,
        correctIndex: warrantiesCorrect,
      ),
    ];
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: NunuColors.primaryLight,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

class Question {
  final String question;
  final List<String> options;
  final int correctIndex;

  Question({
    required this.question,
    required this.options,
    required this.correctIndex,
  });
}
