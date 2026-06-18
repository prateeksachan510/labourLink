import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:labour_link/data/models/chat_message.dart';
import 'package:labour_link/data/models/chat_room.dart';
import 'package:labour_link/domain/repositories/chat_repository.dart';

class ChatProvider extends ChangeNotifier {
  ChatProvider(this._chatRepository);

  final ChatRepository _chatRepository;

  bool isLoading = false;
  String? error;

  List<ChatRoom> chatRooms = [];
  List<ChatMessage> currentMessages = [];
  String? activeChatId;

  StreamSubscription<List<ChatRoom>>? _roomsSub;
  StreamSubscription<List<ChatMessage>>? _msgsSub;
  String? _watchedUid;

  // ── Chat rooms list ───────────────────────────────────────────────────────

  void startWatchingRooms({
    required String uid,
    required String currentUserName,
  }) {
    if (_watchedUid == uid) return;
    _watchedUid = uid;
    _roomsSub?.cancel();
    debugPrint('[ChatProvider] startWatchingRooms uid=$uid');
    _roomsSub = _chatRepository
        .watchChatRooms(uid: uid, currentUserName: currentUserName)
        .listen(
      (rooms) {
        chatRooms = rooms;
        debugPrint('[ChatProvider] chatRooms updated: ${rooms.length}');
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ChatProvider] chatRooms stream error: $e');
      },
    );
  }

  void stopWatchingRooms() {
    _watchedUid = null;
    _roomsSub?.cancel();
    _roomsSub = null;
  }

  // ── Active chat messages ──────────────────────────────────────────────────

  Future<String> openOrCreateChat({
    required String myUid,
    required String myName,
    required String otherUid,
    required String otherName,
  }) async {
    try {
      final chatId = await _chatRepository.ensureChatRoom(
        uid1: myUid,
        name1: myName,
        uid2: otherUid,
        name2: otherName,
      );
      _openChatMessages(chatId);
      return chatId;
    } catch (e) {
      debugPrint('[ChatProvider] openOrCreateChat error: $e');
      error = 'Could not open chat';
      notifyListeners();
      return '';
    }
  }

  void _openChatMessages(String chatId) {
    if (activeChatId == chatId) return;
    activeChatId = chatId;
    _msgsSub?.cancel();
    currentMessages = [];
    debugPrint('[ChatProvider] watching messages for chatId=$chatId');
    _msgsSub = _chatRepository.watchMessages(chatId).listen(
      (messages) {
        currentMessages = messages;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ChatProvider] messages stream error: $e');
      },
    );
  }

  void closeChat() {
    activeChatId = null;
    currentMessages = [];
    _msgsSub?.cancel();
    _msgsSub = null;
  }

  // ── Send ──────────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    try {
      final message = ChatMessage.create(
        senderId: senderId,
        senderName: senderName,
        text: trimmed,
      );
      debugPrint(
        '[ChatProvider] sendMessage chatId=$chatId from=$senderId '
        'len=${trimmed.length}',
      );
      await _chatRepository.sendMessage(chatId: chatId, message: message);
    } catch (e) {
      debugPrint('[ChatProvider] sendMessage error: $e');
      error = 'Failed to send message';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    _msgsSub?.cancel();
    super.dispose();
  }
}
