import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/books_provider.dart';
import '../../../app/providers/connectivity_provider.dart';
import '../../../app/providers/home_shell_provider.dart';
import '../../../app/providers/kids_provider.dart';
import '../../../app/providers/library_provider.dart';
import '../../../app/providers/notification_provider.dart';
import '../../../app/providers/progress_provider.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/models/progress_model.dart';
import '../../league/widgets/league_mini_card.dart';
import 'home_daily_quote_card.dart';
import 'home_tab_sections.dart';

ProgressModel? _findContinueReadingProgress(
  List<ProgressModel> progress, {
  required bool isKidsMode,
}) {
  for (final item in progress) {
    final book = item.book;
    if (book == null) continue;
    if (item.isCompleted || item.completionPercentage >= 100) continue;
    if (isKidsMode && book.isKids != true) continue;
    return item;
  }
  return null;
}

class HomeTabSection extends ConsumerStatefulWidget {
  const HomeTabSection({
    super.key,
    required this.onOpenDiscover,
    required this.isActive,
  });

  final ValueChanged<String?> onOpenDiscover;
  final bool isActive;

  @override
  ConsumerState<HomeTabSection> createState() => _HomeTabSectionState();
}

class _HomeTabSectionState extends ConsumerState<HomeTabSection>
    with WidgetsBindingObserver {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isActive) {
        refreshNotificationProvidersForWidget(ref);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeTabSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.isActive && widget.isActive) {
      refreshNotificationProvidersForWidget(ref);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && widget.isActive) {
      refreshNotificationProvidersForWidget(ref);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAuthenticated = authState.isAuthenticated;
    final progressAsync = ref.watch(allProgressProvider);
    final featuredAsync = ref.watch(featuredBooksProvider);
    final categoriesAsync = ref.watch(homeQuickCategoriesProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final kidsModeEnabled = ref.watch(kidsModeProvider);
    final continueReadingProgress = isAuthenticated
        ? _findContinueReadingProgress(
            progressAsync.valueOrNull ?? const [],
            isKidsMode: kidsModeEnabled,
          )
        : null;
    final showLeagueSection = isAuthenticated && !kidsModeEnabled;

    return SafeArea(
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppUI.screenHorizontalPadding,
            AppUI.screenTopPadding,
            AppUI.screenHorizontalPadding,
            AppUI.screenBottomContentPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (kidsModeEnabled) ...[
                const SizedBox(height: AppUI.blockGap),
                const KidsModeInfoCard(),
                const SizedBox(height: AppUI.blockGap),
              ],
              if (isAuthenticated &&
                  (authState.isOfflineSession ||
                      ref.watch(isDeviceOfflineProvider))) ...[
                OfflineReadingBanner(
                  onOpenDownloads: () {
                    ref.read(homeTabRequestProvider.notifier).state =
                        kHomeShellLibraryTabIndex;
                    ref.read(libraryFocusDownloadsProvider.notifier).state =
                        true;
                  },
                ),
                const SizedBox(height: AppUI.blockGap),
              ],
              const SizedBox(height: AppUI.blockGap),
              HomeGreetingSection(
                user: user,
                isAuthenticated: isAuthenticated,
                kidsModeEnabled: kidsModeEnabled,
                onSearchTap: () => context.push('/home/search'),
              ),
              if (isAuthenticated && !isPremium) ...[
                const SizedBox(height: AppUI.blockGap),
                CompactPremiumCta(onTap: () => context.push('/premium')),
              ],
              const SizedBox(height: AppUI.sectionGap),
              const DailyQuoteCardSection(),
              if (showLeagueSection || continueReadingProgress != null)
                const SizedBox(height: AppUI.sectionGap),
              if (showLeagueSection) ...[
                const LeagueMiniCard(),
                if (continueReadingProgress != null)
                  const SizedBox(height: AppUI.sectionGap),
              ],
              if (continueReadingProgress != null)
                HomeContinueReadingSection(recent: continueReadingProgress),
              const SizedBox(height: AppUI.sectionGap),
              HomeQuickCategoriesSection(
                categoriesAsync: categoriesAsync,
                kidsModeEnabled: kidsModeEnabled,
                onOpenDiscover: widget.onOpenDiscover,
              ),
              const SizedBox(height: AppUI.sectionGap),
              HomeFeaturedBooksSection(
                featuredAsync: featuredAsync,
                onOpenDiscover: widget.onOpenDiscover,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
