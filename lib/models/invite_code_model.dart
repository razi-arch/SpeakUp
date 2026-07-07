import 'package:cloud_firestore/cloud_firestore.dart';

class InviteCodeModel {
  final String code;
  final String childId;
  final String createdBy;
  final DateTime expiresAt;
  final bool used;

  const InviteCodeModel({
    required this.code,
    required this.childId,
    required this.createdBy,
    required this.expiresAt,
    required this.used,
  });

  factory InviteCodeModel.fromJson(String code, Map<String, dynamic> json) {
    return InviteCodeModel(
      code: code,
      childId: json['childId'] as String,
      createdBy: json['createdBy'] as String,
      expiresAt: (json['expiresAt'] as Timestamp).toDate(),
      used: json['used'] as bool? ?? false,
    );
  }

  factory InviteCodeModel.fromDoc(DocumentSnapshot doc) {
    return InviteCodeModel.fromJson(doc.id, doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() => {
    'childId': childId,
    'createdBy': createdBy,
    'expiresAt': Timestamp.fromDate(expiresAt),
    'used': used,
  };

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !used && !isExpired;

  InviteCodeModel copyWith({
    String? code,
    String? childId,
    String? createdBy,
    DateTime? expiresAt,
    bool? used,
  }) {
    return InviteCodeModel(
      code: code ?? this.code,
      childId: childId ?? this.childId,
      createdBy: createdBy ?? this.createdBy,
      expiresAt: expiresAt ?? this.expiresAt,
      used: used ?? this.used,
    );
  }
}
