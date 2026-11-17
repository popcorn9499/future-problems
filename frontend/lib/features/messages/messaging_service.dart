import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/network/auth_client.dart';
import 'messaging_api_mock.dart';
import 'models/chat_message.dart';
import 'models/conversation.dart';

class MessagingService {
  MessagingService({http.Client? client, MessagingApiMock? mock})
    : _client = client ?? createAuthClient(),
      _mock = mock ?? MessagingApiMock();

  final http.Client _client;
  final MessagingApiMock _mock;

  bool get usingMockData => MessagingApiMock.useMock;

  /// Loads inbox previews: one row per conversation, not the full chat history.
  Future<List<Conversation>> getInbox() async {
    final response = usingMockData
        ? await _mock.getInbox()
        : await _client.get(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/conversations'),
            headers: const {'Accept': 'application/json'},
          );

    _expectStatus(response, 200, 'Loading conversations');

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return (body['conversations'] as List<dynamic>)
        .map((item) => Conversation.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// Loads individual messages in one conversation.
  Future<List<ChatMessage>> getConversationMessages(
    String conversationId, {
    required String currentUserId,
  }) async {
    final response = usingMockData
        ? await _mock.getConversationMessages(
            conversationId,
            currentUserId: currentUserId,
          )
        : await _client.get(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/conversations/$conversationId/messages?limit=50',
            ),
            headers: const {'Accept': 'application/json'},
          );

    _expectStatus(response, 200, 'Loading conversation messages');

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    return (body['messages'] as List<dynamic>)
        .map((item) => ChatMessage.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ChatMessage> sendMessage({
    required String conversationId,
    required String content,
    required String currentUserId,
  }) async {
    final response = usingMockData
        ? await _mock.sendMessage(
            conversationId: conversationId,
            content: content,
            currentUserId: currentUserId,
          )
        : await _client.post(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/conversations/$conversationId/messages',
            ),
            headers: const {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({'content': content}),
          );
    _expectStatus(response, 201, 'Sending message');
    return ChatMessage.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final response = usingMockData
        ? await _mock.markConversationAsRead(conversationId)
        : await _client.patch(
            Uri.parse(
              '${ApiConfig.baseUrl}/api/v1/conversations/$conversationId/read',
            ),
            headers: const {'Accept': 'application/json'},
          );
    _expectStatus(response, 200, 'Marking messages as read');
  }

  void _expectStatus(http.Response response, int expected, String operation) {
    if (response.statusCode == expected) return;
    throw Exception(
      '$operation failed (${response.statusCode}): ${response.body}',
    );
  }
}
