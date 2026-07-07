
import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String childId;
  final String module; // 'aac' | 'vocab' | 'speech'
  final String? activityType; // e.g. 'guided' | 'fill_blank'
  final double? accuracy;
  final String scoreStatus; // 'reviewed' | 'pending' | 'not_applicable'
  final String? recordingId;
  final int wordsAttempted;
  final int durationSeconds;
  final DateTime timestamp;

  const SessionModel({
    required this.id,
    required this.childId,
    required this.module,
    this.activityType,
    required this.accuracy,
    required this.scoreStatus,
    this.recordingId,
    required this.wordsAttempted,
    required this.durationSeconds,
    required this.timestamp,
  });

  factory SessionModel.fromJson(String id, Map<String, dynamic> json) {
    final module = json['module'] as String;
    final rawAccuracy = json['accuracy'];
    final rawStatus = json['scoreStatus'] as String?;

    return SessionModel(
      id: id,
      childId: json['childId'] as String,
      module: module,
      activityType: json['activityType'] as String?,
      accuracy: rawAccuracy == null ? null : (rawAccuracy as num).toDouble(),
      scoreStatus: rawStatus ?? _inferScoreStatus(module, rawAccuracy),
      recordingId: json['recordingId'] as String?,
      wordsAttempted: (json['wordsAttempted'] as num).toInt(),
      durationSeconds: (json['durationSeconds'] as num).toInt(),
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }

  factory SessionModel.fromDoc(DocumentSnapshot doc) {
    return SessionModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'childId': childId,
    'module': module,
    'activityType': activityType,
    'accuracy': accuracy,
    'scoreStatus': scoreStatus,
    'recordingId': recordingId,
    'wordsAttempted': wordsAttempted,
    'durationSeconds': durationSeconds,
    'timestamp': Timestamp.fromDate(timestamp),
  };

  SessionModel copyWith({
    String? id,
    String? childId,
    String? module,
    String? activityType,
    Object? accuracy = _unset,
    String? scoreStatus,
    Object? recordingId = _unset,
    int? wordsAttempted,
    int? durationSeconds,
    DateTime? timestamp,
  }) {
    return SessionModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      module: module ?? this.module,
      activityType: activityType ?? this.activityType,
      accuracy: identical(accuracy, _unset) ? this.accuracy : accuracy as double?,
      scoreStatus: scoreStatus ?? this.scoreStatus,
      recordingId: identical(recordingId, _unset)
          ? this.recordingId
          : recordingId as String?,
      wordsAttempted: wordsAttempted ?? this.wordsAttempted,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  static const Object _unset = Object();

  static String _inferScoreStatus(String module, Object? _) {
    if (module == 'aac') return 'not_applicable';
    if (module == 'speech') return 'pending';
    return 'reviewed';
  }

  bool get hasRecordingLink =>
      recordingId != null && recordingId!.trim().isNotEmpty;

  bool get isScored {
    if (module == 'speech') {
      return scoreStatus == 'reviewed' && accuracy != null && hasRecordingLink;
    }
    return scoreStatus == 'reviewed' && accuracy != null;
  }

  bool get isPendingReview {
    if (module == 'speech') {
      return !isScored;
    }
    return scoreStatus == 'pending';
  }

  bool get isAac => module == 'aac' || scoreStatus == 'not_applicable';
}
