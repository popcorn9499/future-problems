import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/ride_offer.dart';
import 'package:gobison/features/ride_offer/ride_offer_controller.dart';
import 'package:gobison/features/ride_offer/ride_offer_service.dart';

class FakeRideOfferService extends RideOfferService {
  FakeRideOfferService()
      : super(
          client: MockClient((_) async {
            return http.Response('{}', 200);
          }),
        );

  Future<Map<String, dynamic>> Function({
    required String userId,
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required int passengerNum,
    required List<String> daysOfWeek,
    String? description,
    required bool askingForDrivers,
  })? onCreateRideOffer;

  @override
  Future<Map<String, dynamic>> createRideOffer({
    required String userId,
    required String city,
    required String streetAddress,
    required String arrivalTime,
    required int passengerNum,
    required List<String> daysOfWeek,
    String? description,
    required bool askingForDrivers,
  }) {
    return onCreateRideOffer!(
      userId: userId,
      city: city,
      streetAddress: streetAddress,
      arrivalTime: arrivalTime,
      passengerNum: passengerNum,
      daysOfWeek: daysOfWeek,
      description: description,
      askingForDrivers: askingForDrivers,
    );
  }
}

void main() {
  group('RideOfferController', () {
    late FakeRideOfferService rideOfferService;
    late RideOfferController controller;

    final rideOfferJson = {
      'id': 'ride123',
      'userId': '123',
      'city': 'Winnipeg',
      'streetAddress': '123 Main Street',
      'arrivalTime': '08:30',
      'daysOfWeek': ['Monday', 'Wednesday', 'Friday'],
      'passengerNum': 3,
      'description': 'Morning commute',
      'askingForDrivers': false,
    };

    setUp(() {
      rideOfferService = FakeRideOfferService();
      controller = RideOfferController(rideOfferService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with the correct initial state', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.createdRideOffer, isNull);
      expect(controller.updatedRideOffer, isNull);
    });

    test('createRideOffer stores the created ride offer after success',
        () async {
      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday', 'Wednesday', 'Friday'],
        description: 'Morning commute',
        askingForDrivers: false,
      );

      expect(controller.createdRideOffer, isA<RideOffer>());
      expect(controller.createdRideOffer?.userId, '123');
      expect(controller.createdRideOffer?.city, 'Winnipeg');
      expect(controller.createdRideOffer?.streetAddress, '123 Main Street');
      expect(controller.createdRideOffer?.arrivalTime, '08:30');
      expect(controller.createdRideOffer?.passengerNum, 3);
      expect(controller.createdRideOffer?.daysOfWeek, ['Monday', 'Wednesday', 'Friday'],);
      expect(controller.createdRideOffer?.description, 'Morning commute');
      expect(controller.createdRideOffer?.askingForDrivers, false);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('trims city and street address before passing them to the service',
        () async {
      Map<String, dynamic>? receivedData;

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        receivedData = {
          'city': city,
          'streetAddress': streetAddress,
        };

        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: '  Winnipeg  ',
        streetAddress: '  123 Main Street  ',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(receivedData, {
        'city': 'Winnipeg',
        'streetAddress': '123 Main Street',
      });
    });

    test('trims description before passing it to the service',
        () async {
      String? receivedDescription;

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        receivedDescription = description;

        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        description: '  Morning commute  ',
        askingForDrivers: false,
      );

      expect(receivedDescription, 'Morning commute');
    });

    test('converts an empty description to null', () async {
      String? receivedDescription = 'not null';

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        receivedDescription = description;

        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 2,
        daysOfWeek: ['Monday'],
        description: '',
        askingForDrivers: false,
      );

      expect(receivedDescription, isNull);
    });

    test('converts a whitespace-only description to null', () async {
      String? receivedDescription = 'not null';

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        receivedDescription = description;

        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 2,
        daysOfWeek: ['Monday'],
        description: '   ',
        askingForDrivers: false,
      );

      expect(receivedDescription, isNull);
    });

    test('passes null description when description is omitted',
        () async {
      String? receivedDescription = 'not null';

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        receivedDescription = description;

        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 2,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(receivedDescription, isNull);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('passes askingForDrivers to the service', () async {
      bool? receivedValue;

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        required askingForDrivers,
        description,
      }) async {
        receivedValue = askingForDrivers;
        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(receivedValue, isTrue);
    });

    test('clears the previous created ride offer before creating another',
        () async {
      var callCount = 0;

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        callCount++;

        return {
          ...rideOfferJson,
          'id': 'ride$callCount',
        };
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(controller.createdRideOffer, isNotNull);

      final completer = Completer<Map<String, dynamic>>();

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) {
        return completer.future;
      };

      final future = controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '456 Oak Street',
        arrivalTime: '09:00',
        passengerNum: 2,
        daysOfWeek: ['Tuesday'],
        askingForDrivers: true,
      );

      expect(controller.createdRideOffer, isNull);

      completer.complete(rideOfferJson);
      await future;

      expect(controller.createdRideOffer, isNotNull);
    });

    test('displays an error when creation fails with HTTP 400',
        () async {
      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        throw Exception('Ride offer creation failed (400)');
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(
        controller.errorMessage,
        'Some ride offer details are invalid. Please check your entries.',
      );
      expect(controller.isLoading, isFalse);
      expect(controller.createdRideOffer, isNull);
    });

    test('displays an error when the session expires',
        () async {
      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        throw Exception('Ride offer creation failed (401)');
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(
        controller.errorMessage,
        'Your session has expired. Please sign in again.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays an error when creation fails with HTTP 500',
        () async {
      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        throw Exception('Ride offer creation failed (500)');
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(
        controller.errorMessage,
        'Something went wrong. Please try again later.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays a generic error for unknown status codes',
        () async {
      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        throw Exception('Ride offer creation failed (503)');
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(
        controller.errorMessage,
        'Unable to save your ride offer. Please try again.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('sets loading while ride offer creation is in progress',
        () async {
      final completer = Completer<Map<String, dynamic>>();

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) {
        return completer.future;
      };

      final future = controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(controller.isLoading, isTrue);

      completer.complete(rideOfferJson);

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

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required passengerNum,
        required daysOfWeek,
        description,
        required askingForDrivers,
      }) async {
        return rideOfferJson;
      };

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        passengerNum: 3,
        daysOfWeek: ['Monday'],
        askingForDrivers: true,
      );

      expect(notificationCount, 2);
    });

    test('ignores a second creation while the first is loading', () async {
      final completer = Completer<Map<String, dynamic>>();
      var serviceCallCount = 0;

      rideOfferService.onCreateRideOffer = ({
        required userId,
        required city,
        required streetAddress,
        required arrivalTime,
        required daysOfWeek,
        required passengerNum,
        description,
        required askingForDrivers,
      }) {
        serviceCallCount++;
        return completer.future;
      };

      final firstCreation = controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '123 Main Street',
        arrivalTime: '08:30',
        daysOfWeek: ['Monday'],
        passengerNum: 2,
        askingForDrivers: true,
      );

      await controller.createRideOffer(
        userId: '123',
        city: 'Winnipeg',
        streetAddress: '456 Oak Street',
        arrivalTime: '09:00',
        daysOfWeek: ['Tuesday'],
        passengerNum: 3,
        askingForDrivers: false,
      );

      expect(serviceCallCount, 1);

      completer.complete(rideOfferJson);
      await firstCreation;

      expect(controller.isLoading, isFalse);
      expect(controller.createdRideOffer, isNotNull);
    });
  });

  group('extractErrorCode', () {
    test('extracts supported HTTP status codes', () {
      expect(
        extractErrorCode(Exception('Request failed (400)')),
        400,
      );
      expect(
        extractErrorCode(Exception('Request failed (401)')),
        401,
      );
      expect(
        extractErrorCode(Exception('Request failed (500)')),
        500,
      );
    });

    test('returns -1 for an unsupported status code format', () {
      expect(
        extractErrorCode(Exception('Request failed')),
        -1,
      );
    });
  });
}
