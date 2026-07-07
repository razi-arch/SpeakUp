import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_text.dart';
import 'spring_tap.dart';
import 'vocab_image.dart';

/// AAC grid tile — 80×80dp minimum (hard constraint for motor accessibility).
class SymbolCard extends StatelessWidget {
  const SymbolCard({
    required this.emoji,
    required this.label,
    this.imageUrl,
    this.localImagePath,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String emoji;
  final String label;
  final String? imageUrl;
  final String? localImagePath;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.spring,
        constraints: const BoxConstraints(minWidth: 80, minHeight: 80),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.greenLight : AppColors.bgCard,
          borderRadius: AppRadius.md,
          border: Border.all(
            color: selected ? AppColors.greenMid : AppColors.ink4,
            width: 1.5,
          ),
          // Same length list; second shadow goes transparent when not selected
          // to avoid negative blur from elasticOut overshoot during lerp.
          boxShadow: [
            BoxShadow(
              color: selected
                  ? const Color(0x141C1917)
                  : const Color(0x0F1C1917),
              blurRadius: selected ? 20 : 2,
              offset: selected ? const Offset(0, 4) : const Offset(0, 1),
            ),
            BoxShadow(
              color: selected
                  ? const Color(0x0F1C1917)
                  : Colors.transparent,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _SymbolVisual(
              emoji: emoji,
              imageUrl: imageUrl,
              localImagePath: localImagePath,
              selected: selected,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.symbolLabel(),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _SymbolVisual extends StatelessWidget {
  const _SymbolVisual({
    required this.emoji,
    required this.imageUrl,
    required this.localImagePath,
    required this.selected,
  });

  final String emoji;
  final String? imageUrl;
  final String? localImagePath;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return VocabImage(
      localImagePath: localImagePath,
      imageUrl: imageUrl,
      width: 44,
      height: 44,
      borderRadius: AppRadius.sm,
      fallback: _EmojiOrIconFallback(
        emoji: emoji,
        selected: selected,
      ),
    );
  }
}

class _EmojiOrIconFallback extends StatelessWidget {
  const _EmojiOrIconFallback({
    required this.emoji,
    required this.selected,
  });

  final String emoji;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isNotEmpty) {
      return Text(trimmedEmoji, style: const TextStyle(fontSize: 30));
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? Colors.white : AppColors.bgRaised,
        borderRadius: AppRadius.sm,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        color: AppColors.ink3,
        size: 22,
      ),
    );
  }
}
