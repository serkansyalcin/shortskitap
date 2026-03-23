import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../widgets/social_auth_buttons.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;
  bool _acceptTerms = false;
  bool _acceptPrivacyPolicy = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  String _targetAfterAuth(BuildContext context) {
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    if (returnTo == null || returnTo.isEmpty) {
      return '/home';
    }
    return returnTo;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passwordCtrl.text,
          acceptTerms: _acceptTerms,
          acceptPrivacyPolicy: _acceptPrivacyPolicy,
        );

    if (!mounted) return;

    setState(() => _loading = false);
    if (success) {
      context.go(_targetAfterAuth(context));
    } else {
      setState(() => _error = 'Kayıt tamamlanamadı. Bilgileri kontrol et.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final returnTo = GoRouterState.of(context).uri.queryParameters['returnTo'];
    final readingIntent = returnTo?.startsWith('/read/') == true;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          const _RegisterBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _RegisterHero(readingIntent: readingIntent),
                      const SizedBox(height: 26),
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
                            Text(
                              'Yeni hesabını oluştur',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bir dakika sürer. Hemen kitapları keşfetmeye başla.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.55,
                              ),
                            ),
                            const SizedBox(height: 22),
                            Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameCtrl,
                                    decoration: const InputDecoration(
                                      labelText: 'Ad Soyad',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'Ad bilgisi gerekli.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: const InputDecoration(
                                      labelText: 'E-posta',
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          !value.contains('@')) {
                                        return 'Geçerli bir e-posta gir.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    obscureText: _obscure,
                                    decoration: InputDecoration(
                                      labelText: 'Şifre',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () {
                                          setState(() => _obscure = !_obscure);
                                        },
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                        ),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.length < 8) {
                                        return 'En az 8 karakter gir.';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest
                                          .withOpacity(0.45),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: colorScheme.outline.withOpacity(
                                          0.55,
                                        ),
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        CheckboxListTile(
                                          value: _acceptTerms,
                                          onChanged: (value) {
                                            setState(
                                              () => _acceptTerms = value ?? false,
                                            );
                                          },
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          title: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      'Kullanım Koşulları\'nı okudum ve kabul ediyorum. ',
                                                ),
                                                TextSpan(
                                                  text: 'Aç',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () {
                                                          launchUrl(
                                                            Uri.parse(
                                                              'https://kitaplig.com/kullanim-kosullari',
                                                            ),
                                                          );
                                                        },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        CheckboxListTile(
                                          value: _acceptPrivacyPolicy,
                                          onChanged: (value) {
                                            setState(
                                              () => _acceptPrivacyPolicy =
                                                  value ?? false,
                                            );
                                          },
                                          contentPadding: EdgeInsets.zero,
                                          controlAffinity:
                                              ListTileControlAffinity.leading,
                                          title: RichText(
                                            text: TextSpan(
                                              style: TextStyle(
                                                color: colorScheme.onSurface,
                                                fontSize: 14,
                                              ),
                                              children: [
                                                const TextSpan(
                                                  text:
                                                      'Gizlilik Politikası\'nı okudum ve kabul ediyorum. ',
                                                ),
                                                TextSpan(
                                                  text: 'Aç',
                                                  style: const TextStyle(
                                                    color: AppColors.primary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  recognizer:
                                                      TapGestureRecognizer()
                                                        ..onTap = () {
                                                          launchUrl(
                                                            Uri.parse(
                                                              'https://kitaplig.com/gizlilik-politikasi',
                                                            ),
                                                          );
                                                        },
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF351717),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(
                                      0xFFFF6B6B,
                                    ).withValues(alpha: 0.40),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.error_outline_rounded,
                                      color: Color(0xFFFF8B8B),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFFFFD3D3),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: (_loading ||
                                      !_acceptTerms ||
                                      !_acceptPrivacyPolicy)
                                  ? null
                                  : _submit,
                              child: _loading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.black,
                                        strokeWidth: 2.2,
                                      ),
                                    )
                                  : Text(
                                      readingIntent
                                          ? 'Kayıt ol ve oku'
                                          : 'Kayıt ol',
                                    ),
                            ),
                            SocialAuthButtons(returnTo: returnTo, isLogin: false),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: () => context.pop(),
                                child: const Text.rich(
                                  TextSpan(
                                    text: 'Zaten hesabın var mı? ',
                                    style: TextStyle(
                                      color: AppColors.lightTextSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Giriş yap',
                                        style: TextStyle(
                                          color: AppColors.primaryLight,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
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

class _RegisterBackdrop extends StatelessWidget {
  const _RegisterBackdrop();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return IgnorePointer(
      child: Stack(
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
          Positioned(
            top: -120,
            right: -50,
            child: _RegisterGlow(
              size: 270,
              color: AppColors.primary.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            bottom: -110,
            left: -70,
            child: _RegisterGlow(
              size: 280,
              color: AppColors.accent.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _RegisterGlow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, Colors.transparent]),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  final bool readingIntent;

  const _RegisterHero({required this.readingIntent});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: theme.cardColor.withOpacity(isDark ? 0.92 : 0.98),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: colorScheme.outline.withOpacity(0.7)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.auto_stories_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                readingIntent
                    ? 'Okumaya başlamak için hesap oluştur'
                    : 'Kitaplig ile okumaya başla',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        BrandLogo(
          variant: isDark ? BrandLogoVariant.dark : BrandLogoVariant.light,
          height: 56,
        ),
        const SizedBox(height: 24),
        Text(
          'Kitaplig hesabını aç',
          style: textTheme.displayMedium?.copyWith(color: colorScheme.onSurface),
        ),
        const SizedBox(height: 10),
        Text(
          readingIntent
              ? 'Bir hesap oluştur, hemen kitabın içine geç.'
              : 'Paragraf paragraf oku, günlük hedefini tut, ligde arkadaşlarınla yarış.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
