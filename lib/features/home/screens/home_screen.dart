import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers/achievements_provider.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/connectivity_provider.dart';
import '../../../app/providers/home_shell_provider.dart';
import '../../../app/providers/library_provider.dart';
import '../../../app/providers/progress_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/providers/kids_provider.dart';
import '../../../app/providers/league_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/achievement_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/widgets/category_visuals.dart';
import '../../../core/widgets/reader_profile_avatar.dart';
import '../../../core/services/subscription_service.dart';
import '../../../core/services/notification_permission_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../league/screens/league_screen.dart';
import '../../library/widgets/library_view.dart';
import '../../profile/screens/profile_screen.dart';
import '../../profile/widgets/achievement_badge_grid.dart';
import '../../profile/widgets/achievement_celebration_widget.dart';
import '../../profile/widgets/delete_account_dialog.dart';
import '../../profile/widgets/reader_profile_dialogs.dart';
import '../../profile/widgets/reading_heatmap_widget.dart';
import '../../subscription/widgets/premium_badge.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../widgets/kids_mode_exit_dialog.dart';
import '../widgets/kids_mode_pin_set_dialog.dart';
import '../widgets/home_async_inline_retry.dart';
import '../widgets/home_tab.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;
  String? _discoverCategory;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthenticated = authState.isAuthenticated;
    final guestSelectedIndex = _selectedIndex > 1 ? 0 : _selectedIndex;

    ref.listen<int?>(homeTabRequestProvider, (previous, next) {
      if (next == null || !isAuthenticated) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() => _selectedIndex = next);
        ref.read(homeTabRequestProvider.notifier).state = null;
      });
    });

    ref.listen<AsyncValue<List<ConnectivityResult>>>(connectivityProvider, (
      previous,
      next,
    ) {
      next.whenData((list) {
        if (!connectivityListOnline(list)) return;
        final auth = ref.read(authProvider);
        if (auth.isOfflineSession) {
          ref.read(authProvider.notifier).refreshMe();
        }
      });
    });

    return Scaffold(
      body: IndexedStack(
        index: isAuthenticated ? _selectedIndex : guestSelectedIndex,
        children: isAuthenticated
            ? [
                HomeTabSection(
                  isActive: _selectedIndex == 0,
                  onOpenDiscover: (category) => setState(() {
                    _discoverCategory = category;
                    _selectedIndex = 1;
                  }),
                ),
                _DiscoverTab(
                  key: ValueKey('discover-${_discoverCategory ?? 'all'}'),
                  selectedCategory: _discoverCategory,
                  onCategoryChanged: (category) {
                    setState(() => _discoverCategory = category);
                  },
                ),
                const _LeagueTab(),
                const _LibraryTab(),
                const ProfileScreen(),
              ]
            : [
                HomeTabSection(
                  isActive: guestSelectedIndex == 0,
                  onOpenDiscover: (category) => setState(() {
                    _discoverCategory = category;
                    _selectedIndex = 1;
                  }),
                ),
                _DiscoverTab(
                  key: ValueKey('discover-${_discoverCategory ?? 'all'}'),
                  selectedCategory: _discoverCategory,
                  onCategoryChanged: (category) {
                    setState(() => _discoverCategory = category);
                  },
                ),
              ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: isAuthenticated ? _selectedIndex : guestSelectedIndex,
        onDestinationSelected: (i) {
          if (!isAuthenticated) {
            if (i == 2) {
              context.go('/login');
              return;
            }
            setState(() => _selectedIndex = i);
            return;
          }
          setState(() => _selectedIndex = i);
        },
        destinations: isAuthenticated
            ? const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Keşfet',
                ),
                NavigationDestination(
                  icon: Icon(Icons.emoji_events_outlined),
                  selectedIcon: Icon(Icons.emoji_events),
                  label: 'Lig',
                ),
                NavigationDestination(
                  icon: Icon(Icons.library_books_outlined),
                  selectedIcon: Icon(Icons.library_books),
                  label: 'Kütüphane',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline),
                  selectedIcon: Icon(Icons.person),
                  label: 'Profil',
                ),
              ]
            : const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Ana Sayfa',
                ),
                NavigationDestination(
                  icon: Icon(Icons.explore_outlined),
                  selectedIcon: Icon(Icons.explore),
                  label: 'Keşfet',
                ),
                NavigationDestination(
                  icon: Icon(Icons.login_rounded),
                  selectedIcon: Icon(Icons.login_rounded),
                  label: 'Giriş',
                ),
              ],
      ),
    );
  }
}

class _DiscoverTab extends ConsumerStatefulWidget {
  const _DiscoverTab({
    super.key,
    this.selectedCategory,
    this.onCategoryChanged,
  });

  final String? selectedCategory;
  final ValueChanged<String?>? onCategoryChanged;

  @override
  ConsumerState<_DiscoverTab> createState() => _DiscoverTabState();
}

class _DiscoverTabState extends ConsumerState<_DiscoverTab> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory;
  }

  @override
  void didUpdateWidget(covariant _DiscoverTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedCategory != widget.selectedCategory) {
      _selectedCategory = widget.selectedCategory;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final isKids = ref.watch(kidsModeProvider);
    final currentFilter = BooksFilter(
      category: _selectedCategory,
      isKids: isKids,
    );
    final booksAsync = ref.watch(booksProvider(currentFilter));
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = theme.cardColor;
    final textSecondary = colorScheme.onSurfaceVariant;
    final selectedCategoryBackground = isDark
        ? AppColors.accent.withValues(alpha: 0.38)
        : AppColors.accentSoft;
    final selectedCategoryForeground = isDark
        ? AppColors.primaryLight
        : AppColors.accent;
    final selectedCategoryBorder = isDark
        ? AppColors.outline.withValues(alpha: 0.95)
        : colorScheme.outline.withValues(alpha: 0.72);

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keşfet',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Search bar
                  GestureDetector(
                    onTap: () => context.push('/home/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: textSecondary, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            'Kitap, yazar veya kullanıcı ara...',
                            style: TextStyle(
                              color: textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: categoriesAsync.when(
              data: (cats) => SizedBox(
                height: 44,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: cats.length + 1,
                  itemBuilder: (ctx, i) {
                    final isAllTab = i == 0;
                    final category = isAllTab ? null : cats[i - 1];
                    final isSelected = isAllTab
                        ? _selectedCategory == null
                        : _selectedCategory == category!.slug;

                    return GestureDetector(
                      onTap: () {
                        String? nextCategory;
                        setState(() {
                          if (isAllTab) {
                            nextCategory = null;
                          } else if (isSelected) {
                            nextCategory = null;
                          } else {
                            nextCategory = category!.slug;
                          }
                          _selectedCategory = nextCategory;
                        });
                        widget.onCategoryChanged?.call(nextCategory);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? selectedCategoryBackground
                              : surfaceColor,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(color: selectedCategoryBorder)
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isAllTab)
                              Icon(
                                Icons.grid_view_rounded,
                                size: 16,
                                color: isSelected
                                    ? selectedCategoryForeground
                                    : colorScheme.onSurface,
                              )
                            else
                              Icon(
                                CategoryVisuals.resolve(
                                  slug: category!.slug,
                                  name: category.name,
                                  colorHex: category.color,
                                ).icon,
                                size: 16,
                                color: isSelected
                                    ? selectedCategoryForeground
                                    : colorScheme.onSurface,
                              ),
                            const SizedBox(width: 6),
                            Text(
                              isAllTab ? 'Tümü' : category!.name,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? selectedCategoryForeground
                                    : colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (err, _) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: homeAsyncInlineRetry(
                  context,
                  ref: ref,
                  error: err,
                  onRetry: () => ref.invalidate(categoriesProvider),
                  hint: 'Kategoriler yüklenemedi',
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _selectedCategory == null
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.tune_rounded,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kategori filtresi aktif',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() => _selectedCategory = null);
                              widget.onCategoryChanged?.call(null);
                            },
                            child: const Text('Temizle'),
                          ),
                        ],
                      ),
                    ),
            ),
          ),

          // Books grid
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: booksAsync.when(
              data: (books) {
                if (books.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48),
                      child: Column(
                        children: [
                          Text('📚', style: TextStyle(fontSize: 48)),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz kitap bulunamadı.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Yakında yeni kitaplar eklenecek.',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((ctx, i) {
                    final book = books[i];
                    return GestureDetector(
                      onTap: () => context.push('/books/${book.slug}'),
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
                                      width: double.infinity,
                                      errorWidget: (_, error, stackTrace) =>
                                          Container(
                                            color: AppColors.primary.withValues(
                                              alpha: 0.1,
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
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
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
                          Text(
                            book.author?.name ?? '',
                            style: TextStyle(
                              fontSize: 11,
                              color: textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }, childCount: books.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.58,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                ),
              ),
              error: (err, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 48),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cloud_off_rounded,
                        size: 48,
                        color: textSecondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Kitaplar yüklenemedi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'İnternet bağlantınızı kontrol edip tekrar deneyin.',
                        style: TextStyle(fontSize: 14, color: textSecondary),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: () =>
                            ref.invalidate(booksProvider(currentFilter)),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Tekrar Dene'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeagueTab extends StatelessWidget {
  const _LeagueTab();

  @override
  Widget build(BuildContext context) => const LeagueScreen(embedded: true);
}

class _LibraryTab extends ConsumerWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) => const LibraryView();
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  final NotificationPermissionService _notificationPermissionService =
      createNotificationPermissionService();
  final Set<String> _celebratedAchievementKeys = <String>{};
  NotificationPermissionState _notificationStatus =
      NotificationPermissionState.denied;
  bool _notificationLoading = false;
  int? _celebratingAchievementIndex;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await _notificationPermissionService.getStatus();
    if (mounted) {
      setState(() => _notificationStatus = status);
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (_notificationLoading) {
      return;
    }

    setState(() => _notificationLoading = true);

    NotificationPermissionState nextStatus = _notificationStatus;
    if (enable) {
      nextStatus = await _notificationPermissionService.requestPermission();
      if (nextStatus == NotificationPermissionState.permanentlyDenied) {
        await _notificationPermissionService.openSettings();
        nextStatus = await _notificationPermissionService.getStatus();
      }
    } else {
      await _notificationPermissionService.openSettings();
      nextStatus = await _notificationPermissionService.getStatus();
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationStatus = nextStatus;
      _notificationLoading = false;
    });

    switch (nextStatus) {
      case NotificationPermissionState.granted:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirimler artık açık.')),
        );
        break;
      case NotificationPermissionState.unsupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu platformda bildirim desteği kullanılamıyor.'),
          ),
        );
        break;
      case NotificationPermissionState.denied:
      case NotificationPermissionState.permanentlyDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bildirim izni kapalı. İstersen ayarlardan açabilirsin.',
            ),
          ),
        );
        break;
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final password = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const DeleteAccountDialog(),
    );
    if (password != null && password.isNotEmpty && mounted) {
      final ok = await ref.read(authProvider.notifier).deleteAccount(password);
      if (ok && mounted) {
        context.go('/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Şifreniz yanlış veya bir hata oluştu. Lütfen tekrar deneyin.',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _ensureParentPinBeforeEnteringKidsMode() async {
    final auth = ref.read(authProvider);
    final svc = await ref.read(kidsModePinServiceProvider.future);
    final userHasParentPin = auth.user?.hasParentPin;
    if (userHasParentPin == true ||
        (userHasParentPin == null && svc.hasPin())) {
      return true;
    }

    if (!mounted) return false;
    final ok = await KidsModePinSetDialog.show(
      context,
      onSave: (pin) async {
        final service = await ref.read(kidsModePinServiceProvider.future);
        await service.setPin(pin);
        ref.invalidate(kidsModePinServiceProvider);
        await ref.read(authProvider.notifier).refreshMe();
      },
    );

    if (ok == true) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Ebeveyn şifresi kaydedildi. Çocuk moduna geçiliyor.',
            ),
          ),
        );
      }
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Çocuk moduna geçmek için önce ebeveyn şifresi belirlemelisiniz.',
          ),
        ),
      );
    }
    return false;
  }

  Future<void> _switchIntoChildProfile() async {
    final auth = ref.read(authProvider);
    var childProfiles = auth.profiles
        .where((profile) => profile.isChild && !profile.isArchived)
        .toList(growable: false);

    if (childProfiles.isEmpty) {
      final form = await ReaderProfileDialogs.showChildProfileFormDialog(
        context,
        suggestedAvatarUrl: ReaderProfileAvatarCatalog.tokenValueAt(
          auth.profileCapabilities.activeChildProfilesCount,
        ),
      );
      if (form == null || form.name.trim().isEmpty) return;

      final created = await ref
          .read(authProvider.notifier)
          .createChildProfile(
            name: form.name.trim(),
            birthYear: form.birthYear,
            avatarUrl: form.avatarUrl,
            avatarBytes: form.avatarBytes,
            avatarFileName: form.avatarFileName,
          );
      if (!created || !mounted) return;

      childProfiles = ref
          .read(authProvider)
          .profiles
          .where((profile) => profile.isChild && !profile.isArchived)
          .toList(growable: false);
    }

    if (childProfiles.isEmpty || !mounted) return;
    final selected = childProfiles.length == 1
        ? childProfiles.first
        : await ReaderProfileDialogs.showChildProfilePicker(
            context,
            profiles: childProfiles,
          );
    if (selected == null) return;

    final hasParentPin = await _ensureParentPinBeforeEnteringKidsMode();
    if (!hasParentPin || !mounted) return;

    await ref.read(authProvider.notifier).activateReaderProfile(selected.id);
  }

  Future<void> _switchBackToParentProfile() async {
    final auth = ref.read(authProvider);
    dynamic parentProfile;
    for (final profile in auth.profiles) {
      if (profile.isParent && !profile.isArchived) {
        parentProfile = profile;
        break;
      }
    }
    if (parentProfile == null) return;

    final svc = await ref.read(kidsModePinServiceProvider.future);
    final hasParentPin = auth.user?.hasParentPin ?? svc.hasPin();
    if (!hasParentPin) {
      final switched = await ref
          .read(authProvider.notifier)
          .activateReaderProfile(parentProfile.id as int);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              switched
                  ? 'Ebeveyn şifresi bulunmadığı için ebeveyn profiline dönüldü. Lütfen bir şifre belirleyin.'
                  : 'Ebeveyn profiline dönülemedi. Lütfen tekrar deneyin.',
            ),
          ),
        );
      }
      return;
    }

    if (!mounted) return;
    await KidsModeExitDialog.show(
      context,
      verifyPin: (pin) async {
        final ok = await ref
            .read(authProvider.notifier)
            .activateReaderProfile(parentProfile.id as int, parentPin: pin);
        if (!ok) {
          return ref.read(authProvider).error ??
              'Ebeveyn profiline dönülemedi. Lütfen tekrar deneyin.';
        }
        return null;
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sayfa açılamadı.')));
      }
    }
  }

  String _planLabel(SubscriptionStatus? status) {
    if (status == null) return 'Premium erişim';
    if ((status.planLabel ?? '').trim().isNotEmpty) return status.planLabel!;

    return switch (status.planType) {
      'monthly' => 'Aylık plan',
      'yearly' => 'Yıllık plan',
      'lifetime' => 'Ömür boyu plan',
      _ => 'Premium erişim',
    };
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';

    final local = date.toLocal();
    final months = <int, String>{
      1: 'Ocak',
      2: 'Şubat',
      3: 'Mart',
      4: 'Nisan',
      5: 'Mayıs',
      6: 'Haziran',
      7: 'Temmuz',
      8: 'Ağustos',
      9: 'Eylül',
      10: 'Ekim',
      11: 'Kasım',
      12: 'Aralık',
    };

    return '${local.day} ${months[local.month]} ${local.year}';
  }

  String _premiumStartedText(UserModel? user, SubscriptionStatus? status) {
    final startedAt = _formatDate(status?.startedAt);
    if (startedAt.isNotEmpty) return startedAt;

    if (user?.isPremium == true) {
      return 'Satın alma tarihi kayıtlı değil';
    }

    return 'Premium aktif değil';
  }

  String _premiumExpiresText(UserModel? user, SubscriptionStatus? status) {
    if (status?.isLifetime == true) {
      return 'Süresiz erişim';
    }

    final subscriptionExpiry = _formatDate(status?.expiresAt);
    if (subscriptionExpiry.isNotEmpty) return subscriptionExpiry;

    final userExpiry = _formatDate(user?.premiumExpiresAt);
    if (userExpiry.isNotEmpty) return userExpiry;

    if (user?.isPremium == true) {
      return 'Bitiş tarihi tanımlanmamış';
    }

    return 'Premium aktif değil';
  }

  Future<void> _showPremiumDetailsModal(
    BuildContext context,
    UserModel? user,
    SubscriptionStatus? status,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final planLabel = _planLabel(status);
    final startedAt = _premiumStartedText(user, status);
    final expiresAt = _premiumExpiresText(user, status);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 64,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Premium bilgisi',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Premium erişimin',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Planın ve erişim tarihlerin burada görünüyor.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.4,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: theme.brightness == Brightness.dark
                          ? const [Color(0xFF171A17), Color(0xFF111311)]
                          : const [Color(0xFFF7FBF7), Color(0xFFEFF8F0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Column(
                    children: [
                      _PremiumDetailRow(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Plan',
                        value: planLabel,
                      ),
                      const SizedBox(height: 14),
                      _PremiumDetailRow(
                        icon: Icons.calendar_month_rounded,
                        label: 'Başlangıç tarihi',
                        value: startedAt,
                      ),
                      const SizedBox(height: 14),
                      _PremiumDetailRow(
                        icon: Icons.event_available_rounded,
                        label: status?.isLifetime == true
                            ? 'Erişim'
                            : 'Bitiş tarihi',
                        value: expiresAt,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.verified_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Reklamsız okuma, premium kitaplara erişim ve üyelik ayrıcalıkların şu anda aktif.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<AchievementModel>>>(earnedAchievementsProvider, (
      previous,
      next,
    ) {
      next.whenData((achievements) {
        if (!mounted || _celebratingAchievementIndex != null) {
          return;
        }

        final nextIndex = achievements.indexWhere(
          (achievement) =>
              achievement.isNew &&
              !_celebratedAchievementKeys.contains(achievement.key),
        );
        if (nextIndex == -1) {
          return;
        }

        _celebratedAchievementKeys.add(achievements[nextIndex].key);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() => _celebratingAchievementIndex = nextIndex);
        });
      });
    });

    final user = ref.watch(authProvider).user;
    final progress = ref.watch(allProgressProvider).valueOrNull ?? const [];
    final favorites = ref.watch(favoritesProvider).valueOrNull ?? const [];
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final colorScheme = theme.colorScheme;
    final isPremium = ref.watch(isPremiumProvider);
    final subscriptionStatus = ref.watch(subscriptionProvider).valueOrNull;
    final startedBooks = progress
        .where(
          (item) =>
              item.totalParagraphsRead > 0 ||
              (item.lastParagraphOrder ?? 0) > 0,
        )
        .length;
    final completedBooks = progress.where((item) => item.isCompleted).length;
    final readParagraphs = progress.fold<int>(
      0,
      (sum, item) => sum + item.totalParagraphsRead,
    );
    final notificationEnabled =
        _notificationStatus == NotificationPermissionState.granted;
    final achievementsAsync = ref.watch(earnedAchievementsProvider);
    final leagueStatus = ref.watch(kidsModeProvider)
        ? null
        : ref.watch(myLeagueProvider).valueOrNull;
    final streakShields = leagueStatus?.membership.streakShields ?? 0;

    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProfileHeroCard(
                  userName: user?.name ?? 'Okuyucu',
                  userEmail: user?.email ?? '',
                  initial: user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : '?',
                  isPremium: isPremium,
                  dailyGoal: user?.dailyGoal ?? 10,
                  startedBooks: startedBooks,
                  completedBooks: completedBooks,
                  favoriteCount: favorites.length,
                  readParagraphs: readParagraphs,
                  onPremiumDetailsTap: isPremium
                      ? () => _showPremiumDetailsModal(
                          context,
                          user,
                          subscriptionStatus,
                        )
                      : null,
                  onPremiumTap: isPremium
                      ? null
                      : () => context.push('/premium'),
                ),

                const SizedBox(height: 14),

                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _ProfileQuickStat(
                      width: (MediaQuery.of(context).size.width - 42) / 2,
                      icon: Icons.flag_rounded,
                      iconColor: AppColors.primary,
                      value: '${user?.dailyGoal ?? 10}',
                      label: 'Günlük hedef',
                    ),
                    _ProfileQuickStat(
                      width: (MediaQuery.of(context).size.width - 42) / 2,
                      icon: Icons.auto_stories_rounded,
                      iconColor: const Color(0xFFEA580C),
                      value: '$startedBooks',
                      label: 'Başlanan kitap',
                    ),
                    _ProfileQuickStat(
                      width: (MediaQuery.of(context).size.width - 42) / 2,
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      value: '$completedBooks',
                      label: 'Tamamlanan',
                    ),
                    _ProfileQuickStat(
                      width: (MediaQuery.of(context).size.width - 42) / 2,
                      icon: Icons.favorite_border_rounded,
                      iconColor: const Color(0xFFEF4444),
                      value: '${favorites.length}',
                      label: 'Favori kitap',
                    ),
                    if (streakShields > 0)
                      _ProfileQuickStat(
                        width: (MediaQuery.of(context).size.width - 42) / 2,
                        icon: Icons.shield_rounded,
                        iconColor: Colors.blueAccent,
                        value: '$streakShields',
                        label: 'Seri Kalkanı',
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: theme.brightness == Brightness.dark
                          ? const [Color(0xFF161713), Color(0xFF1E211C)]
                          : const [Color(0xFFF7FBF7), Color(0xFFEFF6EF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.7),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Okuma özeti',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              readParagraphs > 0
                                  ? 'Toplam $readParagraphs paragraf okudun. Güzel bir ritim yakaladın.'
                                  : 'Henüz başlangıç aşamasındasın. İlk birkaç paragrafla ritmi yakalayabilirsin.',
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // --- Rozetler ---
                achievementsAsync.when(
                  data: (achievements) {
                    if (achievements.isEmpty) return const SizedBox.shrink();
                    return Column(
                      children: [
                        AchievementBadgeGrid(
                          achievements: achievements,
                          earnedCount: achievements
                              .where((a) => a.isEarned)
                              .length,
                          compact: true,
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (err, _) => homeAsyncInlineRetry(
                    context,
                    ref: ref,
                    error: err,
                    onRetry: () => ref.invalidate(earnedAchievementsProvider),
                    hint: 'Rozetler yüklenemedi',
                  ),
                ),

                // --- Heatmap ---
                const ReadingHeatmapWidget(),
                const SizedBox(height: 20),

                // --- Stats ---
                Offstage(
                  offstage: true,
                  child: Row(
                    children: [
                      _StatCard(
                        label: 'Günlük Hedef',
                        value: '${user?.dailyGoal ?? 10}',
                        icon: '🎯',
                      ),
                      const SizedBox(width: 12),
                      const _StatCard(label: 'Seri', value: '—', icon: '🔥'),
                      const SizedBox(width: 12),
                      const _StatCard(
                        label: 'Rozetler',
                        value: '0',
                        icon: '🏆',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // --- Hesap ---
                _SectionLabel('Hesap'),
                _MenuCard(
                  color: cardColor,
                  children: [
                    _MenuItem(
                      icon: Icons.format_quote_rounded,
                      title: 'Alıntılarım',
                      subtitle: 'Kaydettiğiniz paragraflar ve notlar',
                      onTap: () => context.push('/home/highlights'),
                    ),
                    _MenuDivider(),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      title: 'Ayarlar',
                      subtitle: 'Tema, okuma tercihleri ve uygulama ayarları',
                      onTap: () => context.push('/home/settings'),
                    ),
                    _MenuDivider(),
                    _MenuItem(
                      icon: Icons.child_care_rounded,
                      title: 'Çocuk Modu',
                      subtitle: 'Çocuklara özel güvenli okuma alanı',
                      color: Colors.pink.shade600,
                      trailing: Switch(
                        value: ref.watch(kidsModeProvider),
                        activeThumbColor: Colors.pink.shade500,
                        onChanged: (val) async {
                          if (val) {
                            await _switchIntoChildProfile();
                          } else {
                            await _switchBackToParentProfile();
                          }
                        },
                      ),
                      onTap: () async {
                        final val = !ref.read(kidsModeProvider);
                        if (val) {
                          await _switchIntoChildProfile();
                        } else {
                          await _switchBackToParentProfile();
                        }
                      },
                    ),
                    _MenuDivider(),
                    _KidsModePinMenuItem(),
                    _MenuDivider(),
                    _MenuItem(
                      icon: Icons.logout_outlined,
                      title: 'Çıkış Yap',
                      onTap: () async {
                        final ok = await showDialog<bool>(
                          context: context,
                          builder: (dialogContext) {
                            final scheme = Theme.of(dialogContext).colorScheme;
                            return AlertDialog(
                              title: Text(
                                'Çıkış Yap',
                                style: TextStyle(
                                  color: scheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                              content: Text(
                                'Oturumunuzu kapatmak istediğinize emin misiniz?',
                                style: TextStyle(
                                  color: scheme.onSurface.withValues(
                                    alpha: 0.92,
                                  ),
                                  height: 1.45,
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, false),
                                  child: const Text('İptal'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogContext, true),
                                  child: const Text('Çıkış Yap'),
                                ),
                              ],
                            );
                          },
                        );
                        if (ok == true) {
                          await ref.read(authProvider.notifier).logout();
                          if (!context.mounted) return;
                          context.go('/login');
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Bildirimler ---
                _SectionLabel('BİLDİRİMLER'),
                _MenuCard(
                  color: cardColor,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications_outlined,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Bildirimlere İzin Ver',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  notificationEnabled
                                      ? 'Bildirimler açık'
                                      : 'Günlük hatırlatıcılar ve lig güncellemeleri',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: notificationEnabled,
                            activeThumbColor: AppColors.primary,
                            onChanged: _toggleNotifications,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Yasal ---
                _SectionLabel('YASAL'),
                _MenuCard(
                  color: cardColor,
                  children: [
                    _MenuItem(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Gizlilik Politikası',
                      trailing: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () => _launchUrl(
                        'https://kitaplig.com/gizlilik-politikasi',
                      ),
                    ),
                    _MenuDivider(),
                    _MenuItem(
                      icon: Icons.description_outlined,
                      title: 'Kullanım Koşulları',
                      trailing: const Icon(
                        Icons.open_in_new,
                        size: 16,
                        color: Colors.grey,
                      ),
                      onTap: () =>
                          _launchUrl('https://kitaplig.com/kullanim-kosullari'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // --- Tehlikeli Alan ---
                _SectionLabel('TEHLİKELİ ALAN'),
                Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: _MenuItem(
                    icon: Icons.delete_forever_outlined,
                    title: 'Hesabı Sil',
                    subtitle: 'Tüm verileriniz kalıcı olarak silinir',
                    color: Colors.red,
                    onTap: _showDeleteAccountDialog,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
          // Achievement celebration overlay
          if (_celebratingAchievementIndex != null)
            achievementsAsync.when(
              data: (achievements) {
                final idx = _celebratingAchievementIndex!;
                if (idx >= achievements.length) {
                  return const SizedBox.shrink();
                }
                return AchievementCelebrationOverlay(
                  achievement: achievements[idx],
                  onDismiss: () async {
                    await ref
                        .read(achievementServiceProvider)
                        .markSeen(achievements[idx]);
                    ref.invalidate(earnedAchievementsProvider);
                    if (mounted) {
                      setState(() => _celebratingAchievementIndex = null);
                    }
                  },
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, stackTrace) => const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Color color;
  final List<Widget> children;
  const _MenuCard({required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 18,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.userName,
    required this.userEmail,
    required this.initial,
    required this.isPremium,
    required this.dailyGoal,
    required this.startedBooks,
    required this.completedBooks,
    required this.favoriteCount,
    required this.readParagraphs,
    this.onPremiumDetailsTap,
    this.onPremiumTap,
  });

  final String userName;
  final String userEmail;
  final String initial;
  final bool isPremium;
  final int dailyGoal;
  final int startedBooks;
  final int completedBooks;
  final int favoriteCount;
  final int readParagraphs;
  final VoidCallback? onPremiumDetailsTap;
  final VoidCallback? onPremiumTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final colorScheme = theme.colorScheme;
    final summaryText = readParagraphs > 0
        ? 'Toplam $readParagraphs paragraf okudun. Ritim iyi gidiyor.'
        : 'Okuma yolculuğun yeni başlıyor. İlk kitabını seçip başlayabilirsin.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            if (isDark) const Color(0xFF181914) else const Color(0xFFF7FAF6),
            if (isDark) const Color(0xFF22261F) else const Color(0xFFF0F7F0),
            AppColors.primary.withValues(alpha: 0.18),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : theme.colorScheme.outline.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.colorScheme.outline.withValues(alpha: 0.55),
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            userName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isPremium) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onPremiumDetailsTap,
                            child: const PremiumBadge(
                              size: PremiumBadgeSize.small,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 12,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            summaryText,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeroInfoChip(
                icon: Icons.local_fire_department_outlined,
                label: '$dailyGoal paragraf hedefi',
              ),
              _HeroInfoChip(
                icon: isPremium ? Icons.workspace_premium : Icons.bolt_outlined,
                label: isPremium ? 'Premium aktif' : 'Ücretsiz plan',
              ),
            ],
          ),
          if (!isPremium && onPremiumTap != null) ...[
            const SizedBox(height: 14),
            InkWell(
              onTap: onPremiumTap,
              borderRadius: BorderRadius.circular(18),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.workspace_premium,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Premium ile reklamsız okumaya ve tüm kitaplara geç.',
                        style: TextStyle(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroInfoChip extends StatelessWidget {
  const _HeroInfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: isDark ? 0.18 : 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PremiumDetailRow extends StatelessWidget {
  const _PremiumDetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileQuickStat extends StatelessWidget {
  const _ProfileQuickStat({
    required this.width,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final double width;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _KidsModePinMenuItem extends ConsumerWidget {
  const _KidsModePinMenuItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pinAsync = ref.watch(kidsModePinServiceProvider);
    final color = const Color(0xFFE91E63);

    return pinAsync.when(
      data: (svc) {
        final kidsOn = ref.watch(kidsModeProvider);
        final userHasParentPin = ref.watch(
          authProvider.select((state) => state.user?.hasParentPin),
        );
        final hasParentPin = userHasParentPin ?? svc.hasPin();
        final subtitle = kidsOn
            ? (hasParentPin
                  ? 'Şifreyi değiştirmek için önce ebeveyn profiline dönün'
                  : 'Şifreyi ebeveyn profiline döndükten sonra belirleyin')
            : hasParentPin
            ? 'Çocuk modundan çıkmak için şifre tanımlı'
            : 'Çocuk modundan çıkmak için şifre belirleyin';

        return _MenuItem(
          icon: Icons.child_care_rounded,
          title: 'Ebeveyn Şifresi',
          subtitle: subtitle,
          color: color,
          onTap: () async {
            if (kidsOn) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ebeveyn şifresi sadece ebeveyn profilindeyken değiştirilebilir.',
                  ),
                ),
              );
              return;
            }

            final ok = await KidsModePinSetDialog.show(
              context,
              onSave: (pin) async {
                final service = await ref.read(
                  kidsModePinServiceProvider.future,
                );
                await service.setPin(pin);
                ref.invalidate(kidsModePinServiceProvider);
                await ref.read(authProvider.notifier).refreshMe();
              },
            );
            if (ok == true && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ebeveyn şifresi kaydedildi.')),
              );
            }
          },
        );
      },
      loading: () => const ListTile(
        title: Text('Ebeveyn Şifresi'),
        trailing: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
      error: (err, _) => ListTile(
        leading: Icon(Icons.error_outline_rounded, color: color),
        title: const Text('Ebeveyn Şifresi'),
        subtitle: Text(
          userFacingErrorMessage(
            err,
            fallback: 'Yerel şifre bilgisi okunamadı.',
          ),
          maxLines: 3,
        ),
        trailing: TextButton(
          onPressed: () => ref.invalidate(kidsModePinServiceProvider),
          child: const Text('Tekrar'),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            size: 20,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
