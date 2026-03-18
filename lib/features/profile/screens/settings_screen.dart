import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/notification_permission_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final NotificationPermissionService _notificationPermissionService =
      createNotificationPermissionService();

  NotificationPermissionState _notificationStatus =
      NotificationPermissionState.denied;
  bool _notificationLoading = false;
  bool _profileSaving = false;
  int _selectedTab = 0;
  String _appVersion = '';
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    NotificationPermissionState status = NotificationPermissionState.denied;
    String version = '1.0.0';
    String buildNumber = '1';

    try {
      status = await _notificationPermissionService.getStatus();
    } catch (_) {
      status = NotificationPermissionState.denied;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version.isNotEmpty ? info.version : version;
      buildNumber = info.buildNumber.isNotEmpty ? info.buildNumber : buildNumber;
    } catch (_) {}

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationStatus = status;
      _appVersion = '$version ($buildNumber)';
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authProvider).user;
    if (user != null && _nameController.text != user.name) {
      _nameController.text = user.name;
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (_notificationLoading) {
      return;
    }

    setState(() => _notificationLoading = true);

    NotificationPermissionState nextStatus = _notificationStatus;

    if (enable) {
      try {
        nextStatus = await _notificationPermissionService.requestPermission();
        if (nextStatus == NotificationPermissionState.permanentlyDenied) {
          await _notificationPermissionService.openSettings();
          nextStatus = await _notificationPermissionService.getStatus();
        }
      } catch (_) {
        nextStatus = NotificationPermissionState.denied;
      }
    } else {
      try {
        await _notificationPermissionService.openSettings();
        nextStatus = await _notificationPermissionService.getStatus();
      } catch (_) {
        nextStatus = NotificationPermissionState.denied;
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _notificationStatus = nextStatus;
      _notificationLoading = false;
    });

    switch (nextStatus) {
      case NotificationPermissionState.granted:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bildirimler artık açık.')),
        );
        break;
      case NotificationPermissionState.unsupported:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bu cihazda bildirim izni desteklenmiyor.'),
          ),
        );
        break;
      case NotificationPermissionState.denied:
      case NotificationPermissionState.permanentlyDenied:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Bildirim izni kapalı. İstersen tarayıcı veya sistem ayarlarından açabilirsin.',
            ),
          ),
        );
        break;
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sayfa açılamadı.')));
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authProvider).user;
    final name = _nameController.text.trim();

    if (user == null || name.isEmpty) {
      return;
    }

    setState(() => _profileSaving = true);
    final ok = await ref.read(authProvider.notifier).updateProfile(name: name);

    if (!mounted) {
      return;
    }

    setState(() => _profileSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profil bilgilerin güncellendi.' : 'Profil kaydedilemedi.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final notificationEnabled =
        _notificationStatus == NotificationPermissionState.granted;
    final notificationStatusLabel = switch (_notificationStatus) {
      NotificationPermissionState.granted => 'Açık',
      NotificationPermissionState.unsupported => 'Desteklenmiyor',
      NotificationPermissionState.permanentlyDenied => 'Ayarlar kapalı',
      NotificationPermissionState.denied => 'Kapalı',
    };
    final notificationDescription = switch (_notificationStatus) {
      NotificationPermissionState.granted =>
        'Günlük hedefin ve önemli güncellemeler için bildirim alıyorsun.',
      NotificationPermissionState.unsupported =>
        'Bu cihazda bildirim izni desteklenmiyor.',
      NotificationPermissionState.permanentlyDenied =>
        'İzin daha önce kapatılmış. Tek dokunuşla ayarlara gidip açabilirsin.',
      NotificationPermissionState.denied =>
        'Günlük hatırlatıcılar için bildirimi açabilirsin.',
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          _SettingsHeroCard(
            title: 'Okuma deneyimini kendine göre ayarla',
            subtitle:
                'Tema, yazı boyutu, günlük hedef ve bildirim tercihlerin burada.',
          ),
          const SizedBox(height: 20),
          _SettingsTabBar(
            selectedIndex: _selectedTab,
            onChanged: (index) => setState(() => _selectedTab = index),
          ),
          const SizedBox(height: 20),
          if (_selectedTab == 0) ...[
            _SectionLabel('Kişisel Bilgiler'),
            _SettingsCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _BlockHeader(
                    icon: Icons.person_outline_rounded,
                    title: 'Profil Bilgileri',
                    subtitle: 'Ad soyad bilgini buradan güncelleyebilirsin.',
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Ad Soyad',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    initialValue: user?.email ?? '',
                    enabled: false,
                    decoration: const InputDecoration(
                      labelText: 'E-posta Adresi',
                      prefixIcon: Icon(Icons.alternate_email_rounded),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'E-posta adresi şu an yalnızca görüntülenebilir. Güncelleme desteği yakında eklenebilir.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: textSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _profileSaving ? null : _saveProfile,
                      child: _profileSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Bilgileri Kaydet'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (_selectedTab == 1) ...[
          _SectionLabel('Görünüm'),
          _SettingsCard(
            child: Column(
              children: [
                const _BlockHeader(
                  icon: Icons.palette_outlined,
                  title: 'Tema',
                  subtitle: 'Uygulamanın genel görünümünü seç',
                ),
                const SizedBox(height: 16),
                ...[
                  ('system', 'Sistem', Icons.brightness_auto_rounded),
                  ('light', 'Açık', Icons.wb_sunny_rounded),
                  ('dark', 'Koyu', Icons.dark_mode_rounded),
                  ('sepia', 'Sepya', Icons.auto_awesome_rounded),
                ].map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _ThemeOptionTile(
                      label: item.$2,
                      icon: item.$3,
                      selected: settings.theme == item.$1,
                      onTap: () => notifier.setTheme(item.$1),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Okuma'),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _LeadingIcon(
                      icon: Icons.text_fields_rounded,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Font Boyutu',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Okuma ekranındaki yazı büyüklüğünü belirle.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        '${settings.fontSize}px',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 14)),
                    Expanded(
                      child: Slider(
                        value: settings.fontSize.toDouble(),
                        min: 12,
                        max: 22,
                        divisions: 5,
                        activeColor: AppColors.primary,
                        onChanged: (v) => notifier.setFontSize(v.round()),
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 24)),
                  ],
                ),
                Divider(
                  color: theme.colorScheme.outline.withOpacity(0.7),
                  height: 24,
                ),
                Row(
                  children: [
                    const _LeadingIcon(
                      icon: Icons.flag_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Günlük Hedef',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Günde kaç paragraf okumak istediğini seç.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [5, 10, 20, 30]
                      .map(
                        (goal) => _GoalChip(
                          label: '$goal paragraf',
                          selected: settings.dailyGoal == goal,
                          onTap: () => notifier.setDailyGoal(goal),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Bildirimler'),
          _SettingsCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const _LeadingIcon(
                      icon: Icons.notifications_active_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Günlük Hatırlatıcı',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            notificationDescription,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_notificationLoading)
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      Switch(
                        value: notificationEnabled,
                        activeColor: AppColors.primary,
                        onChanged: _toggleNotifications,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                _StatusPill(
                  label: notificationStatusLabel,
                  enabled: notificationEnabled,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ],
          _SectionLabel('Yasal'),
          _SettingsCard(
            child: Column(
              children: [
                _LinkTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Gizlilik Politikası',
                  color: const Color(0xFF4F8EF7),
                  onTap: () => _launchUrl(
                    'https://kitaplig.com/gizlilik-politikasi',
                  ),
                ),
                Divider(
                  color: theme.colorScheme.outline.withOpacity(0.7),
                  height: 1,
                ),
                _LinkTile(
                  icon: Icons.description_outlined,
                  title: 'Kullanım Koşulları',
                  color: const Color(0xFF4F8EF7),
                  onTap: () =>
                      _launchUrl('https://kitaplig.com/kullanim-kosullari'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _SectionLabel('Hakkında'),
          _SettingsCard(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline,
                  title: 'Uygulama Versiyonu',
                  trailing: Text(
                    _appVersion,
                    style: TextStyle(color: textSecondary, fontSize: 13),
                  ),
                ),
                Divider(
                  color: theme.colorScheme.outline.withOpacity(0.7),
                  height: 1,
                ),
                _LinkTile(
                  icon: Icons.email_outlined,
                  title: 'Geri Bildirim Gönder',
                  color: AppColors.primary,
                  onTap: () => _launchUrl(
                    'mailto:destek@kitaplig.com?subject=KitapLig%20Geri%20Bildirim',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              children: [
                Text(
                  'KitapLig',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2026 KitapLig. Tüm hakları saklıdır.',
                  style: TextStyle(fontSize: 11, color: textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            if (isDark) const Color(0xFF171A17) else const Color(0xFFF5F8F3),
            AppColors.primary.withOpacity(isDark ? 0.18 : 0.22),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.06)
              : theme.colorScheme.outline.withOpacity(0.8),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _SettingsTabBar extends StatelessWidget {
  const _SettingsTabBar({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = const ['Profil', 'Tercihler'];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
        ),
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final selected = index == selectedIndex;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: index == 0 ? 6 : 0),
              child: InkWell(
                onTap: () => onChanged(index),
                borderRadius: BorderRadius.circular(14),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.primary.withOpacity(0.16)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    items[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: selected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    super.key,
    this.child,
    this.color,
    this.children,
  });

  final Widget? child;
  final Color? color;
  final List<Widget>? children;

  @override
  Widget build(BuildContext context) {
    final effectiveChild =
        child ?? Column(mainAxisSize: MainAxisSize.min, children: children ?? []);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: effectiveChild,
    );
  }
}

class _BlockHeader extends StatelessWidget {
  const _BlockHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        _LeadingIcon(icon: icon, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.12)
              : isDark
              ? Colors.white.withOpacity(0.02)
              : theme.colorScheme.surfaceContainerHighest.withOpacity(0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.35)
                : theme.colorScheme.outline.withOpacity(isDark ? 0.5 : 0.75),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? AppColors.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Icon(icon, color: selected ? AppColors.primary : Colors.amber),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalChip extends StatelessWidget {
  const _GoalChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.75),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.enabled,
  });

  final String label;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.primary.withOpacity(0.14)
              : Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(999),
        ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: enabled
              ? AppColors.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _LinkTile extends StatelessWidget {
  const _LinkTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _LeadingIcon(icon: icon, color: color),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        Icons.open_in_new,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: onTap,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: _LeadingIcon(icon: icon, color: AppColors.primary),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      trailing: trailing,
    );
  }
}
