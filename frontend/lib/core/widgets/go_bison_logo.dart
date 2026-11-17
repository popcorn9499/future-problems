import 'package:flutter/material.dart';

class GoBisonLogo extends StatelessWidget {
  const GoBisonLogo({super.key, this.height = 90});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Image.asset('assets/images/go_bison_logo.png', height: height, fit: BoxFit.contain),
      ),
    );
  }
}

class LogoSmall extends StatelessWidget {
  const LogoSmall({super.key, this.height = 40});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Center(
        child: Image.asset('assets/images/logo_small.png', height: height, fit: BoxFit.contain),
      ),
    );
  }
}
