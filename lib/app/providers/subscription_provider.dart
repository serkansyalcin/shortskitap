import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/subscription_service.dart';
import 'auth_provider.dart';

final _subscriptionService = SubscriptionService();

/// Holds the subscription status fetched from the backend.
/// Automatically initialised when auth state changes.
class SubscriptionStatusNotifier
    extends AsyncNotifier<SubscriptionStatus> {
  @override
  Future<SubscriptionStatus> build() async {
    // Watch auth state — re-run when user logs in/out
    final auth = ref.watch(authProvider);
    if (!auth.isAuthenticated || auth.user == null) {
      return const SubscriptionStatus.free();
    }

    // Configure RevenueCat with the user's ID on first build
    await SubscriptionService.configure(auth.user!.id.toString());

    return _subscriptionService.getStatusFromBackend();
  }

  /// Re-fetch from backend (call after a successful purchase).
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _subscriptionService.getStatusFromBackend(),
    );
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

/// Convenience provider — just the bool isPremium
final isPremiumProvider = Provider<bool>((ref) {
  return ref.watch(subscriptionProvider).valueOrNull?.isPremium ?? false;
});
