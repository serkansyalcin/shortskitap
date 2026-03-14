import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ShortsKitapApp());
}

class ShortsKitapApp extends StatelessWidget {
  const ShortsKitapApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shorts Kitap',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const _AppLoader(),
    );
  }
}

class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  bool _showHome = false;

  @override
  Widget build(BuildContext context) {
    if (_showHome) {
      return const HomeScreen();
    }
    return SplashScreen(
      onDone: () => setState(() => _showHome = true),
    );
  }
}
