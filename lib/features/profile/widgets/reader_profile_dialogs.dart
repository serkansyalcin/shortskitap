import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/models/reader_profile_model.dart';
import '../../../core/services/avatar_picker_service.dart';
import '../../../core/services/avatar_picker_types.dart';
import '../../../core/widgets/reader_profile_avatar.dart';

class ReaderProfileFormData {
  final String name;
  final int? age;
  final String? avatarUrl;
  final Uint8List? avatarBytes;
  final String? avatarFileName;

  const ReaderProfileFormData({
    required this.name,
    this.age,
    this.avatarUrl,
    this.avatarBytes,
    this.avatarFileName,
  });
}

class ReaderProfileDialogs {
  static Future<String?> showCreateChildProfileDialog(
    BuildContext context, {
    String? suggestedAvatarUrl,
  }) async {
    final result = await showChildProfileFormDialog(
      context,
      suggestedAvatarUrl: suggestedAvatarUrl,
    );
    return result?.name;
  }

  static Future<ReaderProfileFormData?> showChildProfileFormDialog(
    BuildContext context, {
    ReaderProfileFormData? initialValue,
    String? suggestedAvatarUrl,
    String title = 'Çocuk Profili Oluştur',
    String submitLabel = 'Oluştur',
    String? helperText,
  }) async {
    final picker = createAvatarPickerService();
    final nameController = TextEditingController(
      text: initialValue?.name ?? '',
    );
    final ageController = TextEditingController(
      text: initialValue?.age?.toString() ?? '',
    );
    String? selectedAvatarUrl =
        initialValue?.avatarUrl ??
        suggestedAvatarUrl ??
        ReaderProfileAvatarCatalog.tokenValue('fox');
    Uint8List? selectedAvatarBytes = initialValue?.avatarBytes;
    String? selectedAvatarFileName = initialValue?.avatarFileName;
    String? nameError;
    String? ageError;

    final result = await showModalBottomSheet<ReaderProfileFormData>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final textTheme = theme.textTheme;
        final colorScheme = theme.colorScheme;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> pickAvatar(
              Future<PickedAvatar?> Function() callback,
            ) async {
              final picked = await callback();
              if (picked == null) return;

              setState(() {
                selectedAvatarBytes = picked.bytes;
                selectedAvatarFileName = picked.fileName;
              });
            }

            void chooseDefaultAvatar(String tokenValue) {
              setState(() {
                selectedAvatarUrl = tokenValue;
                selectedAvatarBytes = null;
                selectedAvatarFileName = null;
              });
            }

            void submit() {
              final name = nameController.text.trim();
              final ageText = ageController.text.trim();
              int? age;

              if (name.isEmpty) {
                setState(() => nameError = 'Lütfen profil adını girin.');
                return;
              }

              if (ageText.isEmpty) {
                setState(() => ageError = 'Lütfen yaş bilgisini girin.');
                return;
              }

              age = int.tryParse(ageText);
              if (age == null || age < 1 || age > 18) {
                setState(() => ageError = 'Geçerli bir yaş girin.');
                return;
              }

              Navigator.of(sheetContext).pop(
                ReaderProfileFormData(
                  name: name,
                  age: age,
                  avatarUrl: selectedAvatarUrl,
                  avatarBytes: selectedAvatarBytes,
                  avatarFileName: selectedAvatarFileName,
                ),
              );
            }

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 8,
                  bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        helperText ??
                            'Bu profil yalnızca aile hesabınız içinde görünür.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ReaderProfileAvatar(
                          name: nameController.text.isEmpty
                              ? 'Ç'
                              : nameController.text,
                          avatarRef: selectedAvatarUrl,
                          memoryBytes: selectedAvatarBytes,
                          size: 92,
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () =>
                                pickAvatar(() => picker.pickFromGallery()),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Galeriden Seç'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () =>
                                pickAvatar(() => picker.pickFromCamera()),
                            icon: const Icon(Icons.photo_camera_outlined),
                            label: const Text('Kamerayla Çek'),
                          ),
                        ],
                      ),
                      if (selectedAvatarBytes != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Yüklenen fotoğraf bu profilde kullanılacak. Dilersen aşağıdan varsayılan bir avatar seçerek geri dönebilirsin.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.35,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text(
                        'Karakter avatarları',
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: ReaderProfileAvatarCatalog.presets
                            .map((preset) {
                              final tokenValue =
                                  ReaderProfileAvatarCatalog.tokenValue(
                                    preset.token,
                                  );
                              final isSelected =
                                  selectedAvatarBytes == null &&
                                  selectedAvatarUrl == tokenValue;

                              return GestureDetector(
                                onTap: () => chooseDefaultAvatar(tokenValue),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  width: 82,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary.withValues(
                                            alpha: 0.10,
                                          )
                                        : colorScheme.surfaceContainerLowest,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline.withValues(
                                              alpha: 0.35,
                                            ),
                                      width: isSelected ? 1.8 : 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: colorScheme.shadow.withValues(
                                          alpha: isSelected ? 0.10 : 0.04,
                                        ),
                                        blurRadius: isSelected ? 18 : 10,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      ReaderProfileAvatar(
                                        name: preset.label,
                                        avatarRef: tokenValue,
                                        size: 56,
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        preset.label,
                                        style: textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : colorScheme.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            })
                            .toList(growable: false),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: nameController,
                        autofocus: true,
                        textInputAction: TextInputAction.next,
                        onChanged: (_) => setState(() => nameError = null),
                        decoration: InputDecoration(
                          labelText: 'Profil adı',
                          hintText: 'Örnek: Mina',
                          errorText: nameError,
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: ageController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        onChanged: (_) => setState(() => ageError = null),
                        onSubmitted: (_) => submit(),
                        decoration: InputDecoration(
                          labelText: 'Yaşı',
                          hintText: 'Yaşı girin',
                          errorText: ageError,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(sheetContext).pop(),
                              child: const Text('İptal'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: submit,
                              child: Text(submitLabel),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    ageController.dispose();
    return result;
  }

  static Future<bool?> showArchiveChildProfileDialog(
    BuildContext context, {
    required ReaderProfileModel profile,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final isDark = theme.brightness == Brightness.dark;

        return Dialog(
          backgroundColor: isDark ? const Color(0xFF171A17) : theme.cardColor,
          surfaceTintColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Profili Arşivle',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  '${profile.name} profili arşivlenecek. Bu işlem profilin geçmiş verilerini korur ama profili listeden kaldırır.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(false),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Vazgeç'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(dialogContext).pop(true),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Arşivle'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<ReaderProfileModel?> showChildProfilePicker(
    BuildContext context, {
    required List<ReaderProfileModel> profiles,
  }) {
    return showModalBottomSheet<ReaderProfileModel>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Çocuk Profili Seç',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Çocuk alanına geçmek için bir okuyucu profili seç.',
                ),
                const SizedBox(height: 16),
                ...profiles.map(
                  (profile) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ReaderProfileAvatar(
                      name: profile.name,
                      avatarRef:
                          profile.avatarUrl ??
                          ReaderProfileAvatarCatalog.suggestedTokenValue(
                            index: profile.id,
                          ),
                      size: 48,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    title: Text(profile.name),
                    subtitle: Text(
                      profile.age != null
                          ? 'Çocuk profili • ${profile.age} yaş'
                          : 'Çocuk profili',
                    ),
                    onTap: () => Navigator.of(context).pop(profile),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
