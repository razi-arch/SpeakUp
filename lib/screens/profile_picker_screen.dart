import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/child_model.dart';
import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../providers/reward_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';
import '../widgets/primary_button.dart';
import '../widgets/profile_card.dart';
import '../widgets/secondary_button.dart';

class ProfilePickerScreen extends ConsumerWidget {
  const ProfilePickerScreen({super.key});

  static const _gradient = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF2FAF6), AppColors.bg, Color(0xFFFFF8EE)],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authStateProvider);
    final adultProfileAsync = ref.watch(adultProfileProvider);
    final childrenAsync = ref.watch(linkedChildrenProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _gradient,
        child: SafeArea(
          child: Stack(
            children: [
              const _BackgroundShapes(),
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _HeroPanel(
                              authAsync: authAsync,
                              adultProfileAsync: adultProfileAsync,
                            ),
                            const SizedBox(height: 20),
                            _buildBody(
                              context,
                              ref,
                              authAsync,
                              childrenAsync,
                              constraints.maxWidth,
                            ),
                          ],
                        )
                            .animate()
                            .fadeIn(
                              duration: AppMotion.slow,
                              curve: AppMotion.easeOut,
                            )
                            .slideY(
                              begin: 0.03,
                              end: 0,
                              duration: AppMotion.slow,
                              curve: AppMotion.easeOut,
                            ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    AsyncValue<dynamic> authAsync,
    AsyncValue<List<ChildModel>> childrenAsync,
    double width,
  ) {
    final signedInUser =
        authAsync.valueOrNull ?? ref.read(authServiceProvider).user;

    if (authAsync.isLoading && signedInUser == null) {
      return const _SpinnerPanel();
    }

    if (signedInUser == null) {
      return _SetupRequired(context: context);
    }

    if (childrenAsync.isLoading) return const _SpinnerPanel();

    if (childrenAsync.hasError) return const _ErrorState();

    final children = childrenAsync.valueOrNull ?? [];

    if (children.isEmpty) {
      return _NoChildren(context: context);
    }

    return _CardGrid(children: children, width: width);
  }
}

class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: _GlowCircle(
              size: 220,
              colors: [
                AppColors.amberLight.withValues(alpha: 0.9),
                AppColors.amber.withValues(alpha: 0.05),
              ],
            ),
          ),
          Positioned(
            top: 180,
            left: -80,
            child: _GlowCircle(
              size: 240,
              colors: [
                AppColors.skyLight.withValues(alpha: 0.86),
                AppColors.sky.withValues(alpha: 0.04),
              ],
            ),
          ),
          Positioned(
            bottom: -90,
            right: 110,
            child: _GlowCircle(
              size: 260,
              colors: [
                AppColors.greenLight.withValues(alpha: 0.82),
                AppColors.green.withValues(alpha: 0.04),
              ],
            ),
          ),
          const Positioned(
            top: 92,
            left: 54,
            child: _SoftDot(size: 16, color: AppColors.amberMid),
          ),
          const Positioned(
            top: 154,
            right: 126,
            child: _SoftDot(size: 11, color: AppColors.skyMid),
          ),
          const Positioned(
            bottom: 146,
            left: 80,
            child: _SoftDot(size: 14, color: AppColors.greenMid),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _SoftDot extends StatelessWidget {
  const _SoftDot({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.authAsync,
    required this.adultProfileAsync,
  });

  final AsyncValue<dynamic> authAsync;
  final AsyncValue<dynamic> adultProfileAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFFCF5),
            AppColors.bgCard,
            Color(0xFFF1FAF6),
          ],
        ),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.45)),
        boxShadow: AppShadows.lg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 820;

          return Wrap(
            spacing: 18,
            runSpacing: 18,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: compact ? constraints.maxWidth : constraints.maxWidth * 0.64,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.greenLight,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        'Welcome back',
                        style: AppText.caption(color: AppColors.greenDark),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('Who is here today?', style: AppText.display()),
                    const SizedBox(height: 8),
                    Text(
                      'Choose your picture to begin.',
                      style: AppText.body(color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: compact ? constraints.maxWidth : constraints.maxWidth * 0.24,
                child: _AdultAccessCard(
                  authAsync: authAsync,
                  adultProfileAsync: adultProfileAsync,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AdultAccessCard extends StatelessWidget {
  const _AdultAccessCard({
    required this.authAsync,
    required this.adultProfileAsync,
  });

  final AsyncValue<dynamic> authAsync;
  final AsyncValue<dynamic> adultProfileAsync;

  @override
  Widget build(BuildContext context) {
    final isSignedIn = authAsync.valueOrNull != null;
    final profile = adultProfileAsync.valueOrNull;
    final title = isSignedIn
        ? (profile?.firstName ?? 'Parent / Teacher')
        : 'Parent / Teacher Login';
    final subtitle = isSignedIn
        ? 'Tap to unlock adult tools'
        : 'Sign in to manage profiles here';

    return GestureDetector(
      onTap: () => _handleAdultAccess(context),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.78),
          borderRadius: AppRadius.xl,
          border: Border.all(color: AppColors.ink4.withValues(alpha: 0.42)),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.ink5,
                borderRadius: AppRadius.lg,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppText.caption(color: AppColors.ink2),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppText.caption(color: AppColors.ink3),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleAdultAccess(BuildContext context) async {
    final container = ProviderScope.containerOf(context, listen: false);
    final user = container.read(authStateProvider).valueOrNull ??
        container.read(authServiceProvider).user;

    if (user == null) {
      if (context.mounted) context.go('/admin/login');
      return;
    }

    try {
      final profile = await container.read(adultProfileProvider.future);
      if (profile == null) {
        if (context.mounted) context.go('/admin/login');
        return;
      }

      if (!profile.hasPin) {
        if (!context.mounted) return;
        final pin = await showDialog<String>(
          context: context,
          barrierDismissible: false,
          builder: (_) => _CreatePinDialog(firstName: profile.firstName),
        );

        if (pin == null) return;
        await container.read(authServiceProvider).updateAccessPin(user.uid, pin);
        container.invalidate(adultProfileProvider);
      }

      final refreshedProfile =
          await container.read(adultProfileProvider.future) ?? profile;
      if (!context.mounted) return;
      final unlocked = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => _PinUnlockDialog(firstName: refreshedProfile.firstName),
      );

      if (unlocked == true && context.mounted) {
        container.read(adultAccessUnlockedProvider.notifier).state = true;
        context.go('/admin/dashboard');
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not unlock adult tools right now. Please try again.'),
        ),
      );
    }
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.children,
    required this.width,
  });

  final List<ChildModel> children;
  final double width;

  @override
  Widget build(BuildContext context) {
    final cardSpacing = width >= 900 ? 18.0 : 14.0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.9),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.5)),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose your picture', style: AppText.heading()),
          const SizedBox(height: 6),
          Text(
            'Tap a profile when you are ready.',
            style: AppText.body(color: AppColors.ink2),
          ),
          const SizedBox(height: 18),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Wrap(
                spacing: cardSpacing,
                runSpacing: 18,
                alignment: WrapAlignment.center,
                children: [
                  for (var i = 0; i < children.length; i++)
                    _ProfileCardItem(
                      key: ValueKey(children[i].id),
                      child: children[i],
                      index: i,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileCardItem extends ConsumerWidget {
  const _ProfileCardItem({
    required this.child,
    required this.index,
    super.key,
  });

  final ChildModel child;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stars =
        ref.watch(rewardProvider(child.id)).valueOrNull?.totalStars ?? 0;

    void goConfirm() => context.push('/confirm/${child.id}');

    return ProfileCard(
      name: child.name,
      avatarEmoji: child.avatarEmoji,
      gradientStart: _hexColor(child.avatarGradientStart),
      gradientEnd: _hexColor(child.avatarGradientEnd),
      totalStars: stars,
      isActive: child.isActiveOnDevice,
      onTap: goConfirm,
      onCountdownComplete: goConfirm,
    )
        .animate(delay: Duration(milliseconds: index * 90))
        .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut)
        .slideY(
          begin: 0.05,
          end: 0,
          duration: AppMotion.slow,
          curve: AppMotion.easeOut,
        );
  }

  static Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _SpinnerPanel extends StatelessWidget {
  const _SpinnerPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 280),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.9),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.45)),
        boxShadow: AppShadows.md,
      ),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: AppColors.green,
        strokeWidth: 3,
      ),
    );
  }
}

class _SetupRequired extends StatelessWidget {
  const _SetupRequired({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Center(
      child: _EmptyCard(
        emoji: '',
        title: 'Set up this device',
        subtitle:
            'An adult needs to log in and add child profiles before anyone can begin.',
        action: PrimaryButton(
          label: 'Parent & Teacher Sign In',
          onPressed: () => context.go('/admin/login'),
        ),
      ),
    );
  }
}

class _NoChildren extends StatelessWidget {
  const _NoChildren({required this.context});

  final BuildContext context;

  @override
  Widget build(BuildContext ctx) {
    return Center(
      child: _EmptyCard(
        emoji: '',
        title: 'No profiles yet',
        subtitle:
            'Add a child profile from the parent or teacher dashboard to get started.',
        action: SecondaryButton(
          label: 'Parent & Teacher Dashboard',
          onPressed: () => context.go('/admin/dashboard'),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: _EmptyCard(
        emoji: '',
        title: 'Something went wrong',
        subtitle: 'Check your connection and try opening the app again.',
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard({
    required this.emoji,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final Widget? action;

  IconData get _icon {
    switch (title) {
      case 'Set up this device':
        return Icons.lock_rounded;
      case 'No profiles yet':
        return Icons.person_add_alt_rounded;
      default:
        return emoji.isNotEmpty
            ? Icons.cloud_off_rounded
            : Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.95),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.5)),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 48, color: AppColors.green),
          const SizedBox(height: 16),
          Text(
            title,
            style: AppText.heading(),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: AppText.body(color: AppColors.ink2),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[
            const SizedBox(height: 24),
            action!,
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut)
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AppMotion.slow,
          curve: AppMotion.easeOut,
        );
  }
}

class _PinUnlockDialog extends ConsumerStatefulWidget {
  const _PinUnlockDialog({required this.firstName});

  final String firstName;

  @override
  ConsumerState<_PinUnlockDialog> createState() => _PinUnlockDialogState();
}

class _PinUnlockDialogState extends ConsumerState<_PinUnlockDialog> {
  final _pinCtrl = TextEditingController();
  String? _error;
  bool _verifying = false;

  @override
  void dispose() {
    _pinCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final pin = _pinCtrl.text.trim();
    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'Please enter your 4-digit PIN.');
      return;
    }

    setState(() {
      _verifying = true;
      _error = null;
    });

    final profile = await ref.read(adultProfileProvider.future);
    if (!mounted) return;

    if (profile?.pinCode == pin) {
      Navigator.of(context).pop(true);
      return;
    }

    setState(() {
      _verifying = false;
      _error = 'That PIN does not match this adult account.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
      title: Text('Unlock adult tools', style: AppText.title()),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${widget.firstName}, enter your 4-digit PIN to open the parent and teacher area.',
              style: AppText.body(color: AppColors.ink2),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinCtrl,
              autofocus: true,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              onSubmitted: (_) => _verify(),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: '4-digit PIN',
                counterText: '',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppText.caption(color: AppColors.rose),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          label: 'Cancel',
          onPressed: _verifying ? null : () => Navigator.of(context).pop(false),
        ),
        PrimaryButton(
          label: _verifying ? 'Checking...' : 'Unlock',
          onPressed: _verifying ? null : _verify,
        ),
      ],
    );
  }
}

class _CreatePinDialog extends ConsumerStatefulWidget {
  const _CreatePinDialog({required this.firstName});

  final String firstName;

  @override
  ConsumerState<_CreatePinDialog> createState() => _CreatePinDialogState();
}

class _CreatePinDialogState extends ConsumerState<_CreatePinDialog> {
  final _pinCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _pinCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final pin = _pinCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    if (!RegExp(r'^\d{4}$').hasMatch(pin)) {
      setState(() => _error = 'Choose a 4-digit PIN.');
      return;
    }

    if (confirm != pin) {
      setState(() => _error = 'The PIN confirmation does not match.');
      return;
    }

    Navigator.of(context).pop(pin);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgCard,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
      title: Text('Create your PIN', style: AppText.title()),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hi ${widget.firstName}, create a 4-digit PIN for unlocking adult tools on this shared device.',
              style: AppText.body(color: AppColors.ink2),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'New 4-digit PIN',
                counterText: '',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Confirm PIN',
                counterText: '',
                filled: true,
                fillColor: AppColors.bg,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: AppText.caption(color: AppColors.rose),
              ),
            ],
          ],
        ),
      ),
      actions: [
        SecondaryButton(
          label: 'Cancel',
          onPressed: () => Navigator.of(context).pop(),
        ),
        PrimaryButton(
          label: 'Save PIN',
          onPressed: _save,
        ),
      ],
    );
  }
}
