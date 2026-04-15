import 'package:flutter/material.dart';

class InteractionPalette {
  const InteractionPalette({
    required this.accent,
    required this.secondaryAccent,
    required this.onAccent,
    required this.background,
    required this.backgroundAlt,
    required this.surface,
    required this.surfaceStrong,
    required this.border,
    required this.text,
    required this.mutedText,
    required this.success,
    required this.error,
  });

  final Color accent;
  final Color secondaryAccent;
  final Color onAccent;
  final Color background;
  final Color backgroundAlt;
  final Color surface;
  final Color surfaceStrong;
  final Color border;
  final Color text;
  final Color mutedText;
  final Color success;
  final Color error;

  factory InteractionPalette.fromAccent(Color accentColor) {
    final scheme = ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.dark,
    );

    return InteractionPalette(
      accent: accentColor,
      secondaryAccent: scheme.secondary,
      onAccent: scheme.onPrimary,
      background: Color.lerp(scheme.surface, accentColor, 0.10)!,
      backgroundAlt: Color.lerp(
        scheme.surfaceContainerHigh,
        accentColor,
        0.18,
      )!,
      surface: Color.lerp(scheme.surfaceContainerHigh, accentColor, 0.10)!,
      surfaceStrong: Color.lerp(
        scheme.surfaceContainerHighest,
        accentColor,
        0.16,
      )!,
      border: Color.lerp(scheme.outlineVariant, accentColor, 0.26)!,
      text: scheme.onSurface,
      mutedText: scheme.onSurfaceVariant,
      success: scheme.tertiary,
      error: scheme.error,
    );
  }
}

Color resolveInteractionAccentColor(BuildContext context, String? rawColor) {
  final fallback = Theme.of(context).colorScheme.primary;
  if (rawColor == null || rawColor.trim().isEmpty) {
    return fallback;
  }

  final normalized = rawColor.trim();

  try {
    if (normalized.startsWith('#')) {
      final hex = normalized.substring(1);
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      }
      if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    }

    if (normalized.startsWith('0x')) {
      return Color(int.parse(normalized.substring(2), radix: 16));
    }
  } catch (_) {
    return fallback;
  }

  return fallback;
}
