import 'package:flutter_test/flutter_test.dart';

import 'package:gobison/features/profile/profile_validators.dart';

void main() {
  group('ProfileValidators', () {
    group('validateFirstName', () {
      test('returns an error when the value is null', () {
        expect(
          ProfileValidators.validateFirstName(null),
          'Please enter your first name',
        );
      });

      test('returns an error when the value is empty', () {
        expect(
          ProfileValidators.validateFirstName(''),
          'Please enter your first name',
        );
      });

      test('returns an error when the value contains only whitespace', () {
        expect(
          ProfileValidators.validateFirstName('   '),
          'Please enter your first name',
        );
      });

      test('returns null when a valid first name is provided', () {
        expect(ProfileValidators.validateFirstName('Rebekah'), isNull);
      });

      test(
        'returns null when the first name contains surrounding whitespace',
        () {
          expect(ProfileValidators.validateFirstName(' Rebekah '), isNull);
        },
      );
    });

    group('validateAge', () {
      test('returns null when the value is null', () {
        expect(ProfileValidators.validateAge(null), isNull);
      });

      test('returns null when the value is empty', () {
        expect(ProfileValidators.validateAge(''), isNull);
      });

      test('returns null when the value contains only whitespace', () {
        expect(ProfileValidators.validateAge('   '), isNull);
      });

      test('returns an error when the age is not a number', () {
        expect(
          ProfileValidators.validateAge('abc'),
          'Enter an age between 18 and 100',
        );
      });

      test('returns an error when the age is below 18', () {
        expect(
          ProfileValidators.validateAge('17'),
          'Enter an age between 18 and 100',
        );
      });

      test('returns an error when the age is above 100', () {
        expect(
          ProfileValidators.validateAge('101'),
          'Enter an age between 18 and 100',
        );
      });

      test('accepts the minimum age of 18', () {
        expect(ProfileValidators.validateAge('18'), isNull);
      });

      test('accepts the maximum age of 100', () {
        expect(ProfileValidators.validateAge('100'), isNull);
      });

      test('accepts a valid age within the range', () {
        expect(ProfileValidators.validateAge('22'), isNull);
      });

      test('accepts an age with surrounding whitespace', () {
        expect(ProfileValidators.validateAge(' 22 '), isNull);
      });

      test('rejects a decimal age', () {
        expect(
          ProfileValidators.validateAge('22.5'),
          'Enter an age between 18 and 100',
        );
      });
    });
  });
}
