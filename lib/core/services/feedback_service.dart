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
        'platform': PlatformSupport.platformName,
        ...?_optionalField('rating', rating),
        ...?_optionalField('app_version', appVersion),
      },
    );
  }

  Map<String, dynamic>? _optionalField(String key, Object? value) {
    if (value == null) {
      return null;
    }

    return <String, dynamic>{key: value};
  }
}
