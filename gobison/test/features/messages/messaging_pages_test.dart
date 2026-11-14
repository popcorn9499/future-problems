import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/messages/messaging_controller.dart';
import 'package:gobison/features/messages/presentation/chat_page.dart';
import 'package:gobison/features/messages/presentation/inbox_page.dart';

import 'messaging_test_helpers.dart';

void main() {
  group('InboxPage', () {
    late FakeMessagingService service;
    late MessagingController controller;

    setUp(() {
      service = FakeMessagingService();
      controller = MessagingController(messagingService: service);
    });

    tearDown(() => controller.dispose());

    testWidgets('shows conversation previews and unread count', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InboxPage(
            currentUserId: 'current-user',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('See you soon'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('shows an empty inbox message', (tester) async {
      service.inboxResult = [];

      await tester.pumpWidget(
        MaterialApp(
          home: InboxPage(
            currentUserId: 'current-user',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No conversations yet'), findsOneWidget);
      expect(find.text('Jane Doe'), findsNothing);
    });

    testWidgets('opens a chat and sends a message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InboxPage(
            currentUserId: 'current-user',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Jane Doe'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(find.text('Hello there'), findsOneWidget);
      expect(service.requestedConversationId, 'conversation-1');
      expect(service.readCallCount, 1);

      await tester.enterText(find.byType(TextField), 'A new message');
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();

      expect(find.text('A new message'), findsOneWidget);
      expect(service.sentContent, 'A new message');
      expect(controller.conversationMessages, hasLength(2));
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty,
      );
    });
  });
}
