import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/providers/auth_provider.dart';
import '../../../core/api/api_client.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/category_visuals.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  final _pageController = PageController();
  late final AnimationController _bgAnimationController;
  int _currentPage = 0;
  bool _isSubmitting = false;

  int _selectedGoal = 10;
  final Set<String> _selectedCategories = <String>{};

  static const List<int> _goals = [5, 10, 20, 30];
  static const List<String> _categories = [
    'Roman',
    'Psikoloji',
    'Klasikler',
    'Bilim Kurgu',
    'Felsefe',
    'Tarih',
    'Kisisel Gelisim',
    'Polisiye',
  ];

  bool get _canFinish => _selectedCategories.length >= 2;

  @override
  void initState() {
    super.initState();
    _bgAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimationController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<void> _finish({
    required bool navigateToRegister,
    required bool isAuthenticated,
  }) async {
    setState(() => _isSubmitting = true);

    if (isAuthenticated) {
      try {
        await ApiClient.instance.put('/me', data: {
          'daily_goal': _selectedGoal,
          'preferences': _selectedCategories.toList(),
        });
        await ref.read(authProvider.notifier).refreshMe();
      } catch (_) {}
    }

    // Kurulum tamamlandı bilgisini hem cihaza hem de memory'deki state'e yazıyoruz.
    // app_router artık Provider olarak settings'i izlemediği için (sadece redirect anında read ile okuyor)
    // state'in güncellenmesi yönlendiriciyi çökertmeyecek, ancak bir sonraki sayfa geçişine izin verecektir.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('daily_goal', _selectedGoal);
    await prefs.setStringList('onboarding_prefs', _selectedCategories.toList());
    await ref.read(settingsProvider.notifier).completeOnboarding();
    await ref.read(settingsProvider.notifier).setTheme('system');

    if (mounted) {
      if (!isAuthenticated && navigateToRegister) {
        context.go('/register');
      } else {
        context.go('/home');
      }
    }
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final active = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: active ? 10 : 8,
          width: active ? 32 : 8,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : Colors.grey.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isAuthenticated = ref.watch(authProvider).isAuthenticated;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Hareketli modern arka plan
          AnimatedBuilder(
            animation: _bgAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ModernBackgroundPainter(
                  animationValue: _bgAnimationController.value,
                  pageOffset: _currentPage.toDouble(),
                  isDark: isDark,
                ),
                child: Container(),
              );
            },
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 24),
                const BrandLogo(height: 42),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _FeaturePage(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Kısa ve Akıcı\nOkuma',
                        description:
                            'Yorucu sayfalar yerine odaklanmanı sağlayan kısa paragraflarla ritmini kaybetmeden ilerle.',
                        accentColor: AppColors.primary,
                        isDark: isDark,
                      ),
                      _FeaturePage(
                        icon: Icons.headphones_rounded,
                        title: 'Duyarak Hisset,\nDinleyerek Yaşa',
                        description:
                            'Kitapları sadece okumakla kalma, yüksek kaliteli sesli kitap özelliği ile yoldayken de hikayenin içinde kal.',
                        accentColor: Colors.deepPurpleAccent,
                        isDark: isDark,
                      ),
                      _FeaturePage(
                        icon: Icons.cloud_download_rounded,
                        title: 'Sınırları Kaldır,\nÇevrim Dışı Oku',
                        description:
                            'İnternet bağlantın olmadığında bile indirdiğin eserleri her yerde keyifle okumaya devam et.',
                        accentColor: Colors.blueAccent,
                        isDark: isDark,
                      ),
                      _FeaturePage(
                        icon: Icons.emoji_events_rounded,
                        title: 'Lig Sistemi ile\nYarış',
                        description:
                            'Okudukça puan topla, liglerde yükselerek diğer okurlarla mücadele et ve sürpriz kilitleri aç.',
                        accentColor: Colors.amber.shade600,
                        isDark: isDark,
                      ),
                      _SetupPage(
                        goals: _goals,
                        categories: _categories,
                        selectedGoal: _selectedGoal,
                        selectedCategories: _selectedCategories,
                        onGoalSelect: (g) => setState(() => _selectedGoal = g),
                        onCategoryToggle: (c) {
                          setState(() {
                            if (_selectedCategories.contains(c)) {
                              _selectedCategories.remove(c);
                            } else {
                              _selectedCategories.add(c);
                            }
                          });
                        },
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDotIndicator(),
                      const SizedBox(height: 36),
                      if (_currentPage < 4)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : Colors.black87,
                              foregroundColor: isDark ? Colors.black : Colors.white,
                              elevation: 10,
                              shadowColor: (isDark ? Colors.white : Colors.black).withOpacity(0.3),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: const Text(
                              'Keşfetmeye Devam Et',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        )
                      else
                        Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              height: 60,
                              child: ElevatedButton(
                                onPressed: _canFinish
                                    ? () => _finish(
                                          navigateToRegister: !isAuthenticated,
                                          isAuthenticated: isAuthenticated,
                                        )
                                    : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  elevation: _canFinish ? 12 : 0,
                                  shadowColor: AppColors.primary.withOpacity(0.4),
                                  disabledBackgroundColor:
                                      isDark ? Colors.white10 : Colors.grey.shade300,
                                  disabledForegroundColor:
                                      isDark ? Colors.white30 : Colors.grey.shade500,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        _canFinish
                                            ? (isAuthenticated
                                                ? 'Maceraya Başla'
                                                : 'Kayıt Ol ve Başla')
                                            : 'Kategori Seçin',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (_canFinish && !isAuthenticated)
                              TextButton(
                                onPressed: () => _finish(
                                  navigateToRegister: false,
                                  isAuthenticated: isAuthenticated,
                                ),
                                style: TextButton.styleFrom(
                                  foregroundColor:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                                child: const Text(
                                  'Kayıt Olmadan Devam Et',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              )
                            else if (_currentPage == 4 && !_canFinish)
                              const SizedBox(height: 48),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final bool isDark;

  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              shape: BoxShape.circle,
              boxShadow: isDark
                  ? []
                  : [
                      BoxShadow(
                        color: accentColor.withOpacity(0.15),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      )
                    ],
              border: Border.all(
                color: accentColor.withOpacity(isDark ? 0.3 : 0.1),
                width: 2,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned(
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [accentColor.withOpacity(0.4), accentColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
                Icon(icon, size: 52, color: Colors.white),
              ],
            ),
          ),
          const SizedBox(height: 64),
          Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
              fontSize: 16,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SetupPage extends StatelessWidget {
  final List<int> goals;
  final List<String> categories;
  final int selectedGoal;
  final Set<String> selectedCategories;
  final ValueChanged<int> onGoalSelect;
  final ValueChanged<String> onCategoryToggle;
  final bool isDark;

  const _SetupPage({
    required this.goals,
    required this.categories,
    required this.selectedGoal,
    required this.selectedCategories,
    required this.onGoalSelect,
    required this.onCategoryToggle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Son Ayarlar',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Deneyiminizi en iyi hale getirelim.',
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF64748B),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          Text(
            'Günlük Okuma Hedefi',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF334155),
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: goals.map((goal) {
              final active = goal == selectedGoal;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onGoalSelect(goal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: active && !isDark
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              )
                            ]
                          : (!isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : []),
                      border: Border.all(
                        color: active
                            ? Colors.transparent
                            : (isDark ? Colors.white10 : Colors.transparent),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$goal',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: active
                                ? Colors.white
                                : (isDark ? Colors.white : const Color(0xFF1E293B)),
                          ),
                        ),
                        Text(
                          'prgf',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white.withOpacity(0.8)
                                : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 48),
          Text(
            'İlgi Duyduğunuz Türler',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF334155),
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Lütfen en az 2 kategori seçin.',
            style: TextStyle(
              color: isDark ? Colors.white54 : const Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: categories.map((cat) {
              final active = selectedCategories.contains(cat);
              final visual = CategoryVisuals.resolve(name: cat);
              return GestureDetector(
                onTap: () => onCategoryToggle(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: active
                        ? visual.accent
                        : (isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: active && !isDark
                        ? [
                            BoxShadow(
                              color: visual.accent.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : (!isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : []),
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        visual.icon,
                        size: 18,
                        color: active
                            ? Colors.white
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat,
                        style: TextStyle(
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          color: active
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _ModernBackgroundPainter extends CustomPainter {
  final double animationValue;
  final double pageOffset;
  final bool isDark;

  _ModernBackgroundPainter({
    required this.animationValue,
    required this.pageOffset,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawAbstractBlobs(canvas, size);
    _drawMeshLines(canvas, size);
  }

  void _drawAbstractBlobs(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = AppColors.primary.withOpacity(isDark ? 0.08 : 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final paint2 = Paint()
      ..color = AppColors.accent.withOpacity(isDark ? 0.08 : 0.05)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    final offset1 = Offset(
      size.width * 0.2 + math.sin(animationValue * 2 * math.pi) * 80,
      size.height * 0.3 + math.cos(animationValue * 2 * math.pi) * 60,
    );
    canvas.drawCircle(offset1, 250, paint1);

    final offset2 = Offset(
      size.width * 0.8 + math.cos(animationValue * 2 * math.pi) * 100,
      size.height * 0.8 + math.sin(animationValue * 2 * math.pi) * 80,
    );
    canvas.drawCircle(offset2, 300, paint2);
  }

  void _drawMeshLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final yProgress = i / 5;
      final yStart = size.height * yProgress;

      path.moveTo(0, yStart);
      path.cubicTo(
        size.width * 0.3,
        yStart + math.sin(animationValue * math.pi * 2 + i) * 100 * (1 - pageOffset * 0.2),
        size.width * 0.7,
        yStart - math.cos(animationValue * math.pi * 2 + i) * 100 * (1 - pageOffset * 0.2),
        size.width,
        yStart,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ModernBackgroundPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.pageOffset != pageOffset ||
        oldDelegate.isDark != isDark;
  }
}
