import 'package:flutter/material.dart';

/// A Gmail-style email list widget showing an inbox
/// Can be used to create levels where users need to find/select specific emails
class GmailEmailList extends StatelessWidget {
  final List<EmailItem> emails;
  final Function(EmailItem)? onEmailTap;
  final Function(EmailItem)? onEmailArchive;
  final Function(EmailItem)? onEmailDelete;
  final String searchHint;

  const GmailEmailList({
    Key? key,
    required this.emails,
    this.onEmailTap,
    this.onEmailArchive,
    this.onEmailDelete,
    this.searchHint = 'Search in emails',
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
          // Header with search and profile
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            color: Colors.white,
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Icon(Icons.menu, color: Colors.grey),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        searchHint,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.teal,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'n',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Primary label
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Colors.white,
            child: Text(
              'Primary',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Email list
          Expanded(
            child: ListView.builder(
              itemCount: emails.length,
              itemBuilder: (context, index) {
                return _EmailListItem(
                  email: emails[index],
                  onTap: onEmailTap != null ? () => onEmailTap!(emails[index]) : null,
                  onArchive: onEmailArchive != null ? () => onEmailArchive!(emails[index]) : null,
                  onDelete: onEmailDelete != null ? () => onEmailDelete!(emails[index]) : null,
                );
              },
            ),
          ),

          // Bottom navigation
          Container(
            height: 72,
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
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Stack(
                        children: [
                          Icon(Icons.mail_outline, color: Colors.grey.shade700, size: 24),
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: const Text(
                                '8',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Icon(Icons.videocam_outlined, color: Colors.grey.shade400, size: 24),
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
}

class _EmailListItem extends StatelessWidget {
  final EmailItem email;
  final VoidCallback? onTap;
  final VoidCallback? onArchive;
  final VoidCallback? onDelete;

  const _EmailListItem({
    Key? key,
    required this.email,
    this.onTap,
    this.onArchive,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('${email.senderName}_${email.subject}_${email.time}'),
      background: Container(
        color: Colors.green.shade600,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(
          Icons.archive_outlined,
          color: Colors.white,
          size: 24,
        ),
      ),
      secondaryBackground: Container(
        color: Colors.red.shade600,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 24,
        ),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd && onArchive != null) {
          onArchive!();
        } else if (direction == DismissDirection.endToStart && onDelete != null) {
          onDelete!();
        }
      },
      child: InkWell(
        onTap: onTap,
        child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: email.isRead ? Colors.white : Colors.grey.shade50,
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
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
                    return _buildAvatarFallback();
                  },
                ),
              )
                  : _buildAvatarFallback(),
            ),
            const SizedBox(width: 12),

            // Email content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RichText(
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: email.senderName,
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 14,
                                  fontWeight: email.isRead ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                              if (email.participantCount > 1)
                                TextSpan(
                                  text: ', me',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: email.isRead ? FontWeight.normal : FontWeight.w600,
                                  ),
                                ),
                              if (email.participantCount > 1)
                                TextSpan(
                                  text: ' ${email.participantCount}',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        email.time,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.subject,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: email.isRead ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email.preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Star icon
            Icon(
              email.isStarred ? Icons.star : Icons.star_border,
              color: email.isStarred ? Colors.amber : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    return Center(
      child: Text(
        email.senderName.isNotEmpty ? email.senderName[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Data model for an email item
class EmailItem {
  final String senderName;
  final String subject;
  final String preview;
  final String time;
  final bool isRead;
  final bool isStarred;
  final int participantCount;
  final String? avatarUrl;

  EmailItem({
    required this.senderName,
    required this.subject,
    required this.preview,
    required this.time,
    this.isRead = false,
    this.isStarred = false,
    this.participantCount = 1,
    this.avatarUrl,
  });
}