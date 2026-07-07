import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Linear countdown from 100% → 0% width over [duration].
/// Uses Curves.linear — the only sanctioned place in the design system.
/// Pass a [ValueKey] tied to the active state at the call site so the
/// animation restarts whenever the card becomes active again.
class CountdownBar extends StatelessWidget {
  const CountdownBar({
    this.duration = const Duration(seconds: 3),
    required this.onComplete,
    this.color = AppColors.green,
    this.height = 4.0,
    super.key,
  });

  final Duration duration;
  final VoidCallback onComplete;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 1.0, end: 0.0),
      duration: duration,
      curve: Curves.linear,
      onEnd: onComplete,
      builder: (context, value, child) => Container(
        height: height,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.ink5,
          borderRadius: AppRadius.pill,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: value,
            heightFactor: 1.0,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.pill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
