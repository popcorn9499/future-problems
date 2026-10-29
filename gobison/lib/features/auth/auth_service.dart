import 'dart:convert';

//import 'package:gobison/features/auth/api_service_mock.dart';

import 'package:http/http.dart' as http;

import '../../core/network/auth_client.dart';

import '../../core/network/api_config.dart';

class AuthService {
  final http.Client _client;

  AuthService({http.Client? client}) : _client = client ?? createAuthClient();

  Future<Map<String, dynamic>> register({
    required String firstName,
    String lastName = '',
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/register');
    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Registration failed (${response.statusCode}): '
      '${response.body}',
    );
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/login');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Login failed (${response.statusCode}): '
      '${response.body}',
    );
  }

  Future<Map<String, dynamic>?> currentUser() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/me');
    final response = await _client.get(uri, headers: {'Accept': 'application/json'});
    if (response.statusCode == 401) {
      return null;
    }
    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    }
    throw Exception('Session lookup failed (${response.statusCode}): ${response.body}');
  }
  Future<Map<String, dynamic>> verifyEmail({required String code}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/verify-email');

    final response = await _client.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }

    throw Exception(
      'Account verification failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}
