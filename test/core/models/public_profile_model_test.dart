import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/public_profile_model.dart';

void main() {
  test('PublicProfileModel payloadini güvenli parse eder', () {
    final profile = PublicProfileModel.fromJson({
      'profile': {
        'id': 12,
        'name': 'Öznur Yalçın',
        'username': 'oznur_yalcin',
        'avatar_url': 'https://example.com/avatar.png',
        'is_premium': true,
      },
      'counts': {
        'followers': 14,
        'following': 9,
      },
      'relationship': {
        'is_self': false,
        'is_following': true,
      },
      'stats': {
        'total_paragraphs_read': 240,
        'completed_books': 6,
        'started_books': 8,
        'current_streak': 5,
        'longest_streak': 11,
      },
      'active_league': {
        'season_number': 2,
        'days_remaining': 3,
        'tier': 'kum',
        'tier_label': 'Kum Ligi',
        'tier_icon': '🪨',
        'tier_color': '#A1855B',
        'group_number': 1,
        'weekly_xp': 30,
        'weekly_lp': 4,
        'duel_wins': 1,
        'duel_losses': 0,
        'streak_shields': 1,
        'rank': 2,
        'group_size': 8,
      },
      'league_history': [
        {
          'season': 'Sezon 1',
          'tier_label': 'Kum Ligi',
          'tier_icon': '🪨',
          'rank': 1,
          'result': 'promoted',
        },
      ],
      'achievements': [
        {
          'id': 1,
          'key': 'first_finish',
          'title': 'İlk Kitap',
          'description': 'İlk kitabını bitirdin.',
          'icon': '🏅',
          'rarity': 'common',
          'xp_reward': 10,
          'category': 'reading',
          'source': 'api',
          'progress_current': 1,
          'progress_target': 1,
          'earned_at': '2026-03-24T09:00:00.000Z',
          'seen_at': '2026-03-24T10:00:00.000Z',
        },
      ],
    });

    expect(profile.profile.username, 'oznur_yalcin');
    expect(profile.counts.followers, 14);
    expect(profile.relationship.isFollowing, isTrue);
    expect(profile.stats.totalParagraphsRead, 240);
    expect(profile.activeLeague?.weeklyLp, 4);
    expect(profile.leagueHistory, hasLength(1));
    expect(profile.achievements, hasLength(1));
    expect(profile.achievements.first.isEarned, isTrue);
  });
}
