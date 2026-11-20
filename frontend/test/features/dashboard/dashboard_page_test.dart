
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/user.dart';
import 'package:gobison/features/ride_request/ride_request_service.dart';
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
) => {
  'id': id,
  'firstName': first,
  'lastName': last,
};

Map<String, dynamic> _agreement({
  int? id = 1,
  String? listingId,
  String? roundTripId,
  String rideType = 'ARRIVAL',
  String origin = 'Morris',
  List<String> days = const ['MONDAY', 'WEDNESDAY'],
  String status = 'OPEN',
  bool createdByCurrentUser = false,
  String? arrivalTime = '07:45:00',
  String? departureTime,
  List<Map<String, dynamic>>? drivers,
  List<Map<String, dynamic>>? passengers,
}) => {
  'id': id,
  'listingId': listingId ??
      (id == null ? 'unjoined-listing' : 'listing-$id'),
  'roundTripId': roundTripId,
  'rideType': rideType,
  'origin': origin,
  'destination': 'University of Manitoba',
  'arrivalTime': arrivalTime,
  'departureTime': departureTime,
  'daysOfWeek': days,
  'status': status,
  'createdByCurrentUser': createdByCurrentUser,
  'drivers': drivers ??
      [
        _member(
          'jankek@myumanitoba.ca',
          'Kamryn',
          'Janke',
        ),
      ],
  'passengers': passengers ??
      [
        _member(
          'coless1@myumanitoba.ca',
          'Sasha',
          'Coles',
        ),
      ],
};

List<Map<String, dynamic>> _twoAgreements() => [
  _agreement(
    id: 1,
    origin: 'Morris',
    days: ['MONDAY', 'WEDNESDAY'],
  ),
  _agreement(
    id: 2,
    origin: 'Osborne Village',
    days: ['TUESDAY', 'THURSDAY'],
  ),
];

// Each unjoined listing needs its own listingId. The page groups tickets by
// listingId, so a shared one would merge them into a fake round-trip group.
List<Map<String, dynamic>> _mixedAgreements() => [
  _agreement(
    id: 1,
    listingId: 'joined-listing',
    origin: 'Morris',
    days: ['MONDAY'],
  ),
  _agreement(
    id: null,
    listingId: 'offer-listing',
    origin: 'Winnipeg',
    days: ['MONDAY'],
    createdByCurrentUser: true,
    drivers: [_member('jankek@myumanitoba.ca', 'Kamryn', 'Janke')],
    passengers: [],
  ),
  _agreement(
    id: null,
    listingId: 'request-listing',
    origin: 'Steinbach',
    days: ['TUESDAY'],
    createdByCurrentUser: true,
    drivers: [],
    passengers: [_member('jankek@myumanitoba.ca', 'Kamryn', 'Janke')],
  ),
];

http.Response _ok(List<Map<String, dynamic>> body) =>
    http.Response(jsonEncode(body), 200);

Future<void> _pumpPage(
  WidgetTester tester,
  MockClient client,
) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DashboardPage(
          user: _currentUser,
          rideRequestService: RideRequestService(client: client),
          dashboardService: DashboardService(
            client: client,
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpWith(
  WidgetTester tester,
  List<Map<String, dynamic>> agreements,
) async {
  await _pumpPage(
    tester,
    MockClient((request) async => _ok(agreements)),
  );
  await tester.pumpAndSettle();
}

Finder _chip(String label) =>
    find.widgetWithText(FilterChip, label);

bool _isSelected(WidgetTester tester, String label) =>
    tester.widget<FilterChip>(_chip(label)).selected;

Future<void> _tapChip(
  WidgetTester tester,
  String label,
) async {
  await tester.tap(_chip(label));
  await tester.pumpAndSettle();
}

Finder _kindChip(String label) =>
    find.widgetWithText(ChoiceChip, label);

bool _isKindSelected(WidgetTester tester, String label) =>
    tester.widget<ChoiceChip>(_kindChip(label)).selected;

Future<void> _tapKind(WidgetTester tester, String label) async {
  await tester.tap(_kindChip(label));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('edits both request legs when the day filter hides the return', (tester) async {
    final loads = <String>[];
    final writes = <Map<String, dynamic>>[];
    var dashboardLoads = 0;
    final client = MockClient((request) async {
      final path = request.url.path;
      if (path == '/api/v1/dashboard/agreements') {
        dashboardLoads++;
        return _ok([
          for (final id in ['a', 'b'])
            {
              ..._agreement(listingId: id, roundTripId: 'trip',
                rideType: id == 'a' ? 'ARRIVAL' : 'DEPARTURE',
                days: [id == 'a' ? 'MONDAY' : 'TUESDAY'], createdByCurrentUser: true,
                drivers: [], passengers: [_member(_currentUser.email, 'Kamryn', 'Janke')]),
              'listingType': 'REQUEST',
            },
        ]);
      }
      if (request.method == 'GET') {
        final id = request.url.pathSegments.last;
        loads.add(id);
        return http.Response(jsonEncode({
          'requestId': id, 'roundTripId': 'trip', 'status': 'OPEN',
          'rideType': id == 'a' ? 'arriving' : 'departing',
          'city': 'Winnipeg', 'streetAddress': '123 Main Street', 'daysOfWeek': ['MONDAY'],
          'arrivalTime': id == 'a' ? '08:30' : null,
          'departureTime': id == 'b' ? '17:00' : null,
        }), 200);
      }
      expect(request.method, 'PATCH');
      expect(path, '/api/v1/rides/requests/a/round-trip');
      writes.add(jsonDecode(request.body) as Map<String, dynamic>);
      return http.Response('[]', 200);
    });

    await _pumpPage(tester, client);
    await tester.pumpAndSettle();
    await _tapChip(tester, 'Monday');
    final edit = find.text('Edit request');
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(loads, unorderedEquals(['a', 'b']));
    expect(find.text('Edit both legs'), findsOneWidget);
    final address = find.widgetWithText(TextFormField, '123 Main Street');
    await tester.enterText(address, '456 Main Street');
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();
    expect(writes.single['streetAddress'], '456 Main Street');
    expect(writes.single['arrivalTime'], '08:30');
    expect(writes.single['departureTime'], '17:00');
    expect(dashboardLoads, 2);
    expect(find.text('Edit both legs'), findsNothing);
  });

  testWidgets('cancels both legs only after confirmation and refreshes the group', (tester) async {
    var cancelled = false;
    final deletes = <Uri>[];
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        return _ok([
          for (final type in ['ARRIVAL', 'DEPARTURE'])
            {
              ..._agreement(listingId: type == 'ARRIVAL' ? 'arrival-id' : 'departure-id', roundTripId: 'round', rideType: type,
                  createdByCurrentUser: true, status: cancelled ? 'CANCELLED' : 'OPEN'),
              'listingType': 'REQUEST',
            },
        ]);
      }
      expect(request.method, 'DELETE');
      deletes.add(request.url);
      expect(request.url.path, '/api/v1/rides/requests/arrival-id');
      if (request.url.queryParameters['confirmParticipants'] == 'true') {
        cancelled = true;
        return http.Response('', 204);
      }
      return http.Response('{"code":"CONFIRMATION_REQUIRED"}', 409);
    });

    await _pumpPage(tester, client);
    await tester.pumpAndSettle();
    final button = find.text('Cancel both legs');
    expect(button, findsOneWidget);
    expect(find.text('Edit request'), findsNothing);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep ride'));
    await tester.pumpAndSettle();
    expect(deletes.single.queryParameters, isEmpty);
    await tester.tap(button);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();
    expect(deletes.map((uri) => uri.queryParameters['confirmParticipants']), [null, null, 'true']);
    expect(button, findsNothing);
    expect(find.text('Ride request cancelled.'), findsOneWidget);
  });

  group('loading, empty and error states', () {
    testWidgets(
      'shows a spinner while loading, then the tickets',
      (tester) async {
        final completer = Completer<http.Response>();

        await _pumpPage(
          tester,
          MockClient((request) => completer.future),
        );

        expect(
          find.byType(CircularProgressIndicator),
          findsOneWidget,
        );

        completer.complete(_ok([_agreement()]));
        await tester.pumpAndSettle();

        expect(
          find.byType(CircularProgressIndicator),
          findsNothing,
        );
        expect(find.text('Morris'), findsOneWidget);
        expect(
          find.text('University of Manitoba'),
          findsOneWidget,
        );
        expect(find.text('7:45 AM'), findsOneWidget);
        expect(find.text('Open'), findsOneWidget);
      },
    );

    testWidgets(
      'shows the empty state without filters when there are no agreements',
      (tester) async {
        await _pumpWith(tester, []);

        expect(find.text('Nothing here yet'), findsOneWidget);
        expect(find.byType(FilterChip), findsNothing);
      },
    );

    testWidgets(
      'shows the error state and recovers when retrying',
      (tester) async {
        var status = 500;

        await _pumpPage(
          tester,
          MockClient(
            (request) async => status == 200
                ? _ok([_agreement()])
                : http.Response('', status),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text('Something went wrong'),
          findsOneWidget,
        );
        expect(
          find.text(
            "It's not you, it's us. Please try again later.",
          ),
          findsOneWidget,
        );

        status = 200;

        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();

        expect(
          find.text('Something went wrong'),
          findsNothing,
        );
        expect(find.text('Morris'), findsOneWidget);
      },
    );

    testWidgets(
      'shows the session-expired message for a 401',
      (tester) async {
        await _pumpPage(
          tester,
          MockClient(
            (request) async => http.Response('', 401),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.text(
            'Your session has expired. Please log in again.',
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('ticket contents', () {
    testWidgets(
      'displays the origin, destination and arrival time',
      (tester) async {
        await _pumpWith(tester, [_agreement()]);

        expect(find.text('Morris'), findsOneWidget);
        expect(
          find.text('University of Manitoba'),
          findsOneWidget,
        );
        expect(find.text('Arrive at campus by'), findsOneWidget);
        expect(find.text('7:45 AM'), findsOneWidget);
      },
    );

    testWidgets(
      'uses singular section labels for one driver and one passenger',
      (tester) async {
        await _pumpWith(tester, [_agreement()]);

        expect(find.text('DRIVER'), findsOneWidget);
        expect(find.text('PASSENGER'), findsOneWidget);
      },
    );

    testWidgets(
      'pluralises DRIVERS when there are several drivers',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            drivers: [
              _member('driver1', 'Ann', 'One'),
              _member('driver2', 'Bob', 'Two'),
            ],
          ),
        ]);

        expect(find.text('DRIVERS'), findsOneWidget);
        expect(find.text('DRIVER'), findsNothing);
      },
    );

    testWidgets(
      'pluralises PASSENGERS when there are several passengers',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            passengers: [
              _member('passenger1', 'Sam', 'One'),
              _member('passenger2', 'Alex', 'Two'),
            ],
          ),
        ]);

        expect(find.text('PASSENGERS'), findsOneWidget);
        expect(find.text('PASSENGER'), findsNothing);
      },
    );

    testWidgets(
      'does not display the passenger section when there are no passengers',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            createdByCurrentUser: true,
            id: null,
            drivers: [
              _member(
                'jankek@myumanitoba.ca',
                'Kamryn',
                'Janke',
              ),
            ],
            passengers: [],
          ),
        ]);

        expect(find.text('DRIVER'), findsOneWidget);
        expect(find.text('PASSENGER'), findsNothing);
      },
    );

    testWidgets(
      'does not display the driver section when there are no drivers',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            createdByCurrentUser: true,
            id: null,
            drivers: [],
            passengers: [
              _member(
                'jankek@myumanitoba.ca',
                'Kamryn',
                'Janke',
              ),
            ],
          ),
        ]);

        expect(find.text('DRIVER'), findsNothing);
        expect(find.text('PASSENGER'), findsOneWidget);
      },
    );
  });

  group('current user marker', () {
    testWidgets(
      'shows a YOU badge only on the current user',
      (tester) async {
        await _pumpWith(tester, [_agreement()]);

        expect(find.text('YOU'), findsOneWidget);
        expect(find.text('Kamryn Janke'), findsOneWidget);
        expect(find.text('Sasha Coles'), findsOneWidget);
      },
    );

  });

  group('ownership labels', () {
    testWidgets(
      'shows CREATED BY YOU for an arrangement created by the current user',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(createdByCurrentUser: true),
        ]);

        expect(find.text('CREATED BY YOU'), findsOneWidget);
        expect(find.text('JOINED'), findsNothing);
      },
    );

    testWidgets(
      'shows JOINED for an arrangement created by another user',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            id: 5,
            createdByCurrentUser: false,
          ),
        ]);

        expect(find.text('JOINED'), findsOneWidget);
        expect(find.text('CREATED BY YOU'), findsNothing);
      },
    );

    testWidgets(
      'shows YOUR RIDE OFFER and WAITING FOR OTHERS for an unjoined offer',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            id: null,
            createdByCurrentUser: true,
            drivers: [
              _member(
                'jankek@myumanitoba.ca',
                'Kamryn',
                'Janke',
              ),
            ],
            passengers: [],
          ),
        ]);

        expect(find.text('YOUR RIDE OFFER'), findsOneWidget);
        expect(
          find.text('WAITING FOR OTHERS'),
          findsOneWidget,
        );
        expect(find.text('CREATED BY YOU'), findsOneWidget);
      },
    );

    testWidgets(
      'shows YOUR RIDE REQUEST and WAITING FOR OTHERS for an unjoined request',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            id: null,
            createdByCurrentUser: true,
            drivers: [],
            passengers: [
              _member(
                'jankek@myumanitoba.ca',
                'Kamryn',
                'Janke',
              ),
            ],
          ),
        ]);

        expect(find.text('YOUR RIDE REQUEST'), findsOneWidget);
        expect(
          find.text('WAITING FOR OTHERS'),
          findsOneWidget,
        );
        expect(find.text('CREATED BY YOU'), findsOneWidget);
      },
    );

    testWidgets(
      'does not show WAITING FOR OTHERS when an arrangement has joiners',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            id: null,
            createdByCurrentUser: true,
            drivers: [
              _member(
                'jankek@myumanitoba.ca',
                'Kamryn',
                'Janke',
              ),
            ],
            passengers: [
              _member(
                'coless1@myumanitoba.ca',
                'Sasha',
                'Coles',
              ),
            ],
          ),
        ]);

        expect(find.text('CREATED BY YOU'), findsOneWidget);
        expect(
          find.text('WAITING FOR OTHERS'),
          findsNothing,
        );
        expect(find.text('RIDE ARRANGEMENT'), findsOneWidget);
      },
    );
  });

  group('ride statuses', () {
    testWidgets(
      'displays Open, Full and Archived status labels',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(id: 1, origin: 'Morris', status: 'OPEN'),
          _agreement(id: 2, origin: 'Winnipeg', status: 'FULL'),
          _agreement(id: 3, origin: 'Steinbach', status: 'ARCHIVED'),
        ]);

        expect(find.text('Open'), findsOneWidget);
        expect(find.text('Full'), findsOneWidget);
        expect(find.text('Archived'), findsOneWidget);
      },
    );
  });

  group('round trips', () {
    testWidgets(
      'groups two legs with the same roundTripId into one round trip',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            id: 10,
            listingId: 'departure-listing',
            roundTripId: 'round-trip-1',
            rideType: 'DEPARTURE',
            origin: 'University of Manitoba',
            arrivalTime: null,
            departureTime: '16:30:00',
          ),
          _agreement(
            id: 10,
            listingId: 'arrival-listing',
            roundTripId: 'round-trip-1',
            rideType: 'ARRIVAL',
            origin: 'Morris',
            arrivalTime: '07:45:00',
            departureTime: null,
          ),
        ]);

        expect(find.text('ROUND TRIP'), findsOneWidget);
        expect(
          find.text('TWO LEGS · ONE ROUND TRIP'),
          findsOneWidget,
        );
        expect(find.text('Arrive at campus by'), findsOneWidget);
        expect(find.text('Leave campus at'), findsOneWidget);
      },
    );

    testWidgets(
      'displays the arrival leg before the departure leg',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            id: 10,
            listingId: 'departure-listing',
            roundTripId: 'round-trip-1',
            rideType: 'DEPARTURE',
            origin: 'University of Manitoba',
            arrivalTime: null,
            departureTime: '16:30:00',
          ),
          _agreement(
            id: 10,
            listingId: 'arrival-listing',
            roundTripId: 'round-trip-1',
            rideType: 'ARRIVAL',
            origin: 'Morris',
            arrivalTime: '07:45:00',
            departureTime: null,
          ),
        ]);

        final arrivalPosition = tester.getTopLeft(
          find.text('Arrive at campus by'),
        );
        final departurePosition = tester.getTopLeft(
          find.text('Leave campus at'),
        );

        expect(
          arrivalPosition.dy,
          lessThan(departurePosition.dy),
        );
      },
    );

    testWidgets(
      'displays the correct time for each leg',
      (tester) async {
        await _pumpWith(tester, [
          _agreement(
            id: 10,
            listingId: 'arrival-listing',
            roundTripId: 'round-trip-1',
            rideType: 'ARRIVAL',
            arrivalTime: '07:45:00',
            departureTime: null,
          ),
          _agreement(
            id: 10,
            listingId: 'departure-listing',
            roundTripId: 'round-trip-1',
            rideType: 'DEPARTURE',
            arrivalTime: null,
            departureTime: '16:30:00',
          ),
        ]);

        expect(find.text('7:45 AM'), findsOneWidget);
        expect(find.text('4:30 PM'), findsOneWidget);
      },
    );
  });

  group('day filter', () {
    testWidgets(
      'shows the filter chips above the tickets',
      (tester) async {
        await _pumpWith(tester, _twoAgreements());

        expect(find.text('FILTER BY DAY'), findsOneWidget);
        expect(find.byType(FilterChip), findsNWidgets(6));

        for (final label in [
          'All',
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
        ]) {
          expect(_chip(label), findsOneWidget, reason: label);
        }
      },
    );

    testWidgets(
      'starts with All selected and shows every ticket',
      (tester) async {
        await _pumpWith(tester, _twoAgreements());

        expect(_isSelected(tester, 'All'), isTrue);
        expect(_isSelected(tester, 'Monday'), isFalse);
        expect(find.text('Morris'), findsOneWidget);
        expect(find.text('Osborne Village'), findsOneWidget);
      },
    );

    testWidgets(
      'tapping a day shows only tickets that run on that day',
      (tester) async {
        await _pumpWith(tester, _twoAgreements());

        await _tapChip(tester, 'Monday');

        expect(_isSelected(tester, 'Monday'), isTrue);
        expect(_isSelected(tester, 'All'), isFalse);
        expect(find.text('Morris'), findsOneWidget);
        expect(find.text('Osborne Village'), findsNothing);
      },
    );

    testWidgets(
      'tapping the same day again removes the filter',
      (tester) async {
        await _pumpWith(tester, _twoAgreements());

        await _tapChip(tester, 'Monday');
        await _tapChip(tester, 'Monday');

        expect(_isSelected(tester, 'All'), isTrue);
        expect(find.text('Morris'), findsOneWidget);
        expect(find.text('Osborne Village'), findsOneWidget);
      },
    );

    testWidgets(
      'selecting several days shows tickets matching any of them',
      (tester) async {
        await _pumpWith(tester, _twoAgreements());

        await _tapChip(tester, 'Monday');
        await _tapChip(tester, 'Tuesday');

        expect(find.text('Morris'), findsOneWidget);
        expect(find.text('Osborne Village'), findsOneWidget);
      },
    );

    testWidgets(
      'All clears the selected days',
      (tester) async {
        await _pumpWith(tester, _twoAgreements());

        await _tapChip(tester, 'Tuesday');
        expect(find.text('Morris'), findsNothing);

        await _tapChip(tester, 'All');

        expect(_isSelected(tester, 'All'), isTrue);
        expect(_isSelected(tester, 'Tuesday'), isFalse);
        expect(find.text('Morris'), findsOneWidget);
        expect(find.text('Osborne Village'), findsOneWidget);
      },
    );

    testWidgets(
      'shows a message when no ticket runs on the selected day',
      (tester) async {
        await _pumpWith(tester, _twoAgreements());

        await _tapChip(tester, 'Friday');

        expect(find.text('No matching rides'), findsOneWidget);
        expect(find.text('Morris'), findsNothing);
        expect(find.text('Osborne Village'), findsNothing);
        expect(find.text('FILTER BY DAY'), findsOneWidget);
      },
    );
  });

  group('ticket kind filter', () {
    testWidgets('shows the four kind chips', (tester) async {
      await _pumpWith(tester, _mixedAgreements());

      expect(find.text('SHOW'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNWidgets(4));

      for (final label in [
        'All',
        'Agreements',
        'Seeking riders',
        'Seeking a driver',
      ]) {
        expect(_kindChip(label), findsOneWidget, reason: label);
      }
    });

    testWidgets('starts with All selected and shows every ticket',
        (tester) async {
      await _pumpWith(tester, _mixedAgreements());

      expect(_isKindSelected(tester, 'All'), isTrue);
      expect(_isKindSelected(tester, 'Agreements'), isFalse);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Winnipeg'), findsOneWidget);
      expect(find.text('Steinbach'), findsOneWidget);
    });

    testWidgets('Agreements shows only tickets someone has joined',
        (tester) async {
      await _pumpWith(tester, _mixedAgreements());

      await _tapKind(tester, 'Agreements');

      expect(_isKindSelected(tester, 'Agreements'), isTrue);
      expect(_isKindSelected(tester, 'All'), isFalse);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Winnipeg'), findsNothing);
      expect(find.text('Steinbach'), findsNothing);
    });

    testWidgets('Seeking riders shows only your unjoined offers',
        (tester) async {
      await _pumpWith(tester, _mixedAgreements());

      await _tapKind(tester, 'Seeking riders');

      expect(find.text('Winnipeg'), findsOneWidget);
      expect(find.text('YOUR RIDE OFFER'), findsOneWidget);
      expect(find.text('Morris'), findsNothing);
      expect(find.text('Steinbach'), findsNothing);
    });

    testWidgets('Seeking a driver shows only your unjoined requests',
        (tester) async {
      await _pumpWith(tester, _mixedAgreements());

      await _tapKind(tester, 'Seeking a driver');

      expect(find.text('Steinbach'), findsOneWidget);
      expect(find.text('YOUR RIDE REQUEST'), findsOneWidget);
      expect(find.text('Morris'), findsNothing);
      expect(find.text('Winnipeg'), findsNothing);
    });

    testWidgets('tapping All again shows every ticket', (tester) async {
      await _pumpWith(tester, _mixedAgreements());

      await _tapKind(tester, 'Agreements');
      await _tapKind(tester, 'All');

      expect(_isKindSelected(tester, 'All'), isTrue);
      expect(find.text('Morris'), findsOneWidget);
      expect(find.text('Winnipeg'), findsOneWidget);
      expect(find.text('Steinbach'), findsOneWidget);
    });

    testWidgets('combines with the day filter', (tester) async {
      await _pumpWith(tester, _mixedAgreements());

      await _tapChip(tester, 'Tuesday');

      // All + Tuesday: only the request runs on Tuesday.
      expect(find.text('Steinbach'), findsOneWidget);
      expect(find.text('Morris'), findsNothing);
      expect(find.text('Winnipeg'), findsNothing);

      await _tapKind(tester, 'Seeking riders');

      // The offer runs on Monday only, so nothing matches.
      expect(find.text('No matching rides'), findsOneWidget);
    });

    testWidgets(
      'shows a message and keeps the filters when the kind has no matches',
      (tester) async {
        await _pumpWith(tester, [_agreement()]);

        await _tapKind(tester, 'Seeking riders');

        expect(find.text('No matching rides'), findsOneWidget);
        expect(find.text('Morris'), findsNothing);
        expect(find.text('SHOW'), findsOneWidget);
        expect(find.byType(ChoiceChip), findsNWidgets(4));
      },
    );

    testWidgets('does not show the kind filter in the empty state',
        (tester) async {
      await _pumpWith(tester, []);

      expect(find.text('Nothing here yet'), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });
}
