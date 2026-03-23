import 'package:flutter/material.dart';
import '../../../core/services/highlight_service.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/paragraph_model.dart';

class HighlightModal extends StatefulWidget {
  final int bookId;
  final ParagraphModel paragraph;

  const HighlightModal({
    super.key,
    required this.bookId,
    required this.paragraph,
  });

  static void show(BuildContext context, int bookId, ParagraphModel paragraph) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HighlightModal(bookId: bookId, paragraph: paragraph),
    );
  }

  @override
  State<HighlightModal> createState() => _HighlightModalState();
}

class _HighlightModalState extends State<HighlightModal> {
  final _noteCtrl = TextEditingController();
  bool _isSubmitting = false;
  String _selectedColor = '#FFEB3B';

  final List<Map<String, String>> _colors = [
    {'hex': '#FFEB3B', 'name': 'Sarı'},
    {'hex': '#4CAF50', 'name': 'Yeşil'},
    {'hex': '#2196F3', 'name': 'Mavi'},
    {'hex': '#E91E63', 'name': 'Pembe'},
    {'hex': '#9C27B0', 'name': 'Mor'},
  ];

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    try {
      final service = HighlightService();
      await service.createHighlight(
        bookId: widget.bookId,
        paragraphId: widget.paragraph.id,
        text: widget.paragraph.content,
        note: _noteCtrl.text,
        color: _selectedColor,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vurgu kaydedildi!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hata oluştu. Giriş yaptığınızdan emin olun.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Parse the current selected color safely
    Color highlightColor = const Color(0xFFFFEB3B);
    try {
      highlightColor = Color(int.parse(_selectedColor.replaceFirst('#', '0xFF')));
    } catch (_) {}

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
              'Paragrafı Vurgula',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: highlightColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: highlightColor.withOpacity(0.3)),
                borderLeft: BorderSide(color: highlightColor, width: 4),
              ),
              child: Text(
                widget.paragraph.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: theme.colorScheme.onSurface,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Renk Seçimi',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: _colors.map((colorObj) {
                final hexString = colorObj['hex']!;
                Color c = Colors.grey;
                try {
                  c = Color(int.parse(hexString.replaceFirst('#', '0xFF')));
                } catch (_) {}
                final isSelected = _selectedColor == hexString;

                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hexString),
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null,
                      boxShadow: isSelected ? [
                        BoxShadow(color: c.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
                      ] : null,
                    ),
                    child: isSelected ? const Icon(Icons.check, color: Colors.white) : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _noteCtrl,
              maxLines: 3,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText: 'Kendinize bir not ekleyin... (İsteğe bağlı)',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
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
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Vurguyu Kaydet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
