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
import '../../../core/models/bookmark_model.dart';
import '../../../core/models/favorite_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/widgets/animated_segmented_control.dart';

enum _LibraryMode {
  overview,
  reading,
  completed,
  downloaded,
  favorites,
  highlights,
}

class LibraryView extends ConsumerStatefulWidget {
  const LibraryView({super.key});

  @override
  ConsumerState<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends ConsumerState<LibraryView> {
  _LibraryMode _mode = _LibraryMode.overview;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState.status == AuthStatus.unknown) {
      return const SafeArea(
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final progressAsync = ref.watch(allProgressProvider);
    final favoritesAsync = ref.watch(favoritesProvider);
    final bookmarksAsync = ref.watch(bookmarksProvider);
    final downloadedAsync = ref.watch(downloadedBooksProvider);
    final isKidsMode = ref.watch(kidsModeProvider);

    final rawProgress = progressAsync.valueOrNull ?? const <ProgressModel>[];
    final rawFavorites = favoritesAsync.valueOrNull ?? const <FavoriteModel>[];
    final rawBookmarks = bookmarksAsync.valueOrNull ?? const <BookmarkModel>[];

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
    final bookmarks = isKidsMode
        ? rawBookmarks
              .where((b) => b.book?.isKids == true)
              .toList(growable: false)
        : rawBookmarks;
    final downloadedBooks = downloadedAsync.valueOrNull ?? const <BookModel>[];

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
              bookmarksAsync: bookmarksAsync,
              downloadedAsync: downloadedAsync,
              filteredCounts: isKidsMode
                  ? (
                      progress: activeProgress.length,
                      completed: completedProgress.length,
                      downloaded: downloadedBooks.length,
                      favorites: favorites.length,
                      bookmarks: bookmarks.length,
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
              ],
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) {
                final slide = Tween<Offset>(
                  begin: const Offset(0.03, 0),
                  end: Offset.zero,
                ).animate(animation);
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(position: slide, child: child),
                );
              },
              child: KeyedSubtree(
                key: ValueKey(_mode),
                child: _LibraryModeContent(
                  mode: _mode,
                  onRetryProgress: () => ref.invalidate(allProgressProvider),
                  onRetryFavorites: () => ref.invalidate(favoritesProvider),
                  onRetryBookmarks: () => ref.invalidate(bookmarksProvider),
                  progressAsync: progressAsync,
                  favoritesAsync: favoritesAsync,
                  bookmarksAsync: bookmarksAsync,
                  downloadedAsync: downloadedAsync,
                  allProgress: allProgress,
                  activeProgress: activeProgress,
                  completedProgress: completedProgress,
                  downloadedBooks: downloadedBooks,
                  favorites: favorites,
                  bookmarks: bookmarks,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryModeContent extends StatelessWidget {
  final _LibraryMode mode;
  final VoidCallback onRetryProgress;
  final VoidCallback onRetryFavorites;
  final VoidCallback onRetryBookmarks;
  final AsyncValue<List<ProgressModel>> progressAsync;
  final AsyncValue<List<FavoriteModel>> favoritesAsync;
  final AsyncValue<List<BookmarkModel>> bookmarksAsync;
  final AsyncValue<List<BookModel>> downloadedAsync;
  final List<ProgressModel> allProgress;
  final List<ProgressModel> activeProgress;
  final List<ProgressModel> completedProgress;
  final List<BookModel> downloadedBooks;
  final List<FavoriteModel> favorites;
  final List<BookmarkModel> bookmarks;

  const _LibraryModeContent({
    required this.mode,
    required this.onRetryProgress,
    required this.onRetryFavorites,
    required this.onRetryBookmarks,
    required this.progressAsync,
    required this.favoritesAsync,
    required this.bookmarksAsync,
    required this.downloadedAsync,
    required this.allProgress,
    required this.activeProgress,
    required this.completedProgress,
    required this.downloadedBooks,
    required this.favorites,
    required this.bookmarks,
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
              _ => 'Yarım bıraktığın kitapları tek yerden sürdür.',
            },
          ),
          const SizedBox(height: 10),
          progressAsync.when(
            loading: () => const _LibraryLoadingCard(height: 186),
            error: (_, __) => _LibraryErrorCard(
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
                  onTap: () => context.go('/home'),
                );
              }

              return SizedBox(
                height: 186,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: progressForMode.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 14),
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
            subtitle: 'Cihazına kaydettiğin kitaplara hızlıca ulaş.',
          ),
          const SizedBox(height: 10),
          downloadedAsync.when(
            loading: () => const _LibraryLoadingCard(height: 140),
            error: (_, __) => const _InlineInfoCard(
              title: 'İndirilen kitaplar yüklenemedi',
              subtitle: 'Yerel kütüphane birazdan tekrar denenebilir.',
            ),
            data: (_) {
              if (downloadedBooks.isEmpty) {
                return const _InlineInfoCard(
                  title: 'Henüz indirilen kitap yok',
                  subtitle:
                      'Bir kitabı indirdiginde burada göreceksin.',
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
            error: (_, __) => const _InlineInfoCard(
              title: 'Favoriler yüklenemedi',
              subtitle: 'Bağlantını kontrol edip tekrar deneyebilirsin.',
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
            subtitle: 'İşaretlediğin paragraflara hızlıca geri dön.',
          ),
          const SizedBox(height: 10),
          bookmarksAsync.when(
            loading: () => const _LibraryLoadingCard(height: 220),
            error: (_, __) => const _InlineInfoCard(
              title: 'Kaydedilen alıntılar yüklenemedi',
              subtitle: 'Bu alan daha sonra tekrar denenebilir.',
            ),
            data: (_) {
              if (bookmarks.isEmpty) {
                return const _InlineInfoCard(
                  title: 'Henüz kayıtlı alıntın yok',
                  subtitle:
                      'Okurken bir paragrafı kaydettiğinde burada notlarınla birlikte görünecek.',
                );
              }

              final limit = mode == _LibraryMode.highlights ? 12 : 8;
              return Column(
                children: List.generate(
                  bookmarks.length.clamp(0, limit),
                  (index) => Padding(
                    padding: EdgeInsets.only(
                      bottom: index == limit - 1 ? 0 : 12,
                    ),
                    child: _BookmarkCard(bookmark: bookmarks[index]),
                  ),
                ),
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
  final AsyncValue<List<BookmarkModel>> bookmarksAsync;
  final AsyncValue<List<BookModel>> downloadedAsync;
  final ({
    int progress,
    int completed,
    int downloaded,
    int favorites,
    int bookmarks,
  })?
  filteredCounts;

  const _LibraryHero({
    required this.progressAsync,
    required this.favoritesAsync,
    required this.bookmarksAsync,
    required this.downloadedAsync,
    this.filteredCounts,
  });

  @override
  Widget build(BuildContext context) {
    final progressCount =
        filteredCounts?.progress ?? progressAsync.valueOrNull?.length ?? 0;
    final completedCount =
        filteredCounts?.completed ??
        progressAsync.valueOrNull?.where((item) => item.isCompleted).length ??
        0;
    final downloadedCount =
        filteredCounts?.downloaded ?? downloadedAsync.valueOrNull?.length ?? 0;
    final favoritesCount =
        filteredCounts?.favorites ?? favoritesAsync.valueOrNull?.length ?? 0;
    final bookmarksCount =
        filteredCounts?.bookmarks ?? bookmarksAsync.valueOrNull?.length ?? 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.75)),
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
                child: _StatPill(label: 'Aktif okuma', value: '$progressCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(label: 'Biten', value: '$completedCount'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatPill(label: 'İndirilen', value: '$downloadedCount'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatPill(label: 'Favori', value: '$favoritesCount'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatPill(label: 'Alıntı', value: '$bookmarksCount'),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox.shrink()),
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
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.7)),
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
            color: theme.colorScheme.outline.withOpacity(0.75),
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
                      backgroundColor: theme.colorScheme.outline.withOpacity(
                        0.45,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress.isCompleted ? Colors.green : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress.isCompleted
                        ? 'Tamamlandi'
                        : '%${progress.completionPercentage.toStringAsFixed(0)} tamamlandi',
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
            color: theme.colorScheme.outline.withOpacity(0.75),
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
            color: theme.colorScheme.outline.withOpacity(0.75),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaldırma tamamlanamadı: $error')));
    }
  }
}

class _BookmarkCard extends StatelessWidget {
  final BookmarkModel bookmark;

  const _BookmarkCard({required this.bookmark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final excerpt = bookmark.note?.trim().isNotEmpty == true
        ? bookmark.note!.trim()
        : bookmark.paragraph?.content.trim() ?? '';
    final book = bookmark.book;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.75)),
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
                  color: AppColors.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.bookmark_added_rounded,
                  color: AppColors.accent,
                ),
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
            ),
          ),
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
              errorWidget: (_, __, ___) =>
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
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.75)),
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
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.75)),
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
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.75)),
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
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.75)),
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
