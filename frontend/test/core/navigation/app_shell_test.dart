import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/navigation/app_shell.dart';
import 'package:gobison/core/navigation/navigation_item.dart';
import 'package:gobison/core/widgets/unread_message_badge.dart';
import 'package:gobison/features/messages/messaging_controller.dart';
import 'package:gobison/features/messages/presentation/chat_page.dart';
import 'package:gobison/features/messages/presentation/inbox_page.dart';

import '../../features/messages/messaging_test_helpers.dart';

void main() {
  const user = User(
    id: 'ada',
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: 'ada@example.com',
    verified: true,
  );

  Widget createTestWidget({
    VoidCallback? onProfileTap,
    MessagingController? messaging,
  }) {
    return MaterialApp(
      home: AppShell(
        dashboardPage: const Text('Dashboard content'),
        inboxPage: messaging == null
            ? const Text('Messages content')
            : InboxPage(
                currentUserId: user.id,
                controller: messaging,
                showAppBar: false,
              ),
        messagingController: messaging,
        rideRequestPage: const Text('Ride Request content'),
        rideOfferPage: const Text('Ride Offer content'),
        mapPage: const Text('Ride Requests & Offers'),
        user: user,
        onProfileTap: onProfileTap ?? () {},
      ),
    );
  }

  group('AppShell', () {
    testWidgets('totals unread messages and refreshes only in the foreground', (
      tester,
    ) async {
      final service = FakeMessagingService()
        ..inboxResult = [
          testConversation(),
          testConversation(id: 'other', unreadCount: 3),
        ];
      final messaging = MessagingController(messagingService: service);
      addTearDown(service.close);
      addTearDown(messaging.dispose);

      await tester.pumpWidget(createTestWidget(messaging: messaging));
      await tester.pumpAndSettle();
      final badge = find.byType(UnreadMessageBadge);
      expect(find.descendant(of: badge, matching: find.text('5')), findsOneWidget);

      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Messages, 5 unread messages'), findsOneWidget);
      final icon = find.byIcon(Icons.chat_bubble_outline_rounded);
      expect(tester.getCenter(badge).dx, greaterThan(tester.getCenter(icon).dx));
      expect(tester.getCenter(badge).dy, lessThan(tester.getCenter(icon).dy));

      service.inboxResult = [testConversation(unreadCount: 4)];
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);

      service.inboxFailure = Exception('Network unavailable');
      await tester.pump(const Duration(seconds: 15));
      await tester.pump();
      expect(find.text('4'), findsOneWidget);
      expect(messaging.inboxErrorMessage, isNull);

      service.inboxFailure = null;
      service.inboxResult = [testConversation(unreadCount: 0)];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      await tester.pump(const Duration(seconds: 15));
      expect(find.text('4'), findsOneWidget);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(badge, findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('reading a chat updates the shared sidebar count', (tester) async {
      final service = FakeMessagingService()
        ..inboxResult = [
          testConversation(),
          testConversation(id: 'other', name: 'Alex Rider', unreadCount: 3),
        ];
      final messaging = MessagingController(messagingService: service);
      addTearDown(service.close);
      addTearDown(messaging.dispose);
      await tester.pumpWidget(createTestWidget(messaging: messaging));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jane Doe'));
      await tester.pumpAndSettle();

      expect(find.byType(ChatPage), findsOneWidget);
      expect(service.readCallCount, 1);
      expect(messaging.unreadCount, 3);
      service.inboxResult = [
        testConversation(unreadCount: 0),
        testConversation(id: 'other', name: 'Alex Rider', unreadCount: 3),
      ];
      await tester.pageBack();
      await tester.pumpAndSettle();
      final sidebar = find.widgetWithText(NavigationItem, 'Messages');
      expect(find.descendant(of: sidebar, matching: find.text('3')), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });

    testWidgets('shows dashboard by default and switches to messages', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Dashboard content'), findsOneWidget);
      expect(find.text('Dashboard'), findsNWidgets(2));
      expect(find.text('Messages content'), findsNothing);

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(find.text('Messages content'), findsOneWidget);
      expect(find.text('Messages'), findsNWidgets(2));

      final navItems = tester.widgetList<NavigationItem>(
        find.byType(NavigationItem),
      );

      expect(navItems.elementAt(0).isSelected, isFalse);
      expect(navItems.elementAt(1).isSelected, isTrue);
    });

    testWidgets('navigates to Create Ride Request', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Create Ride Request'));
      await tester.pumpAndSettle();

      expect(find.text('Ride Request content'), findsOneWidget);
      expect(find.text('Create Ride Request'), findsNWidgets(2));

      final navItems = tester.widgetList<NavigationItem>(
        find.byType(NavigationItem),
      );

      expect(navItems.elementAt(0).isSelected, isFalse);
      expect(navItems.elementAt(2).isSelected, isTrue);
    });

    testWidgets('navigates to Create Ride Offer', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      await tester.tap(find.text('Create Ride Offer'));
      await tester.pumpAndSettle();

      expect(find.text('Ride Offer content'), findsOneWidget);
      expect(find.text('Create Ride Offer'), findsNWidgets(2));

      final navItems = tester.widgetList<NavigationItem>(
        find.byType(NavigationItem),
      );

      expect(navItems.elementAt(0).isSelected, isFalse);
      expect(navItems.elementAt(3).isSelected, isTrue);
    });

    testWidgets('collapses and expands the sidebar', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Dashboard'), findsNWidgets(2));

      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byTooltip('Dashboard'), findsOneWidget);

      await tester.tap(find.byTooltip('Expand sidebar'));
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsNWidgets(2));
    });

    testWidgets('tapping the avatar calls the profile callback', (
      WidgetTester tester,
    ) async {
      var profileTapped = false;

      await tester.pumpWidget(
        createTestWidget(onProfileTap: () => profileTapped = true),
      );

      await tester.tap(find.text('AL'));

      expect(profileTapped, isTrue);
    });
  });
}
