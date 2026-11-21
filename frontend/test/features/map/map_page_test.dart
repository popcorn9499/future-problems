import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/navigation/app_shell.dart';
import 'package:gobison/core/navigation/dashboard_ride_navigation.dart';
import 'package:gobison/core/services/session_service.dart';
import 'package:gobison/core/theme/app_colors.dart';
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

  Widget createTestWidget({double? sheetWidth}) {
    return MaterialApp(
      theme: sheetWidth == null
          ? null
          : ThemeData(
              bottomSheetTheme: BottomSheetThemeData(
                constraints: BoxConstraints(maxWidth: sheetWidth),
              ),
            ),
      home: const CarpoolMultiSourceMapPage(user: testUser),
    );
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
    testWidgets('places evenly sized filters at the top of the map', (
      tester,
    ) async {
      await pumpMapPage(tester);

      final selector = find.byWidgetPredicate(
        (widget) => widget is SegmentedButton,
      );
      final controls = [
        selector,
        find.byType(TextField),
        find.byType(DropdownButtonFormField<String?>),
        for (final label in [
          'Days of Week',
          'Arrive at campus by',
          'Leave campus at',
        ])
          find.ancestor(of: find.text(label), matching: find.byType(InkWell)).first,
      ];

      expect(find.byType(AppBar), findsNothing);
      expect(tester.getTopLeft(selector).dy, closeTo(25, 1));
      final myPosts = find.widgetWithText(FilterChip, 'Show my posts');
      final departure = find.text('Leave campus at');
      expect(tester.getCenter(myPosts).dy, tester.getCenter(departure).dy);
      expect(tester.getTopLeft(myPosts).dx, greaterThan(tester.getTopRight(departure).dx));
      for (final control in controls) {
        expect(tester.getSize(control).height, 44);
      }

      // Measure the painted surfaces as well as their outer layout boxes.
      for (final field in [find.byType(EditableText), find.text('Any')]) {
        final border = InputDecorator.containerOf(tester.element(field));
        expect(border?.size.height, 44);
      }
      for (final button in [
        find.widgetWithText(TextButton, 'All rides'),
      ]) {
        final surface = find.descendant(
          of: button,
          matching: find.byType(Material),
        );
        expect(tester.getSize(surface.first).height, 44);
      }
    });

    testWidgets('shows all filter controls', (WidgetTester tester) async {
      await pumpMapPage(tester);

      expect(find.widgetWithText(TextField, 'City'), findsOneWidget);
      expect(find.text('Days of Week'), findsOneWidget);
      expect(find.text('Ride Type'), findsOneWidget);
      expect(find.text('Leave campus at'), findsOneWidget);
      expect(find.text('Arrive at campus by'), findsOneWidget);
      expect(find.text('Status'), findsNothing);
      expect(find.text('All rides'), findsOneWidget);
      expect(find.text('Requests'), findsOneWidget);
      expect(find.text('Offers'), findsOneWidget);
      expect(find.byType(Switch), findsOneWidget);
      expect(find.text('Apply'), findsNothing);
    });

    testWidgets('updates city results after typing pauses', (tester) async {
      final cities = <String?>[];
      await pumpMapPage(
        tester,
        respond: (request) async {
          cities.add(request.url.queryParameters['city']);
          return http.Response('{}', 200);
        },
      );

      final city = find.byType(TextField);
      await tester.enterText(city, 'Win');
      await tester.pump(const Duration(milliseconds: 200));
      await tester.enterText(city, 'Winnipeg');
      await tester.pump(const Duration(milliseconds: 200));
      expect(cities, [null, null]);

      await settle(tester);
      expect(cities, [null, null, 'Winnipeg', 'Winnipeg']);
    });

    testWidgets('formats and clears selected campus times', (tester) async {
      final queries = <Map<String, String>>[];
      await pumpMapPage(
        tester,
        respond: (request) async {
          queries.add(request.url.queryParameters);
          return http.Response('{}', 200);
        },
      );

      for (final (label, parameter) in [
        ('Leave campus at', 'departureTime'),
        ('Arrive at campus by', 'arrivalTime'),
      ]) {
        await tester.tap(find.text(label));
        await settle(tester);
        await tester.tap(find.text('OK'));
        await settle(tester);

        final selected = find.text('$label · 8:30 AM');
        expect(selected, findsOneWidget);
        expect(queries.last[parameter], '08:30');

        final chip = find.ancestor(of: selected, matching: find.byType(InkWell));
        await tester.tap(
          find.descendant(of: chip.first, matching: find.byIcon(Icons.close)),
        );
        await settle(tester);

        expect(find.text(label), findsOneWidget);
        expect(selected, findsNothing);
        expect(queries.last.containsKey(parameter), isFalse);
      }
    });

    testWidgets('does not show Clear Filters when no filters are set', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      expect(find.text('Clear Filters'), findsNothing);
    });
  });

  group('CarpoolMultiSourceMapPage ride type dropdown', () {
    testWidgets('hides and clears times that do not match the direction', (
      tester,
    ) async {
      final queries = <Map<String, String>>[];
      await pumpMapPage(
        tester,
        respond: (request) async {
          queries.add(request.url.queryParameters);
          return http.Response('{}', 200);
        },
      );

      await tester.tap(find.text('Leave campus at'));
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(queries.last['departureTime'], '08:30');

      await selectRideType(tester, 'To campus');
      expect(find.text('Arrive at campus by'), findsOneWidget);
      expect(find.textContaining('Leave campus at'), findsNothing);
      expect(queries.last.containsKey('departureTime'), isFalse);

      await tester.tap(find.text('Arrive at campus by'));
      await settle(tester);
      await tester.tap(find.text('OK'));
      await settle(tester);
      expect(queries.last['arrivalTime'], '08:30');

      await selectRideType(tester, 'From campus');
      expect(find.text('Leave campus at'), findsOneWidget);
      expect(find.textContaining('Arrive at campus by'), findsNothing);
      expect(queries.last.containsKey('arrivalTime'), isFalse);

      await selectRideType(tester, 'Round trip');
      expect(find.text('Arrive at campus by'), findsOneWidget);
      expect(find.text('Leave campus at'), findsOneWidget);
    });

    testWidgets('defaults to Any', (WidgetTester tester) async {
      await pumpMapPage(tester);

      expect(selectedRideType(tester), isNull);
      expect(find.text('Any'), findsOneWidget);
      expect(find.text('—'), findsNothing);
    });

    testWidgets('shows campus directions and Round trip', (WidgetTester tester) async {
      await pumpMapPage(tester);

      await openRideTypeDropdown(tester);

      expect(find.text('To campus'), findsWidgets);
      expect(find.text('From campus'), findsWidgets);
      expect(find.text('Round trip'), findsWidgets);
      expect(find.text('roundTrip'), findsNothing);
    });

    testWidgets('selecting a ride type shows Clear Filters', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      await selectRideType(tester, 'From campus');

      expect(selectedRideType(tester), 'departing');
      expect(find.text('Clear Filters'), findsOneWidget);
    });

    testWidgets('Clear Filters resets ride type to Any', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);
      await selectRideType(tester, 'From campus');

      await tester.tap(find.text('Clear Filters'));
      await settle(tester);

      expect(selectedRideType(tester), isNull);
      expect(find.text('Clear Filters'), findsNothing);
    });
  });


  for (final source in ['requests', 'offers']) {
    testWidgets('hides status and inapplicable times in $source details', (
      tester,
    ) async {
      final isArrival = source == 'requests';
      final rideType = isArrival ? 'arriving' : 'departing';
      await pumpMapPage(
        tester,
        respond: (request) async {
          expect(request.url.queryParameters.containsKey('status'), isFalse);
          if (!request.url.path.endsWith('/$source')) {
            return http.Response('{}', 200);
          }
          return http.Response(
            '{"$source":[{"status":"OPEN","rideType":"$rideType",'
            '"arrivalTime":"08:30","departureTime":"16:30",'
            '"location":{"latitude":49.8951,"longitude":-97.1384}}]}',
            200,
          );
        },
      );

      final marker = tester
          .widget<MarkerLayer>(find.byType(MarkerLayer))
          .markers
          .single;
      await tester.tap(find.byWidget(marker.child));
      await settle(tester);

      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(
          of: sheet,
          matching: find.text(isArrival ? 'To campus' : 'From campus'),
        ),
        findsOneWidget,
      );
      final arrivalLabel = find.descendant(
        of: sheet,
        matching: find.text('Arrive at campus by:'),
      );
      final departureLabel = find.descendant(
        of: sheet,
        matching: find.text('Leave campus at:'),
      );
      expect(arrivalLabel, isArrival ? findsOneWidget : findsNothing);
      expect(departureLabel, isArrival ? findsNothing : findsOneWidget);
      expect(find.text('Posted by'), findsNothing);
      expect(find.descendant(of: sheet, matching: find.text('Status:')), findsNothing);
      expect(find.descendant(of: sheet, matching: find.text('OPEN')), findsNothing);
    });
  }

  for (final (kind, source) in [('request', 'requests'), ('offer', 'offers')]) {
    testWidgets('shows the compact $kind schedule and actions', (
      tester,
    ) async {
      await pumpMapPage(
        tester,
        respond: (request) async => request.url.path.endsWith('/$source')
            ? http.Response(
                '{"$source":[{"rideType":"roundTrip","userId":"another-user",'
                '"arrivalTime":"07:15","departureTime":"16:30",'
                '"poster":{"firstName":"Jordan","lastName":"Lee","avatarColor":"#D1C4E9"},'
                '"daysOfWeek":["MONDAY","WEDNESDAY","SATURDAY"],'
                '"description":"Meet by the entrance","passengerNum":3,"askingForDrivers":false,'
                '"location":{"latitude":49.8951,"longitude":-97.1384}}]}',
                200,
              )
            : http.Response('{}', 200),
      );
      final marker = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single;
      await tester.tap(find.byWidget(marker.child));
      await settle(tester);

      expect(find.text('Ride $kind'), findsOneWidget);
      final arrival = find.text('7:15 AM');
      final departure = find.text('4:30 PM');
      expect(arrival, findsOneWidget);
      expect(departure, findsOneWidget);
      expect(find.text('Ride type:'), findsNothing);
      expect(
        tester.getBottomLeft(find.text('Round trip')).dy,
        lessThan(tester.getTopLeft(arrival).dy),
      );
      expect(tester.getTopLeft(arrival).dy, tester.getTopLeft(departure).dy);
      expect(tester.getTopLeft(arrival).dx, lessThan(tester.getTopLeft(departure).dx));
      expect(find.text('Days'), findsOneWidget);
      expect(find.text('Sa'), findsOneWidget);
      expect(find.text('Su'), findsNothing);

      BoxDecoration bubbleDecoration(String label) {
        final bubble = find.ancestor(
          of: find.text(label),
          matching: find.byWidgetPredicate(
            (widget) => widget is Container &&
                widget.decoration is BoxDecoration &&
                (widget.decoration as BoxDecoration).shape == BoxShape.circle,
          ),
        );
        return tester.widget<Container>(bubble.first).decoration! as BoxDecoration;
      }

      expect(bubbleDecoration('M').color, AppColors.primary);
      expect(bubbleDecoration('T').color, Colors.transparent);
      final offerFieldMatcher = kind == 'offer' ? findsOneWidget : findsNothing;
      expect(find.text('Up to 3 passengers'), offerFieldMatcher);
      final sheet = find.byType(BottomSheet);
      expect(
        find.descendant(of: sheet, matching: find.text('Looking for other drivers')),
        findsNothing,
      );
      expect(find.text('Ride notes'), findsOneWidget);
      expect(find.text('Meet by the entrance'), findsOneWidget);
      expect(find.text('Posted by'), findsOneWidget);
      expect(find.text('Jordan Lee'), findsOneWidget);
      final avatar = find.widgetWithText(CircleAvatar, 'JL');
      expect(tester.widget<CircleAvatar>(avatar).backgroundColor, const Color(0xFFD1C4E9));

      final message = find.widgetWithText(OutlinedButton, 'Message');
      final join = find.widgetWithText(FilledButton, 'Ask to Join Ride');
      expect(tester.widget<OutlinedButton>(message).onPressed, isNotNull);
      expect(tester.widget<FilledButton>(join).onPressed, isNotNull);
      expect(tester.getCenter(message).dy, tester.getCenter(join).dy);
      await tester.tap(join);
      await settle(tester);
      expect(find.text('Ride $kind'), findsOneWidget);
      expect(message.hitTestable(), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);

      await tester.pumpWidget(createTestWidget(sheetWidth: 240));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(arrival).dy, lessThan(tester.getTopLeft(departure).dy));
      expect(message.hitTestable(), findsOneWidget);
      expect(join.hitTestable(), findsOneWidget);
      expect(tester.getCenter(message).dy, lessThan(tester.getCenter(join).dy));
    });
  }

  for (final capacity in [1, null]) {
    testWidgets('shows driver preference with capacity $capacity', (tester) async {
      await pumpMapPage(
        tester,
        respond: (request) async => request.url.path.endsWith('/offers')
            ? http.Response(
                '{"offers":[{"rideType":"departing","askingForDrivers":true,'
                '"passengerNum":$capacity,'
                '"location":{"latitude":49.8951,"longitude":-97.1384}}]}',
                200,
              )
            : http.Response('{}', 200),
      );
      final marker = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single;
      await tester.tap(find.byWidget(marker.child));
      await settle(tester);
      await tester.pumpWidget(createTestWidget(sheetWidth: 240));
      await settle(tester);

      final sheet = find.byType(BottomSheet);
      expect(find.descendant(of: sheet, matching: find.text('From campus')), findsOneWidget);
      expect(find.text('Leave campus at:'), findsNothing);
      expect(find.widgetWithText(Chip, 'Looking for other drivers'), findsOneWidget);
      expect(
        find.widgetWithText(Chip, 'Up to 1 passenger'),
        capacity == null ? findsNothing : findsOneWidget,
      );
      if (capacity != null) {
        expect(
          tester.getTopLeft(find.widgetWithText(Chip, 'Looking for other drivers')).dy,
          greaterThan(tester.getTopLeft(find.widgetWithText(Chip, 'Up to 1 passenger')).dy),
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  for (final mixed in [true, false]) {
    testWidgets('groups nearby rides when mixed is $mixed', (tester) async {
      const requestRide = '{"rideType":"arriving","city":"Winnipeg",'
          '"arrivalTime":"07:15","daysOfWeek":["MONDAY","WEDNESDAY"],'
          '"location":{"latitude":49.8951,"longitude":-97.1384}}';
      await pumpMapPage(
        tester,
        respond: (request) async {
          if (request.url.path.endsWith('/requests')) {
            return http.Response(
              mixed
                  ? '{"requests":[$requestRide]}'
                  : '{"requests":[$requestRide,$requestRide]}',
              200,
            );
          }
          return http.Response(mixed ? '{"offers":[$requestRide]}' : '{}', 200);
        },
      );
      final marker = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single;
      await tester.tap(find.byWidget(marker.child));
      await settle(tester);

      expect(find.text('Rides in this area'), findsOneWidget);
      expect(find.text(mixed ? '1 offer · 1 request' : '0 offers · 2 requests'),
          findsOneWidget);
      expect(find.text(mixed ? 'Ride requests (1)' : 'Ride requests (2)'),
          findsOneWidget);
      expect(find.text('Ride offers (1)'), mixed ? findsOneWidget : findsNothing);
      expect(find.text('Ride offers (0)'), findsNothing);
      expect(find.text('To campus'), findsNWidgets(2));
      expect(find.text('Arrive by 7:15 AM'), findsNWidgets(2));

      final city = find.text('Winnipeg').first;
      final row = find.ancestor(of: city, matching: find.byType(InkWell)).first;
      final bubbles = find.descendant(of: row, matching: find.byType(Wrap));
      final direction = find.descendant(
        of: row,
        matching: find.text('To campus'),
      );
      final time = find.descendant(of: row, matching: find.text('Arrive by 7:15 AM'));
      final chevron = find.descendant(
        of: row,
        matching: find.byIcon(Icons.chevron_right),
      );
      expect(find.descendant(of: bubbles, matching: find.text('M')), findsOneWidget);
      expect(tester.getCenter(bubbles).dy, closeTo(tester.getCenter(row).dy, 0.1));
      expect(tester.getTopLeft(bubbles).dx, greaterThan(tester.getTopRight(city).dx));
      expect(tester.getTopLeft(time).dx, greaterThan(tester.getTopRight(bubbles).dx));
      expect(tester.getTopRight(time).dx, tester.getTopLeft(chevron).dx - 12);
      expect(tester.getTopRight(chevron).dx, tester.getTopRight(row).dx - 12);

      await tester.pumpWidget(createTestWidget(sheetWidth: 320));
      await settle(tester);
      expect(tester.takeException(), isNull);
      expect(tester.getTopLeft(bubbles).dy, greaterThan(tester.getBottomLeft(direction).dy));
      expect(tester.getTopRight(time).dx, tester.getTopLeft(chevron).dx - 12);
      expect(tester.getTopRight(chevron).dx, tester.getTopRight(row).dx - 12);

      expect(find.text('Winnipeg'), findsNWidgets(2));
      expect(find.textContaining(' — Winnipeg'), findsNothing);
      await tester.tap(city);
      await settle(tester);
      expect(find.text('Ride request'), findsOneWidget);
    });
  }

  testWidgets('labels nearby departure and round-trip times', (tester) async {
    const location = '"location":{"latitude":49.8951,"longitude":-97.1384}';
    await pumpMapPage(
      tester,
      respond: (request) async => request.url.path.endsWith('/offers')
          ? http.Response(
              '{"offers":['
              '{"rideType":"roundTrip","arrivalTime":"08:30","departureTime":"16:30",$location},'
              '{"rideType":"departing","departureTime":"17:00",$location},'
              '{"rideType":"arriving",$location}]}',
              200,
            )
          : http.Response('{}', 200),
    );
    final marker = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single;
    await tester.tap(find.byWidget(marker.child));
    await settle(tester);

    final arrival = find.text('Arrive by 8:30 AM');
    final departure = find.text('Leave at 4:30 PM');
    expect(arrival, findsOneWidget);
    expect(departure, findsOneWidget);
    expect(tester.getCenter(arrival).dy, lessThan(tester.getCenter(departure).dy));
    expect(tester.getTopRight(arrival).dx, closeTo(tester.getTopRight(departure).dx, 0.1));
    expect(find.text('Leave at 5:00 PM'), findsOneWidget);
    expect(find.textContaining('Arrive by'), findsOneWidget);
    expect(find.textContaining('Leave at'), findsNWidgets(2));
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

  testWidgets('shows exact owner pins and opens the dashboard target', (
    tester,
  ) async {
    useLargeScreen(tester);
    final queries = <Uri>[];
    await http.runWithClient(
      () async {
        await tester.pumpWidget(
          MaterialApp(
            home: AppShell(
              user: testUser,
              dashboardPage: Builder(
                builder: (context) => ValueListenableBuilder<DashboardRideTarget?>(
                  valueListenable: DashboardRideNavigation.maybeOf(context)!.target,
                  builder: (_, target, _) => Text(
                    '${target?.kind.name} ${target?.listingId}',
                  ),
                ),
              ),
              inboxPage: const SizedBox.shrink(),
              rideRequestPage: const SizedBox.shrink(),
              rideOfferPage: const SizedBox.shrink(),
              mapPage: const CarpoolMultiSourceMapPage(user: testUser),
              onProfileTap: () {},
            ),
          ),
        );
        await settle(tester);
        await tester.tap(find.byIcon(Icons.map_outlined));
        await settle(tester);
      },
      () => MockClient((request) async {
        if (!request.url.path.startsWith('/api/v1/rides/')) {
          return http.Response('', 404);
        }
        queries.add(request.url);
        if (request.url.path.endsWith('/offers')) return http.Response('{}', 200);
        const location = '"location":{"latitude":49.8951,"longitude":-97.1384}';
        final own = request.url.queryParameters['includeOwn'] == 'true'
            ? ',{"requestId":"mine","userId":"${testUser.email}",'
                '"rideType":"arriving","arrivalTime":"08:30",$location}'
            : '';
        return http.Response('{"requests":[{"requestId":"other",$location}$own]}', 200);
      }),
    );

    List<Marker> markers() =>
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
    final chip = find.widgetWithText(FilterChip, 'Show my posts');
    expect(tester.widget<FilterChip>(chip).selected, isFalse);
    expect(markers(), hasLength(1));
    expect(queries.every((uri) => !uri.queryParameters.containsKey('includeOwn')), isTrue);

    await tester.enterText(find.byType(TextField), 'Winnipeg');
    await tester.tap(chip);
    await settle(tester);
    expect(markers(), hasLength(2));
    expect(queries.last.queryParameters, {'city': 'Winnipeg', 'includeOwn': 'true'});
    final own = markers().last;
    expect(own.width, 40);
    expect(own.height, 40);
    expect(own.point.latitude, 49.8951);
    expect(own.point.longitude, -97.1384);
    expect(
      find.descendant(
        of: find.byWidget(own.child),
        matching: find.byWidgetPredicate((widget) => widget is Icon && widget.color == Colors.green),
      ),
      findsOneWidget,
    );
    expect(markers().first.point, isNot(own.point));
    final pin = find.byWidget(own.child);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(pin));
    await tester.pump();
    await settle(tester);
    final scale = find.descendant(of: pin, matching: find.byType(AnimatedScale));
    final frame = find.descendant(of: pin, matching: find.byType(AnimatedContainer));
    expect(tester.widget<AnimatedScale>(scale).scale, 1.12);
    final decoration = tester.widget<AnimatedContainer>(frame).decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    expect(decoration.border, isNull);
    await mouse.removePointer();
    await tester.tap(find.byWidget(own.child));
    await settle(tester);
    expect(find.text('Your ride request'), findsOneWidget);
    expect(find.text('Message'), findsNothing);
    expect(find.text('Ask to Join Ride'), findsNothing);
    await tester.tap(find.text('Open in Dashboard'));
    await settle(tester);
    expect(find.text('request mine'), findsOneWidget);
  });

  testWidgets('own cluster padding lets nearby requests receive taps', (
    tester,
  ) async {
    await pumpMapPage(
      tester,
      respond: (request) async {
        if (request.url.path.endsWith('/offers')) return http.Response('{}', 200);
        const ownPoint = '"location":{"latitude":49.8951,"longitude":-97.1384}';
        final own = request.url.queryParameters['includeOwn'] == 'true'
            ? ',{"requestId":"mine-1","userId":"${testUser.email}",$ownPoint}'
                ',{"requestId":"mine-2","userId":"${testUser.email}",$ownPoint}'
            : '';
        return http.Response(
          '{"requests":[{"requestId":"nearby",'
          '"location":{"latitude":49.84,"longitude":-97.1384}}$own]}',
          200,
        );
      },
    );
    await tester.tap(find.text('Show my posts'));
    await settle(tester);

    final markers = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
    expect(markers, hasLength(2));
    final nearby = find.byWidget(markers.first.child);
    final ownCluster = find.byWidget(markers.last.child);
    final nearbyPoint = tester.getCenter(nearby);
    expect(tester.getRect(ownCluster).contains(nearbyPoint), isTrue);
    expect(nearbyPoint.dy, greaterThan(tester.getCenter(ownCluster).dy + 20));

    await tester.tapAt(nearbyPoint);
    await settle(tester);
    expect(find.text('Ride request'), findsOneWidget);
    await tester.tap(find.descendant(
      of: find.byType(BottomSheet),
      matching: find.byIcon(Icons.close),
    ));
    await settle(tester);

    final refreshedMarkers =
        tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers;
    await tester.tap(find.descendant(
      of: find.byWidget(refreshedMarkers.last.child),
      matching: find.text('2'),
    ));
    await settle(tester);
    expect(find.text('Rides in this area'), findsOneWidget);
  });

  group('CarpoolMultiSourceMapPage listing selector', () {
    testWidgets('loads the selected sources immediately and preserves city', (
      tester,
    ) async {
      final calls = <Uri>[];
      await pumpMapPage(
        tester,
        respond: (request) async {
          calls.add(request.url);
          return http.Response('{}', 200);
        },
      );

      List<String> sources() =>
          calls.map((uri) => uri.pathSegments.last).toList();
      expect(sources(), ['requests', 'offers']);
      expect(find.text('Clear Filters'), findsNothing);

      await tester.tap(find.text('Requests'));
      await settle(tester);
      expect(sources().skip(2), ['requests']);
      expect(find.text('Clear Filters'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Winnipeg');
      calls.clear();
      await tester.tap(find.text('Offers'));
      await settle(tester);
      expect(sources(), ['offers']);
      expect(calls.single.queryParameters['city'], 'Winnipeg');

      calls.clear();
      await tester.tap(find.text('All rides'));
      await settle(tester);
      expect(sources(), ['requests', 'offers']);
      expect(calls.map((uri) => uri.queryParameters['city']), [
        'Winnipeg',
        'Winnipeg',
      ]);

      await tester.tap(find.text('Offers'));
      await settle(tester);
      calls.clear();
      await tester.tap(find.text('Clear Filters'));
      await settle(tester);
      expect(sources(), ['requests', 'offers']);
      expect(calls.every((uri) => !uri.queryParameters.containsKey('city')), isTrue);
      expect(find.text('Clear Filters'), findsNothing);
    });

    testWidgets('wraps the driver switch below the selector on narrow screens', (
      tester,
    ) async {
      await pumpMapPage(tester);
      tester.view.physicalSize = const Size(440, 1100);
      await settle(tester);

      final all = find.text('All rides');
      final offers = find.text('Offers');
      final drivers = find.text('Looking for other drivers');
      expect(all.hitTestable(), findsOneWidget);
      expect(offers.hitTestable(), findsOneWidget);
      expect(tester.getCenter(drivers).dy, greaterThan(tester.getCenter(all).dy));
      expect(tester.takeException(), isNull);
    });
  });

  group('CarpoolMultiSourceMapPage map', () {
    testWidgets('shows OpenStreetMap attribution', (WidgetTester tester) async {
      await pumpMapPage(tester);

      expect(find.text('OpenStreetMap contributors'), findsOneWidget);
    });
  });

  testWidgets('filters offers looking for drivers and keeps requests visible', (
    tester,
  ) async {
    const location = '"location":{"latitude":49.8951,"longitude":-97.1384}';
    await pumpMapPage(
      tester,
      respond: (request) async => request.url.path.endsWith('/requests')
          ? http.Response('{"requests":[{"city":"Request city",$location}]}', 200)
          : http.Response(
              '{"offers":['
              '{"city":"Rideshare city","askingForDrivers":true,$location},'
              '{"city":"Other city","askingForDrivers":false,$location}]}',
              200,
            ),
    );

    final filter = find.byType(Switch);
    Future<void> openCluster() async {
      final marker = tester.widget<MarkerLayer>(find.byType(MarkerLayer)).markers.single;
      await tester.tap(find.byWidget(marker.child));
      await settle(tester);
    }

    Future<void> closeCluster() async {
      await tester.tap(find.descendant(
        of: find.byType(BottomSheet),
        matching: find.byIcon(Icons.close),
      ));
      await settle(tester);
    }

    expect(tester.widget<Switch>(filter).value, isFalse);
    await openCluster();
    expect(find.text('2 offers · 1 request'), findsOneWidget);
    expect(find.text('Other city'), findsOneWidget);
    await closeCluster();

    await tester.tap(find.text('Looking for other drivers'));
    await settle(tester);
    expect(tester.widget<Switch>(filter).value, isTrue);
    await openCluster();
    expect(find.text('1 offer · 1 request'), findsOneWidget);
    expect(find.text('Rideshare city'), findsOneWidget);
    expect(find.text('Request city'), findsOneWidget);
    expect(find.text('Other city'), findsNothing);
    await closeCluster();

    await tester.tap(find.text('Clear Filters'));
    await settle(tester);
    expect(tester.widget<Switch>(filter).value, isFalse);
    await openCluster();
    expect(find.text('2 offers · 1 request'), findsOneWidget);
    await closeCluster();

    await tester.tap(filter);
    await settle(tester);
    await tester.tap(find.text('Offers'));
    await settle(tester);
    expect(tester.widget<Switch>(filter).value, isTrue);
    await tester.tap(find.text('All rides'));
    await settle(tester);
    expect(tester.widget<Switch>(filter).value, isTrue);
    await tester.tap(find.text('Requests'));
    await settle(tester);
    expect(filter, findsNothing);
    await tester.tap(find.text('Offers'));
    await settle(tester);
    expect(tester.widget<Switch>(filter).value, isFalse);
  });

  group('CarpoolMultiSourceMapPage error dialog', () {
    testWidgets('a filter change shows sign-in on the first unauthorized response', (
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
          await tester.enterText(find.byType(TextField), 'Winnipeg');
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

    testWidgets('an empty offers view shows no error', (
      WidgetTester tester,
    ) async {
      await pumpMapPage(tester);

      await tester.tap(find.text('Offers'));
      await settle(tester);

      expect(find.textContaining('Couldn’t load'), findsNothing);
      expect(find.text('No rides match the selected filters.'), findsOneWidget);
    });
  });
}
