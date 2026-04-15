import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_ui.dart';
import '../../../core/models/book_model.dart';
import '../../../core/utils/user_friendly_error.dart' show apiFormErrorMessage, userFacingErrorMessage;
import '../ai_story_strings.dart';
import '../providers/ai_story_provider.dart';
import '../widgets/ai_story_form_card.dart';
import '../widgets/ai_story_generation_dialog.dart';
import '../widgets/ai_story_preview_card.dart';
import '../widgets/ai_story_quota_banner.dart';

class AiStoryStudioScreen extends ConsumerStatefulWidget {
  const AiStoryStudioScreen({super.key});

  @override
  ConsumerState<AiStoryStudioScreen> createState() =>
      _AiStoryStudioScreenState();
}

class _AiStoryStudioScreenState extends ConsumerState<AiStoryStudioScreen> {
  final _titleController = TextEditingController();
  final _themeController = TextEditingController();
  final _parentPinController = TextEditingController();
  bool _isSubmitting = false;
  String? _selectedType;
  String? _selectedVisibility;

  @override
  void dispose() {
    _titleController.dispose();
    _themeController.dispose();
    _parentPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(aiStoryStudioConfigProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AiStoryStrings.studioTitle)),
      body: configAsync.when(
        data: (config) {
          _selectedType ??= config.types.isNotEmpty ? config.types.first.value : '';
          _selectedVisibility ??= config.defaultVisibility;

          final matchingTypes = config.types
              .where((item) => item.value == _selectedType)
              .toList(growable: false);
          final selectedTypeOption =
              matchingTypes.isNotEmpty ? matchingTypes.first : null;
          final isAdultType = selectedTypeOption?.isAdult == true;

          if (isAdultType && _selectedVisibility != 'private') {
            _selectedVisibility = 'private';
          }

          final selectedVisibility =
              _selectedVisibility ?? config.defaultVisibility;
          final showParentPin =
              config.publicRequiresParentPin && selectedVisibility == 'public';
          final latestStories = ref.watch(myAiStoriesProvider(null)).valueOrNull;
          final latestBook =
              latestStories != null && latestStories.isNotEmpty
                  ? latestStories.first
                  : null;
          final activeGeneration = config.activeGeneration;
          final hasActiveGeneration = activeGeneration?.isActive == true;
          final canGenerate = config.quota.canGenerate && !hasActiveGeneration;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppUI.screenHorizontalPadding,
              AppUI.screenTopPadding,
              AppUI.screenHorizontalPadding,
              AppUI.screenBottomContentPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AiStoryStrings.studioSubtitle,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                AiStoryQuotaBanner(quota: config.quota),
                if (!config.quota.canGenerate) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .errorContainer
                          .withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.error.withValues(alpha: 0.22),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AiStoryStrings.quotaLimitTitle,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                config.quota.isPremium
                                    ? AiStoryStrings.quotaLimitPremiumDescription
                                    : AiStoryStrings.quotaLimitFreeDescription,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.45,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (activeGeneration != null && activeGeneration.isActive) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.28),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top_rounded),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AiStoryStrings.activeGenerationNotice,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: _isSubmitting
                              ? null
                              : () => _openGenerationDialog(activeGeneration.id),
                          child: const Text(AiStoryStrings.watchGeneration),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                AiStoryFormCard(
                  types: config.types,
                  visibilityOptions: config.visibilityOptions,
                  selectedType: _selectedType ?? '',
                  selectedVisibility: selectedVisibility,
                  titleController: _titleController,
                  themeController: _themeController,
                  parentPinController: _parentPinController,
                  showParentPin: showParentPin,
                  showAdultInfo: isAdultType,
                  isSubmitting: _isSubmitting || !canGenerate,
                  showSubmittingState: _isSubmitting,
                  submitLabel: _isSubmitting
                      ? 'Hikâye hazırlanıyor...'
                      : !config.quota.canGenerate
                      ? AiStoryStrings.quotaLimitButton
                      : AiStoryStrings.createCta,
                  onTypeChanged: (value) => setState(() => _selectedType = value),
                  onVisibilityChanged: (value) => setState(() {
                    if (isAdultType && value == 'public') {
                      _selectedVisibility = 'private';
                      _showSnackBar(AiStoryStrings.adultPrivacyNotice);
                      return;
                    }
                    _selectedVisibility = value;
                  }),
                  onSubmit: () => _generateStory(),
                ),
                if (latestBook != null) ...[
                  const SizedBox(height: 18),
                  AiStoryPreviewCard(book: latestBook),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => AppUI.errorState(
          context,
          message: 'AI Hikâye Stüdyosu yüklenemedi',
          detail: userFacingErrorMessage(error),
          onRetry: () => ref.invalidate(aiStoryStudioConfigProvider),
        ),
      ),
    );
  }

  Future<void> _generateStory() async {
    final selectedType = _selectedType;
    final selectedVisibility = _selectedVisibility;

    if (selectedType == null || selectedType.isEmpty) {
      _showSnackBar('Lütfen bir tür seç.');
      return;
    }
    if (selectedVisibility == null || selectedVisibility.isEmpty) {
      _showSnackBar('Lütfen görünürlük seç.');
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      _showSnackBar('Lütfen bir başlık yaz.');
      return;
    }
    if (_themeController.text.trim().isEmpty) {
      _showSnackBar('Lütfen hikâyenin temasını yaz.');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final generation = await ref.read(aiStoryServiceProvider).generateStory(
            type: selectedType,
            title: _titleController.text.trim(),
            theme: _themeController.text.trim(),
            visibility: selectedVisibility,
            parentPin: _parentPinController.text.trim().isEmpty
                ? null
                : _parentPinController.text.trim(),
          );

      ref.invalidate(aiStoryStudioConfigProvider);

      if (!mounted) return;
      await _openGenerationDialog(generation.id);
    } on DioException catch (error) {
      ref.invalidate(aiStoryStudioConfigProvider);
      _showSnackBar(
        apiFormErrorMessage(
          error,
          fallback:
              'AI hikâye şu anda oluşturulamadı. Lütfen bilgileri kontrol edip tekrar dene.',
        ),
      );
    } catch (error) {
      _showSnackBar(userFacingErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openGenerationDialog(int generationId) async {
    final result = await showDialog<Object?>(
      context: context,
      barrierDismissible: true,
      builder: (_) => AiStoryGenerationDialog(generationId: generationId),
    );

    ref.invalidate(aiStoryStudioConfigProvider);
    ref.invalidate(myAiStoriesProvider(null));
    ref.invalidate(myAiStoriesProvider('private'));
    ref.invalidate(myAiStoriesProvider('public'));
    ref.invalidate(discoverAiStoriesProvider);

    if (!mounted) return;
    if (result is! BookModel) {
      return;
    }
    context.push('/books/${result.slug}');
  }
}
