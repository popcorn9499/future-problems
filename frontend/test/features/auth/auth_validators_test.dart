import 'package:flutter_test/flutter_test.dart';
import 'package:gobison/features/auth/auth_validators.dart';

void main() {
  group('validateRequired', () {
    test('returns an error when the value is null', () {
      expect(AuthValidators.validateRequired(null), 'This field is required');
    });

    test('returns an error when the value is empty', () {
      expect(AuthValidators.validateRequired(''), 'This field is required');
    });

    test('returns an error when the value contains only whitespace', () {
      expect(AuthValidators.validateRequired('   '), 'This field is required');
    });

    test('returns null when the value is provided', () {
      expect(AuthValidators.validateRequired('Rebekah'), isNull);
    });
  });

  group('validateEmail', () {
    test('returns an error when the value is null', () {
      expect(AuthValidators.validateEmail(null), 'Please enter your UMNetId');
    });

    test('returns an error when the value is empty', () {
      expect(AuthValidators.validateEmail(''), 'Please enter your UMNetId');
    });

    test('returns an error when the value contains only whitespace', () {
      expect(AuthValidators.validateEmail('   '), 'Please enter your UMNetId');
    });

    test('rejects a value containing @', () {
      expect(
        AuthValidators.validateEmail('rebekah@myumanitoba.ca'),
        'Enter the UMNetId part of your email only, without @ or a domain',
      );
    });

    test('accepts a UMNetID without @ or a domain', () {
      expect(AuthValidators.validateEmail('rebekah123'), isNull);
    });

    test('accepts a UMNetID with surrounding whitespace', () {
      expect(AuthValidators.validateEmail('  rebekah123  '), isNull);
    });
  });

  group('validatePassword', () {
    test('returns an error when the value is null', () {
      expect(AuthValidators.validatePassword(null), 'Please enter a password');
    });

    test('returns an error when the value is empty', () {
      expect(AuthValidators.validatePassword(''), 'Please enter a password');
    });

    test('rejects a password shorter than 8 characters', () {
      expect(
        AuthValidators.validatePassword('Pass123'),
        'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
      );
    });

    test('rejects a password without an uppercase letter', () {
      expect(
        AuthValidators.validatePassword('password123'),
        'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
      );
    });

    test('rejects a password without a lowercase letter', () {
      expect(
        AuthValidators.validatePassword('PASSWORD123'),
        'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
      );
    });

    test('rejects a password without a number', () {
      expect(
        AuthValidators.validatePassword('PasswordABC'),
        'Your password must be at least 8 characters and include an uppercase letter, a lowercase letter and a number.',
      );
    });

    test('accepts a password meeting all requirements', () {
      expect(AuthValidators.validatePassword('Password123'), isNull);
    });
  });
}
