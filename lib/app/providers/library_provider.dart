import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/bookmark_model.dart';
import '../../core/models/favorite_model.dart';
import '../../core/services/bookmark_service.dart';
import '../../core/services/favorite_service.dart';

final favoriteServiceProvider = Provider<FavoriteService>((ref) {
  return FavoriteService();
});

final bookmarkServiceProvider = Provider<BookmarkService>((ref) {
  return BookmarkService();
});

final favoritesProvider = FutureProvider<List<FavoriteModel>>((ref) {
  return ref.read(favoriteServiceProvider).getFavorites();
});

final bookmarksProvider = FutureProvider<List<BookmarkModel>>((ref) {
  return ref.read(bookmarkServiceProvider).getBookmarks();
});
