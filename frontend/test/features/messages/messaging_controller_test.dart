import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/messages/messaging_controller.dart';

import 'messaging_test_helpers.dart';

void main() {
  group('MessagingController', () {
    late FakeMessagingService service;
    late MessagingController controller;

    setUp(() {
      service = FakeMessagingService();
      controller = MessagingController(messagingService: service);
    });

    tearDown(() => controller.dispose());

    test('loads inbox previews', () async {
      await controller.loadInbox();

      expect(controller.inbox, service.inboxResult);
      expect(controller.isLoadingInbox, isFalse);
      expect(controller.inboxErrorMessage, isNull);
    });

    test('reports a useful error when the inbox cannot load', () async {
      service.inboxFailure = Exception('Request failed (500)');

      await controller.loadInbox();

      expect(controller.inbox, isEmpty);
      expect(
        controller.inboxErrorMessage,
        'The messaging service had a problem. Please try again later.',
      );
      expect(controller.isLoadingInbox, isFalse);
    });

    test(
      'loads conversation messages and marks the inbox row as read',
      () async {
        controller.inbox = [testConversation(unreadCount: 4)];

        await controller.loadConversationMessages(
          conversationId: 'conversation-1',
          currentUserId: 'current-user',
        );

        expect(controller.conversationMessages, service.messagesResult);
        expect(service.requestedConversationId, 'conversation-1');
        expect(service.requestedCurrentUserId, 'current-user');
        expect(service.readCallCount, 1);
        expect(controller.inbox.single.unreadCount, 0);
        expect(controller.isLoadingConversation, isFalse);
        expect(controller.chatErrorMessage, isNull);
      },
    );

    test('shows an error when conversation messages fail to load', () async {
      service.conversationFailure = Exception('Request failed (404)');

      await controller.loadConversationMessages(
        conversationId: 'missing',
        currentUserId: 'current-user',
      );

      expect(controller.conversationMessages, isEmpty);
      expect(
        controller.chatErrorMessage,
        'This conversation could not be found.',
      );
      expect(service.readCallCount, 0);
      expect(controller.isLoadingConversation, isFalse);
    });

    test(
      'sends a trimmed message and updates chat and inbox preview',
      () async {
        controller.inbox = [testConversation()];
        controller.conversationMessages = [];

        final sent = await controller.sendMessage(
          conversationId: 'conversation-1',
          content: '  Thanks!  ',
          currentUserId: 'current-user',
        );

        expect(sent, isTrue);
        expect(service.sentContent, 'Thanks!');
        expect(controller.conversationMessages.single.content, 'Thanks!');
        expect(controller.inbox.single.lastMessage, 'Thanks!');
        expect(
          controller.inbox.single.lastMessageAt,
          testSentAt.add(const Duration(minutes: 1)),
        );
        expect(controller.chatErrorMessage, isNull);
        expect(controller.isSending, isFalse);
      },
    );

    test('does not send an empty message', () async {
      final sent = await controller.sendMessage(
        conversationId: 'conversation-1',
        content: '   ',
        currentUserId: 'current-user',
      );

      expect(sent, isFalse);
      expect(service.sentContent, isNull);
      expect(controller.chatErrorMessage, 'Write a message before sending.');
    });

    test('maps send failures to a user-facing error', () async {
      service.sendFailure = Exception('Request failed (403)');

      final sent = await controller.sendMessage(
        conversationId: 'conversation-1',
        content: 'Hello',
        currentUserId: 'current-user',
      );

      expect(sent, isFalse);
      expect(
        controller.chatErrorMessage,
        'You no longer have access to this conversation.',
      );
      expect(controller.conversationMessages, isEmpty);
      expect(controller.isSending, isFalse);
    });
  });
}
