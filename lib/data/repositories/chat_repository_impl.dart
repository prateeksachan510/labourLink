import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:labour_link/core/constants/firebase_paths.dart';
import 'package:labour_link/data/models/chat_message.dart';
import 'package:labour_link/data/models/chat_room.dart';
import 'package:labour_link/data/services/firebase_service.dart';
import 'package:labour_link/domain/repositories/chat_repository.dart';

class ChatRepositoryImpl implements ChatRepository {
  DatabaseReference get _chatsRef =>
      FirebaseService.db.ref(FirebasePaths.chats);

  @override
  String getChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  @override
  Future<String> ensureChatRoom({
    required String uid1,
    required String name1,
    required String uid2,
    required String name2,
  }) async {
    final chatId = getChatId(uid1, uid2);
    debugPrint(
      '[ChatRepo] ensureChatRoom chatId=$chatId uid1=$uid1 uid2=$uid2',
    );
    final metaRef = _chatsRef.child(chatId).child('meta');
    final snap = await metaRef.get();
    if (!snap.exists) {
      // Create the room
      await metaRef.set({
        'chatId': chatId,
        'participants': {uid1: true, uid2: true},
        'lastMessage': '',
        'lastSenderId': '',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
        // Store participant names for easy display
        'otherUserName_$uid1': name2,
        'otherUserName_$uid2': name1,
      });
      debugPrint('[ChatRepo] Chat room created chatId=$chatId');
    } else {
      debugPrint('[ChatRepo] Chat room already exists chatId=$chatId');
    }
    return chatId;
  }

  @override
  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  }) async {
    // Rate limiting: check time of last message
    try {
      final lastSnap = await _chatsRef
          .child(chatId)
          .child('messages')
          .orderByChild('timestamp')
          .limitToLast(1)
          .get();
      if (lastSnap.exists && lastSnap.value is Map) {
        final lastMap =
            (lastSnap.value as Map).cast<Object?, Object?>();
        final lastTs = lastMap.values.first is Map
            ? int.tryParse(
                    ((lastMap.values.first as Map)['timestamp'] ?? '0')
                        .toString()) ??
                0
            : 0;
        final diff = DateTime.now().millisecondsSinceEpoch - lastTs;
        if (diff < 300 &&
            lastMap.values.first is Map &&
            (lastMap.values.first as Map)['senderId'] ==
                message.senderId) {
          debugPrint(
              '[ChatRepo] Rate limit: message too fast chatId=$chatId');
          return;
        }
      }
    } catch (_) {}

    debugPrint(
      '[ChatRepo] sendMessage chatId=$chatId from=${message.senderId} '
      'text=${message.text.length > 30 ? message.text.substring(0, 30) : message.text}',
    );
    await _chatsRef
        .child(chatId)
        .child('messages')
        .child(message.messageId)
        .set(message.toMap());

    // Update chat room metadata
    await _chatsRef.child(chatId).child('meta').update({
      'lastMessage': message.text,
      'lastSenderId': message.senderId,
      'updatedAt': message.timestamp,
    });
  }

  @override
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    debugPrint('[ChatRepo] watchMessages chatId=$chatId');
    return _chatsRef
        .child(chatId)
        .child('messages')
        .orderByChild('timestamp')
        .onValue
        .map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <ChatMessage>[];
      }
      final map =
          (event.snapshot.value as Map).cast<Object?, Object?>();
      final messages = map.values
          .map((e) =>
              ChatMessage.fromMap((e as Map).cast<Object?, Object?>()))
          .toList()
        ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
      debugPrint(
          '[ChatRepo] watchMessages emitting ${messages.length} chatId=$chatId');
      return messages;
    });
  }

  @override
  Stream<List<ChatRoom>> watchChatRooms({
    required String uid,
    required String currentUserName,
  }) {
    debugPrint('[ChatRepo] watchChatRooms uid=$uid');
    return _chatsRef.onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <ChatRoom>[];
      }
      final allChats =
          (event.snapshot.value as Map).cast<Object?, Object?>();
      final rooms = <ChatRoom>[];
      for (final entry in allChats.entries) {
        if (entry.value is! Map) continue;
        final chatData =
            (entry.value as Map).cast<Object?, Object?>();
        final metaRaw = chatData['meta'];
        if (metaRaw is! Map) continue;
        final meta = metaRaw.cast<Object?, Object?>();

        // Check if current user is a participant
        final participants = meta['participants'];
        bool isParticipant = false;
        if (participants is Map) {
          isParticipant = participants.containsKey(uid);
        }
        if (!isParticipant) continue;

        rooms.add(ChatRoom.fromMap(meta, uid));
      }
      rooms.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      debugPrint(
          '[ChatRepo] watchChatRooms emitting ${rooms.length} for uid=$uid');
      return rooms;
    });
  }
}
