import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kitaplig/core/models/interactive_element_model.dart';
import 'package:kitaplig/core/services/interaction_service.dart';

import '../theme/interaction_palette.dart';

class QuizWidget extends StatefulWidget {
  final InteractiveElementModel element;
  final Color accentColor;
  final Function(int points) onCompleted;
  final int pageIndex;

  const QuizWidget({
    super.key,
    required this.element,
    required this.accentColor,
    required this.onCompleted,
    required this.pageIndex,
  });

  @override
  State<QuizWidget> createState() => _QuizWidgetState();
}

class _QuizWidgetState extends State<QuizWidget> {
  late final List<Map<String, dynamic>> _questions;
  late final List<String?> _answers;
  int _currentIndex = 0;
  String? _selectedOption;
  bool _hasSubmitted = false;
  bool _isSubmitting = false;
  bool? _wasCurrentAnswerCorrect;

  @override
  void initState() {
    super.initState();
    _questions = _extractQuestions(widget.element.payload);
    _answers = List<String?>.filled(_questions.length, null);
  }

  List<Map<String, dynamic>> _extractQuestions(Map<String, dynamic> payload) {
    final rawQuestions = payload['questions'];

    if (rawQuestions is List) {
      final questions = rawQuestions
          .whereType<Map>()
          .map((question) => Map<String, dynamic>.from(question))
          .toList();

      if (questions.isNotEmpty) {
        return questions;
      }
    }

    return [payload];
  }

  Future<void> _submit() async {
    if (_selectedOption == null || _hasSubmitted) {
      return;
    }

    final correctAnswer = (_questions[_currentIndex]['correct_answer'] ?? '')
        .toString();

    setState(() {
      _answers[_currentIndex] = _selectedOption;
      _hasSubmitted = true;
      _wasCurrentAnswerCorrect = _selectedOption == correctAnswer;
    });
  }

  Future<void> _continueAfterFeedback() async {
    if (!_hasSubmitted || _isSubmitting) {
      return;
    }

    final isLastQuestion = _currentIndex >= _questions.length - 1;

    if (!isLastQuestion) {
      setState(() {
        _currentIndex++;
        _selectedOption = null;
        _hasSubmitted = false;
        _wasCurrentAnswerCorrect = null;
      });
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await InteractionService().submitAnswer(
        elementId: widget.element.id,
        answer: _questions.length == 1
            ? _answers.first
            : _answers.map((answer) => answer ?? '').toList(),
        payload: {'question_count': _questions.length},
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
      ).showSnackBar(SnackBar(content: Text('Quiz sonucu kaydedilemedi: $e')));

      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = InteractionPalette.fromAccent(widget.accentColor);
    final questionPayload = _questions[_currentIndex];
    final String question = questionPayload['question'] ?? 'Soru bulunamadı';
    final List<dynamic> options = questionPayload['options'] ?? [];
    final String correctAnswer = questionPayload['correct_answer'] ?? '';
    final bool isLastQuestion = _currentIndex >= _questions.length - 1;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
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
                'KitapLig Quiz ${_currentIndex + 1}/${_questions.length}',
                style: GoogleFonts.inter(
                  color: palette.accent,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Text(
                      question,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 24,
                        height: 1.4,
                        color: palette.text,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 40),
                    ...options.map((opt) {
                      final String optionStr = opt.toString();
                      final bool isSelected = _selectedOption == optionStr;
                      final bool isCorrectOption = optionStr == correctAnswer;

                      Color bgColor = palette.surface;
                      Color borderColor = palette.border;
                      Color textColor = palette.text;
                      IconData? trailingIcon;

                      if (_hasSubmitted) {
                        if (isCorrectOption) {
                          bgColor = palette.success.withValues(alpha: 0.18);
                          borderColor = palette.success;
                          textColor = palette.success;
                          trailingIcon = Icons.check_circle_rounded;
                        } else if (isSelected) {
                          bgColor = palette.error.withValues(alpha: 0.18);
                          borderColor = palette.error;
                          textColor = palette.error;
                          trailingIcon = Icons.cancel_rounded;
                        }
                      } else if (isSelected) {
                        bgColor = palette.accent.withValues(alpha: 0.24);
                        borderColor = palette.accent;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _hasSubmitted
                                ? null
                                : () {
                                    setState(() {
                                      _selectedOption = optionStr;
                                    });
                                  },
                            borderRadius: BorderRadius.circular(16),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: bgColor,
                                border: Border.all(
                                  color: borderColor,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: isSelected && !_hasSubmitted
                                    ? [
                                        BoxShadow(
                                          color: palette.accent.withValues(
                                            alpha: 0.22,
                                          ),
                                          blurRadius: 8,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      optionStr,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inter(
                                        fontSize: 16,
                                        color: textColor,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  if (trailingIcon != null) ...[
                                    const SizedBox(width: 12),
                                    Icon(
                                      trailingIcon,
                                      color: textColor,
                                      size: 22,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                    if (_hasSubmitted) ...[
                      const SizedBox(height: 12),
                      _QuizFeedbackCard(
                        palette: palette,
                        isCorrect: _wasCurrentAnswerCorrect ?? false,
                        correctAnswer: correctAnswer,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            if (_selectedOption != null && !_hasSubmitted)
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: palette.accent,
                  foregroundColor: palette.onAccent,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 4,
                  shadowColor: palette.accent.withValues(alpha: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Cevabı Kontrol Et',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_hasSubmitted)
              ElevatedButton(
                onPressed: _isSubmitting ? null : _continueAfterFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_wasCurrentAnswerCorrect ?? false)
                      ? palette.success
                      : palette.accent,
                  foregroundColor: palette.onAccent,
                  minimumSize: const Size(double.infinity, 56),
                  elevation: 4,
                  shadowColor:
                      ((_wasCurrentAnswerCorrect ?? false)
                              ? palette.success
                              : palette.accent)
                          .withValues(alpha: 0.42),
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
                        isLastQuestion ? 'Bitir' : 'Sonraki Soru',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _QuizFeedbackCard extends StatelessWidget {
  const _QuizFeedbackCard({
    required this.palette,
    required this.isCorrect,
    required this.correctAnswer,
  });

  final InteractionPalette palette;
  final bool isCorrect;
  final String correctAnswer;

  @override
  Widget build(BuildContext context) {
    final accent = isCorrect ? palette.success : palette.error;
    final title = isCorrect ? 'Doğru cevap!' : 'Bu cevap yanlış.';
    final detail = isCorrect
        ? 'Harika gidiyorsun, aynen devam et.'
        : 'Doğru cevap: $correctAnswer';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.9), width: 1.4),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isCorrect ? Icons.verified_rounded : Icons.info_rounded,
            color: accent,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  detail,
                  style: GoogleFonts.inter(
                    color: palette.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
