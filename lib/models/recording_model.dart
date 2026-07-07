import 'package:cloud_firestore/cloud_firestore.dart';

class RecordingModel {
  const RecordingModel({
    required this.id,
    required this.childId,
    required this.sessionId,
    required this.localFilePath,
    required this.storagePath,
    required this.storageUrl,
    required this.word,
    required this.timestamp,
    required this.status,
    required this.saveError,
    this.reviewStars,
    this.reviewComment,
    this.reviewedAt,
    this.reviewedBy,
  });

  final String id;
  final String childId;
  final String sessionId;
  final String? localFilePath;
  final String? storagePath;
  final String? storageUrl;
  final String word;
  final DateTime timestamp;
  final String status;
  final String? saveError;
  final int? reviewStars;
  final String? reviewComment;
  final DateTime? reviewedAt;
  final String? reviewedBy;

  factory RecordingModel.fromJson(String id, Map<String, dynamic> json) {
    final localFilePath = (json['localFilePath'] as String?)?.trim();
    final storagePath = (json['storagePath'] as String?)?.trim();
    final storageUrl = (json['storageUrl'] as String?)?.trim();
    final rawTimestamp = json['timestamp'];
    final rawReviewedAt = json['reviewedAt'];
    final status = (json['status'] as String?)?.trim();

    return RecordingModel(
      id: id,
      childId: json['childId'] as String,
      sessionId: (json['sessionId'] as String?) ?? '',
      localFilePath:
          localFilePath == null || localFilePath.isEmpty ? null : localFilePath,
      storagePath: storagePath == null || storagePath.isEmpty ? null : storagePath,
      storageUrl: storageUrl == null || storageUrl.isEmpty ? null : storageUrl,
      word: json['word'] as String,
      timestamp: _parseTimestamp(rawTimestamp),
      status: status == null || status.isEmpty
          ? (((storageUrl != null && storageUrl.isNotEmpty) ||
                  (localFilePath != null && localFilePath.isNotEmpty))
              ? 'ready'
              : 'failed')
          : status,
      saveError: (json['saveError'] as String?) ?? (json['uploadError'] as String?),
      reviewStars: json['reviewStars'] as int? ?? json['adminScore'] as int?,
      reviewComment:
          json['reviewComment'] as String? ?? json['adminComment'] as String?,
      reviewedAt: _parseNullableTimestamp(rawReviewedAt),
      reviewedBy: json['reviewedBy'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'childId': childId,
        'sessionId': sessionId,
        'localFilePath': localFilePath,
        'storagePath': storagePath,
        'storageUrl': storageUrl,
        'word': word,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'status': status,
        'saveError': saveError,
        'reviewStars': reviewStars,
        'reviewComment': reviewComment,
        'reviewedAt': reviewedAt?.millisecondsSinceEpoch,
        'reviewedBy': reviewedBy,
      };

  static DateTime? _parseNullableTimestamp(Object? rawTimestamp) {
    if (rawTimestamp == null) return null;
    if (rawTimestamp is Timestamp) return rawTimestamp.toDate();
    if (rawTimestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    }
    if (rawTimestamp is String) {
      final parsedInt = int.tryParse(rawTimestamp);
      if (parsedInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt);
      }
      return DateTime.tryParse(rawTimestamp);
    }
    return null;
  }

  static DateTime _parseTimestamp(Object? rawTimestamp) {
    if (rawTimestamp is Timestamp) {
      return rawTimestamp.toDate();
    }
    if (rawTimestamp is int) {
      return DateTime.fromMillisecondsSinceEpoch(rawTimestamp);
    }
    if (rawTimestamp is String) {
      final parsedInt = int.tryParse(rawTimestamp);
      if (parsedInt != null) {
        return DateTime.fromMillisecondsSinceEpoch(parsedInt);
      }
      final parsedDate = DateTime.tryParse(rawTimestamp);
      if (parsedDate != null) {
        return parsedDate;
      }
    }
    return DateTime.now();
  }

  static const Object _unset = Object();

  RecordingModel copyWith({
    String? id,
    String? childId,
    String? sessionId,
    Object? localFilePath = _unset,
    Object? storagePath = _unset,
    Object? storageUrl = _unset,
    String? word,
    DateTime? timestamp,
    String? status,
    Object? saveError = _unset,
    Object? reviewStars = _unset,
    Object? reviewComment = _unset,
    Object? reviewedAt = _unset,
    Object? reviewedBy = _unset,
  }) {
    return RecordingModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      sessionId: sessionId ?? this.sessionId,
      localFilePath: identical(localFilePath, _unset)
          ? this.localFilePath
          : localFilePath as String?,
      storagePath: identical(storagePath, _unset)
          ? this.storagePath
          : storagePath as String?,
      storageUrl: identical(storageUrl, _unset)
          ? this.storageUrl
          : storageUrl as String?,
      word: word ?? this.word,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      saveError:
          identical(saveError, _unset) ? this.saveError : saveError as String?,
      reviewStars: identical(reviewStars, _unset)
          ? this.reviewStars
          : reviewStars as int?,
      reviewComment: identical(reviewComment, _unset)
          ? this.reviewComment
          : reviewComment as String?,
      reviewedAt: identical(reviewedAt, _unset)
          ? this.reviewedAt
          : reviewedAt as DateTime?,
      reviewedBy: identical(reviewedBy, _unset)
          ? this.reviewedBy
          : reviewedBy as String?,
    );
  }

  bool get isSaving => status == 'saving' || status == 'uploading';
  bool get isUploading => isSaving;
  bool get isReady =>
      status == 'ready' &&
      ((storageUrl != null && storageUrl!.isNotEmpty) ||
          (localFilePath != null && localFilePath!.isNotEmpty));
  bool get isFailed => status == 'failed';
  bool get isReviewed => reviewStars != null;
}
