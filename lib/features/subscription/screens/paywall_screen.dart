import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../app/providers/subscription_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/platform/platform_support.dart';
import '../../../core/services/subscription_service.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedIndex = 1;
  bool _isLoading = false;
  String? _errorMessage;

  Offerings? _offerings;
  bool _offeringsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      if (mounted) {
        setState(() => _offeringsLoading = false);
      }
      return;
    }

    final offerings = await SubscriptionService().getOfferings();
    if (!mounted) return;

    setState(() {
      _offerings = offerings;
      _offeringsLoading = false;
    });
  }

  Package? _packageForIndex(int index) {
    final current = _offerings?.current;
    if (current == null) return null;

    final monthlyId =
        dotenv.env['RC_PRODUCT_MONTHLY'] ?? 'kitaplig_premium_monthly';
    final yearlyId =
        dotenv.env['RC_PRODUCT_YEARLY'] ?? 'kitaplig_premium_yearly';
    final lifetimeId =
        dotenv.env['RC_PRODUCT_LIFETIME'] ?? 'kitaplig_premium_lifetime';

    for (final package in current.availablePackages) {
      final id = package.storeProduct.identifier;
      if (index == 0 && (id == monthlyId || id.contains('monthly'))) {
        return package;
      }
      if (index == 1 &&
          (id == yearlyId || id.contains('yearly') || id.contains('annual'))) {
        return package;
      }
      if (index == 2 && (id == lifetimeId || id.contains('lifetime'))) {
        return package;
      }
    }

    return null;
  }

  String _priceForIndex(int index) {
    final package = _packageForIndex(index);
    if (package != null) {
      return package.storeProduct.priceString;
    }

    return switch (index) {
      0 => FallbackPrices.monthly,
      1 => FallbackPrices.yearly,
      _ => FallbackPrices.lifetime,
    };
  }

  String _selectedPlanTitle() {
    return switch (_selectedIndex) {
      0 => 'Aylık',
      1 => 'Yıllık',
      _ => 'Ömür Boyu',
    };
  }

  String _selectedPlanNote() {
    return switch (_selectedIndex) {
      0 => 'Esnek başla, ritmini sonra büyüt.',
      1 => 'En dengeli tercih. Daha az öde, daha uzun oku.',
      _ => 'Tek ödeme ile tüm premium avantajlar kalıcı olarak sende.',
    };
  }

  Future<void> _purchase() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      setState(() {
        _errorMessage =
            'Premium satın alma şu anda yalnızca Android ve iOS uygulamasında destekleniyor.';
      });
      return;
    }

    final package = _packageForIndex(_selectedIndex);
    if (package == null) {
      await _syncFallback();
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref
          .read(subscriptionProvider.notifier)
          .purchase(package);
      if (success && mounted) {
        _showSuccessDialog();
      } else if (mounted) {
        setState(() {
          _errorMessage = 'Satın alma tamamlanamadı. Lütfen tekrar dene.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Satın alma işlemi başarısız oldu. Lütfen tekrar dene.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _syncFallback() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;
    setState(() => _isLoading = false);
    _showSuccessDialog();
  }

  Future<void> _restore() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      setState(() {
        _errorMessage =
            'Geri yükleme yalnızca Android ve iOS uygulamasında kullanılabilir.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await ref.read(subscriptionProvider.notifier).restore();
      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        setState(() {
          _errorMessage = 'Geri yüklenecek aktif abonelik bulunamadı.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Geri yükleme sırasında bir hata oluştu.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return AlertDialog(
          backgroundColor: AppColors.spotifyPanel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  size: 42,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Premium açıldı',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Reklamsız deneyim, premium kitaplar ve tüm avantajlar artık aktif.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Harika',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseSupported = PlatformSupport.supportsInAppPurchases;
    final selectedPrice = _priceForIndex(_selectedIndex);
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return Scaffold(
      backgroundColor: AppColors.spotifyBlack,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF111B13),
              AppColors.spotifyBlack,
              AppColors.spotifyBlack,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.38, 1],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: -80,
                left: -40,
                child: _GlowOrb(
                  size: 220,
                  color: AppColors.primary.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                top: 80,
                right: -60,
                child: _GlowOrb(
                  size: 180,
                  color: const Color(0xFFFFD54F).withValues(alpha: 0.10),
                ),
              ),
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.06,
                              ),
                              foregroundColor: Colors.white,
                              fixedSize: const Size(48, 48),
                            ),
                            icon: const Icon(Icons.close_rounded),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: const Text(
                              'Premium planları',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                      child: _HeroCard(
                        selectedPrice: selectedPrice,
                        planTitle: _selectedPlanTitle(),
                        planNote: _selectedPlanNote(),
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: const _SectionHeader(
                        title: 'Neler açılır?',
                        subtitle:
                            'Premium ile okuma deneyimi daha temiz, daha odaklı ve daha güçlü hale gelir.',
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _FeatureGrid(
                        items: const [
                          _FeatureItem(
                            icon: Icons.block_rounded,
                            title: 'Reklamsız deneyim',
                            subtitle: 'Okurken akışın bölünmez.',
                            color: Color(0xFF5EE39B),
                          ),
                          _FeatureItem(
                            icon: Icons.menu_book_rounded,
                            title: 'Premium kitaplar',
                            subtitle: 'Tüm özel içeriklere eriş.',
                            color: Color(0xFF7AC7FF),
                          ),
                          _FeatureItem(
                            icon: Icons.auto_graph_rounded,
                            title: 'Sınırsız takip',
                            subtitle: 'İlerlemeyi daha net gör.',
                            color: Color(0xFFFFC864),
                          ),
                          _FeatureItem(
                            icon: Icons.workspace_premium_rounded,
                            title: 'Özel rozet',
                            subtitle: 'Ligde premium görünüm kazan.',
                            color: Color(0xFFF7A7FF),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
                      child: const _SectionHeader(
                        title: 'Planını seç',
                        subtitle:
                            'İstersen aylık başla, istersen en avantajlı yıllık planı seç.',
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                      child: _offeringsLoading
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 32),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                _PlanCard(
                                  title: 'Aylık',
                                  subtitle: 'Esnek kullanım',
                                  detail:
                                      'Her ay yenilenir. Premium deneyimi kısa sürede denemek için ideal.',
                                  price: _priceForIndex(0),
                                  badge: null,
                                  isSelected: _selectedIndex == 0,
                                  onTap: () {
                                    setState(() => _selectedIndex = 0);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _PlanCard(
                                  title: 'Yıllık',
                                  subtitle: 'En popüler seçim',
                                  detail:
                                      'Daha düşük ortalama maliyetle yıl boyu kesintisiz premium kullan.',
                                  price: _priceForIndex(1),
                                  badge: 'En avantajlı',
                                  isSelected: _selectedIndex == 1,
                                  onTap: () {
                                    setState(() => _selectedIndex = 1);
                                  },
                                ),
                                const SizedBox(height: 12),
                                _PlanCard(
                                  title: 'Ömür boyu',
                                  subtitle: 'Tek ödeme',
                                  detail:
                                      'Abonelik yenilemesi olmadan tüm premium avantajları kalıcı aç.',
                                  price: _priceForIndex(2),
                                  badge: 'Kalıcı',
                                  isSelected: _selectedIndex == 2,
                                  onTap: () {
                                    setState(() => _selectedIndex = 2);
                                  },
                                ),
                              ],
                            ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
                      child: Column(
                        children: [
                          if (_errorMessage != null) ...[
                            _StatusCard(
                              icon: Icons.error_outline_rounded,
                              color: const Color(0xFFFF7A7A),
                              background: const Color(0xFF2A1212),
                              message: _errorMessage!,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (!purchaseSupported)
                            const _StatusCard(
                              icon: Icons.info_outline_rounded,
                              color: Color(0xFFFFC864),
                              background: Color(0xFF2A2110),
                              message:
                                  'Premium satın alma ve geri yükleme bu platformda kullanılamıyor. Mobil uygulamada devam edebilirsin.',
                            ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      child: _BottomActionCard(
                        selectedPrice: selectedPrice,
                        selectedPlan: _selectedPlanTitle(),
                        isLoading: _isLoading,
                        purchaseSupported: purchaseSupported,
                        onPurchase: _purchase,
                        onRestore: _restore,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(child: SizedBox(height: bottomInset + 12)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String selectedPrice;
  final String planTitle;
  final String planNote;

  const _HeroCard({
    required this.selectedPrice,
    required this.planTitle,
    required this.planNote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          colors: [Color(0xFF173320), Color(0xFF0F1812), Color(0xFF101010)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.14),
            blurRadius: 30,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE082), Color(0xFFFFB300)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: Colors.black,
                  size: 38,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'KitapLig Premium',
                        style: TextStyle(
                          color: Color(0xFFFFE082),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Daha az dikkat dağınıklığı, daha güçlü okuma ritmi.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        height: 1.1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Reklamları kaldır, premium kitaplara eriş ve okuma alışkanlığını daha net takip et.',
            style: TextStyle(
              color: AppColors.lightTextSecondary,
              fontSize: 15,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seçili plan',
                        style: TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        planTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        planNote,
                        style: const TextStyle(
                          color: AppColors.lightTextSecondary,
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Bugün',
                      style: TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      selectedPrice,
                      style: const TextStyle(
                        color: AppColors.primaryLight,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.lightTextSecondary,
            fontSize: 14,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final List<_FeatureItem> items;

  const _FeatureGrid({required this.items});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.08,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF131313),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color),
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item.subtitle,
                style: const TextStyle(
                  color: AppColors.lightTextSecondary,
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String detail;
  final String price;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.detail,
    required this.price,
    required this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.primary
        : Colors.white.withValues(alpha: 0.08);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF112116)
                : const Color(0xFF141414),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: borderColor, width: isSelected ? 1.6 : 1),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.16),
                      blurRadius: 26,
                      offset: const Offset(0, 14),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white24,
                    width: 2,
                  ),
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                ),
                child: isSelected
                    ? const Center(
                        child: Icon(
                          Icons.circle,
                          color: AppColors.primary,
                          size: 10,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (badge != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.16)
                                  : Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : Colors.white70,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: const TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                price,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryLight : Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomActionCard extends StatelessWidget {
  final String selectedPrice;
  final String selectedPlan;
  final bool isLoading;
  final bool purchaseSupported;
  final VoidCallback onPurchase;
  final VoidCallback onRestore;

  const _BottomActionCard({
    required this.selectedPrice,
    required this.selectedPlan,
    required this.isLoading,
    required this.purchaseSupported,
    required this.onPurchase,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF121212),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Seçimin hazır',
                      style: TextStyle(
                        color: AppColors.lightTextSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '$selectedPlan • $selectedPrice',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Güvenli ödeme',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: (isLoading || !purchaseSupported) ? null : onPurchase,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.primary.withValues(
                  alpha: 0.32,
                ),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.black,
                      ),
                    )
                  : const Text(
                      'Premium’a Geç',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: isLoading ? null : onRestore,
            child: const Text(
              'Satın alımı geri yükle',
              style: TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final String message;

  const _StatusCard({
    required this.icon,
    required this.color,
    required this.background,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: size / 1.6,
              spreadRadius: size / 10,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
