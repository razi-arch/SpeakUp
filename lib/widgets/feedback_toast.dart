import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_text.dart';

/// Shows a floating correct/wrong toast above all content.
/// Usage: FeedbackToast.show(context, message: 'Correct!', isCorrect: true);
class FeedbackToast {
  FeedbackToast._();

  static void show(
    BuildContext context, {
    required String message,
    required bool isCorrect,
    Duration duration = const Duration(milliseconds: 1800),
  }) {
    OverlayEntry? entry;
    entry = OverlayEntry(
      builder: (_) => _ToastOverlay(
        message: message,
        isCorrect: isCorrect,
        duration: duration,
        onDismiss: () => entry?.remove(),
      ),
    );
    Overlay.of(context).insert(entry);
  }
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.isCorrect,
    required this.duration,
    required this.onDismiss,
  });

  final String message;
  final bool isCorrect;
  final Duration duration;
  final VoidCallback onDismiss;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  Timer? _dismiss;

  @override
  void initState() {
    super.initState();
    _dismiss = Timer(
      widget.duration,
      widget.onDismiss,
    );
  }

  @override
  void dispose() {
    _dismiss?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 24),
            child: _buildChip()
                .animate()
                .fadeIn(
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOut,
                )
                .slideY(
                  begin: 0.15,
                  end: 0,
                  duration: AppMotion.fast,
                  curve: AppMotion.easeOut,
                ),
          ),
        ),
      ),
    );
  }

  Widget _buildChip() {
    final isCorrect = widget.isCorrect;
    final bg = isCorrect ? AppColors.greenLight : AppColors.roseLight;
    final border = isCorrect ? AppColors.greenMid : AppColors.roseMid;
    final fg = isCorrect ? AppColors.green : AppColors.rose;
    final emoji = isCorrect ? '✅' : '❌';

    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.pill,
          border: Border.all(color: border, width: 1.5),
          boxShadow: AppShadows.md,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 8),
            Text(widget.message, style: AppText.button(color: fg)),
          ],
        ),
      ),
    );
  }
}
