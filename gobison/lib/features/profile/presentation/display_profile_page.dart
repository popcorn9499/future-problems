import 'package:flutter/material.dart';

import '../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/theme/avatar_color_option.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/user_avatar.dart';
import '../profile_controller.dart';
import '../profile_service.dart';

class DisplayProfilePage extends StatefulWidget {
  const DisplayProfilePage({
    super.key,
    required this.user,
    required this.profile,
    required this.currentUserId,
    this.onEdit,
    this.onAccountDeleted,
  });

  final User user;
  final UserProfile profile;
  final String currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onAccountDeleted;

  @override
  State<DisplayProfilePage> createState() => _DisplayProfilePageState();
}

class _DisplayProfilePageState extends State<DisplayProfilePage> {
  late final ProfileController _controller;

  bool get _isOwnProfile => widget.profile.userId == widget.currentUserId;

  @override
  void initState() {
    super.initState();
    _controller = ProfileController(ProfileService());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.error,
          size: 52,
        ),
        title: const Text('Delete your account?'),
        content: const SizedBox(
          width: 320,
          child: Text(
            'This action cannot be undone. You will be signed out and cannot '
            'sign in or register again with this email.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, delete account'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final deleted = await _controller.deleteAccount();
    if (!mounted) return;
    if (deleted) {
      widget.onAccountDeleted?.call();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Unable to delete your account.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const SizedBox(height: 16),
                        Center(
                          child: UserAvatar(
                            firstName: widget.user.firstName,
                            lastName: widget.user.lastName,
                            radius: 50,
                            backgroundColor:
                                AvatarColorOption.getBackgroundColor(
                                  widget.profile.avatarColor,
                                ),
                            textColor: AvatarColorOption.getTextColor(
                              widget.profile.avatarColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            widget.profile.firstName +
                                (widget.profile.lastName != null
                                    ? ' ${widget.profile.lastName}'
                                    : ''),
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_isOwnProfile) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: OutlinedButton.icon(
                              onPressed: widget.onEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Edit Profile'),
                            ),
                          ),
                        ],
                        const SizedBox(height: 32),
                        if (_hasText(widget.profile.description))
                          _section(
                            context,
                            'About Me',
                            widget.profile.description!,
                          ),
                        if (widget.profile.age != null)
                          _section(
                            context,
                            'Age',
                            widget.profile.age.toString(),
                          ),
                        if (_hasText(widget.profile.pronouns))
                          _section(
                            context,
                            'Pronouns',
                            widget.profile.pronouns!,
                          ),
                      ],
                    ),
                  ),
                  if (_isOwnProfile)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 70),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 320),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _controller.isLoading
                                  ? null
                                  : _confirmDeleteAccount,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.error,
                                side: const BorderSide(
                                  color: AppColors.error,
                                  width: 1.5,
                                ),
                                minimumSize: const Size.fromHeight(52),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              icon: _controller.isLoading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.error,
                                      ),
                                    )
                                  : const Icon(Icons.delete_outline),
                              label: Text(
                                _controller.isLoading
                                    ? 'Deleting account…'
                                    : 'Delete Account',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (_controller.isLoading)
              const Align(
                alignment: Alignment.topCenter,
                child: LinearProgressIndicator(),
              ),
          ],
        ),
      ),
    );
  }

  bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

  Widget _section(BuildContext context, String title, String value) {
    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: ListTile(title: Text(title), subtitle: Text(value)),
      ),
    );
  }
}
