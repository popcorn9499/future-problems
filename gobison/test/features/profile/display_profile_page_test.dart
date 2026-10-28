import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/features/profile/presentation/display_profile_page.dart';

void main() {
  final user = User(
    id: '123',
    firstName: 'Rebekah',
    lastName: 'Soneye',
    email: 'rebekah123@myumanitoba.ca',
  );

  final profile = UserProfile(
    userId: '123',
    firstName: 'Rebekah',
    lastName: 'Soneye',
    age: 22,
    pronouns: 'She/her',
    description: 'I enjoy building software.',
  );

  Widget createTestWidget({
    User? testUser,
    UserProfile? testProfile,
    String currentUserId = '123',
    VoidCallback? onEdit,
  }) {
    return MaterialApp(
      home: DisplayProfilePage(
        user: testUser ?? user,
        profile: testProfile ?? profile,
        currentUserId: currentUserId,
        onEdit: onEdit,
      ),
    );
  }

  group('DisplayProfilePage', () {
    testWidgets('displays the profile name and details', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Rebekah Soneye'), findsOneWidget);
      expect(find.text('About Me'), findsOneWidget);
      expect(find.text('I enjoy building software.'), findsOneWidget);
      expect(find.text('Age'), findsOneWidget);
      expect(find.text('22'), findsOneWidget);
      expect(find.text('Pronouns'), findsOneWidget);
      expect(find.text('She/her'), findsOneWidget);
    });

    testWidgets('shows Edit Profile for the current user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget());

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('calls onEdit when Edit Profile is tapped', (
      WidgetTester tester,
    ) async {
      var editCalled = false;

      await tester.pumpWidget(
        createTestWidget(
          onEdit: () {
            editCalled = true;
          },
        ),
      );

      await tester.tap(find.text('Edit Profile'));

      expect(editCalled, isTrue);
    });

    testWidgets('hides Edit Profile when viewing another user', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(createTestWidget(currentUserId: '456'));

      expect(find.text('Edit Profile'), findsNothing);
    });

    testWidgets('hides optional details when they are missing', (
      WidgetTester tester,
    ) async {
      final profileWithoutOptionalDetails = UserProfile(
        userId: '123',
        firstName: 'Rebekah',
        lastName: null,
        age: null,
        pronouns: null,
        description: null,
      );

      await tester.pumpWidget(
        createTestWidget(testProfile: profileWithoutOptionalDetails),
      );

      expect(find.text('Rebekah'), findsOneWidget);
      expect(find.text('About Me'), findsNothing);
      expect(find.text('Age'), findsNothing);
      expect(find.text('Pronouns'), findsNothing);
      expect(find.text('Edit Profile'), findsOneWidget);
    });

    testWidgets('hides blank description and pronouns', (
      WidgetTester tester,
    ) async {
      final profileWithBlankDetails = UserProfile(
        userId: '123',
        firstName: 'Rebekah',
        lastName: 'Soneye',
        age: null,
        pronouns: '   ',
        description: '   ',
      );

      await tester.pumpWidget(
        createTestWidget(testProfile: profileWithBlankDetails),
      );

      expect(find.text('About Me'), findsNothing);
      expect(find.text('Pronouns'), findsNothing);
      expect(find.text('Age'), findsNothing);
    });

    testWidgets('displays the first name when last name is missing', (
      WidgetTester tester,
    ) async {
      final profileWithoutLastName = UserProfile(
        userId: '123',
        firstName: 'Rebekah',
        lastName: null,
        age: 22,
        pronouns: 'She/her',
        description: null,
      );

      await tester.pumpWidget(
        createTestWidget(testProfile: profileWithoutLastName),
      );

      expect(find.text('Rebekah'), findsOneWidget);
      expect(find.text('Rebekah Soneye'), findsNothing);
    });
  });
}
