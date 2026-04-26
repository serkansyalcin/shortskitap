import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kitaplig/app/providers/auth_provider.dart';
import 'package:kitaplig/core/api/api_client.dart';
import 'package:kitaplig/core/models/app_notification_model.dart';
import 'package:kitaplig/core/services/notification_center_service.dart';
import 'package:dio/dio.dart';
import 'package:kitaplig/core/utils/user_friendly_error.dart';

final notificationCenterServiceProvider = Provider<NotificationCenterService>((
  ref,
) {
  return NotificationCenterService(ApiClient.instance);
});

final unreadNotificationsCountProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  final activeProfileId = ref.watch(
    authProvider.select((state) => state.activeProfile?.id),
  );
  if (userId == null || activeProfileId == null) {
    return 0;
  }

  try {
    return await ref.read(notificationCenterServiceProvider).getUnreadCount();
  } on DioException {
    return 0;
  } catch (_) {
    return 0;
  }
});

final notificationPreviewProvider = FutureProvider<NotificationPageModel>((
  ref,
) async {
  final userId = ref.watch(authProvider.select((state) => state.user?.id));
  final activeProfileId = ref.watch(
    authProvider.select((state) => state.activeProfile?.id),
  );
  if (userId == null || activeProfileId == null) {
    return const NotificationPageModel.empty();
  }

  try {
    return await ref
        .read(notificationCenterServiceProvider)
        .fetchNotifications(limit: 5);
  } on DioException {
    return const NotificationPageModel.empty();
  } catch (_) {
    return const NotificationPageModel.empty();
  }
});

void refreshNotificationProviders(Ref ref) {
  ref.invalidate(unreadNotificationsCountProvider);
  ref.invalidate(notificationPreviewProvider);
}

void refreshNotificationProvidersForWidget(WidgetRef ref) {
  ref.invalidate(unreadNotificationsCountProvider);
  ref.invalidate(notificationPreviewProvider);
}

final notificationsFeedProvider =
    StateNotifierProvider.autoDispose<
      NotificationsFeedNotifier,
      NotificationsFeedState
    >((ref) {
      final userId = ref.watch(authProvider.select((state) => state.user?.id));
      final activeProfileId = ref.watch(
        authProvider.select((state) => state.activeProfile?.id),
      );
      return NotificationsFeedNotifier(
        ref,
        ref.read(notificationCenterServiceProvider),
        userId,
        activeProfileId,
      );
    });

class NotificationsFeedState {
  final List<AppNotificationModel> items;
  final bool isLoadingInitial;
  final bool isLoadingMore;
  final String? nextCursor;
  final String? errorMessage;

  const NotificationsFeedState({
    this.items = const <AppNotificationModel>[],
    this.isLoadingInitial = false,
    this.isLoadingMore = false,
    this.nextCursor,
    this.errorMessage,
  });

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;

  NotificationsFeedState copyWith({
    List<AppNotificationModel>? items,
    bool? isLoadingInitial,
    bool? isLoadingMore,
    Object? nextCursor = _sentinel,
    Object? errorMessage = _sentinel,
  }) {
    return NotificationsFeedState(
      items: items ?? this.items,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      nextCursor: identical(nextCursor, _sentinel)
          ? this.nextCursor
          : nextCursor as String?,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const _sentinel = Object();

class NotificationsFeedNotifier extends StateNotifier<NotificationsFeedState> {
  final Ref _ref;
  final NotificationCenterService _service;
  final int? _userId;
  final int? _activeProfileId;

  NotificationsFeedNotifier(
    this._ref,
    this._service,
    this._userId,
    this._activeProfileId,
  ) : super(const NotificationsFeedState());

  Future<void> loadInitial() async {
    if (_userId == null || _activeProfileId == null) {
      state = const NotificationsFeedState();
      return;
    }

    state = state.copyWith(
      isLoadingInitial: true,
      errorMessage: null,
      nextCursor: null,
    );

    try {
      final page = await _service.fetchNotifications(limit: 20);
      final items = await _markVisible(page.items);
      state = NotificationsFeedState(
        items: items,
        nextCursor: page.nextCursor,
        isLoadingInitial: false,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingInitial: false,
        errorMessage: userFacingErrorMessage(
          error,
          fallback:
              'Bildirimler su anda yuklenemiyor. Lutfen biraz sonra tekrar deneyin.',
        ),
      );
    }
  }

  Future<void> refresh() async {
    await loadInitial();
  }

  Future<void> loadMore() async {
    if (_userId == null ||
        _activeProfileId == null ||
        state.isLoadingInitial ||
        state.isLoadingMore ||
        !state.hasMore) {
      return;
    }

    state = state.copyWith(isLoadingMore: true, errorMessage: null);

    try {
      final page = await _service.fetchNotifications(
        limit: 20,
        cursor: state.nextCursor,
      );
      final newItems = await _markVisible(page.items);
      state = state.copyWith(
        items: [...state.items, ...newItems],
        isLoadingMore: false,
        nextCursor: page.nextCursor,
      );
    } catch (error) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: userFacingErrorMessage(
          error,
          fallback: 'Daha fazla bildirim yuklenemedi.',
        ),
      );
    }
  }

  Future<void> markAsRead(AppNotificationModel notification) async {
    try {
      await _service.markRead(notification.id);
    } catch (_) {
      // Keep the UI responsive even if the backend mark-read call fails.
    } finally {
      _setItemsAsRead([notification.id]);
      refreshNotificationProviders(_ref);
    }
  }

  Future<List<AppNotificationModel>> _markVisible(
    List<AppNotificationModel> items,
  ) async {
    final ids = items.map((item) => item.id).toList(growable: false);
    if (ids.isEmpty) {
      return items;
    }
    try {
      await _service.markVisible(ids);
    } catch (_) {
      return items;
    } finally {
      refreshNotificationProviders(_ref);
    }

    final readAt = DateTime.now();
    return items
        .map((item) => item.copyWith(readAt: readAt, isRead: true))
        .toList(growable: false);
  }

  void _setItemsAsRead(List<int> ids) {
    final idSet = ids.toSet();
    final readAt = DateTime.now();
    state = state.copyWith(
      items: [
        for (final item in state.items)
          if (idSet.contains(item.id))
            item.copyWith(readAt: readAt, isRead: true)
          else
            item,
      ],
    );
  }
}
