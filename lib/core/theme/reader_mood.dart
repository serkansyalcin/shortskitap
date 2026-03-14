import 'package:flutter/material.dart';

/// Okuma ekranında kaydırdıkça değişen arka plan gradyanları.
/// Her paragraf/sayfa farklı bir "mood" — tekdüzelik kalkar, ilerleme hissi verir.
class ReaderMood {
  ReaderMood._();

  static const List<List<Color>> _gradients = [
    [Color(0xFF2D2520), Color(0xFF1C1815)], // Sıcak sepia
    [Color(0xFF2A2438), Color(0xFF1A1625)], // Soft lavanta-gri
    [Color(0xFF252A2E), Color(0xFF161C1E)], // Gece mavisi
    [Color(0xFF24302A), Color(0xFF151D19)], // Orman yeşili
    [Color(0xFF2E2622), Color(0xFF1F1916)], // Terracotta
    [Color(0xFF2B2826), Color(0xFF1A1816)], // Sıcak kömür
  ];

  static const List<Color> _progressAccents = [
    Color(0xFFE8B86D), // Amber
    Color(0xFFB8A4C9), // Lavanta
    Color(0xFF7B9BB2), // Mavi
    Color(0xFF7BA88A), // Yeşil
    Color(0xFFC4957A), // Terracotta
    Color(0xFFB8A99A), // Bej
  ];

  static List<Color> gradientForPage(int pageIndex) {
    return _gradients[pageIndex % _gradients.length];
  }

  static Color progressAccentForPage(int pageIndex) {
    return _progressAccents[pageIndex % _progressAccents.length];
  }

  static BoxDecoration decorationForPage(int pageIndex) {
    final colors = gradientForPage(pageIndex);
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      ),
    );
  }
}
