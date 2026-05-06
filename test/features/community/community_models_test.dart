import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/public_profile_model.dart';
import 'package:kitaplig/features/community/models/community_models.dart';

void main() {
  test('CommunityPostModel parses backend payload safely', () {
    final post = CommunityPostModel.fromJson({
      'id': 12,
      'type': 'quote',
      'body': 'Kısa bir not',
      'quote_text': 'Bir alıntı',
      'quote_source': 'Kitap',
      'visibility': 'public',
      'status': 'published',
      'is_admin_approved': true,
      'created_at': '2026-05-06T10:00:00+03:00',
      'author': {
        'id': 7,
        'name': 'Serkan',
        'username': 'serkan',
        'avatar_url': null,
        'is_premium': true,
      },
      'book': {
        'id': 5,
        'title': 'Deneme Kitabı',
        'slug': 'deneme-kitabi',
        'cover_image_url': null,
        'author': 'Yazar',
      },
      'images': [
        {'id': 1, 'url': 'https://example.com/a.jpg', 'sort_order': 0},
      ],
      'counts': {'likes': 3, 'comments': 2, 'saves': 1, 'reports': 0},
      'viewer_state': {
        'is_liked': true,
        'is_saved': false,
        'is_reported': false,
        'can_comment': true,
        'can_edit': false,
        'can_delete': false,
        'can_report': true,
      },
    });

    expect(post.id, 12);
    expect(post.type, 'quote');
    expect(post.author.username, 'serkan');
    expect(post.book?.slug, 'deneme-kitabi');
    expect(post.images.single.url, 'https://example.com/a.jpg');
    expect(post.counts.likes, 3);
    expect(post.viewerState.isLiked, isTrue);
    expect(post.viewerState.canReport, isTrue);
  });

  test('CommunityPageMeta exposes pagination state', () {
    final meta = CommunityPageMeta.fromJson({
      'current_page': '2',
      'last_page': 4,
      'per_page': 15,
      'total': 48,
    });

    expect(meta.currentPage, 2);
    expect(meta.hasMore, isTrue);
  });

  test('ProfileCountsModel parses community post count aliases', () {
    expect(
      ProfileCountsModel.fromJson({
        'followers': 1,
        'following': 2,
        'posts': 3,
      }).posts,
      3,
    );
    expect(
      ProfileCountsModel.fromJson({
        'followers': 1,
        'following': 2,
        'community_posts': 4,
      }).posts,
      4,
    );
  });
}
