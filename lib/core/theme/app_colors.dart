import 'package:flutter/material.dart';

/// KitapLig - Kitap odaklı, sıcak ve okunabilir palet
class AppColors {
  AppColors._();

  // Ana arka plan - koyu sepia / gece okuma, daha sıcak
  static const Color background = Color(0xFF1E1A18);
  static const Color surface = Color(0xFF282420);
  static const Color surfaceVariant = Color(0xFF332E28);

  // Metin
  static const Color textPrimary = Color(0xFFF5EDE4);
  static const Color textSecondary = Color(0xFFB8A99A);
  static const Color textMuted = Color(0xFF8B7D70);

  // Vurgu - sıcak amber (kitap / sayfa hissi)
  static const Color accent = Color(0xFFE8B86D);
  static const Color accentDim = Color(0xFFC49B5A);

  // İkincil aksan
  static const Color secondary = Color(0xFF7D6B5C);

  // Gradient için
  static const Color gradientStart = Color(0xFF2A231E);
  static const Color gradientEnd = Color(0xFF1A1614);
}
