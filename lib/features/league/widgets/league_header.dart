import 'package:flutter/material.dart';
import 'package:kitaplig/core/models/league_model.dart';

class LeagueHeader extends StatelessWidget {
  final LeagueStatusModel status;
  final Color tierColor;

  const LeagueHeader({super.key, required this.status, required this.tierColor});

  @override
  Widget build(BuildContext context) {
    final m = status.membership;
    final s = status.season;
    final isInPromotion = m.isInPromotionZone;
    final isInDemotion = m.isInDemotionZone;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            tierColor,
            tierColor.withOpacity(0.7),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Season info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Sezon ${s.number}  •  ${s.daysRemaining} gün kaldı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Tier icon + name
              Text(m.tierIcon, style: const TextStyle(fontSize: 36)),
              const SizedBox(height: 2),
              Text(
                m.tierLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Grup ${m.groupNumber}  •  ${m.groupSize} okuyucu',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 8),

              // XP + Rank row
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  _StatChip(
                    icon: '⚡',
                    label: '${m.weeklyXp} XP',
                    subtitle: 'Bu hafta',
                  ),
                  _StatChip(
                    icon: '🎯',
                    label: '#${m.rank}',
                    subtitle: '${m.groupSize} içinde',
                    highlight: isInPromotion,
                  ),
                  if (m.xpToPromotion != null && m.xpToPromotion! > 0)
                    _StatChip(
                      icon: '🚀',
                      label: '+${m.xpToPromotion} XP',
                      subtitle: 'Terfiye kadar',
                    ),
                ],
              ),

              // Zone indicator
              if (isInPromotion) ...[
                const SizedBox(height: 6),
                _ZoneBanner(
                  icon: '↑',
                  text: 'Terfi Bölgesinde!',
                  color: Colors.green.shade400,
                ),
              ] else if (isInDemotion) ...[
                const SizedBox(height: 6),
                _ZoneBanner(
                  icon: '⚠',
                  text: 'Düşme tehlikesinde!',
                  color: Colors.red.shade400,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String label;
  final String subtitle;
  final bool highlight;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.subtitle,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withOpacity(0.35)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: Colors.white54, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Text('$icon  $label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 1),
          Text(subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 10,
              )),
        ],
      ),
    );
  }
}

class _ZoneBanner extends StatelessWidget {
  final String icon;
  final String text;
  final Color color;

  const _ZoneBanner({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon,
              style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 4),
          Text(text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
