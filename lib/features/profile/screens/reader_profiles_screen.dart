import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/theme/app_ui.dart';
import '../../../core/models/reader_profile_model.dart';
import '../../../core/widgets/reader_profile_avatar.dart';
import '../widgets/reader_profile_dialogs.dart';
import '../widgets/reader_profiles_section.dart';

class ReaderProfilesScreen extends ConsumerStatefulWidget {
  const ReaderProfilesScreen({super.key});

  @override
  ConsumerState<ReaderProfilesScreen> createState() =>
      _ReaderProfilesScreenState();
}

class _ReaderProfilesScreenState extends ConsumerState<ReaderProfilesScreen> {
  void _showMessage(String message, {Color? backgroundColor}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: backgroundColor),
    );
  }

  void _showAuthError({required String fallback, Color? backgroundColor}) {
    final message = ref.read(authProvider).error ?? fallback;
    _showMessage(message, backgroundColor: backgroundColor);
  }

  String _suggestedAvatarUrl(AuthState auth, {ReaderProfileModel? profile}) {
    final currentValue = profile?.avatarUrl;
    if (currentValue != null && currentValue.trim().isNotEmpty) {
      return currentValue;
    }

    if (profile != null && profile.isChild) {
      return ReaderProfileAvatarCatalog.suggestedTokenValue(index: profile.id);
    }

    return ReaderProfileAvatarCatalog.tokenValueAt(
      auth.profileCapabilities.activeChildProfilesCount,
    );
  }

  Future<void> _openChildProfileForm({ReaderProfileModel? profile}) async {
    final auth = ref.read(authProvider);
    final formResult = await ReaderProfileDialogs.showChildProfileFormDialog(
      context,
      initialValue: profile == null
          ? null
          : ReaderProfileFormData(
              name: profile.name,
              birthYear: profile.birthYear,
              avatarUrl: _suggestedAvatarUrl(auth, profile: profile),
            ),
      suggestedAvatarUrl: _suggestedAvatarUrl(auth, profile: profile),
      title: profile == null
          ? 'Çocuk Profili Oluştur'
          : 'Çocuk Profilini Düzenle',
      submitLabel: profile == null ? 'Oluştur' : 'Kaydet',
      helperText: profile == null
          ? 'Bu profil yalnızca aile hesabınız içinde görünür.'
          : 'Bu profil bilgileri yalnızca aile hesabınız içinde güncellenir.',
    );
    if (formResult == null) return;

    final notifier = ref.read(authProvider.notifier);
    final ok = profile == null
        ? await notifier.createChildProfile(
            name: formResult.name,
            birthYear: formResult.birthYear,
            avatarUrl: formResult.avatarUrl,
            avatarBytes: formResult.avatarBytes,
            avatarFileName: formResult.avatarFileName,
          )
        : await notifier.updateReaderProfile(
            profileId: profile.id,
            name: formResult.name,
            birthYear: formResult.birthYear,
            avatarUrl: formResult.avatarUrl,
            avatarBytes: formResult.avatarBytes,
            avatarFileName: formResult.avatarFileName,
          );

    if (!ok) {
      _showAuthError(
        fallback: profile == null
            ? 'Çocuk profili oluşturulamadı.'
            : 'Çocuk profili güncellenemedi.',
      );
    }
  }

  Future<void> _archiveChildProfile(ReaderProfileModel profile) async {
    final approved = await ReaderProfileDialogs.showArchiveChildProfileDialog(
      context,
      profile: profile,
    );
    if (approved != true) return;

    final ok = await ref
        .read(authProvider.notifier)
        .archiveReaderProfile(profile.id);
    if (!ok) {
      _showAuthError(fallback: 'Profil arşivlenemedi.');
      return;
    }

    _showMessage('${profile.name} profili arşivlendi.');
  }

  Future<void> _activateManagedProfile(ReaderProfileModel profile) async {
    if (profile.id == ref.read(authProvider).activeProfile?.id) {
      return;
    }

    final ok = await ref
        .read(authProvider.notifier)
        .activateReaderProfile(profile.id);
    if (!ok) {
      _showAuthError(fallback: 'Profile geçilemedi.');
      return;
    }

    if (!mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final activeProfile = auth.activeProfile;
    final isPremium = auth.user?.isPremium == true;

    return Scaffold(
      appBar: AppBar(title: const Text('Okuyucu Profilleri')),
      body: SafeArea(
        top: false,
        child: activeProfile == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  AppUI.screenBottomContentPadding,
                ),
                children: [
                  Text(
                    'Aile hesabınızdaki çocuk profillerini burada düzenleyebilir, avatarlarını güncelleyebilir ve profiller arasında geçiş yapabilirsiniz.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ReaderProfilesSection(
                    activeProfile: activeProfile,
                    profiles: auth.profiles,
                    profileCapabilities: auth.profileCapabilities,
                    isPremium: isPremium,
                    onAddProfile: () => _openChildProfileForm(),
                    onActivateProfile: _activateManagedProfile,
                    onEditProfile: (profile) =>
                        _openChildProfileForm(profile: profile),
                    onArchiveProfile: _archiveChildProfile,
                    onUpgradeTap: () => context.push('/premium'),
                    showSectionTitle: false,
                    parentAvatarUrl: auth.user?.avatarUrl,
                  ),
                ],
              ),
      ),
    );
  }
}
