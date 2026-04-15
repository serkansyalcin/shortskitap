import 'package:flutter/material.dart';

/// Tutarlı UI bileşenleri - tüm sayfalarda aynı tasarım dili
class AppUI {
  const AppUI._();
  static const double screenHorizontalPadding = 20;
  static const double screenTopPadding = 20;
  static const double screenBottomContentPadding = 96;
  static const double sectionGap = 24;
  static const double blockGap = 16;

  /// Sayfa başlığı stili
  static TextStyle pageTitle(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color);
  }

  /// İkincil metin rengi
  static Color textSecondary(BuildContext context) =>
      Theme.of(context).colorScheme.onSurfaceVariant;

  /// Kart arka plan rengi (tema uyumlu)
  static Color cardColor(BuildContext context) => Theme.of(context).cardColor;

  /// Bölüm başlığı (GÖRÜNÜM, AYARLAR vb.)
  static Widget sectionTitle(BuildContext context, String text) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  /// Tema uyumlu kart container
  static Widget card({
    required BuildContext context,
    required List<Widget> children,
  }) {
    final color = cardColor(context);
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  /// Boş durum widget'ı
  static Widget emptyState(
    BuildContext context, {
    required String emoji,
    required String title,
    String? subtitle,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Hata durumu + tekrar dene butonu
  static Widget errorState(
    BuildContext context, {
    required String message,
    String? detail,
    required VoidCallback onRetry,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              const SizedBox(height: 8),
              Text(
                detail,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}
