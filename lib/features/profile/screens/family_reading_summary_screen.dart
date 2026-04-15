import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/family_reading_summary_provider.dart';
import '../../../app/theme/app_ui.dart';
import '../widgets/family_reading_summary_panel.dart';

class FamilyReadingSummaryScreen extends ConsumerWidget {
  const FamilyReadingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auth = ref.watch(authProvider);
    final summaryAsync = ref.watch(familyReadingSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Aile Okuma Özeti')),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            20,
            16,
            20,
            AppUI.screenBottomContentPadding,
          ),
          children: [
            Text(
              'Aile hesabındaki profillerin son dönemdeki okuma yoğunluğunu ve tamamlanan kitaplarını burada detaylı görebilirsiniz.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) {
                if (summary == null) {
                  return const SizedBox.shrink();
                }

                return FamilyReadingSummaryPanel(
                  summary: summary,
                  maxVisibleProfiles: summary.profiles.length,
                  parentAvatarUrl: auth.user?.avatarUrl,
                  showDescription: false,
                  showHiddenProfilesHint: false,
                );
              },
              loading: () => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.18),
                  ),
                ),
                child: const Center(child: CircularProgressIndicator()),
              ),
              error: (error, stackTrace) => Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  _familySummaryErrorText(error),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _familySummaryErrorText(Object error) {
  final raw = error.toString().trim();
  if (raw.isEmpty) {
    return 'Aile özeti şu anda yüklenemedi.';
  }

  if (raw.startsWith('Bad state: ')) {
    return raw.replaceFirst('Bad state: ', '');
  }

  return raw;
}
