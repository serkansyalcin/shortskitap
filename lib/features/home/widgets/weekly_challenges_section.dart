import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/challenge_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/challenge_model.dart';
import '../../../core/utils/user_friendly_error.dart';

class WeeklyChallengesSection extends ConsumerWidget {
  const WeeklyChallengesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengesAsync = ref.watch(challengesProvider);
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haftalık Görevler',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: scheme.onSurface,
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Tamamla, XP ve LP kazan.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            challengesAsync.whenOrNull(
              data: (list) {
                final done = list.where((c) => c.isCompleted && !c.isClaimed).length;
                if (done == 0) return null;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$done alınmayı bekliyor',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                );
              },
            ) ?? const SizedBox.shrink(),
          ],
        ),
        const SizedBox(height: 12),
        challengesAsync.when(
          loading: () => const _ChallengesSkeletonList(),
          error: (e, _) => Center(
            child: Text(
              userFacingErrorMessage(e, fallback: 'Görevler yüklenemedi.'),
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          data: (challenges) {
            if (challenges.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Bu hafta için görev bulunmuyor.',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              );
            }
            return Column(
              children: challenges
                  .map((c) => _ChallengeTile(challenge: c, isDark: isDark))
                  .toList(),
            );
          },
        ),
      ],
    );
  }
}

class _ChallengeTile extends ConsumerStatefulWidget {
  const _ChallengeTile({required this.challenge, required this.isDark});
  final ChallengeModel challenge;
  final bool isDark;

  @override
  ConsumerState<_ChallengeTile> createState() => _ChallengeTileState();
}

class _ChallengeTileState extends ConsumerState<_ChallengeTile> {
  bool _claiming = false;

  Future<void> _claim() async {
    if (_claiming) return;
    setState(() => _claiming = true);
    try {
      await ref.read(challengesProvider.notifier).claim(widget.challenge.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🎉 +${widget.challenge.xpReward} XP${widget.challenge.lpReward > 0 ? ' · +${widget.challenge.lpReward} LP' : ''} kazandın!',
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userFacingErrorMessage(e, fallback: 'Ödül alınamadı.'))),
        );
      }
    } finally {
      if (mounted) setState(() => _claiming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.challenge;
    final scheme = Theme.of(context).colorScheme;
    final isDark = widget.isDark;

    final Color cardBg = c.isClaimed
        ? scheme.surfaceContainerHighest.withValues(alpha: isDark ? 0.3 : 0.5)
        : c.isCompleted
            ? AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.08)
            : isDark
                ? const Color(0xFF1C1C1C)
                : Colors.white;

    final Color borderColor = c.isClaimed
        ? scheme.outline.withValues(alpha: 0.1)
        : c.isCompleted
            ? AppColors.primary.withValues(alpha: 0.4)
            : scheme.outline.withValues(alpha: 0.15);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (c.icon != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Text(c.icon!, style: const TextStyle(fontSize: 22)),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.title,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: c.isClaimed
                              ? scheme.onSurfaceVariant
                              : scheme.onSurface,
                          decoration: c.isClaimed ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      Text(
                        c.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _RewardBadge(xp: c.xpReward, lp: c.lpReward, dimmed: c.isClaimed),
              ],
            ),
            const SizedBox(height: 10),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: c.progressPct / 100,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                valueColor: AlwaysStoppedAnimation(
                  c.isClaimed
                      ? scheme.onSurfaceVariant.withValues(alpha: 0.3)
                      : c.isCompleted
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  c.isClaimed
                      ? 'Tamamlandı ✓'
                      : '${c.currentValue} / ${c.targetValue}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: c.isCompleted && !c.isClaimed
                        ? AppColors.primary
                        : scheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                if (c.isCompleted && !c.isClaimed)
                  SizedBox(
                    height: 30,
                    child: FilledButton(
                      onPressed: _claiming ? null : _claim,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: _claiming
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Ödülü al'),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RewardBadge extends StatelessWidget {
  const _RewardBadge({required this.xp, required this.lp, required this.dimmed});
  final int xp;
  final int lp;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Opacity(
      opacity: dimmed ? 0.45 : 1.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (xp > 0)
            _pill('+$xp XP', const Color(0xFF4CAF50), isDark),
          if (lp > 0) ...[
            const SizedBox(height: 3),
            _pill('+$lp LP', const Color(0xFF2196F3), isDark),
          ],
        ],
      ),
    );
  }

  Widget _pill(String text, Color color, bool isDark) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? color.withValues(alpha: 0.9) : color,
          ),
        ),
      );
}

class _ChallengesSkeletonList extends StatelessWidget {
  const _ChallengesSkeletonList();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: List.generate(
        3,
        (_) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            height: 90,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ),
      ),
    );
  }
}
