import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFFFF6B35);       // Locket-inspired orange
  static const Color primaryLight = Color(0xFFFF8C5E);
  static const Color primaryDark = Color(0xFFE55A28);
  static const Color accent = Color(0xFFFFD166);

  // Neutral
  static const Color textDark = Color(0xFF1A1A2E);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Backgrounds
  static const Color lightBackground = Color(0xFFF9FAFB);
  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF16213E);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Black opacities (reusable colors to fix invalid Flutter color constants)
  static const Color black10 = Color(0x1A000000); // Color.fromRGBO(0, 0, 0, 0.1)
  static const Color black24 = Color(0x3D000000); // Color.fromRGBO(0, 0, 0, 0.24)
}
