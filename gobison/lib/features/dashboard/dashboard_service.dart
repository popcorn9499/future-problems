import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/auth_client.dart';
import '../../core/network/api_config.dart';

class DashboardService {
  final http.Client _client;

  /// While the ride request backend doesn't exist yet, this serves mock data.
  /// Flip to `false` (or delete the mock branch) once the endpoint is live.
  final bool useMock;

  DashboardService({http.Client? client, this.useMock = false})
    : _client = client ?? createAuthClient();

  /// Fetches every ride agreement the logged-in user is part of.
  /// The user is identified by the session cookie, so no user id is sent.
  Future<List<Map<String, dynamic>>> fetchAgreements() async {
    if (useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return _mockAgreements;
    }

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

final List<Map<String, dynamic>> _mockAgreements = [
  {
    'id': 1,
    'origin': 'Steinbach',
    'destination': 'University of Manitoba',
    'departureTime': '07:45',
    'daysOfWeek': ['MONDAY', 'WEDNESDAY', 'FRIDAY'],
    'status': 'ACTIVE',
    'drivers': [
      {'id': 11, 'firstName': 'Sasha', 'lastName': 'Coles', 'address': '123 Main St'},
      {'id': 12, 'firstName': 'Kamryn', 'lastName': 'Janke', 'address': '456 Oak Ave'},
    ],
    'passengers': [
      {'id': 13, 'firstName': 'Carina', 'lastName': 'Rook', 'address': '789 Pine Rd'},
      {'id': 14, 'firstName': 'Rebekah', 'lastName': 'Soneye', 'address': '321 Elm St'},
    ],
  },
  {
    'id': 2,
    'origin': 'Osborne Village',
    'destination': 'University of Manitoba',
    'departureTime': '12:30',
    'daysOfWeek': ['TUESDAY', 'THURSDAY'],
    'status': 'ARCHIVED',
    'drivers': [
      {'id': 15, 'firstName': 'Logan', 'lastName': 'Smith', 'address': '123 Pine Rd'},
    ],
    'passengers': [
      {'id': 16, 'firstName': 'Ruitian', 'lastName': 'Fan', 'address': '987 Oak St'},
      {'id': 17, 'firstName': 'Leon', 'lastName': 'Bauer', 'address': '654 Cedar Ave'},
    ],
  },
];