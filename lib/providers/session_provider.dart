import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/session_model.dart';
import '../services/session_service.dart';
import 'child_provider.dart';

final sessionServiceProvider =
    Provider<SessionService>((ref) => SessionService());

// Admin progress screen — all sessions for an arbitrary child
final childSessionsProvider =
    StreamProvider.family<List<SessionModel>, String>((ref, childId) {
  return ref.watch(sessionServiceProvider).getSessionsForChild(childId);
});

final recentSessionsProvider = StreamProvider<List<SessionModel>>((ref) {
  final child = ref.watch(activeChildProvider);
  if (child == null) return const Stream.empty();
  return ref
      .watch(sessionServiceProvider)
      .getRecentSessions(child.id, limit: 10);
});

// Tracks the in-progress session's start time and module
class CurrentSession {
  final String module;
  final DateTime startedAt;
  final List<bool> results; // true = correct, false = wrong

  const CurrentSession({
    required this.module,
    required this.startedAt,
    this.results = const [],
  });

  CurrentSession addResult(bool correct) => CurrentSession(
        module: module,
        startedAt: startedAt,
        results: [...results, correct],
      );

  double get accuracy =>
      results.isEmpty ? 0 : results.where((r) => r).length / results.length;

  int get durationSeconds =>
      DateTime.now().difference(startedAt).inSeconds;
}

class CurrentSessionNotifier extends Notifier<CurrentSession?> {
  @override
  CurrentSession? build() => null;

  void start(String module) {
    state = CurrentSession(module: module, startedAt: DateTime.now());
  }

  void recordResult(bool correct) {
    state = state?.addResult(correct);
  }

  Future<void> finish(WidgetRef ref) async {
    final session = state;
    final child   = ref.read(activeChildProvider);
    if (session == null || child == null) return;

    await ref.read(sessionServiceProvider).createSession(SessionModel(
          id: '',
          childId: child.id,
          module: session.module,
          accuracy: session.accuracy,
          scoreStatus:
              session.module == 'aac' ? 'not_applicable' : 'reviewed',
          wordsAttempted: session.results.length,
          durationSeconds: session.durationSeconds,
          timestamp: DateTime.now(),
        ));
    state = null;
  }
}

final currentSessionProvider =
    NotifierProvider<CurrentSessionNotifier, CurrentSession?>(
        CurrentSessionNotifier.new);
