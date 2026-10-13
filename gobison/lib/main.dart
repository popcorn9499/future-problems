import 'package:flutter/material.dart';

import 'features/auth/register_page.dart';

void main() {
  runApp(const GoBisonApp());
}

class GoBisonApp extends StatelessWidget {
  const GoBisonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GoBison',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF654321)),
        useMaterial3: true,
      ),
      home: const RegisterPage(),
    );
  }
}
