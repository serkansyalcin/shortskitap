import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // KitapLig brand palette
  static const primary = Color(0xFF1DB954);
  static const primaryLight = Color(0xFF3BE477);
  static const accent = Color(0xFF509BF5);
  static const accentSoft = Color(0xFFFFC864);

  // Shared neutrals
  static const spotifyBlack = Color(0xFF070707);
  static const spotifyGraphite = Color(0xFF121212);
  static const spotifyPanel = Color(0xFF181818);
  static const spotifyPanelHigh = Color(0xFF232323);
  static const outline = Color(0xFF2E2E2E);

  // Default app theme: KitapLig dark UI
  static const lightBackground = spotifyBlack;
  static const lightSurface = spotifyGraphite;
  static const lightText = Color(0xFFF6F6F6);
  static const lightTextSecondary = Color(0xFFB3B3B3);

  // Alternative dark mode: deeper black
  static const darkBackground = Color(0xFF030303);
  static const darkSurface = Color(0xFF101010);
  static const darkText = Colors.white;
  static const darkTextSecondary = Color(0xFF9C9C9C);

  // Optional warm reading mode
  static const sepiaBackground = Color(0xFFF5ECD7);
  static const sepiaSurface = Color(0xFFEDE0C4);
  static const sepiaText = Color(0xFF3B2F20);
  static const sepiaTextSecondary = Color(0xFF7B6550);

  static const brandGradient = LinearGradient(
    colors: [primaryLight, primary, Color(0xFF11833B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF1A1A1A), Color(0xFF090909)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
