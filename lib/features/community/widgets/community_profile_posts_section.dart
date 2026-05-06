import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/utils/user_friendly_error.dart';
import '../models/community_models.dart';
import '../providers/community_provider.dart';
import 'community_comments_sheet.dart';
import 'community_post_card.dart';
import 'community_report_sheet.dart';

class CommunityProfilePostsSection extends ConsumerStatefulWidget {
  const CommunityProfilePostsSection({
    super.key,
    required this.username,
    required this.isSelf,
    required this.postsCount,
  });

  final String username;
  final bool isSelf;
  final int postsCount;

  @override
  ConsumerState<CommunityProfilePostsSection> createState() => _CommunityProfilePostsSectionState();
}

class _CommunityProfilePostsSectionState extends ConsumerState<CommunityProfilePostsSection> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final args = CommunityProfilePostsArgs(username: widget.username, isSelf: widget.isSelf);
      ref.read(communityProfilePostsProvider(args).notifier).load();
    }
  }

  void _message(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _comments(BuildContext context, CommunityPostModel post, bool isReadOnly) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CommunityCommentsSheet(post: post, isReadOnly: isReadOnly),
    );
  }

  Future<void> _report(BuildContext context, CommunityPostModel post) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CommunityReportSheet(
        onSubmit: (reason, details) => ref.read(communityServiceProvider).reportPost(post.id, reason: reason, details: details),
      ),
    );
    if (ok == true && context.mounted) _message(context, 'Şikayetin alındı.');
  }

  @override
  Widget build(BuildContext context) {
    final args = CommunityProfilePostsArgs(username: widget.username, isSelf: widget.isSelf);
    final state = ref.watch(communityProfilePostsProvider(args));
    final controller = ref.read(communityProfilePostsProvider(args).notifier);
    final isReadOnly = ref.watch(authProvider.select((s) => s.activeProfile?.isChild == true));
    final scheme = Theme.of(context).colorScheme;

    if (state.isLoading && state.posts.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: AppColors.primary),
      ));
    }

    if (state.error != null && state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Gönderiler yüklenemedi', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(userFacingErrorMessage(state.error), textAlign: TextAlign.center),
              TextButton(onPressed: controller.refresh, child: const Text('Tekrar Dene')),
            ],
          ),
        ),
      );
    }

    if (state.posts.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Henüz gönderi yok', style: TextStyle(color: scheme.onSurface, fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                widget.isSelf ? 'Paylaştığın gönderiler burada görünecek.' : 'Bu profilde henüz görünür gönderi yok.',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: state.posts.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.posts.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        final post = state.posts[index];
        return CommunityPostCard(
          post: post,
          compact: true,
          isReadOnly: isReadOnly,
          onLike: () async {
            try {
              await controller.toggleLike(post);
            } catch (error) {
              if (context.mounted) _message(context, userFacingErrorMessage(error));
            }
          },
          onSave: () async {
            try {
              await controller.toggleSave(post);
            } catch (error) {
              if (context.mounted) _message(context, userFacingErrorMessage(error));
            }
          },
          onComments: () => _comments(context, post, isReadOnly),
          onReport: () => _report(context, post),
          onDelete: widget.isSelf
              ? () async {
                  try {
                    await controller.deletePost(post);
                  } catch (error) {
                    if (context.mounted) {
                      _message(context, userFacingErrorMessage(error));
                    }
                  }
                }
              : null,
        );
      },
    );
  }
}
