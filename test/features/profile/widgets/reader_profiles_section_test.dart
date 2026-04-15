import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/reader_profile_capabilities_model.dart';
import 'package:kitaplig/core/models/reader_profile_model.dart';
import 'package:kitaplig/features/profile/widgets/reader_profiles_section.dart';

void main() {
  final parentProfile = ReaderProfileModel.fromJson({
    'id': 1,
    'user_id': 4,
    'name': 'Ebeveyn',
    'type': 'parent',
    'content_mode': 'adult',
    'is_default': true,
    'is_active_for_last_session': true,
    'is_archived': false,
  });
  final childProfile = ReaderProfileModel.fromJson({
    'id': 2,
    'user_id': 4,
    'name': 'Mina',
    'type': 'child',
    'content_mode': 'kids',
    'birth_year': 2018,
    'is_default': false,
    'is_active_for_last_session': false,
    'is_archived': false,
  });

  testWidgets('ebeveyn görünümünde limit doluysa premium CTA gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderProfilesSection(
            activeProfile: parentProfile,
            profiles: [parentProfile, childProfile],
            profileCapabilities: const ReaderProfileCapabilitiesModel(
              maxChildProfiles: 1,
              activeChildProfilesCount: 1,
              canCreateChildProfile: false,
              requiresPremiumForMore: true,
            ),
            isPremium: false,
            onAddProfile: () {},
            onActivateProfile: (_) {},
            onEditProfile: (_) {},
            onArchiveProfile: (_) {},
            onUpgradeTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Daha fazla profil için Premium'), findsOneWidget);
    expect(find.text('Mina'), findsOneWidget);
    expect(find.text('Premium\'a Geç'), findsOneWidget);
    expect(find.text('Daha Fazlası İçin Premium'), findsNothing);
  });

  testWidgets('çocuk görünümünde yönetim yerine yönlendirme gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderProfilesSection(
            activeProfile: childProfile,
            profiles: [parentProfile, childProfile],
            profileCapabilities: const ReaderProfileCapabilitiesModel(
              maxChildProfiles: 4,
              activeChildProfilesCount: 1,
              canCreateChildProfile: true,
              requiresPremiumForMore: false,
            ),
            isPremium: true,
            onAddProfile: () {},
            onActivateProfile: (_) {},
            onEditProfile: (_) {},
            onArchiveProfile: (_) {},
            onUpgradeTap: () {},
          ),
        ),
      ),
    );

    expect(
      find.text('Profil yönetimi ebeveyn profilinde açık'),
      findsOneWidget,
    );
    expect(find.text('Yeni Çocuk Profili'), findsNothing);
  });
}
