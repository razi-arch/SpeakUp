import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_text.dart';

/// Coloured progress fill. Use [ProgressBar.green], [.sky], or [.rose]
/// factory constructors for the three module colours.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    required this.value,
    this.color = AppColors.green,
    this.height = 9.0,
    this.label,
    super.key,
  }) : assert(value >= 0.0 && value <= 1.0);

  /// AAC Board progress — green
  const ProgressBar.green({
    required double value,
    String? label,
    double height = 9.0,
    Key? key,
  }) : this(
          value: value,
          color: AppColors.green,
          height: height,
          label: label,
          key: key,
        );

  /// Vocab Learning progress — sky
  const ProgressBar.sky({
    required double value,
    String? label,
    double height = 9.0,
    Key? key,
  }) : this(
          value: value,
          color: AppColors.sky,
          height: height,
          label: label,
          key: key,
        );

  /// Speech Practice progress — rose
  const ProgressBar.rose({
    required double value,
    String? label,
    double height = 9.0,
    Key? key,
  }) : this(
          value: value,
          color: AppColors.rose,
          height: height,
          label: label,
          key: key,
        );

  final double value;
  final Color color;
  final double height;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(label!, style: AppText.caption()),
          const SizedBox(height: 4),
        ],
        Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.ink5,
            borderRadius: AppRadius.pill,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: AnimatedFractionallySizedBox(
              duration: AppMotion.slow,
              curve: AppMotion.easeOut,
              widthFactor: value.clamp(0.0, 1.0),
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
      ],
    );
  }
}
