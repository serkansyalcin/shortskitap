import 'dart:typed_data';

class CommunityPageMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  const CommunityPageMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;

  factory CommunityPageMeta.fromJson(Map<String, dynamic> json) {
    return CommunityPageMeta(
      currentPage: _asInt(json['current_page'], fallback: 1),
      lastPage: _asInt(json['last_page'], fallback: 1),
      perPage: _asInt(json['per_page'], fallback: 15),
      total: _asInt(json['total']),
    );
  }
}

class CommunityPageModel<T> {
  final List<T> items;
  final CommunityPageMeta meta;

  const CommunityPageModel({required this.items, required this.meta});
}

class CommunityAuthorModel {
  final int id;
  final String name;
  final String username;
  final String? avatarUrl;
  final bool isPremium;

  const CommunityAuthorModel({
    required this.id,
    required this.name,
    required this.username,
    this.avatarUrl,
    required this.isPremium,
  });

  factory CommunityAuthorModel.fromJson(Map<String, dynamic> json) {
    return CommunityAuthorModel(
      id: _asInt(json['id']),
      name: json['name'] as String? ?? '',
      username: json['username'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      isPremium: json['is_premium'] == true,
    );
  }
}

class CommunityBookPreviewModel {
  final int id;
  final String title;
  final String slug;
  final String? coverImageUrl;
  final String? author;

  const CommunityBookPreviewModel({
    required this.id,
    required this.title,
    required this.slug,
    this.coverImageUrl,
    this.author,
  });

  factory CommunityBookPreviewModel.fromJson(Map<String, dynamic> json) {
    return CommunityBookPreviewModel(
      id: _asInt(json['id']),
      title: json['title'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      coverImageUrl: json['cover_image_url'] as String?,
      author: json['author'] as String?,
    );
  }
}

class CommunityImageModel {
  final int id;
  final String url;
  final int sortOrder;

  const CommunityImageModel({
    required this.id,
    required this.url,
    required this.sortOrder,
  });

  factory CommunityImageModel.fromJson(Map<String, dynamic> json) {
    return CommunityImageModel(
      id: _asInt(json['id']),
      url: json['url'] as String? ?? '',
      sortOrder: _asInt(json['sort_order']),
    );
  }
}

class CommunityCountsModel {
  final int likes;
  final int comments;
  final int saves;
  final int reports;

  const CommunityCountsModel({
    required this.likes,
    required this.comments,
    required this.saves,
    required this.reports,
  });

  factory CommunityCountsModel.fromJson(Map<String, dynamic> json) {
    return CommunityCountsModel(
      likes: _asInt(json['likes']),
      comments: _asInt(json['comments']),
      saves: _asInt(json['saves']),
      reports: _asInt(json['reports']),
    );
  }

  CommunityCountsModel copyWith({
    int? likes,
    int? comments,
    int? saves,
    int? reports,
  }) {
    return CommunityCountsModel(
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      saves: saves ?? this.saves,
      reports: reports ?? this.reports,
    );
  }
}

class CommunityViewerStateModel {
  final bool isLiked;
  final bool isSaved;
  final bool isReported;
  final bool canComment;
  final bool canEdit;
  final bool canDelete;
  final bool canReport;

  const CommunityViewerStateModel({
    required this.isLiked,
    required this.isSaved,
    required this.isReported,
    required this.canComment,
    required this.canEdit,
    required this.canDelete,
    required this.canReport,
  });

  factory CommunityViewerStateModel.fromJson(Map<String, dynamic> json) {
    return CommunityViewerStateModel(
      isLiked: json['is_liked'] == true,
      isSaved: json['is_saved'] == true,
      isReported: json['is_reported'] == true,
      canComment: json['can_comment'] == true,
      canEdit: json['can_edit'] == true,
      canDelete: json['can_delete'] == true,
      canReport: json['can_report'] == true,
    );
  }

  CommunityViewerStateModel copyWith({
    bool? isLiked,
    bool? isSaved,
    bool? isReported,
    bool? canComment,
    bool? canEdit,
    bool? canDelete,
    bool? canReport,
  }) {
    return CommunityViewerStateModel(
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isReported: isReported ?? this.isReported,
      canComment: canComment ?? this.canComment,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      canReport: canReport ?? this.canReport,
    );
  }
}

class CommunityPostModel {
  final int id;
  final String type;
  final String? body;
  final String? quoteText;
  final String? quoteSource;
  final String visibility;
  final String status;
  final bool isAdminApproved;
  final String? hiddenReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CommunityAuthorModel author;
  final CommunityBookPreviewModel? book;
  final List<CommunityImageModel> images;
  final CommunityCountsModel counts;
  final CommunityViewerStateModel viewerState;

  const CommunityPostModel({
    required this.id,
    required this.type,
    this.body,
    this.quoteText,
    this.quoteSource,
    required this.visibility,
    required this.status,
    required this.isAdminApproved,
    this.hiddenReason,
    this.createdAt,
    this.updatedAt,
    required this.author,
    this.book,
    required this.images,
    required this.counts,
    required this.viewerState,
  });

  factory CommunityPostModel.fromJson(Map<String, dynamic> json) {
    final images = (json['images'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(CommunityImageModel.fromJson)
        .toList(growable: false);

    return CommunityPostModel(
      id: _asInt(json['id']),
      type: json['type'] as String? ?? 'text',
      body: json['body'] as String?,
      quoteText: json['quote_text'] as String?,
      quoteSource: json['quote_source'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      status: json['status'] as String? ?? 'published',
      isAdminApproved: json['is_admin_approved'] == true,
      hiddenReason: json['hidden_reason'] as String?,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      author: CommunityAuthorModel.fromJson(
        json['author'] as Map<String, dynamic>? ?? const {},
      ),
      book: json['book'] is Map<String, dynamic>
          ? CommunityBookPreviewModel.fromJson(
              json['book'] as Map<String, dynamic>,
            )
          : null,
      images: images,
      counts: CommunityCountsModel.fromJson(
        json['counts'] as Map<String, dynamic>? ?? const {},
      ),
      viewerState: CommunityViewerStateModel.fromJson(
        json['viewer_state'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  CommunityPostModel copyWith({
    CommunityCountsModel? counts,
    CommunityViewerStateModel? viewerState,
  }) {
    return CommunityPostModel(
      id: id,
      type: type,
      body: body,
      quoteText: quoteText,
      quoteSource: quoteSource,
      visibility: visibility,
      status: status,
      isAdminApproved: isAdminApproved,
      hiddenReason: hiddenReason,
      createdAt: createdAt,
      updatedAt: updatedAt,
      author: author,
      book: book,
      images: images,
      counts: counts ?? this.counts,
      viewerState: viewerState ?? this.viewerState,
    );
  }
}

class CommunityCommentModel {
  final int id;
  final String body;
  final String status;
  final DateTime? createdAt;
  final CommunityAuthorModel author;
  final CommunityViewerStateModel viewerState;

  const CommunityCommentModel({
    required this.id,
    required this.body,
    required this.status,
    this.createdAt,
    required this.author,
    required this.viewerState,
  });

  factory CommunityCommentModel.fromJson(Map<String, dynamic> json) {
    return CommunityCommentModel(
      id: _asInt(json['id']),
      body: json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'published',
      createdAt: _parseDate(json['created_at']),
      author: CommunityAuthorModel.fromJson(
        json['author'] as Map<String, dynamic>? ?? const {},
      ),
      viewerState: CommunityViewerStateModel.fromJson(
        json['viewer_state'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class CommunityComposePayload {
  final String? body;
  final String? quoteText;
  final String? quoteSource;
  final int? bookId;
  final int? paragraphId;
  final String visibility;
  final List<CommunityImagePayload> images;

  const CommunityComposePayload({
    this.body,
    this.quoteText,
    this.quoteSource,
    this.bookId,
    this.paragraphId,
    this.visibility = 'public',
    this.images = const [],
  });
}

class CommunityImagePayload {
  final Uint8List bytes;
  final String fileName;

  const CommunityImagePayload({required this.bytes, required this.fileName});
}

DateTime? _parseDate(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

int _asInt(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}
