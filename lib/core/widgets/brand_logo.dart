import 'package:flutter/material.dart';

enum BrandLogoVariant { auto, dark, light, web }

class BrandLogo extends StatelessWidget {
  final BrandLogoVariant variant;
  final double height;
  final BoxFit fit;

  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.auto,
    this.height = 44,
    this.fit = BoxFit.contain,
  });

  String _assetPath(BuildContext context) {
    switch (variant) {
      case BrandLogoVariant.auto:
        return Theme.of(context).brightness == Brightness.dark
            ? 'assets/images/logo-dark.png'
            : 'assets/images/logo-white.png';
      case BrandLogoVariant.dark:
        return 'assets/images/logo-dark.png';
      case BrandLogoVariant.web:
        return 'assets/images/logo-web.png';
      case BrandLogoVariant.light:
        return 'assets/images/logo-white.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Image.asset(
        _assetPath(context),
        fit: fit,
      ),
    );
  }
}
