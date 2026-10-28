import 'package:flutter/material.dart';

import '../../../core/models/user_profile.dart';
import 'profile_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._profileService);

  final ProfileService _profileService;

  bool isLoading = false;
  String? errorMessage;
  UserProfile? updatedProfile;

  Future<void> saveProfile({
    required UserProfile currentProfile,
    required String firstName,
    required String lastName,
    required String age,
    required String pronouns,
    required String description,
    required String avatarColor,
  }) async {
    if (isLoading) return;

    isLoading = true;
    errorMessage = null;
    updatedProfile = null;
    notifyListeners();

    try {
      final ageText = age.trim();
      final trimmedFirstName = firstName.trim();
      final trimmedLastName = lastName.trim();
      final trimmedDescription = description.trim();
      final trimmedPronouns = pronouns.trim();

      final editedProfile = UserProfile(
        userId: currentProfile.userId,
        firstName: trimmedFirstName,
        lastName: trimmedLastName.isEmpty ? null : trimmedLastName,
        age: ageText.isEmpty ? null : int.parse(ageText),
        pronouns: trimmedPronouns.isEmpty ? null : trimmedPronouns,
        description: trimmedDescription.isEmpty ? null : trimmedDescription,
        avatarColor: avatarColor
      );

      final changes = <String, dynamic>{};

      if (editedProfile.firstName != currentProfile.firstName) {
        changes['firstName'] = editedProfile.firstName;
      }

      if (editedProfile.lastName != currentProfile.lastName) {
        changes['lastName'] = editedProfile.lastName;
      }

      if (editedProfile.age != currentProfile.age) {
        changes['age'] = editedProfile.age;
      }

      if (editedProfile.pronouns != currentProfile.pronouns) {
        changes['pronouns'] = editedProfile.pronouns;
      }

      if (editedProfile.description != currentProfile.description) {
        changes['description'] = editedProfile.description;
      }

      if (editedProfile.avatarColor != currentProfile.avatarColor) {
        changes['avatarColor'] = editedProfile.avatarColor;
      }

      if (changes.isEmpty) {
        updatedProfile = currentProfile;
        return;
      }

      updatedProfile = await _profileService.updateProfile(changes: changes);
    } catch (e) {
      errorMessage = _handleError(extractErrorCode(e));
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  String _handleError(int code) {
    switch (code) {
      case 400:
        return 'Some profile details are invalid. Please check your entries.';
      case 401:
        return 'Unable to save your profile. Please try again.';
      case 500:
        return 'Something went wrong. Please try again later.';
      default:
        return 'Unable to save your profile. Please try again.';
    }
  }
}

int extractErrorCode(Object e) {
  final match = RegExp(r'\((\d{3})\)').firstMatch(e.toString());
  return match == null ? -1 : int.parse(match.group(1)!);
}
