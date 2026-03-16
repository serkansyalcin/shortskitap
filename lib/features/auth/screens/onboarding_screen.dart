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
  final _controller = PageController();
  int _page = 0;
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
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await ref.read(settingsProvider.notifier).setDailyGoal(_selectedGoal);
    await ref.read(settingsProvider.notifier).completeOnboarding();
    if (mounted) context.go('/login');
  }

  void _next() {
    if (_page < 2) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  bool get _canNext {
    if (_page == 2) return _selectedCategories.length >= 2;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: i == _page ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: i == _page ? AppColors.primary : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )),
              ),
            ),

            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStep1(),
                  _buildStep2(),
                  _buildStep3(),
                ],
              ),
            ),

            // Next button
            Padding(
              padding: const EdgeInsets.all(24),
              child: ElevatedButton(
                onPressed: _canNext ? _next : null,
                child: Text(_page == 2 ? 'Başla 🚀' : 'Devam'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep1() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📱', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          const Text(
            'Kitapları farklı gör',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Her ekranda bir paragraf. Parmağınla yukarı kaydır, kitapları Instagram Reels gibi oku.',
            style: TextStyle(fontSize: 16, color: AppColors.lightTextSecondary, height: 1.6),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          // Mock phone animation
          Container(
            width: 140,
            height: 220,
            decoration: BoxDecoration(
              color: AppColors.darkBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.grey.shade300, width: 3),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '"Kitaplar insanların zihinlerinde gezindiği bahçelerdir."',
                  style: TextStyle(color: Colors.white70, fontSize: 9, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                Icon(Icons.keyboard_arrow_up, color: Colors.white54, size: 20),
                Text('kaydır', style: TextStyle(color: Colors.white38, fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎯', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 32),
          const Text(
            'Günlük hedefini belirle',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          const Text(
            'Her gün kaç paragraf okumak istiyorsun?',
            style: TextStyle(fontSize: 16, color: AppColors.lightTextSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: _goals.map((goal) => GestureDetector(
              onTap: () => setState(() => _selectedGoal = goal),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                decoration: BoxDecoration(
                  color: _selectedGoal == goal ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedGoal == goal ? AppColors.primary : Colors.grey.shade200,
                    width: 2,
                  ),
                  boxShadow: _selectedGoal == goal ? [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4)),
                  ] : [],
                ),
                child: Column(
                  children: [
                    Text(
                      '$goal',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _selectedGoal == goal ? Colors.white : AppColors.lightText,
                      ),
                    ),
                    Text(
                      'paragraf/gün',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectedGoal == goal ? Colors.white70 : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 16),
          const Text('❤️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          const Text(
            'İlgi alanlarını seç',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'En az 2 kategori seç',
            style: TextStyle(fontSize: 14, color: AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
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
                      borderRadius: BorderRadius.circular(40),
                      border: Border.all(
                        color: selected ? AppColors.primary : Colors.grey.shade200,
                      ),
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
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
