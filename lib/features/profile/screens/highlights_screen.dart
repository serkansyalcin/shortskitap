import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/highlight_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HighlightsScreen extends StatefulWidget {
  const HighlightsScreen({super.key});

  @override
  State<HighlightsScreen> createState() => _HighlightsScreenState();
}

class _HighlightsScreenState extends State<HighlightsScreen> {
  final HighlightService _service = HighlightService();
  bool _isLoading = true;
  String? _error;
  List<dynamic> _highlights = [];

  @override
  void initState() {
    super.initState();
    _fetchHighlights();
  }

  Future<void> _fetchHighlights() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _service.getHighlights();
      setState(() {
        _highlights = res['data'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHighlight(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vurguyu Sil'),
        content: const Text('Bu vurguyu silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('İptal')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _service.deleteHighlight(id);
      setState(() {
        _highlights.removeWhere((h) => h['id'] == id);
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vurgu silindi.')));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Silinirken bir hata oluştu.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alıntılarım', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      body: _buildBody(theme),
    );
  }

  Widget _buildBody(ThemeData theme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Yüklenemedi: $_error', textAlign: TextAlign.center, style: TextStyle(color: theme.colorScheme.onSurface)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchHighlights, child: const Text('Tekrar Dene')),
          ],
        ),
      );
    }

    if (_highlights.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.format_quote_rounded, size: 64, color: theme.colorScheme.surfaceContainerHighest),
            const SizedBox(height: 16),
            Text('Henüz bir alıntın yok.', style: TextStyle(fontSize: 16, color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchHighlights,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _highlights.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (ctx, index) {
          final highlight = _highlights[index];
          final book = highlight['book'];
          Color color = const Color(0xFFFFEB3B);
          try {
            if (highlight['color'] != null) {
              color = Color(int.parse(highlight['color'].toString().replaceFirst('#', '0xFF')));
            }
          } catch (_) {}

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (book != null)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push('/books/${book['slug']}'),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 56,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: theme.colorScheme.surfaceContainerHighest,
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: book['cover_image_url'] != null
                                  ? CachedNetworkImage(imageUrl: book['cover_image_url'], fit: BoxFit.cover)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                book['title'] ?? 'Bilinmeyen Kitap',
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () => _deleteHighlight(highlight['id']),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    border: Border(left: BorderSide(color: color, width: 4)),
                  ),
                  child: Text(
                    highlight['text'] ?? '',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: theme.colorScheme.onSurface,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                if (highlight['note'] != null && highlight['note'].toString().trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            highlight['note'],
                            style: TextStyle(
                              fontSize: 14,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
