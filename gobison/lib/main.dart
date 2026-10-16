import 'package:flutter/material.dart';

import 'features/auth/presentation/register_page.dart';
import 'features/auth/presentation/login_page.dart';

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
      initialRoute: '/register',

      routes: {
        //'/': (context) => const HomePage(), TODO: Uncomment this line when the HomePage is implemented.
        '/register': (context) => const RegisterPage(),
        '/login': (context) => const LoginPage(),
      },
    );
  }
}
