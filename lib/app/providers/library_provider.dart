import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/bookmark_model.dart';
import '../../core/models/favorite_model.dart';
import '../../core/models/highlight_model.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/services/favorite_service.dart';
import '../../core/services/highlight_service.dart';
import 'kids_provider.dart';

/// When set to true, [LibraryView] opens the "İndirilenler" segment once.
final libraryFocusDownloadsProvider = StateProvider<bool>((ref) => false);

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final highlightServiceProvider = Provider<HighlightService>((ref) {
  return HighlightService();
});

final favoritesProvider = FutureProvider<List<FavoriteModel>>((ref) {
  return ref.read(favoriteServiceProvider).getFavorites();
});

final bookmarksProvider = FutureProvider<List<BookmarkModel>>((ref) {
  return ref.read(bookmarkServiceProvider).getBookmarks();
});

class HighlightsListState {
  const HighlightsListState({
    required this.items,
    required this.total,
    required this.currentPage,
    required this.lastPage,
    this.isLoadingMore = false,
  });

  final List<HighlightModel> items;
  final int total;
  final int currentPage;
  final int lastPage;
  final bool isLoadingMore;

  bool get hasMore => currentPage < lastPage;

  HighlightsListState copyWith({
    List<HighlightModel>? items,
    int? total,
    int? currentPage,
    int? lastPage,
    bool? isLoadingMore,
  }) {
    return HighlightsListState(
      items: items ?? this.items,
      total: total ?? this.total,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class HighlightsListNotifier extends AsyncNotifier<HighlightsListState> {
  static const int _perPage = 30;

  @override
  Future<HighlightsListState> build() async {
    final kidsOnly = ref.watch(kidsModeProvider);
    final svc = ref.read(highlightServiceProvider);
    final page = await svc.fetchHighlightsPage(
      page: 1,
      perPage: _perPage,
      kidsOnly: kidsOnly,
    );
    return HighlightsListState(
      items: page.items,
      total: page.total,
      currentPage: page.currentPage,
      lastPage: page.lastPage,
    );
  }

  Future<void> loadMore() async {
    final cur = state.valueOrNull;
    if (cur == null || !cur.hasMore || cur.isLoadingMore) return;

    state = AsyncData(cur.copyWith(isLoadingMore: true));
    try {
      final kidsOnly = ref.read(kidsModeProvider);
      final svc = ref.read(highlightServiceProvider);
      final next = await svc.fetchHighlightsPage(
        page: cur.currentPage + 1,
        perPage: _perPage,
        kidsOnly: kidsOnly,
      );
      state = AsyncData(
        HighlightsListState(
          items: [...cur.items, ...next.items],
          total: next.total,
          currentPage: next.currentPage,
          lastPage: next.lastPage,
        ),
      );
    } catch (e, st) {
      state = AsyncData(cur.copyWith(isLoadingMore: false));
      Error.throwWithStackTrace(e, st);
    }
  }

  Future<void> removeHighlight(int id) async {
    final cur = state.valueOrNull;
    if (cur == null) return;
    await ref.read(highlightServiceProvider).deleteHighlight(id);
    final nextItems = cur.items.where((h) => h.id != id).toList(growable: false);
    final nextTotal = cur.total > 0 ? cur.total - 1 : 0;
    state = AsyncData(
      cur.copyWith(items: nextItems, total: nextTotal),
    );
  }
}

final highlightsProvider =
    AsyncNotifierProvider<HighlightsListNotifier, HighlightsListState>(
  HighlightsListNotifier.new,
);
