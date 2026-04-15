import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:kitaplig/core/models/interactive_element_model.dart';
import 'package:kitaplig/core/services/interaction_service.dart';

import '../theme/interaction_palette.dart';

class MatchWidget extends StatefulWidget {
  final InteractiveElementModel element;
  final Color accentColor;
  final Function(int points) onCompleted;

  const MatchWidget({
    super.key,
    required this.element,
    required this.accentColor,
    required this.onCompleted,
  });

  @override
  State<MatchWidget> createState() => _MatchWidgetState();
}

class _MatchWidgetState extends State<MatchWidget> {
  final Map<String, String> _matches = {};
  String? _selectedLeft;
  String? _selectedRight;
  bool _isSuccess = false;
  bool _isSubmitting = false;
  String? _feedbackMessage;
  bool? _feedbackIsSuccess;
  late List<String> _leftItems;
  late List<String> _rightItems;

  @override
  void initState() {
    super.initState();
    final List<dynamic> pairs = widget.element.payload['pairs'] ?? [];
    _leftItems = pairs.map((p) => p['left'].toString()).toList();
    _rightItems = pairs.map((p) => p['right'].toString()).toList();
    _rightItems.shuffle();
  }

  void _onLeftTap(String item) {
    if (_matches.containsKey(item) || _isSuccess) {
      return;
    }

    setState(() {
      _selectedLeft = _selectedLeft == item ? null : item;
      _checkMatch();
    });
  }

  void _onRightTap(String item) {
    if (_matches.containsValue(item) || _isSuccess) {
      return;
    }

    setState(() {
      _selectedRight = _selectedRight == item ? null : item;
      _checkMatch();
    });
  }

  void _checkMatch() {
    if (_selectedLeft == null || _selectedRight == null) {
      return;
    }

    final List<dynamic> pairs = widget.element.payload['pairs'] ?? [];
    final bool isCorrect = pairs.any(
      (p) =>
          p['left'].toString() == _selectedLeft &&
          p['right'].toString() == _selectedRight,
    );

    if (isCorrect) {
      _matches[_selectedLeft!] = _selectedRight!;
      _feedbackIsSuccess = true;
      _feedbackMessage =
          'Doğru eşleştirme! ${_matches.length}/${_leftItems.length} tamamlandı.';
      _selectedLeft = null;
      _selectedRight = null;

      if (_matches.length == _leftItems.length) {
        _submitResult();
      }

      return;
    }

    _feedbackIsSuccess = false;
    _feedbackMessage = 'Bu ikili eşleşmiyor. Tekrar dene.';
    _selectedLeft = null;
    _selectedRight = null;
  }

  Future<void> _submitResult() async {
    setState(() {
      _isSuccess = true;
      _isSubmitting = true;
      _feedbackIsSuccess = true;
      _feedbackMessage = 'Harika! Tüm eşleştirmeleri doğru yaptın.';
    });

    int pointsAwarded = 0;

    try {
      final List<Map<String, String>> submission = _matches.entries
          .map((e) => {'left': e.key, 'right': e.value})
          .toList();

      final result = await InteractionService().submitAnswer(
        elementId: widget.element.id,
        answer: submission,
      );
      pointsAwarded = result['points_awarded'] ?? 0;
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eşleştirme sonucu kaydedilemedi: $e')),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() => _isSubmitting = false);

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        widget.onCompleted(pointsAwarded);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final palette = InteractionPalette.fromAccent(widget.accentColor);
    final payload = widget.element.payload;
    final instruction =
        payload['instruction'] ?? 'Öğeleri doğru şekilde eşleştir.';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: palette.accent.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: palette.accent.withValues(alpha: 0.32)),
            ),
            child: Text(
              'KitapLig Eşleştirme ${_leftItems.length} soru',
              style: GoogleFonts.inter(
                color: palette.accent,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 24),
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
          if (_feedbackMessage != null) ...[
            const SizedBox(height: 20),
            _MatchFeedbackCard(
              palette: palette,
              message: _feedbackMessage!,
              isSuccess: _feedbackIsSuccess ?? false,
            ),
          ],
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _leftItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _leftItems[index];
                      final isMatched = _matches.containsKey(item);
                      final isSelected = _selectedLeft == item;

                      return _buildMatchItem(
                        text: item,
                        isSelected: isSelected,
                        isMatched: isMatched,
                        onTap: () => _onLeftTap(item),
                        palette: palette,
                      );
                    },
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: _rightItems.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = _rightItems[index];
                      final isMatched = _matches.containsValue(item);
                      final isSelected = _selectedRight == item;

                      return _buildMatchItem(
                        text: item,
                        isSelected: isSelected,
                        isMatched: isMatched,
                        onTap: () => _onRightTap(item),
                        palette: palette,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          if (_isSuccess)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: palette.success.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: palette.success),
                ),
                child: _isSubmitting
                    ? SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: palette.success,
                        ),
                      )
                    : Text(
                        'Tebrikler! Hepsini buldun.',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: palette.success,
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMatchItem({
    required String text,
    required bool isSelected,
    required bool isMatched,
    required VoidCallback onTap,
    required InteractionPalette palette,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      child: Material(
        color: isMatched
            ? palette.success.withValues(alpha: 0.15)
            : (isSelected
                  ? palette.accent.withValues(alpha: 0.24)
                  : palette.surface),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: isMatched
                    ? palette.success
                    : (isSelected ? palette.accent : palette.border),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: palette.accent.withValues(alpha: 0.26),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected || isMatched
                    ? FontWeight.w600
                    : FontWeight.w500,
                color: isMatched ? palette.success : palette.text,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MatchFeedbackCard extends StatelessWidget {
  const _MatchFeedbackCard({
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
      padding: const EdgeInsets.all(14),
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
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
