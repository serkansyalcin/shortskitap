import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:screenshot/screenshot.dart';
import '../../../app/providers/daily_quote_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/daily_quote_model.dart';
import '../../../core/platform/browser_file_download.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../core/widgets/shareable_quote_overlay.dart';
import 'home_async_inline_retry.dart';

class DailyQuoteCardSection extends ConsumerStatefulWidget {
  const DailyQuoteCardSection({super.key});

  @override
  ConsumerState<DailyQuoteCardSection> createState() =>
      _DailyQuoteCardSectionState();
}

class _DailyQuoteCardSectionState extends ConsumerState<DailyQuoteCardSection> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isSharing = false;

  Future<bool> _ensureGallerySavePermission() async {
    if (kIsWeb || !Platform.isIOS) {
      return true;
    }

    final status = await Permission.photosAddOnly.request();
    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Galeriye kaydetmek için erişim izni vermelisiniz.',
          ),
          action: status.isPermanentlyDenied
              ? SnackBarAction(
                  label: 'Ayarlar',
                  onPressed: () => openAppSettings(),
                )
              : null,
        ),
      );
    }

    return false;
  }

  bool _useLegacyGalleryPermissionFlow() => false;

  Future<void> _shareQuote(DailyQuoteModel quote) async {
    if (_isSharing) return;

    setState(() => _isSharing = true);

    try {
      if (_useLegacyGalleryPermissionFlow()) {
        if (Platform.isAndroid) {
          final status = await Permission.photosAddOnly.request();
          if (!status.isGranted && !status.isLimited) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Galeriye kaydetmek için izin vermelisiniz.'),
                ),
              );
            }
            return;
          }
        }
      } else if (_useLegacyGalleryPermissionFlow()) {
        final status = await Permission.photosAddOnly.request();

        if (!status.isGranted && !status.isLimited) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                  'Galeriye kaydetmek için izin vermelisiniz.',
                ),
                action: status.isPermanentlyDenied
                    ? SnackBarAction(
                        label: 'Ayarlar',
                        onPressed: () => openAppSettings(),
                      )
                    : null,
              ),
            );
          }
          return;
        }
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      final image = await _screenshotController.captureFromWidget(
        Material(
          child: ShareableQuoteOverlay(quote: quote, isDark: isDark),
        ),
        delay: const Duration(milliseconds: 100),
      );

      if (kIsWeb) {
        await downloadBytes(
          bytes: image,
          mimeType: 'image/png',
          filename: 'kitaplig_quote_${quote.id}.png',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Alıntı indirildi! ✨'),
              backgroundColor: AppColors.primary,
            ),
          );
        }
      } else {
        final canSave = await _ensureGallerySavePermission();
        if (!canSave) {
          return;
        }

        final result = await ImageGallerySaverPlus.saveImage(
          image,
          quality: 100,
          name: 'kitaplig_quote_${quote.id}',
        );
        if (mounted) {
          if (result['isSuccess'] == true) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Alıntı galeriye kaydedildi! ✨'),
                backgroundColor: AppColors.primary,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kaydedilirken bir hata oluştu.')),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Share error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingErrorMessage(
                e,
                fallback:
                    'Paylaşım veya kayıt sırasında bir sorun oluştu. Tekrar dene.',
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSharing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final quoteAsync = ref.watch(dailyQuoteProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return quoteAsync.when(
      data: (quote) {
        if (quote == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: colorScheme.outline.withOpacity(0.35)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      colorScheme.surfaceContainerHighest.withOpacity(0.6),
                      colorScheme.surfaceContainerHighest.withOpacity(0.3),
                    ]
                  : [
                      AppColors.primary.withOpacity(0.08),
                      AppColors.accent.withOpacity(0.05),
                    ],
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Positioned(
                top: -20,
                right: -20,
                child: Icon(
                  Icons.format_quote_rounded,
                  size: 100,
                  color: AppColors.primary.withOpacity(0.1),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'Günün Alıntısı',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const Spacer(),
                        _isSharing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              )
                            : IconButton(
                                visualDensity: VisualDensity.compact,
                                onPressed: () => _shareQuote(quote),
                                icon: Icon(
                                  Icons.ios_share_rounded,
                                  size: 18,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '"${quote.content}"',
                      style: TextStyle(
                        fontSize: 16,
                        fontStyle: FontStyle.italic,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => context.push('/books/${quote.book.slug}'),
                      child: Row(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  quote.book.title,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (quote.book.author != null)
                                  Text(
                                    quote.book.author!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: colorScheme.onSurfaceVariant.withOpacity(
                              0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (err, _) => homeAsyncInlineRetry(
        context,
        ref: ref,
        error: err,
        onRetry: () => ref.invalidate(dailyQuoteProvider),
        hint: 'Günün sözü yüklenemedi',
      ),
    );
  }
}
