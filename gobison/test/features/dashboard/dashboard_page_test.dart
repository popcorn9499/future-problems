// Widget tests for DashboardPage.
//
// These need one small change to the page so a test can supply its own
// service instead of the real network-backed one:
//
//   const DashboardPage({super.key, required this.user, this.dashboardService});
//   final DashboardService? dashboardService;
//   ...
//   _dashboardService = widget.dashboardService ?? DashboardService();

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/user.dart';
import 'package:gobison/features/dashboard/dashboard_service.dart';
import 'package:gobison/features/dashboard/presentation/dashboard_page.dart';

const _currentUser = User(
  id: 'jankek@myumanitoba.ca',
  firstName: 'Kamryn',
  lastName: 'Janke',
  email: 'jankek@myumanitoba.ca',
  verified: true,
);

Map<String, dynamic> _member(
  String id,
  String first,
  String last,
  String address,
) => {'id': id, 'firstName': first, 'lastName': last, 'address': address};

/// One agreement. By default Kamryn (the current user) drives and Sasha rides,
/// and both have an address.
Map<String, dynamic> _agreement({
  int id = 1,
  String origin = 'Morris',
  List<String> days = const ['MONDAY', 'WEDNESDAY'],
  String status = 'ACTIVE',
  List<Map<String, dynamic>>? drivers,
  List<Map<String, dynamic>>? passengers,
}) => {
  'id': id,
  'origin': origin,
  'destination': 'University of Manitoba',
  'departureTime': '07:45',
  'daysOfWeek': days,
  'status': status,
  'drivers':
      drivers ??
      [_member('jankek@myumanitoba.ca', 'Kamryn', 'Janke', '123 Main St, Morris')],
  'passengers':
      passengers ??
      [_member('coless1@myumanitoba.ca', 'Sasha', 'Coles', '45 Elm Ave, Morris')],
};

/// Two agreements on different days, for the filter tests.
List<Map<String, dynamic>> _twoAgreements() => [
  _agreement(id: 1, origin: 'Morris', days: ['MONDAY', 'WEDNESDAY']),
  _agreement(id: 2, origin: 'Osborne Village', days: ['TUESDAY', 'THURSDAY']),
];

http.Response _ok(List<Map<String, dynamic>> body) =>
    http.Response(jsonEncode(body), 200);

Future<void> _pumpPage(WidgetTester tester, MockClient client) async {
  // Tall enough that every ticket is built without scrolling.
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      // The app's AppShell supplies a Scaffold; snackbars need one here too.
      home: Scaffold(
        body: DashboardPage(
          user: _currentUser,
          dashboardService: DashboardService(client: client, useMock: false),
        ),
      ),
    ),
  );
}

Future<void> _pumpWith(
  WidgetTester tester,
  List<Map<String, dynamic>> agreements,
) async {
  await _pumpPage(tester, MockClient((request) async => _ok(agreements)));
  await tester.pumpAndSettle();
}

Finder _chip(String label) => find.widgetWithText(FilterChip, label);

bool _isSelected(WidgetTester tester, String label) =>
    tester.widget<FilterChip>(_chip(label)).selected;

Future<void> _tapChip(WidgetTester tester, String label) async {
  await tester.tap(_chip(label));
  await tester.pump();
}

void main() {
  group('loading, empty and error states', () {
    testWidgets('shows a spinner while loading, then the tickets', (tester) async {
      final completer = Completer<http.Response>();
      await _pumpPage(tester, MockClient((request) => completer.future));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(_ok([_agreement()]));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('University of Manitoba'), findsOneWidget);
      expect(find.text('7:45 AM'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('shows the empty state, without filters, when there are no agreements', (tester) async {
      await _pumpWith(tester, []);

      expect(find.text('No ride agreements yet'), findsOneWidget);
      expect(find.byType(FilterChip), findsNothing);
    });

    testWidgets('shows the error state and recovers when retrying', (tester) async {
      var status = 500;
      await _pumpPage(
        tester,
        MockClient(
          (request) async =>
              status == 200 ? _ok([_agreement()]) : http.Response('', status),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(
        find.text('It\'s not you, it\'s us. Please try again later.'),
        findsOneWidget,
      );

      status = 200;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong'), findsNothing);
      expect(find.text('Morris'), findsOneWidget);
    });

    testWidgets('shows the session-expired message for a 401', (tester) async {
      await _pumpPage(
        tester,
        MockClient((request) async => http.Response('', 401)),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Your session has expired. Please log in again.'),
        findsOneWidget,
      );
    });
  });

  group('ticket contents', () {
    testWidgets('uses singular section labels for one driver and one passenger', (tester) async {
      await _pumpWith(tester, [_agreement()]);

      expect(find.text('DRIVER'), findsOneWidget);
      expect(find.text('PASSENGER'), findsOneWidget);
    });

    testWidgets('pluralises DRIVERS when there are several drivers', (tester) async {
      await _pumpWith(tester, [
        _agreement(
          drivers: [
            _member('a', 'Ann', 'One', '1 A St'),
            _member('b', 'Bob', 'Two', '2 B St'),
          ],
        ),
      ]);

      expect(find.text('DRIVERS'), findsOneWidget);
    });

    testWidgets('shows non-active statuses with a capitalised label', (tester) async {
      await _pumpWith(tester, [_agreement(status: 'PENDING')]);

      expect(find.text('Pending'), findsOneWidget);
    });
  });

  group('current user marker', () {
    testWidgets('shows a YOU badge only on the current user', (tester) async {
      await _pumpWith(tester, [_agreement()]);

      expect(find.text('YOU'), findsOneWidget);
      expect(find.text('Kamryn Janke'), findsOneWidget);
      expect(find.text('Sasha Coles'), findsOneWidget);
    });

    testWidgets('does not append the old "(you)" suffix to names', (tester) async {
      await _pumpWith(tester, [_agreement()]);

      expect(find.text('Kamryn Janke (you)'), findsNothing);
    });
  });

  group('copy address', () {
    testWidgets('shows a copy button for other members but not for the current user', (tester) async {
      await _pumpWith(tester, [_agreement()]);

      // Kamryn (you) and Sasha both have addresses; only Sasha gets a button.
      expect(find.byTooltip('Copy address'), findsOneWidget);
    });


    testWidgets('tapping copy puts the other member\'s address on the clipboard and confirms', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied =
                (call.arguments as Map<dynamic, dynamic>)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await _pumpWith(tester, [_agreement()]);

      await tester.tap(find.byTooltip('Copy address'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(copied, '45 Elm Ave, Morris');
      expect(find.text('Address copied to clipboard!'), findsOneWidget);
    });
  });

  group('day filter', () {
    testWidgets('shows the filter chips above the tickets', (tester) async {
      await _pumpWith(tester, _twoAgreements());

      expect(find.text('FILTER BY DAY'), findsOneWidget);
      expect(find.byType(FilterChip), findsNWidgets(6));
      for (final label in ['All', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday']) {
        expect(_chip(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('starts with All selected and shows every ticket', (tester) async {
      await _pumpWith(tester, _twoAgreements());

      expect(_isSelected(tester, 'All'), isTrue);
      expect(_isSelected(tester, 'Monday'), isFalse);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Osborne Village'), findsOneWidget);
    });

    testWidgets('tapping a day shows only tickets that run on that day', (tester) async {
      await _pumpWith(tester, _twoAgreements());

      await _tapChip(tester, 'Monday');

      expect(_isSelected(tester, 'Monday'), isTrue);
      expect(_isSelected(tester, 'All'), isFalse);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Osborne Village'), findsNothing);
    });

    testWidgets('tapping the same day again removes the filter', (tester) async {
      await _pumpWith(tester, _twoAgreements());

      await _tapChip(tester, 'Monday');
      await _tapChip(tester, 'Monday');

      expect(_isSelected(tester, 'All'), isTrue);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Osborne Village'), findsOneWidget);
    });

    testWidgets('selecting several days shows tickets matching any of them', (tester) async {
      await _pumpWith(tester, _twoAgreements());

      await _tapChip(tester, 'Monday');
      await _tapChip(tester, 'Tuesday');

      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Osborne Village'), findsOneWidget);
    });

    testWidgets('All clears the selected days', (tester) async {
      await _pumpWith(tester, _twoAgreements());

      await _tapChip(tester, 'Tuesday');
      expect(find.text('Morris'), findsNothing);

      await _tapChip(tester, 'All');

      expect(_isSelected(tester, 'All'), isTrue);
      expect(_isSelected(tester, 'Tuesday'), isFalse);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Osborne Village'), findsOneWidget);
    });

    testWidgets('shows a message when no ticket runs on the selected day', (tester) async {
      await _pumpWith(tester, _twoAgreements());

      await _tapChip(tester, 'Friday');

      expect(find.text('No rides on this day'), findsOneWidget);
      expect(find.text('Morris'), findsNothing);
      expect(find.text('Osborne Village'), findsNothing);
      // The filter stays visible so the user can change their selection.
      expect(find.text('FILTER BY DAY'), findsOneWidget);
    });
  });
}