import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/child_model.dart';
import '../../models/session_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/session_provider.dart';
import '../../services/progress_summary_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/admin_sidebar.dart';
import '../../widgets/progress_bar.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({required this.childId, super.key});

  final String childId;

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  late String _selectedChildId;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(linkedChildrenProvider).valueOrNull ?? [];
    final sessionsAsync = ref.watch(childSessionsProvider(_selectedChildId));

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE8),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSidebar(currentPath: '/admin/progress/${widget.childId}'),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Header(),
                  const Divider(color: AppColors.ink4, height: 1),
                  if (children.length > 1) ...[
                    _ChildSelector(
                      children: children,
                      selectedId: _selectedChildId,
                      onSelect: (id) => setState(() => _selectedChildId = id),
                    ),
                    const Divider(color: AppColors.ink4, height: 1),
                  ],
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
                          'Could not load sessions',
                          style: AppText.body(color: AppColors.ink3),
                        ),
                      ),
                      data: (sessions) => _Content(
                        childId: _selectedChildId,
                        sessions: sessions,
                      ),
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

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      color: AppColors.bgCard,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Progress', style: AppText.heading()),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/admin/dashboard'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '<- Dashboard',
                style: AppText.caption(color: AppColors.ink3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildSelector extends StatelessWidget {
  const _ChildSelector({
    required this.children,
    required this.selectedId,
    required this.onSelect,
  });

  final List<ChildModel> children;
  final String selectedId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.bgCard,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Text('Child:', style: AppText.caption()),
          const SizedBox(width: 10),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final child in children)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => onSelect(child.id),
                        child: AnimatedContainer(
                          duration: AppMotion.fast,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: selectedId == child.id
                                ? AppColors.green
                                : AppColors.ink5,
                            borderRadius: AppRadius.pill,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(child.avatarEmoji, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Text(
                                child.name,
                                style: AppText.caption(
                                  color: selectedId == child.id
                                      ? Colors.white
                                      : AppColors.ink2,
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
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.childId,
    required this.sessions,
  });

  final String childId;
  final List<SessionModel> sessions;

  static const _summaryService = ProgressSummaryService();

  @override
  Widget build(BuildContext context) {
    final summary = _summaryService.build(sessions);
    final previewSessions = _summaryService.dashboardPreviewSessions(sessions);

    if (sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insights_rounded, size: 48, color: AppColors.ink3),
            const SizedBox(height: 16),
            Text('No sessions yet', style: AppText.heading()),
            const SizedBox(height: 6),
            Text(
              'Sessions will appear here once the child starts using the app.',
              style: AppText.body(color: AppColors.ink3),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TrendCard(sessions: summary.learningSessions),
                const SizedBox(height: 20),
                _LearningBreakdownCard(summary: summary),
                const SizedBox(height: 20),
                _AacUsageCard(summary: summary.aacUsage),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 2,
            child: _SessionHistoryPreviewCard(
              childId: childId,
              sessions: previewSessions,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.sessions});

  final List<SessionModel> sessions;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  List<FlSpot> _buildSpots() {
    final now = DateTime.now();
    final spots = <FlSpot>[];

    for (int i = 0; i < 7; i++) {
      final target = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - i));
      final daySessions = sessions.where((session) {
        final sessionDay = DateTime(
          session.timestamp.year,
          session.timestamp.month,
          session.timestamp.day,
        );
        return sessionDay == target;
      }).toList();

      if (daySessions.isNotEmpty) {
        final avg = daySessions
                .map((session) => session.accuracy ?? 0.0)
                .fold<double>(0.0, (sum, value) => sum + value) /
            daySessions.length;
        spots.add(FlSpot(i.toDouble(), (avg * 100).roundToDouble()));
      }
    }

    return spots;
  }

  Widget _bottomTitle(double value, TitleMeta meta) {
    final now = DateTime.now();
    final day = now.subtract(Duration(days: 6 - value.toInt()));
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(_dayNames[day.weekday - 1], style: AppText.caption()),
    );
  }

  Widget _leftTitle(double value, TitleMeta meta) {
    if (value == meta.max) return const SizedBox.shrink();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text('${value.toInt()}%', style: AppText.caption()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final spots = _buildSpots();

    return Container(
      height: 250,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learning Accuracy Trend', style: AppText.title()),
          const SizedBox(height: 4),
          Text(
            'Scored sessions only. Excludes AAC and pending speech reviews.',
            style: AppText.caption(color: AppColors.ink2),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: spots.isEmpty
                ? Center(
                    child: Text(
                      'No scored learning data in the last 7 days',
                      style: AppText.caption(),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: AppColors.green,
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.green,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.green.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: _bottomTitle,
                            reservedSize: 28,
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 50,
                            getTitlesWidget: _leftTitle,
                            reservedSize: 36,
                          ),
                        ),
                        rightTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles:
                            const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 50,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.ink4,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineTouchData: const LineTouchData(enabled: false),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LearningBreakdownCard extends StatelessWidget {
  const _LearningBreakdownCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final items = [summary.guided, summary.fillBlank, summary.speech];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Learning Breakdown', style: AppText.title()),
          const SizedBox(height: 16),
          for (int i = 0; i < items.length; i++) ...[
            _ActivityRow(summary: items[i]),
            if (i != items.length - 1)
              const Divider(color: AppColors.ink5, height: 20),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.summary});

  final ActivityProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final color = _bandColor(summary.averageAccuracy);

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
          child: Icon(_iconForActivity(summary.activityId), color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text(summary.label, style: AppText.title())),
                  Text('${summary.sessionCount} sessions', style: AppText.caption()),
                ],
              ),
              const SizedBox(height: 6),
              ProgressBar(
                value: (summary.averageAccuracy ?? 0.0).clamp(0.0, 1.0),
                color: color,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 56,
          child: Text(
            summary.averageAccuracy == null
                ? '—'
                : '${((summary.averageAccuracy ?? 0.0) * 100).round()}%',
            style: AppText.title(color: color),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _AacUsageCard extends StatelessWidget {
  const _AacUsageCard({required this.summary});

  final AacUsageSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.skyLight,
              borderRadius: AppRadius.lg,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.record_voice_over_rounded,
              color: AppColors.skyDark,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AAC Communication Usage', style: AppText.title()),
                const SizedBox(height: 6),
                Text(
                  'Tracked separately from scored learning progress.',
                  style: AppText.caption(color: AppColors.ink2),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${summary.sessionCount} sessions', style: AppText.title()),
              const SizedBox(height: 6),
              Text(_formatDuration(summary.totalDurationSeconds), style: AppText.caption()),
            ],
          ),
        ],
      ),
    );
  }
}

class _SessionHistoryPreviewCard extends StatelessWidget {
  const _SessionHistoryPreviewCard({
    required this.childId,
    required this.sessions,
  });

  final String childId;
  final List<SessionModel> sessions;

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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Session History', style: AppText.title())),
              GestureDetector(
                onTap: () => context.go('/admin/progress/$childId/history'),
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    'See more',
                    style: AppText.caption(color: AppColors.green),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Latest 10 learning sessions. AAC stays in the full history view.',
            style: AppText.caption(color: AppColors.ink2),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.ink5, height: 1),
          if (sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('No learning sessions yet', style: AppText.caption()),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppColors.ink5, height: 1),
              itemBuilder: (_, index) => _SessionHistoryRow(session: sessions[index]),
            ),
        ],
      ),
    );
  }
}

class _SessionHistoryRow extends StatelessWidget {
  const _SessionHistoryRow({required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(session);
    final label = _historyStatusLabel(session);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(_formatDate(session.timestamp), style: AppText.caption()),
          ),
          Expanded(
            child: Row(
              children: [
                Icon(_iconForSession(session), size: 16, color: color),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _labelForSession(session),
                    style: AppText.caption(color: AppColors.ink2),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              _formatDuration(session.durationSeconds),
              style: AppText.caption(),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.pill,
            ),
            child: Text(label, style: AppText.caption(color: color)),
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

Color _statusColor(SessionModel session) {
  if (session.isPendingReview) return AppColors.skyDark;
  if (session.module == 'aac') return AppColors.skyDark;
  return _bandColor(session.accuracy);
}

String _historyStatusLabel(SessionModel session) {
  if (session.isPendingReview) return 'Pending';
  if (session.accuracy == null) return 'Done';
  return '${(session.accuracy! * 100).round()}%';
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

IconData _iconForSession(SessionModel session) {
  if (session.module == 'aac') return Icons.record_voice_over_rounded;
  if (session.module == 'speech') return Icons.mic_rounded;
  if (session.activityType == 'fill_blank') return Icons.edit_note_rounded;
  return Icons.quiz_rounded;
}

String _labelForSession(SessionModel session) {
  if (session.module == 'aac') return 'AAC Communication';
  if (session.module == 'speech') return 'Speech Practice';
  if (session.activityType == 'fill_blank') return 'Fill in the Blank';
  return 'Guided Questions';
}

String _formatDate(DateTime dateTime) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final sessionDay = DateTime(dateTime.year, dateTime.month, dateTime.day);
  final diff = today.difference(sessionDay).inDays;
  final time =
      '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return 'Today $time';
  if (diff == 1) return 'Yesterday';
  return '${dateTime.day}/${dateTime.month}/${dateTime.year.toString().substring(2)}';
}

String _formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  final minutes = seconds ~/ 60;
  final remainingSeconds = seconds % 60;
  return remainingSeconds == 0
      ? '${minutes}m'
      : '${minutes}m ${remainingSeconds}s';
}
