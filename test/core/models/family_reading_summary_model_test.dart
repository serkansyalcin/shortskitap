import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/family_reading_summary_model.dart';

void main() {
  test('parses family reading summary and resolves top reader', () {
    final summary = FamilyReadingSummaryModel.fromJson({
      'period': {
        'days': 28,
        'label': 'Son 4 hafta',
        'start_date': '2026-03-19',
        'end_date': '2026-04-15',
      },
      'totals': {
        'total_paragraphs': 52,
        'total_minutes': 34,
        'completed_books': 2,
        'active_profiles': 2,
      },
      'profiles': [
        {
          'profile': {
            'id': 11,
            'user_id': 3,
            'name': 'Elif',
            'type': 'child',
            'content_mode': 'kids',
            'avatar_url': 'reader-avatar://default/fox',
            'birth_year': 2018,
            'is_default': false,
            'is_active_for_last_session': false,
            'is_archived': false,
          },
          'total_paragraphs': 30,
          'total_minutes': 20,
          'completed_books': 1,
          'active_days': 4,
          'last_activity_date': '2026-04-15',
          'heatmap': {'2026-04-15': 12},
        },
        {
          'profile': {
            'id': 10,
            'user_id': 3,
            'name': 'Serkan',
            'type': 'parent',
            'content_mode': 'adult',
            'avatar_url': 'https://example.com/avatar.jpg',
            'birth_year': null,
            'is_default': true,
            'is_active_for_last_session': true,
            'is_archived': false,
          },
          'total_paragraphs': 22,
          'total_minutes': 14,
          'completed_books': 1,
          'active_days': 3,
          'last_activity_date': '2026-04-14',
          'heatmap': {'2026-04-14': 8},
        },
      ],
    });

    expect(summary.periodDays, 28);
    expect(summary.totalParagraphs, 52);
    expect(summary.activeProfiles, 2);
    expect(summary.topReader?.profile.name, 'Elif');
    expect(summary.profiles.first.heatmap['2026-04-15'], 12);
  });
}
