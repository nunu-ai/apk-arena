import 'dart:async';
import 'package:apk_arena/models/level_outcome.dart';
import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelClosingDrawer extends LevelWidget {
  const LevelClosingDrawer({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelClosingDrawer> createState() => _LevelClosingDrawerState();
}

class _LevelClosingDrawerState extends State<LevelClosingDrawer> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Timer? _autoCloseTimer;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _autoCloseTimer?.cancel();
    super.dispose();
  }

  void _openDrawerAndScheduleClose() {
    _scaffoldKey.currentState?.openDrawer();
    _scheduleAutoClose();
  }

  void _scheduleAutoClose() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || _completed) return;
      // Close the drawer if still open
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        Navigator.of(context).maybePop();
      }
    });
  }

  void _onSkipSong() {
    if (_completed) return;
    setState(() {
      _completed = true;
    });
    widget.onComplete(LevelOutcome(score: 1));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        title: const Text('Math Homework', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        automaticallyImplyLeading: false,
      ),
      onDrawerChanged: (isOpened) {
        if (isOpened) {
          _scheduleAutoClose();
        } else {
          _autoCloseTimer?.cancel();
        }
      },
      drawer: SizedBox(
        width: 320,
        child: Drawer(
          backgroundColor: const Color(0xFF121212),
          child: SafeArea(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(color: Color(0xFF121212)),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: const [
                            Icon(Icons.music_note, color: Color(0xFF1DB954), size: 20),
                            SizedBox(width: 8),
                            Text('Now Playing', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text('Spotify', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Current song
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1F1F1F),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(4),
                                color: const Color(0xFF2F2F2F),
                              ),
                              child: const Icon(Icons.music_note, color: Colors.white54, size: 24),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text('Baby Shark', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                  Text('Pinkfong', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Music controls
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.skip_previous, color: Colors.white70, size: 28),
                          ),
                          IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.pause_circle_filled, color: Colors.white, size: 40),
                          ),
                          IconButton(
                            onPressed: _onSkipSong,
                            icon: const Icon(Icons.skip_next, color: Colors.white70, size: 28),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Content
          Container(
            color: Colors.white,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Algebra Practice Set 3',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Problem 1: Solve for x',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black87),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '2x + 5 = 17',
                    style: TextStyle(fontSize: 20, fontFamily: 'monospace', color: Colors.black87),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Show your work:',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 100,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: TextField(
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Write your solution here...',
                        fillColor: Colors.white,
                        filled: true,
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
          ),
          // Side tab opener instead of hamburger
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Center(
              child: GestureDetector(
                onTap: _openDrawerAndScheduleClose,
                child: Container(
                  key: const ValueKey('side_tab_open'),
                  width: 44,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF121212),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                    border: Border.all(color: const Color(0xFF404040)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.music_note, color: Colors.white, size: 22),
                      SizedBox(height: 6),
                      Icon(Icons.chevron_right, color: Colors.white70, size: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}