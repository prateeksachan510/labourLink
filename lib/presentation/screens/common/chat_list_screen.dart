import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/data/models/chat_room.dart';
import 'package:labour_link/presentation/providers/auth_provider.dart';
import 'package:labour_link/presentation/providers/chat_provider.dart';
import 'package:labour_link/presentation/screens/common/chat_screen.dart';
import 'package:provider/provider.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) return;
      context.read<ChatProvider>().startWatchingRooms(
            uid: user.uid,
            currentUserName: user.name,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();
    final currentUser = context.watch<AuthProvider>().currentUser;

    return Scaffold(
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Messages',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.onBackground,
                      ),
                    ),
                    Text(
                      '${chatProvider.chatRooms.length} conversation${chatProvider.chatRooms.length != 1 ? 's' : ''}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.subtle,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // List
              Expanded(
                child: chatProvider.chatRooms.isEmpty
                    ? _EmptyChats()
                    : ListView.builder(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: chatProvider.chatRooms.length,
                        itemBuilder: (context, index) {
                          final room = chatProvider.chatRooms[index];
                          return _ChatRoomTile(
                            room: room,
                            currentUserId: currentUser?.uid ?? '',
                            currentUserName: currentUser?.name ?? '',
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppTheme.subtle,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No conversations yet',
            style: TextStyle(
              color: AppTheme.onBackground,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chats open once a hire request\nis accepted.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.subtle, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _ChatRoomTile extends StatelessWidget {
  const _ChatRoomTile({
    required this.room,
    required this.currentUserId,
    required this.currentUserName,
  });

  final ChatRoom room;
  final String currentUserId;
  final String currentUserName;

  @override
  Widget build(BuildContext context) {
    final name = room.otherUserName.isNotEmpty
        ? room.otherUserName
        : room.otherUserId.length > 6
            ? room.otherUserId.substring(0, 6)
            : room.otherUserId;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final timeStr = room.updatedAt > 0
        ? DateFormat('hh:mm a').format(room.updatedAtDate)
        : '';
    final isLastMine = room.lastSenderId == currentUserId;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            chatId: room.chatId,
            otherUserId: room.otherUserId,
            otherUserName: name,
            currentUserId: currentUserId,
            currentUserName: currentUserName,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (isLastMine)
                        const Text(
                          'You: ',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          room.lastMessage.isEmpty
                              ? 'Start a conversation'
                              : room.lastMessage,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppTheme.subtle,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              timeStr,
              style: const TextStyle(color: AppTheme.subtle, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}
