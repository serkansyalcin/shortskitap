import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/reading_list_model.dart';
import '../../core/services/reading_list_service.dart';
import 'auth_provider.dart';

final readingListServiceProvider = Provider<ReadingListService>((_) => ReadingListService());

final readingListBooksProvider = FutureProvider.autoDispose
    .family<List<ReadingListBookItem>, int>((ref, listId) async {
  return ref.read(readingListServiceProvider).getListBooks(listId);
});

final readingListsProvider = AsyncNotifierProvider<ReadingListsNotifier, List<ReadingListModel>>(
  ReadingListsNotifier.new,
);

class ReadingListsNotifier extends AsyncNotifier<List<ReadingListModel>> {
  ReadingListService get _svc => ref.read(readingListServiceProvider);

  @override
  Future<List<ReadingListModel>> build() async {
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated) return [];
    try {
      return await _svc.getLists();
    } catch (_) {
      return [];
    }
  }

  Future<void> create({required String name, String? description, bool isPublic = false}) async {
    final created = await _svc.createList(name: name, description: description, isPublic: isPublic);
    state = AsyncData([...state.valueOrNull ?? [], created]);
  }

  Future<void> delete(int listId) async {
    await _svc.deleteList(listId);
    state = AsyncData((state.valueOrNull ?? []).where((l) => l.id != listId).toList());
  }

  Future<void> addBook(int listId, int bookId) async {
    final updated = await _svc.addBook(listId, bookId);
    _replaceList(updated);
  }

  Future<void> removeBook(int listId, int bookId) async {
    final updated = await _svc.removeBook(listId, bookId);
    _replaceList(updated);
  }

  void _replaceList(ReadingListModel updated) {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.map((l) => l.id == updated.id ? updated : l).toList());
  }
}
