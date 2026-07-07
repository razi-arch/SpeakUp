class AdultProfile {
  const AdultProfile({
    required this.uid,
    required this.email,
    required this.role,
    required this.fullName,
    required this.emailVerified,
    this.pinCode,
  });

  final String uid;
  final String email;
  final String role;
  final String fullName;
  final bool emailVerified;
  final String? pinCode;

  bool get hasPin => (pinCode ?? '').length == 4;

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'Parent / Teacher';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  factory AdultProfile.fromJson(String uid, Map<String, dynamic> json) {
    return AdultProfile(
      uid: uid,
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      emailVerified: json['emailVerified'] as bool? ?? false,
      pinCode: json['pinCode'] as String?,
    );
  }
}
