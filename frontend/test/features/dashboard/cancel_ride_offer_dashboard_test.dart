import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/features/dashboard/dashboard_service.dart';
import 'package:gobison/features/dashboard/presentation/dashboard_page.dart';
import 'package:gobison/features/ride_offer/ride_offer_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

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
    final cancel = find.text('Cancel offer');
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Keep ride'));
    await tester.pumpAndSettle();
    expect(confirms, [null]);
    expect(cancelled, isFalse);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yes, cancel'));
    await tester.pumpAndSettle();
    expect(confirms, [null, null, 'true']);
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
    expect(find.text('Cancel offer'), findsNothing);
  });
}
