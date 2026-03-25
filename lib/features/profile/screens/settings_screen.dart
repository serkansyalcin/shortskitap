import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/providers/league_provider.dart';
import '../../../app/providers/profile_provider.dart';
import '../../../app/providers/settings_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/avatar_picker_service.dart';
import '../../../core/services/avatar_picker_types.dart';
import '../../../core/services/notification_permission_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _permissionService = createNotificationPermissionService();
  final _avatarPicker = createAvatarPickerService();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();

  NotificationPermissionState _notificationStatus =
      NotificationPermissionState.denied;
  bool _notificationLoading = false;
  bool _profileSaving = false;
  String _appVersion = '';
  Uint8List? _avatarBytes;
  String? _avatarFileName;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    try {
      _notificationStatus = await _permissionService.getStatus();
    } catch (_) {}

    try {
      final info = await PackageInfo.fromPlatform();
      _appVersion = '${info.version} (${info.buildNumber})';
    } catch (_) {
      _appVersion = '1.0.0';
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authProvider).user;
    if (user == null) return;
    if (_nameController.text != user.name) _nameController.text = user.name;
    if (_usernameController.text != user.username) {
      _usernameController.text = user.username;
    }
    if (_emailController.text != user.email) _emailController.text = user.email;
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authProvider).user;
    final previousUsername = user?.username;
    final username = _usernameController.text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    if (user == null ||
        _nameController.text.trim().isEmpty ||
        username.length < 3 ||
        _emailController.text.trim().isEmpty) {
      return;
    }

    setState(() => _profileSaving = true);
    final ok = await ref.read(authProvider.notifier).updateProfile(
      name: _nameController.text.trim(),
      username: username,
      email: _emailController.text.trim(),
      avatarBytes: _avatarBytes,
      avatarFileName: _avatarFileName,
    );
    if (!mounted) return;
    setState(() {
      _profileSaving = false;
      if (ok) {
        _avatarBytes = null;
        _avatarFileName = null;
      }
    });

    if (ok) {
      ref.invalidate(myLeagueProvider);
      ref.invalidate(leaderboardProvider);
      ref.invalidate(leagueHistoryProvider);
      if (previousUsername != null && previousUsername.isNotEmpty) {
        ref.invalidate(publicProfileProvider(previousUsername));
      }
      ref.invalidate(publicProfileProvider(username));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Profil bilgilerin güncellendi.' : 'Profil kaydedilemedi.',
        ),
      ),
    );
  }

  Future<void> _pickAvatarFromGallery() =>
      _pickAvatar(() => _avatarPicker.pickFromGallery());

  Future<void> _pickAvatarFromCamera() =>
      _pickAvatar(() => _avatarPicker.pickFromCamera());

  Future<void> _pickAvatar(
    Future<PickedAvatar?> Function() picker,
  ) async {
    try {
      final picked = await picker();
      if (picked == null || !mounted) return;

      setState(() {
        _avatarBytes = picked.bytes;
        _avatarFileName = picked.fileName;
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fotoğraf seçilirken bir hata oluştu.'),
        ),
      );
    }
  }

  Future<void> _showAvatarSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Profil fotoğrafı seç',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galeriden Seç'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickAvatarFromGallery();
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Kamerayla Çek'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await _pickAvatarFromCamera();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleNotifications(bool enabled) async {
    if (_notificationLoading) return;
    setState(() => _notificationLoading = true);
    try {
      _notificationStatus = enabled
          ? await _permissionService.requestPermission()
          : await _permissionService.getStatus();
      if (!enabled || _notificationStatus == NotificationPermissionState.permanentlyDenied) {
        await _permissionService.openSettings();
        _notificationStatus = await _permissionService.getStatus();
      }
    } catch (_) {
      _notificationStatus = NotificationPermissionState.denied;
    }
    if (!mounted) return;
    setState(() => _notificationLoading = false);
  }

  Future<void> _openUrl(String url) async {
    if (!await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault) &&
        mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Sayfa açılamadı.')));
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< HEAD
=======
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
>>>>>>> 407dc54a40ea07243180d48f8dc1e437549e519f
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final user = ref.watch(authProvider).user;
    final notificationEnabled =
        _notificationStatus == NotificationPermissionState.granted;
    final notificationText = switch (_notificationStatus) {
      NotificationPermissionState.granted =>
        'Günlük hedefin için bildirimler açık.',
      NotificationPermissionState.unsupported =>
        'Bu cihazda bildirim desteği yok.',
      NotificationPermissionState.permanentlyDenied =>
        'Bildirim izni sistem ayarlarında kapalı.',
      NotificationPermissionState.denied => 'Bildirimler şu an kapalı.',
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
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil ve tercihlerin',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user?.username.isNotEmpty == true
                      ? '@${user!.username}'
                      : 'Hesabını ve okuma deneyimini burada yönetebilirsin.',
                  style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil Bilgileri',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _AvatarPreview(
                      imageUrl: user?.avatarUrl,
                      imageBytes: _avatarBytes,
                      name: _nameController.text.isNotEmpty
                          ? _nameController.text
                          : (user?.name ?? ''),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Profil Fotoğrafı',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Galeri içinden seçtiğin görsel BunnyCDN üzerinde saklanır.',
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: _showAvatarSourceSheet,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: Text(
                              _avatarBytes != null
                                  ? 'Fotoğrafı Değiştir'
                                  : 'Fotoğraf Seç',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Ad Soyad'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _usernameController,
                  autocorrect: false,
                  decoration: const InputDecoration(labelText: 'Kullanıcı Adı'),
                ),
                const SizedBox(height: 8),
                Text(
                  'Küçük harf, rakam ve alt çizgi kullanabilirsin. Profil bağlantın bu alanla açılır.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'E-posta'),
                ),
                const SizedBox(height: 16),
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
          const SizedBox(height: 16),
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tema',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ('system', 'Sistem'),
                    ('light', 'Açık'),
                    ('dark', 'Koyu'),
                  ].map((item) {
                    final selected = settings.theme == item.$1;
                    return ChoiceChip(
                      label: Text(item.$2),
                      selected: selected,
                      onSelected: (_) => settingsNotifier.setTheme(item.$1),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Font Boyutu: ${settings.fontSize}px',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Slider(
                  value: settings.fontSize.toDouble(),
                  min: 12,
                  max: 22,
                  divisions: 5,
                  activeColor: AppColors.primary,
                  onChanged: (value) =>
                      settingsNotifier.setFontSize(value.round()),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Günlük Hedef',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [5, 10, 20, 30].map((goal) {
                    return ChoiceChip(
                      label: Text('$goal paragraf'),
                      selected: settings.dailyGoal == goal,
                      onSelected: (_) => settingsNotifier.setDailyGoal(goal),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _Card(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bildirimler',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notificationText,
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_notificationLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
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
          ),
          const SizedBox(height: 16),
          _Card(
            child: Column(
              children: [
                _LinkRow(
                  label: 'Gizlilik Politikası',
                  onTap: () =>
                      _openUrl('https://kitaplig.com/gizlilik-politikasi'),
                ),
                const Divider(),
                _LinkRow(
                  label: 'Kullanım Koşulları',
                  onTap: () =>
                      _openUrl('https://kitaplig.com/kullanim-kosullari'),
                ),
                const Divider(),
                _LinkRow(
                  label: 'Geri Bildirim Gönder',
                  onTap: () => _openUrl(
                    'mailto:serkan.syalcin@khotmail.com?subject=Kitaplig%20Geri%20Bildirim',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'Kitaplig • $_appVersion',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.7),
        ),
      ),
      child: child,
    );
  }
}

<<<<<<< HEAD
class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: const Icon(Icons.open_in_new_rounded, size: 18),
      onTap: onTap,
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.imageUrl,
    required this.imageBytes,
    required this.name,
  });
=======
class _BlockHeader extends StatelessWidget {
  const _BlockHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
});
>>>>>>> 407dc54a40ea07243180d48f8dc1e437549e519f

  final String? imageUrl;
  final Uint8List? imageBytes;
  final String name;

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    return Container(
      width: 84,
      height: 84,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageBytes != null
          ? Image.memory(imageBytes!, fit: BoxFit.cover)
          : imageUrl != null && imageUrl!.isNotEmpty
          ? Image.network(imageUrl!, fit: BoxFit.cover)
          : Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ),
    );
  }
}
