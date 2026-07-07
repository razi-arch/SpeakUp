import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/secondary_button.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus   = FocusNode();
  final _passwordFocus = FocusNode();

  bool    _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // â”€â”€ Sign-in logic â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _signIn() async {
    if (_loading) return;
    final email    = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Please enter your email and password.');
      return;
    }

    setState(() { _loading = true; _error = null; });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signIn(email, password);

      if (mounted) {
        ref.read(adultAccessUnlockedProvider.notifier).state = true;
        ref.invalidate(adultProfileProvider);
        ref.invalidate(linkedChildrenProvider);
        setState(() => _loading = false);
        context.go('/admin/dashboard');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) setState(() { _loading = false; _error = _mapError(e.code); });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _error = 'Sign in failed. Please try again.'; });
    }
  }

  static String _mapError(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'Email or password is incorrect.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      default:
        return 'Sign in failed. Please try again.';
    }
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // â”€â”€ Icon â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.sm,
                      border: Border.all(
                        color: AppColors.ink4.withValues(alpha: 0.65),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.lock_rounded,
                      size: 38,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // â”€â”€ Heading â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Text('Parent & Teacher Sign In', style: AppText.heading()),
                  const SizedBox(height: 6),
                  Text(
                    "Sign in to manage children's profiles and progress",
                    style: AppText.body(color: AppColors.ink3),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  // â”€â”€ Form card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: AppRadius.xl,
                      boxShadow: AppShadows.md,
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _LoginField(
                          label: 'Email',
                          controller: _emailCtrl,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onSubmitted: () => _passwordFocus.requestFocus(),
                        ),
                        const SizedBox(height: 16),
                        _LoginField(
                          label: 'Password',
                          controller: _passwordCtrl,
                          focusNode: _passwordFocus,
                          obscure: true,
                          textInputAction: TextInputAction.done,
                          onSubmitted: _signIn,
                        ),
                        // â”€â”€ Error â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          _ErrorBanner(message: _error!),
                        ],
                        const SizedBox(height: 24),
                        // â”€â”€ Sign-in button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                        if (_loading)
                          Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.green,
                              borderRadius: AppRadius.pill,
                            ),
                            alignment: Alignment.center,
                            child: const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        else
                          PrimaryButton(
                            label: 'Sign In',
                            width: double.infinity,
                            onPressed: _signIn,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // â”€â”€ Divider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.ink4)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text('New here?',
                            style: AppText.caption(color: AppColors.ink3)),
                      ),
                      const Expanded(child: Divider(color: AppColors.ink4)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // â”€â”€ Create Account button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  SecondaryButton(
                    label: 'Create an Account',
                    width: double.infinity,
                    onPressed: () => context.go('/admin/register'),
                  ),
                  const SizedBox(height: 24),
                  // â”€â”€ Back link â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
                  GestureDetector(
                    onTap: () => context.go('/'),
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.arrow_back_rounded,
                            size: 16,
                            color: AppColors.ink3,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Back to child screen',
                            style: AppText.caption(color: AppColors.ink3),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut)
                .slideY(
                  begin: 0.03,
                  end: 0,
                  duration: AppMotion.slow,
                  curve: AppMotion.easeOut,
                ),
            ),
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Login field â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _LoginField extends StatefulWidget {
  const _LoginField({
    required this.label,
    required this.controller,
    required this.focusNode,
    this.obscure = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  final String label;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool obscure;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final VoidCallback? onSubmitted;

  @override
  State<_LoginField> createState() => _LoginFieldState();
}

class _LoginFieldState extends State<_LoginField> {
  bool _focused = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() =>
      setState(() => _focused = widget.focusNode.hasFocus);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppText.caption()),
        const SizedBox(height: 6),
        AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.easeOut,
          decoration: BoxDecoration(
            borderRadius: AppRadius.md,
            boxShadow: _focused
                ? [
                    BoxShadow(
                      color: AppColors.greenMid.withValues(alpha: 0.55),
                      blurRadius: 0,
                      spreadRadius: 3,
                    ),
                  ]
                : [],
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            obscureText: widget.obscure && !_showPassword,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onSubmitted: (_) => widget.onSubmitted?.call(),
            style: AppText.body(),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.bg,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide:
                    const BorderSide(color: AppColors.ink4, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: AppRadius.md,
                borderSide:
                    const BorderSide(color: AppColors.green, width: 1.5),
              ),
              hintText: widget.label,
              hintStyle: AppText.body(color: AppColors.ink3),
              suffixIcon: widget.obscure
                  ? IconButton(
                      icon: Icon(
                        _showPassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        color: AppColors.ink3,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _showPassword = !_showPassword),
                    )
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

// â”€â”€â”€ Error banner â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.roseLight,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.roseMid, width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.rose, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: AppText.caption(color: AppColors.rose)),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppMotion.fast).slideY(begin: -0.1, end: 0, duration: AppMotion.fast);
  }
}

