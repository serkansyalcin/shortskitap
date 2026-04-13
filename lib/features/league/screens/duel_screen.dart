import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaplig/app/providers/auth_provider.dart';
import 'package:kitaplig/app/providers/duel_provider.dart';
import 'package:kitaplig/app/providers/kids_provider.dart';
import 'package:kitaplig/app/theme/app_colors.dart';
import 'package:kitaplig/app/theme/app_ui.dart';
import 'package:kitaplig/core/models/duel_model.dart';
import 'package:kitaplig/core/utils/user_friendly_error.dart';

class DuelScreen extends ConsumerStatefulWidget {
  final int duelId;

  const DuelScreen({super.key, required this.duelId});

  @override
  ConsumerState<DuelScreen> createState() => _DuelScreenState();
}

class _DuelScreenState extends ConsumerState<DuelScreen> {
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final duelAsync = ref.watch(duelDetailsProvider(widget.duelId));
    final isKidsMode = ref.watch(kidsModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Düello Detayı', style: AppUI.pageTitle(context)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: duelAsync.when(
        loading: () => Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.cloud_off_rounded,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Düello yüklenemedi',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  userFacingErrorMessage(
                    err,
                    fallback:
                        'Bilgiler alınamadı. Bağlantını kontrol edip tekrar dene.',
                  ),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton.tonal(
                  onPressed: () =>
                      ref.invalidate(duelDetailsProvider(widget.duelId)),
                  child: const Text('Tekrar Dene'),
                ),
              ],
            ),
          ),
        ),
        data: (duel) => _DuelContent(
          duel: duel,
          disableProfileNavigation: isKidsMode,
        ),
      ),
    );
  }
}

class _DuelContent extends StatelessWidget {
  final DuelModel duel;
  final bool disableProfileNavigation;

  const _DuelContent({
    required this.duel,
    this.disableProfileNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [AppColors.darkSurfaceHigh, AppColors.darkBackground]
              : const [Color(0xFFFFFFFF), AppColors.lpGreen50],
        ),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppUI.screenHorizontalPadding,
            AppUI.screenTopPadding,
            AppUI.screenHorizontalPadding,
            32,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DuelHeroCard(
                duel: duel,
                disableProfileNavigation: disableProfileNavigation,
              ),
              const SizedBox(height: AppUI.sectionGap),
              _DuelStats(duel: duel),
              if (duel.isPending) ...[
                const SizedBox(height: AppUI.sectionGap),
                _PendingActions(duel: duel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DuelHeroCard extends StatelessWidget {
  final DuelModel duel;
  final bool disableProfileNavigation;

  const _DuelHeroCard({
    required this.duel,
    this.disableProfileNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.72),
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : AppColors.accent).withValues(
              alpha: isDark ? 0.22 : 0.08,
            ),
            blurRadius: 26,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      duel.isActive
                          ? 'Canlı Karşılaşma'
                          : _statusLabel(duel.status),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark
                            ? AppColors.primaryLight
                            : AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _VersusHeader(
            duel: duel,
            disableProfileNavigation: disableProfileNavigation,
          ),
          const SizedBox(height: 24),
          _ProgressComparison(duel: duel),
        ],
      ),
    );
  }
}

class _VersusHeader extends StatelessWidget {
  final DuelModel duel;
  final bool disableProfileNavigation;

  const _VersusHeader({
    required this.duel,
    this.disableProfileNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _UserAvatar(
            user: duel.challenger,
            label: 'Meydan Okuyan',
            alignEnd: true,
            disableProfileNavigation: disableProfileNavigation,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
          child: _VersusBadge(),
        ),
        Expanded(
          child: _UserAvatar(
            user: duel.opponent,
            label: 'Rakip',
            disableProfileNavigation: disableProfileNavigation,
          ),
        ),
      ],
    );
  }
}

class _VersusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.accent.withValues(alpha: 0.46),
                  AppColors.primary.withValues(alpha: 0.26),
                ]
              : [
                  AppColors.accentSoft,
                  AppColors.primary.withValues(alpha: 0.22),
                ],
        ),
        border: Border.all(
          color: (isDark ? AppColors.primaryLight : AppColors.primary)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Text(
          'VS',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            color: isDark ? AppColors.primaryLight : AppColors.accent,
          ),
        ),
      ),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final DuelUserModel? user;
  final String label;
  final bool alignEnd;
  final bool disableProfileNavigation;

  const _UserAvatar({
    this.user,
    required this.label,
    this.alignEnd = false,
    this.disableProfileNavigation = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;
    final crossAxisAlignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;

    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        InkWell(
          onTap: !disableProfileNavigation && user?.username.isNotEmpty == true
              ? () => context.push('/profil/${user!.username}')
              : null,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.accentSoft,
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.28),
              ),
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Colors.transparent,
              backgroundImage: user?.avatarUrl != null
                  ? NetworkImage(user!.avatarUrl!)
                  : null,
              child: user?.avatarUrl == null
                  ? Icon(
                      Icons.person_rounded,
                      size: 38,
                      color: isDark ? AppColors.primaryLight : AppColors.accent,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 132),
          child: InkWell(
            onTap: !disableProfileNavigation && user?.username.isNotEmpty == true
                ? () => context.push('/profil/${user!.username}')
                : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                user?.name ?? 'Bilinmiyor',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: textAlign,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: textAlign,
        ),
      ],
    );
  }
}

class _ProgressComparison extends StatelessWidget {
  final DuelModel duel;

  const _ProgressComparison({required this.duel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalScore = duel.challengerScore + duel.opponentScore;
    final challengerFlex = totalScore == 0 ? 1 : duel.challengerScore;
    final opponentFlex = totalScore == 0 ? 1 : duel.opponentScore;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _ScorePill(
                label: 'Meydan Okuyan',
                value: '${duel.challengerScore} Paragraf',
                alignEnd: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ScorePill(
                label: 'Rakip',
                value: '${duel.opponentScore} Paragraf',
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: Container(
            height: 18,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: challengerFlex,
                  child: Container(color: AppColors.primary),
                ),
                Expanded(
                  flex: opponentFlex,
                  child: Container(color: AppColors.accent),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _leadSummary(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  String _leadSummary() {
    if (duel.challengerScore == duel.opponentScore) {
      return duel.challengerScore == 0
          ? 'Karşılaşma henüz başlamadı.'
          : 'Şu an skor eşit gidiyor.';
    }

    final leader = duel.challengerScore > duel.opponentScore
        ? duel.challenger?.name ?? 'Meydan okuyan'
        : duel.opponent?.name ?? 'Rakip';
    return '$leader şu an önde gidiyor.';
  }
}

class _ScorePill extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _ScorePill({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final crossAxisAlignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    final textAlign = alignEnd ? TextAlign.end : TextAlign.start;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
            textAlign: textAlign,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
            textAlign: textAlign,
          ),
        ],
      ),
    );
  }
}

class _DuelStats extends StatelessWidget {
  final DuelModel duel;

  const _DuelStats({required this.duel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = _statusColor(context, duel.status);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.72),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Düello Durumu',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(label: _statusLabel(duel.status), color: statusColor),
            ],
          ),
          const SizedBox(height: 18),
          _StatRow(
            label: 'Kalan Süre',
            value: _formatDuration(duel.timeRemaining),
            valueColor: theme.colorScheme.onSurface,
          ),
          Divider(
            height: 28,
            color: theme.colorScheme.outline.withValues(alpha: 0.18),
          ),
          _StatRow(
            label: 'Ödül',
            value: '${duel.pointsAtStake} LP',
            valueColor: AppColors.primary,
          ),
          Divider(
            height: 28,
            color: theme.colorScheme.outline.withValues(alpha: 0.18),
          ),
          _StatRow(
            label: 'Durum',
            value: _statusLabel(duel.status),
            valueColor: statusColor,
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--:--';
    if (duration == Duration.zero) return 'Süre doldu';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    if (hours <= 0) {
      return '$minutes dk';
    }

    return '$hours s $minutes dk';
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
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

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;

  const _StatRow({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingActions extends ConsumerWidget {
  final DuelModel duel;

  const _PendingActions({required this.duel});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.watch(
      authProvider.select((state) => state.user?.id),
    );
    final currentProfileId = ref.watch(
      authProvider.select((state) => state.activeProfile?.id),
    );
    final isIncomingRequest = duel.isIncomingForActor(
      userId: currentUserId,
      readerProfileId: currentProfileId,
    );
    final theme = Theme.of(context);

    Future<void> handleAccept() async {
      final result = await ref.read(duelStateProvider.notifier).accept(duel.id);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    }

    Future<void> handleDecline() async {
      final result = await ref
          .read(duelStateProvider.notifier)
          .decline(duel.id);
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(result.message)));
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.72),
        ),
      ),
      child: isIncomingRequest
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: handleDecline,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onSurface,
                      side: BorderSide(
                        color: theme.colorScheme.outline.withValues(
                          alpha: 0.52,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Reddet'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: FilledButton(
                    onPressed: handleAccept,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Kabul Et'),
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: handleDecline,
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.onSurface,
                  side: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.52),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Teklifi İptal Et'),
              ),
            ),
    );
  }
}

String _statusLabel(String status) {
  return switch (status) {
    'pending' => 'Onay Bekliyor',
    'active' => 'Devam Ediyor',
    'completed' => 'Tamamlandı',
    'expired' => 'Süre Doldu',
    'declined' => 'Reddedildi',
    _ => status,
  };
}

Color _statusColor(BuildContext context, String status) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return switch (status) {
    'pending' => isDark ? AppColors.primaryLight : AppColors.primary,
    'active' => AppColors.accent,
    'completed' => AppColors.primary,
    'expired' => Theme.of(context).colorScheme.onSurfaceVariant,
    'declined' => Theme.of(context).colorScheme.error,
    _ => Theme.of(context).colorScheme.onSurfaceVariant,
  };
}
