import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../platform/platform_support.dart';

class StoreListingService {
  const StoreListingService._();

  // Configure with --dart-define=APP_STORE_ID=1234567890 for reliable iOS fallback.
  static const String _iosAppStoreId = String.fromEnvironment('APP_STORE_ID');

  static Future<bool> open({
    required String packageName,
    bool writeReview = false,
  }) async {
    if (!PlatformSupport.isMobileNative) {
      return false;
    }

    final inAppReview = InAppReview.instance;
    try {
      await inAppReview.openStoreListing(
        appStoreId: PlatformSupport.isIOS && _iosAppStoreId.isNotEmpty
            ? _iosAppStoreId
            : null,
      );
      return true;
    } catch (_) {
      // Fall back to explicit store URLs below.
    }

    if (PlatformSupport.isAndroid) {
      final marketUri = Uri.parse('market://details?id=$packageName');
      if (await launchUrl(marketUri, mode: LaunchMode.externalApplication)) {
        return true;
      }

      final webUri = Uri.parse(
        'https://play.google.com/store/apps/details?id=$packageName',
      );
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) {
        return true;
      }

      return false;
    }

    if (_iosAppStoreId.isEmpty) {
      return false;
    }

    final reviewSuffix = writeReview ? '?action=write-review' : '';
    final nativeUri = Uri.parse(
      'itms-apps://itunes.apple.com/app/id$_iosAppStoreId$reviewSuffix',
    );
    if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) {
      return true;
    }

    final webUri = Uri.parse(
      'https://apps.apple.com/app/id$_iosAppStoreId$reviewSuffix',
    );
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }
}
