import 'package:flutter/material.dart';

class AppColors {
  // KitapLig Brand
  static const primary = Color(0xFF1B5E20);      // Derin yeşil
  static const primaryLight = Color(0xFF2E7D32);
  static const accent = Color(0xFFF9A825);        // Altın sarısı
  static const accentSoft = Color(0xFFFFE082);

  // Light theme
  static const lightBackground = Color(0xFFF8F9F6);
  static const lightSurface = Colors.white;
  static const lightText = Color(0xFF1A1A1A);
  static const lightTextSecondary = Color(0xFF5C6B73);

  // Dark theme
  static const darkBackground = Color(0xFF0D1B12);
  static const darkSurface = Color(0xFF1B2E22);
  static const darkText = Color(0xFFE8F5E9);
  static const darkTextSecondary = Color(0xFF9EAD9E);

  // Sepia theme
  static const sepiaBackground = Color(0xFFF5ECD7);
  static const sepiaSurface = Color(0xFFEDE0C4);
  static const sepiaText = Color(0xFF3B2F20);
  static const sepiaTextSecondary = Color(0xFF7B6550);

  // KitapLig gradients
  static const brandGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
