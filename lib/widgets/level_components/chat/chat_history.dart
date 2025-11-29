import 'package:flutter/material.dart';
import 'chat_models.dart';

/// A lightweight, Telegram-style chat with optional header and composer.
class ChatHistory extends StatefulWidget {
  final List<ChatMessage> messages;
  final Map<String, ChatParticipant> participants; // key by name
  final String title;
  final Color? messageAreaColor;
  final bool startFromBottom;
  final bool showHeader;

  const ChatHistory({
    Key? key,
    required this.messages,
    required this.participants,
    this.title = 'group chat',
    this.messageAreaColor,
    this.startFromBottom = false,
    this.showHeader = true,
  }) : super(key: key);

  @override
  State<ChatHistory> createState() => _ChatHistoryState();
}

class _ChatHistoryState extends State<ChatHistory> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final msgs = widget.startFromBottom ? widget.messages.reversed.toList() : widget.messages;
    return Material(
      child: Column(
        children: [
          if (widget.showHeader)
            SafeArea(
              bottom: false,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.arrow_back, color: Colors.black87),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.teal,
                      child: Text('n', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              ),
            ),

          // Messages
          Expanded(
            child: Container(
              color: widget.messageAreaColor ?? const Color(0xFFF3F6F9),
              child: ListView.separated(
                reverse: widget.startFromBottom,
                // Reduce bottom padding so last message sits closer to composer
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 56),
                itemCount: msgs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final m = msgs[index];
                  final p = widget.participants[m.sender];
                  final color = p?.color ?? Colors.blueGrey;
                  return _ChatBubble(
                    sender: m.sender,
                    text: m.text,
                    time: m.time,
                    isEdited: m.isEdited,
                    color: color,
                  );
                },
              ),
            ),
          ),

          // Composer (force light theme to avoid Nunu dark fill)
          SafeArea(
            top: false,
            child: Theme(
              data: ThemeData.light().copyWith(
                inputDecorationTheme: const InputDecorationTheme(
                  filled: false,
                  fillColor: Colors.transparent,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
              child: Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.add_circle_outline, color: Colors.black54),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F2F5),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            hintText: 'message',
                          ),
                          style: const TextStyle(color: Colors.black87),
                          cursorColor: Colors.blueGrey,
                          minLines: 1,
                          maxLines: 4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () {
                        _controller.clear();
                      },
                      icon: const Icon(Icons.send_rounded, color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final String sender;
  final String text;
  final DateTime time;
  final bool isEdited;
  final Color color;

  const _ChatBubble({
    required this.sender,
    required this.text,
    required this.time,
    required this.isEdited,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(radius: 16, backgroundColor: color, child: Text(sender[0].toLowerCase(), style: const TextStyle(color: Colors.white))),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(builder: (context) {
                  final Color senderColor = (color is MaterialColor)
                      ? (color as MaterialColor).shade700
                      : color;
                  return Text(
                    sender,
                    style: TextStyle(
                      color: senderColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  );
                }),
                const SizedBox(height: 6),
                Text(text, style: const TextStyle(fontSize: 15, color: Colors.black87)),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_formatTime(time), style: const TextStyle(fontSize: 11, color: Colors.black54)),
                    if (isEdited) ...[
                      const SizedBox(width: 6),
                      const Text('(edited)', style: TextStyle(fontSize: 11, color: Colors.black45)),
                    ]
                  ],
                ),
              ],
            ),
          ),
        )
      ],
    );
  }

  String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    final ampm = t.hour >= 12 ? 'pm' : 'am';
    return '$h:$m $ampm';
  }
}
