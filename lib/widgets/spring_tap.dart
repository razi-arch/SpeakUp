import 'package:flutter/material.dart';
import '../theme/app_motion.dart';

class SpringTap extends StatefulWidget {
  const SpringTap({required this.child, this.onTap, super.key});
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<SpringTap> createState() => _SpringTapState();
}

class _SpringTapState extends State<SpringTap> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: AppMotion.mid,
        curve: AppMotion.spring,
        child: widget.child,
      ),
    );
  }
}
