import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../models/reward_model.dart';
import '../../models/session_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/spring_tap.dart';

class ChildHomeScreen extends ConsumerWidget {
  const ChildHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final child = ref.watch(activeChildProvider);
    final adultProfile = ref.watch(adultProfileProvider).valueOrNull;
    final signedInUser =
        ref.watch(authStateProvider).valueOrNull ??
        ref.read(authServiceProvider).user;

    if (child == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: SizedBox.shrink(),
      );
    }

    final rewardAsync = ref.watch(rewardProvider(child.id));
    final recentAsync = ref.watch(recentSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 1080;
            final sideColumn = Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ReviewAccountCard(
                  adultName:
                      adultProfile?.fullName.trim().isNotEmpty == true
                          ? adultProfile!.fullName.trim()
                          : (signedInUser?.email ?? 'Parent / Teacher'),
                  roleLabel:
                      adultProfile?.role.trim().isNotEmpty == true
                          ? adultProfile!.role
                          : 'review account',
                ),
                const SizedBox(height: 18),
                _ProgressSummaryCard(rewardAsync: rewardAsync),
                const SizedBox(height: 18),
                _ActivityCard(recentAsync: recentAsync),
                const SizedBox(height: 18),
                _SwitchProfilesCard(
                  onTap: () {
                    ref.read(adultAccessUnlockedProvider.notifier).state = false;
                    ref.read(activeChildProvider.notifier).state = null;
                    context.go('/');
                  },
                ),
              ],
            );

            return Stack(
              children: [
                const _BackgroundShapes(),
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1220),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _HeroCard(
                            childName: child.name,
                            rewardAsync: rewardAsync,
                            recentAsync: recentAsync,
                          )
                              .animate()
                              .fadeIn(
                                duration: AppMotion.slow,
                                curve: AppMotion.easeOut,
                              )
                              .slideY(
                                begin: 0.03,
                                end: 0,
                                duration: AppMotion.slow,
                                curve: AppMotion.easeOut,
                              ),
                          const SizedBox(height: 20),
                          if (isWide)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: const _ModuleSection(),
                                ),
                                const SizedBox(width: 20),
                                Expanded(flex: 2, child: sideColumn),
                              ],
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const _ModuleSection(),
                                const SizedBox(height: 20),
                                sideColumn,
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BackgroundShapes extends StatelessWidget {
  const _BackgroundShapes();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -40,
            child: _GlowCircle(
              size: 220,
              colors: [
                AppColors.amberLight,
                AppColors.amber.withValues(alpha: 0.08),
              ],
            ),
          ),
          Positioned(
            top: 180,
            left: -90,
            child: _GlowCircle(
              size: 240,
              colors: [
                AppColors.skyLight,
                AppColors.sky.withValues(alpha: 0.07),
              ],
            ),
          ),
          Positioned(
            bottom: -100,
            right: 90,
            child: _GlowCircle(
              size: 260,
              colors: [
                AppColors.greenLight,
                AppColors.green.withValues(alpha: 0.06),
              ],
            ),
          ),
          const Positioned(
            top: 94,
            left: 42,
            child: _SoftDot(size: 18, color: AppColors.amberMid),
          ),
          const Positioned(
            top: 136,
            right: 120,
            child: _SoftDot(size: 12, color: AppColors.skyMid),
          ),
          const Positioned(
            bottom: 160,
            left: 88,
            child: _SoftDot(size: 14, color: AppColors.greenMid),
          ),
          const Positioned(
            bottom: 110,
            right: 56,
            child: _SoftDot(size: 10, color: AppColors.amberMid),
          ),
        ],
      ),
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle({
    required this.size,
    required this.colors,
  });

  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: colors),
      ),
    );
  }
}

class _SoftDot extends StatelessWidget {
  const _SoftDot({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.55),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.childName,
    required this.rewardAsync,
    required this.recentAsync,
  });

  final String childName;
  final AsyncValue<RewardModel?> rewardAsync;
  final AsyncValue<List<SessionModel>> recentAsync;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final reward = rewardAsync.valueOrNull;
    final recent = recentAsync.valueOrNull ?? const <SessionModel>[];
    final stars = reward?.totalStars ?? 0;
    final badges = reward?.badges.length ?? 0;
    final practicedToday = recent
        .where((session) => _isSameDay(session.timestamp, DateTime.now()))
        .length;

    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDF7EE),
            AppColors.bgCard,
            Color(0xFFF3FAF6),
          ],
        ),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.45)),
        boxShadow: AppShadows.lg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 860;

          return Stack(
            children: [
              Positioned(
                top: -18,
                right: compact ? -20 : 160,
                child: _GlowCircle(
                  size: compact ? 120 : 150,
                  colors: [
                    AppColors.amberLight.withValues(alpha: 0.85),
                    AppColors.amber.withValues(alpha: 0.03),
                  ],
                ),
              ),
              Positioned(
                bottom: -24,
                left: -8,
                child: _GlowCircle(
                  size: compact ? 110 : 140,
                  colors: [
                    AppColors.skyLight.withValues(alpha: 0.8),
                    AppColors.sky.withValues(alpha: 0.02),
                  ],
                ),
              ),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width:
                        compact ? constraints.maxWidth : constraints.maxWidth * 0.58,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.greenLight,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Text(
                            'Today\'s learning adventure',
                            style: AppText.caption(color: AppColors.greenDark),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$_greeting, $childName!',
                          style: AppText.display(),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'What would you like to practice today?',
                          style: AppText.body(color: AppColors.ink2),
                        ),
                        const SizedBox(height: 18),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _StatPill(
                              label: '$stars stars',
                              accent: AppColors.amberDark,
                              background: AppColors.amberLight,
                              icon: Icons.star_rounded,
                            ),
                            _StatPill(
                              label: '$badges badges',
                              accent: AppColors.greenDark,
                              background: AppColors.greenLight,
                              icon: Icons.workspace_premium_rounded,
                            ),
                            _StatPill(
                              label: '$practicedToday today',
                              accent: AppColors.skyDark,
                              background: AppColors.skyLight,
                              icon: Icons.today_rounded,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width:
                        compact ? constraints.maxWidth : constraints.maxWidth * 0.32,
                    child: _HeroSidePanel(
                      stars: stars,
                      badges: badges,
                      compact: compact,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _HeroSidePanel extends StatelessWidget {
  const _HeroSidePanel({
    required this.stars,
    required this.badges,
    required this.compact,
  });

  final int stars;
  final int badges;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MascotGreetingCard(),
        SizedBox(height: compact ? 14 : 16),
        _RewardPeekCard(
          stars: stars,
          badges: badges,
        ),
      ],
    );
  }
}

class _ReviewAccountCard extends StatelessWidget {
  const _ReviewAccountCard({
    required this.adultName,
    required this.roleLabel,
  });

  final String adultName;
  final String roleLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.94),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.6)),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: AppRadius.lg,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.verified_user_rounded,
              color: AppColors.greenDark,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Review account connected', style: AppText.title()),
                const SizedBox(height: 4),
                Text(
                  adultName,
                  style: AppText.body(color: AppColors.ink2),
                ),
                const SizedBox(height: 2),
                Text(
                  'Speech recordings will be sent to this $roleLabel.',
                  style: AppText.caption(color: AppColors.ink3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.accent,
    required this.background,
    required this.icon,
  });

  final String label;
  final Color accent;
  final Color background;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.pill,
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        boxShadow: AppShadows.xs,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Text(label, style: AppText.button(color: accent)),
        ],
      ),
    );
  }
}

class _MascotGreetingCard extends StatefulWidget {
  const _MascotGreetingCard();

  @override
  State<_MascotGreetingCard> createState() => _MascotGreetingCardState();
}

class _MascotGreetingCardState extends State<_MascotGreetingCard> {
  static const _videoPath = 'assets/mascot/home_greeting.mp4';

  late final VideoPlayerController _controller;
  bool _finishedGreeting = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(_videoPath)
      ..setLooping(false)
      ..setVolume(0)
      ..addListener(_handleVideoTick);

    _controller.initialize().then((_) async {
      if (!mounted) return;
      await _controller.play();
      setState(() {});
    });
  }

  void _handleVideoTick() {
    if (!_controller.value.isInitialized || _finishedGreeting) return;

    final duration = _controller.value.duration;
    final position = _controller.value.position;
    if (duration > Duration.zero &&
        position >= duration - const Duration(milliseconds: 120)) {
      _finishedGreeting = true;
      _controller.pause();
      if (mounted) setState(() {});
    }
  }

  Future<void> _replayGreeting() async {
    if (!_controller.value.isInitialized) return;
    _finishedGreeting = false;
    await _controller.seekTo(Duration.zero);
    await _controller.play();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_handleVideoTick)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isReady = _controller.value.isInitialized;
    final showReplayHint =
        isReady && !_controller.value.isPlaying && _controller.value.position > Duration.zero;
    final aspectRatio = isReady
        ? _controller.value.aspectRatio.clamp(0.85, 1.25)
        : 1.0;

    return SpringTap(
      onTap: isReady ? _replayGreeting : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF4F8FF),
              Color(0xFFFFFBF4),
            ],
          ),
          borderRadius: AppRadius.xl,
          border: Border.all(color: AppColors.ink4.withValues(alpha: 0.55)),
          boxShadow: AppShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.skyLight,
                borderRadius: AppRadius.pill,
              ),
              child: Text(
                'Mascot hello',
                style: AppText.caption(color: AppColors.skyDark),
              ),
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: AppRadius.lg,
              child: ColoredBox(
                color: AppColors.bgCard.withValues(alpha: 0.96),
                child: AspectRatio(
                  aspectRatio: aspectRatio,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.skyLight.withValues(alpha: 0.42),
                                AppColors.amberLight.withValues(alpha: 0.2),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (isReady)
                        Positioned.fill(
                          child: FittedBox(
                            fit: BoxFit.contain,
                            child: SizedBox(
                              width: _controller.value.size.width,
                              height: _controller.value.size.height,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        )
                      else
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 62,
                              height: 62,
                              decoration: BoxDecoration(
                                color: AppColors.greenLight,
                                borderRadius: AppRadius.xl,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.waving_hand_rounded,
                                color: AppColors.greenDark,
                                size: 30,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Getting the mascot ready...',
                              style: AppText.caption(color: AppColors.ink2),
                            ),
                          ],
                        ),
                      if (showReplayHint)
                        Positioned(
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard.withValues(alpha: 0.92),
                              borderRadius: AppRadius.pill,
                              boxShadow: AppShadows.xs,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.replay_rounded,
                                  size: 15,
                                  color: AppColors.skyDark,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Tap to say hello again',
                                  style: AppText.caption(color: AppColors.skyDark),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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

class _RewardPeekCard extends StatelessWidget {
  const _RewardPeekCard({
    required this.stars,
    required this.badges,
  });

  final int stars;
  final int badges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.amberLight, Color(0xFFFFFCF5)],
        ),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.amberMid, width: 1.5),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: AppRadius.lg,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.emoji_events_rounded,
              color: AppColors.amberDark,
              size: 28,
            ),
          ),
          const SizedBox(height: 18),
          Text('Star corner', style: AppText.title()),
          const SizedBox(height: 6),
          Text(
            'A soft little snapshot of the stars and badges you have earned so far.',
            style: AppText.body(color: AppColors.ink2),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: 'Stars',
                  value: '$stars',
                  accent: AppColors.amberDark,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniStat(
                  label: 'Badges',
                  value: '$badges',
                  accent: AppColors.greenDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.8),
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption(color: AppColors.ink2)),
          const SizedBox(height: 4),
          Text(value, style: AppText.heading(color: accent)),
        ],
      ),
    );
  }
}

class _ModuleSection extends StatelessWidget {
  const _ModuleSection();

  static final _modules = [
    _HomeModule(
      icon: Icons.record_voice_over_rounded,
      title: 'AAC Board',
      subtitle: 'Tap symbols to build words and little sentences.',
      hint: 'Speak with symbols',
      accent: AppColors.sky,
      softColor: AppColors.skyLight,
      route: '/child/aac',
    ),
    _HomeModule(
      icon: Icons.auto_stories_rounded,
      title: 'Vocab Learning',
      subtitle: 'Learn new words with friendly pictures and calm repetition.',
      hint: 'Grow your word bank',
      accent: AppColors.amber,
      softColor: AppColors.amberLight,
      route: '/child/vocab',
    ),
    _HomeModule(
      icon: Icons.mic_rounded,
      title: 'Speech Practice',
      subtitle: 'Record your voice and practice brave, steady speaking.',
      hint: 'Practice out loud',
      accent: AppColors.rose,
      softColor: AppColors.roseLight,
      route: '/child/speech',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.92),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.6)),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose an activity', style: AppText.heading()),
          const SizedBox(height: 6),
          Text(
            'Pick one gentle learning adventure to begin.',
            style: AppText.body(color: AppColors.ink2),
          ),
          const SizedBox(height: 18),
          Column(
            children: [
              for (var index = 0; index < _modules.length; index++) ...[
                _ModuleCard(module: _modules[index])
                    .animate(delay: Duration(milliseconds: 80 + (index * 80)))
                    .fadeIn(
                      duration: AppMotion.slow,
                      curve: AppMotion.easeOut,
                    )
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: AppMotion.slow,
                      curve: AppMotion.easeOut,
                    ),
                if (index != _modules.length - 1) const SizedBox(height: 16),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeModule {
  const _HomeModule({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.hint,
    required this.accent,
    required this.softColor,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String hint;
  final Color accent;
  final Color softColor;
  final String route;
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module});

  final _HomeModule module;

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: () => context.go(module.route),
      child: Container(
        constraints: const BoxConstraints(minHeight: 158),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              module.softColor,
              AppColors.bgCard,
            ],
          ),
          borderRadius: AppRadius.xl,
          border: Border.all(
            color: module.accent.withValues(alpha: 0.16),
            width: 1.5,
          ),
          boxShadow: AppShadows.sm,
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -18,
              child: Container(
                width: 112,
                height: 112,
                decoration: BoxDecoration(
                  color: module.accent.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    color: module.accent.withValues(alpha: 0.14),
                    borderRadius: AppRadius.xl,
                    boxShadow: AppShadows.xs,
                  ),
                  alignment: Alignment.center,
                  child: Icon(module.icon, size: 38, color: module.accent),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard.withValues(alpha: 0.82),
                          borderRadius: AppRadius.pill,
                          boxShadow: AppShadows.xs,
                        ),
                        child: Text(
                          module.hint,
                          style: AppText.caption(color: module.accent),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(module.title, style: AppText.heading()),
                      const SizedBox(height: 6),
                      Text(
                        module.subtitle,
                        style: AppText.body(color: AppColors.ink2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppColors.bgCard.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: module.accent.withValues(alpha: 0.16),
                    ),
                    boxShadow: AppShadows.xs,
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    size: 22,
                    color: module.accent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressSummaryCard extends StatelessWidget {
  const _ProgressSummaryCard({required this.rewardAsync});

  final AsyncValue<RewardModel?> rewardAsync;

  static const _milestones = [10, 25, 50, 100, 200, 500];

  int _nextMilestone(int stars) {
    for (final milestone in _milestones) {
      if (stars < milestone) return milestone;
    }
    return _milestones.last;
  }

  @override
  Widget build(BuildContext context) {
    final reward = rewardAsync.valueOrNull;
    final stars = reward?.totalStars ?? 0;
    final badges = reward?.badges.length ?? 0;
    final next = _nextMilestone(stars);
    final progress = stars >= next ? 1.0 : stars / next;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.94),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.6)),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Your progress', style: AppText.title()),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '$badges ${badges == 1 ? 'badge' : 'badges'}',
                  style: AppText.caption(color: AppColors.greenDark),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'You are doing beautifully. Keep collecting stars at your own pace.',
            style: AppText.body(color: AppColors.ink2),
          ),
          const SizedBox(height: 14),
          ProgressBar.green(value: progress),
          const SizedBox(height: 8),
          Text(
            '${next - stars <= 0 ? 0 : next - stars} stars until your next badge',
            style: AppText.caption(color: AppColors.ink2),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _MiniProgressCard(
                  label: 'Current stars',
                  value: '$stars',
                  accent: AppColors.amberDark,
                  background: AppColors.amberLight,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniProgressCard(
                  label: 'Next goal',
                  value: '$next',
                  accent: AppColors.greenDark,
                  background: AppColors.greenLight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniProgressCard extends StatelessWidget {
  const _MiniProgressCard({
    required this.label,
    required this.value,
    required this.accent,
    required this.background,
  });

  final String label;
  final String value;
  final Color accent;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppText.caption(color: AppColors.ink2)),
          const SizedBox(height: 4),
          Text(value, style: AppText.heading(color: accent)),
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.recentAsync});

  final AsyncValue<List<SessionModel>> recentAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard.withValues(alpha: 0.94),
        borderRadius: AppRadius.xl,
        border: Border.all(color: AppColors.ink4.withValues(alpha: 0.6)),
        boxShadow: AppShadows.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent little wins', style: AppText.title()),
          const SizedBox(height: 6),
          Text(
            'A calm look back at the practice you have already done.',
            style: AppText.body(color: AppColors.ink2),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: recentAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 2,
                ),
              ),
              error: (error, stackTrace) => Center(
                child: Text(
                  'Could not load sessions',
                  style: AppText.caption(),
                ),
              ),
              data: (sessions) {
                if (sessions.isEmpty) return const _EmptyActivity();
                final shown = sessions.length > 5 ? sessions.sublist(0, 5) : sessions;
                return ListView.separated(
                  itemCount: shown.length,
                  separatorBuilder: (context, index) => Divider(
                    color: AppColors.ink5,
                    height: 18,
                  ),
                  itemBuilder: (_, index) => _SessionRow(session: shown[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyActivity extends StatelessWidget {
  const _EmptyActivity();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.greenLight,
              borderRadius: AppRadius.xl,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.play_arrow_rounded,
              color: AppColors.greenDark,
              size: 36,
            ),
          ),
          const SizedBox(height: 14),
          Text('No activities yet', style: AppText.title()),
          const SizedBox(height: 6),
          Text(
            'Start one of the activities above and your little wins will appear here.',
            style: AppText.body(color: AppColors.ink3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({required this.session});

  final SessionModel session;

  String _formatDate(DateTime dateTime) {
    final today = DateTime.now();
    final todayDay = DateTime(today.year, today.month, today.day);
    final sessionDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final difference = todayDay.difference(sessionDay).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    return '${dateTime.day}/${dateTime.month}';
  }

  static String _moduleName(String module) {
    if (module == 'aac') return 'AAC Board';
    if (module == 'vocab') return 'Vocab Learning';
    if (module == 'speech') return 'Speech Practice';
    return 'Activity';
  }

  static Color _moduleColor(String module) {
    if (module == 'aac') return AppColors.sky;
    if (module == 'vocab') return AppColors.amber;
    if (module == 'speech') return AppColors.rose;
    return AppColors.ink2;
  }

  static IconData _moduleIcon(String module) {
    if (module == 'aac') return Icons.record_voice_over_rounded;
    if (module == 'vocab') return Icons.auto_stories_rounded;
    if (module == 'speech') return Icons.mic_rounded;
    return Icons.extension_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _moduleColor(session.module);
    final trailingLabel = session.module == 'aac'
        ? _formatDuration(session.durationSeconds)
        : session.isPendingReview
            ? 'Pending review'
            : session.accuracy == null
                ? 'Done'
                : '${(session.accuracy! * 100).round()}%';

    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.lg,
          ),
          alignment: Alignment.center,
          child: Icon(_moduleIcon(session.module), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_moduleName(session.module), style: AppText.title()),
              const SizedBox(height: 2),
              Text(
                session.module == 'aac'
                    ? '${_formatDate(session.timestamp)} - communication time'
                    : '${_formatDate(session.timestamp)} - ${session.wordsAttempted} words',
                style: AppText.caption(color: AppColors.ink2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.pill,
          ),
          child: Text(
            trailingLabel,
            style: AppText.caption(color: color),
          ),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return remainingSeconds == 0
        ? '${minutes}m'
        : '${minutes}m ${remainingSeconds}s';
  }
}

class _SwitchProfilesCard extends StatelessWidget {
  const _SwitchProfilesCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SpringTap(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgCard.withValues(alpha: 0.88),
          borderRadius: AppRadius.xl,
          border: Border.all(color: AppColors.ink4.withValues(alpha: 0.55)),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.ink5,
                borderRadius: AppRadius.lg,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: AppColors.ink2,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Switch profile', style: AppText.title()),
                  const SizedBox(height: 2),
                  Text(
                    'Go back and choose a different learner.',
                    style: AppText.caption(color: AppColors.ink2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.ink3,
            ),
          ],
        ),
      ),
    );
  }
}
