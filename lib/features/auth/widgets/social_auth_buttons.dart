import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../../../app/providers/auth_provider.dart';
import '../../../core/platform/platform_support.dart';

class SocialAuthButtons extends ConsumerStatefulWidget {
  final String? returnTo;
  final bool isLogin;

  const SocialAuthButtons({super.key, this.returnTo, this.isLogin = true});

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  bool _busy = false;

  String _targetAfterAuth() {
    final returnTo = widget.returnTo;
    if (returnTo == null || returnTo.isEmpty) {
      return '/home';
    }
    return returnTo;
  }

  // Google Sign-In — Android + iOS
  Future<void> _loginWithGoogle() async {
    if (_busy || !PlatformSupport.isMobileNative) return;
    setState(() => _busy = true);
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId:
            '975354372290-5pte4d2tmc25v27c28gipbbqpvi76k4h.apps.googleusercontent.com',
      );

      final account = await googleSignIn.signIn();
      if (account == null) return;

      final auth = await account.authentication;
      log(
        "auth.idToken ${auth.idToken}.  account.displayName ${account.displayName}",
      );
      final success = await ref
          .read(authProvider.notifier)
          .socialLogin(
            provider: 'google',
            idToken: auth.idToken,
            accessToken: auth.accessToken,
            name: account.displayName,
            email: account.email,
            avatarUrl: account.photoUrl,
          );

      if (!mounted) return;
      if (success) {
        context.go(_targetAfterAuth());
        return;
      }

      final error =
          ref.read(authProvider).error ??
          'Google ile giriş yapılamadı. Lütfen tekrar dene.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google ile giriş sırasında bir hata oluştu.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _loginWithApple() async {
    if (_busy || !PlatformSupport.isIOS) return;

    setState(() => _busy = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final firstName = credential.givenName?.trim();
      final lastName = credential.familyName?.trim();
      final fullName = [
        if (firstName?.isNotEmpty == true) firstName,
        if (lastName?.isNotEmpty == true) lastName,
      ].whereType<String>().join(' ');
      log(
        "auth.idToken ${credential.identityToken}.  account.displayName $fullName",
      );
      final success = await ref
          .read(authProvider.notifier)
          .socialLogin(
            provider: 'apple',
            identityToken: credential.identityToken,
            authorizationCode: credential.authorizationCode,
            email: credential.email,
            name: fullName.isNotEmpty ? fullName : null,
          );

      if (!mounted) return;
      if (success) {
        context.go(_targetAfterAuth());
        return;
      }

      final error =
          ref.read(authProvider).error ??
          'Apple ile giriş yapılamadı. Lütfen tekrar dene.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    } on SignInWithAppleAuthorizationException catch (e) {
      if (!mounted ||
          e.code == AuthorizationErrorCode.canceled ||
          e.code == AuthorizationErrorCode.notHandled) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple ile giriş sırasında bir hata oluştu.'),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Apple ile giriş sırasında bir hata oluştu.'),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final actionText = widget.isLogin ? 'Giriş yap' : 'Kayıt ol';

    // Neither platform supported — render nothing (e.g. web/desktop)
    if (!PlatformSupport.isMobileNative) return const SizedBox.shrink();

    return Column(
      children: [
        const SizedBox(height: 18),
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('veya', style: Theme.of(context).textTheme.bodySmall),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 14),
        // Apple — iOS only
        if (PlatformSupport.isIOS)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _loginWithApple,
              icon: const Icon(Icons.apple_rounded),
              label: Text('Apple ile $actionText'),
            ),
          ),
        // Google — Android + iOS
        if (PlatformSupport.isAndroid || PlatformSupport.isIOS) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _loginWithGoogle,
              icon: const Icon(Icons.g_mobiledata_rounded, size: 24),
              label: Text('Google ile $actionText'),
            ),
          ),
        ],
      ],
    );
  }
}
