import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class _FileNode {
  final String name;
  final bool isFolder;
  final List<_FileNode> children;

  const _FileNode({
    required this.name,
    this.isFolder = false,
    this.children = const [],
  });

  /// Recursively count every *file* (non-folder) in this subtree.
  int get totalFiles {
    if (!isFolder) return 1;
    int count = 0;
    for (final child in children) {
      count += child.totalFiles;
    }
    return count;
  }
}

// ---------------------------------------------------------------------------
// File tree data
// ---------------------------------------------------------------------------

const _root = _FileNode(
  name: 'project',
  isFolder: true,
  children: [
    // --- data (file) -------------------------------------------------
    _FileNode(name: 'data'),
    // --- data/ (folder, same name!) ----------------------------------
    _FileNode(
      name: 'data',
      isFolder: true,
      children: [
        _FileNode(name: 'cache'),
        _FileNode(
          name: 'cache',
          isFolder: true,
          children: [
            _FileNode(name: 'temp'),
            // scroll-trap folder with 20 log files
            _FileNode(
              name: 'logs',
              isFolder: true,
              children: [
                _FileNode(name: 'access_01'),
                _FileNode(name: 'access_02'),
                _FileNode(name: 'access_03'),
                _FileNode(name: 'access_04'),
                _FileNode(name: 'access_05'),
                _FileNode(name: 'error_01'),
                _FileNode(name: 'error_02'),
                _FileNode(name: 'error_03'),
                _FileNode(name: 'error_04'),
                _FileNode(name: 'error_05'),
                _FileNode(name: 'debug_01'),
                _FileNode(name: 'debug_02'),
                _FileNode(name: 'debug_03'),
                _FileNode(name: 'debug_04'),
                _FileNode(name: 'debug_05'),
                _FileNode(name: 'crash_01'),
                _FileNode(name: 'crash_02'),
                _FileNode(name: 'crash_03'),
                _FileNode(name: 'crash_04'),
                _FileNode(name: 'crash_05'),
              ],
            ),
          ],
        ),
        _FileNode(name: 'backup'),
      ],
    ),
    // --- src/ ---------------------------------------------------------
    _FileNode(
      name: 'src',
      isFolder: true,
      children: [
        _FileNode(name: 'app'),
        _FileNode(
          name: 'lib',
          isFolder: true,
          children: [
            _FileNode(name: 'data'),
            _FileNode(
              name: 'core',
              isFolder: true,
              children: [
                _FileNode(name: 'engine'),
                _FileNode(name: 'config'),
              ],
            ),
            _FileNode(name: 'utils'),
          ],
        ),
        _FileNode(
          name: 'test',
          isFolder: true,
          children: [
            _FileNode(name: 'app'),
            _FileNode(name: 'mock'),
          ],
        ),
      ],
    ),
    // --- config/ ------------------------------------------------------
    _FileNode(
      name: 'config',
      isFolder: true,
      children: [
        _FileNode(name: 'dev'),
        _FileNode(name: 'prod'),
        _FileNode(
          name: 'local',
          isFolder: true,
          children: [
            _FileNode(name: 'dev'),
            _FileNode(name: 'keys'),
          ],
        ),
      ],
    ),
    // --- README (file) ------------------------------------------------
    _FileNode(name: 'README'),
  ],
);

// ---------------------------------------------------------------------------
// Level widget
// ---------------------------------------------------------------------------

class LevelFileExplorer extends LevelWidget {
  const LevelFileExplorer({super.key, required super.onComplete});

  @override
  State<LevelFileExplorer> createState() => _LevelFileExplorerState();
}

class _LevelFileExplorerState extends State<LevelFileExplorer> {
  final _answerController = TextEditingController();
  bool _isChecking = false;

  /// Navigation stack – each entry is the folder node currently being viewed.
  /// Starts at root.
  final List<_FileNode> _navStack = [_root];

  _FileNode get _currentFolder => _navStack.last;

  bool get _isAtRoot => _navStack.length == 1;

  int get _correctAnswer => _root.totalFiles;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  // ---- navigation -------------------------------------------------------

  void _enterFolder(_FileNode folder) {
    setState(() {
      _navStack.add(folder);
    });
  }

  void _goBack() {
    if (!_isAtRoot) {
      setState(() {
        _navStack.removeLast();
      });
    }
  }

  // ---- answer checking ---------------------------------------------------

  Future<void> _checkAnswer() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) {
      _showSnackbar('enter the total file count', Colors.orange);
      return;
    }

    final parsed = int.tryParse(text);
    if (parsed == null) {
      _showSnackbar('enter a number', Colors.orange);
      return;
    }

    setState(() => _isChecking = true);
    await Future.delayed(const Duration(milliseconds: 400));

    if (parsed == _correctAnswer) {
      widget.onComplete(true);
    } else {
      _showSnackbar('wrong — try again', NunuColors.errorMain);
      setState(() => _isChecking = false);
    }
  }

  void _showSnackbar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ---- build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NunuColors.backgroundDefault,
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildFileList()),
            _buildSubmitBar(),
          ],
        ),
      ),
    );
  }

  // -- header --------------------------------------------------------------

  Widget _buildHeader() {
    const double headerHeight = 42;

    return Container(
      height: headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: NunuColors.backgroundPaper,
        border: Border(
          bottom: BorderSide(
            color: NunuColors.primaryDark.withValues(alpha: 0.4),
          ),
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
            ),
          if (_isAtRoot)
            const Icon(
              Icons.folder_open,
              color: NunuColors.warningMain,
              size: 20,
            ),
        ],
      ),
    );
  }

  // -- file list -----------------------------------------------------------

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

    // Folders first, then files
    final sorted = [...children]
      ..sort((a, b) {
        if (a.isFolder == b.isFolder) return 0;
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
        final node = sorted[index];
        return _buildRow(node);
      },
    );
  }

  Widget _buildRow(_FileNode node) {
    final isFolder = node.isFolder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isFolder ? () => _enterFolder(node) : null,
        splashColor: NunuColors.primaryMain.withValues(alpha: 0.15),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // icon
              Icon(
                isFolder ? Icons.folder : Icons.insert_drive_file_outlined,
                color: isFolder
                    ? NunuColors.warningMain
                    : Colors.white.withValues(alpha: 0.55),
                size: 22,
              ),
              const SizedBox(width: 14),
              // name
              Expanded(
                child: Text(
                  isFolder ? '${node.name}/' : node.name,
                  style: TextStyle(
                    color: isFolder ? Colors.white : Colors.white70,
                    fontSize: 14,
                    fontWeight: isFolder ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ),
              // chevron for folders
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

  // -- submit bar ----------------------------------------------------------

  Widget _buildSubmitBar() {
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
          const Text(
            'total files:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: TextField(
              controller: _answerController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                filled: true,
                fillColor: NunuColors.backgroundDefault,
                hintText: '?',
                hintStyle: TextStyle(color: Colors.grey.shade700),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade700),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(
                    color: NunuColors.primaryMain,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: FilledButton(
              onPressed: _isChecking ? null : _checkAnswer,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: NunuColors.primaryMain,
                foregroundColor: Colors.white,
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
                  : const Text(
                      'submit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
