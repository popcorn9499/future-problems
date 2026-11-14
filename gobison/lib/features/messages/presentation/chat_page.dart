import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../messaging_controller.dart';
import '../models/chat_message.dart';
import '../models/conversation.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    super.key,
    required this.conversation,
    required this.currentUserId,
    required this.controller,
  });

  final Conversation conversation;
  final String currentUserId;
  final MessagingController controller;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _composerController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadConversationMessages();
    });
  }

  Future<void> _loadConversationMessages() async {
    await widget.controller.loadConversationMessages(
      conversationId: widget.conversation.conversationId,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;
    _scrollToBottom();
  }

  Future<void> _send() async {
    final content = _composerController.text.trim();
    if (content.isEmpty || widget.controller.isSending) return;

    final sent = await widget.controller.sendMessage(
      conversationId: widget.conversation.conversationId,
      content: content,
      currentUserId: widget.currentUserId,
    );
    if (!mounted) return;

    if (sent) {
      _composerController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _composerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participant = widget.conversation.participant;
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) => Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.textPrimary,
          surfaceTintColor: Colors.transparent,
          titleSpacing: 0,
          title: Row(
            children: [
              UserAvatar(
                firstName: participant.firstName,
                lastName: participant.lastName,
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  participant.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            if (widget.controller.usingMockData)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: AppColors.surface,
                child: const Text(
                  'Demo conversation . All messages are simulated and not sent to a real user.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            if (widget.controller.chatErrorMessage != null)
              _ErrorBanner(message: widget.controller.chatErrorMessage!),
            Expanded(
              child: widget.controller.isLoadingConversation
                  ? const Center(child: CircularProgressIndicator())
                  : widget.controller.conversationMessages.isEmpty
                  ? const Center(
                      child: Text(
                        'Start the conversation with a friendly hello.',
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      itemCount: widget.controller.conversationMessages.length,
                      itemBuilder: (context, index) {
                        final message =
                            widget.controller.conversationMessages[index];
                        return _MessageBubble(
                          message: message,
                          isMine: message.senderId == widget.currentUserId,
                        );
                      },
                    ),
            ),
            _MessageComposer(
              controller: _composerController,
              sending: widget.controller.isSending,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.fromLTRB(12, 8, 12, 0),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(message, style: const TextStyle(color: AppColors.error)),
  );
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.isMine});

  final ChatMessage message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    final color = isMine ? AppColors.primary : AppColors.surface;
    final textColor = isMine ? Colors.white : AppColors.textPrimary;
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.76,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 11),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMine ? 18 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 18),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                message.content,
                style: TextStyle(color: textColor, fontSize: 15, height: 1.35),
              ),
              const SizedBox(height: 5),
              Text(
                _formatMessageTime(message.sentAt),
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.7),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Write a message…',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filled(
            tooltip: 'Send message',
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
    ),
  );
}

String _formatMessageTime(DateTime value) {
  final date = value.toLocal();
  final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
  return '$hour:${date.minute.toString().padLeft(2, '0')} ${date.hour >= 12 ? 'PM' : 'AM'}';
}
