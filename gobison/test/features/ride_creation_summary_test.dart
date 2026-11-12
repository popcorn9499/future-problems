import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:gobison/features/ride_offer/ride_offer_controller.dart';
import 'package:gobison/features/ride_offer/ride_offer_service.dart';
import 'package:gobison/features/ride_request/ride_request_controller.dart';
import 'package:gobison/features/ride_request/ride_request_service.dart';

void main() {
  for (final type in ['arriving', 'departing', 'roundTrip']) {
    final arriving = type != 'departing';
    final departing = type != 'arriving';
    final roundTrip = type == 'roundTrip';
    final arrivalTime = arriving ? '08:30' : null;
    final departureTime = departing ? '17:00' : null;
    final arrivalId = arriving ? 'arrival-id' : null;
    final departureId = departing ? 'departure-id' : null;
    final roundTripId = roundTrip ? 'shared-id' : null;
    final oneWayId = roundTrip ? null : arrivalId ?? departureId;
    final summary = {
      'rideType': type,
      'userId': 'ada@myumanitoba.ca',
      'city': 'Winnipeg',
      'streetAddress': '123 Main',
      'arrivalTime': arrivalTime,
      'departureTime': departureTime,
      'arrivalId': arrivalId,
      'departureId': departureId,
      'roundTripId': roundTripId,
      'daysOfWeek': ['MONDAY', 'FRIDAY'],
      'description': null,
      'status': 'OPEN',
    };

    MockClient clientFor(Map<String, dynamic> response) {
      return MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body.containsKey('userId'), isFalse);
        expect(body['rideType'], type);
        expect(body['daysOfWeek'], ['MONDAY', 'FRIDAY']);
        return http.Response(jsonEncode(response), 201);
      });
    }

    test('request parses a $type summary from actual JSON', () async {
      final controller = RideRequestController(
        RideRequestService(
          client: clientFor({...summary, 'requestId': oneWayId}),
        ),
      );
      addTearDown(controller.dispose);

      await controller.createRideRequest(
        userId: 'untrusted-client-id',
        rideType: type,
        city: 'Winnipeg',
        streetAddress: '123 Main',
        arrivalTime: arrivalTime,
        departureTime: departureTime,
        daysOfWeek: ['Monday', 'Friday'],
      );

      expect(controller.errorMessage, isNull);
      final result = controller.createdRideRequest!;
      expect(result.requestId, oneWayId);
      expect(result.arrivalId, arrivalId);
      expect(result.departureId, departureId);
      expect(result.roundTripId, roundTripId);
      expect(result.rideType, type);
      expect(result.arrivalTime, arrivalTime);
      expect(result.departureTime, departureTime);
      expect(result.daysOfWeek, ['MONDAY', 'FRIDAY']);
      expect(result.userId, 'ada@myumanitoba.ca');
      expect(result.status, 'OPEN');
    });

    test('offer parses a $type summary from actual JSON', () async {
      final controller = RideOfferController(
        RideOfferService(
          client: clientFor({
            ...summary,
            'offerId': oneWayId,
            'passengerNum': 3,
            'askingForDrivers': true,
          }),
        ),
      );
      addTearDown(controller.dispose);

      await controller.createRideOffer(
        userId: 'untrusted-client-id',
        rideType: type,
        city: 'Winnipeg',
        streetAddress: '123 Main',
        arrivalTime: arrivalTime,
        departureTime: departureTime,
        daysOfWeek: ['Monday', 'Friday'],
        passengerNum: 3,
        askingForDrivers: true,
      );

      expect(controller.errorMessage, isNull);
      final result = controller.createdRideOffer!;
      expect(result.offerId, oneWayId);
      expect(result.arrivalId, arrivalId);
      expect(result.departureId, departureId);
      expect(result.roundTripId, roundTripId);
      expect(result.rideType, type);
      expect(result.arrivalTime, arrivalTime);
      expect(result.departureTime, departureTime);
      expect(result.daysOfWeek, ['MONDAY', 'FRIDAY']);
      expect(result.userId, 'ada@myumanitoba.ca');
      expect(result.status, 'OPEN');
      expect(result.passengerNum, 3);
      expect(result.askingForDrivers, isTrue);
    });
  }
}
