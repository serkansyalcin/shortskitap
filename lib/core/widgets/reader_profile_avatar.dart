import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ReaderProfileAvatarPreset {
  const ReaderProfileAvatarPreset({
    required this.token,
    required this.icon,
    required this.backgroundColor,
    required this.decorationColor,
    required this.accentColor,
    required this.label,
  });

  final String token;
  final IconData icon;
  final Color backgroundColor;
  final Color decorationColor;
  final Color accentColor;
  final String label;
}

class ReaderProfileAvatarCatalog {
  static const String defaultPrefix = 'reader-avatar://default/';

  static const List<ReaderProfileAvatarPreset> presets =
      <ReaderProfileAvatarPreset>[
        ReaderProfileAvatarPreset(
          token: 'fox',
          icon: Icons.pets_rounded,
          backgroundColor: Color(0xFFFFD9A8),
          decorationColor: Color(0xFFFFE7C5),
          accentColor: Color(0xFF9A3412),
          label: 'Tilki',
        ),
        ReaderProfileAvatarPreset(
          token: 'star',
          icon: Icons.star_rounded,
          backgroundColor: Color(0xFFFFF2A8),
          decorationColor: Color(0xFFFFF8CB),
          accentColor: Color(0xFFA16207),
          label: 'Yıldız',
        ),
        ReaderProfileAvatarPreset(
          token: 'planet',
          icon: Icons.public_rounded,
          backgroundColor: Color(0xFFB7D7FF),
          decorationColor: Color(0xFFD3E6FF),
          accentColor: Color(0xFF1D4ED8),
          label: 'Gezegen',
        ),
        ReaderProfileAvatarPreset(
          token: 'leaf',
          icon: Icons.local_florist_rounded,
          backgroundColor: Color(0xFFC8F1B8),
          decorationColor: Color(0xFFE0F8D5),
          accentColor: Color(0xFF3F7A28),
          label: 'Yaprak',
        ),
        ReaderProfileAvatarPreset(
          token: 'rocket',
          icon: Icons.rocket_launch_rounded,
          backgroundColor: Color(0xFFFCC6EA),
          decorationColor: Color(0xFFFEDDF2),
          accentColor: Color(0xFF9D174D),
          label: 'Roket',
        ),
        ReaderProfileAvatarPreset(
          token: 'cloud',
          icon: Icons.cloud_rounded,
          backgroundColor: Color(0xFFDDF2FF),
          decorationColor: Color(0xFFF0F9FF),
          accentColor: Color(0xFF0F766E),
          label: 'Bulut',
        ),
      ];

  static String tokenValue(String token) => '$defaultPrefix$token';

  static String tokenValueAt(int index) {
    final normalizedIndex = index % presets.length;
    return tokenValue(presets[normalizedIndex].token);
  }

  static String suggestedTokenValue({int? index, String? seedText}) {
    if (index != null) {
      return tokenValueAt(index.abs());
    }

    if (seedText != null && seedText.trim().isNotEmpty) {
      final hash = seedText.trim().runes.fold<int>(
        0,
        (value, rune) => value + rune,
      );
      return tokenValueAt(hash);
    }

    return tokenValueAt(0);
  }

  static bool isDefaultAvatar(String? value) =>
      value != null && value.startsWith(defaultPrefix);

  static ReaderProfileAvatarPreset? presetForValue(String? value) {
    if (!isDefaultAvatar(value)) return null;
    final token = value!.substring(defaultPrefix.length);
    for (final preset in presets) {
      if (preset.token == token) return preset;
    }
    return null;
  }
}

class ReaderProfileAvatar extends StatelessWidget {
  const ReaderProfileAvatar({
    super.key,
    required this.name,
    this.avatarRef,
    this.memoryBytes,
    this.size = 72,
    this.borderRadius,
  });

  final String name;
  final String? avatarRef;
  final Uint8List? memoryBytes;
  final double size;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.3);

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(width: size, height: size, child: _buildChild(context)),
    );
  }

  Widget _buildChild(BuildContext context) {
    if (memoryBytes != null) {
      return Image.memory(memoryBytes!, fit: BoxFit.cover);
    }

    final preset = ReaderProfileAvatarCatalog.presetForValue(avatarRef);
    if (preset != null) {
      return _PresetAvatarTile(preset: preset);
    }

    if (ReaderProfileAvatarCatalog.isDefaultAvatar(avatarRef)) {
      return _InitialFallback(name: name, size: size);
    }

    if (avatarRef != null && avatarRef!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: avatarRef!,
        fit: BoxFit.cover,
        errorWidget: (context, url, error) =>
            _InitialFallback(name: name, size: size),
      );
    }

    return _InitialFallback(name: name, size: size);
  }
}

class _InitialFallback extends StatelessWidget {
  const _InitialFallback({required this.name, required this.size});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.trim()[0].toUpperCase();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : const Color(0xFF75B43E).withValues(alpha: 0.14),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            fontSize: size * 0.44,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF75B43E),
          ),
        ),
      ),
    );
  }
}

class _PresetAvatarTile extends StatelessWidget {
  const _PresetAvatarTile({required this.preset});

  final ReaderProfileAvatarPreset preset;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: preset.backgroundColor),
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -10,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: preset.decorationColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(child: Icon(preset.icon, size: 30, color: preset.accentColor)),
        ],
      ),
    );
  }
}
