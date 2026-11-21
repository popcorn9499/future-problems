import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/network/api_config.dart';
import '../../core/network/auth_client.dart';
import '../../core/models/user_profile.dart';

class ProfileService {
  ProfileService({http.Client? client})
    : _client = client ?? createAuthClient();

  final http.Client _client;

    Future<UserProfile> getCurrentProfile({required String userId}) {
    return _fetchProfile(
      Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me/profile'),
      userId,
    );
  }

  /// Another user's public profile. [userId] is their email
  Future<UserProfile> getProfile({required String userId}) {
    return _fetchProfile(
      Uri.parse(
        '${ApiConfig.baseUrl}/api/v1/users/${Uri.encodeComponent(userId)}/profile',
      ),
      userId,
    );
  }

  Future<UserProfile> _fetchProfile(Uri uri, String userId) async {
    final response = await _client.get(
      uri,
      headers: const {'Accept': 'application/json'},
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return UserProfile(
        userId: userId,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String?,
        age: json['age'] as int?,
        pronouns: json['pronouns'] as String? ?? json['gender'] as String?,
        description: json['description'] as String?,
        avatarColor: json['avatarColor'] as String? ?? '#E9DFD2',
      );
    }

    throw Exception(
      'Profile lookup failed (${response.statusCode}): ${response.body}',
    );
  }

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

  Future<void> deleteAccount() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/v1/users/me');
    final response = await _client.delete(
      uri,
      headers: const {'Accept': 'application/json'},
    );
    if (response.statusCode == 204) return;
    throw Exception(
      'Account deletion failed (${response.statusCode}): ${response.body}',
    );
  }
}
