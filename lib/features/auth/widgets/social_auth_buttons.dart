import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialAuthButtons extends ConsumerStatefulWidget {
  final String? returnTo;
  final bool isLogin;

  const SocialAuthButtons({super.key, this.returnTo, this.isLogin = true});

  @override
  ConsumerState<SocialAuthButtons> createState() => _SocialAuthButtonsState();
}

class _SocialAuthButtonsState extends ConsumerState<SocialAuthButtons> {
  @override
  Widget build(BuildContext context) {
    // Google/Apple social auth is temporarily disabled.
    return const SizedBox.shrink();
  }
}
