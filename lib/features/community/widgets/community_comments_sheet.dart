import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../../../core/widgets/reader_profile_avatar.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import 'community_report_sheet.dart';

class CommunityCommentsSheet extends ConsumerStatefulWidget {
  const CommunityCommentsSheet({
    super.key,
    required this.post,
    required this.isReadOnly,
    this.onCommentCreated,
  });

  final CommunityPostModel post;
  final bool isReadOnly;
  final VoidCallback? onCommentCreated;

  @override
  ConsumerState<CommunityCommentsSheet> createState() =>
      _CommunityCommentsSheetState();
}

class _CommunityCommentsSheetState
    extends ConsumerState<CommunityCommentsSheet> {
  final TextEditingController _controller = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _message(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    final body = _controller.text.trim();
    if (body.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(communityServiceProvider)
          .createComment(widget.post.id, body);
      _controller.clear();
      ref.invalidate(communityCommentsProvider(widget.post.id));
      widget.onCommentCreated?.call();
    } catch (error) {
      _message(apiFormErrorMessage(error, fallback: 'Yorum gönderilemedi.'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(CommunityCommentModel comment) async {
    try {
      await ref.read(communityServiceProvider).deleteComment(comment.id);
      ref.invalidate(communityCommentsProvider(widget.post.id));
    } catch (error) {
      _message(apiFormErrorMessage(error, fallback: 'Yorum silinemedi.'));
    }
  }

  Future<void> _report(CommunityCommentModel comment) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CommunityReportSheet(
        onSubmit: (reason, details) => ref
            .read(communityServiceProvider)
            .reportComment(comment.id, reason: reason, details: details),
      ),
    );
    if (ok == true) _message('Şikayetin alındı.');
  }

  @override
  Widget build(BuildContext context) {
    final commentsAsync = ref.watch(communityCommentsProvider(widget.post.id));
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.78,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Yorumlar',
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: commentsAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  ),
                  error: (error, _) => Center(
                    child: Text(
                      userFacingErrorMessage(
                        error,
                        fallback: 'Yorumlar yüklenemedi.',
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  data: (page) {
                    if (page.items.isEmpty) {
                      return Center(
                        child: Text(
                          'İlk yorumu sen yaz.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      );
                    }
                    return ListView.separated(
                      itemCount: page.items.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, index) {
                        final comment = page.items[index];
                        return _CommentTile(
                          comment: comment,
                          onDelete: comment.viewerState.canDelete
                              ? () => _delete(comment)
                              : null,
                          onReport:
                              comment.viewerState.canReport &&
                                  !widget.isReadOnly
                              ? () => _report(comment)
                              : null,
                        );
                      },
                    );
                  },
                ),
              ),
              if (!widget.isReadOnly && widget.post.viewerState.canComment) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 3,
                        maxLength: 1000,
                        decoration: const InputDecoration(
                          hintText: 'Yorum yaz...',
                          counterText: '',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      onPressed: _busy ? null : _submit,
                      icon: _busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, this.onDelete, this.onReport});

  final CommunityCommentModel comment;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReaderProfileAvatar(
          name: comment.author.name,
          avatarRef: comment.author.avatarUrl,
          size: 36,
          borderRadius: BorderRadius.circular(12),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        comment.author.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (onDelete != null || onReport != null)
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        onSelected: (value) {
                          if (value == 'delete') onDelete?.call();
                          if (value == 'report') onReport?.call();
                        },
                        itemBuilder: (_) => [
                          if (onReport != null)
                            const PopupMenuItem(
                              value: 'report',
                              child: Text('Şikayet et'),
                            ),
                          if (onDelete != null)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Sil'),
                            ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.body,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 13.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
