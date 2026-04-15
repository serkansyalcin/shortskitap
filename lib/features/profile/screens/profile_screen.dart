import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/achievements_provider.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/kids_provider.dart';
import '../../../app/providers/profile_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/models/public_profile_model.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/subscription_service.dart';
import '../widgets/achievement_badge_grid.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/reader_profile_dialogs.dart';
import '../widgets/reading_heatmap_widget.dart';
import '../../home/widgets/kids_mode_exit_dialog.dart';
import '../../home/widgets/kids_mode_pin_set_dialog.dart';
import '../../subscription/widgets/premium_badge.dart';

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
    ref.invalidate(publicProfileProvider(username));
    await ref.read(publicProfileProvider(username).future);
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
            'Oturumunu kapatmak istediğine emin misin?',
            style: TextStyle(
              color: scheme.onSurface.withValues(alpha: 0.92),
              height: 1.45,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('İptal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Çıkış Yap'),
            ),
          ],
        );
      },
    );
    if (approved != true) return;
    await ref.read(authProvider.notifier).logout();
    if (mounted) context.go('/login');
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

  static const Color _kidsAccent = Color(0xFFE91E63);

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

  Future<void> _onKidsModeSwitch(bool wantOn) async {
    if (wantOn) {
      final auth = ref.read(authProvider);
      var childProfiles = auth.profiles
          .where((profile) => profile.isChild && !profile.isArchived)
          .toList(growable: false);

      if (childProfiles.isEmpty) {
        final name = await ReaderProfileDialogs.showCreateChildProfileDialog(
          context,
        );
        if (name == null || name.trim().isEmpty) return;

        final created = await ref
            .read(authProvider.notifier)
            .createChildProfile(name: name.trim());
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
      return;
    }

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
    final ok = await KidsModeExitDialog.show(context, verifyPin: svc.verifyPin);
    if (ok == true && mounted) {
      await ref
          .read(authProvider.notifier)
          .activateReaderProfile(parentProfile.id as int);
    }
  }

  Future<void> _onOpenParentPinDialog() async {
    if (ref.read(kidsModeProvider)) {
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
        final service = await ref.read(kidsModePinServiceProvider.future);
        await service.setPin(pin);
        ref.invalidate(kidsModePinServiceProvider);
        await ref.read(authProvider.notifier).refreshMe();
      },
    );
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ebeveyn şifresi kaydedildi.')),
      );
    }
  }

  String _planLabel(SubscriptionStatus? status) {
    if (status == null) return 'Pro üyelik';
    if ((status.planLabel ?? '').trim().isNotEmpty) return status.planLabel!;

    return switch (status.planType) {
      'monthly' => 'Aylık paket',
      'yearly' => 'Yıllık paket',
      'lifetime' => 'Ömür boyu paket',
      _ => 'Pro üyelik',
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

    return 'Pro üyelik aktif değil';
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

    return 'Pro üyelik aktif değil';
  }

  Future<void> _showPremiumDetailsModal(
    BuildContext context,
    UserModel? user,
    SubscriptionStatus? status,
  ) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final planLabel = _planLabel(status);
    final startedAt = _premiumStartedText(user, status);
    final expiresAt = _premiumExpiresText(user, status);
    final detailCardColors = isDark
        ? const [Color(0xFF202520), Color(0xFF171B18)]
        : const [Color(0xFFFFFBEB), Color(0xFFF7F0D9)];
    final detailCardBorderColor = isDark
        ? const Color(0xFFF6C35B).withValues(alpha: 0.24)
        : const Color(0xFFF59E0B).withValues(alpha: 0.18);
    final detailLabelColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : colorScheme.onSurfaceVariant;
    final detailValueColor = isDark ? Colors.white : colorScheme.onSurface;
    final detailIconBackgroundColor = isDark
        ? const Color(0xFF4A3715)
        : const Color(0xFFF59E0B).withValues(alpha: 0.14);
    final detailIconColor = isDark
        ? const Color(0xFFF7C65B)
        : const Color(0xFFB45309);
    final activePanelColor = isDark
        ? const Color(0xFF1D2B1A)
        : AppColors.primary.withValues(alpha: 0.08);
    final activePanelTextColor = isDark
        ? Colors.white.withValues(alpha: 0.94)
        : colorScheme.onSurface;

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
                    color: isDark
                        ? const Color(0xFF3A2A12)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Pro üyelik',
                    style: TextStyle(
                      color: isDark
                          ? const Color(0xFFF7C65B)
                          : const Color(0xFFB45309),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Üyelik detayların',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Satın aldığın paket ve erişim tarihlerinin özeti burada görünüyor.',
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
                      colors: detailCardColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(color: detailCardBorderColor),
                  ),
                  child: Column(
                    children: [
                      _MembershipDetailRow(
                        icon: Icons.workspace_premium_rounded,
                        label: 'Paket adı',
                        value: planLabel,
                        labelColor: detailLabelColor,
                        valueColor: detailValueColor,
                        iconBackgroundColor: detailIconBackgroundColor,
                        iconColor: detailIconColor,
                      ),
                      const SizedBox(height: 14),
                      _MembershipDetailRow(
                        icon: Icons.calendar_month_rounded,
                        label: 'Başlangıç tarihi',
                        value: startedAt,
                        labelColor: detailLabelColor,
                        valueColor: detailValueColor,
                        iconBackgroundColor: detailIconBackgroundColor,
                        iconColor: detailIconColor,
                      ),
                      const SizedBox(height: 14),
                      _MembershipDetailRow(
                        icon: Icons.event_available_rounded,
                        label: status?.isLifetime == true
                            ? 'Erişim'
                            : 'Bitiş tarihi',
                        value: expiresAt,
                        labelColor: detailLabelColor,
                        valueColor: detailValueColor,
                        iconBackgroundColor: detailIconBackgroundColor,
                        iconColor: detailIconColor,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: activePanelColor,
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
                          'Reklamsız okuma, Pro kitaplara erişim ve üyelik ayrıcalıkların şu anda aktif.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: activePanelTextColor,
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
    final authState = ref.watch(authProvider);
    final currentUser = _isSelf ? authState.user : null;
    final subscriptionStatus = _isSelf
        ? ref.watch(subscriptionProvider).valueOrNull
        : null;
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
        error: (_, stackTrace) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppUI.screenHorizontalPadding),
          children: const [
            _SectionCard(
              title: 'Profil yüklenemedi',
              subtitle:
                  'Bağlantını kontrol edip tekrar denediğinde bilgiler yenilenecek.',
            ),
          ],
        ),
        data: (profile) {
          final isPremium = _isSelf
              ? (subscriptionStatus?.isPremium == true) ||
                    (currentUser?.isPremium == true) ||
                    profile.profile.isPremium
              : profile.profile.isPremium;
          final achievements =
              _isSelf && (earnedAsync?.valueOrNull?.isNotEmpty ?? false)
              ? earnedAsync!.valueOrNull!
              : profile.achievements.where((item) => item.isEarned).toList();

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppUI.screenHorizontalPadding,
              AppUI.screenTopPadding,
              AppUI.screenHorizontalPadding,
              28,
            ),
            children: [
              _HeroCard(
                profile: profile,
                isSelf: _isSelf,
                isPremium: isPremium,
                premiumPlanLabel: isPremium
                    ? _planLabel(subscriptionStatus)
                    : null,
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
                onSettings: _isSelf
                    ? () => context.push('/home/settings')
                    : null,
                onHighlights: _isSelf
                    ? () => context.push('/home/highlights')
                    : null,
                onLogout: _isSelf ? _logout : null,
                onPremiumTap: _isSelf && !isPremium
                    ? () => context.push('/premium')
                    : null,
                onPremiumDetailsTap: _isSelf && isPremium
                    ? () => _showPremiumDetailsModal(
                        context,
                        currentUser,
                        subscriptionStatus,
                      )
                    : null,
              ),
              const SizedBox(height: AppUI.sectionGap),
              _StatsGrid(stats: profile.stats),
              const SizedBox(height: AppUI.sectionGap),
              _LeagueCard(activeLeague: profile.activeLeague),
              const SizedBox(height: AppUI.sectionGap),
              if (achievements.isNotEmpty)
                AchievementBadgeGrid(
                  achievements: achievements,
                  earnedCount: achievements
                      .where((item) => item.isEarned)
                      .length,
                  compact: true,
                  limit: _isSelf ? 6 : null,
                )
              else
                const _SectionCard(
                  title: 'Rozetler',
                  subtitle: 'Henüz gösterilecek bir rozet yok.',
                ),
              if (_isSelf) ...[
                const SizedBox(height: AppUI.sectionGap),
                const ReadingHeatmapWidget(),
                const SizedBox(height: AppUI.sectionGap),
                _KidsModeProfileSection(
                  accent: _kidsAccent,
                  onToggleKidsMode: _onKidsModeSwitch,
                  onOpenParentPin: _onOpenParentPinDialog,
                ),
              ],
              const SizedBox(height: AppUI.sectionGap),
              _HistorySection(history: profile.leagueHistory),
              if (_isSelf) ...[
                const SizedBox(height: AppUI.sectionGap),
                _DeleteAccountSection(onTap: _showDeleteAccountDialog),
              ],
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
    required this.isPremium,
    required this.followBusy,
    required this.onFollow,
    required this.onFollowers,
    required this.onFollowing,
    this.premiumPlanLabel,
    this.onSettings,
    this.onHighlights,
    this.onLogout,
    this.onPremiumTap,
    this.onPremiumDetailsTap,
  });

  final PublicProfileModel profile;
  final bool isSelf;
  final bool isPremium;
  final bool followBusy;
  final VoidCallback onFollow;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final String? premiumPlanLabel;
  final VoidCallback? onSettings;
  final VoidCallback? onHighlights;
  final VoidCallback? onLogout;
  final VoidCallback? onPremiumTap;
  final VoidCallback? onPremiumDetailsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasPremium = isPremium || profile.profile.isPremium;
    final summary = profile.stats.totalParagraphsRead > 0
        ? 'Toplam ${profile.stats.totalParagraphsRead} paragraf okudu.'
        : 'Okuma yolculuğu yeni başlıyor.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F1713), Color(0xFF173524), Color(0xFF102218)]
              : const [Color(0xFFF5F8F3), Color(0xFFE6F3E7), Color(0xFFD4ECD7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : theme.colorScheme.outline.withValues(alpha: 0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.24)
                : AppColors.primary.withValues(alpha: 0.08),
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
              _Avatar(
                name: profile.profile.name,
                url: profile.profile.avatarUrl,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            profile.profile.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasPremium) ...[
                          const SizedBox(width: 8),
                          _ProfileProBadge(
                            onTap: isSelf ? onPremiumDetailsTap : null,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${profile.profile.username}',
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.72)
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      summary,
                      style: TextStyle(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.86)
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isSelf && hasPremium) ...[
            const SizedBox(height: 16),
            _MembershipBanner(
              planLabel: premiumPlanLabel ?? 'Pro üyelik',
              onTap: onPremiumDetailsTap,
            ),
          ],
          if (isSelf && !hasPremium && onPremiumTap != null) ...[
            const SizedBox(height: 16),
            _UpgradeToProCard(onTap: onPremiumTap!),
          ],
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

class _ProfileProBadge extends StatelessWidget {
  const _ProfileProBadge({this.onTap});

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFBBF24), Color(0xFFF59E0B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.white.withValues(alpha: 0.28),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withValues(alpha: 0.22),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: 15,
            color: Color(0xFF4B2A00),
          ),
          SizedBox(width: 4),
          Text(
            'PRO',
            style: TextStyle(
              color: Color(0xFF4B2A00),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return badge;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: badge,
      ),
    );
  }
}

class _MembershipBanner extends StatelessWidget {
  const _MembershipBanner({required this.planLabel, this.onTap});

  final String planLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor = isDark ? Colors.white : theme.colorScheme.onSurface;
    final subtitleColor = isDark
        ? Colors.white.withValues(alpha: 0.82)
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: isDark
                  ? const [Color(0xFF1D2B22), Color(0xFF172219)]
                  : const [Color(0xFFF7FBEF), Color(0xFFEAF4E1)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: isDark
                  ? const Color(0xFFF6C35B).withValues(alpha: 0.34)
                  : const Color(0xFFF59E0B).withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            children: [
              const PremiumBadge(
                size: PremiumBadgeSize.medium,
                showLabel: false,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pro üyesin',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$planLabel • Detayları görmek için dokun',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: subtitleColor),
            ],
          ),
        ),
      ),
    );
  }
}

class _UpgradeToProCard extends StatelessWidget {
  const _UpgradeToProCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = theme.brightness == Brightness.dark
        ? Colors.white
        : theme.colorScheme.onSurface;
    final subtitleColor = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.78)
        : theme.colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: theme.brightness == Brightness.dark
                  ? const [Color(0xFF1A2117), Color(0xFF112B1A)]
                  : const [Color(0xFFF7FBEF), Color(0xFFE7F6DA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.24),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Pro'ya Geç",
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reklamsız okuma, tüm kitaplar ve ekstra ayrıcalıkları aç.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text(
                  'İncele',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MembershipDetailRow extends StatelessWidget {
  const _MembershipDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.labelColor,
    this.valueColor,
    this.iconBackgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? labelColor;
  final Color? valueColor;
  final Color? iconBackgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color:
                iconBackgroundColor ??
                const Color(0xFFF59E0B).withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFFB45309),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: labelColor ?? theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
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
      childAspectRatio: 1.8,
      children: [
        _StatCard(
          'Okunan',
          '${stats.totalParagraphsRead}',
          'assets/icons/books-read.svg',
        ),
        _StatCard(
          'Başlanan',
          '${stats.startedBooks}',
          Icons.auto_stories_rounded,
        ),
        _StatCard(
          'Biten',
          '${stats.completedBooks}',
          'assets/icons/line-dock.svg',
        ),
        _StatCard(
          'Seri',
          '${stats.currentStreak} gün',
          Icons.local_fire_department_rounded,
        ),
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
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniPill('Sıra', '#${activeLeague!.rank}'),
              _MiniPill('Haftalık LP', '${activeLeague!.weeklyLp}'),
              _MiniPill(
                'Grup',
                '${activeLeague!.groupNumber}/${activeLeague!.groupSize}',
              ),
              _MiniPill(
                'Düello',
                '${activeLeague!.duelWins}G • ${activeLeague!.duelLosses}M',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ana sayfa profil sekmesiyle aynı mantık; `_DeleteAccountSection` kart diliyle uyumlu.
class _KidsModeProfileSection extends ConsumerWidget {
  const _KidsModeProfileSection({
    required this.accent,
    required this.onToggleKidsMode,
    required this.onOpenParentPin,
  });

  final Color accent;
  final Future<void> Function(bool wantOn) onToggleKidsMode;
  final Future<void> Function() onOpenParentPin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = accent.withValues(alpha: isDark ? 0.45 : 0.35);
    final kidsOn = ref.watch(kidsModeProvider);
    final pinAsync = ref.watch(kidsModePinServiceProvider);
    final userHasParentPin = ref.watch(
      authProvider.select((state) => state.user?.hasParentPin),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'ÇOCUK MODU',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: borderColor),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: isDark ? 0.22 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.child_care_rounded,
                          color: accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Çocuk modu',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Yalnızca çocuklara uygun kitaplar gösterilir',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: kidsOn,
                        onChanged: (v) => onToggleKidsMode(v),
                        activeThumbColor: accent,
                        activeTrackColor: accent.withValues(alpha: 0.45),
                        inactiveThumbColor: isDark
                            ? Colors.grey.shade600
                            : Colors.grey.shade400,
                        inactiveTrackColor: isDark
                            ? Colors.white.withValues(alpha: 0.12)
                            : Colors.grey.shade300,
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 16,
                  endIndent: 16,
                  color: theme.colorScheme.outline.withValues(
                    alpha: isDark ? 0.2 : 0.35,
                  ),
                ),
                pinAsync.when(
                  data: (svc) => InkWell(
                    onTap: () => onOpenParentPin(),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 16,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            color: accent,
                            size: 26,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ebeveyn şifresi',
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  kidsOn
                                      ? ((userHasParentPin ?? svc.hasPin())
                                            ? 'Şifreyi değiştirmek için önce ebeveyn profiline dönün'
                                            : 'Şifreyi ebeveyn profiline döndükten sonra belirleyin')
                                      : (userHasParentPin ?? svc.hasPin())
                                      ? 'Çıkış için şifre tanımlı — değiştirmek için dokun'
                                      : 'Çocuk modundan çıkmak için şifre belirleyin',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  error: (_, stackTrace) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Profil sonunda — ayarlardaki "Tehlikeli alan" ile aynı görsel dil (açık/koyu).
class _DeleteAccountSection extends StatelessWidget {
  const _DeleteAccountSection({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = const Color(
      0xFFDC2626,
    ).withValues(alpha: isDark ? 0.45 : 0.35);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TEHLİKELİ ALAN',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.4,
            ),
          ),
        ),
        Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.delete_forever_outlined,
                    color: const Color(0xFFDC2626),
                    size: 26,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hesabı Sil',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFFDC2626),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tüm verilerin kalıcı olarak silinir',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
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
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = page.items[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: _Avatar(
                            name: item.name,
                            url: item.avatarUrl,
                            size: 48,
                          ),
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
        color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.7),
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
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
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
            ? Colors.white.withValues(alpha: 0.08)
            : AppColors.primary.withValues(alpha: 0.14),
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
            ? Colors.white.withValues(alpha: 0.06)
            : Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.08)
              : Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
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
              color: dark ? Colors.white.withValues(alpha: 0.78) : null,
            ),
          ),
        ],
      ),
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton(
    this.label,
    this.onTap, {
    this.filled = false,
    this.dark = false,
  });
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
            ? Colors.white.withValues(alpha: 0.08)
            : null,
        foregroundColor: filled
            ? Colors.white
            : dark
            ? Colors.white
            : null,
        side: dark && !filled
            ? BorderSide(color: Colors.white.withValues(alpha: 0.1))
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  final Object icon;
  @override
  Widget build(BuildContext context) {
    final mappedAsset = switch (label) {
      'Okunan' => 'assets/icons/books-read.svg',
      'Başlanan' => 'assets/icons/books.svg',
      'Biten' => 'assets/icons/line-dock.svg',
      'Seri' => 'assets/icons/time.svg',
      _ => null,
    };
    final svgAsset = icon is String ? icon as String : mappedAsset;

    return _Card(
      child: Align(
        alignment: Alignment.centerLeft,
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: svgAsset != null
                  ? SvgPicture.asset(
                      svgAsset,
                      colorFilter: const ColorFilter.mode(
                        AppColors.primary,
                        BlendMode.srcIn,
                      ),
                    )
                  : Icon(icon as IconData, color: AppColors.primary, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(label),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: Theme.of(
        context,
      ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text('$label: $value'),
  );
}
