import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/navigation/app_shell.dart';
import 'package:gobison/core/navigation/navigation_item.dart';

void main() {
  const user = User(
    id: 'ada',
    firstName: 'Ada',
    lastName: 'Lovelace',
    email: 'ada@example.com',
    verified: true,
  );

  Widget createTestWidget({VoidCallback? onProfileTap}) {
    return MaterialApp(
      home: AppShell(
        dashboardPage: const Text('Dashboard content'),
        messagesPage: const Text('Messages content'),
        user: user,
        onProfileTap: onProfileTap ?? () {},
      ),
    );
  }

  group('AppShell', () {
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
      expect(navItems.first.isSelected, isFalse);
      expect(navItems.elementAt(1).isSelected, isTrue);
    });

    testWidgets('collapses and expands the sidebar', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Dashboard'), findsNWidgets(2));
      await tester.tap(find.byTooltip('Collapse sidebar'));
      await tester.pumpAndSettle();

      // The page title remains while the sidebar label is replaced by a tooltip.
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
