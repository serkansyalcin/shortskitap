import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';

import '../../../app/theme/app_colors.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/widgets/brand_logo.dart';

class VerifyPinScreen extends ConsumerStatefulWidget {
  final String email;
  const VerifyPinScreen({super.key, required this.email});

  @override
  ConsumerState<VerifyPinScreen> createState() => _VerifyPinScreenState();
}

class _VerifyPinScreenState extends ConsumerState<VerifyPinScreen> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Lütfen 6 haneli kodu eksiksiz girin.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await AuthService().verifyResetCode(widget.email, code);
      if (!mounted) return;
      context.push('/reset-password?email=${Uri.encodeComponent(widget.email)}&code=${Uri.encodeComponent(code)}');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.response?.data['message'] ?? 'Geçersiz doğrulama kodu.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Bağlantı hatası oluştu.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: isDark
                  ? AppColors.heroGradient
                  : const LinearGradient(
                      colors: [AppColors.lightBackground, Color(0xFFF1F7F0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
            ),
          ),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      BrandLogo(
                        variant: isDark ? BrandLogoVariant.dark : BrandLogoVariant.light,
                        height: 48,
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Kodu Doğrula',
                        style: textTheme.displaySmall?.copyWith(color: colorScheme.onSurface, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),
                      Text.rich(
                        TextSpan(
                          text: 'E-posta adresine (',
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            height: 1.55,
                          ),
                          children: [
                            TextSpan(
                              text: widget.email,
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                            ),
                            const TextSpan(text: ') gönderdiğimiz 6 haneli doğrulama kodunu gir.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.7),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.32 : 0.08,
                              ),
                              blurRadius: 34,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _codeCtrl,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 24, letterSpacing: 12, fontWeight: FontWeight.w800),
                              decoration: const InputDecoration(
                                counterText: '',
                                labelText: '6 Haneli Kod',
                                alignLabelWithHint: true,
                              ),
                              onChanged: (v) {
                                if (v.length == 6) {
                                  _submit();
                                }
                              },
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF351717),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFFF6B6B).withValues(alpha: 0.40),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.error_outline_rounded, color: Color(0xFFFF8B8B)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: textTheme.bodyMedium?.copyWith(color: const Color(0xFFFFD3D3)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _loading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(double.infinity, 56),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : const Text('Doğrula'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
