
import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/ride_agreement.dart';
import 'package:gobison/features/dashboard/dashboard_controller.dart';
import 'package:gobison/features/dashboard/dashboard_service.dart';

class FakeDashboardService extends DashboardService {
  FakeDashboardService()
      : super(
          client: MockClient((_) async => http.Response('[]', 200))
        );

  Future<List<Map<String, dynamic>>> Function()? onFetchAgreements;

  @override
  Future<List<Map<String, dynamic>>> fetchAgreements() {
    return onFetchAgreements!();
  }
}

Map<String, dynamic> agreementJson({
  int id = 1,
  String? listingId,
  String? roundTripId,
  String rideType = 'ARRIVAL',
  String? arrivalTime = '07:45:00',
  String? departureTime,
  List<String> days = const ['MONDAY', 'WEDNESDAY'],
  String status = 'OPEN',
  bool createdByCurrentUser = false,
  List<Map<String, dynamic>>? drivers,
  List<Map<String, dynamic>>? passengers,
}) {
  return {
    'id': id,
    'listingId': listingId ?? 'listing-$id',
    'roundTripId': roundTripId,
    'rideType': rideType,
    'origin': 'Steinbach',
    'destination': 'University of Manitoba',
    'arrivalTime': arrivalTime,
    'departureTime': departureTime,
    'daysOfWeek': days,
    'status': status,
    'createdByCurrentUser': createdByCurrentUser,
    'drivers': drivers ??
        [
          {
            'id': 'driver-$id',
            'firstName': 'Dana',
            'lastName': 'Driver',
          },
        ],
    'passengers': passengers ??
        [
          {
            'id': 'passenger-$id',
            'firstName': 'Pat',
            'lastName': 'Passenger',
          },
        ],
  };
}

void main() {
  group('AgreementMember', () {
    test('combines first and last name', () {
      const member = AgreementMember(
        id: 'dana@example.com',
        firstName: 'Dana',
        lastName: 'Driver',
      );

      expect(member.fullName, 'Dana Driver');
      expect(member.initials, 'DD');
    });

    test('handles a missing last name', () {
      const member = AgreementMember(
        id: 'rebekah@example.com',
        firstName: 'Rebekah',
      );

      expect(member.fullName, 'Rebekah');
      expect(member.initials, 'R');
    });

    test('handles a null last name from JSON', () {
      final member = AgreementMember.fromJson({
        'id': 'rebekah@example.com',
        'firstName': 'Rebekah',
        'lastName': null,
      });

      expect(member.fullName, 'Rebekah');
      expect(member.initials, 'R');
    });

    test('handles an empty last name', () {
      const member = AgreementMember(
        id: 'rebekah@example.com',
        firstName: 'Rebekah',
        lastName: '',
      );

      expect(member.fullName, 'Rebekah');
      expect(member.initials, 'R');
    });
  });

  group('RideAgreement', () {
    test('parses a one-way arrival', () {
      final agreement = RideAgreement.fromJson(
        agreementJson(
          rideType: 'ARRIVAL',
          arrivalTime: '07:45:00',
          departureTime: null,
        ),
      );

      expect(agreement.rideType, 'ARRIVAL');
      expect(agreement.arrivalTime, '07:45:00');
      expect(agreement.departureTime, isNull);
      expect(agreement.rideTime, '07:45:00');
      expect(agreement.rideTimeLabel, '7:45 AM');
      expect(agreement.roundTripId, isNull);
    });

    test('parses a one-way departure', () {
      final agreement = RideAgreement.fromJson(
        agreementJson(
          rideType: 'DEPARTURE',
          arrivalTime: null,
          departureTime: '16:30:00',
        ),
      );

      expect(agreement.rideType, 'DEPARTURE');
      expect(agreement.arrivalTime, isNull);
      expect(agreement.departureTime, '16:30:00');
      expect(agreement.rideTime, '16:30:00');
      expect(agreement.rideTimeLabel, '4:30 PM');
    });

    test('parses a round-trip arrival leg', () {
      final agreement = RideAgreement.fromJson(
        agreementJson(
          listingId: 'arrival-listing',
          roundTripId: 'round-trip-123',
          rideType: 'ARRIVAL',
          arrivalTime: '08:00:00',
          departureTime: null,
        ),
      );

      expect(agreement.listingId, 'arrival-listing');
      expect(agreement.roundTripId, 'round-trip-123');
      expect(agreement.rideType, 'ARRIVAL');
      expect(agreement.rideTimeLabel, '8:00 AM');
    });

    test('parses a round-trip departure leg', () {
      final agreement = RideAgreement.fromJson(
        agreementJson(
          listingId: 'departure-listing',
          roundTripId: 'round-trip-123',
          rideType: 'DEPARTURE',
          arrivalTime: null,
          departureTime: '16:30:00',
        ),
      );

      expect(agreement.listingId, 'departure-listing');
      expect(agreement.roundTripId, 'round-trip-123');
      expect(agreement.rideType, 'DEPARTURE');
      expect(agreement.rideTimeLabel, '4:30 PM');
    });

    test('parses ownership and status fields', () {
      final agreement = RideAgreement.fromJson(
        agreementJson(
          status: 'FULL',
          createdByCurrentUser: true,
        ),
      );

      expect(agreement.status, 'FULL');
      expect(agreement.createdByCurrentUser, isTrue);
    });

    test('defaults missing optional status and ownership fields', () {
      final json = agreementJson()
        ..remove('status')
        ..remove('createdByCurrentUser');

      final agreement = RideAgreement.fromJson(json);

      expect(agreement.status, 'OPEN');
      expect(agreement.createdByCurrentUser, isFalse);
    });

    test('formats noon and midnight correctly', () {
      final noon = RideAgreement.fromJson(
        agreementJson(
          arrivalTime: '12:00:00',
        ),
      );

      final midnight = RideAgreement.fromJson(
        agreementJson(
          arrivalTime: '00:15:00',
        ),
      );

      expect(noon.rideTimeLabel, '12:00 PM');
      expect(midnight.rideTimeLabel, '12:15 AM');
    });

    test('returns the original value when time cannot be parsed', () {
      final agreement = RideAgreement.fromJson(
        agreementJson(arrivalTime: 'unknown'),
      );

      expect(agreement.rideTimeLabel, 'unknown');
    });

    test('formats weekday abbreviations', () {
      expect(RideAgreement.shortDay('MONDAY'), 'Mon');
      expect(RideAgreement.shortDay('WEDNESDAY'), 'Wed');
      expect(RideAgreement.shortDay('FRIDAY'), 'Fri');
    });
  });

  group('DashboardController', () {
    late FakeDashboardService dashboardService;
    late DashboardController controller;

    setUp(() {
      dashboardService = FakeDashboardService();
      controller = DashboardController(dashboardService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts idle with no data and no error', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.agreements, isEmpty);
    });

    test('loadAgreements stores agreements after success', () async {
      dashboardService.onFetchAgreements = () async => [
            agreementJson(id: 1),
            agreementJson(id: 2),
          ];

      await controller.loadAgreements();

      expect(controller.agreements.map((a) => a.id), ['1', '2']);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('loads both legs of a round trip', () async {
      dashboardService.onFetchAgreements = () async => [
            agreementJson(
              id: 1,
              listingId: 'arrival-listing',
              roundTripId: 'round-trip-123',
              rideType: 'ARRIVAL',
              arrivalTime: '08:00:00',
              departureTime: null,
            ),
            agreementJson(
              id: 1,
              listingId: 'departure-listing',
              roundTripId: 'round-trip-123',
              rideType: 'DEPARTURE',
              arrivalTime: null,
              departureTime: '16:30:00',
            ),
          ];

      await controller.loadAgreements();

      expect(controller.agreements, hasLength(2));
      expect(
        controller.agreements.map((a) => a.roundTripId).toSet(),
        {'round-trip-123'},
      );
      expect(
        controller.agreements.map((a) => a.rideType).toList(),
        ['ARRIVAL', 'DEPARTURE'],
      );
      expect(
        controller.agreements.map((a) => a.rideTimeLabel).toList(),
        ['8:00 AM', '4:30 PM'],
      );
    });

    test('preserves createdByCurrentUser for each agreement', () async {
      dashboardService.onFetchAgreements = () async => [
            agreementJson(id: 1, createdByCurrentUser: true),
            agreementJson(id: 2, createdByCurrentUser: false),
          ];

      await controller.loadAgreements();

      expect(
        controller.agreements.map((a) => a.createdByCurrentUser).toList(),
        [true, false],
      );
    });

    test('an empty response is a success, not an error', () async {
      dashboardService.onFetchAgreements = () async => [];

      await controller.loadAgreements();

      expect(controller.agreements, isEmpty);
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('sets loading while agreements are being fetched', () async {
      final completer =
          Completer<List<Map<String, dynamic>>>();

      dashboardService.onFetchAgreements = () => completer.future;

      final future = controller.loadAgreements();

      expect(controller.isLoading, isTrue);

      completer.complete([agreementJson()]);
      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.agreements, hasLength(1));
    });

    test('notifies listeners when loading starts and finishes', () async {
      final loadingStates = <bool>[];

      controller.addListener(
        () => loadingStates.add(controller.isLoading),
      );

      dashboardService.onFetchAgreements = () async => [
            agreementJson(),
          ];

      await controller.loadAgreements();

      expect(loadingStates, [true, false]);
    });

    const expectedMessages = {
      401: 'Your session has expired. Please log in again.',
      429: 'Too many requests. Please try again in a moment.',
      500: "It's not you, it's us. Please try again later.",
    };

    expectedMessages.forEach((status, message) {
      test('displays the correct message for HTTP $status', () async {
        dashboardService.onFetchAgreements = () async {
          throw Exception(
            'Loading ride agreements failed ($status): ',
          );
        };

        await controller.loadAgreements();

        expect(controller.errorMessage, message);
        expect(controller.agreements, isEmpty);
        expect(controller.isLoading, isFalse);
      });
    });

    test('displays a generic message for other failures', () async {
      dashboardService.onFetchAgreements = () async {
        throw Exception('offline');
      };

      await controller.loadAgreements();

      expect(
        controller.errorMessage,
        'Unable to load your rides. Please try again later.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays a generic message for malformed agreements', () async {
      dashboardService.onFetchAgreements = () async => [
            {'unexpected': true},
          ];

      await controller.loadAgreements();

      expect(
        controller.errorMessage,
        'Unable to load your rides. Please try again later.',
      );
      expect(controller.agreements, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('clears an earlier error when a retry succeeds', () async {
      dashboardService.onFetchAgreements = () async {
        throw Exception(
          'Loading ride agreements failed (500): ',
        );
      };

      await controller.loadAgreements();
      expect(controller.errorMessage, isNotNull);

      dashboardService.onFetchAgreements = () async => [
            agreementJson(),
          ];

      await controller.loadAgreements();

      expect(controller.errorMessage, isNull);
      expect(controller.agreements, hasLength(1));
    });

    test('keeps previously loaded agreements when refresh fails', () async {
      dashboardService.onFetchAgreements = () async => [
            agreementJson(),
          ];

      await controller.loadAgreements();

      dashboardService.onFetchAgreements = () async {
        throw Exception(
          'Loading ride agreements failed (500): ',
        );
      };

      await controller.loadAgreements();

      expect(controller.agreements, hasLength(1));
      expect(controller.errorMessage, isNotNull);
    });
  });

  group('DashboardController with the real service', () {
    DashboardController controllerFor(
      http.Response Function() respond,
    ) {
      final controller = DashboardController(
        DashboardService(
          client: MockClient((request) async => respond())
        ),
      );

      addTearDown(controller.dispose);
      return controller;
    }

    test('an HTTP 401 response becomes the session-expired message',
        () async {
      final controller = controllerFor(
        () => http.Response('', 401),
      );

      await controller.loadAgreements();

      expect(
        controller.errorMessage,
        'Your session has expired. Please log in again.',
      );
    });

    test('a 200 response is parsed into the current models', () async {
      final controller = controllerFor(
        () => http.Response(
          jsonEncode([
            agreementJson(
              id: 7,
              createdByCurrentUser: true,
            ),
          ]),
          200,
        ),
      );

      await controller.loadAgreements();

      final agreement = controller.agreements.single;

      expect(agreement.id, '7');
      expect(agreement.listingId, 'listing-7');
      expect(agreement.rideType, 'ARRIVAL');
      expect(agreement.createdByCurrentUser, isTrue);
      expect(agreement.drivers.single.fullName, 'Dana Driver');
      expect(agreement.passengers.single.fullName, 'Pat Passenger');
      expect(controller.errorMessage, isNull);
    });

    test('a 200 response parses a member without a last name',
        () async {
      final json = agreementJson(
        drivers: [
          {
            'id': 'rebekah@example.com',
            'firstName': 'Rebekah',
            'lastName': null,
          },
        ],
        passengers: [],
      );

      final controller = controllerFor(
        () => http.Response(jsonEncode([json]), 200),
      );

      await controller.loadAgreements();

      expect(
        controller.agreements.single.drivers.single.fullName,
        'Rebekah',
      );
      expect(controller.errorMessage, isNull);
    });
  });

  group('getFilteredAgreements', () {
    late FakeDashboardService dashboardService;
    late DashboardController controller;

    setUp(() async {
      dashboardService = FakeDashboardService()
        ..onFetchAgreements = () async => [
              agreementJson(
                id: 1,
                days: ['MONDAY', 'WEDNESDAY'],
              ),
              agreementJson(
                id: 2,
                days: ['TUESDAY', 'THURSDAY'],
              ),
              agreementJson(
                id: 3,
                days: ['FRIDAY'],
              ),
            ];

      controller = DashboardController(dashboardService);
      await controller.loadAgreements();
    });

    tearDown(() {
      controller.dispose();
    });

    List<String> idsFor(Set<String> days) =>
        controller
            .getFilteredAgreements(days)
            .map((a) => a.id!)
            .toList();

    test('returns everything when no days are selected', () {
      expect(idsFor({}), ['1', '2', '3']);
    });

    test('returns agreements that run on the selected day', () {
      expect(idsFor({'MONDAY'}), ['1']);
      expect(idsFor({'FRIDAY'}), ['3']);
    });

    test('matches if any selected day overlaps, not all', () {
      expect(idsFor({'MONDAY', 'THURSDAY'}), ['1', '2']);
    });

    test('returns empty when no agreements run on selected days', () {
      expect(idsFor({'SUNDAY'}), isEmpty);
    });

    test('does not modify the underlying agreements list', () {
      idsFor({'MONDAY'});

      expect(controller.agreements, hasLength(3));
    });
  });
}
