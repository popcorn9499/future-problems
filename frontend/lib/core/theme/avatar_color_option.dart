import 'package:flutter/material.dart';

import 'app_colors.dart';

class AvatarColorOption {
  const AvatarColorOption({
    required this.name,
    required this.background,
    required this.text,
  });

  final String name;
  final Color background;
  final Color text;

  String get backgroundHex => '#${background.toARGB32().toRadixString(16).substring(2).toUpperCase()}';

  static const List<AvatarColorOption> options = [
    AvatarColorOption(
      name: 'Default',
      background: Color(0xFFE9DFD2),
      text: AppColors.primary,
    ),
    AvatarColorOption(
      name: 'Pastel Pink',
      background: Color(0xFFF8BBD0),
      text: Color(0xFF880E4F),
    ),
    AvatarColorOption(
      name: 'Dark Pink',
      background: Color(0xFFC2185B),
      text: Colors.white,
    ),
    AvatarColorOption(
      name: 'Pastel Purple',
      background: Color(0xFFD1C4E9),
      text: Color(0xFF4527A0),
    ),
    AvatarColorOption(
      name: 'Dark Purple',
      background: Color(0xFF6750A4),
      text: Colors.white,
    ),
    AvatarColorOption(
      name: 'Pastel Blue',
      background: Color(0xFFBBDEFB),
      text: Color(0xFF0D47A1),
    ),
    AvatarColorOption(
      name: 'Dark Blue',
      background: Color(0xFF1565C0),
      text: Colors.white,
    ),
    AvatarColorOption(
      name: 'Pastel Green',
      background: Color(0xFFC8E6C9),
      text: Color(0xFF1B5E20),
    ),
    AvatarColorOption(
      name: 'Dark Green',
      background: Color(0xFF2E7D32),
      text: Colors.white,
    ),
    AvatarColorOption(
      name: 'Pastel Orange',
      background: Color(0xFFFFE0B2),
      text: Color(0xFFE65100),
    ),
    AvatarColorOption(
      name: 'Dark Orange',
      background: Color(0xFFEF6C00),
      text: Colors.white,
    ),
    AvatarColorOption(
      name: 'Pastel Yellow',
      background: Color(0xFFFFF9C4),
      text: Color(0xFFF57F17),
    ),
  ];

  static AvatarColorOption fromHex(String? hex) {
    final normalizedHex = (hex ?? '#E9DFD2')
        .replaceFirst('#', '')
        .toUpperCase();

    for (final option in options) {
      if (option.backgroundHex.substring(1) == normalizedHex) {
        return option;
      }
    }

    return options.first;
  }

  
  static const Color defaultBackground = Color(0xFFE9DFD2);
  static const Color defaultText = Color(0xFF5D4037);

  static Color hexToColor(String? hex) {
    if (hex == null || hex.trim().isEmpty) {
      return defaultBackground;
    }

    try {
      final value = hex.trim().replaceFirst('#', '');
      final normalized = value.length == 6 ? 'FF$value' : value;

      return Color(int.parse(normalized, radix: 16));
    } catch (_) {
      return defaultBackground;
    }
  }

  static Color getBackgroundColor(String? hex) {
    return fromHex(hex).background;
  }

  static Color getTextColor(String? hex) {
    return fromHex(hex).text;
  }

}