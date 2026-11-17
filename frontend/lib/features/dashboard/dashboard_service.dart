import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/auth_client.dart';
import '../../core/network/api_config.dart';

class DashboardService {
  final http.Client _client;

  DashboardService({http.Client? client})
    : _client = client ?? createAuthClient();

  /// Fetches every ride agreement the logged-in user is part of.
  /// The user is identified by the session cookie, so no user id is sent.
  Future<List<Map<String, dynamic>>> fetchAgreements() async {
    

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/dashboard/agreements');

    final response = await _client.get(
      uri,
      headers: {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    }

    throw Exception(
      'Loading ride agreements failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}

