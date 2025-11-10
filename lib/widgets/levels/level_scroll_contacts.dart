import 'package:flutter/material.dart';
import '../level_widget.dart';
import '../../theme/app_theme.dart';
import '../contact_list_item.dart';
import 'dart:math';

class LevelScrollContacts extends LevelWidget {
  const LevelScrollContacts({Key? key, required super.onComplete}) : super(key: key);

  @override
  State<LevelScrollContacts> createState() => _LevelScrollContactsState();
}

class _LevelScrollContactsState extends State<LevelScrollContacts> {
  late List<Map<String, String>> _contacts;
  late int _targetIndex;
  final String _targetName = 'Saul Goodman';
  final String _targetEmoji = '👔';

  @override
  void initState() {
    super.initState();
    _generateContacts();
  }

  void _generateContacts() {
    final firstNames = [
      'James', 'John', 'Robert', 'Michael', 'William', 'David', 'Richard', 'Joseph',
      'Thomas', 'Charles', 'Mary', 'Patricia', 'Jennifer', 'Linda', 'Elizabeth',
      'Barbara', 'Susan', 'Jessica', 'Sarah', 'Karen', 'Nancy', 'Lisa', 'Betty',
      'Margaret', 'Sandra', 'Ashley', 'Kimberly', 'Emily', 'Donna', 'Michelle',
      'Daniel', 'Matthew', 'Anthony', 'Mark', 'Donald', 'Steven', 'Paul', 'Andrew',
      'Joshua', 'Kenneth', 'Kevin', 'Brian', 'George', 'Timothy', 'Ronald', 'Edward',
      'Jason', 'Jeffrey', 'Ryan', 'Jacob', 'Gary', 'Nicholas', 'Eric', 'Jonathan',
      'Stephen', 'Larry', 'Justin', 'Scott', 'Brandon', 'Benjamin', 'Samuel', 'Raymond',
      'Carol', 'Dorothy', 'Amanda', 'Melissa', 'Deborah', 'Stephanie', 'Rebecca',
      'Sharon', 'Laura', 'Cynthia', 'Kathleen', 'Amy', 'Angela', 'Shirley', 'Anna',
    ];

    final lastNames = [
      'Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis',
      'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson', 'Anderson',
      'Thomas', 'Taylor', 'Moore', 'Jackson', 'Martin', 'Lee', 'Perez', 'Thompson',
      'White', 'Harris', 'Sanchez', 'Clark', 'Ramirez', 'Lewis', 'Robinson', 'Walker',
      'Young', 'Allen', 'King', 'Wright', 'Scott', 'Torres', 'Nguyen', 'Hill', 'Flores',
      'Green', 'Adams', 'Nelson', 'Baker', 'Hall', 'Rivera', 'Campbell', 'Mitchell',
      'Carter', 'Roberts', 'Gomez', 'Phillips', 'Evans', 'Turner', 'Diaz', 'Parker',
      'Cruz', 'Edwards', 'Collins', 'Reyes', 'Stewart', 'Morris', 'Morales', 'Murphy',
      'Cook', 'Rogers', 'Morgan', 'Peterson', 'Cooper', 'Reed', 'Bailey', 'Bell',
    ];

    final random = Random();
    _contacts = [];

    // Generate 100-150 contacts
    final numContacts = 100 + random.nextInt(51);

    for (int i = 0; i < numContacts; i++) {
      final firstName = firstNames[random.nextInt(firstNames.length)];
      final lastName = lastNames[random.nextInt(lastNames.length)];
      _contacts.add({
        'name': '$firstName $lastName',
        'phone': _generatePhoneNumber(random),
      });
    }

    // Sort alphabetically
    _contacts.sort((a, b) => a['name']!.compareTo(b['name']!));

    // Insert Saul somewhere in the middle-to-late section (after 'S' names start)
    // Find where 'S' names would be
    int sIndex = _contacts.indexWhere((c) => c['name']!.startsWith('S'));
    if (sIndex == -1) sIndex = (numContacts * 0.7).toInt();

    // Place Saul randomly among the 'S' names
    final sNames = _contacts.where((c) => c['name']!.startsWith('S')).length;
    _targetIndex = sIndex + random.nextInt(max(sNames, 5));

    _contacts.insert(_targetIndex, {
      'name': _targetName,
      'phone': '(505) CALL-SAUL',
    });
  }

  String _generatePhoneNumber(Random random) {
    return '(${random.nextInt(900) + 100}) ${random.nextInt(900) + 100}-${random.nextInt(9000) + 1000}';
  }

  void _handleContactTap(int index) {
    if (index == _targetIndex) {
      // Found Saul!
      widget.onComplete(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.shade800,
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Row(
                children: [
                  const Text(
                    'Contacts',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),

          // Contact list
          Expanded(
            child: ListView.builder(
              itemCount: _contacts.length,
              itemBuilder: (context, index) {
                final contact = _contacts[index];
                final isTarget = index == _targetIndex;

                return ContactListItem(
                  name: contact['name']!,
                  subtitle: contact['phone'],
                  avatarText: isTarget ? _targetEmoji : null,
                  avatarColor: isTarget ? Colors.blue.shade700 : null,
                  isSpecial: isTarget,
                  onTap: () => _handleContactTap(index),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}