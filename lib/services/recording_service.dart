import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../models/recording_model.dart';
import '../services/reward_logic.dart';

class RecordingSaveException implements Exception {
  const RecordingSaveException({
    required this.userMessage,
    required this.debugMessage,
  });

  final String userMessage;
  final String debugMessage;

  @override
  String toString() => 'RecordingSaveException($debugMessage)';
}

class UploadedRecording {
  const UploadedRecording({
    required this.recordingId,
    required this.storagePath,
    required this.storageUrl,
  });

  final String recordingId;
  final String storagePath;
  final String storageUrl;
}

class RecordingUploadAccessCheck {
  const RecordingUploadAccessCheck({
    required this.allowed,
    required this.userMessage,
    required this.debugMessage,
  });

  final bool allowed;
  final String userMessage;
  final String debugMessage;
}

class RecordingService {
  RecordingService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  String newRecordingId() => _db.collection('_').doc().id;

  Future<RecordingUploadAccessCheck> checkUploadAccess({
    required String childId,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return const RecordingUploadAccessCheck(
        allowed: false,
        userMessage:
            'Please sign in as the parent or teacher before sending a recording.',
        debugMessage: 'No authenticated user was available for upload.',
      );
    }

    final childSnap = await _db.collection('children').doc(childId).get();
    if (!childSnap.exists) {
      return const RecordingUploadAccessCheck(
        allowed: false,
        userMessage:
            'This child profile could not be found right now. Please reopen the profile and try again.',
        debugMessage: 'Child document did not exist during upload access check.',
      );
    }

    final linkedUsers = List<String>.from(
      childSnap.data()?['linkedUsers'] as List? ?? const [],
    );
    if (!linkedUsers.contains(currentUser.uid)) {
      return RecordingUploadAccessCheck(
        allowed: false,
        userMessage:
            'This signed-in adult account is not linked to this child profile, so recordings cannot be sent for review yet.',
        debugMessage:
            'Authenticated user ${currentUser.uid} was not in child $childId linkedUsers.',
      );
    }

    return RecordingUploadAccessCheck(
      allowed: true,
      userMessage: 'ok',
      debugMessage:
          'Authenticated user ${currentUser.uid} is linked to child $childId.',
    );
  }

  Stream<List<RecordingModel>> watchRecordings(String childId) {
    return _db
        .collection('recordings')
        .doc(childId)
        .collection('recordings')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RecordingModel.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<UploadedRecording> uploadRecordingFile({
    required String childId,
    required String recordingId,
    String? filePath,
    Uint8List? bytes,
    String fileExtension = 'aac',
    String contentType = 'audio/aac',
  }) async {
    try {
      final accessCheck = await checkUploadAccess(childId: childId);
      if (!accessCheck.allowed) {
        throw RecordingSaveException(
          userMessage: accessCheck.userMessage,
          debugMessage: accessCheck.debugMessage,
        );
      }
      final currentUser = _auth.currentUser!;

      if ((filePath == null || filePath.trim().isEmpty) &&
          (bytes == null || bytes.isEmpty)) {
        throw const RecordingSaveException(
          userMessage: 'We could not find the recording file. Please try again.',
          debugMessage: 'No speech recording path or bytes were provided.',
        );
      }

      var uploadBytes = bytes ?? Uint8List(0);

      if (uploadBytes.isEmpty) {
        final file = File(filePath!);
        if (!await file.exists()) {
          throw const RecordingSaveException(
            userMessage: 'We could not find the recording file. Please try again.',
            debugMessage: 'Speech recording file does not exist on disk.',
          );
        }

        for (var attempt = 0; attempt < 3; attempt++) {
          uploadBytes = await file.readAsBytes();
          if (uploadBytes.isNotEmpty) break;
          await Future<void>.delayed(const Duration(milliseconds: 250));
        }
      }

      if (uploadBytes.isEmpty) {
        throw const RecordingSaveException(
          userMessage:
              'The recording was empty, so it could not be saved. Please record it again.',
          debugMessage: 'Speech recording file was empty after recording stop.',
        );
      }

      final normalizedExtension = fileExtension.trim().replaceFirst('.', '');
      final storagePath =
          'recordings/$childId/$recordingId.$normalizedExtension';
      final ref = _storage.ref().child(storagePath);
      await ref.putData(
        uploadBytes,
        SettableMetadata(
          contentType: contentType,
          customMetadata: {
            'childId': childId,
            'recordingId': recordingId,
            'uploadedBy': currentUser.uid,
          },
        ),
      );
      final storageUrl = await ref.getDownloadURL();

      return UploadedRecording(
        recordingId: recordingId,
        storagePath: storagePath,
        storageUrl: storageUrl,
      );
    } catch (error) {
      if (error is RecordingSaveException) rethrow;
      if (error is FirebaseException) {
        final userMessage = switch (error.code) {
          'unauthenticated' || 'unauthorized' || 'permission-denied' =>
            'This child is signed in correctly, but Firebase Storage is still blocking uploads for project speakup-69ed7. The Storage rules or bucket setup still need attention.',
          _ => 'We could not save this recording yet. Please try again.',
        };
        throw RecordingSaveException(
          userMessage: userMessage,
          debugMessage: 'FirebaseStorage ${error.code}: ${error.message}',
        );
      }
      throw RecordingSaveException(
        userMessage: 'We could not save this recording yet. Please try again.',
        debugMessage: error.toString(),
      );
    }
  }

  Future<void> createRecording({
    required String childId,
    required String recordingId,
    required String sessionId,
    required String word,
    required String storagePath,
    required String storageUrl,
    required DateTime timestamp,
  }) {
    return _db
        .collection('recordings')
        .doc(childId)
        .collection('recordings')
        .doc(recordingId)
        .set({
      'childId': childId,
      'sessionId': sessionId,
      'word': word,
      'storagePath': storagePath,
      'storageUrl': storageUrl,
      'status': 'ready',
      'timestamp': Timestamp.fromDate(timestamp),
      'reviewStars': null,
      'reviewComment': null,
      'reviewedAt': null,
      'reviewedBy': null,
    });
  }

  Future<void> saveReview({
    required String childId,
    required String recordingId,
    required int score,
    required String comment,
  }) async {
    final recordingRef = _db
        .collection('recordings')
        .doc(childId)
        .collection('recordings')
        .doc(recordingId);

    final recordingSnap = await recordingRef.get();
    if (!recordingSnap.exists) {
      throw StateError('Recording $recordingId was not found.');
    }

    final recording = RecordingModel.fromJson(recordingSnap.id, recordingSnap.data()!);
    final previousReviewStars = recording.reviewStars ?? 0;
    final nextReviewStars = speechStarsForReview(score);
    final rewardDelta = nextReviewStars - previousReviewStars;
    final reviewPercent = nextReviewStars / 5;
    final trimmedComment = comment.trim();
    final reviewerId = _auth.currentUser?.uid;

    final rewardsRef = _db.collection('rewards').doc(childId);
    final rewardsSnap = await rewardsRef.get();
    final currentStars = rewardsSnap.data()?['totalStars'] as int? ?? 0;
    final existingBadges =
        List<String>.from(rewardsSnap.data()?['badges'] as List? ?? const []);
    final nextTotalStars = (currentStars + rewardDelta).clamp(0, 1 << 30);
    final newBadges = unlockedBadgeIds(
      previousStars: currentStars,
      newTotalStars: nextTotalStars,
      existingBadges: existingBadges,
    );

    final batch = _db.batch();

    batch.update(recordingRef, {
      'reviewStars': nextReviewStars,
      'reviewComment': trimmedComment.isEmpty ? null : trimmedComment,
      'reviewedAt': FieldValue.serverTimestamp(),
      'reviewedBy': reviewerId,
    });

    batch.update(
      _db
          .collection('sessions')
          .doc(childId)
          .collection('sessions')
          .doc(recording.sessionId),
      {
        'accuracy': reviewPercent,
        'scoreStatus': 'reviewed',
        'recordingId': recordingId,
      },
    );

    batch.set(
      rewardsRef,
      {
        'totalStars': nextTotalStars,
        if (newBadges.isNotEmpty) 'badges': FieldValue.arrayUnion(newBadges),
      },
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  Future<void> deleteRecording({
    required String childId,
    required String recordingId,
  }) async {
    final recordingRef = _db
        .collection('recordings')
        .doc(childId)
        .collection('recordings')
        .doc(recordingId);

    final recordingSnap = await recordingRef.get();
    if (!recordingSnap.exists) {
      throw StateError('Recording $recordingId was not found.');
    }

    final recording =
        RecordingModel.fromJson(recordingSnap.id, recordingSnap.data()!);
    final removedStars = speechStarsForReview(recording.reviewStars ?? 0);

    final batch = _db.batch();
    batch.delete(recordingRef);

    if (recording.sessionId.trim().isNotEmpty) {
      batch.delete(
        _db
            .collection('sessions')
            .doc(childId)
            .collection('sessions')
            .doc(recording.sessionId),
      );
    }

    if (removedStars > 0) {
      final rewardsRef = _db.collection('rewards').doc(childId);
      final rewardsSnap = await rewardsRef.get();
      final currentStars = rewardsSnap.data()?['totalStars'] as int? ?? 0;
      final nextTotalStars = (currentStars - removedStars).clamp(0, 1 << 30);

      batch.set(
        rewardsRef,
        {'totalStars': nextTotalStars},
        SetOptions(merge: true),
      );
    }

    await batch.commit();

    final storagePath = recording.storagePath;
    final storageUrl = recording.storageUrl;
    if (storagePath == null && storageUrl == null) {
      return;
    }

    try {
      if (storagePath != null && storagePath.isNotEmpty) {
        await _storage.ref().child(storagePath).delete();
        return;
      }
      if (storageUrl != null && storageUrl.isNotEmpty) {
        await _storage.refFromURL(storageUrl).delete();
      }
    } on FirebaseException {
      // The record itself is already removed, so a storage cleanup miss
      // should not block the delete experience.
    }
  }
}
