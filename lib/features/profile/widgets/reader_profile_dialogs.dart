import 'package:flutter/material.dart';

import '../../../core/models/reader_profile_model.dart';

class ReaderProfileDialogs {
  static Future<String?> showCreateChildProfileDialog(
    BuildContext context,
  ) async {
    final controller = TextEditingController();
    String? error;

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Çocuk Profili Oluştur'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Bu profilin adı yalnızca aile hesabın içinde görünür.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => error = null),
                    onSubmitted: (_) {
                      final value = controller.text.trim();
                      if (value.isEmpty) {
                        setState(() => error = 'Lütfen profil adı girin.');
                        return;
                      }
                      Navigator.of(dialogContext).pop(value);
                    },
                    decoration: InputDecoration(
                      labelText: 'Profil adı',
                      hintText: 'Örnek: Mina',
                      errorText: error,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    final value = controller.text.trim();
                    if (value.isEmpty) {
                      setState(() => error = 'Lütfen profil adı girin.');
                      return;
                    }
                    Navigator.of(dialogContext).pop(value);
                  },
                  child: const Text('Oluştur'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    return result;
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
                    leading: CircleAvatar(
                      child: Text(
                        profile.name.isEmpty
                            ? '?'
                            : profile.name.trim()[0].toUpperCase(),
                      ),
                    ),
                    title: Text(profile.name),
                    subtitle: const Text('Çocuk profili'),
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
