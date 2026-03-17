import 'package:flutter/material.dart';
import 'package:kitaplig/core/models/league_model.dart';

class LeagueHeader extends StatelessWidget {
  final LeagueStatusModel status;
  final bool showBackButton;

  const LeagueHeader({
    super.key,
    required this.status,
    required this.showBackButton,
  });

  @override
  Widget build(BuildContext context) {
    final membership = status.membership;
    final season = status.season;
    final tierColor = Color(
      int.parse(membership.tierColor.replaceFirst('#', 'FF'), radix: 16),
    );
    final progressToPromotion =
        membership.xpToPromotion == null || membership.xpToPromotion! <= 0
        ? 1.0
        : (1 - (membership.xpToPromotion! / 600).clamp(0, 1)).toDouble();

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tierColor.withValues(alpha: 0.30), const Color(0xFF151515)],
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: tierColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: tierColor.withValues(alpha: 0.16),
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
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
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
                  color: Colors.white.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'Sezon ${season.number} · ${season.daysRemaining} gün kaldı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
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
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
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
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Grup ${membership.groupNumber} · ${membership.groupSize} okuyucu',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF101010).withValues(alpha: 0.74),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _HeaderMetric(
                        icon: Icons.flash_on_rounded,
                        label: 'Bu hafta',
                        value: '${membership.weeklyXp} XP',
                        accent: const Color(0xFFFBBF24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeaderMetric(
                        icon: Icons.military_tech_rounded,
                        label: 'Sıralama',
                        value: '#${membership.rank}',
                        accent: const Color(0xFF60A5FA),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _HeaderMetric(
                        icon: Icons.trending_up_rounded,
                        label:
                            membership.xpToPromotion != null &&
                                membership.xpToPromotion! > 0
                            ? 'Terfiye kaldı'
                            : 'Durum',
                        value:
                            membership.xpToPromotion != null &&
                                membership.xpToPromotion! > 0
                            ? '${membership.xpToPromotion} XP'
                            : 'Hazır',
                        accent: const Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        membership.isInPromotionZone
                            ? 'Terfi bölgesindesin'
                            : membership.isInDemotionZone
                            ? 'Düşme hattından çık'
                            : 'Biraz daha yüksel',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      membership.isInPromotionZone
                          ? 'Güçlü gidiyorsun'
                          : membership.isInDemotionZone
                          ? 'Riskli alan'
                          : 'Hedefe yaklaş',
                      style: TextStyle(
                        color: membership.isInPromotionZone
                            ? const Color(0xFF4ADE80)
                            : membership.isInDemotionZone
                            ? const Color(0xFFF87171)
                            : const Color(0xFFFBBF24),
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
                    minHeight: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    color: membership.isInDemotionZone
                        ? const Color(0xFFF87171)
                        : tierColor,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 10),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
