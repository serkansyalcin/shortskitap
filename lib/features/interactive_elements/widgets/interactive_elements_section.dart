import 'package:flutter/material.dart';
import 'package:kitaplig/core/models/interactive_element_model.dart';

import '../utils/interaction_launcher.dart';

class InteractiveElementsSection extends StatelessWidget {
  const InteractiveElementsSection({
    super.key,
    required this.elements,
    required this.accentColor,
    this.title = 'Etkinlikler & Oyunlar',
    this.titleStyle,
  });

  final List<InteractiveElementModel> elements;
  final Color accentColor;
  final String title;
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    if (elements.isEmpty) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style:
              titleStyle ??
              Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 12),
        ...elements.map(
          (element) => _InteractiveElementCard(
            element: element,
            accentColor: accentColor,
          ),
        ),
      ],
    );
  }
}

class _InteractiveElementCard extends StatelessWidget {
  const _InteractiveElementCard({
    required this.element,
    required this.accentColor,
  });

  final InteractiveElementModel element;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final questionCount = _questionCount(element);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.36),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openInteraction(context),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: accentColor.withValues(alpha: 0.14)),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(_iconFor(element.type), color: accentColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleFor(element.type),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        questionCount == null
                            ? '+${element.rewardPoints} LP'
                            : '$questionCount soru • +${element.rewardPoints} LP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.play_circle_fill_rounded,
                  color: accentColor.withValues(alpha: 0.72),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openInteraction(BuildContext context) {
    InteractionLauncher.show(
      context: context,
      element: element,
      accentColor: accentColor,
      onCompleted: (points) {
        if (!context.mounted) {
          return;
        }

        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              points > 0
                  ? 'Tebrikler! $points LP kazandın.'
                  : 'Doğru cevapları gördün, ama bu etkinlikten ek puan gelmedi.',
            ),
          ),
        );
      },
    );
  }
}

String _titleFor(String type) {
  switch (type) {
    case 'quiz':
      return 'Mini Test';
    case 'drag_drop':
      return 'Sürükle & Bırak';
    case 'match':
      return 'Eşleştirme';
    default:
      return 'Oyun';
  }
}

IconData _iconFor(String type) {
  switch (type) {
    case 'quiz':
      return Icons.quiz_rounded;
    case 'drag_drop':
      return Icons.drag_indicator_rounded;
    case 'match':
      return Icons.join_inner_rounded;
    default:
      return Icons.extension_rounded;
  }
}

int? _questionCount(InteractiveElementModel element) {
  final payload = element.payload;
  final rawItems = switch (element.type) {
    'quiz' => payload['questions'],
    'drag_drop' => payload['rounds'],
    'match' => payload['pairs'],
    _ => null,
  };

  if (rawItems is List && rawItems.isNotEmpty) {
    return rawItems.length;
  }

  return null;
}
