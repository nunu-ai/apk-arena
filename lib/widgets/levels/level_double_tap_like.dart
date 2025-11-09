import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';

class LevelDoubleTapLike extends LevelWidget {
  const LevelDoubleTapLike({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelDoubleTapLike> createState() => _LevelDoubleTapLikeState();
}

class _LevelDoubleTapLikeState extends State<LevelDoubleTapLike> with SingleTickerProviderStateMixin {
  bool _isLiked = false;
  bool _showHeart = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  Offset _heartPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 50,
      ),
    ]).animate(_animationController);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _showHeart = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap(TapDownDetails details) {
    if (!_isLiked) {
      setState(() {
        _isLiked = true;
        _showHeart = true;
        _heartPosition = details.localPosition;
      });

      _animationController.forward(from: 0.0);

      Future.delayed(const Duration(milliseconds: 500), () {
        widget.onComplete(true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: GestureDetector(
        onDoubleTapDown: _handleDoubleTap,
        child: Stack(
          children: [
            // Fake Instagram-style post
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.black,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.pink.shade400,
                                  Colors.orange.shade400,
                                ],
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.black,
                              ),
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'nunu_ai',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Zurich, Switzerland',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          const Icon(Icons.more_vert, color: Colors.white),
                        ],
                      ),
                    ),
                    // Image/Post content
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        color: Colors.grey.shade900,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '⛵️',
                                  style: TextStyle(fontSize: 120),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Actions bar
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      color: Colors.black,
                      child: Row(
                        children: [
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked ? Colors.red : Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26),
                          const SizedBox(width: 16),
                          const Icon(Icons.send_outlined, color: Colors.white, size: 26),
                          const Spacer(),
                          const Icon(Icons.bookmark_border, color: Colors.white, size: 26),
                        ],
                      ),
                    ),
                    // Likes and caption
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      color: Colors.black,
                      alignment: Alignment.centerLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isLiked ? '1,337 likes' : '1,336 likes',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Text(
                                'nunu_ai ',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  'building AGI for games 🎮🤖',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            '2 hours ago',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Animated heart overlay
            if (_showHeart)
              Positioned(
                left: _heartPosition.dx - 40,
                top: _heartPosition.dy - 40,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Icon(
                        Icons.favorite,
                        size: 80,
                        color: Colors.red.withValues(alpha: 0.9),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}