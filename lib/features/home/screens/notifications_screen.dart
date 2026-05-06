import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaplig/app/providers/notification_provider.dart';
import 'package:kitaplig/core/models/app_notification_model.dart';
import 'package:kitaplig/features/home/widgets/app_notification_tile.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  late final ScrollController _scrollController;
  bool _isMarkingAllRead = false;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationsFeedProvider.notifier).loadInitial();
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }

    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(notificationsFeedProvider.notifier).loadMore();
    }
  }

  Future<void> _handleNotificationTap(AppNotificationModel notification) async {
    await ref.read(notificationsFeedProvider.notifier).markAsRead(notification);
    if (!mounted || notification.deeplink == null) {
      return;
    }
    context.push(notification.deeplink!);
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAllRead) {
      return;
    }

    setState(() => _isMarkingAllRead = true);
    try {
      await ref.read(notificationsFeedProvider.notifier).markAllAsRead();
    } finally {
      if (mounted) {
        setState(() => _isMarkingAllRead = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsFeedProvider);
    final hasUnread = state.items.any((item) => !item.isRead);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirimler'),
        actions: [
          if (hasUnread)
            TextButton(
              onPressed: _isMarkingAllRead ? null : _markAllAsRead,
              child: _isMarkingAllRead
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tümünü Okundu Yap'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          refreshNotificationProvidersForWidget(ref);
          await ref.read(notificationsFeedProvider.notifier).refresh();
        },
        child: Builder(
          builder: (context) {
            if (state.isLoadingInitial && state.items.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state.errorMessage != null && state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.notifications_off_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Bildirimler yüklenemedi',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    state.errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }

            if (state.items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  const SizedBox(height: 120),
                  Icon(
                    Icons.notifications_none_rounded,
                    size: 56,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Henüz bildirim yok',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Düello teklifleri, lig sonuçları ve LP hareketleri burada görünecek.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index >= state.items.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final notification = state.items[index];
                return AppNotificationTile(
                  notification: notification,
                  onTap: () => _handleNotificationTap(notification),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
