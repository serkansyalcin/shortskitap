import 'package:flutter/material.dart';
import '../../../app/theme/app_colors.dart';

enum PremiumBadgeSize { small, medium, large }

class PremiumBadge extends StatelessWidget {
  final PremiumBadgeSize size;
  final bool showLabel;

  const PremiumBadge({
    super.key,
    this.size = PremiumBadgeSize.medium,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final (iconSize, fontSize, padH, padV) = switch (size) {
      PremiumBadgeSize.small  => (10.0, 9.0,  5.0, 2.0),
      PremiumBadgeSize.medium => (13.0, 11.0, 7.0, 3.0),
      PremiumBadgeSize.large  => (16.0, 13.0, 10.0, 4.0),
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('👑', style: TextStyle(fontSize: iconSize)),
          if (showLabel) ...[
            const SizedBox(width: 3),
            Text(
              'Premium',
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Crown-only icon (e.g. next to a username in a leaderboard)
class PremiumCrownIcon extends StatelessWidget {
  final double size;

  const PremiumCrownIcon({super.key, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size + 6,
      height: size + 6,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFD700), Color(0xFFFFA000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '👑',
          style: TextStyle(fontSize: size * 0.75),
        ),
      ),
    );
  }
}

/// Upgrade CTA banner — shown in profile/settings for non-premium users
class UpgradeBanner extends StatelessWidget {
  final VoidCallback onTap;

  const UpgradeBanner({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const Text('👑', style: TextStyle(fontSize: 36)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Premium\'a Geç',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Reklamsız okuma, tüm kitaplar ve daha fazlası',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Keşfet',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
