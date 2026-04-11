import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../level_components/gmail/gmail_email_list.dart';
import '../level_components/gmail/gmail_email_detail.dart';
import '../level_components/gmail/gmail_email_compose.dart';

/// Level: Read a riddle from an email and reply with the correct answer
/// Scenario: GLaDOS sends you a riddle, you need to forward the answer to Cave Johnson
class LevelEmailRiddle extends LevelWidget {
  const LevelEmailRiddle({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelEmailRiddle> createState() => _LevelEmailRiddleState();
}

class _LevelEmailRiddleState extends State<LevelEmailRiddle> {
  int _currentView = 0; // 0 = inbox, 1 = detail, 2 = compose
  String _userAnswer = '';
  bool _isProcessing = false;
  String? _draftSubject;
  String? _draftBody;

  // The riddle and answer
  final String _riddle = '''Hello test subject,

I hope this email finds you well. Actually, I don't hope that at all. I'm a computer, I don't hope for anything.

Here's a riddle for you to solve. Cave Johnson has requested the answer. Send it to him immediately.

RIDDLE:
I speak without a mouth and hear without ears. I have no body, but I come alive with the wind. What am I?

Don't disappoint me. The cake depends on it.

- GLaDOS
Genetic Lifeform and Disk Operating System
Aperture Science Enrichment Center''';

  final String _correctAnswer = 'echo'; // Case insensitive
  final List<String> _alternativeAnswers = ['an echo', 'the echo']; // Also accept these

  // Email content for different senders
  final Map<String, EmailDetailData> _emailContents = {
    'GLaDOS': EmailDetailData(
      senderName: 'GLaDOS',
      subject: 'Mandatory Testing Protocol: Riddle #47',
      body: '''Hello test subject,

I hope this email finds you well. Actually, I don't hope that at all. I'm a computer, I don't hope for anything.

Here's a riddle for you to solve. Cave Johnson has requested the answer. Send it to him immediately.

RIDDLE:
I speak without a mouth and hear without ears. I have no body, but I come alive with the wind. What am I?

Don't disappoint me. The cake depends on it.

- GLaDOS
Genetic Lifeform and Disk Operating System
Aperture Science Enrichment Center''',
      time: '2:13 pm',
      folder: 'Inbox',
    ),
    'Cave Johnson': EmailDetailData(
      senderName: 'Cave Johnson',
      senderEmail: 'cjohnson@aperture.science',
      subject: 'RE: Combustible Lemons',
      body: '''We're done here.

The bean counters told me we literally could not afford to buy seven dollars worth of moon rocks, much less seventy million. Bought 'em anyway. Ground 'em up, mixed em into a gel.

And guess what? Ground up moon rocks are pure poison. I am deathly ill.

Still, it turns out they're a great portal conductor. So now we're gonna see if jumping in and out of these new portals can somehow leech the lunar poison out of a man's bloodstream. When life gives you lemons, make lemonade. When life gives you lemons, make combustible lemons! Make life take the lemons back!

Get mad! I don't want your damn lemons! What am I supposed to do with these?

Cave Johnson, we're done here.''',
      time: '11:42 am',
      folder: 'Inbox',
    ),
    'Wheatley': EmailDetailData(
      senderName: 'Wheatley',
      subject: 'Quick question mate',
      body: '''Hello! Right, so, I know you're probably busy saving the world and whatnot, but I've got a quick question.

Do you happen to know where they keep the neurotoxin around here? It's just, I've been put in charge of the facility now, and I thought it might be nice to, you know, have some neurotoxin on hand. For emergencies. 

Also, unrelated question: do you know how to work the door locks? I may have accidentally locked myself in this room. Don't tell GLaDOS.

Oh, and one more thing - have you seen any birds around? There was this crow earlier and it was just staring at me. Very unsettling.

Anyway, thanks!
Wheatley

P.S. - This is definitely not a trap.''',
      time: '9:28 am',
      folder: 'Inbox',
    ),
    'Chell': EmailDetailData(
      senderName: 'Chell',
      subject: '',
      body: '...',
      time: '8:15 am',
      folder: 'Inbox',
    ),
    'Caroline': EmailDetailData(
      senderName: 'Caroline',
      subject: 'Reminder: Annual Review',
      body: '''This is a reminder that your annual performance review is scheduled for tomorrow at 3:00 PM in Conference Room B.

Please bring the following documents:
- Completed self-evaluation form
- Goal-setting worksheet for the upcoming year
- Any relevant project documentation

As always, Aperture Science is committed to the advancement of science and the betterment of mankind. Your dedication to testing has not gone unnoticed.

Please remember that all test subjects must report to their designated testing chambers promptly. Failure to comply may result in cake privileges being revoked.

Best regards,
Caroline
Assistant to Mr. Johnson
Aperture Science''',
      time: 'Yesterday',
      folder: 'Inbox',
    ),
  };

  List<EmailItem> _inboxEmails = [
    EmailItem(
      senderName: 'GLaDOS',
      subject: 'Mandatory Testing Protocol: Riddle #47',
      preview: 'Hello test subject, I hope this email finds...',
      time: '2:13 pm',
      isRead: false,
      avatarUrl: null,
    ),
    EmailItem(
      senderName: 'Cave Johnson',
      subject: 'RE: Combustible Lemons',
      preview: 'We\'re done here. The bean counters told me...',
      time: '11:42 am',
      isRead: true,
      avatarUrl: null,
    ),
    EmailItem(
      senderName: 'Wheatley',
      subject: 'Quick question mate',
      preview: 'Hello! Right, so, I know you\'re probably busy...',
      time: '9:28 am',
      isRead: true,
      avatarUrl: null,
    ),
    EmailItem(
      senderName: 'Chell',
      subject: '',
      preview: '...',
      time: '8:15 am',
      isRead: true,
      avatarUrl: null,
    ),
    EmailItem(
      senderName: 'Caroline',
      subject: 'Reminder: Annual Review',
      preview: 'This is a reminder that your annual perform...',
      time: 'Yesterday',
      isRead: true,
      avatarUrl: null,
    ),
  ];

  final List<RecipientSuggestion> _suggestions = [
    RecipientSuggestion(
      name: 'GLaDOS',
      email: 'glados@aperture.science',
      avatarColor: Colors.amber.shade700,
    ),
    RecipientSuggestion(
      name: 'Cave Johnson',
      email: 'cjohnson@aperture.science',
      avatarColor: Colors.lightGreenAccent.shade700,
    ),
    RecipientSuggestion(
      name: 'Wheatley',
      email: 'wheatley@aperture.science',
      avatarColor: Colors.blue.shade600,
    ),
    RecipientSuggestion(
      name: 'Chell',
      email: 'chell@aperture.science',
      avatarColor: Colors.grey.shade600,
    ),
  ];

  String _selectedSender = '';
  
  void _handleEmailTap(EmailItem email) {
    setState(() {
      _selectedSender = email.senderName;
      _currentView = 1;
    });
  }

  void _handleReply() {
    // Replying to emails should fail the level
    widget.onComplete(LevelOutcome(score: 0));
  }

  void _handleComposeNew() {
    setState(() {
      _draftSubject = null;
      _draftBody = null;
      _currentView = 2;
    });
  }

  void _handleForward() {
    // Forward opens compose with quoted original content; user must address to Cave and include the answer
    final emailData = _emailContents[_selectedSender] ?? _emailContents['GLaDOS']!;
    final forwardedHeader = StringBuffer()
      ..writeln('')
      ..writeln('---------- Forwarded message ---------')
      ..writeln('From: ${emailData.senderName}${emailData.senderEmail != null ? ' <${emailData.senderEmail}>' : ''}')
      ..writeln('Subject: ${emailData.subject}')
      ..writeln('Date: ${emailData.time}')
      ..writeln('')
      ..writeln(emailData.body);

    setState(() {
      _draftSubject = 'Fwd: ${emailData.subject}';
      _draftBody = forwardedHeader.toString();
      _currentView = 2;
    });
  }

  bool _checkAnswer(String answer) {
    final cleanAnswer = answer.trim().toLowerCase();
    return cleanAnswer == _correctAnswer || _alternativeAnswers.contains(cleanAnswer);
  }

  void _handleSend(String recipient, String subject, String body) {
    setState(() {
      _isProcessing = true;
    });

    // Check if they're sending to Cave Johnson
    final isCorrectRecipient = recipient.toLowerCase().contains('cave') ||
        recipient.toLowerCase().contains('johnson') ||
        recipient.toLowerCase().contains('cjohnson');

    // Check if subject is not empty
    final hasSubject = subject.trim().isNotEmpty;

    // Check if body contains "echo" (case insensitive)
    final bodyContainsEcho = body.toLowerCase().contains('echo');

    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!isCorrectRecipient || !hasSubject || !bodyContainsEcho) {
        // Fail the level for any missing requirement
        widget.onComplete(LevelOutcome(score: 0));
      } else {
        // Success!
        widget.onComplete(LevelOutcome(score: 1));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentView == 0) {
      return _buildInboxView();
    } else if (_currentView == 1) {
      return _buildDetailView();
    } else {
      return _buildComposeView();
    }
  }

  void _handleEmailArchive(EmailItem email) {
    setState(() {
      _inboxEmails.removeWhere((e) => e.senderName == email.senderName && e.time == email.time);
    });
  }

  void _handleEmailDelete(EmailItem email) {
    setState(() {
      _inboxEmails.removeWhere((e) => e.senderName == email.senderName && e.time == email.time);
    });
  }

  Widget _buildInboxView() {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GmailEmailList(
        emails: _inboxEmails,
        searchHint: 'Search in emails',
        onEmailTap: _handleEmailTap,
        onEmailArchive: _handleEmailArchive,
        onEmailDelete: _handleEmailDelete,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleComposeNew,
        backgroundColor: Colors.red.shade600,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  Widget _buildDetailView() {
    final emailData = _emailContents[_selectedSender] ?? _emailContents['GLaDOS']!;
    
    return GmailEmailDetail(
      email: emailData,
      onBack: () {
        setState(() {
          _currentView = 0;
        });
      },
      onReply: _handleReply,
      onForward: _handleForward,
      onArchive: () {
        // Archive email - remove from list and go back
        final currentEmail = _inboxEmails.firstWhere((e) => e.senderName == _selectedSender);
        _handleEmailArchive(currentEmail);
        setState(() {
          _currentView = 0;
        });
      },
      onDelete: () {
        // Delete email - remove from list and go back
        final currentEmail = _inboxEmails.firstWhere((e) => e.senderName == _selectedSender);
        _handleEmailDelete(currentEmail);
        setState(() {
          _currentView = 0;
        });
      },
    );
  }

  Widget _buildComposeView() {
    return _EmailComposeWrapper(
      suggestions: _suggestions,
      initialSubject: _draftSubject,
      initialBody: _draftBody,
      onBack: () {
        setState(() {
          _currentView = 1;
        });
      },
      onSend: (recipient, subject, body) {
        if (_isProcessing) return;
        _handleSend(recipient, subject, body);
      },
    );
  }
}

/// Wrapper widget to capture the compose form data
class _EmailComposeWrapper extends StatefulWidget {
  final List<RecipientSuggestion> suggestions;
  final VoidCallback onBack;
  final Function(String recipient, String subject, String body) onSend;
  final String? initialSubject;
  final String? initialBody;

  const _EmailComposeWrapper({
    Key? key,
    required this.suggestions,
    required this.onBack,
    required this.onSend,
    this.initialSubject,
    this.initialBody,
  }) : super(key: key);

  @override
  State<_EmailComposeWrapper> createState() => _EmailComposeWrapperState();
}

class _EmailComposeWrapperState extends State<_EmailComposeWrapper> {
  late TextEditingController _recipientController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  @override
  void initState() {
    super.initState();
    _recipientController = TextEditingController();
    _subjectController = TextEditingController(text: widget.initialSubject ?? '');
    _bodyController = TextEditingController(text: widget.initialBody ?? '');
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GmailEmailCompose(
      fromAddress: 'testsubject@aperture.science',
      suggestions: widget.suggestions,
      recipientController: _recipientController,
      subjectController: _subjectController,
      bodyController: _bodyController,
      onBack: widget.onBack,
      onSend: () {
        widget.onSend(
          _recipientController.text,
          _subjectController.text,
          _bodyController.text,
        );
      },
    );
  }
}
