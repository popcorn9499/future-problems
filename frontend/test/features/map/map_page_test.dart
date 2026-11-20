import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/navigation/app_shell.dart';
import 'package:gobison/core/services/session_service.dart';
import 'package:gobison/features/auth/presentation/login_page.dart';
import 'package:gobison/features/map/map_page.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  const testUser = User(
    id: 'usr_test',
    firstName: 'Test',
    lastName: 'User',
    email: 'testuser@myumanitoba.ca',
    verified: true,
  );

  Widget createTestWidget() {
    return const MaterialApp(home: CarpoolMultiSourceMapPage(user: testUser));
  }

  /// Uses a desktop-sized screen so the whole filter bar fits above the map
  void useLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  /// pumpAndSettle can time out while the loading spinner is animating,
  /// so pump for a fixed time instead to let loads and animations finish.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> pumpMapPage(
    WidgetTester tester, {
    Future<http.Response> Function(http.Request)? respond,
  }) async {
    useLargeScreen(tester);
    await http.runWithClient(
      () async {
        await tester.pumpWidget(createTestWidget());
        await settle(tester);
      },
      () => MockClient((request) async {
        if (!request.url.path.startsWith('/api/v1/rides/')) {
          return http.Response('', 404);
        }
        return respond == null ? http.Response('{}', 200) : respond(request);
      }),
    );
  }

  // Dropdowns build every item (hidden) to size themselves, so checking
  // for item text can't tell which one is selected. Read the value instead.
  String? selectedRideType(WidgetTester tester) => tester
      .widget<DropdownButton<String?>>(find.byType(DropdownButton<String?>))
      .value;

  String? selectedStatus(WidgetTester tester) => tester
      .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
      .value;

  Future<void> openRideTypeDropdown(WidgetTester tester) async {
    await tester.tap(find.byType(DropdownButton<String?>));
    await settle(tester);
  }

  Future<void> selectRideType(WidgetTester tester, String label) async {
    await openRideTypeDropdown(tester);
    // The open menu is drawn on top, so its item is the last match
    await tester.tap(find.text(label).last);
    await settle(tester);
  }

  group('CarpoolMultiSourceMapPage filter bar', () {
    testWidgets('shows all filter controls', (WidgetTester tester) async {
      await pumpMapPage(tester);

      expect(find.widgetWithText(TextField, 'City'), findsOneWidget);
      expect(find.text('Days of Week'), findsOneWidget);
      expect(find.text('Ride Type'), findsOneWidget);
      expect(find.text('Departure Time'), findsOneWidget);
      expect(find.text('Arrival Time'), findsOneWidget);
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Show Requests'), findsOneWidget);
      expect(find.text('Show Offers'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, 'Apply'), findsOneWidget);
    });

    testWidgets('does not show Clear Filters when no filters are set', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      expect(find.text('Clear Filters'), findsNothing);
    });
  });

  group('CarpoolMultiSourceMapPage ride type dropdown', () {
    testWidgets('defaults to Any', (WidgetTester tester) async {
      await pumpMapPage(tester);

      expect(selectedRideType(tester), isNull);
      expect(find.text('Any'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('shows roundTrip as Round trip', (WidgetTester tester) async {
      await pumpMapPage(tester);

      await openRideTypeDropdown(tester);

      expect(find.text('arriving'), findsWidgets);
      expect(find.text('departing'), findsWidgets);
      expect(find.text('Round trip'), findsWidgets);
      expect(find.text('roundTrip'), findsNothing);
    });

    testWidgets('selecting a ride type shows Clear Filters', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      await selectRideType(tester, 'departing');

      expect(selectedRideType(tester), 'departing');
      expect(find.text('Clear Filters'), findsOneWidget);
    });

    testWidgets('Clear Filters resets ride type to Any', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);
      await selectRideType(tester, 'departing');

      await tester.tap(find.text('Clear Filters'));
      await settle(tester);

      expect(selectedRideType(tester), isNull);
      expect(find.text('Clear Filters'), findsNothing);
    });
  });

  group('CarpoolMultiSourceMapPage status dropdown', () {
    testWidgets('defaults to OPEN with no Default option', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      expect(selectedStatus(tester), 'OPEN');
      expect(find.text('Default (OPEN)'), findsNothing);
    });

    testWidgets('only offers OPEN and CLOSED', (WidgetTester tester) async {
      await pumpMapPage(tester);

      await tester.tap(find.byType(DropdownButton<String>));
      await settle(tester);

      expect(find.text('CLOSED'), findsWidgets);
      expect(find.text('Default (OPEN)'), findsNothing);
    });

    testWidgets('choosing CLOSED counts as an active filter', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      await tester.tap(find.byType(DropdownButton<String>));
      await settle(tester);
      await tester.tap(find.text('CLOSED').last);
      await settle(tester);

      expect(selectedStatus(tester), 'CLOSED');
      expect(find.text('Clear Filters'), findsOneWidget);
    });
  });

  group('CarpoolMultiSourceMapPage days of week picker', () {
    testWidgets('opens a dialog with every day', (WidgetTester tester) async {
      await pumpMapPage(tester);

      await tester.tap(find.text('Days of Week'));
      await settle(tester);

      expect(find.text('Select Days of the Week'), findsOneWidget);
      for (final day in [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday',
      ]) {
        expect(find.text(day), findsOneWidget);
      }
    });

    testWidgets('applying selected days updates the button label', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      await tester.tap(find.text('Days of Week'));
      await settle(tester);
      // Pick out of order to check the label is sorted Monday-first
      await tester.tap(find.text('Friday'));
      await tester.tap(find.text('Monday'));
      await tester.pump();
      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Apply'),
        ),
      );
      await settle(tester);

      expect(find.text('MON, FRI'), findsOneWidget);
      expect(find.text('Clear Filters'), findsOneWidget);
    });

    testWidgets('cancelling the dialog keeps the previous selection', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      await tester.tap(find.text('Days of Week'));
      await settle(tester);
      await tester.tap(find.text('Monday'));
      await tester.tap(find.text('Cancel'));
      await settle(tester);

      expect(find.text('Days of Week'), findsOneWidget);
      expect(find.text('Clear Filters'), findsNothing);
    });
  });

  group('CarpoolMultiSourceMapPage show requests/offers toggles', () {
    testWidgets('both toggles start on Yes', (WidgetTester tester) async {
      await pumpMapPage(tester);

      expect(find.text('Yes'), findsNWidgets(2));
      expect(find.text('No'), findsNothing);
    });

    testWidgets('turning off Show Requests changes it to No', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      final requestsSwitch = find.descendant(
        of: find.widgetWithText(InputDecorator, 'Show Requests'),
        matching: find.byType(Switch),
      );
      await tester.tap(requestsSwitch);
      await settle(tester);

      expect(find.text('No'), findsOneWidget);
      expect(find.text('Yes'), findsOneWidget);
    });
  });

  group('CarpoolMultiSourceMapPage map', () {
    testWidgets('shows OpenStreetMap attribution', (WidgetTester tester) async {
      await pumpMapPage(tester);

      expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    });
  });

  group('CarpoolMultiSourceMapPage error dialog', () {
    testWidgets('Apply shows sign-in on the first unauthorized response', (
      tester,
    ) async {
      useLargeScreen(tester);
      addTearDown(SessionService.clearSession);
      await SessionService.saveUser(user: testUser);
      final requestedSources = <String>[];
      var expired = false;
      final pendingOffers = Completer<http.Response>();
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: const Scaffold(body: Text('Protected home')),
              initialRoute: '/map',
              routes: {
                '/map': (_) => AppShell(
                  dashboardPage: const SizedBox.shrink(),
                  inboxPage: const SizedBox.shrink(),
                  rideRequestPage: const SizedBox.shrink(),
                  rideOfferPage: const SizedBox.shrink(),
                  mapPage: const CarpoolMultiSourceMapPage(user: testUser),
                  user: testUser,
                  onProfileTap: () {},
                ),
              },
            ),
          );
          await settle(tester);
          await tester.tap(find.byIcon(Icons.map_outlined));
          await settle(tester);
          expect(find.byType(AlertDialog), findsNothing);

          expired = true;
          await tester.tap(find.widgetWithText(ElevatedButton, 'Apply'));
          await settle(tester);
        },
        () => MockClient((request) async {
          final path = request.url.path;
          if (!path.startsWith('/api/v1/rides/')) return http.Response('', 404);
          requestedSources.add(path);
          if (!expired) return http.Response('{}', 200);
          if (path.endsWith('/offers')) return pendingOffers.future;
          return http.Response('{"message":"Unauthorized"}', 401);
        }),
      );

      const message = 'Sign in again to continue using GoBison.';
      expect(requestedSources, [
        '/api/v1/rides/requests',
        '/api/v1/rides/offers',
        '/api/v1/rides/requests',
      ]);
      expect(find.text(message), findsOneWidget);
      expect(find.text('Your session has ended'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.textContaining('HTTP 401'), findsNothing);
      expect(find.text('Retry'), findsNothing);
      expect(find.text('Dismiss'), findsNothing);

      await tester.binding.handlePopRoute();
      await tester.tapAt(const Offset(20, 20));
      await tester.pump(const Duration(minutes: 1));
      expect(find.text(message), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await settle(tester);
      expect(find.byType(LoginPage), findsOneWidget);
      expect(SessionService.cachedSession, isNull);
      expect(tester.state<NavigatorState>(find.byType(Navigator)).canPop(), isFalse);
    });

    testWidgets('centers a compact dialog and combines duplicate messages', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(
        tester,
        respond: (_) async => http.Response('', 400),
      );

      final dialog = find.byType(AlertDialog);
      expect(dialog, findsOneWidget);
      final surface = find.descendant(
        of: dialog,
        matching: find.byWidgetPredicate(
          (widget) => widget is Material && widget.type == MaterialType.card,
        ),
      );
      expect(tester.getCenter(surface), const Offset(800, 500));
      expect(tester.getSize(surface).width, lessThanOrEqualTo(400));
      expect(find.text('Couldn’t load rides'), findsOneWidget);
      expect(find.text('Check your filters and try again.'), findsOneWidget);
      expect(find.textContaining('HTTP'), findsNothing);
      expect(find.text('Retry'), findsOneWidget);
    });

    for (final (status, message) in [
      (403, 'You don’t have permission to view these rides.'),
      (503, 'The server is having trouble. Please try again later.'),
      (429, 'Please try again.'),
      (null, 'Check your connection and try again.'),
    ]) {
      testWidgets('shows a friendly map error for ${status ?? 'network loss'}', (
        tester,
      ) async {
        await pumpMapPage(
          tester,
          respond: (request) async {
            if (request.url.path.endsWith('/requests')) {
              return http.Response('{}', 200);
            }
            if (status == null) throw http.ClientException('Network details');
            return http.Response('{"message":"Internal details 401"}', status);
          },
        );

        expect(find.text('Ride offers couldn’t load. $message'), findsOneWidget);
        expect(find.textContaining('Internal details'), findsNothing);
        expect(find.textContaining('Network details'), findsNothing);
        expect(find.textContaining('HTTP'), findsNothing);
        expect(find.text('Retry'), findsOneWidget);
        expect(find.widgetWithText(TextButton, 'Dismiss'), findsOneWidget);
      });
    }

    testWidgets('hides the no-results message while an error is shown', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester, respond: (_) async => http.Response('', 500));

      expect(find.text('No rides match the selected filters.'), findsNothing);
    });

    testWidgets('dismiss button closes the dialog', (WidgetTester tester) async {
      await pumpMapPage(tester, respond: (_) async => http.Response('', 500));

      await tester.tap(find.widgetWithText(TextButton, 'Dismiss'));
      await settle(tester);

      expect(find.textContaining('Couldn’t load'), findsNothing);
      expect(find.text('No rides match the selected filters.'), findsOneWidget);
    });

    testWidgets('retry reloads both sources and closes the dialog on success', (
      tester,
    ) async {
      var requests = 0;
      await pumpMapPage(
        tester,
        respond: (_) async => ++requests <= 2
            ? http.Response('', 500)
            : http.Response('{}', 200),
      );

      await tester.tap(find.widgetWithText(FilledButton, 'Retry'));
      await settle(tester);

      expect(requests, 4);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('No rides match the selected filters.'), findsOneWidget);
    });

    testWidgets('defers background map errors until the map is selected', (
      tester,
    ) async {
      useLargeScreen(tester);
      await http.runWithClient(
        () async {
          await tester.pumpWidget(
            MaterialApp(
              home: AppShell(
                dashboardPage: const Text('Dashboard content'),
                inboxPage: const SizedBox.shrink(),
                rideRequestPage: const SizedBox.shrink(),
                rideOfferPage: const SizedBox.shrink(),
                mapPage: const CarpoolMultiSourceMapPage(user: testUser),
                user: testUser,
                onProfileTap: () {},
              ),
            ),
          );
          await settle(tester);
          expect(find.text('Dashboard content'), findsOneWidget);
          expect(find.byType(AlertDialog), findsNothing);

          await tester.tap(find.byIcon(Icons.map_outlined));
          await settle(tester);
        },
        () => MockClient((_) async => http.Response('', 500)),
      );

      expect(find.text('Couldn’t load rides'), findsOneWidget);
    });

    testWidgets('defers map errors until the filter dialog closes', (
      tester,
    ) async {
      final response = Completer<http.Response>();
      await pumpMapPage(tester, respond: (_) => response.future);

      await tester.tap(find.text('Days of Week'));
      await settle(tester);
      response.complete(http.Response('', 500));
      await settle(tester);

      expect(find.text('Couldn’t load rides'), findsNothing);
      await tester.tap(find.text('Cancel'));
      await settle(tester);
      expect(find.text('Couldn’t load rides'), findsOneWidget);
    });

    testWidgets('turning off both sources shows no error', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      final switches = find.byType(Switch);
      await tester.tap(switches.at(0));
      await settle(tester);
      await tester.tap(switches.at(1));
      await settle(tester);

      expect(find.textContaining('Couldn’t load'), findsNothing);
      expect(find.text('No rides match the selected filters.'), findsOneWidget);
    });
  });
}
