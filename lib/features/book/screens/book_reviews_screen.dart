import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/books_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/review_model.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../widgets/book_review_tile.dart';

class BookReviewsScreen extends ConsumerStatefulWidget {
  const BookReviewsScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<BookReviewsScreen> createState() => _BookReviewsScreenState();
}

class _BookReviewsScreenState extends ConsumerState<BookReviewsScreen> {
  final ScrollController _scroll = ScrollController();
  final List<ReviewModel> _items = [];
  int _page = 1;
  int _lastPage = 1;
  bool _loadingInitial = true;
  bool _loadingMore = false;
  Object? _error;
  BookModel? _book;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final book = await ref.read(bookDetailProvider(widget.slug).future);
      if (!mounted) return;
      setState(() {
        _book = book;
        _error = null;
      });
      await _loadPage(1, append: false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingInitial = false;
        _error = e;
      });
    }
  }

  Future<void> _loadPage(int page, {required bool append}) async {
    final book = _book;
    if (book == null) return;
    if (append && (_loadingMore || _page >= _lastPage)) return;

    if (append) {
      setState(() => _loadingMore = true);
    } else {
      setState(() {
        _loadingInitial = true;
        _error = null;
      });
    }

    try {
      final result = await ref
          .read(reviewServiceProvider)
          .fetchReviewsPage(bookId: book.id, page: page, perPage: 20);
      if (!mounted) return;
      setState(() {
        if (append) {
          _items.addAll(result.items);
        } else {
          _items
            ..clear()
            ..addAll(result.items);
        }
        _page = result.currentPage;
        _lastPage = result.lastPage;
        _loadingInitial = false;
        _loadingMore = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingInitial = false;
        _loadingMore = false;
        _error = e;
      });
    }
  }

  void _onScroll() {
    if (!_scroll.hasClients || _loadingMore || _page >= _lastPage) return;
    final pos = _scroll.position;
    if (pos.pixels < pos.maxScrollExtent - 200) return;
    _loadPage(_page + 1, append: true);
  }

  Future<void> _onRefresh() => _loadPage(1, append: false);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final book = _book;

    if (_error != null && book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Değerlendirmeler'),
          surfaceTintColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  userFacingErrorMessage(_error!),
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 16),
                FilledButton.tonal(
                  onPressed: () {
                    setState(() {
                      _error = null;
                      _loadingInitial = true;
                    });
                    _bootstrap();
                  },
                  child: const Text('Tekrar dene'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (book == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Değerlendirmeler'),
          surfaceTintColor: Colors.transparent,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    final accent = reviewAccentFromCategory(book.category?.color);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Değerlendirmeler',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/books/${book.slug}');
            }
          },
        ),
      ),
      body: _loadingInitial && _items.isEmpty
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : _error != null && _items.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      userFacingErrorMessage(_error!),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.tonal(
                      onPressed: () => _loadPage(1, append: false),
                      child: const Text('Tekrar dene'),
                    ),
                  ],
                ),
              ),
            )
          : _items.isEmpty
          ? Center(
              child: Text(
                'Henüz değerlendirme yok.',
                style: TextStyle(color: colorScheme.onSurfaceVariant),
              ),
            )
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: _onRefresh,
              child: ListView.separated(
                controller: _scroll,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                itemCount: _items.length + (_page < _lastPage ? 1 : 0),
                separatorBuilder: (_, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  if (index >= _items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }
                  return BookReviewTile(
                    review: _items[index],
                    accentColor: accent,
                  );
                },
              ),
            ),
    );
  }
}
