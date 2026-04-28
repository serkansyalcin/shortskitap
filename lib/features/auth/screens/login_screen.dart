import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/widgets/brand_logo.dart';
import '../widgets/social_auth_buttons.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  String? _error;
  AutovalidateMode _autovalidateMode = AutovalidateMode.disabled;

  @override
  void dispose() {
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
    if (password.length < 6) {
      return 'Şifre en az 6 karakter olmalı.';
    }
    return null;
  }

  void _clearInlineError() {
    if (_error != null) {
      setState(() => _error = null);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      setState(() => _autovalidateMode = AutovalidateMode.onUserInteraction);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final success = await ref
        .read(authProvider.notifier)
        .login(_emailCtrl.text.trim(), _passwordCtrl.text);

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
          const _AuthBackdrop(),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AuthHero(
                        label: readingIntent
                            ? 'Okumaya devam etmek için giriş yap'
                            : 'Kitaplig ile okuma ritmini koru',
                        title: 'Tekrar hoş geldin',
                        subtitle: readingIntent
                            ? 'Kitaba dönmek için hesabına giriş yapman gerekiyor.'
                            : 'Okuma ilerlemen, lig puanların ve kitapların hesabında seni bekliyor.',
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.7),
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
                              'Hesabına giriş yap',
                              style: textTheme.titleLarge?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'E-posta ve şifrenle giriş yaparak kaldığın yerden devam edebilirsin.',
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
                                    onFieldSubmitted: (_) {
                                      if (!_loading) {
                                        _submit();
                                      }
                                    },
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
                                  const SizedBox(height: 8),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        context.push('/forgot-password');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Şifreni mi unuttun?',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
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
                                          ? 'Giriş yap ve oku'
                                          : 'Giriş yap',
                                    ),
                            ),
                            SocialAuthButtons(returnTo: returnTo),
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  final uri = Uri(
                                    path: '/register',
                                    queryParameters: returnTo != null
                                        ? {'returnTo': returnTo}
                                        : null,
                                  );
                                  context.pushReplacement(uri.toString());
                                },
                                child: const Text.rich(
                                  TextSpan(
                                    text: 'Hesabın yok mu? ',
                                    style: TextStyle(
                                      color: AppColors.lightTextSecondary,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: 'Kayıt ol',
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

class _AuthBackdrop extends StatelessWidget {
  const _AuthBackdrop();

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
            top: -110,
            left: -40,
            child: _AuthGlow(
              size: 250,
              color: AppColors.primary.withValues(alpha: 0.24),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -60,
            child: _AuthGlow(
              size: 300,
              color: AppColors.accent.withValues(alpha: 0.14),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthGlow extends StatelessWidget {
  final double size;
  final Color color;

  const _AuthGlow({required this.size, required this.color});

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

class _AuthHero extends StatelessWidget {
  final String label;
  final String title;
  final String subtitle;

  const _AuthHero({
    required this.label,
    required this.title,
    required this.subtitle,
  });

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
            color: theme.cardColor.withValues(alpha: isDark ? 0.92 : 0.98),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.7),
            ),
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
                label,
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
          title,
          style: textTheme.displayMedium?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}
