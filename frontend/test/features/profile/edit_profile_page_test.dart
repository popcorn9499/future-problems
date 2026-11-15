import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/features/profile/presentation/edit_profile_page.dart';

void main() {
  late User testUser;
  late UserProfile testProfile;

  setUp(() {
    testUser = User(
      id: '123',
      firstName: 'Rebekah',
      lastName: 'Soneye',
      email: 'rebekah@example.com',
    );

    testProfile = UserProfile(
      userId: '123',
      firstName: 'Rebekah',
      lastName: 'Soneye',
      age: 22,
      pronouns: 'She/her',
      description: 'I enjoy meeting new people.',
    );
  });

  Widget createTestWidget({
    User? user,
    UserProfile? profile,
    Future<void> Function(UserProfile profile)? onSave,
  }) {
    return MaterialApp(
      home: EditProfilePage(
        user: user ?? testUser,
        profile: profile ?? testProfile,
        onSave: onSave,
      ),
    );
  }

  void setUpTestViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1000, 1200);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('displays the edit profile page and form fields', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Make it yours'), findsOneWidget);
    expect(find.text('Public Profile'), findsOneWidget);
    expect(find.text('First Name'), findsOneWidget);
    expect(find.text('Last Name'), findsOneWidget);
    expect(find.text('Age'), findsOneWidget);
    expect(find.text('She/her'), findsOneWidget);
    expect(find.text('About Me'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save Changes'), findsOneWidget);
  });

  testWidgets('initializes fields with existing profile information', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    expect(find.widgetWithText(TextFormField, 'Rebekah'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Soneye'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, '22'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'She/her'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'I enjoy meeting new people.'),
      findsOneWidget,
    );
  });

  testWidgets('shows optional fields as empty when profile values are null', (
    WidgetTester tester,
  ) async {
    final profile = UserProfile(
      userId: '123',
      firstName: 'Rebekah',
      lastName: null,
      age: null,
      pronouns: null,
      description: null,
    );

    await tester.pumpWidget(createTestWidget(profile: profile));

    expect(find.text('Rebekah'), findsOneWidget);

    final pronounsField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Pronouns'),
    );
    expect(pronounsField.controller!.text, isEmpty);

    final ageField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'Age'),
    );
    expect(ageField.controller!.text, isEmpty);

    final bioField = tester.widget<TextFormField>(
      find.widgetWithText(TextFormField, 'About Me'),
    );
    expect(bioField.controller!.text, isEmpty);
  });

  testWidgets('shows validation error when first name is empty', (
    WidgetTester tester,
  ) async {
    setUpTestViewport(tester);
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First Name'),
      '',
    );

    final saveButton = find.text('Save Changes');

    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Please enter your first name'), findsOneWidget);
  });

  testWidgets('shows validation error when age is below 18', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '17');

    final saveButton = find.text('Save Changes');

    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter an age between 18 and 100'), findsOneWidget);
  });

  testWidgets('shows validation error when age is above 100', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '101');

    final saveButton = find.text('Save Changes');

    await tester.ensureVisible(saveButton);
    await tester.pumpAndSettle();

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text('Enter an age between 18 and 100'), findsOneWidget);
  });
  testWidgets('allows age to be empty because it is optional', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());

    await tester.enterText(find.widgetWithText(TextFormField, 'Age'), '');

    await tester.ensureVisible(find.text('Save Changes'));
    await tester.tap(find.text('Save Changes'));
    await tester.pump();

    expect(find.text('Enter an age between 18 and 100'), findsNothing);
    expect(find.text('Please enter your first name'), findsNothing);
  });

  testWidgets('cancel returns to previous page when there are no changes', (
    WidgetTester tester,
  ) async {
    setUpTestViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        EditProfilePage(user: testUser, profile: testProfile),
                  ),
                );
              },
              child: const Text('Open Edit Profile'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Edit Profile'));
    await tester.pumpAndSettle();

    final cancelButton = find.text('Cancel');
    await tester.ensureVisible(cancelButton);
    await tester.pumpAndSettle();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Open Edit Profile'), findsOneWidget);
    expect(find.text('Edit Profile'), findsNothing);
  });

 
 testWidgets('cancel prompts before discarding unsaved changes', (
    WidgetTester tester,
  ) async {
    setUpTestViewport(tester);

    await tester.pumpWidget(createTestWidget());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First Name'),
      'Changed Name',
    );

    final cancelButton = find.text('Cancel');
    await tester.ensureVisible(cancelButton);
    await tester.pumpAndSettle();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(find.text('Discard changes?'), findsOneWidget);
    expect(
      find.text('Your unsaved profile changes will be lost.'),
      findsOneWidget,
    );
    expect(find.text('Keep Editing'), findsOneWidget);
    expect(find.text('Discard'), findsOneWidget);
  });


  testWidgets('keep editing closes the discard dialog without leaving page', (
    WidgetTester tester,
  ) async {
    setUpTestViewport(tester);

    await tester.pumpWidget(createTestWidget());

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First Name'), 'Changed Name',);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();

    expect(find.text('Edit Profile'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Changed Name'), findsOneWidget);
  });

  testWidgets('discard closes the page after confirmation', (
    WidgetTester tester,
  ) async {
    setUpTestViewport(tester);
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        EditProfilePage(user: testUser, profile: testProfile),
                  ),
                );
              },
              child: const Text('Open Edit Profile'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Edit Profile'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'First Name'),
      'Changed Name',
    );

    final cancelButton = find.text('Cancel');
    await tester.ensureVisible(cancelButton);
    await tester.pumpAndSettle();
    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();

    expect(find.text('Open Edit Profile'), findsOneWidget);
    expect(find.text('Edit Profile'), findsNothing);
  });

 testWidgets('displays avatar colour options and allows selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Avatar Color'), findsOneWidget);
    expect(find.byTooltip('Pastel Pink'), findsOneWidget);
    expect(find.byTooltip('Default'), findsOneWidget);

    final pastelPinkFinder = find.byTooltip('Pastel Pink');

    await tester.ensureVisible(pastelPinkFinder);
    await tester.pumpAndSettle();

    await tester.tap(pastelPinkFinder);
    await tester.pumpAndSettle();

    final selectedSwatch = find.descendant(
      of: pastelPinkFinder,
      matching: find.byIcon(Icons.check),
    );

    expect(selectedSwatch, findsOneWidget);
  });
}
