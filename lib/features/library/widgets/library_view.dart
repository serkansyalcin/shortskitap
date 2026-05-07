import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/kids_provider.dart';
import '../../../app/providers/library_provider.dart';
import '../../../app/providers/progress_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/favorite_model.dart';
import '../../../core/models/highlight_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../core/widgets/animated_segmented_control.dart';
import '../../ai_story/ai_story_strings.dart';
import '../../ai_story/providers/ai_story_provider.dart';
import '../../ai_story/widgets/ai_story_preview_card.dart';
import '../../../app/providers/home_shell_provider.dart';
import '../../../app/providers/reading_list_provider.dart';
import '../../../core/models/reading_list_model.dart';

enum _LibraryMode {
  overview,
  reading,
  completed,
  downloaded,
  favorites,
  highlights,
  aiStories,
  lists,
}

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView> {
  _LibraryMode _mode = _LibraryMode.overview;
  String? _aiStoryVisibilityFilter;

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(libraryFocusDownloadsProvider, (previous, next) {
      if (next == true && mounted) {
        setState(() => _mode = _LibraryMode.downloaded);
        ref.read(libraryFocusDownloadsProvider.notifier).state = false;
      }
    });

    final authState = ref.watch(authProvider);
    if (authState.status == AuthStatus.unknown) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final readingListsAsync = ref.watch(readingListsProvider);
    final progressAsync = ref.watch(allProgressProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final highlightsAsync = ref.watch(highlightsProvider);
    final downloadedAsync = ref.watch(downloadedBooksProvider);
    final myAiStoriesAsync = ref.watch(
      myAiStoriesProvider(_aiStoryVisibilityFilter),
    );
    final isKidsMode = ref.watch(kidsModeProvider);

    final rawProgress = progressAsync.valueOrNull ?? const <ProgressModel>[];
    final rawFavorites = favoritesAsync.valueOrNull ?? const <FavoriteModel>[];
    final rawHighlights =
        highlightsAsync.valueOrNull?.items ?? const <HighlightModel>[];

    final allProgress = isKidsMode
        ? rawProgress
              .where((p) => p.book?.isKids == true)
              .toList(growable: false)
        : rawProgress;
    final activeProgress = allProgress
        .where((item) => !item.isCompleted)
        .toList(growable: false);
    final completedProgress = allProgress
        .where((item) => item.isCompleted)
        .toList(growable: false);
    final favorites = isKidsMode
        ? rawFavorites
              .where((f) => f.book?.isKids == true)
              .toList(growable: false)
        : rawFavorites;
    final highlights = isKidsMode
        ? rawHighlights
              .where((h) => h.book?.isKids == true)
              .toList(growable: false)
        : rawHighlights;
    final downloadedBooks = downloadedAsync.valueOrNull ?? const <BookModel>[];
    final myAiStories = myAiStoriesAsync.valueOrNull ?? const <BookModel>[];

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _LibraryHero(
              progressAsync: progressAsync,
              favoritesAsync: favoritesAsync,
              highlightsAsync: highlightsAsync,
              downloadedAsync: downloadedAsync,
              filteredCounts: isKidsMode
                  ? (
                      started: allProgress.length,
                      progress: activeProgress.length,
                      completed: completedProgress.length,
                      downloaded: downloadedBooks.length,
                      favorites: favorites.length,
                      highlights:
                          highlightsAsync.valueOrNull?.total ??
                          highlights.length,
                    )
                  : null,
            ),
            const SizedBox(height: 14),
            AnimatedSegmentedControl<_LibraryMode>(
              selected: _mode,
              onChanged: (value) => setState(() => _mode = value),
              isScrollable: true,
              items: const [
                SegmentedItem(
                  value: _LibraryMode.overview,
                  label: 'Genel',
                  icon: Icons.dashboard_rounded,
                ),
                SegmentedItem(
                  value: _LibraryMode.reading,
                  label: 'Devam',
                  icon: Icons.auto_stories_rounded,
                ),
                SegmentedItem(
                  value: _LibraryMode.completed,
                  label: 'Biten',
                  icon: Icons.verified_rounded,
                ),
                SegmentedItem(
                  value: _LibraryMode.downloaded,
                  label: 'İndirilen',
                  icon: Icons.download_done_rounded,
                ),
                SegmentedItem(
                  value: _LibraryMode.favorites,
                  label: 'Favori',
                  icon: Icons.favorite_rounded,
                ),
                SegmentedItem(
                  value: _LibraryMode.highlights,
                  label: 'Alıntı',
                  icon: Icons.bookmark_rounded,
                ),
                SegmentedItem(
                  value: _LibraryMode.aiStories,
                  label: 'AI Hikâye',
                  icon: Icons.auto_awesome_rounded,
                ),
                SegmentedItem(
                  value: _LibraryMode.lists,
                  label: 'Listeler',
                  icon: Icons.playlist_add_check_rounded,
                ),
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              layoutBuilder: (currentChild, previousChildren) => Stack(
                fit: StackFit.passthrough,
                alignment: Alignment.topCenter,
                children: [
                  ...previousChildren,
                  ?currentChild,
                ],
              ),
              child: KeyedSubtree(
                key: ValueKey(_mode),
                child: _mode == _LibraryMode.lists
                    ? _ReadingListsContent(
                        listsAsync: readingListsAsync,
                        onCreateList: () async {
                          final name = await _showCreateListDialog(context);
                          if (name == null || name.trim().isEmpty) return;
                          await ref
                              .read(readingListsProvider.notifier)
                              .create(name: name.trim());
                        },
                        onDeleteList: (id) =>
                            ref.read(readingListsProvider.notifier).delete(id),
                      )
                    : _LibraryModeContent(
                  mode: _mode,
                  onRetryProgress: () => ref.invalidate(allProgressProvider),
                  onRetryFavorites: () => ref.invalidate(favoritesProvider),
                  onRetryHighlights: () => ref.invalidate(highlightsProvider),
                  onRetryAiStories: () => ref.invalidate(
                    myAiStoriesProvider(_aiStoryVisibilityFilter),
                  ),
                  onOpenHighlightsTab: () =>
                      setState(() => _mode = _LibraryMode.highlights),
                  onGoToDiscover: () =>
                      ref.read(homeTabRequestProvider.notifier).state = 1,
                  onAiStoryFilterChanged: (value) {
                    setState(() => _aiStoryVisibilityFilter = value);
                  },
                  onLoadMoreHighlights: () async {
                    try {
                      await ref.read(highlightsProvider.notifier).loadMore();
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(userFacingErrorMessage(e))),
                      );
                    }
                  },
                  progressAsync: progressAsync,
                  favoritesAsync: favoritesAsync,
                  highlightsAsync: highlightsAsync,
                  downloadedAsync: downloadedAsync,
                  aiStoriesAsync: myAiStoriesAsync,
                  aiStoryVisibilityFilter: _aiStoryVisibilityFilter,
                  allProgress: allProgress,
                  activeProgress: activeProgress,
                  completedProgress: completedProgress,
                  downloadedBooks: downloadedBooks,
                  favorites: favorites,
                  highlights: highlights,
                  myAiStories: myAiStories,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _showCreateListDialog(BuildContext context) {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni okuma listesi'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(hintText: 'Liste adı'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _ReadingListsContent extends StatelessWidget {
  const _ReadingListsContent({
    required this.listsAsync,
    required this.onCreateList,
    required this.onDeleteList,
  });

  final AsyncValue<List<ReadingListModel>> listsAsync;
  final VoidCallback onCreateList;
  final ValueChanged<int> onDeleteList;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Okuma Listelerim',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: onCreateList,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Yeni liste'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        listsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 48),
            child: Align(
              heightFactor: 1,
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Text(
              userFacingErrorMessage(e, fallback: 'Listeler yüklenemedi.'),
              style: TextStyle(color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
          data: (lists) {
            if (lists.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.playlist_add_rounded,
                      size: 56,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz listeniz yok',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Kitap detay sayfasından kitapları\nlistelerinize ekleyebilirsiniz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: onCreateList,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('İlk listenizi oluşturun'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: lists.map((list) => _ReadingListTile(
                list: list,
                isDark: isDark,
                onTap: () => _ReadingListDetailSheet.show(context, list),
                onDelete: () => _confirmDelete(context, list, onDeleteList),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    ReadingListModel list,
    ValueChanged<int> onDelete,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Listeyi sil'),
        content: Text('"${list.name}" listesini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              minimumSize: const Size(80, 44),
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) onDelete(list.id);
  }
}

class _ReadingListTile extends StatelessWidget {
  const _ReadingListTile({
    required this.list,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final ReadingListModel list;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover strip
            if (list.previewCovers.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: Row(
                    children: list.previewCovers.take(4).map((book) {
                      return Expanded(
                        child: book.coverUrl != null
                            ? Image.network(
                                book.coverUrl!,
                                fit: BoxFit.cover,
                                height: 80,
                                errorBuilder: (_, _, _) => _coverPlaceholder(scheme),
                              )
                            : _coverPlaceholder(scheme),
                      );
                    }).toList(),
                  ),
                ),
              )
            else
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                child: SizedBox(
                  height: 60,
                  width: double.infinity,
                  child: ColoredBox(
                    color: AppColors.primary.withValues(alpha: isDark ? 0.12 : 0.08),
                    child: const Icon(Icons.playlist_play_rounded, size: 32, color: AppColors.primary),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                list.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: scheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (list.isPublic)
                              Padding(
                                padding: const EdgeInsets.only(left: 6),
                                child: Icon(
                                  Icons.public_rounded,
                                  size: 14,
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${list.bookCount} kitap',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, size: 20),
                    color: const Color(0xFFDC2626),
                    onPressed: onDelete,
                    tooltip: 'Listeyi sil',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
        ),
      ),
    );
  }

  Widget _coverPlaceholder(ColorScheme scheme) => ColoredBox(
        color: scheme.surfaceContainerHighest,
        child: const SizedBox.expand(
          child: Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 20),
        ),
      );
}

class _ReadingListDetailSheet extends ConsumerWidget {
  const _ReadingListDetailSheet({required this.list});

  final ReadingListModel list;

  static void show(BuildContext context, ReadingListModel list) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => _ReadingListDetailSheet(list: list),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final booksAsync = ref.watch(readingListBooksProvider(list.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        list.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: scheme.onSurface,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${list.bookCount} kitap',
                            style: TextStyle(
                              fontSize: 13,
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (list.isPublic) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.public_rounded, size: 11, color: AppColors.primary),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Herkese açık',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Books list
          Expanded(
            child: booksAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Kitaplar yüklenemedi.',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (books) {
                if (books.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.playlist_add_rounded,
                            size: 56,
                            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Bu listede henüz kitap yok',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: books.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final book = books[i];
                    return _ReadingListBookCard(book: book);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ReadingListBookCard extends StatelessWidget {
  const _ReadingListBookCard({required this.book});

  final ReadingListBookItem book;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.push('/books/${book.slug}');
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
          ),
          child: Row(
            children: [
              // Cover
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: book.coverUrl != null
                    ? Image.network(
                        book.coverUrl!,
                        width: 52,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _placeholder(),
                      )
                    : _placeholder(),
              ),
              const SizedBox(width: 14),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (book.categoryName != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          book.categoryName!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    Text(
                      book.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (book.authorName != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        book.authorName!,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: scheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        width: 52,
        height: 72,
        decoration: const BoxDecoration(
          color: Color(0xFF2A2A2A),
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: const Icon(Icons.auto_stories_rounded, color: AppColors.primary, size: 22),
      );
}

class _LibraryModeContent extends StatelessWidget {
  final _LibraryMode mode;
  final VoidCallback onRetryProgress;
  final VoidCallback onRetryFavorites;
  final VoidCallback onRetryHighlights;
  final VoidCallback onRetryAiStories;
  final VoidCallback onOpenHighlightsTab;
  final VoidCallback onGoToDiscover;
  final ValueChanged<String?> onAiStoryFilterChanged;
  final Future<void> Function() onLoadMoreHighlights;
  final AsyncValue<List<ProgressModel>> progressAsync;
  final AsyncValue<List<FavoriteModel>> favoritesAsync;
  final AsyncValue<HighlightsListState> highlightsAsync;
  final AsyncValue<List<BookModel>> downloadedAsync;
  final AsyncValue<List<BookModel>> aiStoriesAsync;
  final String? aiStoryVisibilityFilter;
  final List<ProgressModel> allProgress;
  final List<ProgressModel> activeProgress;
  final List<ProgressModel> completedProgress;
  final List<BookModel> downloadedBooks;
  final List<FavoriteModel> favorites;
  final List<HighlightModel> highlights;
  final List<BookModel> myAiStories;

  const _LibraryModeContent({
    required this.mode,
    required this.onRetryProgress,
    required this.onRetryFavorites,
    required this.onRetryHighlights,
    required this.onRetryAiStories,
    required this.onOpenHighlightsTab,
    required this.onGoToDiscover,
    required this.onAiStoryFilterChanged,
    required this.onLoadMoreHighlights,
    required this.progressAsync,
    required this.favoritesAsync,
    required this.highlightsAsync,
    required this.downloadedAsync,
    required this.aiStoriesAsync,
    required this.aiStoryVisibilityFilter,
    required this.allProgress,
    required this.activeProgress,
    required this.completedProgress,
    required this.downloadedBooks,
    required this.favorites,
    required this.highlights,
    required this.myAiStories,
  });

  @override
  Widget build(BuildContext context) {
    final progressForMode = switch (mode) {
      _LibraryMode.reading => activeProgress,
      _LibraryMode.completed => completedProgress,
      _ => allProgress,
    };
    final modeSummary = switch (mode) {
      _LibraryMode.overview =>
        'Tüm raflarını tek ekranda gör, kaldığın yerden devam et.',
      _LibraryMode.reading =>
        'Su an aktif okuduğun kitaplar ve son ilerlemen burada.',
      _LibraryMode.completed =>
        'Bitirdiğin kitapların arşivi ve yeniden dönuş rafın.',
      _LibraryMode.downloaded =>
        'Cihazına indirdiğin kitaplar burada, internet olmasa da elinin altında.',
      _LibraryMode.favorites =>
        'Gözunun önunde tutmak istediğin kitapların kısayolu.',
      _LibraryMode.highlights =>
        'Kaydettiğin notlar ve dönmek istedigin alıntılar burada.',
      _LibraryMode.aiStories =>
        'AI ile ürettiğin hikâyeleri özel veya paylaşılan olarak yönet.',
      _LibraryMode.lists =>
        'Oluşturduğun okuma listeleri ve kitapları burada.',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ModeSummaryPill(summary: modeSummary),
        const SizedBox(height: 18),
        if (mode == _LibraryMode.overview ||
            mode == _LibraryMode.reading ||
            mode == _LibraryMode.completed) ...[
          _SectionTitle(
            title: switch (mode) {
              _LibraryMode.reading => 'Devam Edenler',
              _LibraryMode.completed => 'Tamamlananlar',
              _ => 'Okumaya Devam Et',
            },
            subtitle: switch (mode) {
              _LibraryMode.reading =>
                'Henüz bitirmediğin kitapları kaldığın yerden sürdür.',
              _LibraryMode.completed =>
                'Bitirdiğin kitapları tekrar ziyaret et veya yeniden keşfet.',
              _ =>
                'Yarım bıraktığın kitapları tek yerden sürdür.',
            },
          ),
          const SizedBox(height: 10),
          progressAsync.when(
            loading: () => const _LibraryLoadingCard(height: 186),
            error: (_, stackTrace) => _LibraryErrorCard(
              title: 'Okuma ilerlemesi alınamadı',
              buttonLabel: 'Tekrar dene',
              onPressed: onRetryProgress,
            ),
            data: (_) {
              if (progressForMode.isEmpty) {
                return _EmptyPanel(
                  icon: mode == _LibraryMode.completed
                      ? Icons.verified_rounded
                      : Icons.auto_stories_rounded,
                  title: mode == _LibraryMode.completed
                      ? 'Henüz tamamlanan kitabın yok'
                      : 'Kütüphanen burada büyüyecek',
                  subtitle: mode == _LibraryMode.completed
                      ? 'Bir kitabı bitirdiğinde burada ayrı bir raf olarak göreceksin.'
                      : 'İlk kitabını seçtiğinde okuma ilerlemen, favorilerin ve notların bu alanda toplanacak.',
                  actionLabel: 'Keşfet ekranına git',
                  onTap: onGoToDiscover,
                );
              }

              return SizedBox(
                height: 186,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: progressForMode.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 14),
                  itemBuilder: (context, index) => SizedBox(
                    width: 280,
                    child: _ProgressCard(progress: progressForMode[index]),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (mode == _LibraryMode.overview ||
            mode == _LibraryMode.downloaded) ...[
          const _SectionTitle(
            title: 'İndirilenler',
            subtitle:
                'Cihazına kaydettiğin kitaplara hızlıca ulaş.',
          ),
          const SizedBox(height: 10),
          downloadedAsync.when(
            loading: () => const _LibraryLoadingCard(height: 140),
            error: (_, stackTrace) => const _InlineInfoCard(
              title: 'İndirilen kitaplar yüklenemedi',
              subtitle: 'Yerel kütüphane birazdan tekrar denenebilir.',
            ),
            data: (_) {
              if (downloadedBooks.isEmpty) {
                return const _InlineInfoCard(
                  title: 'Henüz indirilen kitap yok',
                  subtitle: 'Bir kitabı indirdiginde burada göreceksin.',
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: downloadedBooks
                    .take(mode == _LibraryMode.downloaded ? 18 : 6)
                    .map((book) => _DownloadedBookCard(book: book))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (mode == _LibraryMode.overview ||
            mode == _LibraryMode.favorites) ...[
          const _SectionTitle(
            title: 'Favorilerin',
            subtitle: 'Sonradan dönmek istediğin kitaplar.',
          ),
          const SizedBox(height: 10),
          favoritesAsync.when(
            loading: () => const _LibraryLoadingCard(height: 140),
            error: (_, stackTrace) => const _InlineInfoCard(
              title: 'Favoriler yüklenemedi',
              subtitle:
                  'Bağlantını kontrol edip tekrar deneyebilirsin.',
            ),
            data: (_) {
              if (favorites.isEmpty) {
                return const _InlineInfoCard(
                  title: 'Henüz favori kitabın yok',
                  subtitle:
                      'Bir kitabı favorilere eklediğinde burada hızlı erişim kartı olarak göreceksin.',
                );
              }

              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: favorites
                    .take(mode == _LibraryMode.favorites ? 12 : 6)
                    .map((favorite) => _FavoriteChip(favorite: favorite))
                    .toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
        if (mode == _LibraryMode.overview ||
            mode == _LibraryMode.highlights) ...[
          const _SectionTitle(
            title: 'Kaydettiğin Alıntılar',
            subtitle:
                'İşaretlediğin paragraflara hızlıca geri dön.',
          ),
          const SizedBox(height: 10),
          highlightsAsync.when(
            loading: () => const _LibraryLoadingCard(height: 220),
            error: (_, stackTrace) => _LibraryErrorCard(
              title: 'Kaydedilen alıntılar yüklenemedi',
              buttonLabel: 'Tekrar dene',
              onPressed: onRetryHighlights,
            ),
            data: (hlState) {
              if (highlights.isEmpty) {
                return const _InlineInfoCard(
                  title: 'Henüz kayıtlı alıntın yok',
                  subtitle:
                      'Okurken bir paragrafı kaydettiğinde burada notlarınla birlikte görünecek.',
                );
              }

              final overviewPreview = mode == _LibraryMode.overview;
              final previewCap = 6;
              final displayCount = overviewPreview
                  ? (highlights.length < previewCap
                        ? highlights.length
                        : previewCap)
                  : highlights.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...List.generate(
                    displayCount,
                    (index) => Padding(
                      padding: EdgeInsets.only(
                        bottom: index == displayCount - 1 ? 0 : 12,
                      ),
                      child: _HighlightCard(highlight: highlights[index]),
                    ),
                  ),
                  if (overviewPreview && hlState.total > displayCount) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Toplam ${hlState.total} alıntı kayıtlı. Hepsini görmek için Alıntı sekmesine geçebilirsin.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: onOpenHighlightsTab,
                        child: const Text('Alıntıları aç'),
                      ),
                    ),
                  ],
                  if (mode == _LibraryMode.highlights) ...[
                    if (hlState.isLoadingMore)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    else if (hlState.hasMore)
                      TextButton.icon(
                        onPressed: () => onLoadMoreHighlights(),
                        icon: const Icon(Icons.expand_more_rounded),
                        label: const Text('Daha fazla yükle'),
                      ),
                  ],
                ],
              );
            },
          ),
        ],
        if (mode == _LibraryMode.overview || mode == _LibraryMode.aiStories) ...[
          const SizedBox(height: 24),
          const _SectionTitle(
            title: AiStoryStrings.myStoriesTitle,
            subtitle: 'Ürettiğin AI hikâyeleri burada bulabilirsin.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AiFilterChip(
                label: AiStoryStrings.allFilter,
                selected: aiStoryVisibilityFilter == null,
                onTap: () => onAiStoryFilterChanged(null),
              ),
              _AiFilterChip(
                label: AiStoryStrings.privateFilter,
                selected: aiStoryVisibilityFilter == 'private',
                onTap: () => onAiStoryFilterChanged('private'),
              ),
              _AiFilterChip(
                label: AiStoryStrings.publicFilter,
                selected: aiStoryVisibilityFilter == 'public',
                onTap: () => onAiStoryFilterChanged('public'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          aiStoriesAsync.when(
            loading: () => const _LibraryLoadingCard(height: 180),
            error: (_, stackTrace) => _LibraryErrorCard(
              title: 'AI hikâyeler yüklenemedi',
              buttonLabel: 'Tekrar dene',
              onPressed: onRetryAiStories,
            ),
            data: (_) {
              if (myAiStories.isEmpty) {
                return const _InlineInfoCard(
                  title: AiStoryStrings.myStoriesTitle,
                  subtitle: AiStoryStrings.emptyMyStories,
                );
              }

              return Column(
                children: myAiStories
                    .map(
                      (book) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AiStoryPreviewCard(book: book),
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
        ],
      ],
    );
  }
}

class _LibraryHero extends StatelessWidget {
  final AsyncValue<List<ProgressModel>> progressAsync;
  final AsyncValue<List<FavoriteModel>> favoritesAsync;
  final AsyncValue<HighlightsListState> highlightsAsync;
  final AsyncValue<List<BookModel>> downloadedAsync;
  final ({
    int started,
    int progress,
    int completed,
    int downloaded,
    int favorites,
    int highlights,
  })?
  filteredCounts;

  const _LibraryHero({
    required this.progressAsync,
    required this.favoritesAsync,
    required this.highlightsAsync,
    required this.downloadedAsync,
    this.filteredCounts,
  });

  @override
  Widget build(BuildContext context) {
    final startedCount =
        filteredCounts?.started ?? progressAsync.valueOrNull?.length ?? 0;
    final progressCount =
        filteredCounts?.progress ??
        progressAsync.valueOrNull?.where((item) => !item.isCompleted).length ??
        0;
    final completedCount =
        filteredCounts?.completed ??
        progressAsync.valueOrNull?.where((item) => item.isCompleted).length ??
        0;
    final downloadedCount =
        filteredCounts?.downloaded ?? downloadedAsync.valueOrNull?.length ?? 0;
    final favoritesCount =
        filteredCounts?.favorites ?? favoritesAsync.valueOrNull?.length ?? 0;
    final highlightsCount =
        filteredCounts?.highlights ??
        highlightsAsync.valueOrNull?.total ??
        highlightsAsync.valueOrNull?.items.length ??
        0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.75),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.library_books_rounded,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Kütüphanen',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Okuma düzenin tek bakışta',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Devam ettiğin kitaplar, favorilerin ve kaydettiğin alıntılar burada bir arada.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _StatPill(label: 'Başlanan', value: '$startedCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(label: 'Aktif okuma', value: '$progressCount'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatPill(label: 'Biten', value: '$completedCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  label: 'İndirilen',
                  value: '$downloadedCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatPill(label: 'Favori', value: '$favoritesCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(
                  label: 'Alıntı',
                  value: '$highlightsCount',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final String value;

  const _StatPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.7),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeSummaryPill extends StatelessWidget {
  final String summary;

  const _ModeSummaryPill({required this.summary});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(
              Icons.tune_rounded,
              size: 16,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final ProgressModel progress;

  const _ProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final book = progress.book;
    if (book == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => context.push('/read/${progress.bookId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          children: [
            _BookCover(
              imageUrl: book.coverImageUrl,
              width: 88,
              height: 128,
              radius: 18,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (book.category != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        book.category!.name,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),
                  Text(
                    book.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      height: 1.2,
                    ),
                  ),
                  const Spacer(),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress.completionPercentage / 100,
                      minHeight: 7,
                      backgroundColor: theme.colorScheme.outline.withValues(
                        alpha: 0.45,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress.isCompleted ? Colors.green : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress.isCompleted
                        ? 'Tamamlandı'
                        : '%${progress.completionPercentage.toStringAsFixed(0)} tamamlandı',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FavoriteChip extends StatelessWidget {
  final FavoriteModel favorite;

  const _FavoriteChip({required this.favorite});

  @override
  Widget build(BuildContext context) {
    final book = favorite.book;
    if (book == null) return const SizedBox.shrink();
    final theme = Theme.of(context);

    return InkWell(
      onTap: () => context.push('/books/${book.slug}'),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BookCover(
              imageUrl: book.coverImageUrl,
              width: 42,
              height: 58,
              radius: 12,
            ),
            const SizedBox(width: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 170),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Favori kitap',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadedBookCard extends ConsumerWidget {
  final BookModel book;

  const _DownloadedBookCard({required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isProcessing = ref.watch(
      bookDownloadControllerProvider.select(
        (downloading) => downloading.contains(book.id),
      ),
    );

    return InkWell(
      onTap: () => context.push(
        '/read/${book.id}',
        extra: {'isPremium': book.isPremium},
      ),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.75),
          ),
        ),
        child: Row(
          children: [
            _BookCover(
              imageUrl: book.coverImageUrl,
              width: 56,
              height: 78,
              radius: 14,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Çevrimdışı hazır',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: isProcessing
                            ? null
                            : () => _removeDownload(context, ref),
                        borderRadius: BorderRadius.circular(999),
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: isProcessing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.accent,
                                  ),
                                )
                              : Icon(
                                  Icons.delete_outline_rounded,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.author?.name ?? 'Hazır indirilen kitap',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeDownload(BuildContext context, WidgetRef ref) async {
    try {
      await ref
          .read(bookDownloadControllerProvider.notifier)
          .removeDownload(book.id);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${book.title} cihazdan kaldırıldı.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingErrorMessage(
              error,
              fallback:
                  'Kaldırma tamamlanamadı. Bağlantını kontrol edip tekrar dene.',
            ),
          ),
        ),
      );
    }
  }
}

class _HighlightCard extends StatelessWidget {
  final HighlightModel highlight;

  const _HighlightCard({required this.highlight});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = highlight.text.trim().isNotEmpty
        ? highlight.text.trim()
        : highlight.note?.trim() ?? '';
    final note = highlight.note?.trim();
    final book = highlight.book;
    Color accent = AppColors.accent;
    try {
      if (highlight.color != null && highlight.color!.isNotEmpty) {
        accent = Color(int.parse(highlight.color!.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.bookmark_added_rounded, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  book?.title ?? 'Kaydedilen alıntı',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            excerpt.isEmpty ? 'Not veya paragraf bulunamadi.' : excerpt,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.6,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (note != null && note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              note,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookCover extends StatelessWidget {
  final String? imageUrl;
  final double width;
  final double height;
  final double radius;

  const _BookCover({
    required this.imageUrl,
    required this.width,
    required this.height,
    required this.radius,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: imageUrl != null
          ? CachedNetworkImage(
              imageUrl: imageUrl!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              errorWidget: (_, error, stackTrace) =>
                  _BookCoverFallback(width: width, height: height),
            )
          : _BookCoverFallback(width: width, height: height),
    );
  }
}

class _BookCoverFallback extends StatelessWidget {
  final double width;
  final double height;

  const _BookCoverFallback({required this.width, required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: width,
      height: height,
      color: theme.colorScheme.surfaceContainerHighest,
      child: const Center(
        child: Icon(
          Icons.menu_book_rounded,
          color: AppColors.primary,
          size: 28,
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  const _EmptyPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(icon, size: 34, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton(onPressed: onTap, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InlineInfoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AiFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? colorScheme.primary.withValues(alpha: 0.35)
                : colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _LibraryLoadingCard extends StatelessWidget {
  final double height;

  const _LibraryLoadingCard({required this.height});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.75),
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _LibraryErrorCard extends StatelessWidget {
  final String title;
  final String buttonLabel;
  final VoidCallback onPressed;

  const _LibraryErrorCard({
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.75),
        ),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.wifi_off_rounded,
            color: AppColors.lightTextSecondary,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
