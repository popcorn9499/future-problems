import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/features/dashboard/dashboard_service.dart';
import 'package:gobison/features/dashboard/presentation/dashboard_page.dart';
import 'package:gobison/features/ride_offer/ride_offer_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';

const user = User(id: 'me', firstName: 'Sam', email: 'sam@example.com', verified: true);

http.Response listing({required bool owner, required bool cancelled}) {
  final driver = owner ? user.email : 'other@example.com';
  final passenger = owner ? 'other@example.com' : user.email;
  return http.Response(jsonEncode([{
    'id': 1, 'listingType': 'OFFER', 'listingId': 'offer-1', 'rideType': 'ARRIVAL',
    'origin': 'Winnipeg', 'destination': 'Campus', 'arrivalTime': '08:30',
    'daysOfWeek': ['MONDAY'], 'createdByCurrentUser': owner,
    'status': cancelled ? 'CANCELLED' : 'OPEN',
    'drivers': [{'id': driver, 'firstName': 'Driver'}],
    'passengers': [{'id': passenger, 'firstName': 'Passenger'}],
  }]), 200);
}

Future<void> openDashboard(WidgetTester tester, MockClient client) async {
  tester.view.physicalSize = const Size(1000, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: DashboardPage(
    user: user,
    dashboardService: DashboardService(client: client),
    rideOfferService: RideOfferService(client: client),
  ))));
  await tester.pumpAndSettle();
}

void main() {
  for (final roundTrip in [false, true]) {
    testWidgets('edits an owned ${roundTrip ? "round-trip" : "one-way"} offer', (tester) async {
      final ids = roundTrip ? ['a', 'b'] : ['a'];
      final tripId = roundTrip ? 'trip' : null;
      final days = roundTrip ? ['MONDAY'] : ['MONDAY', 'SATURDAY'];
      final gets = <String>[];
      final writes = <Map<String, dynamic>>[];
      var dashboardLoads = 0;
      final client = MockClient((request) async {
        final path = request.url.path;
        if (path == '/api/v1/dashboard/agreements') {
          dashboardLoads++;
          return http.Response(jsonEncode([
            for (final id in ids)
              {
                'id': null, 'listingType': 'OFFER', 'listingId': id, 'roundTripId': tripId,
                'rideType': id == 'a' ? 'ARRIVAL' : 'DEPARTURE', 'createdByCurrentUser': true,
                'origin': 'Winnipeg', 'destination': 'Campus', 'status': 'OPEN',
                'arrivalTime': id == 'a' ? '08:30' : null, 'departureTime': id == 'b' ? '17:00' : null,
                'daysOfWeek': [id == 'a' ? 'MONDAY' : 'TUESDAY'],
                'drivers': [{'id': user.email, 'firstName': user.firstName}], 'passengers': [],
              },
          ]), 200);
        }
        final id = request.url.pathSegments.last;
        expect(path, '/api/v1/rides/offers/$id');
        if (request.method == 'GET') {
          gets.add(id);
          return http.Response(jsonEncode({
            'offerId': id, 'roundTripId': tripId, 'rideType': id == 'a' ? 'arriving' : 'departing',
            'status': 'OPEN', 'city': 'Winnipeg', 'streetAddress': '123 Main Street',
            'location': {'latitude': 49.88, 'longitude': -97.12},
            'arrivalTime': id == 'a' ? '08:30' : null, 'departureTime': id == 'b' ? '17:00' : null,
            'daysOfWeek': days, 'description': 'Test ride', 'passengerNum': 3, 'askingForDrivers': true,
          }), 200);
        }
        expect(request.method, 'PATCH');
        expect(id, 'a');
        writes.add(jsonDecode(request.body) as Map<String, dynamic>);
        return http.Response('{}', 200);
      });

      await openDashboard(tester, client);
      if (roundTrip) {
        await tester.tap(find.widgetWithText(FilterChip, 'Monday'));
        await tester.pumpAndSettle();
      }
      final edit = find.text('Edit offer');
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await tester.pumpAndSettle();
      expect(gets, unorderedEquals(ids));
      expect(find.text(roundTrip ? 'Edit both legs' : 'Edit ride offer'), findsOneWidget);
      if (roundTrip) {
        await tester.tap(find.text('Pick on map'));
        await tester.pumpAndSettle();
        final map = tester.widget<FlutterMap>(find.byType(FlutterMap));
        expect(map.options.initialCenter, const LatLng(49.88, -97.12));
        await tester.tapAt(tester.getCenter(find.byType(FlutterMap)));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Use this location'));
        await tester.pumpAndSettle();
        expect(find.text('Pickup label'), findsOneWidget);
      }
      final seats = find.widgetWithText(TextFormField, 'Available seats');
      final drivers = find.widgetWithText(SwitchListTile, 'Looking for a driver');
      expect(tester.widget<TextFormField>(seats).initialValue, '3');
      expect(tester.widget<SwitchListTile>(drivers).value, isTrue);
      expect(find.widgetWithText(FilterChip, 'SAT'), roundTrip ? findsNothing : findsOneWidget);
      expect(find.widgetWithText(FilterChip, 'SUN'), findsNothing);
      final save = find.text('Save changes');
      await tester.ensureVisible(seats);
      await tester.enterText(seats, '10');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(writes, isEmpty);
      expect(save, findsOneWidget);
      await tester.ensureVisible(seats);
      await tester.enterText(seats, '9');
      await tester.ensureVisible(drivers);
      await tester.tap(drivers);
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      expect(writes.single, {
        'city': 'Winnipeg', 'streetAddress': '123 Main Street', 'daysOfWeek': days,
        'arrivalTime': '08:30', 'departureTime': roundTrip ? '17:00' : null,
        'description': 'Test ride', 'passengerNum': 9, 'askingForDrivers': false,
        if (roundTrip) 'location': {
          'latitude': closeTo(49.88, 0.001),
          'longitude': closeTo(-97.12, 0.001),
        },
      });
      expect(dashboardLoads, 2);
      expect(save, findsNothing);
    });
  }

  testWidgets('owner can keep a joined offer or confirm cancellation', (tester) async {
    var cancelled = false;
    var loads = 0;
    final confirms = <String?>[];
    final client = MockClient((request) async {
      if (request.method == 'GET') {
        expect(request.url.path, '/api/v1/dashboard/agreements');
        loads++;
        return listing(owner: true, cancelled: cancelled);
      }
      expect(request.method, 'DELETE');
      expect(request.url.path, '/api/v1/rides/offers/offer-1');
      confirms.add(request.url.queryParameters['confirmParticipants']);
      if (confirms.last == 'true') {
        cancelled = true;
        return http.Response('', 204);
      }
      return http.Response('{"code":"CONFIRMATION_REQUIRED"}', 409);
    });

    await openDashboard(tester, client);
    expect(find.text('Edit offer'), findsNothing);
    final cancel = find.text('Cancel offer');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep ride'));
    await tester.pumpAndSettle();
    expect(confirms, isEmpty);
    expect(cancelled, isFalse);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();
    expect(confirms, ['true']);
    expect(loads, 2);
    expect(find.text('Cancelled'), findsOneWidget);
    expect(cancel, findsNothing);
  });

  testWidgets('a joined passenger sees the offer without a cancel button', (tester) async {
    await openDashboard(tester, MockClient((request) async {
      expect(request.method, 'GET');
      return listing(owner: false, cancelled: false);
    }));
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Edit offer'), findsNothing);
    expect(find.text('Cancel offer'), findsNothing);
  });
}
