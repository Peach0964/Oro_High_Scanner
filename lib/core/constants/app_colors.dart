import 'package:flutter/material.dart';

class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF6C63FF);
  static const Color primaryDark = Color(0xFF5A52D5);
  static const Color primaryDarker = Color(0xFF4A42B8);
  static const Color primaryLight = Color(0xFF8B83FF);
  
  // Accent Colors
  static const Color accent = Color(0xFFFFB347);
  static const Color accentLight = Color(0xFFFF9A76);
  
  // Text Colors
  static const Color textDark = Color(0xFF2D3748);
  static const Color textMedium = Color(0xFF718096);
  static const Color textLight = Color(0xFFCBD5E0);
  
  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundMedium = Color(0xFFE8E8E8);
  static const Color backgroundWhite = Colors.white;
  
  // Border Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocus = primary;
  
  // Status Colors
  static const Color success = Color(0xFF48BB78);
  static const Color error = Color(0xFFF56565);
  static const Color warning = Color(0xFFED8936);
  static const Color info = Color(0xFF4299E1);
  
  // Gradient Colors
  static const List<Color> primaryGradient = [
    primary,
    primaryDark,
    primaryDarker,
  ];
  
  static const List<Color> backgroundGradient = [
    backgroundLight,
    backgroundMedium,
  ];
  
  static const List<Color> accentGradient = [
    accent,
    accentLight,
  ];
  
  // Illustration Colors
  static const Color illustrationTree = Color(0xFF4A5568);
  static const Color illustrationGround = Color(0xFF7DD3C0);
  static const Color illustrationGroundDark = Color(0xFF5FB8A8);
  static const Color illustrationWindow = Color(0xFFFFF4E6);
  static const Color illustrationDoor = Color(0xFF8B4513);
  static const Color illustrationSky = Color(0xFF3A3298);
}
