import 'package:flutter/material.dart';

import 'package:gobison/features/auth/presentation/session_gate.dart';

import '../auth_controller.dart';
import '../auth_service.dart';
import '../../../core/widgets/go_bison_logo.dart';

import '../../../core/models/user.dart';
import '../../../core/models/user_profile.dart';

class VerificationPage extends StatefulWidget {
  const VerificationPage({
    super.key,
    required this.email,
    required this.user,
    required this.userProfile,
  });
  final String email;
  final User user;

  final UserProfile userProfile;

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AuthService _authService;
  late final AuthController _authController;

  final List<TextEditingController> _controllers = List.generate(
    6,
    (_) => TextEditingController(),
  ); // Used for 6 digit verification field
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _authService = AuthService();
    _authController = AuthController(_authService);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authController.dispose();

    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyEmail(String currentCode) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    await _authController.emailVerification(
      code: currentCode,
      user: widget.user,
    );
    if (!mounted) return;
    if (_authController.errorMessage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correct code entered! Account is now verified.'),
        ),
      );
      // Go back through session gate, this time with a verified account
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SessionGate()),
        (route) => false,
      );
    } else {}
  }

  void _handleCodeChanged(String value, int index) {
    if (value.isNotEmpty && index < 5) {
      // Move to next box when a digit is entered
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      // Move back when backspace is pressed
      _focusNodes[index - 1].requestFocus();
    }

    // Combine all controller texts to check if the code is complete
    final currentCode = _controllers.map((c) => c.text).join();

    if (index == 5) _verifyEmail(currentCode);
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
              child: ListenableBuilder(
                listenable: _authController,
                builder: (context, child) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // GoBison logo
                        GoBisonLogo(height: 100),
                        // Title
                        const Text(
                          'Account Verification',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Subtitle with dynamic email and bolded styling
                        Text.rich(
                          TextSpan(
                            text: 'Enter the 6-digit number sent to ',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                            children: [
                              TextSpan(
                                text: widget.email, // Pulls from the variable
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87, // Optional: slightly darker so it stands out more
                                ),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),

                        // 6-Digit Code Fields
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(6, (index) {
                            return SizedBox(
                              width: 48,
                              height: 56,
                              child: TextField(
                                controller: _controllers[index],
                                focusNode: _focusNodes[index],
                                textAlign: TextAlign.center,
                                keyboardType: TextInputType.number,
                                maxLength: 1,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                                decoration: InputDecoration(
                                  counterText: '',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onChanged: (value) =>
                                    _handleCodeChanged(value, index),
                              ),
                            );
                          }),
                        ),

                        // Error message displayed below the code fields if present
                        if (_authController.errorMessage != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _authController.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        const SizedBox(height: 24),
                        const SizedBox(height: 12),

                        const Text(
                          'GoBison • Ride with the herd.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.black38),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
