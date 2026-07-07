import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';

/// Square emoji button with 3D press-depth shadow.
/// Use [AppIconButton.speak], [AppIconButton.record], [AppIconButton.star]
/// factory constructors for the standard variants.
class AppIconButton extends StatefulWidget {
  const AppIconButton({
    required this.emoji,
    this.onTap,
    this.color = AppColors.green,
    this.colorDark = AppColors.greenDark,
    this.size = 50.0,
    super.key,
  });

  /// 🔊 Speak — green
  const AppIconButton.speak({
    required VoidCallback? onTap,
    double size = 50.0,
    Key? key,
  }) : this(
          emoji: '🔊',
          onTap: onTap,
          color: AppColors.green,
          colorDark: AppColors.greenDark,
          size: size,
          key: key,
        );

  /// 🎙️ Record — rose
  const AppIconButton.record({
    required VoidCallback? onTap,
    double size = 50.0,
    Key? key,
  }) : this(
          emoji: '🎙️',
          onTap: onTap,
          color: AppColors.rose,
          colorDark: AppColors.roseDark,
          size: size,
          key: key,
        );

  /// ⭐ Star — amber
  const AppIconButton.star({
    required VoidCallback? onTap,
    double size = 50.0,
    Key? key,
  }) : this(
          emoji: '⭐',
          onTap: onTap,
          color: AppColors.amber,
          colorDark: AppColors.amberDark,
          size: size,
          key: key,
        );

  final String emoji;
  final VoidCallback? onTap;
  final Color color;
  final Color colorDark;
  final double size;

  @override
  State<AppIconButton> createState() => _AppIconButtonState();
}

class _AppIconButtonState extends State<AppIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppMotion.mid,
        curve: AppMotion.spring,
        width: widget.size,
        height: widget.size,
        transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0.0, 0),
        transformAlignment: Alignment.center,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: AppRadius.md,
          boxShadow: [
            BoxShadow(
              color: widget.colorDark,
              blurRadius: 0,
              offset: Offset(0, _pressed ? 1 : 3),
            ),
            if (!_pressed) ...AppShadows.xs,
          ],
        ),
        child: Text(
          widget.emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
