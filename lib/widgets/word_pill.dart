import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text.dart';

/// Sentence bar word chip. Supply [onRemove] to show a dismiss ×.
class WordPill extends StatelessWidget {
  const WordPill({
    required this.word,
    this.onRemove,
    super.key,
  });

  final String word;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(10, 4, onRemove != null ? 2 : 10, 4),
      decoration: BoxDecoration(
        color: AppColors.greenLight,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.greenMid, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(word, style: AppText.symbolLabel(color: AppColors.green)),
          if (onRemove != null)
            GestureDetector(
              onTap: onRemove,
              behavior: HitTestBehavior.opaque,
              // 32×32 tap target around a 16px icon — small visuals stay
              // tappable for kids with motor-control difficulties.
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: AppColors.green,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
