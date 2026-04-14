import 'package:flutter/material.dart';

/// Shared floating button + bottom sheet for showing stage credentials.
/// Each stage provides its credential rows as a Map<String, String>.
class CredentialsFab extends StatelessWidget {
  final Map<String, String> credentials;
  const CredentialsFab({super.key, required this.credentials});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 16,
      right: 16,
      child: FloatingActionButton.small(
        heroTag: 'creds_fab',
        backgroundColor: Colors.amber.shade700,
        onPressed: () => _showSheet(context),
        child: const Icon(Icons.sticky_note_2, color: Colors.white, size: 20),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.sticky_note_2,
                    color: Colors.amber.shade600, size: 18),
                const SizedBox(width: 8),
                const Text('credentials',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
              ],
            ),
            const SizedBox(height: 12),
            ...credentials.entries.map((e) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(e.key,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white38)),
                      ),
                      Expanded(
                        child: SelectableText(e.value,
                            style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontFamily: 'monospace')),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
