import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gobison/core/services/session_service.dart';

import '../../core/models/user.dart';

import 'auth_service.dart';
import 'auth_response_handler.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  bool isLoading = false;
  String? errorMessage;
  User? registeredUser;

  Future<void> register({
    required String firstName,
    required String email,
    required String password,
    String lastName = '',
  }) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      registeredUser = null;
      final data = await _authService.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );

      registeredUser = User.fromJson(data);
      final user = User(
        id: registeredUser!.id,
        firstName: registeredUser!.firstName,
        lastName: registeredUser!.lastName,
        email: registeredUser!.email,
        verified: false,
      );
      await SessionService.saveUser(user: user);
    } catch (e) {
      errorMessage = AuthResponseHandler.handleRegistrationError(
        extractErrorCode(e),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({required String email, required String password}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final responseData = await _authService.login(
        email: email,
        password: password,
      );
      final userMap = responseData['user'];
      // Map the JSON keys explicitly to your User model fields
      final user = User(
        id: userMap['userId'], // Maps 'userId' from JSON to 'id' in your User model
        firstName: userMap['firstName'],
        lastName: userMap['lastName'],
        email: userMap['email'],
        verified: userMap['verified'] ?? false,
      );

      await SessionService.saveUser(user: user);
    } catch (e) {
      errorMessage = AuthResponseHandler.handleLoginError(extractErrorCode(e));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> emailVerification({required String code, User? user}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      print("test1");
      final responseData = await _authService.verifyEmail(code: code);
      print(responseData);
      final isVerified = responseData['universityVerified'];
      await SessionService.setVerification(isVerified: isVerified);
    } catch (e) {
      errorMessage = AuthResponseHandler.handleVerificationError(
        extractErrorCode(e),
      );
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

int extractErrorCode(Object e) {
  final message = e.toString();
  if (message.contains('503')) {
    return 503;
  }
  if (message.contains('400')) {
    return 400;
  }
  if (message.contains('401')) {
    return 401;
  }
  if (message.contains('409')) {
    return 409;
  }
  if (message.contains('422')) {
    return 422;
  }
  if (message.contains('429')) {
    return 429;
  }
  if (message.contains('500')) {
    return 500;
  }
  return -1;
}
