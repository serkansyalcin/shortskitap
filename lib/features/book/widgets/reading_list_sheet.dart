import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/reading_list_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/models/reading_list_model.dart';

/// Bottom sheet — shows all lists + check/uncheck book. Also lets user create a new list.
class ReadingListSheet extends ConsumerStatefulWidget {
  const ReadingListSheet({super.key, required this.bookId});

  final int bookId;

  static Future<void> show(BuildContext context, int bookId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) => ReadingListSheet(bookId: bookId),
    );
  }

  @override
  ConsumerState<ReadingListSheet> createState() => _ReadingListSheetState();
}

class _ReadingListSheetState extends ConsumerState<ReadingListSheet> {
  List<ReadingListModel> _lists = [];
  Set<int> _inLists = {};
  bool _loading = true;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await ref.read(readingListServiceProvider).checkBook(widget.bookId);
      if (!mounted) return;
      setState(() {
        _lists = result.lists;
        _inLists = result.inLists.toSet();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(ReadingListModel list) async {
    if (_busy.contains(list.id)) return;
    setState(() => _busy.add(list.id));

    final wasIn = _inLists.contains(list.id);
    setState(() => wasIn ? _inLists.remove(list.id) : _inLists.add(list.id));

    try {
      if (wasIn) {
        await ref.read(readingListsNotifier).removeBook(list.id, widget.bookId);
      } else {
        await ref.read(readingListsNotifier).addBook(list.id, widget.bookId);
      }
    } catch (_) {
      if (mounted) setState(() => wasIn ? _inLists.add(list.id) : _inLists.remove(list.id));
    } finally {
      if (mounted) setState(() => _busy.remove(list.id));
    }
  }

  Future<void> _createNew() async {
    final name = await _showCreateDialog();
    if (name == null || name.trim().isEmpty || !mounted) return;
    await ref.read(readingListsNotifier).create(name: name.trim());
    await _load();
  }

  Future<String?> _showCreateDialog() {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yeni liste'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(hintText: 'Liste adı'),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            style: FilledButton.styleFrom(minimumSize: const Size(80, 44)),
            child: const Text('Oluştur'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Okuma listelerine ekle',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              IconButton.filledTonal(
                onPressed: _createNew,
                icon: const Icon(Icons.add_rounded),
                tooltip: 'Yeni liste',
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
            )
          else if (_lists.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 48, color: scheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    'Henüz listeniz yok',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 15),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _createNew,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('İlk listenizi oluşturun'),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lists.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final list = _lists[i];
                final checked = _inLists.contains(list.id);
                final busy = _busy.contains(list.id);

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: busy ? null : () => _toggle(list),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: checked
                          ? AppColors.primary.withValues(alpha: isDark ? 0.18 : 0.1)
                          : scheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: Border.all(
                        color: checked
                            ? AppColors.primary.withValues(alpha: 0.5)
                            : scheme.outline.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: busy
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                                )
                              : Icon(
                                  checked ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                  key: ValueKey(checked),
                                  color: checked ? AppColors.primary : scheme.onSurfaceVariant,
                                  size: 22,
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                list.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: scheme.onSurface,
                                ),
                              ),
                              Text(
                                '${list.bookCount} kitap',
                                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                        ),
                        if (list.isPublic)
                          Icon(Icons.public_rounded, size: 16, color: scheme.onSurfaceVariant),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

final readingListsNotifier = readingListsProvider.notifier;
