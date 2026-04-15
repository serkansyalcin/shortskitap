import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kitaplig/app/providers/notification_provider.dart';
import 'package:kitaplig/core/models/app_notification_model.dart';
import 'package:kitaplig/features/home/widgets/app_notification_tile.dart';

class NotificationBellButton extends ConsumerStatefulWidget {
  const NotificationBellButton({super.key});

  @override
  ConsumerState<NotificationBellButton> createState() =>
      _NotificationBellButtonState();
}

class _NotificationBellButtonState
    extends ConsumerState<NotificationBellButton> {
  final GlobalKey _buttonKey = GlobalKey();
  bool _isOpening = false;

  Future<void> _openMenu() async {
    if (_isOpening) {
      return;
    }

    setState(() => _isOpening = true);

    try {
      ref.invalidate(notificationPreviewProvider);
      final page = await ref.read(notificationPreviewProvider.future);
      var previewItems = page.items;

      if (previewItems.isNotEmpty) {
        try {
          await ref
              .read(notificationCenterServiceProvider)
              .markVisible(previewItems.map((item) => item.id).toList());
          final readAt = DateTime.now();
          previewItems = previewItems
              .map((item) => item.copyWith(readAt: readAt, isRead: true))
              .toList(growable: false);
        } catch (_) {}
        refreshNotificationProvidersForWidget(ref);
      }

      if (!mounted) {
        return;
      }

      final buttonBox =
          _buttonKey.currentContext?.findRenderObject() as RenderBox?;
      final overlayBox =
          Overlay.of(context).context.findRenderObject() as RenderBox?;
      if (buttonBox == null || overlayBox == null) {
        return;
      }

      final buttonRect = Rect.fromPoints(
        buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox),
        buttonBox.localToGlobal(
          buttonBox.size.bottomRight(Offset.zero),
          ancestor: overlayBox,
        ),
      );

      final selected = await showMenu<String>(
        context: context,
        position: RelativeRect.fromRect(
          buttonRect,
          Offset.zero & overlayBox.size,
        ),
        items: _buildMenuItems(previewItems, context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      );

      if (!mounted || selected == null) {
        return;
      }

      if (selected == 'all') {
        context.push('/home/notifications');
        return;
      }

      if (selected.startsWith('notification:')) {
        final id = int.tryParse(selected.split(':').last);
        if (id == null) {
          return;
        }

        AppNotificationModel? notification;
        for (final item in previewItems) {
          if (item.id == id) {
            notification = item;
            break;
          }
        }
        if (notification == null) {
          return;
        }

        await _handleNotificationTap(notification);
      }
    } finally {
      if (mounted) {
        setState(() => _isOpening = false);
      }
    }
  }

  Future<void> _handleNotificationTap(AppNotificationModel notification) async {
    try {
      await ref
          .read(notificationCenterServiceProvider)
          .markRead(notification.id);
    } catch (_) {}
    refreshNotificationProvidersForWidget(ref);

    if (!mounted || notification.deeplink == null) {
      return;
    }

    context.push(notification.deeplink!);
  }

  List<PopupMenuEntry<String>> _buildMenuItems(
    List<AppNotificationModel> previewItems,
    BuildContext context,
  ) {
    final theme = Theme.of(context);
    final entries = <PopupMenuEntry<String>>[
      PopupMenuItem<String>(
        enabled: false,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: SizedBox(
          width: 320,
          child: Text(
            'Son Bildirimler',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    ];

    if (previewItems.isEmpty) {
      entries.add(
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: SizedBox(
            width: 320,
            child: Text(
              'Şimdilik yeni bildirim yok.',
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    } else {
      for (final notification in previewItems) {
        entries.add(
          PopupMenuItem<String>(
            value: 'notification:${notification.id}',
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SizedBox(
              width: 320,
              child: AppNotificationTile(
                notification: notification,
                compact: true,
                showChevron: false,
              ),
            ),
          ),
        );
      }
    }

    entries.add(const PopupMenuDivider());
    entries.add(
      const PopupMenuItem<String>(
        value: 'all',
        child: Text(
          'Tümünü Gör',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );

    return entries;
  }

  @override
  Widget build(BuildContext context) {
    final unreadAsync = ref.watch(unreadNotificationsCountProvider);
    final unreadCount = unreadAsync.valueOrNull ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          key: _buttonKey,
          tooltip: 'Bildirimler',
          onPressed: _openMenu,
          icon: _isOpening
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.notifications_none_rounded),
        ),
        if (unreadCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(6, -6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Text(
                    unreadCount > 99 ? '99+' : '$unreadCount',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
