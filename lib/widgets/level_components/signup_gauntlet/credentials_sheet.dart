import 'package:flutter/material.dart';

const _detailsSurface = Color(0xFF1E1E2E);
const _detailsSurfaceRaised = Color(0xFF28283A);
const _detailsAccent = Color(0xFFFFB300);
const _detailsAccentDark = Color(0xFFE09B00);

/// Shared footer button + bottom sheet for showing stage credentials.
/// Each stage provides its credential rows as a Map<String, String>.
class CredentialsFab extends StatelessWidget {
  final Map<String, String> credentials;
  const CredentialsFab({super.key, required this.credentials});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _showSheet(context),
            child: Ink(
              height: 52,
              decoration: BoxDecoration(
                color: _detailsSurfaceRaised,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _detailsAccent.withValues(alpha: 0.7),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.badge_outlined, color: _detailsAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.keyboard_arrow_up,
                      color: _detailsAccent, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: _detailsSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.45,
        minChildSize: 0.25,
        maxChildSize: 0.75,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(
                    Icons.badge_outlined,
                    color: _detailsAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Text('credentials',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: _detailsSurfaceRaised,
                  borderRadius: BorderRadius.circular(14),
                  border:
                      Border.all(color: _detailsAccent.withValues(alpha: 0.22)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: credentials.entries.map((e) {
                    final isLast = e.key == credentials.entries.last.key;
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 9),
                      decoration: BoxDecoration(
                        border: isLast
                            ? null
                            : Border(
                                bottom: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(e.key,
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                    fontWeight: FontWeight.w600)),
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
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
