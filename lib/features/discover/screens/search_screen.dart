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

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Kitap veya yazar ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: AppColors.lightTextSecondary),
          ),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _query.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔍', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('Kitap adı veya yazar ismi girin', style: TextStyle(color: AppColors.lightTextSecondary)),
                ],
              ),
            )
          : searchAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return const Center(child: Text('Sonuç bulunamadı.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: books.length,
                  itemBuilder: (ctx, i) {
                    final book = books[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: book.coverImageUrl != null
                            ? CachedNetworkImage(
                                imageUrl: book.coverImageUrl!,
                                width: 40,
                                height: 52,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 40,
                                height: 52,
                                color: AppColors.primary.withOpacity(0.1),
                                child: const Center(child: Text('📖')),
                              ),
                      ),
                      title: Text(book.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(book.author?.name ?? ''),
                      onTap: () => context.push('/books/${book.slug}'),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => const Center(child: Text('Arama başarısız.')),
            ),
    );
  }
}
