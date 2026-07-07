import '../models/session_model.dart';

class AccuracyBand {
  const AccuracyBand({
    required this.label,
    required this.minPercent,
    required this.maxPercent,
  });

  final String label;
  final int minPercent;
  final int maxPercent;
}

class ActivityProgressSummary {
  const ActivityProgressSummary({
    required this.activityId,
    required this.label,
    required this.sessionCount,
    required this.averageAccuracy,
  });

  final String activityId;
  final String label;
  final int sessionCount;
  final double? averageAccuracy;
}

class AacUsageSummary {
  const AacUsageSummary({
    required this.sessionCount,
    required this.totalDurationSeconds,
  });

  final int sessionCount;
  final int totalDurationSeconds;
}

class ProgressSummary {
  const ProgressSummary({
    required this.learningSessions,
    required this.guided,
    required this.fillBlank,
    required this.speech,
    required this.aacUsage,
  });

  final List<SessionModel> learningSessions;
  final ActivityProgressSummary guided;
  final ActivityProgressSummary fillBlank;
  final ActivityProgressSummary speech;
  final AacUsageSummary aacUsage;

  double? get averageAccuracy {
    if (learningSessions.isEmpty) return null;
    final total = learningSessions
        .map((session) => session.accuracy ?? 0.0)
        .fold<double>(0.0, (sum, value) => sum + value);
    return total / learningSessions.length;
  }
}

class ProgressSummaryService {
  const ProgressSummaryService();

  static const AccuracyBand highBand =
      AccuracyBand(label: 'high', minPercent: 80, maxPercent: 100);
  static const AccuracyBand moderateBand =
      AccuracyBand(label: 'moderate', minPercent: 50, maxPercent: 79);
  static const AccuracyBand lowBand =
      AccuracyBand(label: 'low', minPercent: 0, maxPercent: 49);

  ProgressSummary build(List<SessionModel> sessions) {
    final guidedSessions = sessions
        .where((session) =>
            session.activityType == 'guided' && session.isScored)
        .toList();
    final fillBlankSessions = sessions
        .where((session) =>
            session.activityType == 'fill_blank' && session.isScored)
        .toList();
    final speechSessions = sessions
        .where((session) => session.module == 'speech' && session.isScored)
        .toList();

    final learningSessions = [
      ...guidedSessions,
      ...fillBlankSessions,
      ...speechSessions,
    ]..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    final aacSessions = sessions.where((session) => session.module == 'aac').toList();

    return ProgressSummary(
      learningSessions: learningSessions,
      guided: _buildActivitySummary(
        activityId: 'guided',
        label: 'Guided Questions',
        sessions: guidedSessions,
      ),
      fillBlank: _buildActivitySummary(
        activityId: 'fill_blank',
        label: 'Fill in the Blank',
        sessions: fillBlankSessions,
      ),
      speech: _buildActivitySummary(
        activityId: 'speech',
        label: 'Speech Practice',
        sessions: speechSessions,
      ),
      aacUsage: AacUsageSummary(
        sessionCount: aacSessions.length,
        totalDurationSeconds: aacSessions.fold<int>(
          0,
          (sum, session) => sum + session.durationSeconds,
        ),
      ),
    );
  }

  List<SessionModel> scoredSessionsForLast7Days(List<SessionModel> sessions) {
    final learningSessions = build(sessions).learningSessions;
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 6));
    return learningSessions
        .where((session) => !session.timestamp.isBefore(start))
        .toList();
  }

  List<SessionModel> dashboardPreviewSessions(List<SessionModel> sessions) {
    final preview = sessions
        .where((session) => session.module != 'aac')
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return preview.take(10).toList();
  }

  bool isLearningHistorySession(SessionModel session) =>
      session.module != 'aac';

  AccuracyBand bandForAccuracy(double? accuracy) {
    final percent = ((accuracy ?? 0.0) * 100).round();
    if (percent >= highBand.minPercent) return highBand;
    if (percent >= moderateBand.minPercent) return moderateBand;
    return lowBand;
  }

  ActivityProgressSummary _buildActivitySummary({
    required String activityId,
    required String label,
    required List<SessionModel> sessions,
  }) {
    if (sessions.isEmpty) {
      return ActivityProgressSummary(
        activityId: activityId,
        label: label,
        sessionCount: 0,
        averageAccuracy: null,
      );
    }

    final total = sessions
        .map((session) => session.accuracy ?? 0.0)
        .fold<double>(0.0, (sum, value) => sum + value);

    return ActivityProgressSummary(
      activityId: activityId,
      label: label,
      sessionCount: sessions.length,
      averageAccuracy: total / sessions.length,
    );
  }
}
