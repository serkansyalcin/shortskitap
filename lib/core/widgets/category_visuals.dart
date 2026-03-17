import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class CategoryVisual {
  final IconData icon;
  final Color accent;
  final Color tint;

  const CategoryVisual({
    required this.icon,
    required this.accent,
    required this.tint,
  });
}

class CategoryVisuals {
  const CategoryVisuals._();

  static CategoryVisual resolve({
    String? slug,
    required String name,
    String? colorHex,
  }) {
    final key = _normalize(slug?.isNotEmpty == true ? slug! : name);
    final accent = _colorFromHex(colorHex) ?? _fallbackAccent(key);

    switch (key) {
      case 'roman':
        return _build(Icons.auto_stories_rounded, accent);
      case 'klasikler':
      case 'dunya-klasikleri':
        return _build(Icons.castle_rounded, accent);
      case 'psikoloji':
        return _build(Icons.psychology_alt_rounded, accent);
      case 'felsefe':
        return _build(Icons.lightbulb_rounded, accent);
      case 'bilim-kurgu':
        return _build(Icons.rocket_launch_rounded, accent);
      case 'tarih':
        return _build(Icons.history_edu_rounded, accent);
      case 'biyografi':
        return _build(Icons.person_rounded, accent);
      case 'kisisel-gelisim':
        return _build(Icons.spa_rounded, accent);
      case 'polisiye':
        return _build(Icons.search_rounded, accent);
      case 'siir':
        return _build(Icons.music_note_rounded, accent);
      case 'turk-edebiyati':
        return _build(Icons.menu_book_rounded, accent);
      case 'macera':
        return _build(Icons.explore_rounded, accent);
      case 'kisa-hikayeler':
        return _build(Icons.article_rounded, accent);
      case 'genclik-edebiyati':
        return _build(Icons.bolt_rounded, accent);
      default:
        return _build(Icons.book_rounded, accent);
    }
  }

  static CategoryVisual _build(IconData icon, Color accent) {
    return CategoryVisual(
      icon: icon,
      accent: accent,
      tint: accent.withValues(alpha: 0.14),
    );
  }

  static String _normalize(String value) {
    const source = 'çğıöşüÇĞİÖŞÜâîûÂÎÛ';
    const target = 'cgiosuCGIOSUaiuAIU';

    var normalized = value.trim().toLowerCase();
    for (var i = 0; i < source.length; i++) {
      normalized = normalized.replaceAll(source[i], target[i]);
    }
    return normalized.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  }

  static Color _fallbackAccent(String key) {
    final palette = <Color>[
      AppColors.primary,
      AppColors.accent,
      AppColors.accentSoft,
      const Color(0xFFEF6C57),
      const Color(0xFF7C8CFF),
      const Color(0xFF14B8A6),
    ];
    final index =
        key.runes.fold<int>(0, (sum, rune) => sum + rune) % palette.length;
    return palette[index];
  }

  static Color? _colorFromHex(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final cleaned = hex.replaceFirst('#', '');
    if (cleaned.length != 6) return null;
    final value = int.tryParse('FF$cleaned', radix: 16);
    return value == null ? null : Color(value);
  }
}
