import 'package:flutter/material.dart';

class AppColors {
  // Brand colors
  static const Color primary = Color(0xFFC8E953);
  static const Color primarySoft = Color(0xFFB8CC71);
  
  // Base colors
  static const Color backgroundLight = Color(0xFFF8F8F6);
  static const Color backgroundDark = Color(0xFF1D2111);
  static const Color iosGray = Color(0xFF8E8E93);
  static const Color iosDivider = Color(0xFFE5E5EA);
  static const Color brandDark = Color(0xFF1A1C1E);
  static const Color softBackground = Color(0xFFF9FAFB);
  
  // Semantic colors
  static const Color error = Color(0xFFFEE2E2);
  static const Color errorText = Colors.red;
  static const Color success = Color(0xFFC8E953);
}

class AppDecorations {
  static final softShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.05),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static const borderRadius = BorderRadius.all(Radius.circular(12));
  static const borderRadiusLg = BorderRadius.all(Radius.circular(16));
  static const borderRadiusXl = BorderRadius.all(Radius.circular(24));
}
