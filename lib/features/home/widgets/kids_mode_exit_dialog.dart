import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/utils/user_friendly_error.dart';

class KidsModeExitDialog extends StatefulWidget {
  const KidsModeExitDialog({
    super.key,
    required this.onSuccess,
    required this.onCancel,
    required this.verifyPin,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final Future<bool> Function(String) verifyPin;

  static Future<bool?> show(
    BuildContext context, {
    required Future<bool> Function(String) verifyPin,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => KidsModeExitDialog(
        verifyPin: verifyPin,
        onSuccess: () => Navigator.of(ctx).pop(true),
        onCancel: () => Navigator.of(ctx).pop(false),
      ),
    );
  }

  @override
  State<KidsModeExitDialog> createState() => _KidsModeExitDialogState();
}

class _KidsModeExitDialogState extends State<KidsModeExitDialog> {
  final _controller = TextEditingController();
  String _error = '';
  bool _obscure = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    final pin = _controller.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Lütfen ebeveyn şifresini girin.');
      return;
    }
    if (pin.length < 4 || pin.length > 6) {
      setState(() => _error = 'Şifre 4 ile 6 hane arasında olmalı.');
      return;
    }

    setState(() {
      _error = '';
      _isSubmitting = true;
    });

    try {
      final isValid = await widget.verifyPin(pin);
      if (!mounted) return;

      if (isValid) {
        widget.onSuccess();
      } else {
        setState(() => _error = 'Şifre yanlış. Lütfen tekrar deneyin.');
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = apiFormErrorMessage(
          error,
          fallback: 'Şifre doğrulanamadı. Lütfen tekrar deneyin.',
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
              color: isDark
                  ? accent.withValues(alpha: 0.22)
                  : Colors.pink.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.lock_rounded,
              color: isDark ? accent : Colors.pink.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Çocuk Profilinden Çık',
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
            'Ebeveyn profiline dönmek için ebeveyn şifresini girin. Bu sayede çocukların uygun olmayan içeriklere erişmesi engellenir.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            obscureText: _obscure,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            autofocus: true,
            onChanged: (_) => setState(() => _error = ''),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              labelText: 'Ebeveyn şifresi',
              hintText: '4-6 haneli şifre',
              errorText: _error.isEmpty ? null : _error,
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: widget.onCancel, child: const Text('İptal')),
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
              : const Text('Doğrula'),
        ),
      ],
    );
  }
}
