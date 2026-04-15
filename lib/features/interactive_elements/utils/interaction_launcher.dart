import 'package:flutter/material.dart';
import 'package:kitaplig/core/models/interactive_element_model.dart';

import '../theme/interaction_palette.dart';
import '../widgets/interaction_wrapper.dart';

class InteractionLauncher {
  static Future<void> show({
    required BuildContext context,
    required InteractiveElementModel element,
    required Color accentColor,
    required Function(int points) onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      builder: (context) {
        final palette = InteractionPalette.fromAccent(accentColor);

        return Container(
          height: MediaQuery.of(context).size.height,
          decoration: BoxDecoration(
            color: palette.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: palette.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close_rounded, color: palette.mutedText),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: InteractionWrapperWidget(
                  element: element,
                  accentColor: accentColor,
                  onCompleted: onCompleted,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
