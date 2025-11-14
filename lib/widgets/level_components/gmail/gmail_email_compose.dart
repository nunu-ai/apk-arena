import 'package:flutter/material.dart';

/// A Gmail-style email compose widget
/// Note: This widget intentionally includes the overlapping suggestions issue
/// that the user mentioned - suggestions will overlap the subject field
class GmailEmailCompose extends StatefulWidget {
  final String? recipientHint;
  final String? subjectHint;
  final String? initialRecipient;
  final String? initialSubject;
  final String? initialBody;
  final bool isReply;
  final String fromAddress;
  final List<RecipientSuggestion> suggestions;
  final VoidCallback? onBack;
  final VoidCallback? onSend;
  final Function(String)? onRecipientChanged;
  final TextEditingController? recipientController;
  final TextEditingController? subjectController;
  final TextEditingController? bodyController;

  const GmailEmailCompose({
    Key? key,
    this.recipientHint,
    this.subjectHint,
    this.initialRecipient,
    this.initialSubject,
    this.initialBody,
    this.isReply = false,
    this.fromAddress = 'nunudemolt1@gmail.com',
    this.suggestions = const [],
    this.onBack,
    this.onSend,
    this.onRecipientChanged,
    this.recipientController,
    this.subjectController,
    this.bodyController,
  }) : super(key: key);

  @override
  State<GmailEmailCompose> createState() => _GmailEmailComposeState();
}

class _GmailEmailComposeState extends State<GmailEmailCompose> {
  late TextEditingController _recipientController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;

  bool _showSuggestions = false;
  List<RecipientSuggestion> _filteredSuggestions = [];
  final FocusNode _recipientFocusNode = FocusNode();
  final FocusNode _subjectFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _recipientController = widget.recipientController ??
        TextEditingController(text: widget.initialRecipient ?? '');
    _subjectController = widget.subjectController ??
        TextEditingController(text: widget.initialSubject ?? '');
    _bodyController = widget.bodyController ??
        TextEditingController(text: widget.initialBody ?? '');

    _recipientController.addListener(_onRecipientChanged);
    _recipientFocusNode.addListener(_onRecipientFocusChanged);
  }

  @override
  void dispose() {
    // Only dispose controllers we created
    if (widget.recipientController == null) {
      _recipientController.dispose();
    }
    if (widget.subjectController == null) {
      _subjectController.dispose();
    }
    if (widget.bodyController == null) {
      _bodyController.dispose();
    }
    _recipientFocusNode.dispose();
    _subjectFocusNode.dispose();
    super.dispose();
  }

  void _onRecipientChanged() {
    final text = _recipientController.text.toLowerCase();

    if (widget.onRecipientChanged != null) {
      widget.onRecipientChanged!(text);
    }

    setState(() {
      if (text.isEmpty) {
        _showSuggestions = false;
        _filteredSuggestions = [];
      } else {
        _filteredSuggestions = widget.suggestions.where((suggestion) {
          return suggestion.name.toLowerCase().contains(text) ||
              suggestion.email.toLowerCase().contains(text);
        }).toList();
        _showSuggestions = _filteredSuggestions.isNotEmpty && _recipientFocusNode.hasFocus;
      }
    });
  }

  void _onRecipientFocusChanged() {
    setState(() {
      if (_recipientFocusNode.hasFocus && _recipientController.text.isNotEmpty) {
        _showSuggestions = _filteredSuggestions.isNotEmpty;
      } else {
        _showSuggestions = false;
      }
    });
  }

  void _selectSuggestion(RecipientSuggestion suggestion) {
    setState(() {
      _recipientController.text = suggestion.name;
      _showSuggestions = false;
    });
    _subjectFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            surface: Colors.white,
            background: Colors.white,
          ),
        ),
        child: Container(
          color: Colors.grey.shade100,
          child: Column(
            children: [
          // Top app bar
          Container(
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: widget.onBack,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.attach_file, color: Colors.black87),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.black87),
                      onPressed: widget.onSend,
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.black87),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Email compose form
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  child: Container(
                    color: Colors.white,
                    child: Column(
                      children: [
                        // From field
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  widget.fromAddress,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // To field with intentional overlap issue
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _recipientController,
                                  focusNode: _recipientFocusNode,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                onPressed: () {},
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),

                        // Subject field
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 80,
                                child: Text(
                                  'Subject',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _subjectController,
                                  focusNode: _subjectFocusNode,
                                  maxLines: 1,
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Body field
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            controller: _bodyController,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              hintText: '',
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Suggestions overlay - positioned to overlap the subject field
                // This is the intentional bug mentioned by the user
                if (_showSuggestions)
                  Positioned(
                    top: 128, // Position right after the "To" field, overlapping subject
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                            child: Row(
                              children: [
                                Text(
                                  'Suggestions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
                              ],
                            ),
                          ),
                          ..._filteredSuggestions.map((suggestion) => _SuggestionItem(
                            suggestion: suggestion,
                            onTap: () => _selectSuggestion(suggestion),
                          )),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Bottom toolbar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.text_format, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.image_outlined, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.note_outlined, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.settings, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: Icon(Icons.more_horiz, color: Colors.grey.shade600),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Keyboard spacer would go here
          Container(
            height: MediaQuery.of(context).viewInsets.bottom,
            color: Colors.white,
          ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SuggestionItem extends StatelessWidget {
  final RecipientSuggestion suggestion;
  final VoidCallback onTap;

  const _SuggestionItem({
    Key? key,
    required this.suggestion,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: suggestion.avatarColor ?? Colors.grey.shade400,
              ),
              child: suggestion.avatarUrl != null
                  ? ClipOval(
                child: Image.network(
                  suggestion.avatarUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildAvatarFallback();
                  },
                ),
              )
                  : _buildAvatarFallback(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.name,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    suggestion.email,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: suggestion.avatarIcon != null
          ? Icon(suggestion.avatarIcon, color: Colors.white, size: 24)
          : Text(
        suggestion.name.isNotEmpty ? suggestion.name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Data model for recipient suggestions
class RecipientSuggestion {
  final String name;
  final String email;
  final String? avatarUrl;
  final Color? avatarColor;
  final IconData? avatarIcon;

  RecipientSuggestion({
    required this.name,
    required this.email,
    this.avatarUrl,
    this.avatarColor,
    this.avatarIcon,
  });
}