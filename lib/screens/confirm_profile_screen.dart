import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/child_model.dart';
import '../providers/child_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';
import '../widgets/primary_button.dart';

class ConfirmProfileScreen extends ConsumerWidget {
  const ConfirmProfileScreen({required this.childId, super.key});

  final String childId;

  static const _bg = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF2FAF6), AppColors.bg, Color(0xFFFFF8EE)],
      stops: [0.0, 0.55, 1.0],
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(linkedChildrenProvider);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _bg,
        child: SafeArea(
          child: Stack(
            children: [
              const _BackgroundShapes(),
              const _GoBackLink(),
              Center(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 72, 20, 20),
                  child: childrenAsync.when(
                    loading: () => const CircularProgressIndicator(
                      color: AppColors.green,
                      strokeWidth: 3,
                    ),
                    error: (error, stackTrace) => Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard.withValues(alpha: 0.95),
                        borderRadius: AppRadius.xl,
                        boxShadow: AppShadows.md,
                      ),
                      child: Text(
                        'Something went wrong',
                        style: AppText.body(),
                      ),
                    ),
                    data: (children) {
                      final child = _findChild(children, childId);
                      if (child == null) {
                        return Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.bgCard.withValues(alpha: 0.95),
                            borderRadius: AppRadius.xl,
                            boxShadow: AppShadows.md,
                          ),
                          child: Text(
                            'Profile not found',
                            style: AppText.body(color: AppColors.ink3),
                          ),
                        );
                      }
                      return _ConfirmBody(child: child);
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static ChildModel? _findChild(List<ChildModel> children, String id) {
    for (final child in children) {
      if (child.id == id) return child;
    }
    return null;
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
            right: -24,
            child: _GlowCircle(
              size: 220,
              colors: [
                AppColors.amberLight.withValues(alpha: 0.9),
                AppColors.amber.withValues(alpha: 0.04),
              ],
            ),
          ),
          Positioned(
            top: 190,
            left: -90,
            child: _GlowCircle(
              size: 240,
              colors: [
                AppColors.skyLight.withValues(alpha: 0.84),
                AppColors.sky.withValues(alpha: 0.04),
              ],
            ),
          ),
          Positioned(
            bottom: -90,
            right: 110,
            child: _GlowCircle(
              size: 250,
              colors: [
                AppColors.greenLight.withValues(alpha: 0.8),
                AppColors.green.withValues(alpha: 0.04),
              ],
            ),
          ),
          const Positioned(
            top: 118,
            left: 62,
            child: _SoftDot(size: 16, color: AppColors.amberMid),
          ),
          const Positioned(
            top: 168,
            right: 132,
            child: _SoftDot(size: 12, color: AppColors.skyMid),
          ),
          const Positioned(
            bottom: 138,
            left: 94,
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

class _ConfirmBody extends ConsumerWidget {
  const _ConfirmBody({required this.child});

  final ChildModel child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 460),
      child: Container(
        padding: const EdgeInsets.fromLTRB(30, 34, 30, 30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFFFFCF5),
              AppColors.bgCard,
              Color(0xFFF3FAF6),
            ],
          ),
          borderRadius: AppRadius.xl,
          border: Border.all(color: AppColors.ink4.withValues(alpha: 0.45)),
          boxShadow: AppShadows.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.greenLight,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                'Almost ready',
                style: AppText.caption(color: AppColors.greenDark),
              ),
            ),
            const SizedBox(height: 22),
            _BigAvatar(
              emoji: child.avatarEmoji,
              gradientStart: _hexColor(child.avatarGradientStart),
              gradientEnd: _hexColor(child.avatarGradientEnd),
            ),
            const SizedBox(height: 22),
            Text(
              child.name,
              style: AppText.display(),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Is this you?',
              style: AppText.heading(color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap the green button if this is your picture.',
              style: AppText.body(color: AppColors.ink2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 30),
            PrimaryButton(
              label: "Yes, let's start",
              width: 280,
              onPressed: () {
                ref.read(activeChildProvider.notifier).state = child;
                final currentContext = context;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (currentContext.mounted) {
                    currentContext.go('/child/home');
                  }
                });
              },
            ),
          ],
        ),
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

  static Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _BigAvatar extends StatelessWidget {
  const _BigAvatar({
    required this.emoji,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 132,
      height: 132,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.lg,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 58)),
    );
  }
}

class _GoBackLink extends StatelessWidget {
  const _GoBackLink();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 12,
      child: GestureDetector(
        onTap: () => context.canPop() ? context.pop() : context.go('/'),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
          decoration: BoxDecoration(
            color: AppColors.bgCard.withValues(alpha: 0.8),
            borderRadius: AppRadius.pill,
            border: Border.all(color: AppColors.ink4.withValues(alpha: 0.4)),
            boxShadow: AppShadows.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: AppColors.ink3,
              ),
              const SizedBox(width: 6),
              Text(
                'Back',
                style: AppText.caption(color: AppColors.ink3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
