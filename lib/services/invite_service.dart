import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';
import '../models/invite_code_model.dart';

class InviteService {
  final _db = FirebaseFirestore.instance;

  Future<String> generateCode(String childId, String createdBy) async {
    final code = _sixDigitCode();
    await _db.collection('inviteCodes').doc(code).set(
      InviteCodeModel(
        code: code,
        childId: childId,
        createdBy: createdBy,
        expiresAt: DateTime.now().add(const Duration(hours: 48)),
        used: false,
      ).toJson(),
    );
    return code;
  }

  Future<ChildModel> redeemCode(String code, String uid) async {
    final ref = _db.collection('inviteCodes').doc(code);

    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (!snap.exists) throw 'Invalid code';

      final invite = InviteCodeModel.fromDoc(snap);
      if (invite.used)    throw 'Code already used';
      if (invite.isExpired) throw 'Code expired';

      final childRef = _db.collection('children').doc(invite.childId);
      tx.update(childRef, {
        'linkedUsers': FieldValue.arrayUnion([uid]),
      });
      tx.update(ref, {'used': true});

      final childSnap = await tx.get(childRef);
      return ChildModel.fromDoc(childSnap);
    });
  }

  String _sixDigitCode() =>
      (Random.secure().nextInt(900000) + 100000).toString();
}
