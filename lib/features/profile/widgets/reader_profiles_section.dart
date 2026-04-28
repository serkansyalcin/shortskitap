import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/reader_profile_capabilities_model.dart';
import '../../../core/models/reader_profile_model.dart';
import '../../../core/widgets/reader_profile_avatar.dart';

class ReaderProfilesSection extends StatelessWidget {
  const ReaderProfilesSection({
    super.key,
    required this.activeProfile,
    required this.profiles,
    required this.profileCapabilities,
    required this.isPremium,
    required this.onAddProfile,
    required this.onActivateProfile,
    required this.onEditProfile,
    required this.onArchiveProfile,
    required this.onUpgradeTap,
    this.showSectionTitle = true,
    this.parentAvatarUrl,
  });

  final ReaderProfileModel activeProfile;
  final List<ReaderProfileModel> profiles;
  final ReaderProfileCapabilitiesModel profileCapabilities;
  final bool isPremium;
  final VoidCallback onAddProfile;
  final ValueChanged<ReaderProfileModel> onActivateProfile;
  final ValueChanged<ReaderProfileModel> onEditProfile;
  final ValueChanged<ReaderProfileModel> onArchiveProfile;
  final VoidCallback onUpgradeTap;
  final bool showSectionTitle;
  final String? parentAvatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final childProfiles = profiles
        .where((profile) => profile.isChild && !profile.isArchived)
        .toList(growable: false);
    final parentProfile = profiles.firstWhere(
      (profile) => profile.isParent && !profile.isArchived,
      orElse: () => activeProfile,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showSectionTitle)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(
              'OKUYUCU PROFİLLERİ',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ),
        _SectionCardShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ActiveProfileHeader(
                activeProfile: activeProfile,
                parentProfile: parentProfile,
                profileCapabilities: profileCapabilities,
                parentAvatarUrl: parentAvatarUrl,
              ),
              if (!activeProfile.isParent) ...[
                const SizedBox(height: 16),
                _InlineInfoCard(
                  icon: Icons.lock_outline_rounded,
                  title: 'Profil yönetimi ebeveyn profilinde açık',
                  subtitle:
                      'Yeni çocuk profili eklemek veya profilleri düzenlemek için önce ebeveyn profiline dönün.',
                ),
              ] else ...[
                if (!profileCapabilities.canCreateChildProfile) ...[
                  const SizedBox(height: 16),
                  _LimitBanner(
                    isPremium: isPremium,
                    profileCapabilities: profileCapabilities,
                    onUpgradeTap: onUpgradeTap,
                  ),
                ],
                const SizedBox(height: 16),
                if (childProfiles.isEmpty)
                  _EmptyProfilesState(onAddProfile: onAddProfile)
                else
                  Column(
                    children: childProfiles
                        .map(
                          (profile) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _ChildProfileCard(
                              profile: profile,
                              isActive: profile.id == activeProfile.id,
                              onActivate: () => onActivateProfile(profile),
                              onEdit: () => onEditProfile(profile),
                              onArchive: () => onArchiveProfile(profile),
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                if (profileCapabilities.canCreateChildProfile) ...[
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onAddProfile,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Yeni Çocuk Profili'),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionCardShell extends StatelessWidget {
  const _SectionCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(
            alpha: isDark ? 0.34 : 0.52,
          ),
        ),
      ),
      child: child,
    );
  }
}

class _ActiveProfileHeader extends StatelessWidget {
  const _ActiveProfileHeader({
    required this.activeProfile,
    required this.parentProfile,
    required this.profileCapabilities,
    required this.parentAvatarUrl,
  });

  final ReaderProfileModel activeProfile;
  final ReaderProfileModel parentProfile;
  final ReaderProfileCapabilitiesModel profileCapabilities;
  final String? parentAvatarUrl;

  String? _effectiveAvatarRef(ReaderProfileModel profile) {
    if ((profile.avatarUrl ?? '').trim().isNotEmpty) {
      return profile.avatarUrl;
    }
    if (profile.isParent && (parentAvatarUrl ?? '').trim().isNotEmpty) {
      return parentAvatarUrl;
    }
    if (profile.isChild) {
      return ReaderProfileAvatarCatalog.suggestedTokenValue(index: profile.id);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = activeProfile.isChild
        ? const Color(0xFFE91E63)
        : AppColors.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          ReaderProfileAvatar(
            name: activeProfile.name,
            avatarRef: _effectiveAvatarRef(activeProfile),
            size: 52,
            borderRadius: BorderRadius.circular(18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      activeProfile.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    _MiniBadge(
                      label: activeProfile.isChild
                          ? 'Çocuk aktif'
                          : 'Ebeveyn aktif',
                      color: accent,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  activeProfile.isChild
                      ? 'Çocuk modu ${activeProfile.name} profiliyle açık.'
                      : '${parentProfile.name} ebeveyn profili aktif.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoPill(
                      label:
                          'Çocuk profilleri ${profileCapabilities.activeChildProfilesCount}/${profileCapabilities.maxChildProfiles}',
                    ),
                    _InfoPill(
                      label: activeProfile.age != null
                          ? '${activeProfile.age} yaş'
                          : activeProfile.isChild
                          ? 'Yaş eklenmedi'
                          : 'Aile hesabı',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineInfoCard extends StatelessWidget {
  const _InlineInfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
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

class _LimitBanner extends StatelessWidget {
  const _LimitBanner({
    required this.isPremium,
    required this.profileCapabilities,
    required this.onUpgradeTap,
  });

  final bool isPremium;
  final ReaderProfileCapabilitiesModel profileCapabilities;
  final VoidCallback onUpgradeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = isPremium
        ? theme.colorScheme.secondary
        : const Color(0xFFF59E0B);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isPremium
                ? Icons.info_outline_rounded
                : Icons.workspace_premium_rounded,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPremium
                      ? 'Profil limiti dolu'
                      : 'Daha fazla profil için Premium',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isPremium
                      ? 'Bu hesapta ${profileCapabilities.maxChildProfiles} çocuk profili sınırına ulaşıldı.'
                      : 'Ücretsiz hesaplarda en fazla ${profileCapabilities.maxChildProfiles} çocuk profili oluşturabilirsiniz.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
                if (!isPremium) ...[
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: onUpgradeTap,
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      alignment: Alignment.centerLeft,
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                    label: const Text('Premium\'a Geç'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyProfilesState extends StatelessWidget {
  const _EmptyProfilesState({required this.onAddProfile});

  final VoidCallback onAddProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Henüz çocuk profili yok',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Yeni bir çocuk profili oluşturarak çocuk modunu belirli bir okuyucu profiliyle kullanabilirsiniz.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onAddProfile,
            icon: const Icon(Icons.add_rounded),
            label: const Text('İlk Profili Oluştur'),
          ),
        ],
      ),
    );
  }
}

class _ChildProfileCard extends StatelessWidget {
  const _ChildProfileCard({
    required this.profile,
    required this.isActive,
    required this.onActivate,
    required this.onEdit,
    required this.onArchive,
  });

  final ReaderProfileModel profile;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onEdit;
  final VoidCallback onArchive;

  String? get _effectiveAvatarRef {
    if ((profile.avatarUrl ?? '').trim().isNotEmpty) {
      return profile.avatarUrl;
    }
    return ReaderProfileAvatarCatalog.suggestedTokenValue(index: profile.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = const Color(0xFFE91E63);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border.all(
          color: isActive
              ? accent.withValues(alpha: 0.38)
              : theme.colorScheme.outline.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ReaderProfileAvatar(
                name: profile.name,
                avatarRef: _effectiveAvatarRef,
                size: 48,
                borderRadius: BorderRadius.circular(16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          profile.name,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        if (isActive) _MiniBadge(label: 'Aktif', color: accent),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile.age != null
                          ? '${profile.age} yaşında'
                          : 'Yaş eklenmedi',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: isActive ? null : onActivate,
                child: Text(isActive ? 'Aktif Profil' : 'Bu Profile Geç'),
              ),
              OutlinedButton(onPressed: onEdit, child: const Text('Düzenle')),
              TextButton(
                onPressed: onArchive,
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurfaceVariant,
                ),
                child: const Text('Arşivle'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withValues(alpha: 0.12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: theme.colorScheme.surfaceContainerHigh,
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }
}
