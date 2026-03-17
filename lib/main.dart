import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/providers/settings_provider.dart';
import 'core/platform/platform_support.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // sqflite web desteği — Flutter web'de databaseFactory gerekli
  if (kIsWeb) {
    databaseFactory = databaseFactoryFfiWeb;
  }

  // Force portrait orientation for reading app
  if (PlatformSupport.supportsOrientationLock) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  await dotenv.load(fileName: '.env');

  // Initialize Google Mobile Ads SDK
  if (PlatformSupport.supportsMobileAds) {
    await MobileAds.instance.initialize();
  }

  // Request notification permission on first launch (non-blocking)
  _requestNotificationPermission();

  runApp(const ProviderScope(child: KitapLigApp()));
}

Future<void> _requestNotificationPermission() async {
  if (!PlatformSupport.supportsNotificationPermission) {
    return;
  }

  final status = await Permission.notification.status;
  if (status.isDenied) {
    await Permission.notification.request();
  }
}

class KitapLigApp extends ConsumerWidget {
  const KitapLigApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'KitapLig',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.theme) {
        'dark' => ThemeMode.dark,
        'sepia' => ThemeMode.light,
        _ => ThemeMode.light,
      },
      routerConfig: router,
      builder: (context, child) {
        // Apply sepia overlay for sepia theme
        if (settings.theme == 'sepia') {
          return ColorFiltered(
            colorFilter: const ColorFilter.matrix([
              0.89,
              0.09,
              0.02,
              0,
              0,
              0.60,
              0.52,
              0.08,
              0,
              0,
              0.22,
              0.18,
              0.10,
              0,
              0,
              0,
              0,
              0,
              1,
              0,
            ]),
            child: child!,
          );
        }
        return child!;
      },
    );
  }
}
