import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../app/providers/books_provider.dart';
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
  static const int _pageCount = 6;
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
    'Kişisel Gelişim',
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
    if (_currentPage < _pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  Future<void> _skip() async {
    final isAuthenticated = ref.read(authProvider).isAuthenticated;
    await _finish(
      navigateToRegister: !isAuthenticated,
      isAuthenticated: isAuthenticated,
    );
  }

  Future<void> _finish({
    required bool navigateToRegister,
    required bool isAuthenticated,
  }) async {
    setState(() => _isSubmitting = true);

    if (isAuthenticated) {
      try {
        await ApiClient.instance.put(
          '/me',
          data: {
            'daily_goal': _selectedGoal,
            'preferences': _selectedCategories.toList(),
          },
        );
        await ref.read(authProvider.notifier).refreshMe();
      } catch (_) {}
    }

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
      children: List.generate(_pageCount, (index) {
        final active = _currentPage == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: active ? 10 : 8,
          width: active ? 32 : 8,
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary
                : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
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
    final categoriesAsync = ref.watch(categoriesProvider);
    final onboardingCategories = categoriesAsync.maybeWhen(
      data: (categories) {
        final names = categories
            .map((category) => category.name.trim())
            .where((name) => name.isNotEmpty)
            .toList(growable: false);
        return names.isNotEmpty ? names : _categories;
      },
      orElse: () => _categories,
    );

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F172A)
          : const Color(0xFFF8FAFC),
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
                const Center(
                  child: BrandLogo(height: 52, trimRightPadding: true),
                ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (idx) => setState(() => _currentPage = idx),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _FeaturePage(
                        icon: Icons.auto_awesome_rounded,
                        title: 'Kısa ve Akıcı Okuma',
                        description:
                            'Yorucu sayfalar yerine kısa paragraflarla ritmini kaybetmeden oku ve odağını koru.',
                        accentColor: AppColors.primary,
                        isDark: isDark,
                      ),
                      _FeaturePage(
                        icon: Icons.headphones_rounded,
                        title: 'Dinle ve Çevrim Dışı Devam Et',
                        description:
                            'Sesli kitap ve indirme özellikleriyle hikâyene ister yolda ister internetsizken kaldığın yerden devam et.',
                        accentColor: Colors.blueAccent,
                        highlights: const [
                          'Sesli kitap ile dinleyerek takip et',
                          'İndir ve çevrim dışı oku',
                        ],
                        isDark: isDark,
                      ),
                      _FeaturePage(
                        icon: Icons.emoji_events_rounded,
                        title: 'Ligler ve Düellolar',
                        description:
                            'Okudukça puan topla, liglerde yüksel ve düellolarda diğer okurlarla yarış. Çocuk ve yetişkin profilleri kendi alanlarında ayrı ilerler.',
                        accentColor: Colors.amber.shade600,
                        highlights: const [
                          'Okudukça puan ve sıralama kazan',
                          'Düellolarda bire bir yarış',
                          'Çocuk ve yetişkin profilleri ayrı çalışır',
                        ],
                        isDark: isDark,
                      ),
                      _FeaturePage(
                        icon: Icons.family_restroom_rounded,
                        title: 'Çocuk Modu',
                        description:
                            'Çocuklara uygun içerikleri güvenli bir alanda sun. Ayrı profil oluştur, yetişkin alanına dönüşü şifreyle koru ve çocuk deneyimini ayrı tut.',
                        accentColor: Colors.pinkAccent,
                        highlights: const [
                          'Yaşa uygun güvenli içerik',
                          'Çocuk profilleri yetişkinlerden ayrı çalışır',
                          'Ligler ve düellolar profil tipine göre ayrılır',
                        ],
                        isDark: isDark,
                      ),
                      _FeaturePage(
                        icon: Icons.auto_stories_rounded,
                        title: 'AI ile Kendi Hikâyeni Yaz',
                        description:
                            'Başlığını ve temanı yaz, AI senin için özgün bir hikâye oluştursun. İstersen özel tut, istersen paylaş.',
                        accentColor: AppColors.accent,
                        isDark: isDark,
                        highlights: const [
                          'Başlık ve tema ile hızlı üretim',
                          'Sana özel veya paylaşılabilir hikâyeler',
                          'Çocuk profilleri için güvenli içerik',
                        ],
                      ),
                      _SetupPage(
                        goals: _goals,
                        categories: onboardingCategories,
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
                      if (_currentPage < _pageCount - 1)
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? Colors.white
                                  : Colors.black87,
                              foregroundColor: isDark
                                  ? Colors.black
                                  : Colors.white,
                              elevation: 10,
                              shadowColor:
                                  (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.3),
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
                                  shadowColor: AppColors.primary.withValues(
                                    alpha: 0.4,
                                  ),
                                  disabledBackgroundColor: isDark
                                      ? Colors.white10
                                      : Colors.grey.shade300,
                                  disabledForegroundColor: isDark
                                      ? Colors.white30
                                      : Colors.grey.shade500,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
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
                                  foregroundColor: isDark
                                      ? Colors.white70
                                      : Colors.black54,
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
                            else if (_currentPage == _pageCount - 1 &&
                                !_canFinish)
                              const SizedBox(height: 48),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_currentPage < _pageCount - 1)
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: TextButton(
                onPressed: _isSubmitting ? null : _skip,
                style: TextButton.styleFrom(
                  foregroundColor:
                      isDark ? Colors.white54 : const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'Atla',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeaturePage extends StatefulWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;
  final bool isDark;
  final List<String> highlights;

  const _FeaturePage({
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
    required this.isDark,
    this.highlights = const [],
  });

  @override
  State<_FeaturePage> createState() => _FeaturePageState();
}

class _FeaturePageState extends State<_FeaturePage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _floatController;
  late final Animation<double> _floatAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _floatAnim = Tween<double>(begin: -8.0, end: 8.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (context, child) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: child,
            ),
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: widget.isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white,
                shape: BoxShape.circle,
                boxShadow: widget.isDark
                    ? []
                    : [
                        BoxShadow(
                          color: widget.accentColor.withValues(alpha: 0.18),
                          blurRadius: 48,
                          offset: const Offset(0, 16),
                        ),
                      ],
                border: Border.all(
                  color: widget.accentColor.withValues(
                    alpha: widget.isDark ? 0.3 : 0.12,
                  ),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          widget.accentColor.withValues(alpha: 0.4),
                          widget.accentColor,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                  Icon(widget.icon, size: 52, color: Colors.white),
                ],
              ),
            ),
          ),
          const SizedBox(height: 48),
          Text(
            widget.title,
            style: TextStyle(
              color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            widget.description,
            style: TextStyle(
              color: widget.isDark
                  ? Colors.white70
                  : const Color(0xFF64748B),
              fontSize: 15,
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          if (widget.highlights.isNotEmpty) ...[
            const SizedBox(height: 24),
            for (final item in widget.highlights)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: widget.accentColor.withValues(
                      alpha: widget.isDark ? 0.28 : 0.15,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: widget.accentColor,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item,
                        style: TextStyle(
                          color: widget.isDark
                              ? Colors.white70
                              : const Color(0xFF334155),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _SetupPage extends StatefulWidget {
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
  State<_SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<_SetupPage> {
  static const int _collapsedCategoryCount = 8;

  bool _showAllCategories = false;

  List<String> get _visibleCategories {
    final categories = widget.categories;
    if (_showAllCategories || categories.length <= _collapsedCategoryCount) {
      return categories;
    }

    final visible = categories.take(_collapsedCategoryCount).toList();
    for (final selected in widget.selectedCategories) {
      if (categories.contains(selected) && !visible.contains(selected)) {
        visible.add(selected);
      }
    }
    return visible;
  }

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
              color: widget.isDark ? Colors.white : const Color(0xFF1E293B),
              letterSpacing: -1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Deneyiminizi en iyi hale getirelim.',
            style: TextStyle(
              color: widget.isDark ? Colors.white60 : const Color(0xFF64748B),
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
              color: widget.isDark ? Colors.white : const Color(0xFF334155),
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: widget.goals.map((goal) {
              final active = goal == widget.selectedGoal;
              return Expanded(
                child: GestureDetector(
                  onTap: () => widget.onGoalSelect(goal),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      color: active
                          ? AppColors.primary
                          : (widget.isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: active && !widget.isDark
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : (!widget.isDark
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.04,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : []),
                      border: Border.all(
                        color: active
                            ? Colors.transparent
                            : (widget.isDark
                                  ? Colors.white10
                                  : Colors.transparent),
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
                                : (widget.isDark
                                      ? Colors.white
                                      : const Color(0xFF1E293B)),
                          ),
                        ),
                        Text(
                          'prgf',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: active
                                ? Colors.white.withValues(alpha: 0.8)
                                : (widget.isDark
                                      ? Colors.white54
                                      : const Color(0xFF94A3B8)),
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
              color: widget.isDark ? Colors.white : const Color(0xFF334155),
              fontSize: 16,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.selectedCategories.isEmpty
                ? 'Lütfen en az 2 kategori seçin.'
                : '${widget.selectedCategories.length} tür seçildi. En az 2 seçim yeterli.',
            style: TextStyle(
              color: widget.isDark ? Colors.white54 : const Color(0xFF94A3B8),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: _visibleCategories.map((cat) {
              final active = widget.selectedCategories.contains(cat);
              final visual = CategoryVisuals.resolve(name: cat);
              return GestureDetector(
                onTap: () => widget.onCategoryToggle(cat),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: active
                        ? visual.accent
                        : (widget.isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white),
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: active && !widget.isDark
                        ? [
                            BoxShadow(
                              color: visual.accent.withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : (!widget.isDark
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : []),
                    border: Border.all(
                      color: active
                          ? Colors.transparent
                          : (widget.isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05)),
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
                            : (widget.isDark
                                  ? Colors.white60
                                  : const Color(0xFF64748B)),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        cat,
                        style: TextStyle(
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                          color: active
                              ? Colors.white
                              : (widget.isDark
                                    ? Colors.white70
                                    : const Color(0xFF334155)),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          if (widget.categories.length > _collapsedCategoryCount) ...[
            const SizedBox(height: 14),
            Center(
              child: TextButton.icon(
                onPressed: () {
                  setState(() => _showAllCategories = !_showAllCategories);
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                icon: Icon(
                  _showAllCategories
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
                label: Text(
                  _showAllCategories
                      ? 'Daha Az Göster'
                      : 'Daha Fazla Tür Göster (${widget.categories.length - _visibleCategories.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
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
      ..color = AppColors.primary.withValues(alpha: isDark ? 0.08 : 0.06)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);

    final paint2 = Paint()
      ..color = AppColors.accent.withValues(alpha: isDark ? 0.08 : 0.05)
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
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final path = Path();
    for (int i = 0; i < 6; i++) {
      final yProgress = i / 5;
      final yStart = size.height * yProgress;

      path.moveTo(0, yStart);
      path.cubicTo(
        size.width * 0.3,
        yStart +
            math.sin(animationValue * math.pi * 2 + i) *
                100 *
                (1 - pageOffset * 0.2),
        size.width * 0.7,
        yStart -
            math.cos(animationValue * math.pi * 2 + i) *
                100 *
                (1 - pageOffset * 0.2),
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
