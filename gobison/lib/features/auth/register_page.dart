import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }

    final UMNetId = value.trim();

    if (UMNetId.contains('@')) {
      return 'Enter the UMNetId part of your email only, without @ or a domain';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }

    return null;
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      // TODO: Send the registration details to backend API.
    }
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // GoBison logo
                    Center(
                      child: Container(
                        width: 1006,
                        height: 90,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.all(7),
                                  child: const Icon(
                                    Icons.directions_car_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Image.asset(
                                  'assets/images/umanitoba_bisons_logo.png',
                                  height: 70,
                                  fit: BoxFit.contain,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    // const SizedBox(height: 4),
                    const Text(
                      'Join GoBison',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Your campus journey starts here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // First name
                    _buildTextField(
                      label: 'First name',
                      hint: 'Enter your first name',
                      controller: _firstNameController,
                      icon: Icons.person_outline,
                      validator: _validateRequired,
                    ),

                    const SizedBox(height: 20),

                    // Last name
                    _buildTextField(
                      label: 'Last name',
                      hint: 'Enter your last name',
                      controller: _lastNameController,
                      icon: Icons.person_outline,
                      validator: _validateRequired,
                    ),

                    const SizedBox(height: 20),

                    // Email
                    _buildTextField(
                      label: 'University of Manitoba Email',
                      hint: 'Enter your UMNetID',
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: _validateEmail,
                      suffixIcon: const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            '@myumanitoba.ca',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Password
                    _buildTextField(
                      label: 'Password',
                      hint: 'At least 8 characters',
                      controller: _passwordController,
                      icon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      validator: _validatePassword,
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Show password'
                            : 'Hide password',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Create account button
                    SizedBox(
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Already have an account? ',
                          style: TextStyle(color: Colors.black54, fontSize: 14),
                        ),
                        TextButton(
                          onPressed: () {
                            // TODO: Navigate to the login page.
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            'Sign in',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      'GoBison • Ride with the herd.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
