import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../features/subscription/widgets/premium_badge.dart';
import '../widgets/podcast_player_widget.dart';

class BookDetailScreen extends ConsumerWidget {
  final String slug;

  const BookDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(slug));
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    final isPremium = ref.watch(isPremiumProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textSecondary = colorScheme.onSurfaceVariant;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String loginPathForBook(int bookId) =>
        '/login?returnTo=${Uri.encodeComponent('/read/$bookId')}';

    return Scaffold(
      body: bookAsync.when(
        data: (book) {
          // Load podcasts once we have the book id
          final podcastsAsync = ref.watch(podcastsProvider(book.id));

          return CustomScrollView(
            slivers: [
              // ── Cover App Bar ─────────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: AppColors.primary,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => context.pop(),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (book.coverImageUrl != null)
                        CachedNetworkImage(
                          imageUrl: book.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) =>
                              Container(color: AppColors.primary),
                        )
                      else
                        Container(color: AppColors.primary),
                      // Gradient overlay
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.72),
                            ],
                            stops: const [0.45, 1.0],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Content ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        book.title,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.onSurface,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),

                      // Author
                      if (book.author != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          book.author!.name,
                          style: TextStyle(
                            fontSize: 15,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // ── Stats row ──────────────────────────────────────
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (book.category != null)
                            _Chip(
                              label: book.category!.name,
                              color: Color(
                                int.parse(
                                  book.category!.color?.replaceFirst('#', '0xFF') ??
                                      '0xFF2D6A4F',
                                ),
                              ),
                            ),
                          _InfoChip(
                            icon: Icons.auto_stories_outlined,
                            label: '${book.totalParagraphs} paragraf',
                            color: textSecondary,
                          ),
                          if (book.estimatedReadMinutes != null)
                            _InfoChip(
                              icon: Icons.timer_outlined,
                              label: '${book.estimatedReadMinutes} dk',
                              color: textSecondary,
                            ),
                          if (book.isPremium)
                            const PremiumBadge(size: PremiumBadgeSize.small),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // ── Description ────────────────────────────────────
                      if (book.description != null &&
                          book.description!.isNotEmpty) ...[
                        _SectionTitle('Hakkında'),
                        const SizedBox(height: 8),
                        Text(
                          book.description!,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.75,
                            color: textSecondary,
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],

                      // ── Podcast section ────────────────────────────────
                      podcastsAsync.when(
                        data: (podcasts) => podcasts.isEmpty
                            ? const SizedBox.shrink()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  PodcastSectionWidget(podcasts: podcasts),
                                  const SizedBox(height: 28),
                                ],
                              ),
                        loading: () => Padding(
                          padding: const EdgeInsets.only(bottom: 28),
                          child: _PodcastSkeleton(isDark: isDark),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      // ── Read CTA ───────────────────────────────────────
                      if (book.isPremium && !isPremium) ...[
                        ElevatedButton.icon(
                          onPressed: () => context.push('/premium'),
                          icon: const Text('👑', style: TextStyle(fontSize: 18)),
                          label: const Text('Premium\'a Geç'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700),
                            foregroundColor: Colors.black87,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: () => context.push(
                            '/read/${book.id}',
                            extra: {'isPremium': book.isPremium},
                          ),
                          icon: const Icon(Icons.preview_rounded),
                          label: const Text('Önizleme (3 paragraf)'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 46),
                            side: BorderSide(color: AppColors.primary.withOpacity(0.4)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ] else
                        ElevatedButton.icon(
                          onPressed: () => context.push(
                            '/read/${book.id}',
                            extra: {'isPremium': book.isPremium},
                          ),
                          icon: const Icon(Icons.play_arrow_rounded, size: 22),
                          label: const Text('Okumaya Başla'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            minimumSize: const Size(double.infinity, 54),
                            elevation: 0,
                            shadowColor: AppColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
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
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
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

// ─── Helper Widgets ────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
          letterSpacing: -0.2,
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.13),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      );
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
        Container(height: 18, width: 100, decoration: BoxDecoration(
          color: base.withOpacity(0.07), borderRadius: BorderRadius.circular(6),
        )),
        const SizedBox(height: 12),
        ...List.generate(2, (i) => Container(
          height: 68,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: base.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14),
          ),
        )),
      ],
    );
  }
}
