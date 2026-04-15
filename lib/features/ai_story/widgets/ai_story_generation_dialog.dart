import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../ai_story_strings.dart';
import '../models/ai_story_generation_model.dart';
import '../providers/ai_story_provider.dart';

class AiStoryGenerationDialog extends ConsumerStatefulWidget {
  final int generationId;

  const AiStoryGenerationDialog({
    super.key,
    required this.generationId,
  });

  @override
  ConsumerState<AiStoryGenerationDialog> createState() =>
      _AiStoryGenerationDialogState();
}

class _AiStoryGenerationDialogState
    extends ConsumerState<AiStoryGenerationDialog> {
  AiStoryGenerationModel? _generation;
  Timer? _pollTimer;
  bool _loading = true;
  String? _error;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _pollTimer = Timer.periodic(const Duration(seconds: 2), (_) => _fetch());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetch() async {
    try {
      final generation = await ref
          .read(aiStoryServiceProvider)
          .getGenerationStatus(widget.generationId);

      if (!mounted) return;

      setState(() {
        _generation = generation;
        _loading = false;
        _error = null;
      });

      if (!generation.isActive) {
        _pollTimer?.cancel();
      }

      if (generation.isCompleted &&
          generation.book != null &&
          mounted &&
          !_navigated) {
        _navigated = true;
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        Navigator.of(context).pop(generation.book);
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = userFacingErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final generation = _generation;

    return PopScope(
      canPop: true,
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: _loading
              ? const SizedBox(
                  height: 170,
                  child: Center(child: CircularProgressIndicator()),
                )
              : _error != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: colorScheme.error,
                      size: 34,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'AI hikâye durumu alınamadı',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _fetch,
                      child: const Text('Tekrar dene'),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AiStoryStrings.closeAction),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            generation!.isCompleted
                                ? 'Hikâye hazır'
                                : generation.isFailed
                                ? 'Hikâye hazırlanamadı'
                                : 'Hikâye hazırlanıyor...',
                            style: TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w800,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      _stepText(generation.step),
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 10,
                        value: generation.isFailed
                            ? 0
                            : generation.isCompleted
                            ? 1
                            : generation.progressRatio,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      generation.isCompleted
                          ? 'Tamamlandı'
                          : generation.isFailed
                          ? (generation.errorMessage ?? 'Hazırlama sırasında hata oluştu.')
                          : '${generation.progressCurrent}/${generation.progressTotal} adım',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (generation.isFailed) ...[
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(AiStoryStrings.closeAction),
                      ),
                    ],
                    if (generation.isActive) ...[
                      const SizedBox(height: 16),
                      Text(
                        AiStoryStrings.autoOpenHint,
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.45,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          AiStoryStrings.backgroundContinueAction,
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }

  String _stepText(String? step) {
    switch (step) {
      case 'queued':
        return AiStoryStrings.queuedStatus;
      case 'starting':
        return AiStoryStrings.startingStatus;
      case 'outline':
        return AiStoryStrings.outlineStatus;
      case 'cover':
        return AiStoryStrings.coverStatus;
      case 'done':
        return AiStoryStrings.doneStatus;
      case 'failed':
        return AiStoryStrings.failedStatus;
      default:
        if (step != null && step.startsWith('chapter_')) {
          final index = int.tryParse(step.replaceFirst('chapter_', ''));
          if (index != null) {
            return '$index. bölüm yazılıyor.';
          }
        }
        return 'Hikâye hazırlanıyor...';
    }
  }
}
