import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/books_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/book_model.dart';
import '../../../features/subscription/widgets/premium_badge.dart';
import '../widgets/podcast_player_widget.dart';

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
                      const SizedBox(height: 24),
                      if (book.description != null &&
                          book.description!.isNotEmpty) ...[
                        _ContentCard(
                          title: 'Hakkında',
                          child: Text(
                            book.description!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.75,
                              color: textSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
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
                      _ActionCard(
                        bookId: book.id,
                        isPremiumBook: book.isPremium,
                        hasPremiumAccess: isPremium,
                        accentColor: accentColor,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

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
                if (book.description != null &&
                    book.description!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Text(
                      book.description!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 13.5,
                        height: 1.6,
                        color: colorScheme.onSurface.withValues(alpha: 0.84),
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

class _ActionCard extends StatelessWidget {
  final int bookId;
  final bool isPremiumBook;
  final bool hasPremiumAccess;
  final Color accentColor;

  const _ActionCard({
    required this.bookId,
    required this.isPremiumBook,
    required this.hasPremiumAccess,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final locked = isPremiumBook && !hasPremiumAccess;

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
            locked ? 'Bu eser premium kütüphanede yer alıyor' : 'Okumaya hazır',
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
                : 'Temiz bir okuma deneyimi için hikâye kartları ve podcast burada seni bekliyor.',
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
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
              label: const Text('Okumaya Başla'),
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

  const _MetaPill({required this.icon, required this.label});

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
          Icon(icon, size: 14, color: colorScheme.onSurface),
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
