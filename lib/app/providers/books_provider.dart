import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/book_model.dart';
import '../../core/models/category_model.dart';
import '../../core/models/paragraph_model.dart';
import '../../core/models/podcast_model.dart';
import '../../core/models/review_model.dart';
import '../../core/services/book_service.dart';
import '../../core/services/offline_cache_service.dart';
import '../../core/services/podcast_service.dart';
import '../../core/services/review_service.dart';
import 'kids_provider.dart';
import 'subscription_provider.dart';

final bookServiceProvider = Provider<BookService>((ref) => BookService());
final podcastServiceProvider = Provider<PodcastService>(
  (ref) => PodcastService(),
);
final offlineCacheServiceProvider = Provider<OfflineCacheService>(
  (ref) => OfflineCacheService(),
);
final reviewServiceProvider = Provider<ReviewService>((ref) => ReviewService());

final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) {
  final isKids = ref.watch(kidsModeProvider);
  return ref.read(bookServiceProvider).getCategories(isKids: isKids);
});

final homeQuickCategoriesProvider = FutureProvider<List<CategoryModel>>((
  ref,
) async {
  final isKids = ref.watch(kidsModeProvider);
  final service = ref.read(bookServiceProvider);

  final categoriesFuture = service.getCategories(isKids: isKids);
  final booksFuture = service.getBooks(isKids: isKids, perPage: 100);

  final categories = await categoriesFuture;
  final books = await booksFuture;
  final availableSlugs = books
      .map((book) => book.category?.slug)
      .whereType<String>()
      .toSet();

  return categories
      .where((category) => availableSlugs.contains(category.slug))
      .toList(growable: false);
});

final featuredBooksProvider = FutureProvider<List<BookModel>>((ref) {
  final isKids = ref.watch(kidsModeProvider);
  return ref.read(bookServiceProvider).getFeatured(isKids: isKids);
});

class BooksFilter {
  final String? category;
  final String? sort;
  final int page;
  final bool isKids;

  const BooksFilter({
    this.category,
    this.sort,
    this.page = 1,
    this.isKids = false,
  });

  @override
  bool operator ==(Object other) =>
      other is BooksFilter &&
      other.category == category &&
      other.sort == sort &&
      other.page == page &&
      other.isKids == isKids;

  @override
  int get hashCode => Object.hash(category, sort, page, isKids);
}

final booksProvider = FutureProvider.family<List<BookModel>, BooksFilter>((
  ref,
  filter,
) {
  return ref
      .read(bookServiceProvider)
      .getBooks(
        category: filter.category,
        sort: filter.sort,
        page: filter.page,
        perPage: 20,
        isKids: filter.isKids,
      );
});

final bookDetailProvider = FutureProvider.family<BookModel, String>((
  ref,
  slug,
) {
  return ref.read(bookServiceProvider).getBook(slug);
});

final searchProvider = FutureProvider.family<List<BookModel>, String>((
  ref,
  query,
) async {
  if (query.trim().isEmpty) return [];
  final books = await ref.read(bookServiceProvider).search(query);
  final isKids = ref.read(kidsModeProvider);
  if (isKids) {
    return books.where((b) => b.isKids).toList();
  }
  return books;
});

final podcastsProvider = FutureProvider.family<List<PodcastModel>, int>((
  ref,
  bookId,
) {
  return ref.read(podcastServiceProvider).getPodcasts(bookId);
});

final bookReviewsProvider = FutureProvider.family<List<ReviewModel>, int>((
  ref,
  bookId,
) async {
  final res = await ref.read(reviewServiceProvider).getReviews(bookId);
  final data = res['data']['data'] as List<dynamic>;
  return data.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>)).toList();
});

final downloadedBooksProvider = FutureProvider<List<BookModel>>((ref) async {
  final isPremium = ref.watch(isPremiumProvider);
  if (!isPremium) return const <BookModel>[];

  final isKids = ref.watch(kidsModeProvider);
  final books = await ref.read(offlineCacheServiceProvider).getCachedBooks();
  if (isKids) {
    return books.where((book) => book.isKids).toList(growable: false);
  }
  return books;
});

final bookCacheStatusProvider = FutureProvider.family<bool, int>((ref, bookId) {
  return ref.read(offlineCacheServiceProvider).hasCache(bookId);
});

class BookDownloadController extends StateNotifier<Set<int>> {
  final Ref _ref;

  BookDownloadController(this._ref) : super(const <int>{});

  bool isDownloading(int bookId) => state.contains(bookId);

  Future<int> downloadBook(int bookId, {BookModel? book}) async {
    if (state.contains(bookId)) return 0;

    state = {...state, bookId};
    try {
      final paragraphs = await _ref
          .read(bookServiceProvider)
          .getAllParagraphs(bookId);
      if (book != null) {
        await _ref.read(offlineCacheServiceProvider).cacheBook(book);
      }
      await _ref
          .read(offlineCacheServiceProvider)
          .cacheParagraphs(bookId, paragraphs);
      _ref.invalidate(bookCacheStatusProvider(bookId));
      _ref.invalidate(downloadedBooksProvider);
      _ref.invalidate(paragraphsProvider(bookId));
      return paragraphs.length;
    } finally {
      final next = {...state};
      next.remove(bookId);
      state = next;
    }
  }

  Future<void> removeDownload(int bookId) async {
    if (state.contains(bookId)) return;

    state = {...state, bookId};
    try {
      await _ref.read(offlineCacheServiceProvider).removeCachedBook(bookId);
      _ref.invalidate(bookCacheStatusProvider(bookId));
      _ref.invalidate(downloadedBooksProvider);
      _ref.invalidate(paragraphsProvider(bookId));
    } finally {
      final next = {...state};
      next.remove(bookId);
      state = next;
    }
  }
}

final bookDownloadControllerProvider =
    StateNotifierProvider<BookDownloadController, Set<int>>((ref) {
      return BookDownloadController(ref);
    });

final paragraphsProvider = FutureProvider.family<List<ParagraphModel>, int>((
  ref,
  bookId,
) async {
  final service = ref.read(bookServiceProvider);
  final cache = ref.read(offlineCacheServiceProvider);

  try {
    final paragraphs = await service.getAllParagraphs(bookId);
    final isPremium = ref.read(isPremiumProvider);
    if (isPremium) {
      await cache.cacheParagraphs(bookId, paragraphs);
      ref.invalidate(bookCacheStatusProvider(bookId));
    }
    return paragraphs;
  } catch (_) {
    final cached = await cache.getCachedParagraphs(bookId);
    if (cached.isNotEmpty) return cached;
    rethrow;
  }
});
