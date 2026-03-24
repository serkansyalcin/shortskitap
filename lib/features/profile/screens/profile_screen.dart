import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/achievements_provider.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/profile_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/public_profile_model.dart';
import '../widgets/achievement_badge_grid.dart';
import '../widgets/reading_heatmap_widget.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key, this.username, this.standalone = false});

  final String? username;
  final bool standalone;

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _followBusy = false;

  String? get _me => ref.read(authProvider).user?.username;
  String? get _username => widget.username ?? _me;
  bool get _isSelf => widget.username == null || widget.username == _me;

  Future<void> _refresh() async {
    final username = _username;
    if (username == null || username.isEmpty) return;
    await ref.refresh(publicProfileProvider(username).future);
    if (_isSelf) ref.invalidate(earnedAchievementsProvider);
  }

  Future<void> _toggleFollow(PublicProfileModel profile) async {
    final user = ref.read(authProvider).user;
    final username = profile.profile.username;
    if (user == null) {
      final returnTo = Uri.encodeComponent('/profil/$username');
      context.push('/login?returnTo=$returnTo');
      return;
    }
    if (_followBusy) return;
    setState(() => _followBusy = true);
    try {
      final service = ref.read(profileServiceProvider);
      if (profile.relationship.isFollowing) {
        await service.unfollow(username);
      } else {
        await service.follow(username);
      }
      ref.invalidate(publicProfileProvider(username));
    } finally {
      if (mounted) setState(() => _followBusy = false);
    }
  }

  Future<void> _openPeople(
    String title,
    Future<ProfileFollowPageModel> Function() loader,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) => _PeopleSheet(title: title, loader: loader),
    );
  }

  Future<void> _logout() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumunu kapatmak istediğine emin misin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
    if (approved != true) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final username = _username;
    final standalone = widget.standalone;
    if (username == null || username.isEmpty) {
      final child = const Center(child: Text('Profil bilgisi yüklenemedi.'));
      return standalone ? Scaffold(body: child) : child;
    }

    final profileAsync = ref.watch(publicProfileProvider(username));
    final earnedAsync = _isSelf ? ref.watch(earnedAchievementsProvider) : null;

    final body = RefreshIndicator(
      onRefresh: _refresh,
      child: profileAsync.when(
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
        error: (_, __) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          children: const [
            _SectionCard(
              title: 'Profil yüklenemedi',
              subtitle:
                  'Bağlantını kontrol edip tekrar denediğinde bilgiler yenilenecek.',
            ),
          ],
        ),
        data: (profile) {
          final achievements = _isSelf &&
                  (earnedAsync?.valueOrNull?.isNotEmpty ?? false)
              ? earnedAsync!.valueOrNull!
              : profile.achievements.where((item) => item.isEarned).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              _HeroCard(
                profile: profile,
                isSelf: _isSelf,
                followBusy: _followBusy,
                onFollow: () => _toggleFollow(profile),
                onFollowers: () => _openPeople(
                  'Takipçiler',
                  () => ref
                      .read(profileServiceProvider)
                      .getFollowers(profile.profile.username, limit: 50),
                ),
                onFollowing: () => _openPeople(
                  'Takip edilenler',
                  () => ref
                      .read(profileServiceProvider)
                      .getFollowing(profile.profile.username, limit: 50),
                ),
                onSettings: _isSelf ? () => context.push('/home/settings') : null,
                onHighlights:
                    _isSelf ? () => context.push('/home/highlights') : null,
                onLogout: _isSelf ? _logout : null,
              ),
              const SizedBox(height: 16),
              _StatsGrid(stats: profile.stats),
              const SizedBox(height: 16),
              _LeagueCard(activeLeague: profile.activeLeague),
              const SizedBox(height: 16),
              if (achievements.isNotEmpty)
                AchievementBadgeGrid(
                  achievements: achievements,
                  earnedCount: achievements.where((item) => item.isEarned).length,
                  compact: true,
                  limit: _isSelf ? 6 : null,
                )
              else
                const _SectionCard(
                  title: 'Rozetler',
                  subtitle: 'Henüz gösterilecek bir rozet yok.',
                ),
              if (_isSelf) ...[
                const SizedBox(height: 16),
                const ReadingHeatmapWidget(),
              ],
              const SizedBox(height: 16),
              _HistorySection(history: profile.leagueHistory),
            ],
          );
        },
      ),
    );

    if (!standalone) {
      return SafeArea(child: body);
    }

    return Scaffold(
      appBar: AppBar(title: Text(_isSelf ? 'Profil' : '@$username')),
      body: SafeArea(top: false, child: body),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.profile,
    required this.isSelf,
    required this.followBusy,
    required this.onFollow,
    required this.onFollowers,
    required this.onFollowing,
    this.onSettings,
    this.onHighlights,
    this.onLogout,
  });

  final PublicProfileModel profile;
  final bool isSelf;
  final bool followBusy;
  final VoidCallback onFollow;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback? onSettings;
  final VoidCallback? onHighlights;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final summary = profile.stats.totalParagraphsRead > 0
        ? 'Toplam ${profile.stats.totalParagraphsRead} paragraf okudu.'
        : 'Okuma yolculuğu yeni başlıyor.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [
                  Color(0xFF0F1713),
                  Color(0xFF173524),
                  Color(0xFF102218),
                ]
              : const [
                  Color(0xFFF5F8F3),
                  Color(0xFFE6F3E7),
                  Color(0xFFD4ECD7),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : theme.colorScheme.outline.withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.24)
                : AppColors.primary.withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: profile.profile.name, url: profile.profile.avatarUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.profile.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${profile.profile.username}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.72)
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withOpacity(0.86)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _CountChip(
                  'Takipçi',
                  profile.counts.followers,
                  onFollowers,
                  dark: isDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _CountChip(
                  'Takip',
                  profile.counts.following,
                  onFollowing,
                  dark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (isSelf)
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    'Ayarlar',
                    onSettings,
                    filled: true,
                    dark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    'Alıntılarım',
                    onHighlights,
                    dark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    'Çıkış Yap',
                    onLogout,
                    dark: isDark,
                  ),
                ),
              ],
            )
          else
            SizedBox(
              width: double.infinity,
              child: _ActionButton(
                followBusy
                    ? 'İşleniyor...'
                    : profile.relationship.isFollowing
                    ? 'Takibi Bırak'
                    : 'Takip Et',
                followBusy ? null : onFollow,
                filled: true,
                dark: isDark,
              ),
            ),
        ],
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.stats});

  final ProfileStatsModel stats;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      crossAxisCount: 2,
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _StatCard('Okunan', '${stats.totalParagraphsRead}', Icons.menu_book_rounded),
        _StatCard('Başlanan', '${stats.startedBooks}', Icons.auto_stories_rounded),
        _StatCard('Biten', '${stats.completedBooks}', Icons.task_alt_rounded),
        _StatCard('Seri', '${stats.currentStreak} gün', Icons.local_fire_department_rounded),
      ],
    );
  }
}

class _LeagueCard extends StatelessWidget {
  const _LeagueCard({required this.activeLeague});

  final ProfileLeagueSummaryModel? activeLeague;

  @override
  Widget build(BuildContext context) {
    if (activeLeague == null) {
      return const _SectionCard(
        title: 'Aktif Lig',
        subtitle: 'Henüz aktif lig verisi görünmüyor.',
      );
    }

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            activeLeague!.tierLabel,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill('Sıra', '#${activeLeague!.rank}'),
              _MiniPill('Haftalık LP', '${activeLeague!.weeklyLp}'),
              _MiniPill('Grup', '${activeLeague!.groupNumber}/${activeLeague!.groupSize}'),
              _MiniPill('Düello', '${activeLeague!.duelWins}G • ${activeLeague!.duelLosses}M'),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final List<Map<String, dynamic>> history;

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const _SectionCard(
        title: 'Lig Geçmişi',
        subtitle: 'Tamamlanan sezonlar burada görünecek.',
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: history.map((entry) {
        final result = entry['result'] as String?;
        final label = switch (result) {
          'promoted' => 'Terfi etti',
          'demoted' => 'Lig düşüşü yaşadı',
          'stayed' => 'Yerini korudu',
          _ => 'Sezon sonucu yok',
        };
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _SectionCard(
            title: entry['season'] as String? ?? 'Sezon',
            subtitle:
                '${entry['tier_label'] ?? ''} • $label • #${entry['rank'] ?? '-'}',
          ),
        );
      }).toList(),
    );
  }
}

class _PeopleSheet extends StatelessWidget {
  const _PeopleSheet({required this.title, required this.loader});

  final String title;
  final Future<ProfileFollowPageModel> Function() loader;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<ProfileFollowPageModel>(
          future: loader(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const SizedBox(
                height: 280,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );
            }
            final page = snapshot.data!;
            return SizedBox(
              height: 420,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      itemCount: page.items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = page.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _Avatar(name: item.name, url: item.avatarUrl, size: 48),
                          title: Text(item.name),
                          subtitle: Text('@${item.username}'),
                          onTap: () {
                            Navigator.of(context).pop();
                            if (item.username.isNotEmpty) {
                              context.push('/profil/${item.username}');
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
          ),
        ),
        child: child,
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(subtitle),
          ],
        ),
      );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, this.url, this.size = 72});
  final String name;
  final String? url;
  final double size;
  @override
  Widget build(BuildContext context) {
    final initial = name.isEmpty ? '?' : name.trim()[0].toUpperCase();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.3),
      child: Container(
        width: size,
        height: size,
        color: isDark
            ? Colors.white.withOpacity(0.08)
            : AppColors.primary.withOpacity(0.14),
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(imageUrl: url!, fit: BoxFit.cover)
            : Center(
                child: Text(
                  initial,
                  style: TextStyle(
                    fontSize: size * 0.44,
                    fontWeight: FontWeight.w800,
                    color: isDark ? const Color(0xFF4ADE80) : AppColors.primary,
                  ),
                ),
              ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip(this.label, this.value, this.onTap, {this.dark = false});
  final String label;
  final int value;
  final VoidCallback onTap;
  final bool dark;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withOpacity(0.06)
                : Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withOpacity(0.45),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: dark
                  ? Colors.white.withOpacity(0.08)
                  : Theme.of(context).colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$value',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: dark ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: dark ? Colors.white.withOpacity(0.78) : null,
                ),
              ),
            ],
          ),
        ),
      );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(this.label, this.onTap, {this.filled = false, this.dark = false});
  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool dark;
  @override
  Widget build(BuildContext context) => SizedBox(
        height: 48,
        child: FilledButton.tonal(
          style: FilledButton.styleFrom(
            backgroundColor: filled
                ? AppColors.primary
                : dark
                ? Colors.white.withOpacity(0.08)
                : null,
            foregroundColor: filled
                ? Colors.white
                : dark
                ? Colors.white
                : null,
            side: dark && !filled
                ? BorderSide(color: Colors.white.withOpacity(0.1))
                : null,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard(this.label, this.value, this.icon);
  final String label;
  final String value;
  final IconData icon;
  @override
  Widget build(BuildContext context) => _Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const Spacer(),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            Text(label),
          ],
        ),
      );
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('$label: $value'),
      );
}
