import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiServiceMock {
  // Toggle this to false when your Spring Boot backend is running
  static const bool useMock = true;
  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  // --- LOGIN MOCK ---
  static Future<http.Response> login(String email, String password) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));

      // Simulate a successful login (200 OK)
      if (email == "bauerl1@myumanitoba.ca") {
        final responseBody = {
          "accessToken": "mock-jwt-token",
          "tokenType": "Bearer",
          "expiresIn": 3600,
          "user": {
            "userId": "usr_123",
            "firstName": "Leon",
            "lastName": "Bauer",
            "email": email,
            "verified": false,
          },
        };
        // Return a real http.Response object with status 200
        return http.Response(jsonEncode(responseBody), 200);
      } else {
        // Simulate a failed login (401 Unauthorized)
        return http.Response(
          jsonEncode({"message": "Invalid credentials"}),
          401,
        );
      }
    } else {
      // Real network call
      return await http.post(Uri());
    }
  }

  // --- EMAIL VERIFICATION MOCK ---
  static Future<http.Response> verifyEmail(String token, String code) async {
    if (useMock) {
      await Future.delayed(const Duration(seconds: 1));
      //final String responseBody = jsonEncode({'code': code});
      if (code == "333334" && token == "mock-jwt-token") {
        return http.Response(
          jsonEncode({'universityVerified': true, 'code': code}),
          200,
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
      } else {
        // Simulate a 422 Unprocessable Entity error for wrong codes
        throw Exception('422: The verification code is incorrect.');
      }
    } else {
      // Real backend call
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'code': code}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      } else {
        throw Exception('${response.statusCode}: Verification failed');
      }
    }
  }
}
