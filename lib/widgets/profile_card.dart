import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';
import 'countdown_bar.dart';
import 'spring_tap.dart';

/// Child profile card for the Profile Picker screen.
///
/// Active card: pulsing green ring + countdown bar that auto-selects after
/// [countdownDuration]. Inactive card: softened opacity + neutral border.
/// Tapping either state always routes to the confirmation screen.
class ProfileCard extends StatefulWidget {
  const ProfileCard({
    required this.name,
    required this.avatarEmoji,
    required this.gradientStart,
    required this.gradientEnd,
    required this.totalStars,
    required this.isActive,
    required this.onTap,
    this.countdownDuration = const Duration(seconds: 3),
    this.onCountdownComplete,
    super.key,
  });

  final String name;
  final String avatarEmoji;
  final Color gradientStart;
  final Color gradientEnd;
  final int totalStars;
  final bool isActive;
  final VoidCallback onTap;
  final Duration countdownDuration;
  final VoidCallback? onCountdownComplete;

  @override
  State<ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends State<ProfileCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _pulseAnim = CurvedAnimation(parent: _pulse, curve: Curves.easeInOut);
    if (widget.isActive) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ProfileCard old) {
    super.didUpdateWidget(old);
    if (widget.isActive == old.isActive) return;
    if (widget.isActive) {
      _pulse.repeat(reverse: true);
    } else {
      _pulse
        ..stop()
        ..reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: widget.onTap,
      child: AnimatedOpacity(
        opacity: widget.isActive ? 1.0 : 0.72,
        duration: AppMotion.mid,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            final glow = _pulseAnim.value;
            return Container(
              width: 156,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFFCF8),
                    AppColors.bgCard,
                  ],
                ),
                borderRadius: AppRadius.xl,
                border: Border.all(
                  color: widget.isActive
                      ? AppColors.green.withValues(alpha: 0.9)
                      : AppColors.ink4.withValues(alpha: 0.8),
                  width: 2,
                ),
                boxShadow: [
                  if (widget.isActive)
                    BoxShadow(
                      color: AppColors.green.withValues(
                        alpha: 0.12 + (glow * 0.24),
                      ),
                      blurRadius: 4 + (glow * 18),
                      spreadRadius: glow * 3,
                    ),
                  ...AppShadows.md,
                ],
              ),
              child: child,
            );
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 18, 14, 10),
                child: _Avatar(
                  emoji: widget.avatarEmoji,
                  gradientStart: widget.gradientStart,
                  gradientEnd: widget.gradientEnd,
                ),
              ),
              Text(
                widget.name,
                style: AppText.title(),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.amberLight,
                  borderRadius: AppRadius.pill,
                  border: Border.all(
                    color: AppColors.amberMid.withValues(alpha: 0.7),
                  ),
                ),
                child: Text(
                  '⭐ ${widget.totalStars} stars',
                  style: AppText.caption(color: AppColors.amberDark),
                ),
              ),
              if (widget.isActive) ...[
                const SizedBox(height: 12),
                Text(
                  'Starting soon',
                  style: AppText.caption(color: AppColors.greenDark),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
                  child: CountdownBar(
                    key: ValueKey(widget.isActive),
                    duration: widget.countdownDuration,
                    onComplete: () {
                      if (mounted) {
                        (widget.onCountdownComplete ?? widget.onTap).call();
                      }
                    },
                  ),
                ),
              ] else
                const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
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
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppShadows.sm,
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 36)),
    );
  }
}
