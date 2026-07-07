import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_text.dart';

/// Green pill button with 3D press-depth effect.
/// Normal: 3dp solid bottom shadow. Pressed: shadow collapses to 1dp + translateY +2dp.
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
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
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

// Shadow colors matching AppShadows.sm — kept here to avoid private access.
const _shadowC1 = Color(0x0F1C1917); // 6% ink
const _shadowC2 = Color(0x141C1917); // 8% ink

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  void _down(TapDownDetails _) {
    if (widget.onPressed == null) return;
    setState(() => _pressed = true);
  }

  void _up(TapUpDetails _) {
    if (!_pressed) return;
    setState(() => _pressed = false);
    widget.onPressed?.call();
  }

  void _cancel() => setState(() => _pressed = false);

  // Always 3 shadows, same list length — avoids negative blur from elasticOut overshoot.
  // Disabled / pressed states animate via color transparency, not list length change.
  List<BoxShadow> get _shadows {
    final disabled = widget.onPressed == null;
    return [
      BoxShadow(
        color: disabled ? Colors.transparent : AppColors.greenDark,
        blurRadius: 1,
        offset: Offset(0, disabled ? 3 : (_pressed ? 1 : 3)),
      ),
      BoxShadow(
        color: (disabled || _pressed) ? Colors.transparent : _shadowC2,
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
      BoxShadow(
        color: (disabled || _pressed) ? Colors.transparent : _shadowC1,
        blurRadius: 2,
        offset: const Offset(0, 1),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    return GestureDetector(
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.mid,
        curve: AppMotion.spring,
        child: AnimatedContainer(
          duration: AppMotion.mid,
          curve: AppMotion.spring,
          width: widget.width,
          transform: Matrix4.translationValues(0, _pressed ? 2.0 : 0.0, 0),
          transformAlignment: Alignment.center,
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 26),
          decoration: BoxDecoration(
            color: disabled ? AppColors.ink4 : AppColors.green,
            borderRadius: AppRadius.pill,
            boxShadow: _shadows,
          ),
          child: Row(
            mainAxisSize:
                widget.width != null ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: AppText.button(
                  color: disabled ? AppColors.ink3 : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
