class ChatRoom {
  const ChatRoom({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastSenderId,
    required this.updatedAt,
    this.otherUserName = '',
    this.otherUserId = '',
  });

  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final String lastSenderId;
  final int updatedAt; // milliseconds since epoch
  final String otherUserName;
  final String otherUserId;

  factory ChatRoom.fromMap(Map<Object?, Object?> map, String currentUserId) {
    final parts = <String>[];
    final participantsRaw = map['participants'];
    if (participantsRaw is Map) {
      parts.addAll(participantsRaw.keys.map((k) => k.toString()));
    } else if (participantsRaw is List) {
      parts.addAll(participantsRaw.map((k) => k.toString()));
    }
    final otherId = parts.firstWhere(
      (p) => p != currentUserId,
      orElse: () => '',
    );
    return ChatRoom(
      chatId: (map['chatId'] ?? '').toString(),
      participants: parts,
      lastMessage: (map['lastMessage'] ?? '').toString(),
      lastSenderId: (map['lastSenderId'] ?? '').toString(),
      updatedAt: int.tryParse((map['updatedAt'] ?? '0').toString()) ?? 0,
      otherUserId: otherId,
      otherUserName: (map['otherUserName_$otherId'] ?? '').toString(),
    );
  }

  Map<String, Object?> toMap() {
    final partsMap = <String, bool>{for (final p in participants) p: true};
    return {
      'chatId': chatId,
      'participants': partsMap,
      'lastMessage': lastMessage,
      'lastSenderId': lastSenderId,
      'updatedAt': updatedAt,
    };
  }

  ChatRoom copyWith({
    String? lastMessage,
    String? lastSenderId,
    int? updatedAt,
    String? otherUserName,
  }) {
    return ChatRoom(
      chatId: chatId,
      participants: participants,
      lastMessage: lastMessage ?? this.lastMessage,
      lastSenderId: lastSenderId ?? this.lastSenderId,
      updatedAt: updatedAt ?? this.updatedAt,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserId: otherUserId,
    );
  }

  DateTime get updatedAtDate =>
      DateTime.fromMillisecondsSinceEpoch(updatedAt);
}
