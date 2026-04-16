import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../api/api_client.dart';
import '../platform/platform_support.dart';

/// RevenueCat product identifiers are read from `.env` so they can be swapped
/// without recompiling the app.
class RcProductIds {
  static String get monthly =>
      dotenv.env['RC_PRODUCT_MONTHLY'] ?? 'kitaplig_premium_monthly';
  static String get yearly =>
      dotenv.env['RC_PRODUCT_YEARLY'] ?? 'kitaplig_premium_yearly';
  static String get lifetime =>
      dotenv.env['RC_PRODUCT_LIFETIME'] ?? 'kitaplig_premium_lifetime';
}

/// RevenueCat entitlement name (defined in RevenueCat > Entitlements).
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
  final DateTime? startedAt;
  final DateTime? expiresAt;
  final bool isLifetime;

  const SubscriptionStatus({
    required this.isPremium,
    this.planType,
    this.planLabel,
    this.startedAt,
    this.expiresAt,
    this.isLifetime = false,
  });

  const SubscriptionStatus.free()
    : isPremium = false,
      planType = null,
      planLabel = null,
      startedAt = null,
      expiresAt = null,
      isLifetime = false;

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    final sub = json['subscription'] as Map<String, dynamic>?;
    return SubscriptionStatus(
      isPremium: json['is_premium'] == true,
      planType: sub?['plan_type'] as String?,
      planLabel: sub?['plan_label'] as String?,
      startedAt: sub?['started_at'] != null
          ? DateTime.tryParse(sub!['started_at'] as String)
          : null,
      expiresAt: sub?['expires_at'] != null
          ? DateTime.tryParse(sub!['expires_at'] as String)
          : null,
      isLifetime: sub?['is_lifetime'] == true,
    );
  }
}

class SubscriptionService {
  static bool _configured = false;

  /// Configure RevenueCat without a user ID (for unauthenticated users).
  static Future<void> configureAnonymous() async {
    if (_configured) return;
    if (!PlatformSupport.supportsInAppPurchases) {
      debugPrint('[RC] In-app purchases not supported on this platform');
      return;
    }

    final apiKey = Platform.isAndroid
        ? dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? ''
        : dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[RC] API key not set, skipping anonymous RevenueCat init');
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);
    await Purchases.configure(PurchasesConfiguration(apiKey));
    _configured = true;
    debugPrint('[RC] Configured anonymously');
  }

  /// When the user logs in after an anonymous session, switch to their ID.
  static Future<void> switchUser(String userId) async {
    if (!PlatformSupport.supportsInAppPurchases) return;
    if (!_configured) {
      await configure(userId);
      return;
    }

    try {
      await Purchases.logIn(userId);
      debugPrint('[RC] Switched to user $userId');
    } catch (e) {
      debugPrint('[RC] switchUser error: $e');
    }
  }

  static Future<void> configure(String userId) async {
    if (!PlatformSupport.supportsInAppPurchases) {
      debugPrint('[RC] In-app purchases are not supported on this platform');
      return;
    }

    final apiKey = Platform.isAndroid
        ? dotenv.env['REVENUECAT_ANDROID_API_KEY'] ?? ''
        : dotenv.env['REVENUECAT_IOS_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      debugPrint('[RC] RevenueCat API key not set, skipping init');
      return;
    }

    await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.error);

    final config = PurchasesConfiguration(apiKey)..appUserID = userId;
    await Purchases.configure(config);
    _configured = true;
    debugPrint('[RC] Configured for user $userId');
  }

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

  /// Purchase a package and sync the resulting entitlement to the backend.
  Future<bool> purchase(Package package) async {
    if (!PlatformSupport.supportsInAppPurchases) {
      debugPrint('[RC] purchase skipped on unsupported platform');
      return false;
    }

    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      final info = result.customerInfo;
      await _syncWithBackend(info, purchasedPackage: package);
      return info.entitlements.active.containsKey(RcEntitlement.name);
    } on PurchasesErrorCode catch (e) {
      if (e == PurchasesErrorCode.purchaseCancelledError) {
        return false;
      }
      rethrow;
    } catch (e) {
      debugPrint('[RC] purchase error: $e');
      rethrow;
    }
  }

  /// Restore purchases without creating a synthetic revenue entry.
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

  Future<void> _syncWithBackend(
    CustomerInfo info, {
    Package? purchasedPackage,
  }) async {
    try {
      final active = info.entitlements.active[RcEntitlement.name];
      if (active == null) return;

      String planType = 'monthly';
      final productId = active.productIdentifier;
      if (productId.contains('yearly') || productId.contains('annual')) {
        planType = 'yearly';
      } else if (productId.contains('lifetime')) {
        planType = 'lifetime';
      }

      final currentAppUserId = await Purchases.appUserID;
      final purchaseDate = DateTime.tryParse(active.latestPurchaseDate);
      final package = purchasedPackage;

      await ApiClient.instance.post<dynamic>(
        '/subscription/sync',
        data: {
          'revenuecat_customer_id': info.originalAppUserId,
          'revenuecat_app_user_id': currentAppUserId,
          'revenuecat_original_app_user_id': info.originalAppUserId,
          'plan_type': planType,
          'product_id': productId,
          'store': _mapStore(active.store),
          'expires_at': active.expirationDate,
          'purchase_date': purchaseDate?.toIso8601String(),
          'amount': package?.storeProduct.price,
          'currency': package?.storeProduct.currencyCode,
          'payment_reference': package == null
              ? null
              : _buildPaymentReference(
                  appUserId: currentAppUserId,
                  productId: productId,
                  purchaseDate: purchaseDate,
                  amount: package.storeProduct.price,
                ),
        },
      );
    } catch (e) {
      debugPrint('[RC] _syncWithBackend error: $e');
    }
  }

  Future<bool> hasPremiumEntitlement() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      return false;
    }

    try {
      final info = await Purchases.getCustomerInfo();
      return info.entitlements.active.containsKey(RcEntitlement.name);
    } catch (_) {
      return false;
    }
  }

  String _buildPaymentReference({
    required String appUserId,
    required String productId,
    required DateTime? purchaseDate,
    required double amount,
  }) {
    final purchaseKey = purchaseDate?.toUtc().toIso8601String() ?? 'unknown';
    return 'sync:$appUserId:$productId:$purchaseKey:${amount.toStringAsFixed(2)}';
  }

  String? _mapStore(Store store) {
    switch (store) {
      case Store.appStore:
        return 'app_store';
      case Store.playStore:
        return 'play_store';
      default:
        return null;
    }
  }
}
