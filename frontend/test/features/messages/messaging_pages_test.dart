import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/theme/avatar_color_option.dart';
import 'package:gobison/core/widgets/user_avatar.dart';
import 'package:gobison/features/messages/messaging_api_mock.dart';
import 'package:gobison/features/messages/messaging_controller.dart';
import 'package:gobison/features/messages/messaging_service.dart';
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

    testWidgets('opens a chat from the mock-backed inbox', (tester) async {
      final mockService = MessagingService(mock: MessagingApiMock());
      final mockBackedController = MessagingController(
        messagingService: mockService,
      );
      addTearDown(mockService.close);
      addTearDown(mockBackedController.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: InboxPage(
            currentUserId: 'current-user',
            controller: mockBackedController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jane Doe'), findsOneWidget);
      expect(
        find.text(
          'Preview messages · All messages are simulated and not sent to a real user.',
        ),
        findsOneWidget,
      );
      final avatar = tester.widget<UserAvatar>(find.byType(UserAvatar).first);
      expect(
        avatar.backgroundColor,
        AvatarColorOption.getBackgroundColor('#D1C4E9'),
      );

      await tester.tap(find.text('Jane Doe'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(
        find.text('Hi! Are you still looking for a ride to campus?'),
        findsOneWidget,
      );
    });

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
      final avatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(
        avatar.backgroundColor,
        AvatarColorOption.getBackgroundColor('#D1C4E9'),
      );
      expect(avatar.textColor, AvatarColorOption.getTextColor('#D1C4E9'));
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

    testWidgets('refreshes the inbox when the shell hides the app bar', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: InboxPage(
            currentUserId: 'current-user',
            controller: controller,
            showAppBar: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      service.inboxResult = [testConversation(preview: 'An incoming message')];

      await tester.tap(find.text('Refresh messages'));
      await tester.pumpAndSettle();

      expect(find.text('An incoming message'), findsOneWidget);
    });

    testWidgets('opens a chat, sends a message, and refreshes the thread', (
      tester,
    ) async {
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
      final chatAvatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
      expect(
        chatAvatar.backgroundColor,
        AvatarColorOption.getBackgroundColor('#D1C4E9'),
      );

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

      service.messagesResult = [
        ...controller.conversationMessages,
        testChatMessage(id: 'reply', content: 'A reply'),
      ];
      await tester.tap(find.byTooltip('Refresh conversation'));
      await tester.pumpAndSettle();

      expect(find.text('A reply'), findsOneWidget);
    });

    testWidgets('polls visible chats and retries while preserving the draft', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
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
      await tester.enterText(find.byType(TextField), 'Unsent draft');

      service.conversationFailure = Exception('Network unavailable');
      await tester.pump(const Duration(seconds: 5));
      expect(service.conversationCallCount, 2);
      expect(find.text('Hello there'), findsOneWidget);
      expect(controller.chatErrorMessage, isNull);

      service.conversationFailure = null;
      service.messagesResult = [
        ...service.messagesResult,
        testChatMessage(id: 'reply', content: 'Automatic reply'),
      ];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump(const Duration(seconds: 5));
      expect(service.conversationCallCount, 2);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      expect(find.text('Automatic reply'), findsOneWidget);
      expect(find.text('Unsent draft'), findsOneWidget);
      expect(service.readCallCount, 2);

      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 10));
      expect(service.conversationCallCount, 3);
    });
  });
}
