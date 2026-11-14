import 'package:gobison/features/messages/messaging_service.dart';
import 'package:gobison/features/messages/models/chat_message.dart';
import 'package:gobison/features/messages/models/conversation.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final testSentAt = DateTime.utc(2026, 11, 14, 12);

Conversation testConversation({
  String id = 'conversation-1',
  String name = 'Jane Doe',
  String preview = 'See you soon',
  int unreadCount = 2,
}) => Conversation(
  conversationId: id,
  participant: ConversationParticipant(
    userId: 'rider-2',
    firstName: name.split(' ').first,
    lastName: name.split(' ').skip(1).join(' '),
  ),
  lastMessage: preview,
  lastMessageAt: testSentAt,
  unreadCount: unreadCount,
);

ChatMessage testChatMessage({
  String id = 'message-1',
  String conversationId = 'conversation-1',
  String senderId = 'rider-2',
  String content = 'Hello there',
  DateTime? sentAt,
}) => ChatMessage(
  messageId: id,
  conversationId: conversationId,
  senderId: senderId,
  content: content,
  sentAt: sentAt ?? testSentAt,
);

class FakeMessagingService extends MessagingService {
  FakeMessagingService()
    : super(client: MockClient((_) async => http.Response('', 200)));

  List<Conversation> inboxResult = [testConversation()];
  List<ChatMessage> messagesResult = [testChatMessage()];
  Object? inboxFailure;
  Object? conversationFailure;
  Object? readFailure;
  Object? sendFailure;
  String? requestedConversationId;
  String? requestedCurrentUserId;
  String? sentContent;
  int readCallCount = 0;

  @override
  bool get usingMockData => false;

  @override
  Future<List<Conversation>> getInbox() async {
    if (inboxFailure != null) throw inboxFailure!;
    return inboxResult;
  }

  @override
  Future<List<ChatMessage>> getConversationMessages(
    String conversationId, {
    required String currentUserId,
  }) async {
    requestedConversationId = conversationId;
    requestedCurrentUserId = currentUserId;
    if (conversationFailure != null) throw conversationFailure!;
    return messagesResult;
  }

  @override
  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    required String currentUserId,
  }) async {
    requestedConversationId = conversationId;
    requestedCurrentUserId = currentUserId;
    sentContent = content;
    if (sendFailure != null) throw sendFailure!;
    return testChatMessage(
      id: 'sent-message',
      conversationId: conversationId,
      senderId: currentUserId,
      content: content,
      sentAt: testSentAt.add(const Duration(minutes: 1)),
    );
  }

  @override
  Future<void> markConversationAsRead(String conversationId) async {
    requestedConversationId = conversationId;
    readCallCount++;
    if (readFailure != null) throw readFailure!;
  }
}
