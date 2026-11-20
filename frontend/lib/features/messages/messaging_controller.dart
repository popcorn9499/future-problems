import 'package:flutter/foundation.dart';

import 'messaging_service.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';

class MessagingController extends ChangeNotifier {
  MessagingController({MessagingService? messagingService})
    : _messagingService = messagingService ?? MessagingService(),
      _ownsMessagingService = messagingService == null;

  final MessagingService _messagingService;
  final bool _ownsMessagingService;

  /// Inbox rows: one preview per conversation, with its latest message.
  List<Conversation> inbox = [];

  /// Individual messages for the chat screen currently being viewed.
  List<ChatMessage> conversationMessages = [];
  bool isLoadingInbox = false;
  bool isLoadingConversation = false;
  bool isSending = false;
  String? inboxErrorMessage;
  String? chatErrorMessage;
  bool get usingMockData => _messagingService.usingMockData;

  bool _disposed = false;
  bool _isPollingConversation = false;
  int _conversationRevision = 0;

  Future<void> loadInbox() async {
    isLoadingInbox = true;
    inboxErrorMessage = null;
    _notify();
    try {
      inbox = await _messagingService.getInbox();
    } catch (error) {
      inboxErrorMessage = _userMessage(error, 'inbox');
    } finally {
      isLoadingInbox = false;
      _notify();
    }
  }

  Future<void> loadConversationMessages({
    required String conversationId,
    required String currentUserId,
  }) async {
    _conversationRevision++;
    isLoadingConversation = true;
    chatErrorMessage = null;
    _notify();
    try {
      conversationMessages = await _messagingService.getConversationMessages(
        conversationId,
        currentUserId: currentUserId,
      );
      _notify();
      try {
        await _markConversationAsRead(conversationId);
      } catch (error) {
        chatErrorMessage = _userMessage(error, 'read');
      }
    } catch (error) {
      chatErrorMessage = _userMessage(error, 'conversation');
    } finally {
      isLoadingConversation = false;
      _notify();
    }
  }

  Future<bool> pollConversation({
    required String conversationId,
    required String currentUserId,
    required bool Function() isVisible,
  }) async {
    if (_disposed ||
        _isPollingConversation ||
        isLoadingConversation ||
        isSending ||
        !isVisible()) {
      return false;
    }

    _isPollingConversation = true;
    final revision = _conversationRevision;
    var hasNewMessages = false;
    try {
      final messages = await _messagingService.getConversationMessages(
        conversationId,
        currentUserId: currentUserId,
      );
      if (_disposed || revision != _conversationRevision || !isVisible()) {
        return false;
      }

      final previousIds = conversationMessages
          .map((message) => message.messageId)
          .toSet();
      hasNewMessages = messages.any(
        (message) => !previousIds.contains(message.messageId),
      );
      final changed = !listEquals(
        conversationMessages
            .map((message) => (message.messageId, message.readAt))
            .toList(),
        messages.map((message) => (message.messageId, message.readAt)).toList(),
      );
      if (changed) {
        conversationMessages = messages;
        _notify();
      }

      if (messages.any(
        (message) =>
            message.senderId != currentUserId && message.readAt == null,
      )) {
        await _markConversationAsRead(conversationId);
        _notify();
      }
    } catch (_) {
      // Keep the current history visible and retry on the next poll.
    } finally {
      _isPollingConversation = false;
    }
    return hasNewMessages;
  }

  Future<void> _markConversationAsRead(String conversationId) async {
    await _messagingService.markConversationAsRead(conversationId);
    if (_disposed) return;
    inbox = inbox
        .map(
          (conversation) => conversation.conversationId == conversationId
              ? conversation.copyWith(unreadCount: 0)
              : conversation,
        )
        .toList();
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    required String currentUserId,
  }) async {
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      chatErrorMessage = 'Write a message before sending.';
      _notify();
      return false;
    }

    _conversationRevision++;
    isSending = true;
    chatErrorMessage = null;
    _notify();
    try {
      final message = await _messagingService.sendMessage(
        conversationId: conversationId,
        content: trimmedContent,
        currentUserId: currentUserId,
      );
      conversationMessages = [...conversationMessages, message];
      inbox = inbox
          .map(
            (conversation) => conversation.conversationId == conversationId
                ? conversation.copyWith(
                    lastMessage: message.content,
                    lastMessageAt: message.sentAt,
                  )
                : conversation,
          )
          .toList();
      return true;
    } catch (error) {
      chatErrorMessage = _userMessage(error, 'send');
      return false;
    } finally {
      isSending = false;
      _notify();
    }
  }

  String _userMessage(Object error, String operation) {
    final text = error.toString();
    final code = RegExp(r'\((\d{3})\)').firstMatch(text)?.group(1);
    switch (code) {
      case '400':
        return 'That message could not be sent. Check its content and try again.';
      case '401':
        return 'Your session has expired. Sign in again to continue.';
      case '403':
        return 'You no longer have access to this conversation.';
      case '404':
        return 'This conversation could not be found.';
      case '409':
        return 'This action conflicts with the current conversation. Try again.';
      case '500':
        return 'The messaging service had a problem. Please try again later.';
    }
    switch (operation) {
      case 'send':
        return 'Your message could not be sent. Please try again.';
      case 'read':
        return 'Could not update the read status. Please try again.';
      case 'inbox':
        return 'Could not load your message inbox. Check your connection and try again.';
      default:
        return 'Could not load this conversation. Check your connection and try again.';
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_ownsMessagingService) _messagingService.close();
    super.dispose();
  }
}
