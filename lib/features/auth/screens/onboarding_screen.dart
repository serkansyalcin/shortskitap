import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/widgets/category_visuals.dart';

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
    final visibleStart = sectionTop - viewportHeight * 0.72;
    final visibleEnd = sectionTop - viewportHeight * 0.22;
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
    if (mounted) context.go('/home');
  }

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
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                  sliver: SliverList.list(
                    children: [
                      _AnimatedSection(
                        visibility: _visibility(0, viewportHeight),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.06),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Text(
                                  '3 adımda sana uygun bir başlangıç',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: AppColors.lightTextSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 26),
                            const Center(
                              child: BrandLogo(
                                variant: BrandLogoVariant.light,
                                height: 74,
                              ),
                            ),
                            const SizedBox(height: 24),
                            _HeroPanel(selectedGoal: _selectedGoal),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      _AnimatedSection(
                        visibility: _visibility(360, viewportHeight),
                        alignLeft: true,
                        child: const _FeatureCard(
                          eyebrow: 'KISA VE AKICI',
                          icon: Icons.swipe_up_alt_rounded,
                          title: 'Her kaydırışta okumaya devam et',
                          description:
                              'Uzun ve yorucu sayfalar yerine, odaklanamna yardımcı olacak kısa paragraflarla ritmini kaybetmeden ilerle.',
                          accentColor: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedSection(
                        visibility: _visibility(560, viewportHeight),
                        alignLeft: false,
                        child: const _FeatureCard(
                          eyebrow: 'MOTİVASYON',
                          icon: Icons.emoji_events_rounded,
                          title: 'Hedef koy, istikrar kazan, ligde yüksel',
                          description:
                              'Günlük hedefini korudukça okuma alışkanlığın güçlenir. Lig sistemi seni oyunda tutar.',
                          accentColor: AppColors.accent,
                        ),
                      ),
                      const SizedBox(height: 18),
                      _AnimatedSection(
                        visibility: _visibility(820, viewportHeight),
                        child: _SectionPanel(
                          icon: Icons.track_changes_rounded,
                          title: 'Günlük hedefini seç',
                          subtitle:
                              'Sana uygun tempoyu belirle. İstersen bunu daha sonra ayarlardan değiştirebilirsin.',
                          child: _GoalSelector(
                            goals: _goals,
                            selectedGoal: _selectedGoal,
                            onSelect: (goal) =>
                                setState(() => _selectedGoal = goal),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _AnimatedSection(
                        visibility: _visibility(1120, viewportHeight),
                        child: _SectionPanel(
                          icon: Icons.favorite_rounded,
                          title: 'İlgi alanlarını seç',
                          subtitle:
                              'En az iki kategori seç. Kesfet ekranında sana daha uygun kitapları öne çıkaralım.',
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _categories.map((category) {
                              final selected = _selectedCategories.contains(
                                category,
                              );
                              return _InterestChip(
                                label: category,
                                selected: selected,
                                onTap: () {
                                  setState(() {
                                    if (selected) {
                                      _selectedCategories.remove(category);
                                    } else {
                                      _selectedCategories.add(category);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      _AnimatedSection(
                        visibility: _visibility(1460, viewportHeight),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.spotifyPanel,
                            borderRadius: BorderRadius.circular(28),
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
                            children: [
                              Text(
                                'Kitap okumayı sevdiren Lig',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  color: AppColors.lightText,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _canFinish
                                    ? 'Başlangıcın hazır. Şimdi sana uygun kitapları keşfetmeye geçebilirsin.'
                                    : 'Devam etmek için en az 2 kategori seç.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.lightTextSecondary,
                                  height: 1.55,
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
                                      _canFinish
                                          ? 'Keşfetmeye Başla'
                                          : 'Kategori seç',
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
    final slide = 36 * (1 - visibility);
    final opacity = visibility.clamp(0.0, 1.0);
    final dy = 20 * (1 - visibility);
    final dx = alignLeft == true ? -slide : (alignLeft == false ? slide : 0.0);

    return AnimatedOpacity(
      opacity: opacity,
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      child: Transform.translate(offset: Offset(dx, dy), child: child),
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
            right: -50,
            child: _GlowBlob(
              size: 280,
              color: AppColors.primary.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            top: 420,
            left: -90,
            child: _GlowBlob(
              size: 220,
              color: AppColors.accent.withValues(alpha: 0.14),
            ),
          ),
          Positioned(
            bottom: -140,
            right: -20,
            child: _GlowBlob(
              size: 300,
              color: AppColors.accentSoft.withValues(alpha: 0.12),
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

class _HeroPanel extends StatelessWidget {
  final int selectedGoal;

  const _HeroPanel({required this.selectedGoal});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.spotifyPanel.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Kitap okumayı sevdiren Lig',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.lightText,
              height: 1.08,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Kısa paragraflarla okumaya daha kolay başla, ritmini koru ve lig motivasyonuyla istikrar kazan.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.lightTextSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Her paragraf yeni bir adım',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.lightText,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Dikkatini dağıtmayan kısa paragraflarla okumak daha hafif hissettirir ve günlük alışkanlık kurmayı kolaylaştıır.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.lightTextSecondary,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppColors.brandGradient,
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.24),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department_rounded,
                          size: 18,
                          color: Colors.black,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$selectedGoal paragraf hedefi',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
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
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.spotifyPanel,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: accentColor.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, size: 30, color: accentColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eyebrow,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.lightText,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 8),
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
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 28,
            offset: const Offset(0, 16),
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
                        height: 1.55,
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

class _GoalSelector extends StatelessWidget {
  final List<int> goals;
  final int selectedGoal;
  final ValueChanged<int> onSelect;

  const _GoalSelector({
    required this.goals,
    required this.selectedGoal,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - 12) / 2;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: goals
              .map(
                (goal) => SizedBox(
                  width: itemWidth,
                  child: _GoalChip(
                    goal: goal,
                    selected: selectedGoal == goal,
                    onTap: () => onSelect(goal),
                  ),
                ),
              )
              .toList(),
        );
      },
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
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: const BoxConstraints(minHeight: 96),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.brandGradient : null,
            color: selected ? null : AppColors.spotifyPanelHigh,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? AppColors.primaryLight : AppColors.outline,
              width: selected ? 1.6 : 1.2,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.24),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$goal',
                style: theme.textTheme.displayMedium?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.black : AppColors.lightText,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'paragraf',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: selected ? Colors.black87 : AppColors.lightText,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '/ gun',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected
                      ? Colors.black87
                      : AppColors.lightTextSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final visual = CategoryVisuals.resolve(name: label);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? visual.tint : AppColors.spotifyPanelHigh,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? visual.accent : AppColors.outline,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: selected
                    ? visual.accent.withValues(alpha: 0.18)
                    : visual.tint,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(
                visual.icon,
                size: 18,
                color: selected ? visual.accent : AppColors.lightText,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.lightText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
