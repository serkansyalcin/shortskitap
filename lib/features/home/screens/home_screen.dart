import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/progress_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../league/widgets/league_mini_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeTab(),
          _DiscoverTab(),
          _LibraryTab(),
          _ProfileTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (i) {
          if (i == 2) {
            // League tab — navigate to dedicated league screen
            context.push('/league');
            return;
          }
          setState(() => _selectedIndex = i < 2 ? i : i - 1);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Ana Sayfa'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore), label: 'Keşfet'),
          NavigationDestination(icon: Icon(Icons.emoji_events_outlined), selectedIcon: Icon(Icons.emoji_events), label: 'Lig'),
          NavigationDestination(icon: Icon(Icons.library_books_outlined), selectedIcon: Icon(Icons.library_books), label: 'Kütüphane'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }
}

class _HomeTab extends ConsumerWidget {
  const _HomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final progressAsync = ref.watch(allProgressProvider);
    final featuredAsync = ref.watch(featuredBooksProvider);
    final settings = ref.watch(settingsProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Merhaba, ${user?.name.split(' ').first ?? 'Okuyucu'} 👋',
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'Bugün okumaya devam et!',
                        style: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
                // Daily goal ring
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: 0.3,
                        strokeWidth: 4,
                        backgroundColor: Colors.grey.shade200,
                        color: AppColors.accent,
                      ),
                    ),
                    const Text('🔥', style: TextStyle(fontSize: 20)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // League mini card
            const LeagueMiniCard(),
            const SizedBox(height: 20),

            // Continue reading card
            progressAsync.when(
              data: (progress) {
                final recent = progress.isNotEmpty ? progress.first : null;
                if (recent == null || recent.book == null) return const SizedBox.shrink();

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
                        if (recent.book!.coverImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: CachedNetworkImage(
                              imageUrl: recent.book!.coverImageUrl!,
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
                            child: const Center(child: Text('📖', style: TextStyle(fontSize: 28))),
                          ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Devam Et',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                recent.book!.title,
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
                          child: const Icon(Icons.play_arrow, color: AppColors.primary, size: 20),
                        ),
                      ],
                    ),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),

            const SizedBox(height: 24),

            // Featured Books
            featuredAsync.when(
              data: (books) {
                if (books.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Öne Çıkan Kitaplar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        TextButton(
                          onPressed: () {},
                          child: const Text('Tümü', style: TextStyle(color: AppColors.primary)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: books.length,
                        itemBuilder: (ctx, i) {
                          final book = books[i];
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
                                                color: AppColors.primary.withOpacity(0.1),
                                                child: const Center(child: Text('📖', style: TextStyle(fontSize: 36))),
                                              ),
                                            )
                                          : Container(
                                              color: AppColors.primary.withOpacity(0.1),
                                              child: const Center(child: Text('📖', style: TextStyle(fontSize: 36))),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    book.title,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
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
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscoverTab extends ConsumerWidget {
  const _DiscoverTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final booksAsync = ref.watch(booksProvider(const BooksFilter()));

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keşfet', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  // Search bar
                  GestureDetector(
                    onTap: () => context.push('/home/search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.search, color: AppColors.lightTextSecondary, size: 20),
                          SizedBox(width: 10),
                          Text('Kitap veya yazar ara...', style: TextStyle(color: AppColors.lightTextSecondary)),
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
                  itemCount: cats.length,
                  itemBuilder: (ctx, i) => Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cats[i].icon != null) Text(cats[i].icon!, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(cats[i].name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),

          // Books grid
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: booksAsync.when(
              data: (books) => SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) {
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
                                    )
                                  : Container(
                                      color: AppColors.primary.withOpacity(0.1),
                                      child: const Center(child: Text('📖', style: TextStyle(fontSize: 36))),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            book.title,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            book.author?.name ?? '',
                            style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: books.length,
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
              ),
              loading: () => const SliverToBoxAdapter(
                child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
              ),
              error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTab extends ConsumerWidget {
  const _LibraryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(allProgressProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Kütüphane', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            progressAsync.when(
              data: (progress) {
                if (progress.isEmpty) {
                  return const Center(
                    child: Column(
                      children: [
                        SizedBox(height: 60),
                        Text('📚', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 16),
                        Text('Henüz kitap okumadın.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        Text('Keşfet sekmesinden kitap bul!', style: TextStyle(color: AppColors.lightTextSecondary)),
                      ],
                    ),
                  );
                }

                return Column(
                  children: progress.map((p) {
                    if (p.book == null) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () => context.push('/read/${p.bookId}'),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: p.book!.coverImageUrl != null
                                  ? CachedNetworkImage(
                                      imageUrl: p.book!.coverImageUrl!,
                                      width: 48,
                                      height: 64,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 48,
                                      height: 64,
                                      color: AppColors.primary.withOpacity(0.1),
                                      child: const Center(child: Text('📖')),
                                    ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.book!.title,
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(2),
                                    child: LinearProgressIndicator(
                                      value: p.completionPercentage / 100,
                                      backgroundColor: Colors.grey.shade200,
                                      color: p.isCompleted ? Colors.green : AppColors.primary,
                                      minHeight: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    p.isCompleted
                                        ? '✅ Tamamlandı'
                                        : '%${p.completionPercentage.toStringAsFixed(0)} tamamlandı',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: p.isCompleted ? Colors.green : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.play_arrow, color: AppColors.primary),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTab extends ConsumerStatefulWidget {
  const _ProfileTab();

  @override
  ConsumerState<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<_ProfileTab> {
  PermissionStatus _notificationStatus = PermissionStatus.denied;

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final status = await Permission.notification.status;
    if (mounted) setState(() => _notificationStatus = status);
  }

  Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (mounted) setState(() => _notificationStatus = status);
    if (status.isPermanentlyDenied && mounted) {
      openAppSettings();
    }
  }

  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _DeleteAccountDialog(),
    );
    if (confirmed == true && mounted) {
      final ok = await ref.read(authProvider.notifier).deleteAccount();
      if (ok && mounted) {
        context.go('/login');
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hesap silinirken bir hata oluştu. Lütfen tekrar deneyin.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sayfa açılamadı.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),

            // --- Avatar + Name ---
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      user?.name.isNotEmpty == true
                          ? user!.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.name ?? '',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- Stats ---
            Row(
              children: [
                _StatCard(label: 'Günlük Hedef', value: '${user?.dailyGoal ?? 10}', icon: '🎯'),
                const SizedBox(width: 12),
                const _StatCard(label: 'Seri', value: '—', icon: '🔥'),
                const SizedBox(width: 12),
                const _StatCard(label: 'Rozetler', value: '0', icon: '🏆'),
              ],
            ),
            const SizedBox(height: 28),

            // --- Hesap ---
            _SectionLabel('HESAP'),
            _MenuCard(color: cardColor, children: [
              _MenuItem(
                icon: Icons.settings_outlined,
                title: 'Ayarlar',
                onTap: () => context.push('/home/settings'),
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.logout_outlined,
                title: 'Çıkış Yap',
                onTap: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Çıkış Yap'),
                      content: const Text('Oturumunuzu kapatmak istediğinize emin misiniz?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Çıkış Yap'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true && mounted) {
                    await ref.read(authProvider.notifier).logout();
                    if (mounted) context.go('/login');
                  }
                },
              ),
            ]),
            const SizedBox(height: 20),

            // --- Bildirimler ---
            _SectionLabel('BİLDİRİMLER'),
            _MenuCard(color: cardColor, children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.notifications_outlined,
                          color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Bildirimlere İzin Ver',
                              style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            _notificationStatus.isGranted
                                ? 'Bildirimler açık'
                                : 'Günlük hatırlatıcılar ve lig güncellemeleri',
                            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _notificationStatus.isGranted,
                      activeColor: AppColors.primary,
                      onChanged: (_) async {
                        if (_notificationStatus.isGranted) {
                          await openAppSettings();
                        } else {
                          await _requestNotificationPermission();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),

            // --- Yasal ---
            _SectionLabel('YASAL'),
            _MenuCard(color: cardColor, children: [
              _MenuItem(
                icon: Icons.privacy_tip_outlined,
                title: 'Gizlilik Politikası',
                trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                onTap: () => _launchUrl('https://kitaplig.com/privacy'),
              ),
              _MenuDivider(),
              _MenuItem(
                icon: Icons.description_outlined,
                title: 'Kullanım Koşulları',
                trailing: const Icon(Icons.open_in_new, size: 16, color: Colors.grey),
                onTap: () => _launchUrl('https://kitaplig.com/terms'),
              ),
            ]),
            const SizedBox(height: 20),

            // --- Tehlikeli Alan ---
            _SectionLabel('TEHLİKELİ ALAN'),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
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
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _canDelete = false;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_rounded, color: Colors.red[700]),
          const SizedBox(width: 8),
          const Text('Hesabı Sil'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Bu işlem geri alınamaz. Tüm okuma geçmişiniz, lig puanlarınız ve kişisel verileriniz kalıcı olarak silinecek.',
              style: TextStyle(fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Onaylamak için aşağıya "SİL" yazın:',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              hintText: 'SİL',
              isDense: true,
            ),
            onChanged: (v) => setState(() => _canDelete = v.trim() == 'SİL'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: (_canDelete && !_loading)
              ? () {
                  setState(() => _loading = true);
                  Navigator.pop(context, true);
                }
              : null,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Hesabı Kalıcı Sil'),
        ),
      ],
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
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.grey[500],
          letterSpacing: 1.2,
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
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 56);
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;

  const _StatCard({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
            ),
          ],
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.lightTextSecondary), textAlign: TextAlign.center),
          ],
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
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: 20),
      ),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: TextStyle(fontSize: 12, color: Colors.grey[500]))
          : null,
      trailing: trailing ?? Icon(Icons.chevron_right, size: 20, color: Colors.grey[400]),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}
