import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/models/reader_profile_capabilities_model.dart';
import 'package:kitaplig/core/models/reader_profile_model.dart';
import 'package:kitaplig/features/profile/widgets/reader_profiles_summary_card.dart';

void main() {
  final parentProfile = ReaderProfileModel.fromJson({
    'id': 1,
    'user_id': 7,
    'name': 'Serkan',
    'type': 'parent',
    'content_mode': 'adult',
    'is_default': true,
    'is_active_for_last_session': true,
    'is_archived': false,
  });

  testWidgets('özet kartı aktif profili ve çocuk sayısını gösterir', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ReaderProfilesSummaryCard(
            activeProfile: parentProfile,
            profileCapabilities: const ReaderProfileCapabilitiesModel(
              maxChildProfiles: 4,
              activeChildProfilesCount: 2,
              canCreateChildProfile: true,
              requiresPremiumForMore: false,
            ),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('OKUYUCU PROFİLLERİ'), findsOneWidget);
    expect(find.text('Serkan'), findsOneWidget);
    expect(find.text('Ebeveyn aktif'), findsOneWidget);
    expect(find.text('2/4 çocuk profili'), findsOneWidget);
    expect(find.text('Aile hesabı'), findsOneWidget);
  });
}
