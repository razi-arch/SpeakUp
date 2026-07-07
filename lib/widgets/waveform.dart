import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Animated waveform for speech recording visualisation.
/// Bars animate scaleY 0.25→1 with 100ms stagger when [isActive].
/// Inactive state shows short, dimmed bars.
class Waveform extends StatelessWidget {
  const Waveform({
    this.isActive = false,
    this.barCount = 5,
    this.color = AppColors.rose,
    this.barHeight = 32.0,
    this.barWidth = 4.0,
    super.key,
  });

  final bool isActive;
  final int barCount;
  final Color color;
  final double barHeight;
  final double barWidth;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: List.generate(
        barCount,
        (i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: _WaveBar(
            index: i,
            isActive: isActive,
            color: color,
            height: barHeight,
            width: barWidth,
          ),
        ),
      ),
    );
  }
}

class _WaveBar extends StatelessWidget {
  const _WaveBar({
    required this.index,
    required this.isActive,
    required this.color,
    required this.height,
    required this.width,
  });

  final int index;
  final bool isActive;
  final Color color;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return Container(
        width: width,
        height: height * 0.25,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.3),
          borderRadius: AppRadius.pill,
        ),
      );
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: AppRadius.pill,
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleY(
          begin: 0.25,
          end: 1.0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOut,
          delay: Duration(milliseconds: index * 100),
        );
  }
}
