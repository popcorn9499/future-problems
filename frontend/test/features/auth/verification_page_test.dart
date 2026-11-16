import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/auth/presentation/verification_page.dart';
import 'package:gobison/core/models/user.dart';
import 'package:gobison/core/models/user_profile.dart';
import 'package:gobison/core/widgets/go_bison_logo.dart';

void main() {
  group('VerificationPage UI Tests', () {
    late User testUser;
    late UserProfile testUserProfile;

    setUp(() {
      testUser = User(
        id: '123',
        firstName: 'Rebekah',
        lastName: 'Soneye',
        email: 'rebekah123@myumanitoba.ca',
      );
      testUserProfile = UserProfile(
        userId: '123',
        firstName: 'Rebekah',
        lastName: 'Soneye',
        age: 22,
        pronouns: "She/her",
        description: "I love driving.",
      );
    });

    Widget createVerificationWidget() {
      return MaterialApp(
        home: VerificationPage(
          email: 'rebekah123@myumanitoba.ca',
          user: testUser,
          userProfile: testUserProfile,
        ),
      );
    }

    testWidgets('renders all core UI elements and 6 digit text fields', (
      tester,
    ) async {
      await tester.pumpWidget(createVerificationWidget());

      // Verify header and branding elements
      expect(find.byType(GoBisonLogo), findsOneWidget);
      expect(find.text('Account Verification'), findsOneWidget);
      expect(find.textContaining('rebekah123@myumanitoba.ca'), findsOneWidget);
      expect(find.text('GoBison • Ride with the herd.'), findsOneWidget);

      // Verify exactly 6 text fields are rendered for the code
      expect(find.byType(TextField), findsNWidgets(6));
    });

    testWidgets('shifts focus to the next field when a digit is entered', (
      tester,
    ) async {
      await tester.pumpWidget(createVerificationWidget());

      final textFields = find.byType(TextField);

      // Enter a digit into the first box
      await tester.enterText(textFields.at(0), '4');

      // Check that focus moved to the second text field
      final secondTextField = tester.widget<TextField>(textFields.at(1));
      expect(secondTextField.focusNode?.hasFocus, isTrue);
    });

    testWidgets('does not show error message text widget initially', (
      tester,
    ) async {
      await tester.pumpWidget(createVerificationWidget());

      // Error style text widget should not be present when errorMessage is null
      expect(
        find.byWidgetPredicate(
          (widget) => widget is Text && widget.style?.color == Colors.red,
        ),
        findsNothing,
      );
    });
  });
}
