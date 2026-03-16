import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Theme
          _SectionTitle('Tema'),
          ...['light', 'dark', 'sepia'].map((t) {
            final labels = {'light': '☀️ Açık', 'dark': '🌙 Koyu', 'sepia': '🍂 Sepya'};
            return RadioListTile<String>(
              title: Text(labels[t]!),
              value: t,
              groupValue: settings.theme,
              activeColor: AppColors.primary,
              onChanged: (v) => v != null ? notifier.setTheme(v) : null,
            );
          }),

          const SizedBox(height: 16),
          _SectionTitle('Font Boyutu'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                const Text('A', style: TextStyle(fontSize: 12)),
                Expanded(
                  child: Slider(
                    value: settings.fontSize.toDouble(),
                    min: 12,
                    max: 22,
                    divisions: 5,
                    label: '${settings.fontSize}px',
                    activeColor: AppColors.primary,
                    onChanged: (v) => notifier.setFontSize(v.round()),
                  ),
                ),
                const Text('A', style: TextStyle(fontSize: 22)),
              ],
            ),
          ),

          const SizedBox(height: 16),
          _SectionTitle('Günlük Hedef'),
          Wrap(
            spacing: 8,
            children: [5, 10, 20, 30].map((goal) => ChoiceChip(
              label: Text('$goal paragraf'),
              selected: settings.dailyGoal == goal,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: settings.dailyGoal == goal ? Colors.white : null,
              ),
              onSelected: (_) => notifier.setDailyGoal(goal),
            )).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.lightTextSecondary,
            letterSpacing: 0.5,
          ),
        ),
      );
}
