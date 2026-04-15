import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/auth_session_model.dart';

void main() {
  test('AuthSessionModel profile capability alanını parse eder', () {
    final session = AuthSessionModel.fromJson({
      'account': {
        'id': 9,
        'name': 'Serkan',
        'username': 'serkan',
        'email': 'serkan@example.com',
        'provider': 'email',
        'is_premium': false,
        'daily_goal': 10,
        'preferred_theme': 'light',
        'preferred_font_size': 16,
        'children_mode_enabled': false,
        'has_parent_pin': true,
      },
      'profiles': [
        {
          'id': 1,
          'user_id': 9,
          'name': 'Serkan',
          'type': 'parent',
          'content_mode': 'adult',
          'is_default': true,
          'is_active_for_last_session': true,
          'is_archived': false,
        },
      ],
      'active_profile': {
        'id': 1,
        'user_id': 9,
        'name': 'Serkan',
        'type': 'parent',
        'content_mode': 'adult',
        'is_default': true,
        'is_active_for_last_session': true,
        'is_archived': false,
      },
      'profile_capabilities': {
        'max_child_profiles': 1,
        'active_child_profiles_count': 1,
        'can_create_child_profile': false,
        'requires_premium_for_more': true,
      },
    });

    expect(session.profileCapabilities.maxChildProfiles, 1);
    expect(session.profileCapabilities.activeChildProfilesCount, 1);
    expect(session.profileCapabilities.canCreateChildProfile, isFalse);
    expect(session.profileCapabilities.requiresPremiumForMore, isTrue);
  });
}
