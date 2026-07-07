import 'package:cloud_firestore/cloud_firestore.dart';

class RewardModel {
  final String childId;
  final int totalStars;
  final List<String> badges;

  const RewardModel({
    required this.childId,
    required this.totalStars,
    required this.badges,
  });

  factory RewardModel.fromJson(String childId, Map<String, dynamic> json) {
    return RewardModel(
      childId: childId,
      totalStars: json['totalStars'] as int? ?? 0,
      badges: List<String>.from(json['badges'] as List? ?? []),
    );
  }

  factory RewardModel.fromDoc(DocumentSnapshot doc) {
    return RewardModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'totalStars': totalStars,
    'badges': badges,
  };

  RewardModel copyWith({
    String? childId,
    int? totalStars,
    List<String>? badges,
  }) {
    return RewardModel(
      childId: childId ?? this.childId,
      totalStars: totalStars ?? this.totalStars,
      badges: badges ?? this.badges,
    );
  }
}
