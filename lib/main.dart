import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart';
import 'app/providers/notification_provider.dart';
import 'app/routes/app_router.dart';
import 'app/theme/app_theme.dart';
import 'app/providers/settings_provider.dart';
import 'core/platform/platform_support.dart';
import 'core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  if (PlatformSupport.isMobileNative) {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  if (PlatformSupport.supportsMobileAds) {
    await MobileAds.instance.initialize();
  }

  if (PlatformSupport.isMobileNative) {
    // Ask push permission as part of cold-start flow.
    await PushNotificationService.instance.initialize();
  }

  runApp(const ProviderScope(child: KitapLigApp()));
}

class KitapLigApp extends ConsumerStatefulWidget {
  const KitapLigApp({super.key});

  @override
  ConsumerState<KitapLigApp> createState() => _KitapLigAppState();
}

class _KitapLigAppState extends ConsumerState<KitapLigApp> {
  @override
  void initState() {
    super.initState();

    if (PlatformSupport.isMobileNative) {
      unawaited(
        PushNotificationService.instance.initialize(
          onMessageReceived: () => refreshNotificationProvidersForWidget(ref),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    return MaterialApp.router(
      title: 'Kitaplig',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: switch (settings.theme) {
        'dark' => ThemeMode.dark,
        'system' => ThemeMode.system,
        _ => ThemeMode.light,
      },
      routerConfig: router,
      builder: (context, child) => child!,
    );
  }
}
