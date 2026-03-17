import 'package:flutter/material.dart';

enum BrandLogoVariant { dark, light, web }

class BrandLogo extends StatelessWidget {
  final BrandLogoVariant variant;
  final double height;
  final BoxFit fit;

  const BrandLogo({
    super.key,
    this.variant = BrandLogoVariant.light,
    this.height = 44,
    this.fit = BoxFit.contain,
  });

  String get _assetPath {
    switch (variant) {
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
        _assetPath,
        fit: fit,
      ),
    );
  }
}
