import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/reader_profile_capabilities_model.dart';
import '../../../core/models/reader_profile_model.dart';
import '../../../core/widgets/reader_profile_avatar.dart';

class ReaderProfilesSummaryCard extends StatelessWidget {
  const ReaderProfilesSummaryCard({
    super.key,
    required this.activeProfile,
    required this.profileCapabilities,
    required this.onTap,
    this.parentAvatarUrl,
  });

  final ReaderProfileModel activeProfile;
  final ReaderProfileCapabilitiesModel profileCapabilities;
  final VoidCallback onTap;
  final String? parentAvatarUrl;

  String? get _effectiveAvatarRef {
    if ((activeProfile.avatarUrl ?? '').trim().isNotEmpty) {
      return activeProfile.avatarUrl;
    }
    if (activeProfile.isParent && (parentAvatarUrl ?? '').trim().isNotEmpty) {
      return parentAvatarUrl;
    }
    if (activeProfile.isChild) {
      return ReaderProfileAvatarCatalog.suggestedTokenValue(
        index: activeProfile.id,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = activeProfile.isChild
        ? const Color(0xFFE91E63)
        : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Material(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(
                    alpha: isDark ? 0.34 : 0.52,
                  ),
                ),
              ),
              child: Row(
                children: [
                  ReaderProfileAvatar(
                    name: activeProfile.name,
                    avatarRef: _effectiveAvatarRef,
                    size: 56,
                    borderRadius: BorderRadius.circular(20),
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
                            _SummaryBadge(
                              label: activeProfile.isChild
                                  ? 'Çocuk aktif'
                                  : 'Ebeveyn aktif',
                              color: accent,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          activeProfile.isChild
                              ? 'Profil yönetimi için ebeveyn profiline dönüp detay sayfasını açabilirsiniz.'
                              : 'Çocuk profillerini ve geçiş işlemlerini buradan yönetin.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _SummaryPill(
                              label:
                                  '${profileCapabilities.activeChildProfilesCount}/${profileCapabilities.maxChildProfiles} çocuk profili',
                            ),
                            _SummaryPill(
                              label: activeProfile.birthYear != null
                                  ? 'Doğum yılı ${activeProfile.birthYear}'
                                  : activeProfile.isChild
                                  ? 'Doğum yılı eklenmedi'
                                  : 'Aile hesabı',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.7,
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

class _SummaryBadge extends StatelessWidget {
  const _SummaryBadge({required this.label, required this.color});

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

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
