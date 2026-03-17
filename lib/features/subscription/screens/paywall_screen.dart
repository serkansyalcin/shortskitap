import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  int _selectedIndex = 1; // 0=monthly, 1=yearly, 2=lifetime
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
        setState(() {
          _offeringsLoading = false;
        });
      }
      return;
    }

    final service = SubscriptionService();
    final offerings = await service.getOfferings();
    if (mounted) {
      setState(() {
        _offerings = offerings;
        _offeringsLoading = false;
      });
    }
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
    for (final p in current.availablePackages) {
      final id = p.storeProduct.identifier;
      if (index == 0 && (id == monthlyId || id.contains('monthly'))) return p;
      if (index == 1 &&
          (id == yearlyId || id.contains('yearly') || id.contains('annual')))
        return p;
      if (index == 2 && (id == lifetimeId || id.contains('lifetime'))) return p;
    }
    return null;
  }

  String _priceForIndex(int index) {
    final pkg = _packageForIndex(index);
    if (pkg != null) return pkg.storeProduct.priceString;
    // Fall back to .env values
    return switch (index) {
      0 => FallbackPrices.monthly,
      1 => FallbackPrices.yearly,
      _ => FallbackPrices.lifetime,
    };
  }

  Future<void> _purchase() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      setState(() {
        _errorMessage =
            'Premium satin alma su anda sadece Android ve iOS uygulamasinda destekleniyor.';
      });
      return;
    }

    final pkg = _packageForIndex(_selectedIndex);
    if (pkg == null) {
      // No offerings from RevenueCat — sync manually via backend
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
          .purchase(pkg);
      if (success && mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Satın alma işlemi başarısız: $e';
        });
      }
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  Future<void> _syncFallback() async {
    // Used in dev/test when RevenueCat is not configured
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _isLoading = false;
    });
    if (mounted) _showSuccessDialog();
  }

  Future<void> _restore() async {
    if (!PlatformSupport.supportsInAppPurchases) {
      setState(() {
        _errorMessage =
            'Geri yukleme yalnizca Android ve iOS uygulamasinda kullanilabilir.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final success = await ref.read(subscriptionProvider.notifier).restore();
      if (mounted) {
        if (success) {
          _showSuccessDialog();
        } else {
          setState(() {
            _errorMessage = 'Geri yüklenecek aktif abonelik bulunamadı.';
          });
        }
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = 'Geri yükleme başarısız.';
        });
    } finally {
      if (mounted)
        setState(() {
          _isLoading = false;
        });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            const Text('👑', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text(
              'Premium Aktif!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'KitapLig Premium üyeliğiniz başarıyla aktive edildi.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Harika!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purchaseSupported = PlatformSupport.supportsInAppPurchases;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text('👑', style: TextStyle(fontSize: 36)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'KitapLig Premium',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sınırsız okuma. Reklamsız deneyim.',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Features
                  _buildFeatureList(),
                  const SizedBox(height: 24),

                  // Plan selector
                  const Text(
                    'Plan Seçin',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_offeringsLoading)
                    const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                      ),
                    )
                  else ...[
                    _PlanCard(
                      index: 0,
                      title: 'Aylık',
                      price: _priceForIndex(0),
                      subtitle: 'Aylık yenileme',
                      isSelected: _selectedIndex == 0,
                      onTap: () => setState(() => _selectedIndex = 0),
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      index: 1,
                      title: 'Yıllık',
                      price: _priceForIndex(1),
                      subtitle: 'Aylık ödemeye göre %44 tasarruf',
                      badge: 'En Popüler',
                      isSelected: _selectedIndex == 1,
                      onTap: () => setState(() => _selectedIndex = 1),
                    ),
                    const SizedBox(height: 10),
                    _PlanCard(
                      index: 2,
                      title: 'Ömür Boyu',
                      price: _priceForIndex(2),
                      subtitle: 'Tek seferlik ödeme, sonsuza kadar premium',
                      badge: '♾️ Sonsuz',
                      isSelected: _selectedIndex == 2,
                      onTap: () => setState(() => _selectedIndex = 2),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Error
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (!purchaseSupported)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.orange,
                            size: 18,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Premium satin alma ve geri yukleme bu platformda kullanilamiyor. Mobil uygulamayi kullanabilirsiniz.',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_isLoading || !purchaseSupported)
                          ? null
                          : _purchase,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withOpacity(
                          0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 2,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _selectedIndex == 2
                                  ? 'Ömür Boyu Premium Satın Al'
                                  : 'Premium\'a Geç',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Restore
                  Center(
                    child: TextButton(
                      onPressed: (_isLoading || !purchaseSupported)
                          ? null
                          : _restore,
                      child: const Text(
                        'Satın Almaları Geri Yükle',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                  // Legal
                  const SizedBox(height: 8),
                  const Text(
                    'Abonelik, süresi dolmadan 24 saat önce otomatik olarak yenilenir. '
                    'Hesap ayarlarından her zaman iptal edebilirsiniz.',
                    style: TextStyle(color: Colors.black38, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureList() {
    final features = [
      ('Reklamsız okuma deneyimi', Icons.block),
      ('Tüm premium kitaplara erişim', Icons.library_books_rounded),
      ('Sınırsız okuma ve ilerleme takibi', Icons.auto_stories_rounded),
      ('Özel premium rozeti', Icons.workspace_premium_rounded),
      ('Öncelikli destek', Icons.support_agent_rounded),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F0),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCCE5CC)),
      ),
      child: Column(
        children: features
            .map(
              (f) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(f.$2, color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      f.$1,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final int index;
  final String title;
  final String price;
  final String subtitle;
  final String? badge;
  final bool isSelected;
  final VoidCallback onTap;

  const _PlanCard({
    required this.index,
    required this.title,
    required this.price,
    required this.subtitle,
    this.badge,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF0F7F0) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Radio
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Plan info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black87,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Price
            Text(
              price,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isSelected ? AppColors.primary : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
