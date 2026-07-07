import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/recording_model.dart';
import '../../providers/admin_provider.dart';
import '../../providers/child_provider.dart';
import '../../providers/recording_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/admin_sidebar.dart';

class RecordingReviewScreen extends ConsumerStatefulWidget {
  const RecordingReviewScreen({required this.childId, super.key});

  final String childId;

  @override
  ConsumerState<RecordingReviewScreen> createState() =>
      _RecordingReviewScreenState();
}

class _RecordingReviewScreenState extends ConsumerState<RecordingReviewScreen> {
  late String _selectedChildId;

  @override
  void initState() {
    super.initState();
    _selectedChildId = widget.childId;
  }

  @override
  Widget build(BuildContext context) {
    final children = ref.watch(linkedChildrenProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF0EDE8),
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminSidebar(currentPath: '/admin/recordings/${widget.childId}'),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    children: children,
                    selectedId: _selectedChildId,
                    onChildChanged: (id) => setState(() => _selectedChildId = id),
                  ),
                  const Divider(color: AppColors.ink4, height: 1),
                  Expanded(
                    child: _RecordingList(
                      key: ValueKey(_selectedChildId),
                      childId: _selectedChildId,
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

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.children,
    required this.selectedId,
    required this.onChildChanged,
  });

  final List children;
  final String selectedId;
  final ValueChanged<String> onChildChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 14, 16, 14),
      color: AppColors.bgCard,
      child: Row(
        children: [
          Text('Recording Review', style: AppText.heading()),
          const Spacer(),
          if (children.length > 1)
            DropdownButton<String>(
              value: selectedId,
              underline: const SizedBox.shrink(),
              style: AppText.body(),
              items: [
                for (final child in children)
                  DropdownMenuItem(
                    value: child.id as String,
                    child: Text(child.name as String),
                  ),
              ],
              onChanged: (id) {
                if (id != null) onChildChanged(id);
              },
            ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => context.go('/admin/dashboard'),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                '← Dashboard',
                style: AppText.caption(color: AppColors.ink3),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordingList extends ConsumerStatefulWidget {
  const _RecordingList({required this.childId, super.key});

  final String childId;

  @override
  ConsumerState<_RecordingList> createState() => _RecordingListState();
}

class _RecordingListState extends ConsumerState<_RecordingList> {
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _playingId = null);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay(RecordingModel recording) async {
    if (_playingId == recording.id) {
      await _player.stop();
      setState(() => _playingId = null);
      return;
    }

    try {
      await _player.stop();
      if (recording.storageUrl != null && recording.storageUrl!.isNotEmpty) {
        await _player.play(UrlSource(recording.storageUrl!));
      } else if (recording.localFilePath != null &&
          recording.localFilePath!.isNotEmpty) {
        await _player.play(DeviceFileSource(recording.localFilePath!));
      } else {
        throw StateError('No playable audio source is available.');
      }
      setState(() => _playingId = recording.id);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Audio is not available to play yet.'),
        ),
      );
      setState(() => _playingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<RecordingModel>>(
      stream: ref.read(recordingServiceProvider).watchRecordings(widget.childId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppColors.green,
              strokeWidth: 2,
            ),
          );
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'Could not load recordings',
              style: AppText.body(color: AppColors.ink3),
            ),
          );
        }

        final recordings = snap.data ?? [];
        if (recordings.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.mic_none_rounded,
                  size: 48,
                  color: AppColors.ink3,
                ),
                const SizedBox(height: 16),
                Text('No recordings yet', style: AppText.heading()),
                const SizedBox(height: 6),
                Text(
                  'Speech recordings will appear here after a child sends one for review.',
                  style: AppText.body(color: AppColors.ink3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: recordings.length,
          separatorBuilder: (context, index) => const SizedBox(height: 12),
          itemBuilder: (_, index) {
            final recording = recordings[index];
            return _RecordingCard(
              key: ValueKey(recording.id),
              recording: recording,
              isPlaying: _playingId == recording.id,
              onTogglePlay: () => _togglePlay(recording),
              onSave: (score, comment) async {
                await ref.read(recordingServiceProvider).saveReview(
                      childId: widget.childId,
                      recordingId: recording.id,
                      score: score,
                      comment: comment,
                    );
                ref.invalidate(adminSessionsProvider);
              },
              onDelete: () async {
                if (_playingId == recording.id) {
                  await _player.stop();
                  if (mounted) {
                    setState(() => _playingId = null);
                  }
                }

                await ref.read(recordingServiceProvider).deleteRecording(
                      childId: widget.childId,
                      recordingId: recording.id,
                    );
                ref.invalidate(adminSessionsProvider);
              },
            );
          },
        );
      },
    );
  }
}

class _RecordingCard extends StatefulWidget {
  const _RecordingCard({
    required this.recording,
    required this.isPlaying,
    required this.onTogglePlay,
    required this.onSave,
    required this.onDelete,
    super.key,
  });

  final RecordingModel recording;
  final bool isPlaying;
  final VoidCallback onTogglePlay;
  final Future<void> Function(int score, String comment) onSave;
  final Future<void> Function() onDelete;

  @override
  State<_RecordingCard> createState() => _RecordingCardState();
}

class _RecordingCardState extends State<_RecordingCard> {
  late int? _score;
  late final TextEditingController _commentCtrl;
  late bool _editing;
  bool _saving = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _score = widget.recording.reviewStars;
    _commentCtrl = TextEditingController(text: widget.recording.reviewComment ?? '');
    _editing = widget.recording.reviewStars == null;
  }

  @override
  void didUpdateWidget(covariant _RecordingCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.recording.reviewStars != widget.recording.reviewStars) {
      _score = widget.recording.reviewStars;
      _editing = false;
    }
    if (oldWidget.recording.reviewComment != widget.recording.reviewComment) {
      _commentCtrl.text = widget.recording.reviewComment ?? '';
    }
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  void _cancelEditing() {
    setState(() {
      _score = widget.recording.reviewStars;
      _commentCtrl.text = widget.recording.reviewComment ?? '';
      _error = null;
      _editing = false;
    });
  }

  Future<void> _submit() async {
    if (_saving || _deleting) return;
    if (_score == null) {
      setState(() => _error = 'Please choose a star rating before saving.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSave(_score!, _commentCtrl.text);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save this evaluation yet.';
      });
    }
  }

  Future<void> _confirmDelete() async {
    if (_saving || _deleting) return;

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        title: Text('Delete recording?', style: AppText.title()),
        content: Text(
          'This will permanently remove the "${widget.recording.word}" speech recording and its saved review.',
          style: AppText.body(color: AppColors.ink2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Cancel',
              style: AppText.button(color: AppColors.ink2),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Delete',
              style: AppText.button(color: AppColors.roseDark),
            ),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    setState(() {
      _deleting = true;
      _error = null;
    });

    try {
      await widget.onDelete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recording deleted.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not delete this recording yet.'),
        ),
      );
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final diff = today.difference(day).inDays;
    final time =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (diff == 0) return 'Today $time';
    if (diff == 1) return 'Yesterday';
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  @override
  Widget build(BuildContext context) {
    final recording = widget.recording;
    final reviewed = recording.isReviewed;
    final canReview = recording.isReady;
    final isBusy = _saving || _deleting;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow: AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PlayButton(
                isPlaying: widget.isPlaying,
                enabled: canReview,
                onTap: widget.onTogglePlay,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(recording.word, style: AppText.title())),
                        _ReviewStatusChip(recording: recording),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatDate(recording.timestamp),
                      style: AppText.caption(color: AppColors.ink3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reviewed
                          ? 'This recording has been evaluated. You can edit it anytime.'
                          : 'This recording is waiting for a parent or teacher evaluation.',
                      style: AppText.body(color: AppColors.ink2),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionPill(
                    label: _editing ? 'Cancel' : reviewed ? 'Edit' : 'Evaluate',
                    color: reviewed ? AppColors.skyDark : AppColors.greenDark,
                    background:
                        reviewed ? AppColors.skyLight : AppColors.greenLight,
                    onTap: !canReview || isBusy
                        ? null
                        : _editing
                            ? _cancelEditing
                            : () => setState(() {
                                  _editing = true;
                                  _error = null;
                                  _score = recording.reviewStars;
                                  _commentCtrl.text =
                                      recording.reviewComment ?? '';
                                }),
                  ),
                  const SizedBox(width: 8),
                  _ActionPill(
                    label: _deleting ? 'Deleting...' : 'Delete',
                    color: AppColors.roseDark,
                    background: AppColors.roseLight,
                    onTap: isBusy ? null : _confirmDelete,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (reviewed && !_editing)
            _ReviewedSummary(
              stars: recording.reviewStars!,
              comment: recording.reviewComment,
            ),
          if (_editing) ...[
            const Divider(color: AppColors.ink5, height: 1),
            const SizedBox(height: 16),
            Text('Stars', style: AppText.caption()),
            const SizedBox(height: 8),
            _StarRating(
              value: _score,
              enabled: canReview,
              onChanged: (value) => setState(() => _score = value),
            ),
            const SizedBox(height: 16),
            Text('Feedback / comment', style: AppText.caption()),
            const SizedBox(height: 8),
            TextField(
              controller: _commentCtrl,
              enabled: canReview && !_deleting,
              maxLines: 3,
              style: AppText.body(),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.bg,
                hintText: 'Add remarks for the child here...',
                hintStyle: AppText.body(color: AppColors.ink3),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: const BorderSide(color: AppColors.ink4, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.md,
                  borderSide: const BorderSide(color: AppColors.green, width: 1.5),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: AppText.caption(color: AppColors.rose)),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: _ConfirmButton(
                saving: _saving,
                enabled: canReview && !_deleting,
                onTap: _submit,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.enabled,
    required this.onTap,
  });

  final bool isPlaying;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: !enabled
              ? AppColors.ink5
              : isPlaying
                  ? AppColors.rose
                  : AppColors.roseLight,
          shape: BoxShape.circle,
          border: Border.all(
            color: !enabled
                ? AppColors.ink4
                : isPlaying
                    ? AppColors.roseDark
                    : AppColors.roseMid,
            width: 1.5,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          isPlaying && enabled ? Icons.stop_rounded : Icons.play_arrow_rounded,
          color: !enabled
              ? AppColors.ink3
              : isPlaying
                  ? Colors.white
                  : AppColors.rose,
          size: 24,
        ),
      ),
    );
  }
}

class _ReviewStatusChip extends StatelessWidget {
  const _ReviewStatusChip({required this.recording});

  final RecordingModel recording;

  @override
  Widget build(BuildContext context) {
    late final String label;
    late final Color textColor;
    late final Color bgColor;

    if (recording.isReviewed) {
      label = 'Reviewed';
      textColor = AppColors.greenDark;
      bgColor = AppColors.greenLight;
    } else if (recording.isReady) {
      label = 'Pending review';
      textColor = AppColors.skyDark;
      bgColor = AppColors.skyLight;
    } else {
      label = 'Unavailable';
      textColor = AppColors.rose;
      bgColor = AppColors.roseLight;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadius.pill,
      ),
      child: Text(label, style: AppText.caption(color: textColor)),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final String label;
  final Color color;
  final Color background;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: AppRadius.pill,
        ),
        child: Text(label, style: AppText.button(color: color)),
      ),
    );
  }
}

class _ReviewedSummary extends StatelessWidget {
  const _ReviewedSummary({
    required this.stars,
    required this.comment,
  });

  final int stars;
  final String? comment;

  @override
  Widget build(BuildContext context) {
    final percent = ((stars / 5) * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: AppRadius.lg,
        border: Border.all(color: AppColors.ink4, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StarRating(
                value: stars,
                enabled: false,
                onChanged: (_) {},
              ),
              const SizedBox(width: 10),
              Text('$percent%', style: AppText.title(color: AppColors.greenDark)),
            ],
          ),
          if (comment != null && comment!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(comment!, style: AppText.body(color: AppColors.ink2)),
          ],
        ],
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.value,
    required this.enabled,
    required this.onChanged,
  });

  final int? value;
  final bool enabled;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 1; i <= 5; i++)
          GestureDetector(
            onTap: enabled ? () => onChanged(i) : null,
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                i <= (value ?? 0) ? Icons.star_rounded : Icons.star_border_rounded,
                color: enabled || i <= (value ?? 0) ? AppColors.amber : AppColors.ink4,
                size: 30,
              ),
            ),
          ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  const _ConfirmButton({
    required this.saving,
    required this.enabled,
    required this.onTap,
  });

  final bool saving;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (saving) {
      return const SizedBox(
        width: 180,
        height: 44,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: AppColors.green, strokeWidth: 2),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 180,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? AppColors.green : AppColors.ink5,
          borderRadius: AppRadius.pill,
          boxShadow: enabled
              ? const [
                  BoxShadow(
                    color: AppColors.greenDark,
                    blurRadius: 0,
                    offset: Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Text(
          'Confirm Evaluation',
          style: AppText.button(color: enabled ? Colors.white : AppColors.ink3),
        ),
      ),
    );
  }
}
