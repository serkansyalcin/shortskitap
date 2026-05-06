import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/providers/books_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/book_model.dart';
import '../models/community_models.dart';

enum CommunityComposeMode { text, quote, image, book }

class CommunityComposeSheet extends ConsumerStatefulWidget {
  const CommunityComposeSheet({super.key, required this.onSubmit});

  final Future<void> Function(CommunityComposePayload payload) onSubmit;

  @override
  ConsumerState<CommunityComposeSheet> createState() =>
      _CommunityComposeSheetState();
}

class _CommunityComposeSheetState extends ConsumerState<CommunityComposeSheet> {
  final TextEditingController _bodyController = TextEditingController();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _quoteSourceController = TextEditingController();
  final TextEditingController _bookSearchController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  CommunityComposeMode _mode = CommunityComposeMode.text;
  List<CommunityImagePayload> _images = const [];
  BookModel? _book;
  String _bookQuery = '';
  bool _busy = false;

  @override
  void dispose() {
    _bodyController.dispose();
    _quoteController.dispose();
    _quoteSourceController.dispose();
    _bookSearchController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(imageQuality: 84);
    if (picked.isEmpty) return;
    final next = <CommunityImagePayload>[..._images];
    for (final file in picked.take(4 - next.length)) {
      next.add(
        CommunityImagePayload(
          bytes: await file.readAsBytes(),
          fileName: file.name,
        ),
      );
    }
    setState(() => _images = next);
  }

  bool get _canSubmit {
    if (_busy) return false;
    return _bodyController.text.trim().isNotEmpty ||
        _quoteController.text.trim().isNotEmpty ||
        _images.isNotEmpty ||
        _book != null;
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(
        CommunityComposePayload(
          body: _bodyController.text,
          quoteText: _quoteController.text,
          quoteSource: _quoteSourceController.text,
          bookId: _book?.id,
          images: _images,
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          18 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.86,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Yeni gönderi',
                      style: TextStyle(
                        color: scheme.onSurface,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Paylaş'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                height: 54,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    _ModeItem(
                      mode: CommunityComposeMode.text,
                      icon: Icons.text_fields_rounded,
                      label: 'Metin',
                      selected: _mode == CommunityComposeMode.text,
                      onTap: () => setState(() => _mode = CommunityComposeMode.text),
                    ),
                    _ModeItem(
                      mode: CommunityComposeMode.quote,
                      icon: Icons.format_quote_rounded,
                      label: 'Alıntı',
                      selected: _mode == CommunityComposeMode.quote,
                      onTap: () => setState(() => _mode = CommunityComposeMode.quote),
                    ),
                    _ModeItem(
                      mode: CommunityComposeMode.image,
                      icon: Icons.image_rounded,
                      label: 'Görsel',
                      selected: _mode == CommunityComposeMode.image,
                      onTap: () => setState(() => _mode = CommunityComposeMode.image),
                    ),
                    _ModeItem(
                      mode: CommunityComposeMode.book,
                      icon: Icons.menu_book_rounded,
                      label: 'Kitap',
                      selected: _mode == CommunityComposeMode.book,
                      onTap: () => setState(() => _mode = CommunityComposeMode.book),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    if (_mode == CommunityComposeMode.text)
                      TextField(
                        controller: _bodyController,
                        minLines: 8,
                        maxLines: 12,
                        maxLength: 5000,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                        decoration: InputDecoration(
                          hintText: 'Ne paylaşmak istersin?',
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.all(16),
                          counterText: '',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    if (_mode == CommunityComposeMode.quote) ...[
                      TextField(
                        controller: _quoteController,
                        minLines: 4,
                        maxLines: 7,
                        maxLength: 2000,
                        decoration: const InputDecoration(
                          hintText: 'Alıntını yaz',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _quoteSourceController,
                        maxLength: 255,
                        decoration: const InputDecoration(
                          hintText: 'Kaynak veya kitap adı',
                        ),
                      ),
                    ],
                    if (_mode == CommunityComposeMode.image) ...[
                      OutlinedButton.icon(
                        onPressed: _images.length >= 4 ? null : _pickImages,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text('Görsel seç'),
                      ),
                      const SizedBox(height: 12),
                      if (_images.isNotEmpty)
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (var i = 0; i < _images.length; i++)
                              Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _images[i].bytes,
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: InkWell(
                                      onTap: () => setState(
                                        () => _images = [
                                          for (
                                            var j = 0;
                                            j < _images.length;
                                            j++
                                          )
                                            if (j != i) _images[j],
                                        ],
                                      ),
                                      child: const CircleAvatar(
                                        radius: 13,
                                        backgroundColor: Colors.black54,
                                        child: Icon(
                                          Icons.close,
                                          color: Colors.white,
                                          size: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bodyController,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          hintText: 'Görsele kısa bir not ekle',
                        ),
                      ),
                    ],
                    if (_mode == CommunityComposeMode.book) ...[
                      TextField(
                        controller: _bookSearchController,
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Kitap ara',
                        ),
                        onChanged: (value) =>
                            setState(() => _bookQuery = value),
                      ),
                      const SizedBox(height: 12),
                      if (_book != null) _SelectedBook(book: _book!),
                      _BookSearchResults(
                        query: _bookQuery,
                        onSelected: (book) => setState(() => _book = book),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _bodyController,
                        minLines: 3,
                        maxLines: 5,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          hintText: 'Bu kitap hakkında ne düşünüyorsun?',
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _EmojiBar(
                      onEmojiSelected: (emoji) {
                        final controller = _mode == CommunityComposeMode.quote ? _quoteController : _bodyController;
                        final text = controller.text;
                        final selection = controller.selection;
                        final newText = text.replaceRange(
                          selection.start == -1 ? text.length : selection.start,
                          selection.end == -1 ? text.length : selection.end,
                          emoji,
                        );
                        controller.value = TextEditingValue(
                          text: newText,
                          selection: TextSelection.collapsed(
                            offset: (selection.start == -1 ? text.length : selection.start) + emoji.length,
                          ),
                        );
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_mode == CommunityComposeMode.quote ? _quoteController.text.length : _bodyController.text.length} / ${_mode == CommunityComposeMode.quote ? 2000 : 5000}',
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'En az bir öğe gerekli.',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedBook extends StatelessWidget {
  const _SelectedBook({required this.book});

  final BookModel book;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              book.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookSearchResults extends ConsumerWidget {
  const _BookSearchResults({required this.query, required this.onSelected});

  final String query;
  final ValueChanged<BookModel> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.trim().length < 2) return const SizedBox.shrink();
    final booksAsync = ref.watch(searchProvider(query.trim()));
    return booksAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (books) => Column(
        children: [
          for (final book in books.take(6))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.menu_book_rounded),
              title: Text(
                book.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                book.author?.name ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => onSelected(book),
            ),
        ],
      ),
    );
  }
}
class _ModeItem extends StatelessWidget {
  const _ModeItem({
    required this.mode,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final CommunityComposeMode mode;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? Colors.white
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmojiBar extends StatelessWidget {
  const _EmojiBar({required this.onEmojiSelected});

  final ValueChanged<String> onEmojiSelected;

  static const _emojis = ['😊', '📚', '✨', '💡', '🔥', '❤️', '👏', '🧐', '💭', '🚀'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.emoji_emotions_outlined, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _emojis.map((emoji) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => onEmojiSelected(emoji),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(emoji, style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
