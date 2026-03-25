import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
// import '../widgets/social_auth_buttons.dart';

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
  bool _acceptTerms = false;
  bool _acceptPrivacyPolicy = false;
  String? _error;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

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

  void _clearInlineError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  String? _validateName(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) {
      return 'Adını ve soyadını yaz.';
    }
    if (name.length < 3) {
      return 'Ad soyad en az 3 karakter olmalı.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) {
      return 'E-posta adresini yaz.';
    }
    if (!email.contains('@') || !email.contains('.')) {
      return 'Geçerli bir e-posta adresi gir.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Şifreni yaz.';
    }
    if (password.length < 8) {
      return 'Şifre en az 8 karakter olmalı.';
    }
    return null;
  }

  Future<void> _openExternalUrl(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    if (_loading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final isFormValid = _formKey.currentState!.validate();
    final hasAcceptedPolicies = _acceptTerms && _acceptPrivacyPolicy;

    if (!isFormValid || !hasAcceptedPolicies) {
      setState(() {
        _autovalidateMode = AutovalidateMode.onUserInteraction;
        if (!hasAcceptedPolicies) {
          _error =
              'Devam etmek için Kullanım Koşulları ve Gizlilik Politikası onaylarını vermelisin.';
        }
      });
      return;
    }

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

    if (!mounted) {
      return;
    }

    setState(() => _loading = false);
    if (success) {
      context.go(_targetAfterAuth(context));
      return;
    }

    setState(() {
      _autovalidateMode = AutovalidateMode.onUserInteraction;
      _error = ref.read(authProvider).error;
    });
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
                              'Bir dakikada hesabını aç, sonra okumaya ve ligde yükselmeye başla.',
                              style: textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                height: 1.55,
                              ),
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 18),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF1F1),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: const Color(0xFFFCA5A5),
                                  ),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Padding(
                                      padding: EdgeInsets.only(top: 1),
                                      child: Icon(
                                        Icons.error_outline_rounded,
                                        color: Color(0xFFDC2626),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        _error!,
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: const Color(0xFF991B1B),
                                          height: 1.45,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 22),
                            Form(
                              key: _formKey,
                              autovalidateMode: _autovalidateMode,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _nameCtrl,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) => _clearInlineError(),
                                    decoration: const InputDecoration(
                                      labelText: 'Ad Soyad',
                                      prefixIcon: Icon(
                                        Icons.person_outline_rounded,
                                      ),
                                    ),
                                    validator: _validateName,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (_) => _clearInlineError(),
                                    decoration: const InputDecoration(
                                      labelText: 'E-posta',
                                      hintText: 'ornek@mail.com',
                                      prefixIcon: Icon(
                                        Icons.alternate_email_rounded,
                                      ),
                                    ),
                                    validator: _validateEmail,
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordCtrl,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (_) => _clearInlineError(),
                                    onFieldSubmitted: (_) => _submit(),
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
                                    validator: _validatePassword,
                                  ),
                                  const SizedBox(height: 16),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: theme
                                          .colorScheme
                                          .surfaceContainerHighest
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
                                              () =>
                                                  _acceptTerms = value ?? false,
                                            );
                                            _clearInlineError();
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
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      _openExternalUrl(
                                                        'https://kitaplig.com/kullanim-kosullari',
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
                                            _clearInlineError();
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
                                                  recognizer: TapGestureRecognizer()
                                                    ..onTap = () {
                                                      _openExternalUrl(
                                                        'https://kitaplig.com/gizlilik-politikasi',
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
                            const SizedBox(height: 22),
                            ElevatedButton(
                              onPressed: _loading ? null : _submit,
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
                            // Social auth buttons are hidden for now.
                            // SocialAuthButtons(
                            //   returnTo: returnTo,
                            //   isLogin: false,
                            // ),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  final uri = Uri(
                                    path: '/login',
                                    queryParameters: returnTo != null
                                        ? {'returnTo': returnTo}
                                        : null,
                                  );
                                  context.pushReplacement(uri.toString());
                                },
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
          style: textTheme.displayMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          readingIntent
              ? 'Bir hesap oluştur, hemen kitabına geri dön.'
              : 'Paragraf paragraf oku, hedefini tuttur, ligde yüksel.',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
