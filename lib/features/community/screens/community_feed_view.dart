import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import '../widgets/community_comments_sheet.dart';
import '../widgets/community_compose_sheet.dart';
import '../widgets/community_post_card.dart';
import '../widgets/community_report_sheet.dart';

class CommunityFeedView extends ConsumerStatefulWidget {
  const CommunityFeedView({super.key});

  @override
  ConsumerState<CommunityFeedView> createState() => _CommunityFeedViewState();
}

class _CommunityFeedViewState extends ConsumerState<CommunityFeedView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels > position.maxScrollExtent - 560) {
      ref.read(communityFeedProvider.notifier).load();
    }
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _compose() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CommunityComposeSheet(
        onSubmit: (payload) =>
            ref.read(communityFeedProvider.notifier).addPost(payload),
      ),
    );
    if (ok == true) _message('Gönderin paylaşıldı.');
  }

  Future<void> _comments(CommunityPostModel post) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CommunityCommentsSheet(
        post: post,
        isReadOnly: _isReadOnly,
        onCommentCreated: () {
          ref
              .read(communityFeedProvider.notifier)
              .replacePost(
                post.copyWith(
                  counts: post.counts.copyWith(
                    comments: post.counts.comments + 1,
                  ),
                ),
              );
        },
      ),
    );
  }

  Future<void> _report(CommunityPostModel post) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CommunityReportSheet(
        onSubmit: (reason, details) => ref
            .read(communityServiceProvider)
            .reportPost(post.id, reason: reason, details: details),
      ),
    );
    if (ok == true) _message('Şikayetin alındı.');
  }

  Future<void> _delete(CommunityPostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Gönderi silinsin mi?'),
        content: const Text('Bu gönderi profilinden ve akıştan kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(communityFeedProvider.notifier).deletePost(post);
    } catch (error) {
      _message(apiFormErrorMessage(error, fallback: 'Gönderi silinemedi.'));
    }
  }

  bool get _isReadOnly {
    return ref.read(authProvider).activeProfile?.isChild == true;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(communityFeedProvider);
    final isReadOnly = ref.watch(
      authProvider.select((state) => state.activeProfile?.isChild == true),
    );
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: isReadOnly
          ? null
          : FloatingActionButton.extended(
              onPressed: _compose,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Paylaş'),
            ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(communityFeedProvider.notifier).refresh(),
        child: ListView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 108),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Topluluk',
                    style: AppUI.pageTitle(context).copyWith(fontSize: 24),
                  ),
                ),
                if (isReadOnly)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Güvenli akış',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isReadOnly
                  ? 'Onaylı paylaşımları okuyabilirsin.'
                  : 'Kitaplardan, alıntılardan ve okuma keşiflerinden konuş.',
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            const SizedBox(height: 18),
            _FilterBar(
              selectedFilter: state.filter,
              onFilterChanged: (filter) =>
                  ref.read(communityFeedProvider.notifier).setFilter(filter),
            ),
            const SizedBox(height: 16),
            if (!isReadOnly) _ComposerEntry(onTap: _compose),
            if (state.isLoading && state.posts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              )
            else if (state.error != null && state.posts.isEmpty)
              AppUI.errorState(
                context,
                message: 'Topluluk yüklenemedi',
                detail: userFacingErrorMessage(state.error),
                onRetry: () =>
                    ref.read(communityFeedProvider.notifier).refresh(),
              )
            else if (state.posts.isEmpty)
              AppUI.emptyState(
                context,
                emoji: '💬',
                title: 'Henüz paylaşım yok',
                subtitle: isReadOnly
                    ? 'Onaylı gönderiler burada görünecek.'
                    : 'İlk gönderiyi paylaşarak sohbeti başlat.',
              )
            else ...[
              for (final post in state.posts)
                CommunityPostCard(
                  post: post,
                  isReadOnly: isReadOnly,
                  onLike: () => ref
                      .read(communityFeedProvider.notifier)
                      .toggleLike(post)
                      .catchError(
                        (Object error) => _message(apiFormErrorMessage(error)),
                      ),
                  onSave: () => ref
                      .read(communityFeedProvider.notifier)
                      .toggleSave(post)
                      .catchError(
                        (Object error) => _message(apiFormErrorMessage(error)),
                      ),
                  onComments: () => _comments(post),
                  onReport: () => _report(post),
                  onDelete: () => _delete(post),
                ),
              if (state.isLoadingMore)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: CircularProgressIndicator()),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selectedFilter, required this.onFilterChanged});

  final String? selectedFilter;
  final ValueChanged<String?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: 'Son Paylaşımlar',
            selected: selectedFilter == null,
            onSelected: (_) => onFilterChanged(null),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'Takip Ettiklerim',
            selected: selectedFilter == 'following',
            onSelected: (_) => onFilterChanged('following'),
          ),
          const SizedBox(width: 8),
          _FilterChip(
            label: 'En Çok Beğenilenler',
            selected: selectedFilter == 'popular',
            onSelected: (_) => onFilterChanged('popular'),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      showCheckmark: false,
      labelStyle: TextStyle(
        fontSize: 12.5,
        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        color: selected
            ? Colors.white
            : theme.colorScheme.onSurface.withValues(alpha: 0.8),
      ),
      selectedColor: AppColors.primary,
      backgroundColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.04),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(99),
        side: BorderSide(
          color: selected
              ? AppColors.primary
              : theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}

class _ComposerEntry extends StatelessWidget {
  const _ComposerEntry({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: AppColors.primary,
              child: Icon(Icons.edit_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Bugün ne okudun?',
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ),
            const Icon(Icons.add_circle_outline_rounded),
          ],
        ),
      ),
    );
  }
}
