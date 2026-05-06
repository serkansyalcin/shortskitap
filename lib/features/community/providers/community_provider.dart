import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../models/community_models.dart';
import '../services/community_service.dart';

final communityServiceProvider = Provider<CommunityService>((ref) {
  return CommunityService(ApiClient.instance);
});

class CommunityFeedState {
  final List<CommunityPostModel> posts;
  final int currentPage;
  final int lastPage;
  final bool isLoading;
  final bool isLoadingMore;
  final String? filter;
  final Object? error;

  const CommunityFeedState({
    this.posts = const [],
    this.currentPage = 0,
    this.lastPage = 1,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.filter,
    this.error,
  });

  bool get hasMore => currentPage < lastPage;

  CommunityFeedState copyWith({
    List<CommunityPostModel>? posts,
    int? currentPage,
    int? lastPage,
    bool? isLoading,
    bool? isLoadingMore,
    String? Function()? filter,
    Object? error,
    bool clearError = false,
  }) {
    return CommunityFeedState(
      posts: posts ?? this.posts,
      currentPage: currentPage ?? this.currentPage,
      lastPage: lastPage ?? this.lastPage,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      filter: filter != null ? filter() : this.filter,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class CommunityFeedController extends StateNotifier<CommunityFeedState> {
  CommunityFeedController(this._ref) : super(const CommunityFeedState()) {
    load(refresh: true);
  }

  final Ref _ref;
  static const int _perPage = 15;

  CommunityService get _service => _ref.read(communityServiceProvider);

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;

    final nextPage = refresh ? 1 : state.currentPage + 1;
    state = state.copyWith(
      isLoading: refresh,
      isLoadingMore: !refresh,
      clearError: true,
    );

    try {
      final page = await _service.fetchFeed(
        page: nextPage,
        perPage: _perPage,
        filter: state.filter,
      );
      state = state.copyWith(
        posts: refresh ? page.items : [...state.posts, ...page.items],
        currentPage: page.meta.currentPage,
        lastPage: page.meta.lastPage,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  void setFilter(String? filter) {
    if (state.filter == filter) return;
    state = state.copyWith(
      filter: () => filter,
      posts: [],
      currentPage: 0,
      lastPage: 1,
    );
    load(refresh: true);
  }

  Future<void> addPost(CommunityComposePayload payload) async {
    final post = await _service.createPost(payload);
    state = state.copyWith(posts: [post, ...state.posts], clearError: true);
  }

  Future<void> toggleLike(CommunityPostModel post) {
    final nextLiked = !post.viewerState.isLiked;
    _replacePost(_optimisticLike(post, nextLiked));
    return (nextLiked ? _service.like(post.id) : _service.unlike(post.id))
        .catchError((Object error) {
          _replacePost(post);
          throw error;
        });
  }

  Future<void> toggleSave(CommunityPostModel post) {
    final nextSaved = !post.viewerState.isSaved;
    _replacePost(
      post.copyWith(
        viewerState: post.viewerState.copyWith(isSaved: nextSaved),
        counts: post.counts.copyWith(
          saves: _nonNegative(post.counts.saves + (nextSaved ? 1 : -1)),
        ),
      ),
    );
    return (nextSaved ? _service.save(post.id) : _service.unsave(post.id))
        .catchError((Object error) {
          _replacePost(post);
          throw error;
        });
  }

  Future<void> deletePost(CommunityPostModel post) async {
    await _service.deletePost(post.id);
    state = state.copyWith(
      posts: state.posts.where((item) => item.id != post.id).toList(),
    );
  }

  void replacePost(CommunityPostModel post) => _replacePost(post);

  void _replacePost(CommunityPostModel post) {
    state = state.copyWith(
      posts: [for (final item in state.posts) item.id == post.id ? post : item],
    );
  }

  CommunityPostModel _optimisticLike(CommunityPostModel post, bool liked) {
    return post.copyWith(
      viewerState: post.viewerState.copyWith(isLiked: liked),
      counts: post.counts.copyWith(
        likes: _nonNegative(post.counts.likes + (liked ? 1 : -1)),
      ),
    );
  }
}

int _nonNegative(int value) => value < 0 ? 0 : value;

final communityFeedProvider =
    StateNotifierProvider<CommunityFeedController, CommunityFeedState>((ref) {
      ref.watch(authProvider.select((state) => state.activeProfile?.id));
      return CommunityFeedController(ref);
    });

class CommunityProfilePostsController
    extends StateNotifier<CommunityFeedState> {
  CommunityProfilePostsController(this._ref, this.username, this.isSelf)
    : super(const CommunityFeedState()) {
    load(refresh: true);
  }

  final Ref _ref;
  final String username;
  final bool isSelf;
  static const int _perPage = 15;

  CommunityService get _service => _ref.read(communityServiceProvider);

  Future<void> load({bool refresh = false}) async {
    if (state.isLoading || state.isLoadingMore) return;
    if (!refresh && !state.hasMore) return;
    final nextPage = refresh ? 1 : state.currentPage + 1;

    state = state.copyWith(
      isLoading: refresh,
      isLoadingMore: !refresh,
      clearError: true,
    );
    try {
      final page = isSelf
          ? await _service.fetchMyPosts(page: nextPage, perPage: _perPage)
          : await _service.fetchProfilePosts(
              username,
              page: nextPage,
              perPage: _perPage,
            );
      state = state.copyWith(
        posts: refresh ? page.items : [...state.posts, ...page.items],
        currentPage: page.meta.currentPage,
        lastPage: page.meta.lastPage,
        isLoading: false,
        isLoadingMore: false,
        clearError: true,
      );
    } catch (error) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: error,
      );
    }
  }

  Future<void> refresh() => load(refresh: true);

  Future<void> deletePost(CommunityPostModel post) async {
    await _service.deletePost(post.id);
    state = state.copyWith(
      posts: state.posts.where((item) => item.id != post.id).toList(),
    );
  }

  Future<void> toggleLike(CommunityPostModel post) {
    final nextLiked = !post.viewerState.isLiked;
    _replacePost(_optimisticLike(post, nextLiked));
    return (nextLiked ? _service.like(post.id) : _service.unlike(post.id))
        .catchError((Object error) {
          _replacePost(post);
          throw error;
        });
  }

  Future<void> toggleSave(CommunityPostModel post) {
    final nextSaved = !post.viewerState.isSaved;
    _replacePost(
      post.copyWith(
        viewerState: post.viewerState.copyWith(isSaved: nextSaved),
        counts: post.counts.copyWith(
          saves: _nonNegative(post.counts.saves + (nextSaved ? 1 : -1)),
        ),
      ),
    );
    return (nextSaved ? _service.save(post.id) : _service.unsave(post.id))
        .catchError((Object error) {
          _replacePost(post);
          throw error;
        });
  }

  void _replacePost(CommunityPostModel post) {
    state = state.copyWith(
      posts: [for (final item in state.posts) item.id == post.id ? post : item],
    );
  }

  CommunityPostModel _optimisticLike(CommunityPostModel post, bool liked) {
    return post.copyWith(
      viewerState: post.viewerState.copyWith(isLiked: liked),
      counts: post.counts.copyWith(
        likes: _nonNegative(post.counts.likes + (liked ? 1 : -1)),
      ),
    );
  }
}

final communityProfilePostsProvider = StateNotifierProvider.autoDispose
    .family<
      CommunityProfilePostsController,
      CommunityFeedState,
      CommunityProfilePostsArgs
    >((ref, args) {
      ref.watch(authProvider.select((state) => state.activeProfile?.id));
      return CommunityProfilePostsController(ref, args.username, args.isSelf);
    });

class CommunityProfilePostsArgs {
  final String username;
  final bool isSelf;

  const CommunityProfilePostsArgs({
    required this.username,
    required this.isSelf,
  });

  @override
  bool operator ==(Object other) {
    return other is CommunityProfilePostsArgs &&
        other.username == username &&
        other.isSelf == isSelf;
  }

  @override
  int get hashCode => Object.hash(username, isSelf);
}

final communityCommentsProvider = FutureProvider.autoDispose
    .family<CommunityPageModel<CommunityCommentModel>, int>((ref, postId) {
      ref.watch(authProvider.select((state) => state.activeProfile?.id));
      return ref.read(communityServiceProvider).fetchComments(postId);
    });
