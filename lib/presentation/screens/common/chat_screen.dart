import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:labour_link/core/theme/app_theme.dart';
import 'package:labour_link/data/models/chat_message.dart';
import 'package:labour_link/presentation/providers/chat_provider.dart';
import 'package:provider/provider.dart';

/// Full-screen real-time chat between two users.
class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.currentUserId,
    required this.currentUserName,
  });

  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String currentUserId;
  final String currentUserName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().openOrCreateChat(
            myUid: widget.currentUserId,
            myName: widget.currentUserName,
            otherUid: widget.otherUserId,
            otherName: widget.otherUserName,
          );
    });
  }

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    context.read<ChatProvider>().closeChat();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) return;
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent + 100,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _sending = true);
    _inputCtrl.clear();
    await context.read<ChatProvider>().sendMessage(
          chatId: widget.chatId,
          senderId: widget.currentUserId,
          senderName: widget.currentUserName,
          text: text,
        );
    setState(() => _sending = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final messages = chat.currentMessages;

    // Auto-scroll when new messages arrive
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (messages.isNotEmpty) _scrollToBottom();
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  widget.otherUserName.isNotEmpty
                      ? widget.otherUserName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUserName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onBackground,
                    ),
                  ),
                  const Text(
                    'Online',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppTheme.success,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Container(
        decoration:
            const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: Column(
          children: [
            // Messages
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline_rounded,
                              size: 40, color: AppTheme.subtle),
                          const SizedBox(height: 10),
                          Text(
                            'Say hi to ${widget.otherUserName}!',
                            style: const TextStyle(color: AppTheme.subtle),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == widget.currentUserId;
                        final showDate = index == 0 ||
                            !_sameDay(
                              messages[index - 1].dateTime,
                              msg.dateTime,
                            );
                        return Column(
                          children: [
                            if (showDate) _DateDivider(msg.dateTime),
                            _MessageBubble(
                                message: msg, isMe: isMe),
                          ],
                        );
                      },
                    ),
            ),

            // Input bar
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: const BoxDecoration(
                color: AppTheme.surface,
                border: Border(
                    top: BorderSide(color: Color(0xFF2A2A4A))),
              ),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputCtrl,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: 'Type a message…',
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          filled: true,
                          fillColor: Color(0xFF16213E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      child: GestureDetector(
                        onTap: _sending ? null : _sendMessage,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: _sending
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMe});

  final ChatMessage message;
  final bool isMe;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: isMe ? AppTheme.primaryGradient : null,
          color: isMe ? null : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          border: isMe
              ? null
              : Border.all(color: const Color(0xFF2A2A4A)),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: isMe ? Colors.white : AppTheme.onSurface,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              DateFormat('hh:mm a').format(message.dateTime),
              style: TextStyle(
                color: isMe
                    ? Colors.white.withAlpha(150)
                    : AppTheme.subtle,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateDivider extends StatelessWidget {
  const _DateDivider(this.date);
  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    String label;
    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      label = 'Today';
    } else {
      label = DateFormat('MMM d, y').format(date);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              label,
              style: const TextStyle(
                  color: AppTheme.subtle, fontSize: 11),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFF2A2A4A))),
        ],
      ),
    );
  }
}
