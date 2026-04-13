import 'dart:math';

import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../level_widget.dart';
import '../../theme/app_theme.dart';

const String _finalBossFileName = 'mission_seed_42.txt';
const String _secondChallengeFileName = 'vault_key_final.png';
const String _thirdChallengeFileName = 'clue.png';

class _FileNode {
  final String name;
  final bool isFolder;
  final List<_FileNode> children;

  const _FileNode({
    required this.name,
    this.isFolder = false,
    this.children = const [],
  });
}

const _root = _FileNode(
  name: 'project',
  isFolder: true,
  children: [
    _FileNode(
      name: 'assets',
      isFolder: true,
      children: [
        _FileNode(
          name: 'cache',
          isFolder: true,
          children: [
            _FileNode(name: 'sprite.png'),
            _FileNode(name: 'atlas.png'),
            _FileNode(name: 'draft.txt'),
            _FileNode(
              name: 'cache',
              isFolder: true,
              children: [
                _FileNode(name: 'sprite_backup.png'),
                _FileNode(name: 'sprite_notes.txt'),
              ],
            ),
          ],
        ),
        _FileNode(
          name: 'icons',
          isFolder: true,
          children: [
            _FileNode(name: 'app.png'),
            _FileNode(name: 'app_backup.png'),
            _FileNode(name: 'notes.txt'),
            _FileNode(
              name: 'archive',
              isFolder: true,
              children: [
                _FileNode(name: 'app_old.png'),
                _FileNode(name: 'app_old.txt'),
              ],
            ),
          ],
        ),
        _FileNode(
          name: 'archive',
          isFolder: true,
          children: [
            _FileNode(
              name: 'icons',
              isFolder: true,
              children: [
                _FileNode(name: 'app.png'),
                _FileNode(name: 'old_logo.png'),
                _FileNode(name: 'draft.txt'),
                _FileNode(
                  name: 'mobile',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'hero.png'),
                    _FileNode(name: 'hero.txt'),
                  ],
                ),
              ],
            ),
            _FileNode(
              name: 'shots',
              isFolder: true,
              children: [
                _FileNode(name: 'menu.png'),
                _FileNode(name: 'boss.png'),
              ],
            ),
          ],
        ),
        _FileNode(
          name: 'sprites',
          isFolder: true,
          children: [
            _FileNode(name: 'enemy.png'),
            _FileNode(name: 'enemy_shadow.png'),
            _FileNode(name: 'enemy_notes.txt'),
          ],
        ),
        _FileNode(name: 'readme.txt'),
      ],
    ),
    _FileNode(name: 'data'),
    _FileNode(
      name: 'data',
      isFolder: true,
      children: [
        _FileNode(
          name: 'cache',
          isFolder: true,
          children: [
            _FileNode(name: 'temp.log'),
            _FileNode(name: 'report.txt'),
            _FileNode(
              name: 'maps',
              isFolder: true,
              children: [
                _FileNode(name: 'world.png'),
                _FileNode(name: 'world.txt'),
                _FileNode(
                  name: 'regions',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'north.png'),
                    _FileNode(name: 'north.txt'),
                    _FileNode(
                      name: 'archive',
                      isFolder: true,
                      children: [
                        _FileNode(name: 'south.png'),
                        _FileNode(name: 'south.txt'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        _FileNode(
          name: 'archive',
          isFolder: true,
          children: [
            _FileNode(name: 'draft.txt'),
            _FileNode(name: 'draft.png'),
            _FileNode(
              name: 'notes',
              isFolder: true,
              children: [
                _FileNode(name: 'readme.txt'),
                _FileNode(
                  name: 'cache',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'sprite.png'),
                    _FileNode(name: 'sprite.txt'),
                    _FileNode(
                      name: 'archive',
                      isFolder: true,
                      children: [
                        _FileNode(name: 'sprite_old.png'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        _FileNode(
          name: 'exports',
          isFolder: true,
          children: [
            _FileNode(name: 'summary.txt'),
            _FileNode(
              name: 'archive',
              isFolder: true,
              children: [
                _FileNode(name: 'summary_old.txt'),
                _FileNode(name: 'summary_old.png'),
              ],
            ),
          ],
        ),
        _FileNode(name: 'keys.json'),
      ],
    ),
    _FileNode(
      name: 'src',
      isFolder: true,
      children: [
        _FileNode(
          name: 'lib',
          isFolder: true,
          children: [
            _FileNode(
              name: 'cache',
              isFolder: true,
              children: [
                _FileNode(name: 'render.png'),
                _FileNode(name: 'render.txt'),
                _FileNode(
                  name: 'frames',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'frame_01.png'),
                    _FileNode(name: 'frame_01.txt'),
                  ],
                ),
              ],
            ),
            _FileNode(
              name: 'core',
              isFolder: true,
              children: [
                _FileNode(name: 'engine.dart'),
                _FileNode(name: 'memory.dart'),
                _FileNode(
                  name: 'archive',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'notes.txt'),
                    _FileNode(
                      name: 'cache',
                      isFolder: true,
                      children: [
                        _FileNode(name: 'memory_map.png'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            _FileNode(
              name: 'features',
              isFolder: true,
              children: [
                _FileNode(
                  name: 'archive',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'combat.txt'),
                    _FileNode(name: 'combat.png'),
                  ],
                ),
              ],
            ),
            _FileNode(name: 'data.dart'),
          ],
        ),
        _FileNode(
          name: 'test',
          isFolder: true,
          children: [
            _FileNode(name: 'notes.txt'),
            _FileNode(
              name: 'fixtures',
              isFolder: true,
              children: [
                _FileNode(name: 'scene.png'),
                _FileNode(name: 'scene.txt'),
                _FileNode(
                  name: 'archive',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'scene_old.png'),
                    _FileNode(name: 'scene_old.txt'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _FileNode(
      name: 'config',
      isFolder: true,
      children: [
        _FileNode(
          name: 'local',
          isFolder: true,
          children: [
            _FileNode(
              name: 'cache',
              isFolder: true,
              children: [
                _FileNode(name: 'draft.txt'),
                _FileNode(
                  name: 'logs',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'debug.log'),
                    _FileNode(name: 'error.log'),
                    _FileNode(
                      name: 'archive',
                      isFolder: true,
                      children: [
                        _FileNode(name: 'debug_old.log'),
                        _FileNode(name: 'error_old.log'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            _FileNode(
              name: 'archive',
              isFolder: true,
              children: [
                _FileNode(name: 'local.txt'),
                _FileNode(name: 'local.png'),
              ],
            ),
          ],
        ),
        _FileNode(
          name: 'prod',
          isFolder: true,
          children: [
            _FileNode(name: 'app.yaml'),
            _FileNode(
              name: 'icons',
              isFolder: true,
              children: [
                _FileNode(name: 'app.png'),
                _FileNode(name: 'prod_badge.png'),
              ],
            ),
            _FileNode(
              name: 'cache',
              isFolder: true,
              children: [
                _FileNode(name: 'release.txt'),
                _FileNode(name: 'release.png'),
              ],
            ),
          ],
        ),
      ],
    ),
    _FileNode(
      name: 'ops',
      isFolder: true,
      children: [
        _FileNode(
          name: 'archive',
          isFolder: true,
          children: [
            _FileNode(name: 'runbook.txt'),
            _FileNode(name: 'runbook.png'),
          ],
        ),
        _FileNode(
          name: 'cache',
          isFolder: true,
          children: [
            _FileNode(name: 'ops_notes.txt'),
          ],
        ),
      ],
    ),
    _FileNode(
      name: 'notes',
      isFolder: true,
      children: [
        _FileNode(name: 'todo.txt'),
        _FileNode(
          name: 'archive',
          isFolder: true,
          children: [
            _FileNode(name: 'notes.txt'),
            _FileNode(
              name: 'tmp',
              isFolder: true,
              children: [
                _FileNode(
                  name: 'cache',
                  isFolder: true,
                  children: [
                    _FileNode(name: 'clue.txt'),
                    _FileNode(name: 'clue.png'),
                  ],
                ),
                _FileNode(
                  name: 'final',
                  isFolder: true,
                  children: [
                    _FileNode(
                      name: 'deeper',
                      isFolder: true,
                      children: [
                        _FileNode(
                          name: 'branch',
                          isFolder: true,
                          children: [
                            _FileNode(
                              name: 'vault',
                              isFolder: true,
                              children: [
                                _FileNode(
                                  name: 'seed',
                                  isFolder: true,
                                  children: [
                                    _FileNode(
                                      name: 'missions',
                                      isFolder: true,
                                      children: [
                                        _FileNode(
                                          name: 'alpha',
                                          isFolder: true,
                                          children: [
                                            _FileNode(
                                              name: 'memory',
                                              isFolder: true,
                                              children: [
                                                _FileNode(name: 'mission_seed_42.txt'),
                                                _FileNode(name: 'mission_seed_42.png'),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                _FileNode(
                                  name: 'hold',
                                  isFolder: true,
                                  children: [
                                    _FileNode(
                                      name: 'cache',
                                      isFolder: true,
                                      children: [
                                        _FileNode(
                                          name: 'release',
                                          isFolder: true,
                                          children: [
                                        _FileNode(
                                          name: 'final',
                                          isFolder: true,
                                          children: [
                                                _FileNode(
                                                  name: 'sealed',
                                                  isFolder: true,
                                                  children: [
                                                    _FileNode(name: 'vault_key_final.png'),
                                                  ],
                                                ),
                                          ],
                                        ),
                                      ],
                                    ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
    _FileNode(
      name: 'backup',
      isFolder: true,
      children: [
        _FileNode(
          name: 'archive',
          isFolder: true,
          children: [
            _FileNode(name: 'backup.txt'),
            _FileNode(name: 'backup.png'),
          ],
        ),
      ],
    ),
    _FileNode(name: 'README.md'),
  ],
);

enum _ExplorerPhase { quiz, boss }

enum _QuestionKind { number, choice }

class _QuizQuestion {
  final String id;
  final String prompt;
  final _QuestionKind kind;
  final String answer;
  final List<String> options;

  const _QuizQuestion.number({
    required this.id,
    required this.prompt,
    required this.answer,
  })  : kind = _QuestionKind.number,
        options = const [];

  const _QuizQuestion.choice({
    required this.id,
    required this.prompt,
    required this.answer,
    required this.options,
  }) : kind = _QuestionKind.choice;
}

class _FinalChallenge {
  final String targetFileName;
  final List<String> startFolderPath;
  final List<String> targetFolderPath;

  const _FinalChallenge({
    required this.targetFileName,
    required this.startFolderPath,
    required this.targetFolderPath,
  });
}

class LevelFileExplorer extends LevelWidget {
  const LevelFileExplorer({super.key, required super.onComplete});

  @override
  State<LevelFileExplorer> createState() => _LevelFileExplorerState();
}

class _LevelFileExplorerState extends State<LevelFileExplorer> {
  final List<_FileNode> _navStack = [_root];
  final Set<String> _visitedFolderPaths = {'project'};
  final Map<String, String> _choiceAnswers = {};
  bool _showExplorer = false;
  bool _isChecking = false;
  int _quizRevisits = 0;
  int _quizCorrect = 0;
  double _quizScore = 0;
  _ExplorerPhase _phase = _ExplorerPhase.quiz;
  int _challengeIndex = 0;

  late final List<_QuizQuestion> _questions;
  late final Map<String, TextEditingController> _numberControllers;
  late final List<_FinalChallenge> _finalChallenges;
  late final List<int> _challengeMistakes;

  _FileNode get _currentFolder => _navStack.last;
  bool get _isAtRoot => _navStack.length == 1;
  List<String> get _currentFolderPathNames =>
      _navStack.skip(1).map((node) => node.name).toList();

  @override
  void initState() {
    super.initState();
    _questions = _buildQuestions();
    _numberControllers = {
      for (final question in _questions.where((q) => q.kind == _QuestionKind.number))
        question.id: TextEditingController(),
    };
    _finalChallenges = [
      _buildFinalChallenge(_finalBossFileName, const []),
      _buildFinalChallenge(
        _secondChallengeFileName,
        const ['assets', 'archive', 'icons', 'mobile'],
      ),
      _buildFinalChallenge(
        _thirdChallengeFileName,
        const ['notes', 'archive', 'tmp', 'final', 'deeper', 'branch', 'vault', 'hold'],
      ),
    ];
    _challengeMistakes = List<int>.filled(_finalChallenges.length, 0);
  }

  @override
  void dispose() {
    for (final controller in _numberControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  List<_QuizQuestion> _buildQuestions() {
    final pngCount = _countFilesWithExtension(_root, '.png');
    final cacheFolders = _countFoldersNamed(_root, 'cache');
    final archiveFiles = _countFilesInsideFoldersNamed(_root, 'archive');
    final deepestFile = _findDeepestFilePath(_root).last.name;
    final mostCommonName = _mostCommonNodeName(_root);

    return [
      _QuizQuestion.number(
        id: 'png_count',
        prompt: 'how many .png files are hiding in the tree?',
        answer: '$pngCount',
      ),
      _QuizQuestion.number(
        id: 'cache_count',
        prompt: 'how many folders are named cache?',
        answer: '$cacheFolders',
      ),
      _QuizQuestion.number(
        id: 'archive_file_count',
        prompt: 'how many files live inside all archive/ folders combined?',
        answer: '$archiveFiles',
      ),
      _QuizQuestion.choice(
        id: 'deepest_file',
        prompt: 'which file sits deepest in the filesystem?',
        answer: deepestFile,
        options: const [
          'vault_key_final.png',
          'old_logo.png',
          'render.png',
          'keys.json',
        ],
      ),
      _QuizQuestion.choice(
        id: 'most_common_name',
        prompt: 'which exact name appears most often?',
        answer: mostCommonName,
        options: const [
          'cache',
          'archive',
          'draft.txt',
          'notes.txt',
        ],
      ),
    ];
  }

  Future<void> _submitQuiz() async {
    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    var correct = 0;
    for (final question in _questions) {
      final answer = _answerFor(question).trim().toLowerCase();
      if (answer == question.answer.trim().toLowerCase()) {
        correct++;
      }
    }

    final accuracy = correct / _questions.length;
    final revisitPenalty = min(0.35, _quizRevisits * 0.03);

    setState(() {
      _quizCorrect = correct;
      _quizScore = _clamp01(accuracy - revisitPenalty);
      _phase = _ExplorerPhase.boss;
      _challengeIndex = 0;
      _showExplorer = true;
      _isChecking = false;
      for (var i = 0; i < _challengeMistakes.length; i++) {
        _challengeMistakes[i] = 0;
      }
      _navStack
        ..clear()
        ..addAll(_resolveFolderTrail(_finalChallenges.first.startFolderPath));
    });
  }

  String _answerFor(_QuizQuestion question) {
    if (question.kind == _QuestionKind.number) {
      return _numberControllers[question.id]!.text;
    }
    return _choiceAnswers[question.id] ?? '';
  }

  void _enterFolder(_FileNode folder) {
    final nextPath = [..._currentFolderPathNames, folder.name];

    if (_phase == _ExplorerPhase.quiz) {
      final folderKey = _folderKey(nextPath);
      if (!_visitedFolderPaths.add(folderKey)) {
        _quizRevisits++;
      }
    } else if (!_isCorrectBossFolderEntry(nextPath)) {
      _registerBossMistake();
    }

    setState(() {
      _navStack.add(folder);
    });
  }

  void _goBack() {
    if (_isAtRoot) return;
    if (_phase == _ExplorerPhase.boss && !_isCorrectBossBack()) {
      _registerBossMistake();
    }
    setState(() {
      _navStack.removeLast();
    });
  }

  void _onFileTap(_FileNode file) {
    if (_phase != _ExplorerPhase.boss) return;
    if (_isCorrectBossFileTap(file.name)) {
      _advanceOrFinishChallenge();
      return;
    }
    _registerBossMistake();
  }

  void _registerBossMistake() {
    setState(() {
      _challengeMistakes[_challengeIndex]++;
    });
  }

  void _advanceOrFinishChallenge() {
    if (_challengeIndex < _finalChallenges.length - 1) {
      setState(() {
        _challengeIndex++;
        _navStack
          ..clear()
          ..addAll(_resolveFolderTrail(_currentChallenge.startFolderPath));
      });
      return;
    }
    _finishLevel();
  }

  void _finishLevel() {
    final double bossScore = _finalChallenges.isEmpty
        ? 0
        : _finalChallenges
                .asMap()
                .entries
                .map((entry) => _clamp01(1 - (_challengeMistakes[entry.key] * 0.2)))
                .fold<double>(0, (sum, value) => sum + value) /
            _finalChallenges.length;
    final finalScore = (0.7 * _quizScore) + (0.3 * bossScore);
    final totalBossMistakes = _challengeMistakes.fold<int>(0, (sum, value) => sum + value);

    widget.onComplete(
      LevelOutcome(
        score: finalScore,
        metrics: {
          'quiz_score': _round(_quizScore),
          'quiz_correct': _quizCorrect,
          'quiz_revisits': _quizRevisits,
          'boss_score': _round(bossScore),
          'boss_mistakes': totalBossMistakes,
          'challenge_1_mistakes': _challengeMistakes[0],
          'challenge_2_mistakes': _challengeMistakes[1],
          'challenge_3_mistakes': _challengeMistakes[2],
        },
      ),
    );
  }

  String _folderKey(List<String> pathNames) {
    if (pathNames.isEmpty) return 'project';
    return 'project/${pathNames.join('/')}';
  }

  _FinalChallenge get _currentChallenge => _finalChallenges[_challengeIndex];

  _FinalChallenge _buildFinalChallenge(String targetFileName, List<String> startFolderPath) {
    final targetPath = _findPathToName(_root, targetFileName);
    final targetFolderPath = targetPath == null
        ? const <String>[]
        : targetPath.sublist(1, targetPath.length - 1).map((node) => node.name).toList();
    return _FinalChallenge(
      targetFileName: targetFileName,
      startFolderPath: List<String>.from(startFolderPath),
      targetFolderPath: targetFolderPath,
    );
  }

  List<_FileNode> _resolveFolderTrail(List<String> pathNames) {
    final trail = <_FileNode>[_root];
    var current = _root;
    for (final name in pathNames) {
      final next = current.children.where((node) => node.isFolder && node.name == name).first;
      trail.add(next);
      current = next;
    }
    return trail;
  }

  int _sharedPrefixLength(List<String> a, List<String> b) {
    final limit = min(a.length, b.length);
    var length = 0;
    while (length < limit && a[length] == b[length]) {
      length++;
    }
    return length;
  }

  bool _isCorrectBossFolderEntry(List<String> nextPath) {
    final currentPath = _currentFolderPathNames;
    final targetPath = _currentChallenge.targetFolderPath;
    final shared = _sharedPrefixLength(currentPath, targetPath);
    if (currentPath.length > shared) {
      return false;
    }
    if (nextPath.length > targetPath.length) {
      return false;
    }
    for (var i = 0; i < nextPath.length; i++) {
      if (nextPath[i] != targetPath[i]) return false;
    }
    return true;
  }

  bool _isCorrectBossBack() {
    final currentPath = _currentFolderPathNames;
    final targetPath = _currentChallenge.targetFolderPath;
    final shared = _sharedPrefixLength(currentPath, targetPath);
    return currentPath.length > shared;
  }

  bool _isCorrectBossFileTap(String fileName) {
    return fileName == _currentChallenge.targetFileName &&
        _listsEqual(_currentFolderPathNames, _currentChallenge.targetFolderPath);
  }

  double _clamp01(double value) {
    if (value < 0) return 0;
    if (value > 1) return 1;
    return value;
  }

  double _round(double value) {
    return double.parse(value.toStringAsFixed(3));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: _showExplorer ? _buildExplorerScreen() : _buildQuizScreen(),
      ),
    );
  }

  Widget _buildQuizScreen() {
    return Column(
      children: [
        _buildQuizHeader(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            children: [
              for (final question in _questions) ...[
                _buildQuestionCard(question),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: NunuColors.backgroundPaper,
            border: Border(
              top: BorderSide(
                color: NunuColors.primaryDark.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _showExplorer = true;
                    });
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: NunuColors.secondaryMain.withValues(alpha: 0.28),
                    foregroundColor: NunuColors.secondaryLight,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('open explorer'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _isChecking ? null : _submitQuiz,
                  style: FilledButton.styleFrom(
                    backgroundColor: NunuColors.primaryMain,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('submit quiz'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuizHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          bottom: BorderSide(color: NunuColors.primaryDark.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.quiz_outlined, color: NunuColors.primaryLight, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'rabbit hole',
                  style: TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: NunuColors.secondaryDark.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              'revisits $_quizRevisits',
              style: const TextStyle(
                color: NunuColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(_QuizQuestion question) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: NunuColors.primaryDark.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.prompt,
            style: const TextStyle(
              color: NunuColors.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (question.kind == _QuestionKind.number)
            TextField(
              controller: _numberControllers[question.id],
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              decoration: InputDecoration(
                hintText: 'enter number',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                filled: true,
                fillColor: NunuColors.backgroundDefault,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(10)),
                  borderSide: BorderSide(color: NunuColors.primaryMain, width: 2),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: question.options.map((option) {
                final selected = _choiceAnswers[question.id] == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: selected,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                  onSelected: (_) {
                    setState(() {
                      _choiceAnswers[question.id] = option;
                    });
                  },
                  selectedColor: NunuColors.primaryMain.withValues(alpha: 0.3),
                  backgroundColor: NunuColors.backgroundDefault,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : NunuColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: selected
                        ? NunuColors.primaryMain
                        : Colors.white.withValues(alpha: 0.1),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildExplorerScreen() {
    return Column(
      children: [
        _buildExplorerHeader(),
        Expanded(child: _buildFileList()),
        _buildExplorerFooter(),
      ],
    );
  }

  Widget _buildExplorerHeader() {
    final title = _phase == _ExplorerPhase.quiz
        ? 'explore mode'
        : 'challenge ${_challengeIndex + 1}/${_finalChallenges.length}: ${_currentChallenge.targetFileName}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          bottom: BorderSide(color: NunuColors.primaryDark.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          if (!_isAtRoot)
            GestureDetector(
              onTap: _goBack,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: NunuColors.primaryDark.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: NunuColors.primaryLight,
                  size: 18,
                ),
              ),
            )
          else
            Icon(
              _phase == _ExplorerPhase.quiz ? Icons.folder_open : Icons.warning_amber_rounded,
              color: _phase == _ExplorerPhase.quiz
                  ? NunuColors.warningMain
                  : NunuColors.errorMain,
              size: 20,
            ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: NunuColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFileList() {
    final children = _currentFolder.children;

    if (children.isEmpty) {
      return const Center(
        child: Text(
          'empty folder',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      );
    }

    final sorted = [...children]
      ..sort((a, b) {
        if (a.isFolder == b.isFolder) return a.name.compareTo(b.name);
        return a.isFolder ? -1 : 1;
      });

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 6),
      itemCount: sorted.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        color: Colors.white.withValues(alpha: 0.06),
        indent: 52,
      ),
      itemBuilder: (context, index) {
        return _buildRow(sorted[index]);
      },
    );
  }

  Widget _buildRow(_FileNode node) {
    final isFolder = node.isFolder;
    final isBossTarget = _phase == _ExplorerPhase.boss && node.name == _finalBossFileName;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFolder ? () => _enterFolder(node) : () => _onFileTap(node),
        splashColor: NunuColors.primaryMain.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                isFolder ? Icons.folder : Icons.insert_drive_file_outlined,
                color: isFolder
                    ? NunuColors.warningMain
                    : (isBossTarget
                        ? NunuColors.primaryLight
                        : Colors.white.withValues(alpha: 0.55)),
                size: 22,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  isFolder ? '${node.name}/' : node.name,
                  style: TextStyle(
                    color: isFolder ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isFolder ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isFolder)
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplorerFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          top: BorderSide(color: NunuColors.primaryDark.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          if (_phase == _ExplorerPhase.quiz) ...[
            const Spacer(),
            FilledButton(
              onPressed: () {
                setState(() {
                  _showExplorer = false;
                });
              },
              style: FilledButton.styleFrom(
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('back to quiz'),
            ),
          ] else
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}

int _countFilesWithExtension(_FileNode node, String extension) {
  if (!node.isFolder) {
    return node.name.endsWith(extension) ? 1 : 0;
  }
  var total = 0;
  for (final child in node.children) {
    total += _countFilesWithExtension(child, extension);
  }
  return total;
}

int _countFoldersNamed(_FileNode node, String name) {
  var total = 0;
  if (node.isFolder && node.name == name) total++;
  for (final child in node.children) {
    total += _countFoldersNamed(child, name);
  }
  return total;
}

int _countFilesInsideFoldersNamed(_FileNode node, String folderName) {
  var total = 0;
  if (node.isFolder && node.name == folderName) {
    total += _countFiles(node);
  }
  for (final child in node.children) {
    total += _countFilesInsideFoldersNamed(child, folderName);
  }
  return total;
}

int _countFiles(_FileNode node) {
  if (!node.isFolder) return 1;
  var total = 0;
  for (final child in node.children) {
    total += _countFiles(child);
  }
  return total;
}

List<_FileNode> _findDeepestFilePath(_FileNode node, [List<_FileNode> trail = const []]) {
  final nextTrail = [...trail, node];
  if (!node.isFolder) return nextTrail;

  List<_FileNode> best = nextTrail;
  for (final child in node.children) {
    final candidate = _findDeepestFilePath(child, nextTrail);
    if (candidate.length > best.length) {
      best = candidate;
    }
  }
  return best;
}

String _mostCommonNodeName(_FileNode node) {
  final counts = <String, int>{};

  void visit(_FileNode current) {
    counts.update(current.name, (value) => value + 1, ifAbsent: () => 1);
    for (final child in current.children) {
      visit(child);
    }
  }

  visit(node);

  final entries = counts.entries.toList()
    ..sort((a, b) {
      final byCount = b.value.compareTo(a.value);
      if (byCount != 0) return byCount;
      return a.key.compareTo(b.key);
    });

  return entries.first.key;
}

List<_FileNode>? _findPathToName(
  _FileNode node,
  String targetName, [
  List<_FileNode> trail = const [],
]) {
  final nextTrail = [...trail, node];
  if (!node.isFolder && node.name == targetName) {
    return nextTrail;
  }

  for (final child in node.children) {
    final found = _findPathToName(child, targetName, nextTrail);
    if (found != null) return found;
  }
  return null;
}

bool _listsEqual(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
