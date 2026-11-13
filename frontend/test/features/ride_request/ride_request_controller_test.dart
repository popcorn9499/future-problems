import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/ride_request.dart';
import 'package:gobison/features/ride_request/ride_request_controller.dart';
import 'package:gobison/features/ride_request/ride_request_service.dart';

class FakeRideRequestService extends RideRequestService {
  FakeRideRequestService()
    : super(
        client: MockClient((_) async {
          return http.Response('{}', 200);
        }),
      );

  Future<Map<String, dynamic>> Function({
    required String userId,
    required String rideType,
    required String city,
    required String streetAddress,
    required String? arrivalTime,
    required String? departureTime,
    required List<String> daysOfWeek,
    String? description,
  })? onCreateRideRequest;

  @override
  Future<Map<String, dynamic>> createRideRequest({
    required String userId,
    required String rideType,
    required String city,
    required String streetAddress,
    required String? arrivalTime,
    required String? departureTime,
    required List<String> daysOfWeek,
    String? description,
  }) {
    return onCreateRideRequest!(
      userId: userId,
      rideType: rideType,
      city: city,
      streetAddress: streetAddress,
      arrivalTime: arrivalTime,
      departureTime: departureTime,
      daysOfWeek: daysOfWeek,
      description: description,
    );
  }
}

void main() {
  group('RideRequestController', () {
    late FakeRideRequestService rideRequestService;
    late RideRequestController controller;

    final rideRequestJson = {
      'id': 'request123',
      'rideType': 'arriving',
      'userId': '123',
      'city': 'Winnipeg',
      'streetAddress': '123 Main Street',
      'arrivalTime': '08:30',
      'daysOfWeek': ['Monday', 'Wednesday', 'Friday'],
      'description': 'Morning commute',
    };

    setUp(() {
      rideRequestService = FakeRideRequestService();
      controller = RideRequestController(rideRequestService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with the correct initial state', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.createdRideRequest, isNull);
      expect(controller.updatedRideRequest, isNull);
    });

    test('createRideRequest stores the created ride request after success',
        () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        return rideRequestJson;
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'arriving',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: null,
        daysOfWeek: ['Monday', 'Wednesday', 'Friday'],
        description: 'Morning commute',
      );

      expect(controller.createdRideRequest, isA<RideRequest>());
      expect(controller.createdRideRequest?.userId, '123');
      expect(controller.createdRideRequest?.rideType, 'arriving');
      expect(controller.createdRideRequest?.city, 'Winnipeg');
      expect(controller.createdRideRequest?.streetAddress, '123 Main Street');
      expect(controller.createdRideRequest?.arrivalTime, '08:30');
      expect(controller.createdRideRequest?.departureTime, null);
      expect(
        controller.createdRideRequest?.daysOfWeek,
        ['Monday', 'Wednesday', 'Friday'],
      );
      expect(controller.createdRideRequest?.description, 'Morning commute');
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('createRideRequest passes the correct data to the service',
        () async {
      Map<String, dynamic>? receivedData;

      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        receivedData = {
          'userId': userId,
          'rideType': rideType,
          'city': city,
          'streetAddress': streetAddress,
          'arrivalTime': arrivalTime,
          'departureTime': departureTime,
          'daysOfWeek': daysOfWeek,
          'description': description,
        };

        return rideRequestJson;
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'arriving',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: null,
        daysOfWeek: ['Monday', 'Wednesday', 'Friday'],
        description: 'Morning commute',
      );

      expect(receivedData, {
        'userId': '123',
        'rideType': 'arriving',
        'city': 'Winnipeg',
        'streetAddress': '123 Main Street',
        'arrivalTime': '08:30',
        'departureTime': null,
        'daysOfWeek': ['Monday', 'Wednesday', 'Friday'],
        'description': 'Morning commute',
      });
    });

    test('createRideRequest trims input before sending data', () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        expect(city, 'Winnipeg');
        expect(streetAddress, '123 Main Street');
        expect(description, 'Morning commute');

        return rideRequestJson;
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
        description: ' Morning commute ',
      );

      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('createRideRequest converts blank description to null', () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        expect(description, isNull);

        return rideRequestJson;
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
        description: ' ',
      );

      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('createRideRequest passes null when description is omitted',
        () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        expect(description, isNull);

        return rideRequestJson;
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('arriving request only sends arrival time',
      () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        expect(rideType, 'arriving');
        expect(arrivalTime, '08:30');
        expect(departureTime, isNull);

        return {
          ...rideRequestJson,
          'rideType': 'arriving',
          'arrivalTime': '08:30',
          'departureTime': null,
        };
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'arriving',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: null,
        daysOfWeek: ['Monday'],
      );

      expect(controller.errorMessage, isNull);
      expect(controller.createdRideRequest?.arrivalTime, '08:30');
      expect(controller.createdRideRequest?.departureTime, isNull);
    });

    test('departing request only sends departure time', 
      () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        expect(rideType, 'departing');
        expect(arrivalTime, isNull);
        expect(departureTime, '17:30');

        return {
          ...rideRequestJson,
          'rideType': 'departing',
          'arrivalTime': null,
          'departureTime': '17:30',
        };
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'departing',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: null,
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(controller.errorMessage, isNull);
      expect(controller.createdRideRequest?.arrivalTime, isNull);
      expect(controller.createdRideRequest?.departureTime, '17:30');
    });

    test('round-trip request sends both arrival and departure times', 
      () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        expect(rideType, 'roundTrip');
        expect(arrivalTime, '08:30');
        expect(departureTime, '17:30');

        return {
          ...rideRequestJson,
          'rideType': 'roundTrip',
          'arrivalTime': '08:30',
          'departureTime': '17:30',
        };
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(controller.errorMessage, isNull);
      expect(controller.createdRideRequest?.arrivalTime, '08:30');
      expect(controller.createdRideRequest?.departureTime, '17:30');
    });

    test('clears the previous created ride request before creating another',
        () async {
      var callCount = 0;

      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        callCount++;

        return {
          ...rideRequestJson,
          'id': 'request$callCount',
        };
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(controller.createdRideRequest, isNotNull);

      final completer = Completer<Map<String, dynamic>>();

      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) {
        return completer.future;
      };

      final future = controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '125 Main Street',
        arrivalTime: '07:30',
        departureTime: '19:30',
        daysOfWeek: ['Monday', 'Tuesday'],
      );

      expect(controller.createdRideRequest, isNull);

      completer.complete(rideRequestJson);
      await future;

      expect(controller.createdRideRequest, isNotNull);
    });

    test('displays an error when creation fails with HTTP 400', () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        throw Exception('Request failed (400)');
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(
        controller.errorMessage,
        'Some ride request details are invalid. Please check your entries.',
      );
      expect(controller.isLoading, isFalse);
      expect(controller.createdRideRequest, isNull);
    });

    test('displays an error when the session expires', () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        throw Exception('Request failed (401)');
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(
        controller.errorMessage,
        'Unable to save your ride request. Please try again.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays an error when creation fails with HTTP 500', () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        throw Exception('Request failed (500)');
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(
        controller.errorMessage,
        'Something went wrong. Please try again later.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays a generic error for unknown status codes', () async {
      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        throw Exception('Request failed (503)');
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(
        controller.errorMessage,
        'Unable to save your ride request. Please try again.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('sets loading while ride request creation is in progress',
        () async {
      final completer = Completer<Map<String, dynamic>>();

      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) {
        return completer.future;
      };

      final future = controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(controller.isLoading, isTrue);

      completer.complete(rideRequestJson);

      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('notifies listeners when creation starts and finishes',
        () async {
      var notificationCount = 0;

      controller.addListener(() {
        notificationCount++;
      });

      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) async {
        return rideRequestJson;
      };

      await controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      expect(notificationCount, 2);
    });

    test('ignores a second creation while the first is loading', () async {
      final completer = Completer<Map<String, dynamic>>();
      var serviceCallCount = 0;

      rideRequestService.onCreateRideRequest = ({
        required userId,
        required rideType,
        required city,
        required streetAddress,
        required arrivalTime,
        required departureTime,
        required daysOfWeek,
        description,
      }) {
        serviceCallCount++;
        return completer.future;
      };

      final firstCreation = controller.createRideRequest(
        userId: '123',
        rideType: 'roundTrip',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: '17:30',
        daysOfWeek: ['Monday'],
      );

      await controller.createRideRequest(
        userId: '123',
        rideType: 'arriving',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        departureTime: null,
        daysOfWeek: ['Monday', 'Tuesday'],
      );

      expect(serviceCallCount, 1);

      completer.complete(rideRequestJson);
      await firstCreation;

      expect(controller.isLoading, isFalse);
      expect(controller.createdRideRequest, isNotNull);
    });
  });

  group('extractErrorCode', () {
    test('extracts supported HTTP status codes', () {
      expect(extractErrorCode(Exception('Request failed (400)')), 400);
      expect(extractErrorCode(Exception('Request failed (401)')), 401);
      expect(extractErrorCode(Exception('Request failed (500)')), 500);
    });

    test('returns -1 for an unsupported status code format', () {
      expect(extractErrorCode(Exception('Request failed')), -1);
    });
  });
}
