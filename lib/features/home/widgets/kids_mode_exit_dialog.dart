import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class KidsModeExitDialog extends StatefulWidget {
  const KidsModeExitDialog({
    super.key,
    required this.onSuccess,
    required this.onCancel,
    required this.verifyPin,
  });

  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final bool Function(String) verifyPin;

  static Future<bool?> show(
    BuildContext context, {
    required bool Function(String) verifyPin,
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final pin = _controller.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Lütfen şifreyi girin.');
      return;
    }
    if (widget.verifyPin(pin)) {
      widget.onSuccess();
    } else {
      setState(() => _error = 'Yanlış şifre. Tekrar deneyin.');
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
              Icons.lock_rounded,
              color: isDark ? accent : Colors.pink.shade700,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Çocuk Modundan Çık',
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
            'Erişkin içeriğe geçmek için ebeveyn şifresini girin. Bu sayede çocukların uygun olmayan içeriklere erişmesi engellenir.',
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
            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
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
            backgroundColor: accent,
            foregroundColor: Colors.white,
          ),
          child: const Text('Doğrula'),
        ),
      ],
    );
  }
}
