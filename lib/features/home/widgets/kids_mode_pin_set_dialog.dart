import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    final confirm = _confirmController.text.trim();

    if (pin.length < 4) {
      setState(() => _error = 'Şifre en az 4 haneli olmalı.');
      return;
    }
    if (pin != confirm) {
      setState(() => _error = 'Şifreler eşleşmiyor.');
      return;
    }

    await widget.onSave(pin);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.pink.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.lock_outline_rounded, color: Colors.pink.shade700, size: 28),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Ebeveyn Şifresi Belirle',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Çocuk modundan çıkmak için kullanılacak 4-6 haneli bir şifre belirleyin. Bu şifre çocukların erişkin içeriklere erişmesini engeller.',
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
                icon: Icon(_obscurePin ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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
                icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.pink.shade600,
            foregroundColor: Colors.white,
          ),
          child: const Text('Kaydet'),
        ),
      ],
    );
  }
}
