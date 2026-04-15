import 'package:flutter/material.dart';

import '../ai_story_strings.dart';
import '../models/ai_story_option_model.dart';
import 'ai_story_type_picker.dart';
import 'ai_story_visibility_selector.dart';

class AiStoryFormCard extends StatelessWidget {
  final List<AiStoryOptionModel> types;
  final List<AiStoryOptionModel> visibilityOptions;
  final String selectedType;
  final String selectedVisibility;
  final TextEditingController titleController;
  final TextEditingController themeController;
  final TextEditingController parentPinController;
  final bool showParentPin;
  final bool showAdultInfo;
  final bool isSubmitting;
  final bool showSubmittingState;
  final String submitLabel;
  final ValueChanged<String> onTypeChanged;
  final ValueChanged<String> onVisibilityChanged;
  final VoidCallback onSubmit;

  const AiStoryFormCard({
    super.key,
    required this.types,
    required this.visibilityOptions,
    required this.selectedType,
    required this.selectedVisibility,
    required this.titleController,
    required this.themeController,
    required this.parentPinController,
    required this.showParentPin,
    required this.showAdultInfo,
    required this.isSubmitting,
    this.showSubmittingState = false,
    this.submitLabel = AiStoryStrings.createCta,
    required this.onTypeChanged,
    required this.onVisibilityChanged,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FieldLabel(AiStoryStrings.typeLabel),
          const SizedBox(height: 10),
          AiStoryTypePicker(
            options: types,
            selectedValue: selectedType,
            onChanged: onTypeChanged,
          ),
          if (showAdultInfo) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.22),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AiStoryStrings.adultPrivacyNotice,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          _FieldLabel(AiStoryStrings.titleLabel),
          const SizedBox(height: 8),
          TextField(
            controller: titleController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              hintText: 'Örnek: Ay Işığındaki Orman',
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel(AiStoryStrings.themeLabel),
          const SizedBox(height: 8),
          TextField(
            controller: themeController,
            minLines: 4,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText:
                  'Hikâyenin ana duygusunu, konusunu veya vermesini istediğin mesajı yaz.',
            ),
          ),
          const SizedBox(height: 18),
          _FieldLabel(AiStoryStrings.visibilityLabel),
          const SizedBox(height: 8),
          AiStoryVisibilitySelector(
            options: visibilityOptions,
            selectedValue: selectedVisibility,
            onChanged: onVisibilityChanged,
          ),
          if (showParentPin) ...[
            const SizedBox(height: 8),
            TextField(
              controller: parentPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: AiStoryStrings.parentPinLabel,
                hintText: '4-6 haneli ebeveyn şifresi',
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSubmitting ? null : onSubmit,
              icon: showSubmittingState
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.auto_awesome_rounded),
              label: Text(submitLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;

  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
