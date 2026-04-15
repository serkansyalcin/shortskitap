import 'package:flutter/material.dart';
import 'package:kitaplig/core/models/interactive_element_model.dart';

import '../theme/interaction_palette.dart';
import 'drag_drop_widget.dart';
import 'match_widget.dart';
import 'quiz_widget.dart';

class InteractionWrapperWidget extends StatelessWidget {
  final InteractiveElementModel element;
  final Color accentColor;
  final Function(int points) onCompleted;
  final int pageIndex;

  const InteractionWrapperWidget({
    super.key,
    required this.element,
    required this.accentColor,
    required this.onCompleted,
    this.pageIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    final palette = InteractionPalette.fromAccent(accentColor);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.backgroundAlt, palette.background],
        ),
      ),
      child: Column(children: [Expanded(child: _buildInteraction())]),
    );
  }

  Widget _buildInteraction() {
    if (element.type == 'quiz') {
      return QuizWidget(
        element: element,
        accentColor: accentColor,
        onCompleted: onCompleted,
        pageIndex: pageIndex,
      );
    } else if (element.type == 'drag_drop') {
      return DragDropWidget(
        element: element,
        accentColor: accentColor,
        onCompleted: onCompleted,
      );
    } else if (element.type == 'match') {
      return MatchWidget(
        element: element,
        accentColor: accentColor,
        onCompleted: onCompleted,
      );
    }

    final palette = InteractionPalette.fromAccent(accentColor);

    return Center(
      child: Text(
        'Bilinmeyen etkinlik türü.',
        style: TextStyle(color: palette.text),
      ),
    );
  }
}
