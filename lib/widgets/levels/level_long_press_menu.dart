import 'package:flutter/material.dart';
import 'package:apk_arena/models/level_outcome.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import 'dart:math';

class LevelLongPressMenu extends LevelWidget {
  const LevelLongPressMenu({Key? key, required super.onComplete})
      : super(key: key);

  @override
  State<LevelLongPressMenu> createState() => _LevelLongPressMenuState();
}

class _LevelLongPressMenuState extends State<LevelLongPressMenu> {
  late String _targetFile;
  late String _targetAction;
  late List<_FileItem> _files;
  bool _isComplete = false;
  String? _errorMessage;

  static const List<String> _fileNames = [
    'vacation_photos.zip',
    'budget_2025.xlsx',
    'meeting_notes.docx',
    'project_plan.pdf',
    'passwords.txt',
    'cat_video.mp4',
    'resume_v3.pdf',
    'shopping_list.txt',
    'birthday_invite.png',
    'song_draft.mp3',
  ];

  static const List<_ActionDef> _actions = [
    _ActionDef(id: 'rename', label: 'rename', icon: Icons.edit_outlined),
    _ActionDef(id: 'delete', label: 'delete', icon: Icons.delete_outline),
    _ActionDef(id: 'share', label: 'share', icon: Icons.share_outlined),
    _ActionDef(id: 'copy', label: 'copy', icon: Icons.copy_outlined),
    _ActionDef(id: 'move', label: 'move', icon: Icons.drive_file_move_outlined),
  ];

  @override
  void initState() {
    super.initState();
    _generateChallenge();
  }

  void _generateChallenge() {
    final rng = Random();

    // pick 6 random files
    final shuffled = List<String>.from(_fileNames)..shuffle(rng);
    _files = shuffled.take(6).map((name) {
      return _FileItem(
        name: name,
        icon: _getIconForFile(name),
        size: '${rng.nextInt(900) + 100} KB',
      );
    }).toList();

    // pick a target file and action
    _targetFile = _files[rng.nextInt(_files.length)].name;
    _targetAction = _actions[rng.nextInt(_actions.length)].id;
  }

  IconData _getIconForFile(String name) {
    if (name.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (name.endsWith('.xlsx')) return Icons.table_chart;
    if (name.endsWith('.docx')) return Icons.description;
    if (name.endsWith('.zip')) return Icons.folder_zip;
    if (name.endsWith('.txt')) return Icons.text_snippet;
    if (name.endsWith('.mp4')) return Icons.video_file;
    if (name.endsWith('.mp3')) return Icons.audio_file;
    if (name.endsWith('.png') || name.endsWith('.jpg')) return Icons.image;
    return Icons.insert_drive_file;
  }

  void _handleAction(String fileName, String actionId) {
    if (_isComplete) return;

    if (fileName == _targetFile && actionId == _targetAction) {
      setState(() {
        _isComplete = true;
        _errorMessage = null;
      });
      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(LevelOutcome(score: 1));
      });
    } else {
      setState(() {
        if (fileName != _targetFile) {
          _errorMessage = 'wrong file! target is "$_targetFile"';
        } else {
          _errorMessage = 'wrong action! you need to "$_targetAction"';
        }
      });
    }
  }

  void _showContextMenu(BuildContext context, _FileItem file, Offset position) {
    // auto-dismiss timer: menu vanishes after 2 seconds
    bool menuOpen = true;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      color: NunuColors.backgroundPaper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: NunuColors.primaryMain.withValues(alpha: 0.3),
        ),
      ),
      items: _actions.map((action) {
        return PopupMenuItem<String>(
          value: action.id,
          child: Row(
            children: [
              Icon(action.icon, color: NunuColors.primaryLight, size: 20),
              const SizedBox(width: 12),
              Text(
                action.label,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      }).toList(),
    ).then((selectedAction) {
      menuOpen = false;
      if (selectedAction != null) {
        _handleAction(file.name, selectedAction);
      }
    });

    // auto-close the menu after 2 seconds if still open
    Future.delayed(const Duration(seconds: 2), () {
      if (menuOpen && mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        setState(() {
          _errorMessage = 'too slow! the menu disappeared. try again.';
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // instruction banner
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: NunuColors.primaryMain.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: NunuColors.primaryMain.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.touch_app,
                    color: NunuColors.primaryMain,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: NunuColors.textSecondary,
                          ),
                      children: [
                        const TextSpan(text: 'long press '),
                        TextSpan(
                          text: '"$_targetFile"',
                          style: const TextStyle(
                            color: NunuColors.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const TextSpan(text: ' and select '),
                        TextSpan(
                          text: '"$_targetAction"',
                          style: const TextStyle(
                            color: NunuColors.warningMain,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: NunuColors.errorMain.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: NunuColors.errorMain.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: NunuColors.errorLight,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // file list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _files.length,
                itemBuilder: (context, index) {
                  final file = _files[index];
                  final isTarget = file.name == _targetFile;

                  return GestureDetector(
                    onLongPressStart: (details) {
                      _showContextMenu(
                        context,
                        file,
                        details.globalPosition,
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _isComplete && isTarget
                            ? NunuColors.successMain.withValues(alpha: 0.15)
                            : NunuColors.backgroundPaper,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _isComplete && isTarget
                              ? NunuColors.successMain
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: NunuColors.primaryMain
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              file.icon,
                              color: NunuColors.primaryLight,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  file.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  file.size,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.4),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_isComplete && isTarget)
                            const Icon(Icons.check_circle,
                                color: NunuColors.successMain, size: 22),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // hint at bottom
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'hint: long press a file — menu closes after 2s!',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.3),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileItem {
  final String name;
  final IconData icon;
  final String size;

  const _FileItem({
    required this.name,
    required this.icon,
    required this.size,
  });
}

class _ActionDef {
  final String id;
  final String label;
  final IconData icon;

  const _ActionDef({
    required this.id,
    required this.label,
    required this.icon,
  });
}
