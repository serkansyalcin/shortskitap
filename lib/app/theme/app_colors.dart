import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  // Landing page palette mirrored from the web CSS tokens.
  static const lpGreen50 = Color(0xFFF1F8EC);
  static const lpGreen100 = Color(0xFFD4E8C3);
  static const lpGreen300 = Color(0xFFA3CD7E);
  static const lpGreen400 = Color(0xFF91C365);
  static const lpGreen500 = Color(0xFF75B43E);
  static const lpGreen600 = Color(0xFF6AA438);
  static const lpGreen700 = Color(0xFF53802C);
  static const lpGreen900 = Color(0xFF314C1A);

  static const lpDGreen50 = Color(0xFFE6EBE8);
  static const lpDGreen100 = Color(0xFFB0BFB7);
  static const lpDGreen200 = Color(0xFF8AA194);
  static const lpDGreen300 = Color(0xFF547664);
  static const lpDGreen400 = Color(0xFF335B45);
  static const lpDGreen500 = Color(0xFF003217);
  static const lpDGreen600 = Color(0xFF002E15);
  static const lpDGreen700 = Color(0xFF002410);
  static const lpDGreen800 = Color(0xFF001C0D);
  static const lpDGreen900 = Color(0xFF00150A);

  static const textPrimary = Color(0xFF1A1A1A);
  static const textOnBrand = Colors.white;

  // KitapLig brand aliases used across the app.
  static const primary = lpGreen500;
  static const primaryLight = Color(0xFF9ED36C);
  static const accent = lpDGreen400;
  static const accentSoft = lpGreen100;

  // Shared neutrals
  static const spotifyBlack = Color(0xFF050505);
  static const spotifyGraphite = Color(0xFF0D0E0D);
  static const spotifyPanel = Color(0xFF161816);
  static const spotifyPanelHigh = Color(0xFF222522);
  static const outline = Color(0xFF303630);

  // Light theme
  static const lightBackground = Color(0xFFFFFFFF);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightSurfaceHigh = Color(0xFFFFFFFF);
  static const lightSurfaceMuted = lpDGreen50;
  static const lightText = textPrimary;
  static const lightTextSecondary = lpDGreen300;
  static const lightOutline = Color(0xFFDCE4DB);

  // Dark theme: premium black base with green brand accents.
  static const darkBackground = spotifyBlack;
  static const darkSurface = spotifyGraphite;
  static const darkSurfaceHigh = spotifyPanel;
  static const darkSurfaceMuted = spotifyPanelHigh;
  static const darkText = Color(0xFFF4F6F3);
  static const darkTextSecondary = Color(0xFFB5BBB4);

  static const brandGradient = LinearGradient(
    colors: [primaryLight, primary, lpGreen700],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const heroGradient = LinearGradient(
    colors: [Color(0xFF121512), spotifyBlack],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
