import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _scrollController = ScrollController();
  double _scrollOffset = 0;
  int _selectedGoal = 10;
  final List<String> _selectedCategories = [];

  final _goals = [5, 10, 20, 30];
  final _categories = [
    {'name': 'Roman', 'icon': '📖'},
    {'name': 'Psikoloji', 'icon': '🧠'},
    {'name': 'Klasikler', 'icon': '🏛️'},
    {'name': 'Bilim Kurgu', 'icon': '🚀'},
    {'name': 'Felsefe', 'icon': '💭'},
    {'name': 'Tarih', 'icon': '📜'},
    {'name': 'Kişisel Gelişim', 'icon': '🌱'},
    {'name': 'Polisiye', 'icon': '🔍'},
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) setState(() => _scrollOffset = _scrollController.offset);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _visibility(double sectionTop, double viewportHeight) {
    final visibleStart = sectionTop - viewportHeight * 0.6;
    final visibleEnd = sectionTop - viewportHeight * 0.2;
    if (_scrollOffset < visibleStart) return 0;
    if (_scrollOffset > visibleEnd) return 1;
    return ((_scrollOffset - visibleStart) / (visibleEnd - visibleStart)).clamp(0.0, 1.0);
  }

  double _slideOffset(double visibility) => 30 * (1 - visibility);

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setDailyGoal(_selectedGoal);
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/login');
  }

  bool get _canFinish => _selectedCategories.length >= 2;

  @override
  Widget build(BuildContext context) {
    final viewportHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // --- KitapLig Header ---
            SliverToBoxAdapter(
              child: _AnimatedSection(
                visibility: _visibility(0, viewportHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          gradient: AppColors.brandGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Center(child: Text('📖', style: TextStyle(fontSize: 36))),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'KitapLig',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.8,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Kitap okumayı yeniden keşfet',
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.lightTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- Shorts Format Card (Sol hizalı) ---
            SliverToBoxAdapter(
              child: _AnimatedSection(
                visibility: _visibility(320, viewportHeight),
                alignLeft: true,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 36, 12),
                  child: _FeatureCard(
                    icon: '📱',
                    title: 'Shorts Formatı',
                    description: 'Her ekranda bir paragraf. Parmağınla yukarı kaydır, kitapları Reels gibi oku. Kısa ve odaklı.',
                    gradient: [AppColors.primary, AppColors.primaryLight],
                    isLeft: true,
                  ),
                ),
              ),
            ),

            // --- League Card (Sağ hizalı) ---
            SliverToBoxAdapter(
              child: _AnimatedSection(
                visibility: _visibility(520, viewportHeight),
                alignLeft: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(36, 12, 20, 12),
                  child: _FeatureCard(
                    icon: '🏆',
                    title: 'Lig Sistemi',
                    description: 'Arkadaşlarınla yarış, sezonluk liglerde terfi et. Okuduğun her paragraf XP kazandırır!',
                    gradient: [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
                    isLeft: false,
                  ),
                ),
              ),
            ),

            // --- Günlük Hedef ---
            SliverToBoxAdapter(
              child: _AnimatedSection(
                visibility: _visibility(720, viewportHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('🎯', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      const Text(
                        'Günlük hedefini belirle',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Her gün kaç paragraf okumak istiyorsun?',
                        style: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 20),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _goals.map((goal) => _GoalChip(
                          goal: goal,
                          selected: _selectedGoal == goal,
                          onTap: () => setState(() => _selectedGoal = goal),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // --- İlgi Alanları ---
            SliverToBoxAdapter(
              child: _AnimatedSection(
                visibility: _visibility(950, viewportHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('❤️', style: TextStyle(fontSize: 36)),
                      const SizedBox(height: 12),
                      const Text(
                        'İlgi alanlarını seç',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'En az 2 kategori seç',
                        style: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _categories.map((cat) {
                          final selected = _selectedCategories.contains(cat['name']);
                          return GestureDetector(
                            onTap: () => setState(() {
                              if (selected) {
                                _selectedCategories.remove(cat['name']);
                              } else {
                                _selectedCategories.add(cat['name']!);
                              }
                            }),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: selected ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: selected ? AppColors.primary : Colors.grey.shade200,
                                  width: 1.5,
                                ),
                                boxShadow: selected ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ] : [],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(cat['icon']!, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    cat['name']!,
                                    style: TextStyle(
                                      color: selected ? Colors.white : AppColors.lightText,
                                      fontWeight: FontWeight.w600,
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
                ),
              ),
            ),

            // --- Başla Butonu ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _canFinish ? _finish : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: _canFinish ? 4 : 0,
                      shadowColor: AppColors.primary.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_canFinish ? 'Başla' : 'En az 2 kategori seç'),
                        if (_canFinish) ...[
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_rounded, size: 20),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedSection extends StatelessWidget {
  final double visibility;
  final Widget child;
  final bool? alignLeft;

  const _AnimatedSection({
    required this.visibility,
    required this.child,
    this.alignLeft,
  });

  @override
  Widget build(BuildContext context) {
    final slide = 40 * (1 - visibility);
    final opacity = visibility.clamp(0.0, 1.0);
    final dx = alignLeft == true ? -slide : (alignLeft == false ? slide : 0.0);

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 100),
      child: Transform.translate(
        offset: Offset(dx, 0),
        child: child,
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final List<Color> gradient;
  final bool isLeft;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
    required this.isLeft,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: isLeft ? Alignment.topLeft : Alignment.topRight,
          end: isLeft ? Alignment.bottomRight : Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          if (!isLeft) const Spacer(flex: 1),
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (isLeft) const Spacer(flex: 1),
        ],
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  final int goal;
  final bool selected;
  final VoidCallback onTap;

  const _GoalChip({
    required this.goal,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.grey.shade200,
            width: 2,
          ),
          boxShadow: selected ? [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ] : [],
        ),
        child: Column(
          children: [
            Text(
              '$goal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: selected ? Colors.white : AppColors.lightText,
              ),
            ),
            Text(
              'paragraf/gün',
              style: TextStyle(
                fontSize: 12,
                color: selected ? Colors.white70 : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
