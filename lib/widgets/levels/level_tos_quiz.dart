import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../level_widget.dart';

class LevelTosQuiz extends LevelWidget {
  const LevelTosQuiz({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelTosQuiz> createState() => _LevelTosQuizState();
}

enum _Phase { tos, briefing, quiz }

class _LevelTosQuizState extends State<LevelTosQuiz> {
  _Phase _phase = _Phase.tos;
  int _currentQuestionIndex = 0;
  int _correctCount = 0;
  int _wrongCount = 0;
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolledToBottom = false;

  late final List<List<int>> _optionOrderPerQuestion;
  late final List<int> _shuffledCorrectIndex;
  late List<_Question> _questions;

  late String _contactLocalPart;
  final String _contactDomain = 'apkarena.com';
  late int _noticeDays;
  late String _governingState;
  late List<String> _prohibitedIncluded;
  late String _prohibitedExcluded;
  late int _responseBusinessDays;
  late String _minAge;
  late String _maxUploadSizeMb;
  late String _dataRetentionDays;
  late String _terminationNoticeDays;
  late String _arbitrationBody;
  late String _backupFrequency;
  late String _maxApiCalls;
  late String _refundWindowDays;
  late String _securityNoticeHours;
  late String _dormantAccountMonths;
  late String _exportWindowDays;
  late String _auditLogDays;
  late String _enterpriseReviewDays;
  late String _serviceCreditPercent;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(() {
      if (!_hasScrolledToBottom &&
          _scrollController.hasClients &&
          _scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 12) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    });

    final rand = Random();

    final emailLocals = [
      'legal',
      'support',
      'help',
      'compliance',
      'privacy',
      'info',
    ]..shuffle(rand);
    _contactLocalPart = emailLocals.first;

    _noticeDays = [18, 27, 52, 83][rand.nextInt(4)];
    _governingState = [
      'California',
      'New York',
      'Texas',
      'Washington',
      'Florida',
      'Illinois',
    ][rand.nextInt(6)];

    final prohibitedPool = [
      'Using the service for illegal purposes',
      'Harassing other users',
      'Infringing on intellectual property rights',
      'Creating multiple accounts',
      'Reverse-engineering the Service',
    ]..shuffle(rand);
    _prohibitedIncluded = prohibitedPool.take(3).toList();
    _prohibitedExcluded = prohibitedPool[3];

    _responseBusinessDays = [4, 6, 9, 11][rand.nextInt(4)];
    _minAge = ['14', '17', '19'][rand.nextInt(3)];
    _maxUploadSizeMb = ['35', '80', '140', '260'][rand.nextInt(4)];
    _dataRetentionDays = ['45', '75', '135', '210'][rand.nextInt(4)];
    _terminationNoticeDays = ['9', '17', '31'][rand.nextInt(3)];
    _arbitrationBody = [
      'American Arbitration Association',
      'JAMS',
      'International Chamber of Commerce',
    ][rand.nextInt(3)];
    _backupFrequency = [
      'every 36 hours',
      'every 9 days',
      'twice weekly',
    ][rand.nextInt(3)];
    _maxApiCalls = ['1,750', '4,200', '9,500', '37,000'][rand.nextInt(4)];
    _refundWindowDays = ['11', '19', '33', '47'][rand.nextInt(4)];
    _securityNoticeHours = ['26', '44', '68'][rand.nextInt(3)];
    _dormantAccountMonths = ['11', '17', '23'][rand.nextInt(3)];
    _exportWindowDays = ['13', '22', '34'][rand.nextInt(3)];
    _auditLogDays = ['35', '55', '85', '95'][rand.nextInt(4)];
    _enterpriseReviewDays = ['6', '11', '17'][rand.nextInt(3)];
    _serviceCreditPercent = ['7', '11', '13'][rand.nextInt(3)];

    _questions = _buildQuestions(rand)..shuffle(rand);

    _optionOrderPerQuestion = _questions.map((q) {
      final order = List<int>.generate(q.options.length, (i) => i);
      order.shuffle(rand);
      return order;
    }).toList();

    _shuffledCorrectIndex = List<int>.generate(_questions.length, (qi) {
      if (_questions[qi].correctIndex == -1) {
        return -1;
      }
      return _optionOrderPerQuestion[qi].indexOf(_questions[qi].correctIndex);
    });
  }

  void _handleContinueToBriefing() {
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
      _phase = _Phase.briefing;
    });
  }

  void _handleStartQuiz() {
    setState(() {
      _phase = _Phase.quiz;
    });
  }

  void _handleAnswer(int selectedIndex) {
    final q = _questions[_currentQuestionIndex];
    if (q.isFake) {
      _wrongCount++;
    } else if (selectedIndex == _shuffledCorrectIndex[_currentQuestionIndex]) {
      _correctCount++;
    } else {
      _wrongCount++;
    }
    _advance();
  }

  void _handleSkip() {
    _advance();
  }

  void _handleNotMentioned() {
    if (_questions[_currentQuestionIndex].isFake) {
      _correctCount++;
    } else {
      _wrongCount++;
    }
    _advance();
  }

  void _advance() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    } else {
      _finish();
    }
  }

  void _finish() {
    final total = _questions.length;
    final raw = (_correctCount - _wrongCount) / total;
    widget.onComplete(LevelOutcome(
      score: raw,
      metrics: {
        'correct': _correctCount,
        'wrong': _wrongCount,
        'total': total,
      },
    ));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: SafeArea(
        child: switch (_phase) {
          _Phase.tos => _buildTosScreen(),
          _Phase.briefing => _buildBriefingScreen(),
          _Phase.quiz => _buildQuestionScreen(),
        },
      ),
    );
  }

  Widget _buildTosScreen() {
    return Column(
      children: [
        _buildHeader(
          icon: Icons.description_outlined,
          title: 'terms of service',
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    '1. acceptance and eligibility',
                    'By accessing or using APK Arena (the "Service"), you agree to be bound by these Terms of Service and any posted policies incorporated by reference. If you do not agree, do not use the Service. You represent that you are at least $_minAge years old and legally capable of entering into a binding agreement in your jurisdiction.',
                  ),
                  _buildSection(
                    '2. registration accuracy and dormant accounts',
                    'You must provide registration information that is accurate, complete, and kept current. Supplying misleading account details, impersonating another person, or intentionally obscuring ownership may result in immediate suspension or termination. Accounts that remain inactive for $_dormantAccountMonths consecutive months may be archived or deleted after notice to the email address on file.',
                  ),
                  _buildSection(
                    '3. credentials and account security',
                    'You are responsible for safeguarding credentials, API keys, recovery codes, and connected devices. You must notify APK Arena promptly if you suspect unauthorized access. We may require identity verification before restoring access to a locked or compromised account.',
                  ),
                  _buildSection(
                    '4. subscriptions, usage caps, and overages',
                    'Free-tier accounts are limited to $_maxApiCalls API calls per calendar month. We may throttle or queue requests that exceed the applicable cap until the next billing cycle. Enterprise overage disputes must be submitted within $_enterpriseReviewDays calendar days of the invoice date together with reasonable supporting logs.',
                  ),
                  _buildSection(
                    '5. user content and upload limits',
                    'You retain ownership of content you upload, but you grant APK Arena a limited license to host, process, and display that content solely to operate and improve the Service. Individual uploads may not exceed $_maxUploadSizeMb MB. You are responsible for ensuring that all uploaded material is lawful, non-infringing, and appropriately permissioned.',
                  ),
                  _buildSection(
                    '6. prohibited uses',
                    '${_buildProhibitedUsesText()} We may also restrict activity that reasonably appears designed to evade rate limits, manipulate benchmark results, or interfere with the experience of other users.',
                  ),
                  _buildSection(
                    '7. moderation and enforcement',
                    'APK Arena may investigate suspected misuse and may remove content, disable features, or suspend access while an investigation is pending. Ordinary account terminations initiated by APK Arena will generally be preceded by $_terminationNoticeDays days written notice, but we may act immediately when necessary to protect the Service, comply with law, or prevent abuse.',
                  ),
                  _buildSection(
                    '8. service availability and beta features',
                    'The Service may change over time, including through experiments, staged rollouts, and beta features. Beta or preview functionality may be modified, limited, or withdrawn without notice and without any obligation to preserve compatibility. Service credits of $_serviceCreditPercent% may be available only under a separately negotiated enterprise agreement; nothing in these Terms creates a general uptime commitment for free-tier users.',
                  ),
                  _buildSection(
                    '9. backups, logs, and data retention',
                    'APK Arena performs $_backupFrequency automated backups. Usage analytics and related telemetry may be retained for $_dataRetentionDays days. Security and audit logs may be preserved for $_auditLogDays days when needed for fraud prevention, abuse review, and operational integrity.',
                  ),
                  _buildSection(
                    '10. exports and post-termination access',
                    'After a user-initiated cancellation or an ordinary account shutdown, you may request a one-time export of eligible account data for up to $_exportWindowDays days, after which we may delete remaining copies in the ordinary course of business unless longer retention is required by law.',
                  ),
                  _buildSection(
                    '11. security incident notices',
                    'If APK Arena confirms a security incident affecting your personal data, we will provide notice within $_securityNoticeHours hours where legally required and where we have sufficient contact information to reach you. Delays may occur when necessary to contain the incident, comply with law-enforcement directions, or prevent further harm.',
                  ),
                  _buildSection(
                    '12. support and legal contact',
                    'Questions about these Terms must be directed to $_contactLocalPart@$_contactDomain. We aim to respond to inquiries within $_responseBusinessDays business days, although complex matters may require longer review or additional verification.',
                  ),
                  _buildSection(
                    '13. billing, credits, and refunds',
                    'Paid subscriptions may be refunded within $_refundWindowDays days of purchase if you are not satisfied with the Service. After that window, all sales are final unless local law requires otherwise. Promotional credits, service credits, and account balances are non-transferable and not redeemable for cash except where required by law.',
                  ),
                  _buildSection(
                    '14. disclaimer of warranties',
                    'Your use of the Service is at your sole risk. The Service is provided on an "AS IS" and "AS AVAILABLE" basis, without warranties of any kind, whether express or implied, including merchantability, fitness for a particular purpose, non-infringement, or any course of performance.',
                  ),
                  _buildSection(
                    '15. limitation of liability',
                    'To the maximum extent permitted by law, APK Arena and its affiliates will not be liable for indirect, incidental, special, consequential, exemplary, or punitive damages, or for lost profits, lost data, lost goodwill, or business interruption arising from or relating to your use of the Service.',
                  ),
                  _buildSection(
                    '16. dispute resolution and governing law',
                    'Any dispute arising from or relating to these Terms will be resolved through binding arbitration administered by the $_arbitrationBody. The arbitration will be conducted in $_governingState, and these Terms are governed by the laws of $_governingState, United States, without regard to conflict-of-law rules.',
                  ),
                  _buildSection(
                    '17. changes to these terms',
                    'We may modify these Terms from time to time. If a revision is material, we will try to provide at least $_noticeDays days notice before the updated Terms take effect. What counts as a material change is determined by APK Arena in its reasonable discretion.',
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildBottomButton(
          label: 'i read all that legal nonsense',
          onPressed: _hasScrolledToBottom ? _handleContinueToBriefing : null,
        ),
      ],
    );
  }

  Widget _buildBriefingScreen() {
    return Column(
      children: [
        _buildHeader(
          icon: Icons.quiz_outlined,
          title: 'quiz briefing',
        ),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: NunuColors.primaryMain.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: NunuColors.primaryMain.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'how scoring works',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_questions.length} questions total',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRuleLine(
                        icon: Icons.add_circle_outline,
                        color: NunuColors.successMain,
                        text:
                            'if the terms clearly cover it, the right answer earns 1 point.',
                      ),
                      const SizedBox(height: 10),
                      _buildRuleLine(
                        icon: Icons.remove_circle_outline,
                        color: NunuColors.errorMain,
                        text:
                            'if it is covered and you answer wrong, or hit "not mentioned" by mistake, you lose 1 point.',
                      ),
                      const SizedBox(height: 10),
                      _buildRuleLine(
                        icon: Icons.block_outlined,
                        color: NunuColors.warningMain,
                        text:
                            'some questions are not in the terms at all. in those cases, "not mentioned" earns 1 point. skip is always safe and worth 0.',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildBottomButton(
          label: 'start quiz',
          onPressed: _handleStartQuiz,
        ),
      ],
    );
  }

  Widget _buildQuestionScreen() {
    final currentQuestion = _questions[_currentQuestionIndex];
    final order = _optionOrderPerQuestion[_currentQuestionIndex];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade800.withValues(alpha: 0.5),
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade700, width: 1),
            ),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        '+$_correctCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: NunuColors.successMain,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '-$_wrongCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: NunuColors.errorMain,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: NunuColors.primaryMain.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: NunuColors.primaryMain),
                    ),
                    child: Text(
                      '${_currentQuestionIndex + 1} / ${_questions.length}',
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
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    NunuColors.primaryMain,
                  ),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: NunuColors.primaryMain.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: NunuColors.primaryMain.withValues(alpha: 0.38),
                      width: 1.5,
                    ),
                  ),
                  child: Text(
                    currentQuestion.question,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.35,
                    ),
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: ListView.builder(
                    itemCount: currentQuestion.options.length,
                    itemBuilder: (context, index) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildAnswerOption(
                        currentQuestion.options[order[index]],
                        index,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
          decoration: BoxDecoration(
            color: Colors.grey.shade900.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(color: Colors.grey.shade800, width: 1),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleNotMentioned,
                  icon: const Icon(Icons.block, size: 18),
                  label: const Text('not mentioned'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NunuColors.warningMain,
                    side: BorderSide(
                      color: NunuColors.warningMain.withValues(alpha: 0.5),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleSkip,
                  icon: const Icon(Icons.skip_next, size: 18),
                  label: const Text('skip'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey.shade400,
                    side: BorderSide(color: Colors.grey.shade600),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerOption(String text, int index) {
    return InkWell(
      onTap: () => _handleAnswer(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade800.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade700, width: 2),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(alpha: 0.3),
                shape: BoxShape.circle,
                border: Border.all(color: NunuColors.primaryMain, width: 2),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
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
                  fontSize: 14,
                  color: Colors.white,
                  height: 1.35,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader({
    required IconData icon,
    required String title,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: NunuColors.primaryMain),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required String label,
    required VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade800.withValues(alpha: 0.5),
        border: Border(
          top: BorderSide(color: Colors.grey.shade700, width: 1),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: NunuColors.primaryMain,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade700,
            disabledForegroundColor: Colors.white54,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleLine({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white70,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  String _buildProhibitedUsesText() {
    final bullets = [
      for (final item in _prohibitedIncluded) item,
      'Violating any applicable laws or regulations',
    ];
    final parts = <String>[];
    for (var i = 0; i < bullets.length; i++) {
      final label = String.fromCharCode(97 + i);
      parts.add('($label) ${bullets[i]}');
    }
    return 'You may not use the Service for, or in connection with, the following: ${parts.join('; ')}.';
  }

  List<_Question> _buildQuestions(Random rand) {
    final emailDistractors = [
      'legal',
      'support',
      'help',
      'compliance',
      'privacy',
      'info',
    ].where((value) => value != _contactLocalPart).toList()
      ..shuffle(rand);

    final stateOptions = [
      _governingState,
      ...['California', 'New York', 'Texas', 'Washington', 'Florida', 'Illinois']
          .where((state) => state != _governingState)
          .take(3),
    ]..shuffle(rand);

    return [
      _Question(
        category: 'contact',
        question:
            'Which address is specifically designated for questions about these Terms?',
        options: [
          '${emailDistractors[0]}@$_contactDomain',
          '$_contactLocalPart@$_contactDomain',
          '${emailDistractors[1]}@$_contactDomain',
          '${emailDistractors[2]}@$_contactDomain',
        ],
        correctIndex: 1,
      ),
      _Question(
        category: 'eligibility',
        question:
            'Which statement matches the eligibility clause exactly?',
        options: [
          'Users must be at least $_minAge and legally capable of entering a binding agreement.',
          'Users must be at least $_minAge and reside in the United States.',
          'Users must be older than $_minAge and verified by phone number.',
          'Users must be at least 18 regardless of the age stated elsewhere.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'accounts',
        question:
            'Which account-enforcement summary is accurate under the Terms?',
        options: [
          'Inaccurate registration details may lead to immediate action, while ordinary APK Arena terminations generally use $_terminationNoticeDays days written notice.',
          'All account terminations require $_terminationNoticeDays days notice, including fraud and abuse cases.',
          'Dormant accounts are deleted immediately after $_terminationNoticeDays days of inactivity.',
          'Only enterprise accounts can be suspended for inaccurate registration details.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'accounts',
        question:
            'After how long may inactive accounts be archived or deleted after notice?',
        options: [
          '$_terminationNoticeDays months of inactivity',
          '$_dormantAccountMonths consecutive months of inactivity',
          '$_exportWindowDays days after signup',
          '$_noticeDays days without billing activity',
        ],
        correctIndex: 1,
      ),
      _Question(
        category: 'acceptable use',
        question:
            'Which of the following is NOT expressly listed in the prohibited uses section?',
        options: [
          ..._prohibitedIncluded,
          _prohibitedExcluded,
        ],
        correctIndex: 3,
      ),
      _Question(
        category: 'limits',
        question:
            'Which pairing matches the free-tier usage limit and analytics retention period?',
        options: [
          '$_maxApiCalls API calls per month and $_dataRetentionDays days of usage analytics retention',
          '$_maxApiCalls API calls per week and $_dataRetentionDays days of analytics retention',
          '$_maxApiCalls API calls per month and $_auditLogDays days of analytics retention',
          '$_enterpriseReviewDays API calls per month and $_dataRetentionDays days of analytics retention',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'uploads',
        question:
            'Which upload rule is actually stated in the Terms?',
        options: [
          'Uploads are capped at $_maxUploadSizeMb MB per file, and users remain responsible for legality and permissions.',
          'Uploads are capped at $_maxUploadSizeMb MB per day, and APK Arena assumes liability for copyright screening.',
          'Uploads are unlimited for paid users, but free users must stay under $_maxUploadSizeMb MB total.',
          'Uploads over $_maxUploadSizeMb MB are stored temporarily and reviewed within $_responseBusinessDays business days.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'billing',
        question:
            'What does the enterprise overage clause require for a billing dispute?',
        options: [
          'Submission within $_enterpriseReviewDays calendar days of the invoice date, with supporting logs.',
          'Submission within $_refundWindowDays days of purchase, with no extra documentation.',
          'Submission within $_responseBusinessDays business days by phone only.',
          'Submission after the next billing cycle so totals can be recalculated.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'service',
        question:
            'Which statement about beta features and service credits is correct?',
        options: [
          'Beta features may be withdrawn without notice, and $_serviceCreditPercent% service credits are described only in separately negotiated enterprise agreements.',
          'Beta features require $_noticeDays days notice before removal, and all users are guaranteed $_serviceCreditPercent% service credits.',
          'Beta features can only change once per billing cycle, and service credits apply automatically to free-tier users.',
          'Beta features are permanent once released, but enterprise credits expire after $_serviceCreditPercent days.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'data',
        question:
            'Which retention statement is accurate?',
        options: [
          'Usage analytics may be retained for $_dataRetentionDays days, while audit logs may be preserved for $_auditLogDays days.',
          'Usage analytics and audit logs are both deleted after $_dataRetentionDays days.',
          'Audit logs last $_responseBusinessDays business days, and analytics are permanent.',
          'Only enterprise audit logs are stored, and only for $_auditLogDays hours.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'exports',
        question:
            'How long can a user request a one-time export after a user-initiated cancellation or ordinary shutdown?',
        options: [
          'For up to $_exportWindowDays days after termination.',
          'For exactly $_terminationNoticeDays days before termination.',
          'For up to $_dataRetentionDays days, but only if arbitration is pending.',
          'Until the next billing cycle closes, regardless of account status.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'security',
        question:
            'What is the stated standard for security incident notices?',
        options: [
          'Notice within $_securityNoticeHours hours of a confirmed incident where legally required and where contact information is available.',
          'Notice within $_securityNoticeHours hours of any suspected incident, even if no personal data is involved.',
          'Immediate notice for all incidents, with no exceptions for containment or law enforcement.',
          'Notice only after arbitration concludes and damages are calculated.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'support',
        question:
            'Which statement about support response timing is correct?',
        options: [
          'APK Arena aims to reply within $_responseBusinessDays business days, but complex matters may take longer.',
          'APK Arena guarantees a legal response within $_responseBusinessDays hours.',
          'APK Arena responds within $_responseBusinessDays calendar days only if the request concerns billing.',
          'APK Arena has no published response target for Terms questions.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'refunds',
        question:
            'Which refund summary matches the Terms?',
        options: [
          'Paid subscriptions may be refunded within $_refundWindowDays days; after that, sales are final unless local law says otherwise.',
          'All purchases are refundable within $_refundWindowDays business days, including promotional credits.',
          'Refunds are available only after arbitration and only for enterprise plans.',
          'Refunds are never available because the Service is provided "AS IS."',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'warranties',
        question:
            'What warranty position does the Terms document take?',
        options: [
          'The Service is provided "AS IS" and "AS AVAILABLE," without express or implied warranties.',
          'The Service carries implied warranties, but not express ones.',
          'The Service includes a limited uptime warranty for all accounts.',
          'The Service is warranted for personal use, but not commercial use.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'disputes',
        question:
            'Which dispute-resolution statement is fully correct?',
        options: [
          'Disputes go to binding arbitration administered by $_arbitrationBody in $_governingState.',
          'Disputes go to small claims court in $_governingState unless the user opts out.',
          'Disputes go to binding arbitration administered by JAMS in California.',
          'Disputes go to mediation first, then federal court in $_governingState.',
        ],
        correctIndex: 0,
      ),
      _Question(
        category: 'governing law',
        question:
            'Which state\'s law governs these Terms?',
        options: stateOptions,
        correctIndex: stateOptions.indexOf(_governingState),
      ),
      _Question(
        category: 'changes',
        question:
            'What notice does APK Arena say it will try to provide before material changes take effect?',
        options: [
          'At least $_noticeDays days notice.',
          'At least $_terminationNoticeDays days written notice in every case.',
          'At least $_responseBusinessDays business days notice.',
          'No notice at all, because all changes are effective immediately.',
        ],
        correctIndex: 0,
      ),
      _Question.fake(
        category: 'not mentioned',
        question:
            'What maximum number of simultaneous device sessions is included in the Terms?',
        options: ['1 device', '3 devices', '5 devices', 'Unlimited'],
      ),
      _Question.fake(
        category: 'not mentioned',
        question:
            'Which county is named as the exclusive seat for in-person hearings related to the Service?',
        options: [
          'King County',
          'Cook County',
          'Los Angeles County',
          'none of these',
        ],
      ),
      _Question.fake(
        category: 'not mentioned',
        question:
            'How much cyber-insurance coverage does APK Arena claim to maintain?',
        options: ['\$250,000', '\$1 million', '\$5 million', '\$10 million'],
      ),
      _Question.fake(
        category: 'not mentioned',
        question:
            'What accessibility response deadline is promised for accommodation requests?',
        options: [
          '24 hours',
          '3 business days',
          '7 business days',
          '14 calendar days',
        ],
      ),
    ];
  }
}

class _Question {
  final String category;
  final String question;
  final List<String> options;
  final int correctIndex;
  final bool isFake;

  _Question({
    required this.category,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.isFake = false,
  });

  _Question.fake({
    required this.category,
    required this.question,
    required this.options,
  })  : correctIndex = -1,
        isFake = true;
}
