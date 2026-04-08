import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/books_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/review_service.dart';
import '../../../core/utils/user_friendly_error.dart';

class ReviewModal extends ConsumerStatefulWidget {
  final int bookId;

  const ReviewModal({super.key, required this.bookId});

  @override
  ConsumerState<ReviewModal> createState() => _ReviewModalState();

  static void show(BuildContext context, int bookId) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReviewModal(bookId: bookId),
    );
  }
}

class _ReviewModalState extends ConsumerState<ReviewModal> {
  final _commentCtrl = TextEditingController();
  int _rating = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen bir yıldız seçin.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final service = ReviewService();
      await service.submitReview(
        bookId: widget.bookId,
        rating: _rating,
        comment: _commentCtrl.text,
      );
      if (!mounted) return;
      ref.invalidate(bookReviewsPreviewProvider(widget.bookId));
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Değerlendirmeniz için teşekkürler!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            userFacingErrorMessage(
              e,
              fallback:
                  'Değerlendirme kaydedilemedi. Giriş yaptığını kontrol edip tekrar dene.',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Kitabı Puanla',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu kitabı nasıl buldunuz? Diğer okurlara rehber olmak için değerlendirmenizi paylaşın.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = starValue),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  icon: Icon(
                    starValue <= _rating
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    size: 42,
                    color: const Color(0xFFFFC107),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _commentCtrl,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Kitap hakkında düşünceleriniz... (İsteğe bağlı)',
                filled: true,
                fillColor:
                    theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSubmitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Değerlendirmeyi Gönder',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
