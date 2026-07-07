import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/child_model.dart';
import '../../models/session_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/reward_provider.dart';
import '../../services/progress_summary_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/secondary_button.dart';

const _dashboardBg = Color(0xFFF0EDE8);

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childrenAsync = ref.watch(linkedChildrenProvider);
    final sessionsAsync = ref.watch(adminSessionsProvider);

    return Scaffold(
      backgroundColor: _dashboardBg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AdminSidebar(currentPath: '/admin/dashboard'),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _TopBar(),
                  const Divider(color: AppColors.ink4, height: 1),
                  Expanded(
                    child: sessionsAsync.when(
                      loading: () => const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                          strokeWidth: 3,
                        ),
                      ),
                      error: (error, stackTrace) => Center(
                        child: Text(
                          'Could not load dashboard data',
                          style: AppText.body(color: AppColors.ink3),
                        ),
                      ),
                      data: (sessions) {
                        final children = childrenAsync.valueOrNull ?? [];
                        return _DashboardContent(
                          children: children,
                          sessions: sessions,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ).animate().fadeIn(
              duration: AppMotion.slow,
              curve: AppMotion.easeOut,
            ),
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).valueOrNull;
    final profile = ref.watch(adultProfileProvider).valueOrNull;
    final role = ref.watch(userRoleProvider);
    final name = (profile?.fullName.trim().isNotEmpty ?? false)
        ? profile!.fullName.trim()
        : user?.email ?? 'Parent / Teacher';

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      color: AppColors.bgCard,
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(name, style: AppText.title()),
              if (role != null)
                Text(
                  role[0].toUpperCase() + role.substring(1),
                  style: AppText.caption(color: AppColors.green),
                ),
            ],
          ),
          const Spacer(),
          SecondaryButton(
            label: '+ Add Child',
            onPressed: () => context.go('/admin/add-child'),
          ),
        ],
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({
    required this.children,
    required this.sessions,
  });

  final List<ChildModel> children;
  final List<SessionModel> sessions;

  static const _summaryService = ProgressSummaryService();

  @override
  Widget build(BuildContext context) {
    final summary = _summaryService.build(sessions);
    final wordsToday = summary.learningSessions
        .where((session) => _isSameDay(session.timestamp, DateTime.now()))
        .fold<int>(0, (sum, session) => sum + session.wordsAttempted);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatRow(
            childCount: children.length,
            averageAccuracy: summary.averageAccuracy,
            wordsToday: wordsToday,
          ),
          const SizedBox(height: 24),
          _WeeklyChart(sessions: summary.learningSessions),
          const SizedBox(height: 28),
          Row(
            children: [
              Text('Children', style: AppText.heading()),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.greenLight,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  '${children.length}',
                  style: AppText.caption(color: AppColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (children.isEmpty)
            const _EmptyChildren()
          else
            for (int i = 0; i < children.length; i++) ...[
              _ChildRow(
                key: ValueKey(children[i].id),
                child: children[i],
                linkedChildIds: children.map((child) => child.id).toList(),
                sessions: sessions.where((session) => session.childId == children[i].id).toList(),
              ).animate(delay: Duration(milliseconds: i * 60)).fadeIn(
                    duration: AppMotion.slow,
                    curve: AppMotion.easeOut,
                  ).slideY(
                    begin: 0.03,
                    end: 0,
                    duration: AppMotion.slow,
                    curve: AppMotion.easeOut,
                  ),
              if (i < children.length - 1) const SizedBox(height: 12),
            ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.childCount,
    required this.averageAccuracy,
    required this.wordsToday,
  });

  final int childCount;
  final double? averageAccuracy;
  final int wordsToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.family_restroom_rounded,
            value: '$childCount',
            label: 'Children linked',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.insights_rounded,
            value: averageAccuracy == null
                ? '-'
                : '${(averageAccuracy! * 100).round()}%',
            label: 'Learning accuracy',
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _StatCard(
            icon: Icons.menu_book_rounded,
            value: '$wordsToday',
            label: 'Scored attempts today',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 24, color: AppColors.green),
          const SizedBox(height: 8),
          Text(value, style: AppText.display(color: AppColors.green)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption()),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({required this.sessions});

  final List<SessionModel> sessions;

  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<BarChartGroupData> _buildBars() {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final target = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));

      final daySessions = sessions.where((session) {
        final sessionDay = DateTime(
          session.timestamp.year,
          session.timestamp.month,
          session.timestamp.day,
        );
        return sessionDay == target;
      }).toList();

      final average = daySessions.isEmpty
          ? 0.0
          : daySessions
                  .map((session) => session.accuracy ?? 0.0)
                  .fold<double>(0.0, (sum, value) => sum + value) /
              daySessions.length;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: average,
            color: daySessions.isEmpty ? AppColors.ink5 : AppColors.green,
            width: 18,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
          ),
        ],
      );
    });
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final now = DateTime.now();
    final day = now.subtract(Duration(days: 6 - value.toInt()));
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(_dayLabels[day.weekday - 1], style: AppText.caption()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Weekly learning accuracy', style: AppText.title()),
          const SizedBox(height: 4),
          Text(
            'Scored learning only. AAC and pending speech reviews are excluded.',
            style: AppText.caption(color: AppColors.ink2),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 1.0,
                minY: 0.0,
                barGroups: _buildBars(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 0.5,
                  getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppColors.ink4,
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: _bottomTitle,
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles:
                      const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                barTouchData: BarTouchData(enabled: false),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildRow extends ConsumerStatefulWidget {
  const _ChildRow({
    required this.child,
    required this.linkedChildIds,
    required this.sessions,
    super.key,
  });

  final ChildModel child;
  final List<String> linkedChildIds;
  final List<SessionModel> sessions;

  @override
  ConsumerState<_ChildRow> createState() => _ChildRowState();
}

class _ChildRowState extends ConsumerState<_ChildRow> {
  static const _summaryService = ProgressSummaryService();

  bool _launching = false;

  Future<void> _launchSession() async {
    if (_launching) return;
    setState(() => _launching = true);

    final selectedChild = widget.child.copyWith(isActiveOnDevice: true);
    ref.read(activeChildProvider.notifier).state = selectedChild;

    if (mounted) {
      context.go('/child/home');
    }

    ref
        .read(childServiceProvider)
        .setActiveChild(
          widget.child.id,
          true,
          linkedChildIds: widget.linkedChildIds,
        )
        .catchError((error) {
      debugPrint('Failed to sync active child for dashboard launch: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    final stars =
        ref.watch(rewardProvider(widget.child.id)).valueOrNull?.totalStars ?? 0;
    final summary = _summaryService.build(widget.sessions);
    final rows = [summary.guided, summary.fillBlank, summary.speech];
    final gradientStart = _hexColor(widget.child.avatarGradientStart);
    final gradientEnd = _hexColor(widget.child.avatarGradientEnd);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          _ChildAvatar(
            emoji: widget.child.avatarEmoji,
            gradientStart: gradientStart,
            gradientEnd: gradientEnd,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(widget.child.name, style: AppText.title())),
                    Icon(Icons.star_rounded, size: 16, color: AppColors.amber),
                    const SizedBox(width: 4),
                    Text('$stars', style: AppText.caption()),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    for (int i = 0; i < rows.length; i++) ...[
                      Expanded(child: _ActivityMiniBar(summary: rows[i])),
                      if (i != rows.length - 1) const SizedBox(width: 12),
                    ],
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'AAC usage: ${summary.aacUsage.sessionCount} sessions • ${_formatDuration(summary.aacUsage.totalDurationSeconds)}',
                  style: AppText.caption(color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_launching)
                const SizedBox(
                  width: 110,
                  height: 40,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: AppColors.green,
                      strokeWidth: 2,
                    ),
                  ),
                )
              else
                PrimaryButton(
                  label: 'Launch',
                  icon: const Icon(
                    Icons.play_arrow_rounded,
                    size: 18,
                    color: Colors.white,
                  ),
                  onPressed: _launchSession,
                ),
              const SizedBox(height: 6),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ChildShortcut(
                    label: 'Progress',
                    icon: Icons.bar_chart_rounded,
                    onTap: () => context.go('/admin/progress/${widget.child.id}'),
                  ),
                  const SizedBox(width: 8),
                  _ChildShortcut(
                    label: 'Vocab',
                    icon: Icons.menu_book_rounded,
                    onTap: () => context.go('/admin/vocab/${widget.child.id}'),
                  ),
                  const SizedBox(width: 8),
                  _ChildShortcut(
                    label: 'Recordings',
                    icon: Icons.mic_rounded,
                    onTap: () => context.go('/admin/recordings/${widget.child.id}'),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Color _hexColor(String hex) {
    final clean = hex.replaceFirst('#', '');
    return Color(int.parse('FF$clean', radix: 16));
  }
}

class _ActivityMiniBar extends StatelessWidget {
  const _ActivityMiniBar({required this.summary});

  final ActivityProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = _bandColor(summary.averageAccuracy);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(_iconForActivity(summary.activityId), size: 14, color: color),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                summary.label,
                style: AppText.caption(color: AppColors.ink2),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ProgressBar(
          value: (summary.averageAccuracy ?? 0.0).clamp(0.0, 1.0),
          color: color,
        ),
      ],
    );
  }
}

class _ChildAvatar extends StatelessWidget {
  const _ChildAvatar({
    required this.emoji,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final String emoji;
  final Color gradientStart;
  final Color gradientEnd;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [gradientStart, gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 26)),
    );
  }
}

class _ChildShortcut extends StatelessWidget {
  const _ChildShortcut({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.bgCard,
          borderRadius: AppRadius.sm,
          border: Border.all(color: AppColors.ink4, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.ink2),
            const SizedBox(width: 5),
            Text(label, style: AppText.caption(color: AppColors.ink2)),
          ],
        ),
      ),
    );
  }
}

class _EmptyChildren extends StatelessWidget {
  const _EmptyChildren();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.person_add_alt_rounded,
            size: 40,
            color: AppColors.green,
          ),
          const SizedBox(height: 12),
          Text('No children yet', style: AppText.heading()),
          const SizedBox(height: 6),
          Text(
            'Tap "Add Child" to create the first profile.',
            style: AppText.body(color: AppColors.ink3),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Color _bandColor(double? accuracy) {
  final service = const ProgressSummaryService();
  final band = service.bandForAccuracy(accuracy);
  switch (band.label) {
    case 'high':
      return AppColors.green;
    case 'moderate':
      return AppColors.sky;
    case 'low':
    default:
      return AppColors.rose;
  }
}

IconData _iconForActivity(String activityId) {
  switch (activityId) {
    case 'guided':
      return Icons.quiz_rounded;
    case 'fill_blank':
      return Icons.edit_note_rounded;
    case 'speech':
      return Icons.mic_rounded;
    default:
      return Icons.extension_rounded;
  }
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return remainingSeconds == 0
      ? '${minutes}m'
      : '${minutes}m ${remainingSeconds}s';
}
