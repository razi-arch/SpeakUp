import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/child_provider.dart';
import '../../providers/reward_provider.dart';
import '../../services/reward_logic.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/primary_button.dart';

const _confettiColors = [
  AppColors.amber,
  AppColors.green,
  AppColors.sky,
  AppColors.rose,
  AppColors.amberMid,
  AppColors.greenMid,
  AppColors.skyMid,
  AppColors.roseMid,
];

class RewardScreen extends ConsumerStatefulWidget {
  const RewardScreen({super.key});

  @override
  ConsumerState<RewardScreen> createState() => _RewardScreenState();
}

class _RewardScreenState extends ConsumerState<RewardScreen> {
  late final ConfettiController _confetti;
  late final SessionRewardSummary _sessionReward;

  static const _bg = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.amberLight, AppColors.greenLight],
    ),
  );

  @override
  void initState() {
    super.initState();
    _sessionReward =
        ref.read(pendingRewardSummaryProvider) ??
        const SessionRewardSummary(
          module: 'general',
          earnedStars: 0,
          accuracy: null,
          questionCount: 0,
          correctCount: 0,
        );
    _confetti = ConfettiController(duration: const Duration(seconds: 5));
    if (!_sessionReward.pendingReview && _sessionReward.earnedStars > 0) {
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) _confetti.play();
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(pendingRewardSummaryProvider.notifier).state = null;
      _awardStarsAndUnlockBadges();
    });
  }

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  Future<void> _awardStarsAndUnlockBadges() async {
    final child = ref.read(activeChildProvider);
    if (child == null || _sessionReward.earnedStars <= 0) return;

    final rewardRef = FirebaseFirestore.instance.collection('rewards').doc(child.id);
    final currentReward = ref.read(rewardProvider(child.id)).valueOrNull;
    final currentStars = currentReward?.totalStars ?? 0;
    final currentBadges = currentReward?.badges ?? const <String>[];

    await rewardRef.set(
      {'totalStars': FieldValue.increment(_sessionReward.earnedStars)},
      SetOptions(merge: true),
    );

    if (!mounted) return;

    final newTotal = currentStars + _sessionReward.earnedStars;
    final newBadges = unlockedBadgeIds(
      previousStars: currentStars,
      newTotalStars: newTotal,
      existingBadges: currentBadges,
    );

    if (newBadges.isNotEmpty) {
      await rewardRef.update({'badges': FieldValue.arrayUnion(newBadges)});
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    if (child == null) {
      final ctx = context;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (ctx.mounted) ctx.go('/');
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final reward = ref.watch(rewardProvider(child.id)).valueOrNull;
    final pendingReview = _sessionReward.pendingReview;
    final title = pendingReview ? 'Recording sent' : 'Great job!';
    final subtitle = pendingReview
        ? 'A parent or teacher will review this speech practice soon.'
        : "You're a star learner today";

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _bg,
        child: Stack(
          children: [
            if (!pendingReview && _sessionReward.earnedStars > 0)
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.04,
                  emissionFrequency: 0.06,
                  numberOfParticles: 22,
                  gravity: 0.14,
                  colors: _confettiColors,
                  maximumSize: const Size(12, 6),
                  minimumSize: const Size(5, 2),
                ),
              ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _HeroIcon(pendingReview: pendingReview),
                        const SizedBox(height: 20),
                        Text(title, style: AppText.display())
                            .animate()
                            .fadeIn(
                              delay: 200.ms,
                              duration: AppMotion.slow,
                              curve: AppMotion.easeOut,
                            )
                            .slideY(
                              begin: 0.04,
                              end: 0,
                              delay: 200.ms,
                              duration: AppMotion.slow,
                              curve: AppMotion.easeOut,
                            ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: AppText.body(color: AppColors.ink2),
                          textAlign: TextAlign.center,
                        ).animate().fadeIn(
                              delay: 350.ms,
                              duration: AppMotion.slow,
                              curve: AppMotion.easeOut,
                            ),
                        const SizedBox(height: 28),
                        if (!pendingReview && _sessionReward.earnedStars > 0) ...[
                          _SessionStars(count: _sessionReward.earnedStars),
                          const SizedBox(height: 16),
                        ],
                        _TotalCounter(
                          totalStars: reward?.totalStars ?? 0,
                          pendingReview: pendingReview,
                        ),
                        const SizedBox(height: 12),
                        _SessionSummary(summary: _sessionReward),
                        if (!pendingReview &&
                            reward != null &&
                            reward.badges.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          _BadgesRow(badges: reward.badges),
                        ],
                        const SizedBox(height: 36),
                        PrimaryButton(
                          label: pendingReview ? 'Back to home' : 'Keep it up! →',
                          width: 260,
                          onPressed: () => context.go('/child/home'),
                        )
                            .animate()
                            .fadeIn(
                              delay: 900.ms,
                              duration: AppMotion.slow,
                              curve: AppMotion.easeOut,
                            )
                            .slideY(
                              begin: 0.06,
                              end: 0,
                              delay: 900.ms,
                              duration: AppMotion.slow,
                              curve: AppMotion.easeOut,
                            ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroIcon extends StatefulWidget {
  const _HeroIcon({required this.pendingReview});

  final bool pendingReview;

  @override
  State<_HeroIcon> createState() => _HeroIconState();
}

class _HeroIconState extends State<_HeroIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _float;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _float = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final icon = widget.pendingReview
        ? Icons.mark_email_read_rounded
        : Icons.emoji_events_rounded;
    final iconColor = widget.pendingReview ? AppColors.skyDark : AppColors.amberDark;

    return AnimatedBuilder(
      animation: _float,
      builder: (_, child) => Transform.translate(
        offset: Offset(0, _float.value * -10),
        child: child,
      ),
      child: Container(
        width: 108,
        height: 108,
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.72),
          shape: BoxShape.circle,
          boxShadow: AppShadows.md,
        ),
        alignment: Alignment.center,
        child: Icon(icon, size: 56, color: iconColor),
      ).animate().scale(
            begin: const Offset(0, 0),
            duration: const Duration(milliseconds: 450),
            curve: Curves.elasticOut,
          ),
    );
  }
}

class _SessionStars extends StatelessWidget {
  const _SessionStars({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < count; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: const Text('⭐', style: TextStyle(fontSize: 34))
                .animate(delay: Duration(milliseconds: 500 + i * 110))
                .scale(
                  begin: const Offset(0, 0),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.elasticOut,
                ),
          ),
      ],
    );
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.summary});

  final SessionRewardSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = summary.pendingReview
        ? 'Your speech recording is saved and waiting for evaluation.'
        : summary.questionCount > 0
            ? '${summary.correctCount}/${summary.questionCount} correct • ${((summary.accuracy ?? 0.0) * 100).round()}% accuracy'
            : 'Session complete';

    return Text(
      text,
      style: AppText.body(color: AppColors.ink2),
      textAlign: TextAlign.center,
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 1120),
          duration: AppMotion.mid,
          curve: AppMotion.easeOut,
        );
  }
}

class _TotalCounter extends StatelessWidget {
  const _TotalCounter({
    required this.totalStars,
    required this.pendingReview,
  });

  final int totalStars;
  final bool pendingReview;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.amberLight,
        borderRadius: AppRadius.pill,
        border: Border.all(color: AppColors.amberMid, width: 1.5),
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('⭐', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            pendingReview
                ? '$totalStars total stars so far'
                : '$totalStars total stars',
            style: AppText.button(color: AppColors.amberDark),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: const Duration(milliseconds: 1050),
          duration: AppMotion.mid,
          curve: AppMotion.easeOut,
        )
        .slideY(
          begin: 0.05,
          end: 0,
          delay: const Duration(milliseconds: 1050),
          duration: AppMotion.mid,
          curve: AppMotion.easeOut,
        );
  }
}

class _BadgesRow extends StatelessWidget {
  const _BadgesRow({required this.badges});

  final List<String> badges;

  @override
  Widget build(BuildContext context) {
    final ordered = badgeMilestones.values.where((id) => badges.contains(id)).toList();

    return Column(
      children: [
        Text('Badges earned', style: AppText.title()),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < ordered.length; i++)
              _BadgeChip(badgeId: ordered[i], index: i),
          ],
        ),
      ],
    ).animate().fadeIn(
          delay: const Duration(milliseconds: 1200),
          duration: AppMotion.slow,
          curve: AppMotion.easeOut,
        );
  }
}

class _BadgeChip extends StatelessWidget {
  const _BadgeChip({required this.badgeId, required this.index});

  final String badgeId;
  final int index;

  @override
  Widget build(BuildContext context) {
    final data = badgeData[badgeId];
    if (data == null) return const SizedBox.shrink();
    final (emoji, label) = data;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.amberMid, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 8),
          Text(label, style: AppText.caption()),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 1200 + index * 80))
        .scale(
          begin: const Offset(0, 0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
        );
  }
}
