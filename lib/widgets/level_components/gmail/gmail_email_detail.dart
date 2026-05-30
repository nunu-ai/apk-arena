import 'package:flutter/material.dart';

/// A Gmail-style email detail view showing the full email content
/// Includes reply and forward functionality
class GmailEmailDetail extends StatelessWidget {
  final EmailDetailData email;
  final VoidCallback? onBack;
  final VoidCallback? onReply;
  final VoidCallback? onReplyAll;
  final VoidCallback? onForward;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;
  final List<String>? smartReplyOptions;

  const GmailEmailDetail({
    Key? key,
    required this.email,
    this.onBack,
    this.onReply,
    this.onReplyAll,
    this.onForward,
    this.onArchive,
    this.onDelete,
    this.smartReplyOptions,
  }) : super(key: key);

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
          color: Colors.white,
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
                      onPressed: onBack,
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, color: Colors.black87),
                      onPressed: onArchive,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.black87),
                      onPressed: onDelete,
                    ),
                    IconButton(
                      icon: const Icon(Icons.mail_outline, color: Colors.black87),
                      onPressed: () {},
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

          // Email content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Subject and folder
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            email.subject,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w400,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Icon(
                          email.isStarred ? Icons.star : Icons.star_border,
                          color: email.isStarred ? Colors.amber : Colors.grey,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        email.folder,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),

                  // Sender info
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade300,
                          ),
                          child: email.avatarUrl != null
                              ? ClipOval(
                            child: Image.network(
                              email.avatarUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildAvatarFallback(email.senderName);
                              },
                            ),
                          )
                              : _buildAvatarFallback(email.senderName),
                        ),
                        const SizedBox(width: 12),

                        // Sender details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      email.senderName,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    email.time,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      email.senderEmail != null ? '<${email.senderEmail}>' : '',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text('to me', style: TextStyle(fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 4),
                                  Icon(Icons.keyboard_arrow_down, size: 16, color: Colors.grey.shade600),
                                ],
                              ),
                              if (email.ccLine != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Text(
                                    'cc: ${email.ccLine}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),

                        // Action buttons
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.reply, size: 20),
                              color: Colors.grey.shade600,
                              onPressed: onReply,
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Email body
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      email.body,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ),

                  // Attachment chips
                  if (email.attachments.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: email.attachments.map((att) {
                          return InkWell(
                            onTap: att.onTap,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                border: Border.all(color: Colors.red.shade200),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.picture_as_pdf, color: Colors.red.shade700, size: 18),
                                  const SizedBox(width: 6),
                                  Text(att.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.red.shade900)),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  // Smart reply chips (if provided)
                  if (smartReplyOptions != null && smartReplyOptions!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: smartReplyOptions!.map((option) {
                          return InkWell(
                            onTap: onReply,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: Colors.grey.shade400),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                option,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
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
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onReply,
                      icon: const Icon(Icons.reply, size: 20),
                      label: const Text('Reply'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  if (onReplyAll != null) ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onReplyAll,
                        icon: const Icon(Icons.reply_all, size: 20),
                        label: const Text('Reply All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey.shade500,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onForward,
                      icon: Transform.flip(
                        flipX: true,
                        child: const Icon(Icons.reply, size: 20),
                      ),
                      label: const Text('Forward'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Clickable attachment chip shown in email detail
class EmailAttachment {
  final String name;
  final VoidCallback? onTap;
  const EmailAttachment({required this.name, this.onTap});
}

/// Data model for email detail
class EmailDetailData {
  final String senderName;
  final String? senderEmail;
  final String? ccLine;
  final String subject;
  final String body;
  final String time;
  final String folder;
  final bool isStarred;
  final String? avatarUrl;
  final List<EmailAttachment> attachments;

  EmailDetailData({
    required this.senderName,
    this.senderEmail,
    this.ccLine,
    required this.subject,
    required this.body,
    required this.time,
    this.folder = 'Inbox',
    this.isStarred = false,
    this.avatarUrl,
    this.attachments = const [],
  });
}