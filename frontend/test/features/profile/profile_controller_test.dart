import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/features/profile/profile_controller.dart';
import 'package:gobison/features/profile/profile_service.dart';

class FakeProfileService extends ProfileService {
  FakeProfileService()
    : super(
        client: MockClient((_) async {
          return http.Response('{}', 200);
        }),
      );

  Future<UserProfile> Function({required Map<String, dynamic> changes})?
  onUpdateProfile;

  @override
  Future<UserProfile> updateProfile({required Map<String, dynamic> changes}) {
    return onUpdateProfile!(changes: changes);
  }
}

void main() {
  group('ProfileController', () {
    late FakeProfileService profileService;
    late ProfileController controller;

    final currentProfile = UserProfile(
      userId: '123',
      firstName: 'Rebekah',
      lastName: 'Soneye',
      age: 22,
      gender: 'Female',
      description: 'Hello world',
    );

    setUp(() {
      profileService = FakeProfileService();
      controller = ProfileController(profileService);
    });

    tearDown(() {
      controller.dispose();
    });

    test('starts with the correct initial state', () {
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
      expect(controller.updatedProfile, isNull);
    });

    test('saveProfile stores the updated profile after success', () async {
      final updatedProfile = UserProfile(
        userId: '123',
        firstName: 'Rebecca',
        lastName: 'Soneye',
        age: 22,
        gender: 'Female',
        description: 'Hello world',
      );

      Map<String, dynamic>? receivedChanges;

      profileService.onUpdateProfile = ({required changes}) async {
        receivedChanges = changes;
        return updatedProfile;
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Rebecca',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(controller.updatedProfile, same(updatedProfile));
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
      expect(receivedChanges, {'firstName': 'Rebecca'});
    });

    test('saveProfile trims input before sending changes', () async {
      profileService.onUpdateProfile = ({required changes}) async {
        expect(changes, {
          'firstName': 'Rebekah',
          'lastName': 'Soneye',
          'description': 'Updated description',
        });

        return UserProfile(
          userId: '123',
          firstName: 'Rebekah',
          lastName: 'Soneye',
          age: 22,
          gender: 'Female',
          description: 'Updated description',
        );
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: ' Rebekah ',
        lastName: ' Soneye ',
        age: '22',
        gender: 'Female',
        description: ' Updated description ',
      );

      expect(
        controller.errorMessage,
        'Unable to save your profile. Please try again.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('saveProfile converts blank optional fields to null', () async {
      profileService.onUpdateProfile = ({required changes}) async {
        expect(changes, {'lastName': null, 'age': null, 'description': null});

        return UserProfile(
          userId: '123',
          firstName: 'Rebekah',
          lastName: null,
          age: null,
          gender: 'Female',
          description: null,
        );
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Rebekah',
        lastName: ' ',
        age: ' ',
        gender: 'Female',
        description: ' ',
      );

      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('does not call service when no profile details change', () async {
      var serviceCalled = false;

      profileService.onUpdateProfile = ({required changes}) async {
        serviceCalled = true;
        throw Exception('Service should not be called');
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: ' Rebekah ',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(serviceCalled, isFalse);
      expect(controller.updatedProfile, same(currentProfile));
      expect(controller.errorMessage, isNull);
      expect(controller.isLoading, isFalse);
    });

    test('displays an error when saving fails with HTTP 400', () async {
      profileService.onUpdateProfile = ({required changes}) async {
        throw Exception('Request failed (400)');
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Updated',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(
        controller.errorMessage,
        'Some profile details are invalid. Please check your entries.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays an error when the session expires', () async {
      profileService.onUpdateProfile = ({required changes}) async {
        throw Exception('Request failed (401)');
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Updated',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(
        controller.errorMessage,
        'Unable to save your profile. Please try again.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays an error when saving fails with HTTP 500', () async {
      profileService.onUpdateProfile = ({required changes}) async {
        throw Exception('Request failed (500)');
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Updated',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(
        controller.errorMessage,
        'Something went wrong. Please try again later.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('displays a generic error for unknown status codes', () async {
      profileService.onUpdateProfile = ({required changes}) async {
        throw Exception('Request failed (503)');
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Updated',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(
        controller.errorMessage,
        'Unable to save your profile. Please try again.',
      );
      expect(controller.isLoading, isFalse);
    });

    test('sets loading while profile update is in progress', () async {
      final completer = Completer<UserProfile>();

      profileService.onUpdateProfile = ({required changes}) {
        return completer.future;
      };

      final future = controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Updated',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(controller.isLoading, isTrue);

      completer.complete(
        UserProfile(
          userId: '123',
          firstName: 'Updated',
          lastName: 'Soneye',
          age: 22,
          gender: 'Female',
          description: 'Hello world',
        ),
      );

      await future;

      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('notifies listeners when saving starts and finishes', () async {
      var notificationCount = 0;

      controller.addListener(() {
        notificationCount++;
      });

      profileService.onUpdateProfile = ({required changes}) async {
        return UserProfile(
          userId: '123',
          firstName: 'Updated',
          lastName: 'Soneye',
          age: 22,
          gender: 'Female',
          description: 'Hello world',
        );
      };

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Updated',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(notificationCount, 2);
    });

    test('ignores a second save while the first is loading', () async {
      final completer = Completer<UserProfile>();
      var serviceCallCount = 0;

      profileService.onUpdateProfile = ({required changes}) {
        serviceCallCount++;
        return completer.future;
      };

      final firstSave = controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'First',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      await controller.saveProfile(
        currentProfile: currentProfile,
        firstName: 'Second',
        lastName: 'Soneye',
        age: '22',
        gender: 'Female',
        description: 'Hello world',
      );

      expect(serviceCallCount, 1);

      completer.complete(
        UserProfile(
          userId: '123',
          firstName: 'First',
          lastName: 'Soneye',
          age: 22,
          gender: 'Female',
          description: 'Hello world',
        ),
      );

      await firstSave;

      expect(controller.isLoading, isFalse);
      expect(controller.updatedProfile?.firstName, 'First');
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
