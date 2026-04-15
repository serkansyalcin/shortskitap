import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kitaplig/core/models/interactive_element_model.dart';
import 'package:kitaplig/core/services/interaction_service.dart';

import '../theme/interaction_palette.dart';

class DragDropWidget extends StatefulWidget {
  final InteractiveElementModel element;
  final Color accentColor;
  final Function(int points) onCompleted;

  const DragDropWidget({
    super.key,
    required this.element,
    required this.accentColor,
    required this.onCompleted,
  });

  @override
  State<DragDropWidget> createState() => _DragDropWidgetState();
}

class _DragDropWidgetState extends State<DragDropWidget> {
  late final List<Map<String, dynamic>> _rounds;
  late final List<String?> _answers;
  late List<String> _allItems;
  int _currentIndex = 0;
  bool _isRoundSolved = false;
  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool? _feedbackIsSuccess;

  @override
  void initState() {
    super.initState();
    _rounds = _extractRounds(widget.element.payload);
    _answers = List<String?>.filled(_rounds.length, null);
    _setRoundItems();
  }

  List<Map<String, dynamic>> _extractRounds(Map<String, dynamic> payload) {
    final rawRounds = payload['rounds'];

    if (rawRounds is List) {
      final rounds = rawRounds
          .whereType<Map>()
          .map((round) => Map<String, dynamic>.from(round))
          .toList();

      if (rounds.isNotEmpty) {
        return rounds;
      }
    }

    return [payload];
  }

  void _setRoundItems() {
    final payload = _rounds[_currentIndex];
    final draggableItem = payload['item'] ?? 'Doğru Parça';
    final List<dynamic> distractors = payload['distractors'] ?? [];

    _allItems = [draggableItem, ...distractors.map((e) => e.toString())];
    _allItems.shuffle();
  }

  Future<void> _acceptItem(String item) async {
    final payload = _rounds[_currentIndex];
    final draggableItem = payload['item'] ?? 'Doğru Parça';

    if (_isRoundSolved || _isSubmitting) {
      return;
    }

    if (item != draggableItem) {
      setState(() {
        _feedbackIsSuccess = false;
        _feedbackMessage = 'Bu parça yanlış. Bir daha dene.';
      });
      return;
    }

    setState(() {
      _answers[_currentIndex] = item;
      _isRoundSolved = true;
      _feedbackIsSuccess = true;
      _feedbackMessage = 'Doğru parça! Harika ilerliyorsun.';
    });
  }

  Future<void> _continueAfterFeedback() async {
    if (!_isRoundSolved || _isSubmitting) {
      return;
    }

    final isLastRound = _currentIndex >= _rounds.length - 1;

    if (!isLastRound) {
      setState(() {
        _currentIndex++;
        _isRoundSolved = false;
        _feedbackMessage = null;
        _feedbackIsSuccess = null;
        _setRoundItems();
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await InteractionService().submitAnswer(
        elementId: widget.element.id,
        answer: _rounds.length == 1
            ? _answers.first
            : _answers.map((answer) => answer ?? '').toList(),
        payload: {'question_count': _rounds.length},
      );

      if (!mounted) {
        return;
      }

      widget.onCompleted(result['points_awarded'] ?? 0);
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oyun sonucu kaydedilemedi: $e')));

      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = InteractionPalette.fromAccent(widget.accentColor);
    final payload = _rounds[_currentIndex];
    final instruction = payload['instruction'] ?? 'Doğru öğeyi sürükle';
    final targetText = payload['target'] ?? 'Hedef Alan';
    final isLastRound = _currentIndex >= _rounds.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: palette.accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: palette.accent.withValues(alpha: 0.32),
                ),
              ),
              child: Text(
                'KitapLig Sürükle & Bırak ${_currentIndex + 1}/${_rounds.length}',
                style: GoogleFonts.inter(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              instruction,
              textAlign: TextAlign.center,
              style: GoogleFonts.lora(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: palette.text,
                height: 1.3,
              ),
            ),
            const Spacer(),
            DragTarget<String>(
              builder: (context, candidateData, rejectedData) {
                final isHovering = candidateData.isNotEmpty;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 260,
                  height: 180,
                  decoration: BoxDecoration(
                    color: _isRoundSolved
                        ? palette.success.withValues(alpha: 0.16)
                        : (isHovering
                              ? palette.accent.withValues(alpha: 0.16)
                              : palette.surface),
                    border: Border.all(
                      color: _isRoundSolved
                          ? palette.success
                          : (isHovering ? palette.accent : palette.border),
                      width: 3,
                    ),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: isHovering || _isRoundSolved
                        ? [
                            BoxShadow(
                              color:
                                  (_isRoundSolved
                                          ? palette.success
                                          : palette.accent)
                                      .withValues(alpha: 0.22),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      _isRoundSolved ? 'Doğru cevap!' : targetText,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        color: _isRoundSolved
                            ? palette.success
                            : palette.mutedText,
                        fontWeight: _isRoundSolved
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
              onWillAcceptWithDetails: (details) =>
                  !_isRoundSolved && !_isSubmitting,
              onAcceptWithDetails: (details) => _acceptItem(details.data),
            ),
            const SizedBox(height: 20),
            if (_feedbackMessage != null)
              _DragDropFeedbackCard(
                palette: palette,
                message: _feedbackMessage!,
                isSuccess: _feedbackIsSuccess ?? false,
              ),
            const Spacer(),
            if (!_isRoundSolved)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                alignment: WrapAlignment.center,
                children: _allItems.map((item) {
                  return Draggable<String>(
                    data: item,
                    feedback: Material(
                      color: Colors.transparent,
                      child: _buildItemCard(item, palette, isDragging: true),
                    ),
                    childWhenDragging: Opacity(
                      opacity: 0.3,
                      child: _buildItemCard(item, palette),
                    ),
                    child: _buildItemCard(item, palette),
                  );
                }).toList(),
              ),
            if (_isRoundSolved) ...[
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _continueAfterFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.success,
                  foregroundColor: palette.onAccent,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: palette.onAccent,
                        ),
                      )
                    : Text(
                        isLastRound ? 'Bitir' : 'Sonraki Tur',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(
    String text,
    InteractionPalette palette, {
    bool isDragging = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isDragging ? palette.surfaceStrong : palette.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: palette.accent.withValues(alpha: isDragging ? 0.3 : 0.1),
            blurRadius: isDragging ? 15 : 5,
            offset: Offset(0, isDragging ? 8 : 2),
          ),
        ],
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 15,
          color: palette.text,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DragDropFeedbackCard extends StatelessWidget {
  const _DragDropFeedbackCard({
    required this.palette,
    required this.message,
    required this.isSuccess,
  });

  final InteractionPalette palette;
  final String message;
  final bool isSuccess;

  @override
  Widget build(BuildContext context) {
    final accent = isSuccess ? palette.success : palette.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.9), width: 1.4),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle_rounded : Icons.info_rounded,
            color: accent,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                color: palette.text,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
