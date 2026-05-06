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
    final scheme = Theme.of(context).colorScheme;
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
              SegmentedButton<CommunityComposeMode>(
                segments: const [
                  ButtonSegment(
                    value: CommunityComposeMode.text,
                    icon: Icon(Icons.notes_rounded),
                  ),
                  ButtonSegment(
                    value: CommunityComposeMode.quote,
                    icon: Icon(Icons.format_quote_rounded),
                  ),
                  ButtonSegment(
                    value: CommunityComposeMode.image,
                    icon: Icon(Icons.image_rounded),
                  ),
                  ButtonSegment(
                    value: CommunityComposeMode.book,
                    icon: Icon(Icons.menu_book_rounded),
                  ),
                ],
                selected: {_mode},
                onSelectionChanged: _busy
                    ? null
                    : (value) => setState(() => _mode = value.first),
              ),
              const SizedBox(height: 14),
              Expanded(
                child: ListView(
                  children: [
                    if (_mode == CommunityComposeMode.text)
                      TextField(
                        controller: _bodyController,
                        minLines: 6,
                        maxLines: 10,
                        maxLength: 5000,
                        decoration: const InputDecoration(
                          hintText: 'Ne paylaşmak istersin?',
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
                  ],
                ),
              ),
              Text(
                'En az bir metin, alıntı, görsel veya kitap seçimi gerekli.',
                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
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
