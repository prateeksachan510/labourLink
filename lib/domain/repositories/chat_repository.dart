import 'package:labour_link/data/models/chat_message.dart';
import 'package:labour_link/data/models/chat_room.dart';

abstract class ChatRepository {
  /// Returns a deterministic chatId for two users (sorted UIDs joined by '_').
  String getChatId(String uid1, String uid2);

  /// Ensures a chat room exists for two users. Returns the chatId.
  Future<String> ensureChatRoom({
    required String uid1,
    required String name1,
    required String uid2,
    required String name2,
  });

  Future<void> sendMessage({
    required String chatId,
    required ChatMessage message,
  });

  Stream<List<ChatMessage>> watchMessages(String chatId);

  Stream<List<ChatRoom>> watchChatRooms({
    required String uid,
    required String currentUserName,
  });
}
