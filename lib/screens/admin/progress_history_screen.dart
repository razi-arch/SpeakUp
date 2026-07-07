import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

class ProgressHistoryScreen extends ConsumerStatefulWidget {
  const ProgressHistoryScreen({required this.childId, super.key});

  final String childId;

  @override
  ConsumerState<ProgressHistoryScreen> createState() =>
      _ProgressHistoryScreenState();
}

class _ProgressHistoryScreenState extends ConsumerState<ProgressHistoryScreen> {
  static const _pageSize = 10;

  final List<SessionModel> _sessions = [];
  String _filter = 'all';
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot<Map<String, dynamic>>? _cursor;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  Future<void> _reload() async {
    setState(() {
      _sessions.clear();
      _cursor = null;
      _hasMore = true;
      _loading = true;
    });
    await _loadMore(initial: true);
  }

  Future<void> _loadMore({bool initial = false}) async {
    if ((!_hasMore && !initial) || _loadingMore) return;

    setState(() {
      _loadingMore = !initial;
      if (initial) _loading = true;
    });

    try {
      final page = await ref.read(sessionServiceProvider).fetchSessionHistoryPage(
            childId: widget.childId,
            filter: _filter,
            limit: _pageSize,
            startAfter: _cursor,
          );

      if (!mounted) return;
      setState(() {
        _sessions.addAll(page.sessions);
        _cursor = page.cursor;
        _hasMore = page.hasMore && page.sessions.isNotEmpty;
        _loading = false;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(linkedChildrenProvider).valueOrNull ?? const [];
    final matchingChildren =
        children.where((child) => child.id == widget.childId).toList();
    final childName =
        matchingChildren.isEmpty ? 'Child' : matchingChildren.first.name;

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
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
                    color: AppColors.bgCard,
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Full Session History', style: AppText.heading()),
                              const SizedBox(height: 2),
                              Text(
                                childName,
                                style: AppText.caption(color: AppColors.ink2),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/admin/progress/${widget.childId}'),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              '← Back to progress',
                              style: AppText.caption(color: AppColors.green),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(color: AppColors.ink4, height: 1),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
                          child: Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _FilterChip(
                                label: 'All',
                                selected: _filter == 'all',
                                onTap: () {
                                  setState(() => _filter = 'all');
                                  _reload();
                                },
                              ),
                              _FilterChip(
                                label: 'Guided Questions',
                                selected: _filter == 'guided',
                                onTap: () {
                                  setState(() => _filter = 'guided');
                                  _reload();
                                },
                              ),
                              _FilterChip(
                                label: 'Fill in the Blank',
                                selected: _filter == 'fill_blank',
                                onTap: () {
                                  setState(() => _filter = 'fill_blank');
                                  _reload();
                                },
                              ),
                              _FilterChip(
                                label: 'Speech',
                                selected: _filter == 'speech',
                                onTap: () {
                                  setState(() => _filter = 'speech');
                                  _reload();
                                },
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: _loading
                              ? const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.green,
                                    strokeWidth: 3,
                                  ),
                                )
                              : _HistoryList(
                                  sessions: _sessions,
                                  hasMore: _hasMore,
                                  loadingMore: _loadingMore,
                                  onLoadMore: _loadMore,
                                ),
                        ),
                      ],
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

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.bgCard,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: selected ? AppColors.greenDark : AppColors.ink4,
          ),
        ),
        child: Text(
          label,
          style: AppText.button(
            color: selected ? Colors.white : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

class _HistoryList extends StatelessWidget {
  const _HistoryList({
    required this.sessions,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
  });

  final List<SessionModel> sessions;
  final bool hasMore;
  final bool loadingMore;
  final Future<void> Function() onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return Center(
        child: Text('No sessions found for this filter', style: AppText.body()),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      children: [
        for (int i = 0; i < sessions.length; i++) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.bgCard,
              borderRadius: AppRadius.xl,
              boxShadow: AppShadows.sm,
            ),
            child: _HistoryRow(session: sessions[i]),
          ),
          if (i != sessions.length - 1) const SizedBox(height: 12),
        ],
        const SizedBox(height: 18),
        if (hasMore)
          Center(
            child: GestureDetector(
              onTap: loadingMore ? null : onLoadMore,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: AppRadius.pill,
                  border: Border.all(color: AppColors.ink4),
                ),
                child: loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: AppColors.green,
                          strokeWidth: 2,
                        ),
                      )
                    : Text('Load more', style: AppText.button(color: AppColors.ink2)),
              ),
            ),
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.session});

  final SessionModel session;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(session);
    final isAac = session.module == 'aac';

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: AppRadius.lg,
          ),
          alignment: Alignment.center,
          child: Icon(_iconForSession(session), color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_labelForSession(session), style: AppText.title()),
              const SizedBox(height: 4),
              Text(
                isAac
                    ? '${_formatDate(session.timestamp)} • ${_formatDuration(session.durationSeconds)}'
                    : '${_formatDate(session.timestamp)} • ${session.wordsAttempted} attempt${session.wordsAttempted == 1 ? '' : 's'}',
                style: AppText.caption(color: AppColors.ink2),
              ),
            ],
          ),
        ),
        if (isAac)
          Text(
            _formatDuration(session.durationSeconds),
            style: AppText.title(color: AppColors.skyDark),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.pill,
            ),
            child: Text(
              _historyStatusLabel(session),
              style: AppText.caption(color: color),
            ),
          ),
      ],
    );
  }
}

Color _statusColor(SessionModel session) {
  if (session.isPendingReview) return AppColors.skyDark;
  if (session.module == 'aac') return AppColors.skyDark;
  return _bandColor(session.accuracy);
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

String _historyStatusLabel(SessionModel session) {
  if (session.isPendingReview) return 'Pending';
  if (session.accuracy == null) return 'Done';
  return '${(session.accuracy! * 100).round()}%';
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
