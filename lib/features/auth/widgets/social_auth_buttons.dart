import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/models/user_model.dart';
import '../../../core/services/auth_service.dart';

class SocialAuthButtons extends ConsumerStatefulWidget {
  final String? returnTo;

  const SocialAuthButtons({super.key, this.returnTo});

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  bool _isLoadingGoogle = false;
  bool _isLoadingApple = false;

  void _handleSuccess(UserModel user) {
    ref.read(authProvider.notifier).updateUser(user);
    final returnTo = widget.returnTo;
    if (returnTo != null && returnTo.isNotEmpty) {
      context.go(returnTo);
    } else {
      context.go('/home');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red.shade800),
    );
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoadingGoogle = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email']);
      final GoogleSignInAccount? account = await googleSignIn.signIn();

      if (account != null) {
        final authService = AuthService();
        final result = await authService.socialLogin(
          provider: 'google',
          providerId: account.id,
          name: account.displayName ?? 'Google User',
          email: account.email,
          avatarUrl: account.photoUrl,
        );
        _handleSuccess(result.user);
      }
    } catch (e) {
      _showError('Google ile giriş yapılırken bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoadingApple = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final email = credential.email ?? '${credential.userIdentifier}@apple.com';
      final name = credential.givenName != null 
          ? '${credential.givenName} ${credential.familyName}'
          : 'Apple User';

      final authService = AuthService();
      final result = await authService.socialLogin(
        provider: 'apple',
        providerId: credential.userIdentifier!,
        name: name,
        email: email,
      );
      _handleSuccess(result.user);
    } catch (e) {
       _showError('Apple ile giriş yapılırken bir hata oluştu.');
    } finally {
      if (mounted) setState(() => _isLoadingApple = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool showApple =
        !kIsWeb && defaultTargetPlatform != TargetPlatform.android;

    return Column(
      children: [
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'veya şununla devam et',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(child: Divider(color: Theme.of(context).colorScheme.outlineVariant)),
          ],
        ),
        const SizedBox(height: 24),
        Column(
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isLoadingGoogle ? null : _signInWithGoogle,
                icon: _isLoadingGoogle
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.g_mobiledata, size: 28),
                label: const Text('Google ile Giriş Yap'),
              ),
            ),
            if (showApple) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isLoadingApple ? null : _signInWithApple,
                  icon: _isLoadingApple
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.apple, size: 28),
                  label: const Text('Apple ile Giriş Yap'),
                ),
              ),
            ]
          ],
        ),
      ],
    );
  }
}
