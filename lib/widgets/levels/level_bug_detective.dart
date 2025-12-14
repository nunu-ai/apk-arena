import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelBugDetective extends LevelWidget {
  const LevelBugDetective({super.key, required super.onComplete});

  @override
  State<LevelBugDetective> createState() => _LevelBugDetectiveState();
}

class _CodeChallenge {
  final String title;
  final String language;
  final String code;
  final bool hasBug;
  final String? bugExplanation;

  const _CodeChallenge({
    required this.title,
    required this.language,
    required this.code,
    required this.hasBug,
    this.bugExplanation,
  });
}

class _LevelBugDetectiveState extends State<LevelBugDetective>
    with SingleTickerProviderStateMixin {
  int _currentRound = 0;
  bool _showingFeedback = false;
  bool? _lastAnswerCorrect;
  late List<_CodeChallenge> _challenges;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  // Pool of challenges - some have bugs, some don't
  static const List<_CodeChallenge> _allChallenges = [
    // BUG: Off-by-one error
    _CodeChallenge(
      title: 'user_service.py',
      language: 'python',
      hasBug: true,
      bugExplanation: 'IndexError: iterates to len(users) inclusive',
      code: '''def get_user_names(users):
    names = []
    i = 0
    while i <= len(users):
        names.append(users[i].name)
        i += 1
    return names''',
    ),

    // NO BUG: Correct implementation
    _CodeChallenge(
      title: 'calculator.js',
      language: 'javascript',
      hasBug: false,
      code: '''function divide(a, b) {
  if (b === 0) {
    throw new Error('Division by zero');
  }
  return a / b;
}''',
    ),

    // BUG: Missing await
    _CodeChallenge(
      title: 'api_client.ts',
      language: 'typescript',
      hasBug: true,
      bugExplanation: 'Missing await - returns Promise instead of data',
      code: '''async function fetchUser(id: string) {
  const response = fetch(`/api/users/\${id}`);
  return response.json();
}''',
    ),

    // NO BUG: Correct null check
    _CodeChallenge(
      title: 'user_handler.kt',
      language: 'kotlin',
      hasBug: false,
      code: '''fun getUserEmail(user: User?): String {
    return user?.email ?: "no-email@example.com"
}''',
    ),

    // BUG: Integer overflow
    _CodeChallenge(
      title: 'factorial.c',
      language: 'c',
      hasBug: true,
      bugExplanation: 'Integer overflow: 13! exceeds int32 max',
      code: '''int factorial(int n) {
    int result = 1;
    for (int i = 2; i <= n; i++) {
        result *= i;
    }
    return result;  // breaks for n > 12
}''',
    ),

    // NO BUG: Correct string comparison
    _CodeChallenge(
      title: 'auth.java',
      language: 'java',
      hasBug: false,
      code: '''public boolean verifyPassword(String input, String stored) {
    if (input == null || stored == null) {
        return false;
    }
    return stored.equals(input);
}''',
    ),

    // BUG: SQL Injection vulnerability
    _CodeChallenge(
      title: 'database.py',
      language: 'python',
      hasBug: true,
      bugExplanation: 'SQL injection: unsanitized user input in query',
      code: '''def find_user(username):
    query = f"SELECT * FROM users WHERE name = '{username}'"
    return db.execute(query)''',
    ),

    // NO BUG: Proper error handling
    _CodeChallenge(
      title: 'file_utils.go',
      language: 'go',
      hasBug: false,
      code: '''func readFile(path string) ([]byte, error) {
    data, err := os.ReadFile(path)
    if err != nil {
        return nil, fmt.Errorf("read failed: %w", err)
    }
    return data, nil
}''',
    ),

    // BUG: Race condition
    _CodeChallenge(
      title: 'counter.java',
      language: 'java',
      hasBug: true,
      bugExplanation: 'Race condition: increment is not atomic',
      code: '''public class Counter {
    private int count = 0;
    
    public void increment() {
        count = count + 1;  // not thread-safe
    }
    
    public int getCount() { return count; }
}''',
    ),

    // NO BUG: Correct boundary check
    _CodeChallenge(
      title: 'array_utils.rs',
      language: 'rust',
      hasBug: false,
      code: '''fn get_element(arr: &[i32], index: usize) -> Option<i32> {
    if index < arr.len() {
        Some(arr[index])
    } else {
        None
    }
}''',
    ),

    // BUG: Floating point comparison
    _CodeChallenge(
      title: 'payment.js',
      language: 'javascript',
      hasBug: true,
      bugExplanation: 'Floating point error: 0.1 + 0.2 !== 0.3',
      code: '''function checkBalance(balance, withdrawal) {
  const remaining = balance - withdrawal;
  if (remaining === 0.0) {
    return "Account empty";
  }
  return `Remaining: \$\${remaining}`;
}''',
    ),

    // NO BUG: Proper deep copy
    _CodeChallenge(
      title: 'clone_utils.py',
      language: 'python',
      hasBug: false,
      code: '''import copy

def duplicate_config(config):
    return copy.deepcopy(config)''',
    ),

    // BUG: Memory leak - event listener not removed
    _CodeChallenge(
      title: 'component.tsx',
      language: 'typescript',
      hasBug: true,
      bugExplanation: 'Memory leak: event listener never removed',
      code: '''function Component() {
  useEffect(() => {
    window.addEventListener('resize', handleResize);
    // missing cleanup return
  }, []);
  
  return <div>Content</div>;
}''',
    ),

    // NO BUG: Correct mutex usage
    _CodeChallenge(
      title: 'safe_map.go',
      language: 'go',
      hasBug: false,
      code: '''func (m *SafeMap) Get(key string) (string, bool) {
    m.mu.RLock()
    defer m.mu.RUnlock()
    val, ok := m.data[key]
    return val, ok
}''',
    ),

    // BUG: Null pointer dereference
    _CodeChallenge(
      title: 'user_display.dart',
      language: 'dart',
      hasBug: true,
      bugExplanation: 'Null dereference: user.address could be null',
      code: '''String getFullAddress(User user) {
  return user.address.street + ', ' + 
         user.address.city;  // address might be null
}''',
    ),

    // NO BUG: Proper optional chaining
    _CodeChallenge(
      title: 'config.ts',
      language: 'typescript',
      hasBug: false,
      code: '''function getTheme(config?: Config): string {
  return config?.theme?.name ?? 'default';
}''',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectRandomChallenges();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _selectRandomChallenges() {
    final shuffled = List<_CodeChallenge>.from(_allChallenges)..shuffle();
    _challenges = shuffled.take(3).toList();
  }

  void _handleAnswer(bool playerSaysBug) {
    if (_showingFeedback) return;

    final challenge = _challenges[_currentRound];
    final isCorrect = (playerSaysBug == challenge.hasBug);

    setState(() {
      _showingFeedback = true;
      _lastAnswerCorrect = isCorrect;
      if (!isCorrect) {
        _shakeController.forward(from: 0);
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      if (!isCorrect) {
        // Failed - restart
        widget.onComplete(false);
        return;
      }

      if (_currentRound == 2) {
        // All 3 correct!
        widget.onComplete(true);
        return;
      }

      // Next round
      setState(() {
        _currentRound++;
        _showingFeedback = false;
        _lastAnswerCorrect = null;
      });
    });
  }

  Color _getLanguageColor(String language) {
    switch (language) {
      case 'python':
        return const Color(0xFF3776AB);
      case 'javascript':
        return const Color(0xFFF7DF1E);
      case 'typescript':
        return const Color(0xFF3178C6);
      case 'kotlin':
        return const Color(0xFF7F52FF);
      case 'java':
        return const Color(0xFFED8B00);
      case 'c':
        return const Color(0xFF555555);
      case 'go':
        return const Color(0xFF00ADD8);
      case 'rust':
        return const Color(0xFFDEA584);
      case 'dart':
        return const Color(0xFF0175C2);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenge = _challenges[_currentRound];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0D1117),
            Color(0xFF161B22),
            Color(0xFF0D1117),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              _buildHeader(),
              const SizedBox(height: 16),

              // Progress indicator
              _buildProgressIndicator(),
              const SizedBox(height: 24),

              // Code card
              Expanded(
                child: AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (context, child) {
                    final shake = _lastAnswerCorrect == false
                        ? (1 - _shakeAnimation.value) *
                            10 *
                            ((_shakeAnimation.value * 20).round() % 2 == 0
                                ? 1
                                : -1)
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(shake, 0),
                      child: child,
                    );
                  },
                  child: _buildCodeCard(challenge),
                ),
              ),
              const SizedBox(height: 24),

              // Answer buttons
              _buildAnswerButtons(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: NunuColors.primaryMain.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: NunuColors.primaryMain.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bug_report,
                color: NunuColors.primaryMain,
                size: 18,
              ),
              const SizedBox(width: 6),
              const Text(
                'bug detective',
                style: TextStyle(
                  color: NunuColors.primaryMain,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'round ${_currentRound + 1}/3',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (index) {
        Color color;
        IconData? icon;

        if (index < _currentRound) {
          color = NunuColors.successMain;
          icon = Icons.check;
        } else if (index == _currentRound && _showingFeedback) {
          color = _lastAnswerCorrect == true
              ? NunuColors.successMain
              : NunuColors.errorMain;
          icon = _lastAnswerCorrect == true ? Icons.check : Icons.close;
        } else {
          color = Colors.white24;
          icon = null;
        }

        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
            height: 8,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(4),
            ),
            child: icon != null
                ? Center(
                    child: Icon(icon, size: 6, color: Colors.white),
                  )
                : null,
          ),
        );
      }),
    );
  }

  Widget _buildCodeCard(_CodeChallenge challenge) {
    final langColor = _getLanguageColor(challenge.language);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E2228),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _showingFeedback
              ? (_lastAnswerCorrect == true
                  ? NunuColors.successMain
                  : NunuColors.errorMain)
              : Colors.white10,
          width: _showingFeedback ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (_showingFeedback
                    ? (_lastAnswerCorrect == true
                        ? NunuColors.successMain
                        : NunuColors.errorMain)
                    : Colors.black)
                .withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // File tab
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF2D333B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: langColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    challenge.language,
                    style: TextStyle(
                      color: langColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    challenge.title,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (_showingFeedback)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: challenge.hasBug
                          ? NunuColors.errorMain.withValues(alpha: 0.2)
                          : NunuColors.successMain.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      challenge.hasBug ? 'BUG FOUND' : 'NO BUG',
                      style: TextStyle(
                        color: challenge.hasBug
                            ? NunuColors.errorMain
                            : NunuColors.successMain,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Code content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCodeBlock(challenge.code),
                  if (_showingFeedback &&
                      challenge.hasBug &&
                      challenge.bugExplanation != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: NunuColors.errorMain.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: NunuColors.errorMain.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: NunuColors.errorMain,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              challenge.bugExplanation!,
                              style: TextStyle(
                                color:
                                    NunuColors.errorMain.withValues(alpha: 0.9),
                                fontSize: 13,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    final lines = code.split('\n');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(lines.length, (index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 32,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 13,
                    fontFamily: 'monospace',
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  lines[index],
                  style: const TextStyle(
                    color: Color(0xFFE6EDF3),
                    fontSize: 13,
                    fontFamily: 'monospace',
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildAnswerButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildAnswerButton(
            label: 'no bug',
            icon: Icons.check_circle_outline,
            color: NunuColors.successMain,
            onTap: () => _handleAnswer(false),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildAnswerButton(
            label: 'bug found',
            icon: Icons.bug_report,
            color: NunuColors.errorMain,
            onTap: () => _handleAnswer(true),
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: _showingFeedback ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _showingFeedback
              ? color.withValues(alpha: 0.1)
              : color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _showingFeedback
                ? color.withValues(alpha: 0.2)
                : color.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: _showingFeedback
                  ? color.withValues(alpha: 0.4)
                  : color,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: _showingFeedback
                    ? color.withValues(alpha: 0.4)
                    : color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

