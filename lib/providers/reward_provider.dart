import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward_model.dart';

class SessionRewardSummary {
  const SessionRewardSummary({
    required this.module,
    required this.earnedStars,
    required this.accuracy,
    required this.questionCount,
    required this.correctCount,
    this.pendingReview = false,
  });

  final String module;
  final int earnedStars;
  final double? accuracy;
  final int questionCount;
  final int correctCount;
  final bool pendingReview;
}

/// Live star-count and badge list for a single child.
/// Returns null when the document doesn't exist yet (no sessions completed).
final rewardProvider =
    StreamProvider.family<RewardModel?, String>((ref, childId) {
  return FirebaseFirestore.instance
      .collection('rewards')
      .doc(childId)
      .snapshots()
      .map((doc) => doc.exists ? RewardModel.fromDoc(doc) : null);
});

final pendingRewardSummaryProvider =
    StateProvider<SessionRewardSummary?>((ref) => null);
