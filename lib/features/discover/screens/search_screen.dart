import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/theme/app_colors.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _ctrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchAsync = ref.watch(searchProvider(_query));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textSecondary = colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Kitap veya yazar ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: textSecondary),
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _query.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🔍', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 12),
                  Text(
                    'Kitap adı veya yazar ismi girin',
                    style: TextStyle(color: textSecondary, fontSize: 14),
                  ),
                ],
              ),
            )
          : searchAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📚', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 16),
                        Text(
                          'Sonuç bulunamadı',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Farklı anahtar kelimeler deneyin',
                          style: TextStyle(color: textSecondary, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (ctx, i) {
                    final book = books[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: book.coverImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: book.coverImageUrl!,
                                width: 44,
                                height: 58,
                                fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(
                                  color: AppColors.primary.withOpacity(0.1),
                                  child: const Center(child: Text('📖')),
                                ),
                              )
                            : Container(
                                width: 44,
                                height: 58,
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Center(child: Text('📖')),
                              ),
                      ),
                      title: Text(
                        book.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        book.author?.name ?? '',
                        style: TextStyle(color: textSecondary, fontSize: 13),
                      ),
                      onTap: () => context.push('/books/${book.slug}'),
                    );
                  },
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (_, __) => Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 48, color: textSecondary),
                    const SizedBox(height: 16),
                    Text(
                      'Arama başarısız',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'İnternet bağlantınızı kontrol edin',
                      style: TextStyle(color: textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
