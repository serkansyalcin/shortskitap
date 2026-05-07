import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTheme {
  static ThemeData get light => _buildTheme(
    brightness: Brightness.light,
    background: AppColors.lightBackground,
    surface: AppColors.lightSurface,
    surfaceHigh: AppColors.lightSurfaceHigh,
    surfaceMuted: AppColors.lightSurfaceMuted,
    text: AppColors.lightText,
    textSecondary: AppColors.lightTextSecondary,
    outline: AppColors.lightOutline,
    primaryForeground: AppColors.textOnBrand,
    snackBarBackground: AppColors.lpDGreen500,
  );

  static ThemeData get dark => _buildTheme(
    brightness: Brightness.dark,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    surfaceHigh: AppColors.darkSurfaceHigh,
    surfaceMuted: AppColors.darkSurfaceMuted,
    text: AppColors.darkText,
    textSecondary: AppColors.darkTextSecondary,
    outline: AppColors.outline,
    primaryForeground: AppColors.textOnBrand,
    snackBarBackground: AppColors.spotifyPanelHigh,
  );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceHigh,
    required Color surfaceMuted,
    required Color text,
    required Color textSecondary,
    required Color outline,
    required Color primaryForeground,
    required Color snackBarBackground,
  }) {
    final isDark = brightness == Brightness.dark;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: brightness,
          surface: surface,
        ).copyWith(
          primary: AppColors.primary,
          onPrimary: primaryForeground,
          primaryContainer: isDark
              ? AppColors.lpDGreen600
              : AppColors.lpGreen100,
          onPrimaryContainer: isDark
              ? AppColors.lpGreen100
              : AppColors.lpGreen900,
          secondary: AppColors.accent,
          onSecondary: Colors.white,
          secondaryContainer: isDark
              ? AppColors.lpDGreen500
              : AppColors.lpGreen50,
          onSecondaryContainer: isDark
              ? AppColors.lpDGreen50
              : AppColors.lpDGreen500,
          surface: surface,
          onSurface: text,
          surfaceTint: Colors.transparent,
          surfaceContainerHighest: surfaceMuted,
          surfaceContainerHigh: surfaceHigh,
          onSurfaceVariant: textSecondary,
          outline: outline,
          error: const Color(0xFFFF6B6B),
          onError: Colors.white,
        );

    final textTheme = GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        color: text,
        fontSize: 40,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.4,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        color: text,
        fontSize: 34,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.0,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        color: text,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        color: text,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleMedium: GoogleFonts.dmSans(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
      bodyLarge: GoogleFonts.dmSans(
        color: text,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: GoogleFonts.dmSans(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: GoogleFonts.dmSans(
        color: textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      labelLarge: GoogleFonts.dmSans(
        color: text,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );

    return ThemeData(
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surfaceHigh,
      dividerColor: outline,
      splashColor: AppColors.primary.withValues(alpha: 0.12),
      highlightColor: AppColors.primary.withValues(alpha: 0.08),
      cardTheme: CardThemeData(
        color: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: textTheme.titleLarge,
      ),
      iconTheme: IconThemeData(color: text),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        height: 72,
        indicatorColor: AppColors.primary.withValues(alpha: isDark ? 0.22 : 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.bodySmall?.copyWith(
            color: selected ? text : textSecondary,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primary : textSecondary,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: primaryForeground,
          disabledBackgroundColor: surfaceMuted,
          disabledForegroundColor: textSecondary,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: primaryForeground,
          disabledBackgroundColor: surfaceMuted,
          disabledForegroundColor: textSecondary,
          minimumSize: const Size(double.infinity, 56),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.titleMedium,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: text,
          side: BorderSide(color: outline),
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          final disabled = states.contains(WidgetState.disabled);

          if (selected) {
            return disabled
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.white;
          }

          if (disabled) {
            return isDark
                ? Colors.white.withValues(alpha: 0.35)
                : const Color(0xFFF4F7F1);
          }

          return isDark ? const Color(0xFFD7E2D6) : const Color(0xFFFFFFFF);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          final disabled = states.contains(WidgetState.disabled);

          if (selected) {
            return disabled
                ? AppColors.primary.withValues(alpha: 0.28)
                : AppColors.primary.withValues(alpha: 0.55);
          }

          if (disabled) {
            return isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFE8EEE7);
          }

          return isDark ? const Color(0xFF2A332D) : const Color(0xFFDDE6DB);
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          final disabled = states.contains(WidgetState.disabled);

          if (selected) {
            return Colors.transparent;
          }

          if (disabled) {
            return outline.withValues(alpha: isDark ? 0.2 : 0.35);
          }

          return outline.withValues(alpha: isDark ? 0.65 : 0.9);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceMuted,
        labelStyle: TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 1.6),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceHigh,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: surfaceHigh,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarBackground,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primary,
      ),
      useMaterial3: true,
    );
  }

  static ThemeData fromString(String theme) {
    switch (theme) {
      case 'dark':
        return dark;
      default:
        return light;
    }
  }
}

extension ThemeContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get readerBackground => Theme.of(this).scaffoldBackgroundColor;

  Color get readerText =>
      Theme.of(this).textTheme.bodyLarge?.color ?? Colors.black;
}
