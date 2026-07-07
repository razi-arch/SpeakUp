import 'package:cloud_firestore/cloud_firestore.dart';

class ChildModel {
  final String id;
  final String name;
  final String avatarEmoji;
  final String avatarGradientStart;
  final String avatarGradientEnd;
  final String difficulty; // 'beginner' | 'intermediate' | 'advanced'
  final int qaMode;        // 2 | 4
  final List<String> linkedUsers;
  final String createdBy;
  final bool isActiveOnDevice;

  const ChildModel({
    required this.id,
    required this.name,
    required this.avatarEmoji,
    required this.avatarGradientStart,
    required this.avatarGradientEnd,
    required this.difficulty,
    required this.qaMode,
    required this.linkedUsers,
    required this.createdBy,
    required this.isActiveOnDevice,
  });

  factory ChildModel.fromJson(String id, Map<String, dynamic> json) {
    return ChildModel(
      id: id,
      name: json['name'] as String,
      avatarEmoji: json['avatarEmoji'] as String,
      avatarGradientStart: json['avatarGradientStart'] as String,
      avatarGradientEnd: json['avatarGradientEnd'] as String,
      difficulty: json['difficulty'] as String,
      qaMode: (json['qaMode'] as num).toInt(),
      linkedUsers: List<String>.from(json['linkedUsers'] as List),
      createdBy: json['createdBy'] as String,
      isActiveOnDevice: json['isActiveOnDevice'] as bool? ?? false,
    );
  }

  factory ChildModel.fromDoc(DocumentSnapshot doc) {
    return ChildModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'avatarEmoji': avatarEmoji,
    'avatarGradientStart': avatarGradientStart,
    'avatarGradientEnd': avatarGradientEnd,
    'difficulty': difficulty,
    'qaMode': qaMode,
    'linkedUsers': linkedUsers,
    'createdBy': createdBy,
    'isActiveOnDevice': isActiveOnDevice,
  };

  ChildModel copyWith({
    String? id,
    String? name,
    String? avatarEmoji,
    String? avatarGradientStart,
    String? avatarGradientEnd,
    String? difficulty,
    int? qaMode,
    List<String>? linkedUsers,
    String? createdBy,
    bool? isActiveOnDevice,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      avatarGradientStart: avatarGradientStart ?? this.avatarGradientStart,
      avatarGradientEnd: avatarGradientEnd ?? this.avatarGradientEnd,
      difficulty: difficulty ?? this.difficulty,
      qaMode: qaMode ?? this.qaMode,
      linkedUsers: linkedUsers ?? this.linkedUsers,
      createdBy: createdBy ?? this.createdBy,
      isActiveOnDevice: isActiveOnDevice ?? this.isActiveOnDevice,
    );
  }
}
