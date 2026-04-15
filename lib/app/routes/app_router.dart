import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../providers/settings_provider.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/onboarding_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/forgot_password_screen.dart';
import '../../features/auth/screens/verify_pin_screen.dart';
import '../../features/auth/screens/reset_password_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/home/screens/notifications_screen.dart';
import '../../features/discover/screens/discover_screen.dart';
import '../../features/discover/screens/search_screen.dart';
import '../../features/book/screens/book_detail_screen.dart';
import '../../features/book/screens/book_reviews_screen.dart';
import '../../features/book/screens/reader_screen.dart';
import '../../features/book/screens/series_screen.dart';
import '../../features/library/screens/library_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/profile/screens/family_reading_summary_screen.dart';
import '../../features/profile/screens/reader_profiles_screen.dart';
import '../../features/profile/screens/settings_screen.dart';
import '../../features/profile/screens/highlights_screen.dart';
import '../../features/profile/screens/league_history_screen.dart';
import '../../features/league/screens/league_screen.dart';
import '../../features/league/screens/duel_screen.dart';
import '../../features/subscription/screens/paywall_screen.dart';
import '../../features/profile/screens/all_achievements_screen.dart';
import '../../features/ai_story/screens/ai_story_studio_screen.dart';
import '../../core/models/achievement_model.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() {
    notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier();
  ref.onDispose(refreshNotifier.dispose);

  ref.listen<AuthStatus>(authProvider.select((state) => state.status), (
    _,
    status,
  ) {
    refreshNotifier.refresh();
  });
  ref.listen<bool>(
    settingsProvider.select((settings) => settings.onboardingDone),
    (_, onboardingDone) {
      refreshNotifier.refresh();
    },
  );

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authStatus = ref.read(authProvider).status;
      final onboardingDone = ref.read(settingsProvider).onboardingDone;
      final isAuthenticated = authStatus == AuthStatus.authenticated;
      final isUnknown = authStatus == AuthStatus.unknown;
      final location = state.matchedLocation;
      final returnTo = state.uri.queryParameters['returnTo'];

      if (isUnknown) return location == '/splash' ? null : '/splash';

      final isAuthRoute = location == '/login' || location == '/register';
      final isOnboarding = location == '/onboarding';
      final isSplash = location == '/splash';
      final needsOnboarding = !onboardingDone && !isAuthenticated;
      final isReadRoute = location.startsWith('/read/');
      final isProtectedRoute =
          isReadRoute ||
          location == '/league' ||
          location.startsWith('/duels/') ||
          location == '/home/library' ||
          location == '/home/ai-story-studio' ||
          location == '/home/notifications' ||
          location == '/home/profile' ||
          location == '/home/reader-profiles' ||
          location == '/home/settings';

      if (isSplash) return null;
      if (isOnboarding) return null;

      if (needsOnboarding && !isAuthRoute) {
        return '/onboarding';
      }

      if (!isAuthenticated && isProtectedRoute) {
        final encodedReturnTo = Uri.encodeComponent(state.uri.toString());
        return '/login?returnTo=$encodedReturnTo';
      }

      if (isAuthenticated && isAuthRoute) {
        return returnTo?.isNotEmpty == true ? returnTo : '/home';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, state) => const SplashScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (_, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/login', builder: (_, state) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, state) => const RegisterScreen()),
      GoRoute(
        path: '/forgot-password',
        builder: (_, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/verify-pin',
        builder: (_, state) =>
            VerifyPinScreen(email: state.uri.queryParameters['email'] ?? ''),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          email: state.uri.queryParameters['email'] ?? '',
          code: state.uri.queryParameters['code'] ?? '',
        ),
      ),
      GoRoute(
        path: '/home',
        builder: (_, state) => const HomeScreen(),
        routes: [
          GoRoute(
            path: 'discover',
            builder: (_, state) => const DiscoverScreen(),
          ),
          GoRoute(path: 'search', builder: (_, state) => const SearchScreen()),
          GoRoute(
            path: 'ai-story-studio',
            builder: (_, state) => const AiStoryStudioScreen(),
          ),
          GoRoute(
            path: 'library',
            builder: (_, state) => const LibraryScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (_, state) => const NotificationsScreen(),
          ),
          GoRoute(
            path: 'profile',
            builder: (_, state) => const ProfileScreen(standalone: true),
          ),
          GoRoute(
            path: 'reader-profiles',
            builder: (_, state) => const ReaderProfilesScreen(),
            routes: [
              GoRoute(
                path: 'reading-summary',
                builder: (_, state) => const FamilyReadingSummaryScreen(),
              ),
            ],
          ),
          GoRoute(
            path: 'badges',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return AllAchievementsScreen(
                achievements:
                    extra?['achievements'] as List<AchievementModel>? ?? [],
                earnedCount: extra?['earnedCount'] as int? ?? 0,
              );
            },
          ),
          GoRoute(
            path: 'settings',
            builder: (_, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: 'highlights',
            builder: (_, state) => const HighlightsScreen(),
          ),
        ],
      ),
      GoRoute(path: '/league', builder: (_, state) => const LeagueScreen()),
      GoRoute(
        path: '/profil/:username',
        builder: (_, state) => ProfileScreen(
          username: state.pathParameters['username'],
          standalone: true,
        ),
      ),
      GoRoute(path: '/premium', builder: (_, state) => const PaywallScreen()),
      GoRoute(
        path: '/league-history',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final history = (extra?['history'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);
          return LeagueHistoryScreen(
            history: history,
            title: extra?['title'] as String? ?? 'Lig Geçmişi',
          );
        },
      ),
      GoRoute(
        path: '/books/:slug/reviews',
        builder: (_, state) =>
            BookReviewsScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/books/:slug',
        builder: (_, state) =>
            BookDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/series/:seriesId',
        builder: (_, state) => SeriesScreen(
          seriesId: int.parse(state.pathParameters['seriesId']!),
        ),
      ),
      GoRoute(
        path: '/read/:bookId',
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ReaderScreen(
            bookId: int.parse(state.pathParameters['bookId']!),
            bookIsPremium: extra?['isPremium'] == true,
            backTo: state.uri.queryParameters['backTo'],
            startFromBeginning:
                state.uri.queryParameters['startFromBeginning'] == '1',
          );
        },
      ),
      GoRoute(
        path: '/duels/:duelId',
        builder: (_, state) =>
            DuelScreen(duelId: int.parse(state.pathParameters['duelId']!)),
      ),
    ],
  );
});
