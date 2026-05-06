import 'package:flutter/material.dart';

class CommunityReportSheet extends StatefulWidget {
  const CommunityReportSheet({super.key, required this.onSubmit});

  final Future<void> Function(String reason, String? details) onSubmit;

  @override
  State<CommunityReportSheet> createState() => _CommunityReportSheetState();
}

class _CommunityReportSheetState extends State<CommunityReportSheet> {
  final TextEditingController _detailsController = TextEditingController();
  String _reason = _reasons.first.value;
  bool _busy = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onSubmit(_reason, _detailsController.text);
      if (mounted) Navigator.of(context).pop(true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          8,
          20,
          20 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Şikayet et',
              style: TextStyle(
                color: scheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _reason,
              decoration: const InputDecoration(labelText: 'Sebep'),
              items: _reasons
                  .map(
                    (reason) => DropdownMenuItem(
                      value: reason.value,
                      child: Text(reason.label),
                    ),
                  )
                  .toList(),
              onChanged: _busy
                  ? null
                  : (value) => setState(() => _reason = value ?? _reason),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _detailsController,
              maxLines: 3,
              maxLength: 1000,
              decoration: const InputDecoration(
                labelText: 'Detay',
                hintText: 'İstersen kısa bir açıklama ekle',
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Gönder'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportReason {
  final String value;
  final String label;

  const _ReportReason(this.value, this.label);
}

const _reasons = [
  _ReportReason('spam', 'Spam'),
  _ReportReason('abuse', 'Taciz veya nefret'),
  _ReportReason('spoiler', 'Spoiler'),
  _ReportReason('sexual_content', 'Uygunsuz içerik'),
  _ReportReason('violence', 'Şiddet'),
  _ReportReason('copyright', 'Telif'),
  _ReportReason('other', 'Diğer'),
];
