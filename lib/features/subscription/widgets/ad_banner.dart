import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers/subscription_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/models/advertisement_model.dart';
import '../../../core/platform/platform_support.dart';

/// Returns the correct AdMob banner ad unit ID for the current platform.
/// Reads from .env: ADMOB_BANNER_ANDROID / ADMOB_BANNER_IOS.
String get _bannerAdUnitId {
  if (PlatformSupport.isAndroid) {
    return dotenv.env['ADMOB_BANNER_ANDROID'] ??
        'ca-app-pub-3940256099942544/6300978111';
  }
  return dotenv.env['ADMOB_BANNER_IOS'] ??
      'ca-app-pub-3940256099942544/2934735716';
}

bool get _supportsAdMobBanner => PlatformSupport.supportsMobileAds;

/// Provides active ads for a given position from the backend.
final _adsProvider = FutureProvider.family<List<AdvertisementModel>, String>((
  ref,
  position,
) async {
  try {
    final res = await ApiClient.instance.get<Map<String, dynamic>>(
      '/ads/active',
      params: {'position': position},
    );
    final data = (res.data?['data'] as List<dynamic>?) ?? [];
    return data
        .map((e) => AdvertisementModel.fromJson(e as Map<String, dynamic>))
        .toList();
  } catch (_) {
    return [];
  }
});

final _adMobBannerProvider = FutureProvider.family<BannerAd?, String>((
  ref,
  position,
) async {
  if (!_supportsAdMobBanner) return null;

  final completer = Completer<BannerAd?>();
  BannerAd? bannerAd;

  bannerAd = BannerAd(
    adUnitId: _bannerAdUnitId,
    size: AdSize.banner,
    request: const AdRequest(),
    listener: BannerAdListener(
      onAdLoaded: (ad) {
        if (!completer.isCompleted) {
          completer.complete(ad is BannerAd ? ad : bannerAd);
        }
      },
      onAdFailedToLoad: (ad, _) {
        ad.dispose();
        bannerAd = null;
        if (!completer.isCompleted) {
          completer.complete(null);
        }
      },
    ),
  )..load();

  ref.onDispose(() {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
    bannerAd?.dispose();
  });

  return completer.future;
});

Future<void> warmUpAdBanner({
  required WidgetRef ref,
  required BuildContext context,
  String position = 'reader_banner',
}) async {
  if (ref.read(isPremiumProvider)) return;

  final ads = await ref.read(_adsProvider(position).future);
  if (ads.isNotEmpty) {
    final imageUrl = ads.first.imageUrl;
    if (imageUrl != null && imageUrl.isNotEmpty && context.mounted) {
      await precacheImage(CachedNetworkImageProvider(imageUrl), context);
    }
    return;
  }

  await ref.read(_adMobBannerProvider(position).future);
}

/// AdMob banner (test ID by default; replace with real IDs in production).
class _AdMobBanner extends ConsumerWidget {
  final String position;

  const _AdMobBanner({required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_supportsAdMobBanner) return const SizedBox.shrink();

    final bannerAsync = ref.watch(_adMobBannerProvider(position));
    return bannerAsync.when(
      data: (bannerAd) {
        if (bannerAd == null) return const SizedBox.shrink();
        return SizedBox(
          width: bannerAd.size.width.toDouble(),
          height: bannerAd.size.height.toDouble(),
          child: AdWidget(ad: bannerAd),
        );
      },
      loading: () => const SizedBox(height: 56),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

/// Main widget — shows custom API ads for non-premium users.
/// Falls back to AdMob if no API ads are available.
class AdBannerWidget extends ConsumerWidget {
  final String position;

  const AdBannerWidget({super.key, this.position = 'reader_banner'});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(isPremiumProvider);
    if (isPremium) return const SizedBox.shrink();

    final adsAsync = ref.watch(_adsProvider(position));

    return adsAsync.when(
      data: (ads) {
        if (ads.isEmpty) {
          return _AdMobBanner(position: position);
        }
        final ad = ads.first;
        return _ApiAdBanner(ad: ad);
      },
      loading: () => const SizedBox(height: 56),
      error: (_, stackTrace) => _AdMobBanner(position: position),
    );
  }
}

class _ApiAdBanner extends StatelessWidget {
  final AdvertisementModel ad;

  const _ApiAdBanner({required this.ad});

  Future<void> _onClick() async {
    // Track click
    try {
      await ApiClient.instance.post<dynamic>('/ads/${ad.id}/click');
    } catch (_) {}

    // Open link
    if (ad.linkUrl != null) {
      final uri = Uri.tryParse(ad.linkUrl!);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onClick,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        height: 72,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (ad.imageUrl != null)
              CachedNetworkImage(imageUrl: ad.imageUrl!, fit: BoxFit.cover)
            else
              Center(
                child: Text(
                  ad.title,
                  style: const TextStyle(fontSize: 13, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            // "Reklam" label
            Positioned(
              top: 4,
              right: 6,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black45,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Reklam',
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
