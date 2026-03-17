import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../features/subscription/widgets/premium_badge.dart';

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
    String loginPathForBook(int bookId) =>
        '/login?returnTo=${Uri.encodeComponent('/read/$bookId')}';

    return Scaffold(
      body: bookAsync.when(
        data: (book) => CustomScrollView(
          slivers: [
            // SliverAppBar with cover
            SliverAppBar(
              expandedHeight: 300,
              pinned: true,
              backgroundColor: AppColors.primary,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title & Author
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.author!.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        if (book.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Color(
                                int.parse(
                                  book.category!.color?.replaceFirst(
                                        '#',
                                        '0xFF',
                                      ) ??
                                      '0xFF2D6A4F',
                                ),
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              book.category!.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(
                                  int.parse(
                                    book.category!.color?.replaceFirst(
                                          '#',
                                          '0xFF',
                                        ) ??
                                        '0xFF2D6A4F',
                                  ),
                                ),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.auto_stories_outlined,
                          size: 14,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${book.totalParagraphs} paragraf',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        if (book.isPremium) ...[
                          const SizedBox(width: 12),
                          const PremiumBadge(size: PremiumBadgeSize.small),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    if (book.description != null &&
                        book.description!.isNotEmpty) ...[
                      Text(
                        'Hakkında',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.description!,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Read button — shows paywall CTA if premium book + non-premium user
                    if (book.isPremium && !isPremium) ...[
                      ElevatedButton.icon(
                        onPressed: () => context.push('/premium'),
                        icon: const Text('👑', style: TextStyle(fontSize: 18)),
                        label: const Text('Premium\'a Geç'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700),
                          foregroundColor: Colors.black87,
                          minimumSize: const Size(double.infinity, 52),
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
                          minimumSize: const Size(double.infinity, 44),
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
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Okumaya Başla'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
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
        ),
        loading: () => Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Kitap yüklenemedi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$e',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
