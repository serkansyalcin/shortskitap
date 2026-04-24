import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_client.dart';
import '../platform/platform_support.dart';

class FeedbackService {
  final ApiClient _client = ApiClient.instance;

  Future<void> submit({
    required String type,
    required String message,
    int? rating,
  }) async {
    String? appVersion;
    try {
      final info = await PackageInfo.fromPlatform();
      appVersion = info.version;
    } catch (_) {
      appVersion = null;
    }

    await _client.post(
      '/feedback',
      data: {
        'type': type,
        'message': message,
        if (rating != null) 'rating': rating,
        'platform': PlatformSupport.platformName,
        if (appVersion != null) 'app_version': appVersion,
      },
    );
  }
}
