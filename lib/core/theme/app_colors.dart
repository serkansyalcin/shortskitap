import 'package:flutter/material.dart';

/// KitapLig - kitap odakli, sicak ve okunabilir palet
class AppColors {
  AppColors._();

  // Ana arka plan - gece okuma icin daha sicak tonlar
  static const Color background = Color(0xFF1E1A18);
  static const Color surface = Color(0xFF282420);
  static const Color surfaceVariant = Color(0xFF332E28);

  // Metin
  static const Color textPrimary = Color(0xFFF5EDE4);
  static const Color textSecondary = Color(0xFFB8A99A);
  static const Color textMuted = Color(0xFF8B7D70);

  // Vurgu - sicak amber (kitap / sayfa hissi)
  static const Color accent = Color(0xFFE8B86D);
  static const Color accentDim = Color(0xFFC49B5A);

  // Ikincil aksan
  static const Color secondary = Color(0xFF7D6B5C);

  // Gradient icin
  static const Color gradientStart = Color(0xFF2A231E);
  static const Color gradientEnd = Color(0xFF1A1614);
}
