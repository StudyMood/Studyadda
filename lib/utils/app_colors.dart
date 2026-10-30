import 'package:flutter/material.dart';

class AppColors {
  // Brand accents
  static const primary = Color(0xFF3B6EF8);
  static const primaryLight = Color(0xFFE8EEFF);
  static const primaryDark = Color(0xFF7EA0FF);
  
  static const secondary = Color(0xFF6366F1);
  static const favorite = Color(0xFFE5365B);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF0EA5E9);

  // Subject Card Hues (Cycles for subjects)
  static const List<Color> subjectHues = [
    Color(0xFF2F5BEA), // Blue
    Color(0xFFE5365B), // Pink / Rose
    Color(0xFF17A673), // Emerald
    Color(0xFFF08A24), // Orange
    Color(0xFF8A4FE0), // Purple
    Color(0xFF0DA5C0), // Cyan
    Color(0xFFD1478F), // Magenta
    Color(0xFF5B7A1E), // Olive green
  ];

  static Color getSubjectColor(int index) {
    return subjectHues[index % subjectHues.length];
  }

  // Dark Theme palette
  static const darkBackground = Color(0xFF0D1422);
  static const darkSurface = Color(0xFF16203A);
  static const darkSurfaceVariant = Color(0xFF1D2B52);
  static const darkBorder = Color(0xFF26314F);
  static const darkTextPrimary = Color(0xFFE8EDF8);
  static const darkTextSecondary = Color(0xFF9AA7C2);

  // Light Theme palette
  static const lightBackground = Color(0xFFF4F6FB);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceVariant = Color(0xFFE8EEFF);
  static const lightBorder = Color(0xFFE1E6F0);
  static const lightTextPrimary = Color(0xFF14213A);
  static const lightTextSecondary = Color(0xFF5F6B82);
}
