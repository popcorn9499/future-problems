import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/messages/messaging_api_mock.dart';
import 'package:gobison/features/messages/models/conversation.dart';
import 'package:gobison/features/messages/messaging_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final status in [201, 409]) {
    test(
      'opens a conversation when the create endpoint returns $status',
      () async {
        final service = MessagingService(
          client: MockClient((request) async {
            if (request.method == 'POST') {
              expect(request.url.path, '/api/v1/conversation');
              expect(jsonDecode(request.body), {
                'participantId': 'rider@example.com',
              });
              return http.Response(
                status == 201 ? '{"conversationId":"thread"}' : '',
                status,
              );
            }

            expect(request.method, 'GET');
            expect(request.url.path, '/api/v1/conversations');
            return http.Response(
              '{"conversations":[{"conversationId":"thread",'
              '"participant":{"userId":"rider@example.com","firstName":"Rider"}}]}',
              200,
            );
          }),
        );
        addTearDown(service.close);

        final conversation = await service.startConversation(
          ' Rider@example.com ',
        );
        expect(conversation.conversationId, 'thread');
        expect(conversation.participant.displayName, 'Rider');
        expect(conversation.lastMessage, isEmpty);
      },
    );
  }

  test('loads history when only the response has a conversation ID', () async {
    final service = MessagingService(
      client: MockClient(
        (request) async => http.Response(
          '{"conversationId":"thread","messages":[{"messageId":"message",'
          '"senderId":"rider@example.com","content":"Hello",'
          '"sentAt":"2026-11-19T12:00:00Z"}]}',
          200,
        ),
      ),
    );
    addTearDown(service.close);

    final messages = await service.getConversationMessages(
      'thread',
      currentUserId: 'me@example.com',
    );
    expect(messages.single.conversationId, 'thread');
    expect(messages.single.content, 'Hello');
  });

  group('MessagingService with the mock API', () {
    late MessagingService service;

    setUp(() {
      service = MessagingService(mock: MessagingApiMock());
    });

    test(
      'loads inbox previews separately from conversation messages',
      () async {
        final inbox = await service.getInbox();

        expect(inbox, isNotEmpty);
        expect(inbox.first.conversationId, isNotEmpty);
        expect(inbox.first.participant.displayName, isNotEmpty);
        expect(inbox.first.lastMessage, isNotEmpty);
        expect(inbox.first.lastMessageAt, isNotNull);
        final janeConversation = inbox.firstWhere(
          (item) => item.conversationId == 'conv_123',
        );
        expect(janeConversation.participant.avatarColor, '#D1C4E9');

        final messages = await service.getConversationMessages(
          'conv_123',
          currentUserId: 'current-user',
        );

        expect(messages, hasLength(3));
        expect(messages[1].senderId, 'current-user');
        expect(messages[1].conversationId, 'conv_123');
      },
    );

    test(
      'sends a message and includes it in later conversation loads',
      () async {
        final sent = await service.sendMessage(
          conversationId: 'conv_123',
          content: '  I will be there soon.  ',
          currentUserId: 'current-user',
        );

        expect(sent.content, 'I will be there soon.');
        expect(sent.senderId, 'current-user');
        expect(sent.conversationId, 'conv_123');

        final messages = await service.getConversationMessages(
          'conv_123',
          currentUserId: 'current-user',
        );
        expect(messages.last.messageId, sent.messageId);
      },
    );

    test(
      'marks a conversation read and updates its inbox unread count',
      () async {
        await service.markConversationAsRead('conv_123');

        final inbox = await service.getInbox();
        final conversation = inbox.firstWhere(
          (item) => item.conversationId == 'conv_123',
        );
        expect(conversation.unreadCount, 0);
      },
    );

    test('returns an HTTP-style error for an unknown conversation', () async {
      await expectLater(
        service.getConversationMessages(
          'missing',
          currentUserId: 'current-user',
        ),
        throwsA(
          isA<Exception>().having(
            (error) => error.toString(),
            'message',
            contains('(404)'),
          ),
        ),
      );
    });

    test('uses the default avatar color when the participant has no color', () {
      final participant = ConversationParticipant.fromJson({
        'userId': 'rider-without-color',
        'firstName': 'Rider',
      });

      expect(participant.avatarColor, '#E9DFD2');
    });
  });
}
