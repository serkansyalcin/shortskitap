import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Latest connectivity snapshot from the platform.
final connectivityProvider = StreamProvider<List<ConnectivityResult>>((
  ref,
) async* {
  if (kIsWeb) {
    yield const [ConnectivityResult.wifi];
    return;
  }
  final plugin = Connectivity();
  try {
    yield await plugin.checkConnectivity();
  } catch (_) {
    yield const [ConnectivityResult.none];
  }
  await for (final event in plugin.onConnectivityChanged) {
    yield event;
  }
});

/// True when the device reports no usable network (mobile native only).
final isDeviceOfflineProvider = Provider<bool>((ref) {
  if (kIsWeb) return false;
  return ref
      .watch(connectivityProvider)
      .maybeWhen(
        data: (results) =>
            results.isEmpty ||
            results.every((r) => r == ConnectivityResult.none),
        orElse: () => false,
      );
});

bool connectivityListOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}
