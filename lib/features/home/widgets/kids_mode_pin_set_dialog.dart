import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/user_friendly_error.dart';

class KidsModePinSetDialog extends StatefulWidget {
  const KidsModePinSetDialog({
    super.key,
    required this.onSave,
    required this.onCancel,
  });

  final Future<void> Function(String pin) onSave;
  final VoidCallback onCancel;

  static Future<bool?> show(
    BuildContext context, {
    required Future<void> Function(String pin) onSave,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => KidsModePinSetDialog(
        onSave: onSave,
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  State<KidsModePinSetDialog> createState() => _KidsModePinSetDialogState();
}

class _KidsModePinSetDialogState extends State<KidsModePinSetDialog> {
  final _pinController = TextEditingController();
  final _confirmController = TextEditingController();
  String _error = '';
  bool _obscurePin = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.isEmpty) {
      setState(() => _error = 'Lütfen bir ebeveyn şifresi girin.');
      return;
    }
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'Şifre 4 ile 6 hane arasında olmalı.');
      return;
    }
    if (confirm.isEmpty) {
      setState(() => _error = 'Lütfen şifreyi tekrar girin.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }

    setState(() {
      _error = '';
      _isSubmitting = true;
    });

    try {
      await widget.onSave(pin);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiFormErrorMessage(
          error,
          fallback: 'Ebeveyn şifresi kaydedilemedi. Lütfen tekrar deneyin.',
        );
      });
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    const accent = Color(0xFFE91E63);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? accent.withOpacity(0.22) : Colors.pink.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: isDark ? accent : Colors.pink.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Ebeveyn Şifresi Belirle',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çocuk modundan çıkmak için kullanılacak 4-6 haneli bir şifre belirleyin. Bu şifre çocukların yetişkin içeriklere erişmesini engeller.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _pinController,
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => setState(() => _error = ''),
            decoration: InputDecoration(
              labelText: 'Yeni şifre',
              hintText: '4-6 hane',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePin ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _confirmController,
            obscureText: _obscureConfirm,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            onChanged: (_) => setState(() => _error = ''),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Şifreyi tekrarla',
              hintText: '4-6 hane',
              errorText: _error.isEmpty ? null : _error,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : widget.onCancel,
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Kaydet'),
        ),
      ],
    );
  }
}
