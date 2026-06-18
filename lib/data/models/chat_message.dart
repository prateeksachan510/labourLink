import 'package:uuid/uuid.dart';

class ChatMessage {
  const ChatMessage({
    required this.messageId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
  });

  final String messageId;
  final String senderId;
  final String senderName;
  final String text;
  final int timestamp; // milliseconds since epoch

  factory ChatMessage.create({
    required String senderId,
    required String senderName,
    required String text,
  }) {
    return ChatMessage(
      messageId: const Uuid().v4(),
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  factory ChatMessage.fromMap(Map<Object?, Object?> map) {
    return ChatMessage(
      messageId: (map['messageId'] ?? '').toString(),
      senderId: (map['senderId'] ?? '').toString(),
      senderName: (map['senderName'] ?? '').toString(),
      text: (map['text'] ?? '').toString(),
      timestamp: int.tryParse((map['timestamp'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'messageId': messageId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp,
    };
  }

  DateTime get dateTime =>
      DateTime.fromMillisecondsSinceEpoch(timestamp);
}
