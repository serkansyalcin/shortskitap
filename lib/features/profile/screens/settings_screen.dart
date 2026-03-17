import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/platform/platform_support.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  PermissionStatus _notificationStatus = PermissionStatus.denied;
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final status = PlatformSupport.supportsNotificationPermission
        ? await Permission.notification.status
        : PermissionStatus.denied;
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _notificationStatus = status;
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    }
  }

  Future<void> _toggleNotifications(bool enable) async {
    if (!PlatformSupport.supportsNotificationPermission) {
      return;
    }

    if (enable) {
      final status = await Permission.notification.request();
      if (status.isPermanentlyDenied) openAppSettings();
      if (mounted) setState(() => _notificationStatus = status);
    } else {
      await openAppSettings();
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sayfa açılamadı.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final cardBg = theme.cardColor;
    final textSecondary = theme.colorScheme.onSurfaceVariant;
    final notificationsSupported =
        PlatformSupport.supportsNotificationPermission;

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
          // ─── Görünüm ───────────────────────────────────────────
          AppUI.sectionTitle(context, 'GÖRÜNÜM'),
          _SettingsCard(
            color: cardBg,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Tema',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
              ...['light', 'dark', 'sepia'].map((t) {
                final labels = {
                  'light': '☀️  Açık',
                  'dark': '🌙  Koyu',
                  'sepia': '🍂  Sepya',
                };
                return RadioListTile<String>(
                  title: Text(labels[t]!),
                  value: t,
                  groupValue: settings.theme,
                  activeColor: AppColors.primary,
                  dense: true,
                  onChanged: (v) => v != null ? notifier.setTheme(v) : null,
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Okuma ─────────────────────────────────────────────
          AppUI.sectionTitle(context, 'OKUMA'),
          _SettingsCard(
            color: cardBg,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.text_fields,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Font Boyutu',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${settings.fontSize}px',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
                        activeColor: AppColors.primary,
                        onChanged: (v) => notifier.setFontSize(v.round()),
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 22)),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Günlük Hedef',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: Wrap(
                  spacing: 8,
                  children: [5, 10, 20, 30]
                      .map(
                        (goal) => ChoiceChip(
                          label: Text('$goal paragraf'),
                          selected: settings.dailyGoal == goal,
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: settings.dailyGoal == goal
                                ? Colors.white
                                : theme.colorScheme.onSurface,
                            fontWeight: settings.dailyGoal == goal
                                ? FontWeight.w600
                                : null,
                          ),
                          onSelected: (_) => notifier.setDailyGoal(goal),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Bildirimler ────────────────────────────────────────
          AppUI.sectionTitle(context, 'BİLDİRİMLER'),
          _SettingsCard(
            color: cardBg,
            children: [
              SwitchListTile(
                secondary: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Günlük Hatırlatıcı',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                subtitle: Text(
                  _notificationStatus.isGranted
                      ? 'Bildirimler açık'
                      : 'Okuma hedefin için günlük bildirim al',
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
                value: _notificationStatus.isGranted,
                activeColor: AppColors.primary,
                onChanged: notificationsSupported ? _toggleNotifications : null,
              ),
              if (!_notificationStatus.isGranted && notificationsSupported) ...[
                const Divider(height: 1, indent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bildirimler kapalı. Açmak için izin gereklidir.',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.error,
                          ),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: notificationsSupported
                            ? () async {
                                final status = await Permission.notification
                                    .request();
                                if (status.isPermanentlyDenied)
                                  openAppSettings();
                                if (mounted)
                                  setState(() => _notificationStatus = status);
                              }
                            : null,
                        child: const Text(
                          'İzin Ver',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 20),

          // ─── Yasal ─────────────────────────────────────────────
          AppUI.sectionTitle(context, 'YASAL'),
          _SettingsCard(
            color: cardBg,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.privacy_tip_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Gizlilik Politikası',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: textSecondary,
                ),
                onTap: () => _launchUrl('https://kitaplig.com/privacy'),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Kullanım Koşulları',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: textSecondary,
                ),
                onTap: () => _launchUrl('https://kitaplig.com/terms'),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ─── Hakkında ───────────────────────────────────────────
          AppUI.sectionTitle(context, 'HAKKINDA'),
          _SettingsCard(
            color: cardBg,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.info_outline,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Uygulama Versiyonu',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Text(
                  _appVersion,
                  style: TextStyle(color: textSecondary, fontSize: 13),
                ),
              ),
              const Divider(height: 1, indent: 56),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.email_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Geri Bildirim Gönder',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                trailing: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: textSecondary,
                ),
                onTap: () => _launchUrl(
                  'mailto:destek@kitaplig.com?subject=KitapLig%20Geri%20Bildirim',
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // ─── Footer ─────────────────────────────────────────────
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
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Color color;
  final List<Widget> children;
  const _SettingsCard({required this.color, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}
