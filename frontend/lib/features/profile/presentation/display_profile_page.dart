import 'package:flutter/material.dart';

import '../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/theme/avatar_color_option.dart';

class DisplayProfilePage extends StatelessWidget {
  const DisplayProfilePage({
    super.key,
    required this.user,
    required this.profile,
    required this.currentUserId,
    this.onEdit,
  });

  final User user;
  final UserProfile profile;
  final String currentUserId;
  final VoidCallback? onEdit;

  bool get _isOwnProfile => profile.userId == currentUserId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),

          Center(
            child: UserAvatar(
              firstName: user.firstName,
              lastName: user.lastName,
              radius: 50,
              backgroundColor: AvatarColorOption.getBackgroundColor(profile.avatarColor,),
              textColor: AvatarColorOption.getTextColor(profile.avatarColor,),
            ),
          ),

          const SizedBox(height: 16),

          Center(
            child: Text(
              profile.firstName +
                  (profile.lastName != null ? ' ${profile.lastName}' : ''),
              style: Theme.of(context).textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          if (_isOwnProfile) ...[
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit Profile'),
              ),
            ),
          ],

          const SizedBox(height: 32),

          if (_hasText(profile.description))
            _section(context, 'About Me', profile.description!),

          if (profile.age != null)
            _section(context, 'Age', profile.age.toString()),

          if (_hasText(profile.pronouns))
            _section(context, 'Pronouns', profile.pronouns!),
        ],
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Widget _section(BuildContext context, String title, String value) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(horizontal: 180, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListTile(title: Text(title), subtitle: Text(value)),
      ),
    );
  }
}
