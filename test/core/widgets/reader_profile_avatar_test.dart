import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kitaplig/core/widgets/reader_profile_avatar.dart';

void main() {
  testWidgets(
    'default avatar tokenı network image yerine preset avatar çizer',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReaderProfileAvatar(
              name: 'Mina',
              avatarRef: 'reader-avatar://default/fox',
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.pets_rounded), findsOneWidget);
      expect(find.text('M'), findsNothing);
    },
  );
}
