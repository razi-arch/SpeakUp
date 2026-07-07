
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../models/session_model.dart';
import '../../providers/child_provider.dart';
import '../../providers/recording_provider.dart';
import '../../providers/reward_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/vocab_provider.dart';
import '../../services/recording_service.dart';
import '../../services/vocab_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_text.dart';
import '../../widgets/symbol_card.dart';
import '../../widgets/vocab_image.dart';
import '../../widgets/waveform.dart';

// â”€â”€â”€ Phase & record state â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

enum _Phase { picking, recording }
enum _RecordState { idle, recording, recorded, playing }
enum _UploadState { idle, uploading, uploaded, failed }

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class SpeechPracticeScreen extends ConsumerStatefulWidget {
  const SpeechPracticeScreen({super.key});

  @override
  ConsumerState<SpeechPracticeScreen> createState() =>
      _SpeechPracticeScreenState();
}

class _SpeechPracticeScreenState extends ConsumerState<SpeechPracticeScreen> {
  final FlutterTts    _tts      = FlutterTts();
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer   _player   = AudioPlayer();

  // Picker state
  _Phase         _phase         = _Phase.picking;
  List<VocabItem> _allItems     = [];
  String?        _localCategory; // null = show all

  // Recording state
  VocabItem?   _selectedItem;
  _RecordState _recordState  = _RecordState.idle;
  String?      _recordingPath;
  Uint8List? _recordingBytes;
  _UploadState _uploadState = _UploadState.idle;
  String? _uploadError;
  String? _pendingRecordingId;
  UploadedRecording? _uploadedRecording;
  Future<void>? _pendingUpload;
  DateTime? _attemptStartedAt;

  @override
  void initState() {
    super.initState();
    _tts
      ..setLanguage('en-US')
      ..setSpeechRate(0.45)
      ..setVolume(1.0);
    _player.onPlayerStateChanged.listen((state) {
      if (!mounted) return;
      if (state == PlayerState.completed || state == PlayerState.stopped) {
        if (_recordState == _RecordState.playing) {
          setState(() => _recordState = _RecordState.recorded);
        }
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _recorder.dispose();
    _player.dispose();
    super.dispose();
  }

  // â”€â”€ Derived helpers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  List<String> get _categories => _allItems
      .map((i) => i.category)
      .toSet()
      .toList()
    ..sort();

  List<VocabItem> get _filteredItems => _localCategory == null
      ? _allItems
      : _allItems.where((i) => i.category == _localCategory).toList();

  bool get _canFinish =>
      (_recordState == _RecordState.recorded ||
          _recordState == _RecordState.playing) &&
      _uploadState == _UploadState.uploaded;

  // â”€â”€ Navigation â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _pickWord(VocabItem item) {
    setState(() {
      _selectedItem  = item;
      _phase         = _Phase.recording;
      _recordState   = _RecordState.idle;
      _recordingPath = null;
      _recordingBytes = null;
      _uploadState   = _UploadState.idle;
      _uploadError   = null;
      _pendingRecordingId = null;
      _uploadedRecording = null;
      _attemptStartedAt = DateTime.now();
    });
  }

  Future<void> _backToPicker() async {
    if (_uploadState == _UploadState.uploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Finish this recording to send it for adult review.'),
        ),
      );
      return;
    }
    await _player.stop();
    await _tts.stop();
    await _stopActiveRecordingIfNeeded();
    final canLeave = await _ensureUploadCompleted(
      actionLabel: 'going back',
      requireSuccess: false,
    );
    if (!canLeave || !mounted) return;
    setState(() {
      _phase        = _Phase.picking;
      _selectedItem = null;
      _recordState  = _RecordState.idle;
      _recordingPath = null;
      _recordingBytes = null;
      _uploadState = _UploadState.idle;
      _uploadError = null;
      _pendingRecordingId = null;
      _uploadedRecording = null;
      _attemptStartedAt = null;
    });
  }

  Future<void> _finish() async {
    await _player.stop();
    await _tts.stop();
    await _stopActiveRecordingIfNeeded();
    final canFinish = await _ensureUploadCompleted(
      actionLabel: 'finishing',
      requireSuccess: true,
    );
    if (!canFinish) return;
    await _submitForReview();
    if (mounted) context.go('/child/reward');
  }

  Future<void> _goHome() async {
    await _player.stop();
    await _tts.stop();
    await _stopActiveRecordingIfNeeded();
    final canLeave = await _ensureUploadCompleted(
      actionLabel: 'going home',
      requireSuccess: true,
    );
    if (!canLeave) return;
    if (mounted) context.go('/child/home');
  }

  // â”€â”€ TTS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _listen() async {
    final word = _selectedItem?.word;
    if (word == null) return;
    await _tts.speak(word);
  }

  // â”€â”€ Recording â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _toggleRecord() async {
    if (_recordState == _RecordState.recording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _recorder.hasPermission();
      if (!hasPermission) {
        _showRecorderMessage(
          kIsWeb
              ? 'Chrome is blocking microphone access. Allow the microphone for this site and try again.'
              : 'Microphone access is required before recording.',
        );
        return;
      }

      if (kIsWeb) {
        final path = 'speech_${DateTime.now().millisecondsSinceEpoch}.wav';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.wav),
          path: path,
        );
      } else {
        final dir = await getTemporaryDirectory();
        final path =
            '${dir.path}/speech_${DateTime.now().millisecondsSinceEpoch}.aac';
        await _recorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
          path: path,
        );
      }

      if (!mounted) return;
      setState(() {
        _recordingPath = null;
        _recordingBytes = null;
        _recordState = _RecordState.recording;
        _uploadState = _UploadState.idle;
        _uploadError = null;
      });
    } catch (error) {
      _logUploadDebug('Recording start failed: $error');
      if (!mounted) return;
      _showRecorderMessage(_friendlyRecorderError(error));
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      if (!mounted) return;
      if (path == null || path.trim().isEmpty) {
        _showRecorderMessage('No audio was captured. Please try again.');
        return;
      }

      Uint8List? recordingBytes;
      if (kIsWeb) {
        recordingBytes = await http.readBytes(Uri.parse(path));
      }

      setState(() {
        _recordingPath = path;
        _recordingBytes = recordingBytes;
        _recordState = _RecordState.recorded;
      });

      final child = ref.read(activeChildProvider);
      final item = _selectedItem;
      if (child != null && item != null) {
        _startUpload(
          child.id,
          item.word,
          filePath: path,
          bytes: recordingBytes,
        );
      }
    } catch (error) {
      _logUploadDebug('Recording stop failed: $error');
      if (!mounted) return;
      _showRecorderMessage(_friendlyRecorderError(error));
    }
  }

  Future<void> _stopActiveRecordingIfNeeded() async {
    if (_recordState == _RecordState.recording) {
      await _stopRecording();
    }
  }

  // â”€â”€ Playback â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<void> _togglePlay() async {
    if (_recordState == _RecordState.playing) {
      await _player.stop();
      setState(() => _recordState = _RecordState.recorded);
      return;
    }
    final path = _recordingPath;
    if (path == null) return;
    if (kIsWeb) {
      await _player.play(UrlSource(path));
    } else {
      await _player.play(DeviceFileSource(path));
    }
    setState(() => _recordState = _RecordState.playing);
  }

  // â”€â”€ Firebase â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  void _startUpload(
    String childId,
    String word, {
    required String filePath,
    Uint8List? bytes,
  }) {
    _logUploadDebug(
      'Starting remote save childId=$childId word="$word" filePath=$filePath',
    );
    final future = _performUpload(
      childId: childId,
      word: word,
      filePath: filePath,
      bytes: bytes,
    );
    _pendingUpload = future;
    future.whenComplete(() {
      if (identical(_pendingUpload, future)) {
        _pendingUpload = null;
      }
    });
  }

  Future<void> _performUpload({
    required String childId,
    required String word,
    required String filePath,
    Uint8List? bytes,
  }) async {
    _logUploadDebug(
      'Upload in progress childId=$childId word="$word" filePath=$filePath',
    );
    if (mounted) {
      setState(() {
        _uploadState = _UploadState.uploading;
        _uploadError = null;
      });
    }

    try {
      final recordingId =
          _pendingRecordingId ?? ref.read(recordingServiceProvider).newRecordingId();
      final upload = await ref.read(recordingServiceProvider).uploadRecordingFile(
            childId: childId,
            recordingId: recordingId,
            filePath: filePath,
            bytes: bytes,
            fileExtension: kIsWeb ? 'wav' : 'aac',
            contentType: kIsWeb ? 'audio/wav' : 'audio/aac',
          );
      _logUploadDebug(
        'Remote save finished successfully childId=$childId word="$word"',
      );
      if (!mounted) return;
      setState(() {
        _uploadState = _UploadState.uploaded;
        _uploadError = null;
        _pendingRecordingId = recordingId;
        _uploadedRecording = upload;
      });
    } catch (error) {
      _logUploadFailure(error);
      if (!mounted) return;
      setState(() {
        _uploadState = _UploadState.failed;
        _uploadError = _friendlyUploadError(error);
      });
    }
  }

  Future<void> _retryUpload() async {
    final child = ref.read(activeChildProvider);
    final item = _selectedItem;
    final path = _recordingPath;
    if (child == null || item == null || path == null) return;
    _logUploadDebug(
      'Retrying remote save childId=${child.id} word="${item.word}" '
      'filePath=$path recordingId=$_pendingRecordingId',
    );
    _startUpload(
      child.id,
      item.word,
      filePath: path,
      bytes: _recordingBytes,
    );
  }

  Future<bool> _ensureUploadCompleted({
    required String actionLabel,
    required bool requireSuccess,
  }) async {
    final pending = _pendingUpload;
    if (pending != null) {
      _logUploadDebug('Waiting for upload to finish before $actionLabel');
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text('Uploading your recording before $actionLabel...'),
            ),
          );
      }
      await pending;
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }
    }

    if (!requireSuccess || _uploadState != _UploadState.failed) {
      return true;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _uploadError ?? 'We could not save this recording yet. Try again.',
          ),
        ),
      );
    }
    return false;
  }

  String _friendlyUploadError(Object error) {
    if (error is RecordingSaveException) {
      return error.userMessage;
    }
    final raw = error.toString().trim();
    if (raw.startsWith('Exception: ')) {
      return raw.substring('Exception: '.length);
    }
    return 'We could not save this recording yet. Please try again.';
  }

  String _friendlyRecorderError(Object error) {
    final raw = error.toString().toLowerCase();
    if (raw.contains('permission')) {
      return kIsWeb
          ? 'Chrome could not access the microphone. Allow microphone access for this site and try again.'
          : 'Microphone access is required before recording.';
    }
    if (kIsWeb &&
        (raw.contains('encoder') ||
            raw.contains('mediarecorder') ||
            raw.contains('getusermedia'))) {
      return 'Chrome could not start the microphone with this recording setup. Please try again.';
    }
    return 'We could not start the microphone. Please try again.';
  }

  void _showRecorderMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _logUploadFailure(Object error) {
    if (error is RecordingSaveException) {
      _logUploadDebug(
        'Save failed userMessage="${error.userMessage}" '
        'debugMessage="${error.debugMessage}"',
      );
      return;
    }
    _logUploadDebug('Save failed unexpectedly: $error');
  }

  void _logUploadDebug(String message) {
    debugPrint('[SpeechSave] $message');
  }

  Future<void> _submitForReview() async {
    final child = ref.read(activeChildProvider);
    final item = _selectedItem;
    final upload = _uploadedRecording;
    final recordingId = _pendingRecordingId;
    if (child == null || item == null || upload == null || recordingId == null) {
      return;
    }

    final sessionTimestamp = DateTime.now();
    final durationSeconds = _attemptStartedAt == null
        ? 0
        : sessionTimestamp.difference(_attemptStartedAt!).inSeconds;
    final sessionId = await ref.read(sessionServiceProvider).createSession(
          SessionModel(
            id: '',
            childId: child.id,
            module: 'speech',
            accuracy: null,
            scoreStatus: 'pending',
            recordingId: recordingId,
            wordsAttempted: 1,
            durationSeconds: durationSeconds,
            timestamp: sessionTimestamp,
          ),
        );

    await ref.read(recordingServiceProvider).createRecording(
          childId: child.id,
          recordingId: recordingId,
          sessionId: sessionId,
          word: item.word,
          storagePath: upload.storagePath,
          storageUrl: upload.storageUrl,
          timestamp: sessionTimestamp,
        );

    ref.read(pendingRewardSummaryProvider.notifier).state = const SessionRewardSummary(
          module: 'speech',
          earnedStars: 0,
          accuracy: null,
          questionCount: 0,
          correctCount: 0,
          pendingReview: true,
        );
  }

  // â”€â”€ Build â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  @override
  Widget build(BuildContext context) {
    final child = ref.watch(activeChildProvider);
    if (child == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => context.go('/'));
      return const Scaffold(
          backgroundColor: AppColors.roseLight, body: SizedBox.shrink());
    }

    // Populate _allItems once when the stream first emits
    ref.listen(allVocabItemsProvider, (_, next) {
      final items = next.valueOrNull;
      if (items == null || !mounted) return;
      setState(() => _allItems = items);
    });

    // Seed synchronously if already loaded
    final loaded = ref.read(allVocabItemsProvider).valueOrNull;
    if (_allItems.isEmpty && loaded != null) {
      _allItems = loaded;
    }

    return Scaffold(
      backgroundColor: AppColors.roseLight,
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: AppMotion.mid,
          transitionBuilder: (child, anim) =>
              FadeTransition(opacity: anim, child: child),
          child: _phase == _Phase.picking
              ? _Picker(
                  key: const ValueKey('picker'),
                  items:          _filteredItems,
                  allItems:       _allItems,
                  categories:     _categories,
                  localCategory:  _localCategory,
                  onCategoryChanged: (cat) =>
                      setState(() => _localCategory = cat),
                  onWordPicked:   _pickWord,
                  onGoHome:       _goHome,
                )
              : _Recorder(
                  key: const ValueKey('recorder'),
                  item:         _selectedItem!,
                  recordState:  _recordState,
                  uploadState:  _uploadState,
                  uploadError:  _uploadError,
                  onBack:       _backToPicker,
                  onListen:     _listen,
                  onToggleRecord: _toggleRecord,
                  onTogglePlay:   _togglePlay,
                  onRetryUpload:  _retryUpload,
                  canFinish:      _canFinish,
                  onFinish:       _finish,
                ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Picker view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Picker extends StatelessWidget {
  const _Picker({
    required this.items,
    required this.allItems,
    required this.categories,
    required this.localCategory,
    required this.onCategoryChanged,
    required this.onWordPicked,
    required this.onGoHome,
    super.key,
  });

  final List<VocabItem> items;
  final List<VocabItem> allItems;
  final List<String>    categories;
  final String?         localCategory;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<VocabItem> onWordPicked;
  final VoidCallback    onGoHome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 16, 8),
          child: Row(
            children: [
              Text('Speech Practice', style: AppText.heading()),
              const Spacer(),
              GestureDetector(
                onTap: onGoHome,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.home_rounded,
                          color: AppColors.rose, size: 20),
                      const SizedBox(width: 4),
                      Text('Home',
                          style: AppText.caption(color: AppColors.rose)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          child: Text(
            'Which word do you want to practise today?',
            style: AppText.body(color: AppColors.ink3),
          ),
        ),
        // â”€â”€ Category chips â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        if (categories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _CategoryChip(
                  label: 'All',
                  selected: localCategory == null,
                  onTap: () => onCategoryChanged(null),
                ),
                for (final cat in categories) ...[
                  const SizedBox(width: 8),
                  _CategoryChip(
                    label: cat,
                    selected: localCategory == cat,
                    onTap: () => onCategoryChanged(cat),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 8),
        // â”€â”€ Word grid â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: allItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 48,
                        color: AppColors.green,
                      ),
                      const SizedBox(height: 16),
                      Text('No words yet', style: AppText.heading()),
                      const SizedBox(height: 6),
                      Text(
                        'An admin can add vocab items from the dashboard.',
                        style: AppText.body(color: AppColors.ink3),
                      ),
                    ],
                  ),
                )
              : items.isEmpty
                  ? Center(
                      child: Text('No words in this category',
                          style: AppText.body(color: AppColors.ink3)),
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 130,
                        crossAxisSpacing:   12,
                        mainAxisSpacing:    12,
                        childAspectRatio:   1.0,
                      ),
                      itemCount: items.length,
                      itemBuilder: (_, i) => SymbolCard(
                        key:    ValueKey(items[i].id),
                        emoji:  items[i].emoji,
                        label:  items[i].word,
                        localImagePath: items[i].localImagePath,
                        imageUrl: items[i].imageUrl,
                        onTap:  () => onWordPicked(items[i]),
                      ),
                    ),
        ),
      ],
    ).animate()
      .fadeIn(duration: AppMotion.slow, curve: AppMotion.easeOut);
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String      label;
  final bool        selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve:    AppMotion.easeOut,
        padding:  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.roseLight : AppColors.bgCard,
          borderRadius: AppRadius.pill,
          border: Border.all(
            color: selected ? AppColors.rose : AppColors.ink4,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: AppText.button(
            color: selected ? AppColors.roseDark : AppColors.ink2,
          ),
        ),
      ),
    );
  }
}

// â”€â”€â”€ Recorder view â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _Recorder extends StatelessWidget {
  const _Recorder({
    required this.item,
    required this.recordState,
    required this.uploadState,
    required this.uploadError,
    required this.onBack,
    required this.onListen,
    required this.onToggleRecord,
    required this.onTogglePlay,
    required this.onRetryUpload,
    required this.canFinish,
    required this.onFinish,
    super.key,
  });

  final VocabItem    item;
  final _RecordState recordState;
  final _UploadState uploadState;
  final String? uploadError;
  final VoidCallback onBack;
  final VoidCallback onListen;
  final VoidCallback onToggleRecord;
  final VoidCallback onTogglePlay;
  final VoidCallback onRetryUpload;
  final bool canFinish;
  final VoidCallback onFinish;

  bool get _canPlay =>
      recordState == _RecordState.recorded ||
      recordState == _RecordState.playing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // â”€â”€ Header â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              GestureDetector(
                onTap: onBack,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.arrow_back_ios_rounded,
                          color: AppColors.rose, size: 16),
                      const SizedBox(width: 4),
                      Text('Choose another word',
                          style: AppText.caption(color: AppColors.rose)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // â”€â”€ Main content â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Word card
                Expanded(
                  flex: 3,
                  child: _WordCard(
                    item: item,
                    uploadState: uploadState,
                    uploadError: uploadError,
                  ).animate(key: ValueKey(item.id))
                    .fadeIn(duration: AppMotion.mid, curve: AppMotion.easeOut)
                    .slideY(begin: 0.04, end: 0,
                        duration: AppMotion.mid, curve: AppMotion.easeOut),
                ),
                const SizedBox(width: 28),
                // Controls
                Expanded(
                  flex: 2,
                  child: _ControlsPanel(
                    recordState:    recordState,
                    uploadState:    uploadState,
                    uploadError:    uploadError,
                    canPlay:        _canPlay,
                    onListen:       onListen,
                    onToggleRecord: onToggleRecord,
                    onTogglePlay:   onTogglePlay,
                    onRetryUpload:  onRetryUpload,
                    canFinish:      canFinish,
                    onFinish:       onFinish,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate()
      .fadeIn(duration: AppMotion.mid, curve: AppMotion.easeOut);
  }
}

// â”€â”€â”€ Word card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _WordCard extends StatelessWidget {
  const _WordCard({
    required this.item,
    required this.uploadState,
    required this.uploadError,
  });

  final VocabItem item;
  final _UploadState uploadState;
  final String? uploadError;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color:        AppColors.bgCard,
        borderRadius: AppRadius.xl,
        boxShadow:    AppShadows.lg,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _WordVisual(item: item),
          const SizedBox(height: 20),
          Text(item.word, style: AppText.display()),
          const SizedBox(height: 12),
          _UploadStatusLine(
            uploadState: uploadState,
            uploadError: uploadError,
          ),
        ],
      ),
    );
  }
}

class _WordVisual extends StatelessWidget {
  const _WordVisual({required this.item});

  final VocabItem item;

  @override
  Widget build(BuildContext context) {
    return VocabImage(
      localImagePath: item.localImagePath,
      imageUrl: item.imageUrl,
      width: 160,
      height: 160,
      borderRadius: AppRadius.lg,
      fallback: _WordEmojiFallback(emoji: item.emoji),
    );
  }
}

class _WordEmojiFallback extends StatelessWidget {
  const _WordEmojiFallback({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final trimmedEmoji = emoji.trim();
    if (trimmedEmoji.isNotEmpty) {
      return Text(trimmedEmoji, style: const TextStyle(fontSize: 100));
    }

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        color: AppColors.bgRaised,
        borderRadius: AppRadius.lg,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 72,
        color: AppColors.ink3,
      ),
    );
  }
}

// â”€â”€â”€ Controls panel â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _ControlsPanel extends StatelessWidget {
  const _ControlsPanel({
    required this.recordState,
    required this.uploadState,
    required this.uploadError,
    required this.canPlay,
    required this.onListen,
    required this.onToggleRecord,
    required this.onTogglePlay,
    required this.onRetryUpload,
    required this.canFinish,
    required this.onFinish,
  });

  final _RecordState recordState;
  final _UploadState uploadState;
  final String? uploadError;
  final bool         canPlay;
  final bool         canFinish;
  final VoidCallback onListen;
  final VoidCallback onToggleRecord;
  final VoidCallback onTogglePlay;
  final VoidCallback onRetryUpload;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final isRecording = recordState == _RecordState.recording;
    final isRecorded  = recordState == _RecordState.recorded ||
        recordState == _RecordState.playing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Listen
        _ActionButton(
          label:       'Listen',
          color:       Colors.white,
          bgColor:     AppColors.sky,
          shadowColor: AppColors.skyDark,
          onTap:       onListen,
        ),
        const SizedBox(height: 12),
        // Record / Stop / Recorded
        _ActionButton(
          label: isRecording
              ? 'Stop Recording'
              : isRecorded
                  ? 'Recorded'
                  : 'Record',
          color:       Colors.white,
          bgColor:     isRecorded ? AppColors.green : AppColors.rose,
          shadowColor: isRecorded ? AppColors.greenDark : AppColors.roseDark,
          onTap:       isRecorded ? null : onToggleRecord,
        ),
        if (isRecording) ...[
          const SizedBox(height: 12),
          Center(
            child: Waveform(
              isActive:  true,
              barCount:  7,
              color:     AppColors.rose,
              barHeight: 28,
              barWidth:  5,
            ),
          ),
        ],
        const SizedBox(height: 12),
        // Play back
        _ActionButton(
          label: recordState == _RecordState.playing
              ? 'Stop'
              : 'Play Back',
          color:       canPlay ? Colors.white : AppColors.ink3,
          bgColor:     canPlay
              ? (recordState == _RecordState.playing
                  ? AppColors.rose
                  : AppColors.amber)
              : AppColors.ink5,
          shadowColor: canPlay
              ? (recordState == _RecordState.playing
                  ? AppColors.roseDark
                  : AppColors.amberDark)
              : null,
          onTap: canPlay ? onTogglePlay : null,
        ),
        if (uploadState == _UploadState.uploading) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  color: AppColors.green,
                  strokeWidth: 2,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Uploading this recording for review...',
                  style: AppText.caption(color: AppColors.green),
                ),
              ),
            ],
          ),
        ],
        if (uploadState == _UploadState.failed) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.roseLight,
              borderRadius: AppRadius.md,
              border: Border.all(color: AppColors.roseMid, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  uploadError ?? 'We could not save this recording yet.',
                  style: AppText.caption(color: AppColors.rose),
                ),
                const SizedBox(height: 10),
                _ActionButton(
                  label: 'Try Saving Again',
                  color: Colors.white,
                  bgColor: AppColors.rose,
                  shadowColor: AppColors.roseDark,
                  onTap: onRetryUpload,
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        // Finish
        _ActionButton(
          label: canFinish ? 'Send for Review' : 'Send for Review',
          color:       canFinish ? Colors.white : AppColors.ink3,
          bgColor:     canFinish ? AppColors.green : AppColors.ink5,
          shadowColor: canFinish ? AppColors.greenDark : null,
          onTap:       canFinish ? onFinish : null,
        ),
      ],
    );
  }
}

// â”€â”€â”€ Action button â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _UploadStatusLine extends StatelessWidget {
  const _UploadStatusLine({
    required this.uploadState,
    required this.uploadError,
  });

  final _UploadState uploadState;
  final String? uploadError;

  @override
  Widget build(BuildContext context) {
    if (uploadState == _UploadState.idle) {
      return const SizedBox(height: 22);
    }

    IconData icon;
    Color color;
    String text;

    switch (uploadState) {
      case _UploadState.uploading:
        icon = Icons.cloud_upload_rounded;
        color = AppColors.amberDark;
        text = 'Uploading for review';
        break;
      case _UploadState.uploaded:
        icon = Icons.check_circle_rounded;
        color = AppColors.green;
        text = 'Recording ready for review';
        break;
      case _UploadState.failed:
        icon = Icons.error_outline_rounded;
        color = AppColors.rose;
        text = uploadError ?? 'Recording needs another try';
        break;
      case _UploadState.idle:
        return const SizedBox(height: 22);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: AppText.caption(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.bgColor,
    this.shadowColor,
    this.onTap,
  });

  final String    label;
  final Color     color;
  final Color     bgColor;
  final Color?    shadowColor;
  final VoidCallback? onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;

    return GestureDetector(
      onTapDown:  enabled ? (_) => setState(() => _pressed = true)  : null,
      onTapUp:    enabled
          ? (_) { setState(() => _pressed = false); widget.onTap?.call(); }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration:           AppMotion.mid,
        curve:              AppMotion.spring,
        transform:          Matrix4.translationValues(0, _pressed ? 2 : 0, 0),
        transformAlignment: Alignment.center,
        constraints:        const BoxConstraints(minHeight: 52),
        padding:            const EdgeInsets.symmetric(
            vertical: 14, horizontal: 20),
        decoration: BoxDecoration(
          color:        widget.bgColor,
          borderRadius: AppRadius.pill,
          // Always 3 shadows when shadowColor is set â€” constant list length
          // prevents elasticOut overshoot from producing negative blurRadius.
          boxShadow: widget.shadowColor != null
              ? [
                  BoxShadow(
                    color:      widget.shadowColor!,
                    blurRadius: 0,
                    offset:     Offset(0, _pressed ? 1 : 3),
                  ),
                  BoxShadow(
                    color:      _pressed
                        ? Colors.transparent
                        : const Color(0x141C1917),
                    blurRadius: 8,
                    offset:     const Offset(0, 2),
                  ),
                  BoxShadow(
                    color:      _pressed
                        ? Colors.transparent
                        : const Color(0x0F1C1917),
                    blurRadius: 2,
                    offset:     const Offset(0, 1),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: Text(widget.label,
              style: AppText.button(color: widget.color)),
        ),
      ),
    );
  }
}

