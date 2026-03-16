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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 60),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Season info
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Sezon ${s.number}  •  ${s.daysRemaining} gün kaldı',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tier icon + name
              Text(m.tierIcon, style: const TextStyle(fontSize: 52)),
              const SizedBox(height: 6),
              Text(
                m.tierLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Grup ${m.groupNumber}  •  ${m.groupSize} okuyucu',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              const SizedBox(height: 20),

              // XP + Rank row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _StatChip(
                    icon: '⚡',
                    label: '${m.weeklyXp} XP',
                    subtitle: 'Bu hafta',
                  ),
                  const SizedBox(width: 12),
                  _StatChip(
                    icon: '🎯',
                    label: '#${m.rank}',
                    subtitle: '${m.groupSize} içinde',
                    highlight: isInPromotion,
                  ),
                  if (m.xpToPromotion != null && m.xpToPromotion! > 0) ...[
                    const SizedBox(width: 12),
                    _StatChip(
                      icon: '🚀',
                      label: '+${m.xpToPromotion} XP',
                      subtitle: 'Terfiye kadar',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),

              // Zone indicator
              if (isInPromotion)
                _ZoneBanner(
                  icon: '↑',
                  text: 'Terfi Bölgesinde! Konumunu koru.',
                  color: Colors.green.shade400,
                )
              else if (isInDemotion)
                _ZoneBanner(
                  icon: '⚠',
                  text: 'Düşme tehlikesinde! Daha fazla oku.',
                  color: Colors.red.shade400,
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? Colors.white.withOpacity(0.35)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: Colors.white54, width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          Text('$icon  $label',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 2),
          Text(subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 11,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon,
              style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Text(text,
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
