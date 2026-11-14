import 'dart:convert';

import 'package:http/http.dart' as http;

/// In-memory stand-in for the messaging API.
/// Set [useMock] to false to send requests to the real backend instead.
class MessagingApiMock {
  static const bool useMock = true;

  final Map<String, Map<String, dynamic>> _conversations = {
    'conv_123': {
      'conversationId': 'conv_123',
      'participant': {
        'userId': 'usr_jane',
        'firstName': 'Jane',
        'lastName': 'Doe',
        'avatarColor': '#D1C4E9',
      },
      'unreadCount': 2,
    },
    'conv_456': {
      'conversationId': 'conv_456',
      'participant': {
        'userId': 'usr_john',
        'firstName': 'John',
        'lastName': 'Smith',
        'avatarColor': '#C8E6C9',
      },
      'unreadCount': 0,
    },
    'conv_789': {
      'conversationId': 'conv_789',
      'participant': {
        'userId': 'usr_amina',
        'firstName': 'Amina',
        'lastName': 'Khan',
        'avatarColor': '#BBDEFB',
      },
      'unreadCount': 0,
    },
  };

  late final Map<String, List<Map<String, dynamic>>> _messages =
      _seedMessages();

  Future<http.Response> getInbox() async {
    await _simulateLatency();
    final rows =
        _conversations.values.map((conversation) {
          final messages = _messages[conversation['conversationId']] ?? [];
          final latest = messages.isEmpty ? null : messages.last;
          return {
            ...conversation,
            'lastMessage': latest?['content'] ?? '',
            'lastMessageAt': latest?['sentAt'],
          };
        }).toList()..sort((a, b) {
          final aDate = DateTime.tryParse(a['lastMessageAt'] as String? ?? '');
          final bDate = DateTime.tryParse(b['lastMessageAt'] as String? ?? '');
          if (aDate == null) return 1;
          if (bDate == null) return -1;
          return bDate.compareTo(aDate);
        });
    return _jsonResponse({'conversations': rows}, 200);
  }

  Future<http.Response> getConversationMessages(
    String conversationId, {
    required String currentUserId,
  }) async {
    await _simulateLatency();
    final messages = _messages[conversationId];

    if (messages == null) {
      return _jsonResponse({'message': 'Conversation not found'}, 404);
    }

    return _jsonResponse({
      'conversationId': conversationId,
      'messages': messages
          .map(
            (message) => {
              ...message,
              if (message['senderId'] == 'usr_123') 'senderId': currentUserId,
            },
          )
          .toList(),
      'pagination': {'limit': 50, 'hasMore': false, 'nextCursor': null},
    }, 200);
  }

  Future<http.Response> sendMessage({
    required String conversationId,
    required String content,
    required String currentUserId,
  }) async {
    await _simulateLatency();
    if (content.trim().isEmpty) {
      return _jsonResponse({'message': 'Message content cannot be empty'}, 400);
    }

    final messages = _messages[conversationId];
    if (messages == null) {
      return _jsonResponse({'message': 'Conversation not found'}, 404);
    }

    final sentAt = DateTime.now().toUtc().toIso8601String();
    final message = {
      'messageId': 'mock_${DateTime.now().microsecondsSinceEpoch}',
      'conversationId': conversationId,
      'senderId': currentUserId,
      'content': content.trim(),
      'sentAt': sentAt,
      'readAt': null,
    };
    messages.add(message);
    return _jsonResponse(message, 201);
  }

  Future<http.Response> markConversationAsRead(String conversationId) async {
    await _simulateLatency();
    final messages = _messages[conversationId];
    final conversation = _conversations[conversationId];
    if (messages == null || conversation == null) {
      return _jsonResponse({'message': 'Conversation not found'}, 404);
    }
    final readAt = DateTime.now().toUtc().toIso8601String();
    for (final message in messages) {
      if (message['senderId'] != conversation['participant']['userId'] ||
          message['readAt'] != null) {
        continue;
      }
      message['readAt'] = readAt;
    }
    conversation['unreadCount'] = 0;
    return _jsonResponse({
      'conversationId': conversationId,
      'markedAsRead': 1,
      'readAt': readAt,
    }, 200);
  }

  Map<String, List<Map<String, dynamic>>> _seedMessages() {
    final now = DateTime.now().toUtc();
    return {
      'conv_123': [
        _message(
          'conv_123',
          'usr_jane',
          'Hi! Are you still looking for a ride to campus?',
          now.subtract(const Duration(minutes: 20)),
          'msg_123_1',
        ),
        _message(
          'conv_123',
          'usr_123',
          'Yes, that would be great. Thanks!',
          now.subtract(const Duration(minutes: 16)),
          'msg_123_2',
        ),
        _message(
          'conv_123',
          'usr_jane',
          'What time should I pick you up?',
          now.subtract(const Duration(minutes: 8)),
          'msg_123_3',
        ),
      ],
      'conv_456': [
        _message(
          'conv_456',
          'usr_456',
          'I can meet you outside the library.',
          now.subtract(const Duration(hours: 2, minutes: 4)),
          'msg_456_1',
        ),
        _message(
          'conv_456',
          'usr_123',
          'Sounds good, see you then!',
          now.subtract(const Duration(hours: 2)),
          'msg_456_2',
        ),
      ],
      'conv_789': [
        _message(
          'conv_789',
          'usr_789',
          'Thanks for sharing the ride.',
          now.subtract(const Duration(days: 1)),
          'msg_789_1',
        ),
      ],
    };
  }

  Map<String, dynamic> _message(
    String conversationId,
    String senderId,
    String content,
    DateTime sentAt,
    String messageId,
  ) => {
    'messageId': messageId,
    'conversationId': conversationId,
    'senderId': senderId,
    'content': content,
    'sentAt': sentAt.toIso8601String(),
    'readAt': null,
  };

  Future<void> _simulateLatency() =>
      Future<void>.delayed(const Duration(milliseconds: 350));

  http.Response _jsonResponse(Map<String, dynamic> body, int statusCode) =>
      http.Response(
        jsonEncode(body),
        statusCode,
        headers: const {'Content-Type': 'application/json'},
      );
}
