import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:kitaplig/app/providers/settings_provider.dart';
import 'package:kitaplig/app/routes/app_router.dart';
import 'package:kitaplig/main.dart';

void main() {
  group('KitapLigApp', () {
    testWidgets('renders router content with provider overrides', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Test Route Content'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            settingsProvider.overrideWith(
              (ref) => _TestSettingsNotifier(
                const UserSettings(theme: 'light', onboardingDone: true),
              ),
            ),
          ],
          child: const KitapLigApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Test Route Content'), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('applies sepia builder wrapper when sepia theme is active', (
      WidgetTester tester,
    ) async {
      final router = GoRouter(
        initialLocation: '/test',
        routes: [
          GoRoute(
            path: '/test',
            builder: (_, __) =>
                const Scaffold(body: Center(child: Text('Sepia Route'))),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            routerProvider.overrideWithValue(router),
            settingsProvider.overrideWith(
              (ref) => _TestSettingsNotifier(
                const UserSettings(theme: 'sepia', onboardingDone: true),
              ),
            ),
          ],
          child: const KitapLigApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Sepia Route'), findsOneWidget);
      expect(find.byType(ColorFiltered), findsWidgets);
    });
  });
}

class _TestSettingsNotifier extends SettingsNotifier {
  _TestSettingsNotifier(UserSettings value) : super() {
    state = value;
  }
}
