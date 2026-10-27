import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/models/user_profile.dart';

class ProfileService {
  ProfileService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<UserProfile> updateProfile({
    required Map<String, dynamic> changes,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/profile');

    final response = await _client.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(changes),
    );

    if (response.statusCode == 200) {
      return UserProfile.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    throw Exception(
      'Profile update failed (${response.statusCode}): '
      '${response.body}',
    );
  }
}
