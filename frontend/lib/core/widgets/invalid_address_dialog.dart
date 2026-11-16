import 'package:flutter/material.dart';

Future<void> showInvalidAddressDialog(
  BuildContext context,
  String message,
) => showDialog<void>(
  context: context,
  builder: (context) => AlertDialog(
    title: const Text('Address not found'),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('OK'),
      ),
    ],
  ),
);
