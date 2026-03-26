import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/series_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/user_friendly_error.dart';

class SeriesScreen extends ConsumerWidget {
  final int seriesId;

  const SeriesScreen({super.key, required this.seriesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesAsync = ref.watch(seriesDetailProvider(seriesId));
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: seriesAsync.when(
        data: (series) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                toolbarHeight: 68,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.94),
                surfaceTintColor: Colors.transparent,
                leadingWidth: 68,
                leading: Padding(
                  padding: const EdgeInsets.only(left: 20, top: 12, bottom: 12),
                  child: IconButton(
                    onPressed: () => context.pop(),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.6),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 40),
                      maximumSize: const Size(40, 40),
                    ),
                    icon: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: colorScheme.onSurface,
                      size: 16,
                    ),
                  ),
                ),
                title: Text(
                  series.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Series header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primary.withValues(alpha: 0.18),
                              colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.15),
                          ),
                        ),
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
                                    color:
                                        AppColors.primary.withValues(alpha: 0.14),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: const Text(
                                    '📚 Seri',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${series.books.length} Kitap',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              series.title,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: colorScheme.onSurface,
                                letterSpacing: -0.8,
                                height: 1.1,
                              ),
                            ),
                            if (series.authorName != null) ...[
                              const SizedBox(height: 6),
                              Text(
                                series.authorName!,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            if (series.description != null &&
                                series.description!.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Text(
                                series.description!,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.7,
                                  color: colorScheme.onSurface
                                      .withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Books in series
                      Text(
                        'Seri Kitapları',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 14),
                      ...series.books.asMap().entries.map((entry) {
                        final index = entry.key;
                        final book = entry.value;
                        return GestureDetector(
                          onTap: () => context.push('/books/${book.slug}'),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.14),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                      child: book.coverImageUrl != null
                                      ? CachedNetworkImage(
                                          imageUrl: book.coverImageUrl!,
                                          width: 52,
                                          height: 68,
                                          fit: BoxFit.cover,
                                          errorWidget: (_, __, ___) =>
                                              _BookFallback(
                                            color: AppColors.primary,
                                          ),
                                        )
                                      : _BookFallback(
                                          color: AppColors.primary,
                                        ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        book.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      if (book.totalParagraphs > 0)
                                        Text(
                                          '${book.totalParagraphs} paragraf',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color:
                                                colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => _SeriesAsyncShell(
          colorScheme: colorScheme,
          child: const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (e, _) => _SeriesAsyncShell(
          colorScheme: colorScheme,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(32, 80, 32, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_rounded,
                    size: 52,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Seri yüklenemedi',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    userFacingErrorMessage(
                      e,
                      fallback:
                          'Seri bilgisi alınamadı. Bağlantını kontrol edip tekrar dene.',
                    ),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.tonal(
                    onPressed: () =>
                        ref.refresh(seriesDetailProvider(seriesId)),
                    child: const Text('Tekrar Dene'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeriesAsyncShell extends StatelessWidget {
  const _SeriesAsyncShell({
    required this.colorScheme,
    required this.child,
  });

  final ColorScheme colorScheme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final pad = MediaQuery.paddingOf(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: colorScheme.surface, child: child),
        Positioned(
          top: pad.top + 6,
          left: 12,
          child: IconButton(
            onPressed: () => context.pop(),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.72),
              padding: EdgeInsets.zero,
              minimumSize: const Size(40, 40),
              maximumSize: const Size(40, 40),
            ),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookFallback extends StatelessWidget {
  final Color color;
  const _BookFallback({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 68,
      color: color.withValues(alpha: 0.12),
      child: const Center(child: Text('📖', style: TextStyle(fontSize: 22))),
    );
  }
}
