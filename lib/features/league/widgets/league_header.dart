import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaplig/app/theme/app_colors.dart';
import 'package:kitaplig/core/models/league_model.dart';

class LeagueHeader extends StatelessWidget {
  final LeagueStatusModel status;
  final bool showBackButton;
  final bool isKidsMode;

  const LeagueHeader({
    super.key,
    required this.status,
    required this.showBackButton,
    this.isKidsMode = false,
  });

  static const _dangerColor = Color(0xFFD95C5C);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final membership = status.membership;
    final season = status.season;
    final progressToPromotion =
        membership.lpToPromotion == null || membership.lpToPromotion! <= 0
        ? 1.0
        : (1 - (membership.lpToPromotion! / 600).clamp(0, 1)).toDouble();

    final shellColor = isDark
        ? AppColors.darkSurfaceHigh
        : AppColors.lightSurfaceMuted;
    final promotionColor = isDark ? AppColors.primaryLight : AppColors.primary;
    final neutralColor = isDark ? AppColors.lpGreen300 : AppColors.lpDGreen400;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            shellColor,
            isDark ? AppColors.darkBackground : Colors.white,
          ],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: (isDark ? AppColors.primary : AppColors.accent).withValues(
            alpha: isDark ? 0.22 : 0.16,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? AppColors.primary : AppColors.accent).withValues(
              alpha: isDark ? 0.16 : 0.08,
            ),
            blurRadius: 34,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/home');
                    }
                  },
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: theme.colorScheme.onSurface,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark
                        ? AppColors.darkSurfaceMuted.withValues(alpha: 0.96)
                        : Colors.white.withValues(alpha: 0.94),
                  ),
                )
              else
                const SizedBox(width: 4),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.darkSurfaceMuted.withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isDark
                        ? AppColors.primary.withValues(alpha: 0.16)
                        : AppColors.lightOutline.withValues(alpha: 0.95),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sezon ${season.number} · ${season.daysRemaining} gün kaldı',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (membership.streakShields > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 1,
                        height: 12,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.shield_rounded,
                        color: isDark ? AppColors.lpGreen300 : AppColors.accent,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'x${membership.streakShields}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Spacer(),
              const SizedBox(width: 44),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 86,
              height: 86,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkSurfaceMuted.withValues(alpha: 0.96)
                    : Colors.white.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? AppColors.primary.withValues(alpha: 0.18)
                      : AppColors.lightOutline.withValues(alpha: 0.95),
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                membership.tierIcon,
                style: const TextStyle(fontSize: 42),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            membership.tierLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grup ${membership.groupNumber} · ${membership.groupSize} ${isKidsMode ? 'arkadaş' : 'okuyucu'}',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _HeaderMetric(
                  icon: Icons.flash_on_rounded,
                  label: 'Bu hafta',
                  value: '${membership.weeklyLp} ${isKidsMode ? 'Puan' : 'LP'}',
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderMetric(
                  icon: Icons.military_tech_rounded,
                  label: 'Sıralama',
                  value: '#${membership.rank}',
                  accent: AppColors.accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HeaderMetric(
                  icon: Icons.trending_up_rounded,
                  label: membership.lpToPromotion != null &&
                          membership.lpToPromotion! > 0
                      ? 'Terfiye kaldı'
                      : 'Durum',
                  value: membership.lpToPromotion != null &&
                          membership.lpToPromotion! > 0
                      ? '${membership.lpToPromotion} LP'
                      : 'Hazır',
                  accent: AppColors.lpGreen700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        membership.isInPromotionZone
                            ? (isKidsMode
                                ? 'Ödül bölgesindesin'
                                : 'Terfi bölgesindesin')
                            : membership.isInDemotionZone
                                ? (isKidsMode ? 'Daha fazla oku' : 'Düşme hattından çık')
                                : 'Biraz daha yüksel',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      membership.isInPromotionZone
                          ? (isKidsMode ? 'Süpersin!' : 'Güçlü gidiyorsun')
                          : membership.isInDemotionZone
                              ? (isKidsMode ? 'Daha fazla oku' : 'Riskli alan')
                              : 'Hedefe yaklaş',
                      style: TextStyle(
                        color: membership.isInPromotionZone
                            ? promotionColor
                            : membership.isInDemotionZone
                                ? _dangerColor
                                : neutralColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progressToPromotion,
                    minHeight: 10,
                    backgroundColor: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : theme.colorScheme.outline.withValues(alpha: 0.15),
                    color: membership.isInDemotionZone
                        ? _dangerColor
                        : promotionColor,
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

class _HeaderMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _HeaderMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }
}
