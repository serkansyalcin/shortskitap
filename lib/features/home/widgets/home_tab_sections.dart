import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/kids_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/book_model.dart';
import '../../../core/models/category_model.dart';
import '../../../core/models/progress_model.dart';
import '../../../core/models/reader_profile_model.dart';
import '../../../core/models/user_model.dart';
import 'home_async_inline_retry.dart';
import 'notification_bell_button.dart';

class HomeGreetingSection extends StatelessWidget {
  const HomeGreetingSection({
    super.key,
    required this.user,
    required this.activeProfile,
    required this.isAuthenticated,
    required this.kidsModeEnabled,
    required this.onSearchTap,
  });

  final UserModel? user;
  final ReaderProfileModel? activeProfile;
  final bool isAuthenticated;
  final bool kidsModeEnabled;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final greetingName = kidsModeEnabled
        ? (activeProfile?.name.split(' ').first ?? 'Küçük Okuyucu')
        : (user?.name.split(' ').first ?? 'Okuyucu');

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                kidsModeEnabled
                    ? 'Hoş Geldin, ${user?.name.split(' ').first ?? 'Küçük Okuyucu'} 🎉'
                    : 'Merhaba, ${user?.name.split(' ').first ?? 'Okuyucu'} 👋',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: kidsModeEnabled
                      ? Colors.pink.shade600
                      : colorScheme.onSurface,
                ),
              ),
              Text(
                kidsModeEnabled
                    ? 'Eğlenceli hikayeler seni bekliyor!'
                    : 'Bugün okumaya devam et!',
                style: TextStyle(
                  fontSize: 14,
                  color: kidsModeEnabled
                      ? Colors.pink.shade400
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HomeHeaderIconButton(
              icon: Icons.search_rounded,
              tooltip: 'Ara',
              onTap: onSearchTap,
            ),
            if (isAuthenticated) ...[
              const SizedBox(width: 6),
              const NotificationBellButton(),
              const SizedBox(width: 6),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF151A16)
                          : colorScheme.surfaceContainerHighest,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : colorScheme.outline.withOpacity(0.35),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: CircularProgressIndicator(
                        value: 0.3,
                        strokeWidth: 4,
                        backgroundColor: isDark
                            ? Colors.white.withOpacity(0.14)
                            : colorScheme.outline.withOpacity(0.25),
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.accent,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.local_fire_department_rounded,
                    size: 18,
                    color: isDark ? AppColors.primaryLight : AppColors.accent,
                  ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class HomeContinueReadingSection extends StatelessWidget {
  const HomeContinueReadingSection({super.key, required this.recent});

  final ProgressModel recent;

  @override
  Widget build(BuildContext context) {
    final book = recent.book;
    if (book == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => context.push('/read/${recent.bookId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (book.coverImageUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: book.coverImageUrl!,
                  width: 56,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 56,
                height: 72,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Text('📖', style: TextStyle(fontSize: 28)),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kaldığın Yerden Devam Et',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    book.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: recent.completionPercentage / 100,
                      backgroundColor: Colors.white24,
                      color: AppColors.accent,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '%${recent.completionPercentage.toStringAsFixed(1)} tamamlandı',
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.play_arrow,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeQuickCategoriesSection extends StatelessWidget {
  const HomeQuickCategoriesSection({
    super.key,
    required this.categoriesAsync,
    required this.kidsModeEnabled,
    required this.onOpenDiscover,
  });

  final AsyncValue<List<CategoryModel>> categoriesAsync;
  final bool kidsModeEnabled;
  final ValueChanged<String?> onOpenDiscover;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty || kidsModeEnabled) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hızlı Kategoriler',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenDiscover(null),
                  child: const Text(
                    'Tümü',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length.clamp(0, 10),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return InkWell(
                    onTap: () => onOpenDiscover(category.slug),
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: colorScheme.outline.withOpacity(0.55),
                        ),
                      ),
                      child: Text(
                        category.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, _) => Consumer(
        builder: (context, ref, child) => homeAsyncInlineRetry(
          context,
          ref: ref,
          error: err,
          onRetry: () => ref.invalidate(homeQuickCategoriesProvider),
          hint: 'Hızlı kategoriler yüklenemedi',
        ),
      ),
    );
  }
}

class HomeFeaturedBooksSection extends StatelessWidget {
  const HomeFeaturedBooksSection({
    super.key,
    required this.featuredAsync,
    required this.onOpenDiscover,
  });

  final AsyncValue<List<BookModel>> featuredAsync;
  final ValueChanged<String?> onOpenDiscover;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return featuredAsync.when(
      data: (books) {
        if (books.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Öne Çıkan Kitaplar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: () => onOpenDiscover(null),
                  child: const Text(
                    'Tümü',
                    style: TextStyle(color: AppColors.primary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: books.length,
                itemBuilder: (context, index) {
                  final book = books[index];
                  return GestureDetector(
                    onTap: () => context.push('/books/${book.slug}'),
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: book.coverImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: book.coverImageUrl!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      errorWidget: (_, __, ___) => Container(
                                        color: AppColors.primary.withOpacity(
                                          0.1,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '📖',
                                            style: TextStyle(fontSize: 36),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: AppColors.primary.withOpacity(0.1),
                                      child: const Center(
                                        child: Text(
                                          '📖',
                                          style: TextStyle(fontSize: 36),
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.title,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
      error: (err, _) => Consumer(
        builder: (context, ref, child) => homeAsyncInlineRetry(
          context,
          ref: ref,
          error: err,
          onRetry: () => ref.invalidate(featuredBooksProvider),
          hint: 'Öne çıkan kitaplar yüklenemedi',
        ),
      ),
    );
  }
}

class HomeHeaderIconButton extends StatelessWidget {
  const HomeHeaderIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withOpacity(0.72),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colorScheme.outline.withOpacity(0.5)),
            ),
            child: Icon(icon, size: 22, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

class CompactPremiumCta extends StatelessWidget {
  const CompactPremiumCta({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2E2E2E) : const Color(0xFF3B3B3B),
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.18 : 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                color: Colors.amber.shade400,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "Premium'a Geç",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OfflineReadingBanner extends StatelessWidget {
  const OfflineReadingBanner({super.key, required this.onOpenDownloads});

  final VoidCallback onOpenDownloads;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark
          ? AppColors.spotifyPanel.withValues(alpha: 0.92)
          : colorScheme.surfaceContainerHighest.withValues(alpha: 0.65),
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.5),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Çevrimdışısın',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'İnternet yokken yalnızca cihazına indirdiğin kitaplara '
              'kütüphanedeki İndirilenler bölümünden devam edebilirsin.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: onOpenDownloads,
              icon: const Icon(Icons.download_for_offline_rounded, size: 20),
              label: const Text('İndirilenlere git'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KidsModeInfoCard extends ConsumerWidget {
  const KidsModeInfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFFE91E63);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isDark
            ? LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.18),
                  const Color(0xFF2D1520),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : LinearGradient(
                colors: [
                  Colors.pink.shade50,
                  Colors.pink.shade50.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? accent.withValues(alpha: 0.45)
              : Colors.pink.shade200.withOpacity(0.6),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? accent.withValues(alpha: 0.22)
                  : Colors.pink.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.shield_rounded,
              color: isDark ? accent : Colors.pink.shade700,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Güvenli Okuma Alanı',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? accent : Colors.pink.shade800,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => ref
                          .read(kidsUiPrefsProvider.notifier)
                          .dismissInfoCard(),
                      borderRadius: BorderRadius.circular(999),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: isDark
                              ? colorScheme.onSurface.withValues(alpha: 0.72)
                              : Colors.pink.shade500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Çocuk modu açıkken yalnızca çocuklara uygun içerikler gösterilir. '
                  'Erişkin içeriklere erişim engellenir. Moddan çıkmak için ebeveyn şifresi gerekir.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: isDark
                        ? colorScheme.onSurface.withValues(alpha: 0.88)
                        : colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
