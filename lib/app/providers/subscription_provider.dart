import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/subscription_service.dart';
import 'auth_provider.dart';

final _subscriptionService = SubscriptionService();

/// Holds the subscription status fetched from the backend.
/// Automatically initialised when auth state changes.
class SubscriptionStatusNotifier extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    // Watch auth state - re-run when user logs in/out.
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated || auth.user == null) {
      return const SubscriptionStatus.free();
    }

    // Configure RevenueCat with the user's ID on first build.
    await SubscriptionService.configure(auth.user!.id.toString());

    final status = await _subscriptionService.getStatusFromBackend();
    if (!status.isPremium && auth.user!.isPremium) {
      return SubscriptionStatus(
        isPremium: true,
        planType: status.planType,
        planLabel: status.planLabel,
        startedAt: status.startedAt,
        expiresAt: status.expiresAt,
        isLifetime: status.isLifetime,
      );
    }

    return status;
  }

  /// Re-fetch from backend (call after a successful purchase).
  Future<void> refresh() async {
    final auth = ref.read(authProvider);
    final fallbackUserPremium = auth.user?.isPremium == true;

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final status = await _subscriptionService.getStatusFromBackend();
      if (!status.isPremium && fallbackUserPremium) {
        return SubscriptionStatus(
          isPremium: true,
          planType: status.planType,
          planLabel: status.planLabel,
          startedAt: status.startedAt,
          expiresAt: status.expiresAt,
          isLifetime: status.isLifetime,
        );
      }
      return status;
    });
  }

  /// Purchase a RevenueCat package, then refresh.
  Future<bool> purchase(package) async {
    try {
      final success = await _subscriptionService.purchasePackage(package);
      if (success) await refresh();
      return success;
    } catch (_) {
      return false;
    }
  }

  /// Restore purchases, then refresh.
  Future<bool> restore() async {
    final success = await _subscriptionService.restorePurchases();
    if (success) await refresh();
    return success;
  }
}

final subscriptionProvider =
    AsyncNotifierProvider<SubscriptionStatusNotifier, SubscriptionStatus>(
  SubscriptionStatusNotifier.new,
);

/// Convenience provider - just the bool isPremium.
final isPremiumProvider = Provider<bool>((ref) {
  final auth = ref.watch(authProvider);
  final subscription = ref.watch(subscriptionProvider).valueOrNull;
  return subscription?.isPremium ?? auth.user?.isPremium ?? false;
});
