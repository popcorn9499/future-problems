import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../core/theme/app_colors.dart';
import '../profile_validators.dart';
import '../profile_controller.dart';
import '../profile_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.user,
    required this.profile,
    this.onSave,
  });

  final User user;
  final UserProfile profile;

  // Connect this callback to ProfileService.
  final Future<void> Function(UserProfile profile)? onSave;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  late final ProfileController _profileController;

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _ageController;
  late final TextEditingController _bioController;
  late final TextEditingController _pronounsController;

  final bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    _profileController = ProfileController(ProfileService());
    _profileController.addListener(_onControllerChanged);

    _firstNameController = TextEditingController(text: widget.user.firstName);
    _lastNameController = TextEditingController(text: widget.user.lastName);
    _emailController = TextEditingController(text: widget.user.email);

    _ageController = TextEditingController(
      text: widget.profile.age?.toString() ?? '',
    );
    _bioController = TextEditingController(
      text: widget.profile.description ?? '',
    );

    _pronounsController = TextEditingController(
      text: widget.profile.pronouns ?? '',
    );
  }

  void _onControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _profileController.removeListener(_onControllerChanged);
    _profileController.dispose();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _ageController.dispose();
    _bioController.dispose();
    _pronounsController.dispose();
    
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    await _profileController.saveProfile(
      currentProfile: widget.profile,
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      age: _ageController.text,
      pronouns: _pronounsController.text,
      description: _bioController.text,
    );

    if (!mounted) return;

    if (_profileController.updatedProfile != null) {
      Navigator.of(context).pop(_profileController.updatedProfile);
    } else if (_profileController.errorMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_profileController.errorMessage!)));
    }
  }

  Future<void> _cancel() async {
    if (_isSaving) return;

    final hasChanges =
        _firstNameController.text != (widget.profile.firstName) ||
        _lastNameController.text != (widget.profile.lastName ?? '') ||
        _ageController.text != (widget.profile.age?.toString() ?? '') ||
        _pronounsController.text != (widget.profile.pronouns ?? '') ||
        _bioController.text != (widget.profile.description ?? '');

    if (hasChanges) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Discard changes?'),
          content: const Text('Your unsaved profile changes will be lost.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Keep Editing'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );

      if (discard != true || !mounted) return;
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final name =
        widget.user.firstName +
        (widget.user.lastName!.trim().isNotEmpty
            ? ' ${widget.user.lastName}'
            : '');

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        _buildHeader(name),
                        const SizedBox(height: 50),

                        _buildSection(
                          title: 'Public Profile',
                          subtitle: 'Choose what other GoBison users see.',
                          child: Column(
                            children: [
                              _buildPair(
                                _editableField(
                                  label: 'First Name',
                                  controller: _firstNameController,
                                  validator:
                                      ProfileValidators.validateFirstName,
                                ),
                                _editableField(
                                  label: 'Last Name',
                                  controller: _lastNameController,
                                ),
                              ),
                              const SizedBox(height: 48),

                              _buildPair(
                                _editableField(
                                  label: 'Age',
                                  controller: _ageController,
                                  hint: 'Optional',
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: ProfileValidators.validateAge,
                                ),
                                  _editableField(
                                    label: 'Pronouns',
                                    controller: _pronounsController,
                                    hint: 'Optional',
                                    maxLength: 30,
                                    textCapitalization: TextCapitalization.none,
                                  ),
                              ),
                              const SizedBox(height: 48),

                              _editableField(
                                label: 'About Me',
                                controller: _bioController,
                                hint: 'Tell other riders a little about yourself...',
                                maxLines: 2,
                                maxLength: 100,
                              ),
                              const SizedBox(height: 48),
                              _buildBottomActions(),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String name) {
    return Row(
      children: [
        UserAvatar(
          firstName: widget.user.firstName,
          lastName: widget.user.lastName,
          radius: 32,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Make it yours',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF29251F),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Your profile helps other riders get to know you.',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEAE6DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }

  Widget _buildPair(Widget first, Widget second) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 460) {
          return Column(children: [first, const SizedBox(height: 18), second]);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: first),
            const SizedBox(width: 16),
            Expanded(child: second),
          ],
        );
      },
    );
  }

  Widget _editableField({
    required String label,
    required TextEditingController controller,
    String hint = '',
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? helperText,
    String? Function(String?)? validator,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
    TextCapitalization? textCapitalization, // Add this
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      textCapitalization: textCapitalization ??
          (maxLines > 1
              ? TextCapitalization.sentences
              : TextCapitalization.words),
      decoration: _decoration(
        label: label,
        hint: hint,
        helperText: helperText,
      ),
    );
  }

  InputDecoration _decoration({
    required String label,
    String? hint,
    String? helperText,
    double borderRadius = 12,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helperText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0DDD6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE0DDD6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }

  Widget _buildBottomActions() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 712),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            OutlinedButton(
              onPressed: _isSaving ? null : _cancel,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _saveProfile,
              icon: _profileController.isLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : null,
              label: Text(
                _profileController.isLoading ? 'Saving...' : 'Save Changes',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 15,
                ),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
