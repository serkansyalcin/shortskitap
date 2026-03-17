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
  final Set<String> _selectedCategories = <String>{};

  static const List<int> _goals = [5, 10, 20, 30];
  static const List<_InterestOption> _categories = [
    _InterestOption('Roman', Icons.auto_stories_rounded),
    _InterestOption('Psikoloji', Icons.psychology_alt_rounded),
    _InterestOption('Klasikler', Icons.castle_rounded),
    _InterestOption('Bilim Kurgu', Icons.rocket_launch_rounded),
    _InterestOption('Felsefe', Icons.lightbulb_outline_rounded),
    _InterestOption('Tarih', Icons.history_edu_rounded),
    _InterestOption('Kişisel Gelişim', Icons.spa_rounded),
    _InterestOption('Polisiye', Icons.search_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (mounted) {
        setState(() => _scrollOffset = _scrollController.offset);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _visibility(double sectionTop, double viewportHeight) {
    final visibleStart = sectionTop - viewportHeight * 0.62;
    final visibleEnd = sectionTop - viewportHeight * 0.18;
    if (_scrollOffset < visibleStart) return 0;
    if (_scrollOffset > visibleEnd) return 1;
    return ((_scrollOffset - visibleStart) / (visibleEnd - visibleStart)).clamp(
      0.0,
      1.0,
    );
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setTheme('light');
    await ref.read(settingsProvider.notifier).setDailyGoal(_selectedGoal);
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) {
      context.go('/home');
    }
  }

  bool get _canFinish => _selectedCategories.length >= 2;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewportHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          const _OnboardingBackdrop(),
          SafeArea(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    visibility: _visibility(0, viewportHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.spotifyPanelHigh.withValues(
                                alpha: 0.92,
                              ),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: AppColors.outline),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.auto_stories_rounded,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Kısa paragraflarla okuma alışkanlığı',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            width: 92,
                            height: 92,
                            decoration: BoxDecoration(
                              gradient: AppColors.brandGradient,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.34,
                                  ),
                                  blurRadius: 36,
                                  offset: const Offset(0, 18),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'KitapLig',
                            style: theme.textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightText,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Text(
                              'Kitapları paragraf paragraf oku, günlük hedefini tut, ligde arkadaşlarınla yarış.',
                              style: theme.textTheme.bodyLarge?.copyWith(
                                color: AppColors.lightTextSecondary,
                                height: 1.55,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    visibility: _visibility(250, viewportHeight),
                    alignLeft: true,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                      child: _FeatureCard(
                        eyebrow: 'OKUMA',
                        icon: Icons.swipe_up_alt_rounded,
                        title: 'Paragraf paragraf oku',
                        description:
                            'Her ekranda tek paragraf. Kaydır, oku, ilerle. Dikkat dağıtmadan odaklı okuma deneyimi.',
                        accentColor: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    visibility: _visibility(470, viewportHeight),
                    alignLeft: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                      child: _FeatureCard(
                        eyebrow: 'LİG',
                        icon: Icons.emoji_events_rounded,
                        title: 'Okudukça XP kazan, ligde yüksel',
                        description:
                            'Her paragraf sana puan kazandırır. Sezonluk liglerde arkadaşlarınla yarış, terfi et, motivasyonunu koru.',
                        accentColor: AppColors.accent,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    visibility: _visibility(720, viewportHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                      child: _SectionPanel(
                        icon: Icons.track_changes_rounded,
                        title: 'Günlük hedefini belirle',
                        subtitle:
                            'Her gün kaç paragraf okumayı hedefliyorsun? Okuma alışkanlığını bu hedefle güçlendir.',
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: _goals
                              .map(
                                (goal) => _GoalChip(
                                  goal: goal,
                                  selected: _selectedGoal == goal,
                                  onTap: () =>
                                      setState(() => _selectedGoal = goal),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _AnimatedSection(
                    visibility: _visibility(1010, viewportHeight),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
                      child: _SectionPanel(
                        icon: Icons.favorite_rounded,
                        title: 'İlgi alanlarını seç',
                        subtitle:
                            'En az iki kategori seç. Keşfet sayfasında sana uygun kitapları öne çıkaralım.',
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: _categories.map((category) {
                            final selected = _selectedCategories.contains(
                              category.name,
                            );
                            return _InterestChip(
                              label: category.name,
                              icon: category.icon,
                              selected: selected,
                              onTap: () {
                                setState(() {
                                  if (selected) {
                                    _selectedCategories.remove(category.name);
                                  } else {
                                    _selectedCategories.add(category.name);
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 34),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.spotifyPanel,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: AppColors.outline),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.30),
                            blurRadius: 32,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            _canFinish
                                ? 'Hazırsın! Okumaya başla.'
                                : 'Devam etmek için en az 2 kategori seç.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.lightTextSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: _canFinish ? _finish : null,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _canFinish ? 'Keşfetmeye Başla' : 'Kategori seç',
                                ),
                                if (_canFinish) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
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
      duration: const Duration(milliseconds: 120),
      child: Transform.translate(offset: Offset(dx, 0), child: child),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(gradient: AppColors.heroGradient),
          ),
          Positioned(
            top: -120,
            right: -40,
            child: _GlowBlob(
              size: 260,
              color: AppColors.primary.withValues(alpha: 0.30),
            ),
          ),
          Positioned(
            top: 300,
            left: -70,
            child: _GlowBlob(
              size: 220,
              color: AppColors.accent.withValues(alpha: 0.20),
            ),
          ),
          Positioned(
            bottom: -80,
            right: -20,
            child: _GlowBlob(
              size: 300,
              color: AppColors.primaryLight.withValues(alpha: 0.24),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowBlob({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final String eyebrow;
  final IconData icon;
  final String title;
  final String description;
  final Color accentColor;

  const _FeatureCard({
    required this.eyebrow,
    required this.icon,
    required this.title,
    required this.description,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.spotifyPanel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.34),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -36,
            right: -18,
            child: _GlowBlob(
              size: 140,
              color: accentColor.withValues(alpha: 0.28),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.34),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 30),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: accentColor,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.lightText,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightTextSecondary,
                        height: 1.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionPanel extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionPanel({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.spotifyPanel,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: AppColors.primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: AppColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.lightTextSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
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
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.spotifyPanelHigh,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.outline,
            width: 1.6,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.24),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$goal',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.black : AppColors.lightText,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'paragraf / gün',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.black87 : AppColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.spotifyPanelHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.black : AppColors.lightTextSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.black : AppColors.lightText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterestOption {
  final String name;
  final IconData icon;

  const _InterestOption(this.name, this.icon);
}
