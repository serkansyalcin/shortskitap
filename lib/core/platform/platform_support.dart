import 'package:flutter/foundation.dart';

class PlatformSupport {
  const PlatformSupport._();

  static bool get isAndroid =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static bool get isIOS =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static bool get isMobileNative => isAndroid || isIOS;

  static bool get supportsOrientationLock => isMobileNative;

  static bool get supportsImmersiveUi => isMobileNative;

  static bool get supportsNotificationPermission => isMobileNative;

  static bool get supportsMobileAds => isMobileNative;

  static bool get supportsInAppPurchases => isMobileNative;
}
