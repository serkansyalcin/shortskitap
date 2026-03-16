import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/theme/app_colors.dart';

class BookDetailScreen extends ConsumerWidget {
  final String slug;

  const BookDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookAsync = ref.watch(bookDetailProvider(slug));

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
                        errorWidget: (_, __, ___) => Container(color: AppColors.primary),
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
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (book.author != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.author!.name,
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    // Stats row
                    Row(
                      children: [
                        if (book.category != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(int.parse(
                                    book.category!.color?.replaceFirst('#', '0xFF') ?? '0xFF2D6A4F',
                                  )).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              book.category!.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(int.parse(
                                  book.category!.color?.replaceFirst('#', '0xFF') ?? '0xFF2D6A4F',
                                )),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(width: 12),
                        const Icon(Icons.auto_stories_outlined, size: 14, color: AppColors.lightTextSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${book.totalParagraphs} paragraf',
                          style: const TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
                        ),
                        if (book.isPremium) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              '👑 Premium',
                              style: TextStyle(fontSize: 11, color: Colors.purple),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Description
                    if (book.description != null && book.description!.isNotEmpty) ...[
                      const Text(
                        'Hakkında',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        book.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],

                    // Read button
                    ElevatedButton.icon(
                      onPressed: () => context.push('/read/${book.id}'),
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
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Hata: $e')),
      ),
    );
  }
}
