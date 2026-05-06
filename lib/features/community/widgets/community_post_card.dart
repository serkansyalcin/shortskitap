import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/app_image_viewer.dart';
import '../../../core/widgets/reader_profile_avatar.dart';
import '../models/community_models.dart';

class CommunityPostCard extends StatefulWidget {
  const CommunityPostCard({
    super.key,
    required this.post,
    required this.isReadOnly,
    required this.onLike,
    required this.onSave,
    required this.onComments,
    required this.onReport,
    this.onDelete,
    this.compact = false,
  });

  final CommunityPostModel post;
  final bool isReadOnly;
  final VoidCallback onLike;
  final VoidCallback onSave;
  final VoidCallback onComments;
  final VoidCallback onReport;
  final VoidCallback? onDelete;
  final bool compact;

  @override
  State<CommunityPostCard> createState() => _CommunityPostCardState();
}

class _CommunityPostCardState extends State<CommunityPostCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textMuted = scheme.onSurfaceVariant;
    final isDark = theme.brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        margin: EdgeInsets.only(bottom: widget.compact ? 12 : 14),
        padding: EdgeInsets.all(widget.compact ? 14 : 16),
        decoration: BoxDecoration(
          color: _isHovered 
            ? (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02))
            : theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isHovered 
              ? scheme.primary.withValues(alpha: 0.15)
              : scheme.outline.withValues(alpha: 0.12),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: widget.post.author.username.isEmpty
                      ? null
                      : () => context.push('/profil/${widget.post.author.username}'),
                  child: ReaderProfileAvatar(
                    name: widget.post.author.name,
                    avatarRef: widget.post.author.avatarUrl,
                    size: 42,
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.post.author.name.isEmpty
                                  ? 'KitapLig kullanıcısı'
                                  : widget.post.author.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          if (widget.post.author.isPremium) ...[
                            const SizedBox(width: 5),
                            const Icon(
                              Icons.verified_rounded,
                              size: 15,
                              color: AppColors.primary,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (widget.post.author.username.isNotEmpty)
                            '@${widget.post.author.username}',
                          _relativeTime(widget.post.createdAt),
                        ].where((part) => part.isNotEmpty).join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                _PostMenu(
                  canDelete: widget.post.viewerState.canDelete,
                  canReport: widget.post.viewerState.canReport && !widget.isReadOnly,
                  onDelete: widget.onDelete,
                  onReport: widget.onReport,
                ),
              ],
            ),
            if (widget.post.body?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Text(
                widget.post.body!.trim(),
                style: TextStyle(
                  color: scheme.onSurface,
                  fontSize: 14.5,
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (widget.post.quoteText?.trim().isNotEmpty == true) ...[
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          backgroundColor: Colors.black,
                          appBar: AppBar(
                            backgroundColor: Colors.transparent,
                            elevation: 0,
                            leading: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: CircleAvatar(
                                backgroundColor: Colors.black.withValues(alpha: 0.4),
                                child: IconButton(
                                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ),
                            ),
                          ),
                          body: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                widget.post.quoteText!.trim(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border(
                        left: BorderSide(color: AppColors.primary, width: 4),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.post.quoteText!.trim(),
                          style: TextStyle(
                            color: scheme.onSurface,
                            fontSize: 15,
                            height: 1.45,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (widget.post.quoteSource?.trim().isNotEmpty == true) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.post.quoteSource!.trim(),
                            style: TextStyle(
                              color: textMuted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
            if (widget.post.images.isNotEmpty) ...[
              const SizedBox(height: 12),
              _ImageGrid(
                postId: widget.post.id,
                images: widget.post.images,
              ),
            ],
            if (widget.post.book != null) ...[
              const SizedBox(height: 12),
              _BookPreview(book: widget.post.book!),
            ],
            if (widget.post.status != 'published' || widget.post.hiddenReason != null) ...[
              const SizedBox(height: 10),
              _StatusPill(post: widget.post),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  icon: widget.post.viewerState.isLiked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  label: _countLabel(widget.post.counts.likes),
                  selected: widget.post.viewerState.isLiked,
                  onTap: widget.isReadOnly ? null : widget.onLike,
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: _countLabel(widget.post.counts.comments),
                  onTap: widget.onComments,
                ),
                _ActionButton(
                  icon: widget.post.viewerState.isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  label: _countLabel(widget.post.counts.saves),
                  selected: widget.post.viewerState.isSaved,
                  onTap: widget.isReadOnly ? null : widget.onSave,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PostMenu extends StatelessWidget {
  const _PostMenu({
    required this.canDelete,
    required this.canReport,
    required this.onDelete,
    required this.onReport,
  });

  final bool canDelete;
  final bool canReport;
  final VoidCallback? onDelete;
  final VoidCallback onReport;

  @override
  Widget build(BuildContext context) {
    if (!canDelete && !canReport) return const SizedBox(width: 28);
    return PopupMenuButton<String>(
      tooltip: 'Gönderi seçenekleri',
      icon: const Icon(Icons.more_horiz_rounded),
      onSelected: (value) {
        if (value == 'delete') onDelete?.call();
        if (value == 'report') onReport();
      },
      itemBuilder: (_) => [
        if (canReport)
          const PopupMenuItem(value: 'report', child: Text('Şikayet et')),
        if (canDelete) const PopupMenuItem(value: 'delete', child: Text('Sil')),
      ],
    );
  }
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({required this.postId, required this.images});

  final int postId;
  final List<CommunityImageModel> images;

  void _openViewer(BuildContext context, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AppImageViewer(
          urls: images.map((i) => i.url).toList(),
          initialIndex: index,
          heroTagBase: 'post_${postId}_img',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = images.take(4).toList();
    if (visible.length == 1) {
      return _NetworkImageTile(
        image: visible.first,
        aspectRatio: 16 / 10,
        heroTag: 'post_${postId}_img_0',
        onTap: () => _openViewer(context, 0),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemBuilder: (_, index) => _NetworkImageTile(
        image: visible[index],
        heroTag: 'post_${postId}_img_$index',
        onTap: () => _openViewer(context, index),
      ),
    );
  }
}

class _NetworkImageTile extends StatelessWidget {
  const _NetworkImageTile({
    required this.image,
    this.aspectRatio = 1,
    required this.heroTag,
    required this.onTap,
  });

  final CommunityImageModel image;
  final double aspectRatio;
  final String heroTag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Hero(
          tag: heroTag,
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: image.url,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.image_not_supported_outlined),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BookPreview extends StatelessWidget {
  const _BookPreview({required this.book});

  final CommunityBookPreviewModel book;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: book.slug.isEmpty
          ? null
          : () => context.push('/books/${book.slug}'),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 44,
                height: 62,
                child: book.coverImageUrl == null
                    ? const ColoredBox(
                        color: AppColors.primary,
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                        ),
                      )
                    : CachedNetworkImage(
                        imageUrl: book.coverImageUrl!,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (book.author?.isNotEmpty == true) ...[
                    const SizedBox(height: 3),
                    Text(
                      book.author!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.post});

  final CommunityPostModel post;

  @override
  Widget build(BuildContext context) {
    final label = post.status == 'hidden'
        ? 'Gizlendi'
        : post.status == 'deleted'
        ? 'Silindi'
        : post.status == 'pending_review'
        ? 'İncelemede'
        : 'Onay bekliyor';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        post.hiddenReason == null ? label : '$label · ${post.hiddenReason}',
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? AppColors.primary
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: AppColors.primary.withValues(alpha: 0.08),
        splashColor: AppColors.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 19, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _countLabel(int count) {
  if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}B';
  return '$count';
}

String _relativeTime(DateTime? value) {
  if (value == null) return '';
  final diff = DateTime.now().difference(value.toLocal());
  if (diff.inMinutes < 1) return 'şimdi';
  if (diff.inHours < 1) return '${diff.inMinutes} dk';
  if (diff.inDays < 1) return '${diff.inHours} sa';
  if (diff.inDays < 7) return '${diff.inDays} g';
  return '${value.day}.${value.month}.${value.year}';
}
