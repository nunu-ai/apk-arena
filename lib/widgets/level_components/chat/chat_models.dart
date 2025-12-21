import 'package:flutter/material.dart';

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime time;
  final bool isEdited;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    required this.time,
    this.isEdited = false,
  });
}

class ChatParticipant {
  final String name;
  final Color? color;

  const ChatParticipant(this.name, {this.color});
}

