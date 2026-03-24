import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/character_provider.dart';
import '../../../app/providers/library_provider.dart';
import '../../../app/providers/progress_provider.dart';
import '../../../app/providers/series_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../features/subscription/widgets/premium_badge.dart';
import '../widgets/character_card_widget.dart';
import '../widgets/podcast_player_widget.dart';
import '../widgets/series_info_widget.dart';
import '../../../core/models/review_model.dart';

class BookDetailScreen extends ConsumerWidget {
  final String slug;

  const BookDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(slug));
    final isPremium = ref.watch(isPremiumProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textSecondary = colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: bookAsync.when(
        data: (book) {
          final podcastsAsync = ref.watch(podcastsProvider(book.id));
          final progressAsync = ref.watch(bookProgressProvider(book.id));
          final accentColor = _resolveAccentColor(book.category?.color);

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                toolbarHeight: 68,
                backgroundColor: colorScheme.surface.withValues(alpha: 0.94),
                surfaceTintColor: Colors.transparent,
                leadingWidth: 68,
                titleSpacing: 10,
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
                  book.title,
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
                      _BookHeroCard(
                        book: book,
                        accentColor: accentColor,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 16),
                      _BookActionStrip(book: book, accentColor: accentColor),
                      const SizedBox(height: 24),
                      progressAsync.when(
                        data: (progress) => Column(
                          children: [
                            _PrimaryReadingCard(
                              progress: progress,
                              bookId: book.id,
                              isPremiumBook: book.isPremium,
                              hasPremiumAccess: isPremium,
                              accentColor: accentColor,
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, error) => const SizedBox.shrink(),
                      ),
                      podcastsAsync.when(
                        data: (podcasts) => podcasts.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                children: [
                                  _ContentCard(
                                    title: null,
                                    padding: const EdgeInsets.all(18),
                                    child: PodcastSectionWidget(
                                      podcasts: podcasts,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                        loading: () => Column(
                          children: [
                            _ContentCard(
                              title: null,
                              padding: const EdgeInsets.all(18),
                              child: _PodcastSkeleton(isDark: isDark),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                        error: (_, error) => const SizedBox.shrink(),
                      ),

                      // Series info
                      if (book.seriesId != null)
                        ref
                            .watch(seriesDetailProvider(book.seriesId!))
                            .when(
                              data: (series) => Column(
                                children: [
                                  SeriesInfoWidget(
                                    series: series,
                                    currentBookOrder: book.seriesOrder,
                                    accentColor: accentColor,
                                  ),
                                  const SizedBox(height: 12),
                                  if (series.books.isNotEmpty) ...[
                                    SeriesBookListWidget(
                                      series: series,
                                      currentBookId: book.id,
                                      accentColor: accentColor,
                                    ),
                                    const SizedBox(height: 20),
                                  ],
                                ],
                              ),
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),

                      // Characters section
                      ref
                          .watch(charactersProvider(book.id))
                          .when(
                            data: (characters) => characters.isEmpty
                                ? const SizedBox.shrink()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Karakterler',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      SizedBox(
                                        height: 200,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemCount: characters.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 10),
                                          itemBuilder: (context, index) =>
                                              CharacterCardWidget(
                                                character: characters[index],
                                                accentColor: accentColor,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),

                      // Reviews section
                      ref
                          .watch(bookReviewsProvider(book.id))
                          .when(
                            data: (reviews) => reviews.isEmpty
                                ? const SizedBox.shrink()
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Değerlendirmeler',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.onSurface,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      ...reviews.map(
                                        (review) => Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          child: Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: colorScheme
                                                  .surfaceContainerHighest
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.04,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 12,
                                                      backgroundColor:
                                                          accentColor
                                                              .withOpacity(0.2),
                                                      backgroundImage:
                                                          review.userAvatarUrl !=
                                                              null
                                                          ? CachedNetworkImageProvider(
                                                              review
                                                                  .userAvatarUrl!,
                                                            )
                                                          : null,
                                                      child:
                                                          review.userAvatarUrl ==
                                                              null
                                                          ? Icon(
                                                              Icons.person,
                                                              size: 14,
                                                              color:
                                                                  accentColor,
                                                            )
                                                          : null,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      review.userName ??
                                                          'İsimsiz',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: colorScheme
                                                            .onSurface,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Row(
                                                      children: List.generate(
                                                        5,
                                                        (sIndex) => Icon(
                                                          sIndex < review.rating
                                                              ? Icons
                                                                    .star_rounded
                                                              : Icons
                                                                    .star_border_rounded,
                                                          size: 14,
                                                          color: const Color(
                                                            0xFFFFC107,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (review.comment != null &&
                                                    review
                                                        .comment!
                                                        .isNotEmpty) ...[
                                                  const SizedBox(height: 8),
                                                  Text(
                                                    review.comment!,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      height: 1.5,
                                                      color: colorScheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 20),
                                    ],
                                  ),
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () =>
            Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 52,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Kitap yüklenemedi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$e',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: () => ref.refresh(bookDetailProvider(slug)),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _resolveAccentColor(String? rawColor) {
  if (rawColor == null || rawColor.isEmpty) return AppColors.primary;

  try {
    return Color(int.parse(rawColor.replaceFirst('#', '0xFF')));
  } catch (_) {
    return AppColors.primary;
  }
}

class _BookHeroCard extends StatelessWidget {
  final BookModel book;
  final Color accentColor;
  final Color textSecondary;

  const _BookHeroCard({
    required this.book,
    required this.accentColor,
    required this.textSecondary,
  });

  String _getLanguageName(String code) {
    switch (code.toLowerCase()) {
      case 'tr':
        return 'Türkçe';
      case 'en':
        return 'İngilizce';
      case 'fr':
        return 'Fransızca';
      case 'de':
        return 'Almanca';
      case 'ru':
        return 'Rusça';
      default:
        return code.toUpperCase();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasDescription =
        book.description != null && book.description!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.24),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.92),
            colorScheme.surface.withValues(alpha: 0.98),
          ],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -40,
            right: -12,
            child: Container(
              width: 128,
              height: 128,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withValues(alpha: 0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _BookCover(
                      imageUrl: book.coverImageUrl,
                      title: book.title,
                      accentColor: accentColor,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (book.category != null)
                                _Chip(
                                  label: book.category!.name,
                                  color: accentColor,
                                ),
                              if (book.isPremium)
                                const PremiumBadge(
                                  size: PremiumBadgeSize.small,
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            book.title,
                            style: TextStyle(
                              fontSize: 28,
                              height: 1.1,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                              letterSpacing: -0.8,
                            ),
                          ),
                          if (book.author != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              book.author!.name,
                              style: TextStyle(
                                fontSize: 15,
                                color: textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (book.rating > 0)
                      _MetaPill(
                        icon: Icons.star_rounded,
                        label:
                            '${book.rating.toStringAsFixed(1)} (${book.reviewsCount})',
                        iconColor: const Color(0xFFFFC107),
                      ),
                    _MetaPill(
                      icon: Icons.language_rounded,
                      label: _getLanguageName(book.language),
                    ),
                    _MetaPill(
                      icon: Icons.auto_stories_outlined,
                      label: '${book.totalParagraphs} paragraf',
                    ),
                    if (book.estimatedReadMinutes != null)
                      _MetaPill(
                        icon: Icons.schedule_rounded,
                        label: '${book.estimatedReadMinutes} dk',
                      ),
                    _MetaPill(
                      icon: Icons.local_fire_department_outlined,
                      label: '${book.viewCount} okunma',
                    ),
                  ],
                ),
                if (hasDescription) ...[
                  const SizedBox(height: 18),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _showDescriptionModal(
                        context,
                        title: book.title,
                        author: book.author?.name,
                        description: book.description!,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.menu_book_rounded,
                                  size: 16,
                                  color: colorScheme.onSurface,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Hakkında',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.open_in_full_rounded,
                                  size: 16,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              book.description!,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                height: 1.6,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.84,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _showDescriptionModal(
  BuildContext context, {
  required String title,
  required String description,
  String? author,
}) {
  final colorScheme = Theme.of(context).colorScheme;

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (modalContext) {
      return SafeArea(
        top: false,
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.5,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.35,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Hakkında',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  if (author != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      author,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 15,
                          height: 1.8,
                          color: colorScheme.onSurface.withValues(alpha: 0.92),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    },
  );
}

class _BookCover extends StatelessWidget {
  final String? imageUrl;
  final String title;
  final Color accentColor;

  const _BookCover({
    required this.imageUrl,
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 108,
      height: 148,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: imageUrl != null
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (_, error, stackTrace) =>
                    _FallbackCover(title: title, accentColor: accentColor),
              )
            : _FallbackCover(title: title, accentColor: accentColor),
      ),
    );
  }
}

class _FallbackCover extends StatelessWidget {
  final String title;
  final Color accentColor;

  const _FallbackCover({required this.title, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.95),
            Colors.black.withValues(alpha: 0.88),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Align(
          alignment: Alignment.bottomLeft,
          child: Text(
            title,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              height: 1.05,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _ContentCard({
    required this.title,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            _SectionTitle(title!),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _PrimaryReadingCard extends StatelessWidget {
  final ProgressModel? progress;
  final int bookId;
  final bool isPremiumBook;
  final bool hasPremiumAccess;
  final Color accentColor;

  const _PrimaryReadingCard({
    required this.progress,
    required this.bookId,
    required this.isPremiumBook,
    required this.hasPremiumAccess,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locked = isPremiumBook && !hasPremiumAccess;
    final hasProgress = progress != null;
    final progressValue = ((progress?.completionPercentage ?? 0) / 100).clamp(
      0.0,
      1.0,
    );
    final lastParagraph = progress?.lastParagraphOrder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.16),
            colorScheme.surfaceContainerHighest.withValues(alpha: 0.42),
          ],
        ),
        border: Border.all(color: accentColor.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            locked
                ? 'Bu eser premium kütüphanede yer alıyor'
                : hasProgress
                ? 'Okumaya devam et'
                : 'Okumaya başla',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            locked
                ? 'Tüm bölümlere erişmek için premium üyelik açabilir ya da kısa önizleme ile başlayabilirsin.'
                : hasProgress
                ? lastParagraph != null
                      ? '$lastParagraph. paragraftan devam edebilirsin.'
                      : 'Kaldığın yer seni bekliyor.'
                : 'İlk paragraftan başlayıp hikâyeye hemen girebilirsin.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          if (!locked && hasProgress) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  '%${progress!.completionPercentage.toStringAsFixed(0)} tamamlandı',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                Text(
                  '${progress!.totalParagraphsRead} paragraf okundu',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accentColor),
              ),
            ),
          ],
          const SizedBox(height: 18),
          if (locked) ...[
            ElevatedButton.icon(
              onPressed: () => context.push('/premium'),
              icon: const Icon(Icons.workspace_premium_rounded, size: 20),
              label: const Text('Premium\'a Geç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFD35C),
                foregroundColor: Colors.black87,
                minimumSize: const Size(double.infinity, 56),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.push(
                '/read/$bookId',
                extra: {'isPremium': isPremiumBook},
              ),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Önizleme ile Başla'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                side: BorderSide(color: accentColor.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ] else
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/read/$bookId',
                extra: {'isPremium': isPremiumBook},
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 22),
              label: Text(hasProgress ? 'Okumaya Devam Et' : 'Okumaya Başla'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BookActionStrip extends ConsumerStatefulWidget {
  final BookModel book;
  final Color accentColor;

  const _BookActionStrip({required this.book, required this.accentColor});

  @override
  ConsumerState<_BookActionStrip> createState() => _BookActionStripState();
}

class _BookActionStripState extends ConsumerState<_BookActionStrip> {
  bool _isSubmitting = false;
  bool? _optimisticFavorite;
  bool _syncedDownloadedMetadata = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final authState = ref.watch(authProvider);
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? const [];
    final isDownloading = ref.watch(
      bookDownloadControllerProvider.select(
        (downloading) => downloading.contains(widget.book.id),
      ),
    );
    final isDownloaded =
        ref.watch(bookCacheStatusProvider(widget.book.id)).valueOrNull == true;
    final isPremium = ref.watch(isPremiumProvider);
    if (isDownloaded && !_syncedDownloadedMetadata && isPremium) {
      _syncedDownloadedMetadata = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await ref.read(offlineCacheServiceProvider).cacheBook(widget.book);
        ref.invalidate(downloadedBooksProvider);
      });
    }
    final isAuthenticated = authState.isAuthenticated;
    final isFavorite =
        _optimisticFavorite ??
        favorites.any((item) => item.bookId == widget.book.id);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: widget.accentColor.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isFavorite ? 'Favorilere eklendi' : 'Kitap işlemleri',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFavorite
                ? 'İstersen buradan paylaşabilir veya okumaya geçebilirsin.'
                : 'Kaydet ya da paylaş.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _isSubmitting
                      ? 'Kaydediliyor...'
                      : isFavorite
                      ? 'Favorilerde'
                      : 'Favoriye ekle',
                  accentColor: widget.accentColor,
                  emphasized: isFavorite,
                  onTap: _isSubmitting ? null : _toggleFavorite,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_outlined,
                  label: 'Paylaş',
                  accentColor: widget.accentColor,
                  emphasized: false,
                  onTap: _shareBook,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ActionButton(
            icon: isDownloaded
                ? Icons.delete_outline_rounded
                : isDownloading
                ? Icons.downloading_rounded
                : Icons.download_rounded,
            label: isDownloaded
                ? 'Cihazdan kaldır'
                : isDownloading
                ? 'Kitap indiriliyor...'
                : 'Cihaza indir ve Çevrimdışı oku',
            accentColor: widget.accentColor,
            emphasized: isDownloaded,
            onTap: isDownloading
                ? null
                : isDownloaded
                ? _removeDownload
                : _downloadBook,
          ),
          if (!isAuthenticated) ...[
            const SizedBox(height: 10),
            Text(
              'Favoriye eklemek için giriş yapman gerekiyor.',
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showPremiumRequiredForDownloadModal() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF171A17) : theme.cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 4,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: 64,
                height: 64,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
              Text(
                'Premium Özellik',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Kitapları cihazınıza indirip çevrimdışı okumak için Kitaplig Premium abonesi olmalısınız. İstediğiniz zaman, internete ihtiyaç duymadan okuma keyfini çıkarın!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  context.push('/premium');
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Premium\'u İncele',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Vazgeç',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadBook() async {
    final isPremium = ref.read(isPremiumProvider);
    if (!isPremium) {
      _showPremiumRequiredForDownloadModal();
      return;
    }

    try {
      final count = await ref
          .read(bookDownloadControllerProvider.notifier)
          .downloadBook(widget.book.id, book: widget.book);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            count > 0
                ? 'Kitap indirildi. Artık çevrimdışı da açılabilir.'
                : 'Bu kitap zaten indiriliyor.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'İndirme işlemi sırasında bir hata oluştu. Hesabınıza giriş yaptığınızdan emin olun.',
          ),
        ),
      );
    }
  }

  Future<void> _removeDownload() async {
    try {
      await ref
          .read(bookDownloadControllerProvider.notifier)
          .removeDownload(widget.book.id);
      _syncedDownloadedMetadata = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kitap cihazdan kaldırıldı.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaldırma tamamlanamadı: $error')));
    }
  }

  Future<void> _toggleFavorite() async {
    final authState = ref.read(authProvider);
    if (!authState.isAuthenticated) {
      if (!mounted) return;
      final returnTo = Uri.encodeComponent('/books/${widget.book.slug}');
      context.go('/login?returnTo=$returnTo');
      return;
    }

    final currentFavorite =
        _optimisticFavorite ??
        (ref.read(favoritesProvider).valueOrNull ?? const []).any(
          (item) => item.bookId == widget.book.id,
        );
    final nextFavorite = !currentFavorite;

    setState(() {
      _isSubmitting = true;
      _optimisticFavorite = nextFavorite;
    });

    try {
      final favorited = await ref
          .read(favoriteServiceProvider)
          .toggleFavorite(widget.book.id);
      ref.invalidate(favoritesProvider);
      if (!mounted) return;
      setState(() => _optimisticFavorite = favorited);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            favorited
                ? 'Kitap favorilerine eklendi.'
                : 'Kitap favorilerinden kaldırıldı.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _optimisticFavorite = currentFavorite);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favori işlemi şu anda tamamlanamadı.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _shareBook() {
    final author = widget.book.author?.name;
    final shareText = StringBuffer()
      ..writeln('${widget.book.title}${author != null ? ' - $author' : ''}')
      ..writeln()
      ..write('Kitaplig uygulamasında bu kitaba göz at: ${widget.book.title}');

    Share.share(shareText.toString(), subject: widget.book.title);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color accentColor;
  final bool emphasized;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.accentColor,
    required this.emphasized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: emphasized
          ? accentColor.withValues(alpha: 0.18)
          : colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: emphasized ? accentColor : colorScheme.onSurface,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: -0.2,
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? iconColor;

  const _MetaPill({required this.icon, required this.label, this.iconColor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: iconColor ?? colorScheme.onSurface),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _PodcastSkeleton extends StatelessWidget {
  final bool isDark;

  const _PodcastSkeleton({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final base = isDark ? Colors.white : Colors.black;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 18,
          width: 100,
          decoration: BoxDecoration(
            color: base.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(
          2,
          (i) => Container(
            height: 68,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: base.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}
