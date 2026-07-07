import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';
import 'spring_tap.dart';

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    required this.label,
    this.onPressed,
    this.icon,
    this.width,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onPressed,
      child: Container(
        width: width,
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.pill,
          border: Border.all(color: AppColors.ink4, width: 1.5),
          boxShadow: AppShadows.xs,
        ),
        child: Row(
          mainAxisSize:
              width != null ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              icon!,
              const SizedBox(width: 8),
            ],
            Text(label, style: AppText.button(color: AppColors.ink)),
          ],
        ),
      ),
    );
  }
}
