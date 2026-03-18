import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/book_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/paragraph_model.dart';
import '../../core/models/podcast_model.dart';
import '../../core/services/book_service.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/podcast_service.dart';

final bookServiceProvider = Provider<BookService>((ref) => BookService());
final podcastServiceProvider = Provider<PodcastService>((ref) => PodcastService());

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  return ref.read(bookServiceProvider).getCategories();
});

final featuredBooksProvider = FutureProvider<List<BookModel>>((ref) {
  return ref.read(bookServiceProvider).getFeatured();
});

class BooksFilter {
  final String? category;
  final String? sort;
  final int page;

  const BooksFilter({this.category, this.sort, this.page = 1});

  @override
  bool operator ==(Object other) =>
      other is BooksFilter &&
      other.category == category &&
      other.sort == sort &&
      other.page == page;

  @override
  int get hashCode => Object.hash(category, sort, page);
}

final booksProvider =
    FutureProvider.family<List<BookModel>, BooksFilter>((ref, filter) {
  return ref.read(bookServiceProvider).getBooks(
        category: filter.category,
        sort: filter.sort,
        page: filter.page,
      );
});

final bookDetailProvider =
    FutureProvider.family<BookModel, String>((ref, slug) {
  return ref.read(bookServiceProvider).getBook(slug);
});

final searchProvider =
    FutureProvider.family<List<BookModel>, String>((ref, query) {
  if (query.trim().isEmpty) return Future.value([]);
  return ref.read(bookServiceProvider).search(query);
});

final podcastsProvider =
    FutureProvider.family<List<PodcastModel>, int>((ref, bookId) {
  return ref.read(podcastServiceProvider).getPodcasts(bookId);
});

final paragraphsProvider =
    FutureProvider.family<List<ParagraphModel>, int>((ref, bookId) async {
  final service = ref.read(bookServiceProvider);
  final cache = OfflineCacheService();

  try {
    final paragraphs = await service.getParagraphs(bookId, limit: 200);
    await cache.cacheParagraphs(bookId, paragraphs);
    return paragraphs;
  } catch (_) {
    final cached = await cache.getCachedParagraphs(bookId);
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
});
