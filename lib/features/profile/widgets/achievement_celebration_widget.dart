import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/models/achievement_model.dart';

/// Overlay widget that shows a new achievement celebration.
/// Wrap your Scaffold body in a Stack and add this on top.
class AchievementCelebrationOverlay extends StatefulWidget {
  final AchievementModel achievement;
  final VoidCallback onDismiss;

  const AchievementCelebrationOverlay({
    super.key,
    required this.achievement,
    required this.onDismiss,
  });

  @override
  State<AchievementCelebrationOverlay> createState() =>
      _AchievementCelebrationOverlayState();
}

class _AchievementCelebrationOverlayState
    extends State<AchievementCelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _controller.reverse().then((_) {
          if (mounted) widget.onDismiss();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final rarityColor = _rarityColor(widget.achievement.rarity);

    return FadeTransition(
      opacity: _fadeAnim,
      child: GestureDetector(
        onTap: () {
          _controller.reverse().then((_) {
            if (mounted) widget.onDismiss();
          });
        },
        child: Container(
          color: Colors.black.withValues(alpha: 0.55),
          alignment: Alignment.center,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: rarityColor.withValues(alpha: 0.45),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: rarityColor.withValues(alpha: 0.35),
                    blurRadius: 40,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: rarityColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '🎉 Yeni Rozet Kazandın!',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: rarityColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SparkleIcon(
                    icon: widget.achievement.icon ?? '🎖️',
                    color: rarityColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.achievement.title ?? widget.achievement.key,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: colorScheme.onSurface,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.achievement.description != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.achievement.description!,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  if (widget.achievement.xpReward > 0) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 18)),
                          const SizedBox(width: 8),
                          Text(
                            '+${widget.achievement.xpReward} XP',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Dokunarak kapat',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _rarityColor(AchievementRarity rarity) => switch (rarity) {
    AchievementRarity.common => const Color(0xFF6B7280),
    AchievementRarity.uncommon => const Color(0xFF10B981),
    AchievementRarity.rare => const Color(0xFF3B82F6),
    AchievementRarity.epic => const Color(0xFF8B5CF6),
    AchievementRarity.legendary => const Color(0xFFFFD35C),
  };
}

class _SparkleIcon extends StatefulWidget {
  final String icon;
  final Color color;

  const _SparkleIcon({required this.icon, required this.color});

  @override
  State<_SparkleIcon> createState() => _SparkleIconState();
}

class _SparkleIconState extends State<_SparkleIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _rotationAnim = Tween<double>(
      begin: -0.05,
      end: 0.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotationAnim,
      builder: (context, child) =>
          Transform.rotate(angle: _rotationAnim.value, child: child),
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          shape: BoxShape.circle,
          border: Border.all(
            color: widget.color.withValues(alpha: 0.35),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.color.withValues(alpha: 0.3),
              blurRadius: 20,
            ),
          ],
        ),
        child: Center(
          child: Text(widget.icon, style: const TextStyle(fontSize: 38)),
        ),
      ),
    );
  }
}
