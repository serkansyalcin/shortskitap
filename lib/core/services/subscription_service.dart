import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../api/api_client.dart';
import '../platform/platform_support.dart';

/// RevenueCat product identifiers — read from .env so you can swap without
/// recompiling. Falls back to hardcoded strings if key is missing.
class RcProductIds {
  static String get monthly =>
      dotenv.env['RC_PRODUCT_MONTHLY'] ?? 'kitaplig_premium_monthly';
  static String get yearly =>
      dotenv.env['RC_PRODUCT_YEARLY'] ?? 'kitaplig_premium_yearly';
  static String get lifetime =>
      dotenv.env['RC_PRODUCT_LIFETIME'] ?? 'kitaplig_premium_lifetime';
}

/// RevenueCat entitlement name (defined in RC dashboard > Entitlements).
class RcEntitlement {
  static String get name => dotenv.env['RC_ENTITLEMENT'] ?? 'premium';
}

/// Fallback prices shown while RevenueCat offerings load or on error.
class FallbackPrices {
  static String get monthly => dotenv.env['PRICE_MONTHLY'] ?? '₺14,99';
  static String get yearly => dotenv.env['PRICE_YEARLY'] ?? '₺99,99';
  static String get lifetime => dotenv.env['PRICE_LIFETIME'] ?? '₺299,99';
}

class SubscriptionStatus {
  final bool isPremium;
  final String? planType;
  final String? planLabel;
  final DateTime? expiresAt;
  final bool isLifetime;

  const SubscriptionStatus({
    required this.isPremium,
    this.planType,
    this.planLabel,
    this.expiresAt,
    this.isLifetime = false,
  });

  const SubscriptionStatus.free()
    : isPremium = false,
      planType = null,
      planLabel = null,
      expiresAt = null,
      isLifetime = false;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>?;
    return SubscriptionStatus(
      isPremium: json['is_premium'] == true,
      planType: sub?['plan_type'] as String?,
      planLabel: sub?['plan_label'] as String?,
      expiresAt: sub?['expires_at'] != null
          ? DateTime.tryParse(sub!['expires_at'] as String)
          : null,
      isLifetime: sub?['is_lifetime'] == true,
    );
  }
}

class SubscriptionService {
  /// Call this once on app start (after user is identified).
  static Future<void> configure(String userId) async {
    if (!PlatformSupport.supportsInAppPurchases) {
      debugPrint('[RC] In-app purchases are not supported on this platform');
      return;
    }

    final apiKey = dotenv.env['REVENUECAT_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[RC] REVENUECAT_API_KEY not set — skipping RevenueCat init');
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);
    debugPrint('[RC] Configured for user $userId');
  }

  /// Fetch offerings from RevenueCat.
  Future<Offerings?> getOfferings() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      return null;
    }

    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[RC] getOfferings error: $e');
      return null;
    }
  }

  /// Purchase a package. Returns true on success.
  Future<bool> purchasePackage(Package package) async {
    if (!PlatformSupport.supportsInAppPurchases) {
      debugPrint('[RC] purchasePackage skipped on unsupported platform');
      return false;
    }

    try {
      final result = await Purchases.purchasePackage(package);
      final info = result.customerInfo;
      await _syncWithBackend(info);
      return info.entitlements.active.containsKey(RcEntitlement.name);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    } catch (e) {
      debugPrint('[RC] purchasePackage error: $e');
      rethrow;
    }
  }

  /// Restore purchases (e.g. on a new device).
  Future<bool> restorePurchases() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      debugPrint('[RC] restorePurchases skipped on unsupported platform');
      return false;
    }

    try {
      final info = await Purchases.restorePurchases();
      await _syncWithBackend(info);
      return info.entitlements.active.containsKey(RcEntitlement.name);
    } catch (e) {
      debugPrint('[RC] restorePurchases error: $e');
      return false;
    }
  }

  /// Fetch subscription status from backend.
  Future<SubscriptionStatus> getStatusFromBackend() async {
    try {
      final res = await ApiClient.instance.get<Map<String, dynamic>>(
        '/subscription/status',
      );
      if (res.data != null) {
        return SubscriptionStatus.fromJson(res.data!);
      }
    } catch (e) {
      debugPrint('[RC] getStatusFromBackend error: $e');
    }
    return const SubscriptionStatus.free();
  }

  /// After a successful purchase, notify the backend to update the user record.
  Future<void> _syncWithBackend(CustomerInfo info) async {
    try {
      final active = info.entitlements.active['premium'];
      if (active == null) return;

      String planType = 'monthly';
      final productId = active.productIdentifier;
      if (productId.contains('yearly') || productId.contains('annual')) {
        planType = 'yearly';
      } else if (productId.contains('lifetime')) {
        planType = 'lifetime';
      }

      await ApiClient.instance.post<dynamic>(
        '/subscription/sync',
        data: {
          'revenuecat_customer_id': info.originalAppUserId,
          'plan_type': planType,
          'expires_at': active.expirationDate,
        },
      );
    } catch (e) {
      debugPrint('[RC] _syncWithBackend error: $e');
    }
  }

  /// Check if the user currently has an active "premium" entitlement locally.
  Future<bool> hasPremiumEntitlement() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      return false;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(RcEntitlement.name);
    } catch (e) {
      return false;
    }
  }
}
