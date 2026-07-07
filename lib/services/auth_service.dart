import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/adult_profile.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db   = FirebaseFirestore.instance;

  Stream<User?> get currentUser => _auth.authStateChanges();

  User? get user => _auth.currentUser;

  Future<UserCredential> signIn(String email, String password) {
    return _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> signOut() => _auth.signOut();

  Future<AdultProfile?> getAdultProfile(String uid) async {
    final ref = _db.collection('users').doc(uid);
    final doc = await ref.get();
    if (!doc.exists) return null;

    final data = doc.data()!;
    final savedPin = data['pinCode'] as String?;
    final savedEmail = (data['email'] as String? ?? '').toLowerCase();

    // One-time migration for the existing lecturer demo account.
    if ((savedPin == null || savedPin.isEmpty) &&
        savedEmail == 'razidisini@gmail.com') {
      await ref.update({'pinCode': '0306'});
      data['pinCode'] = '0306';
    }

    return AdultProfile.fromJson(doc.id, data);
  }

  Future<String?> getUserRole(String uid) async {
    final profile = await getAdultProfile(uid);
    return profile?.role;
  }

  Future<void> updateAccessPin(String uid, String pinCode) {
    return _db.collection('users').doc(uid).update({'pinCode': pinCode});
  }

  Future<void> register({
    required String email,
    required String password,
    required String role,
    required Map<String, dynamic> profileData,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _db.collection('users').doc(credential.user!.uid).set({
      'role':          role,
      'email':         email,
      'emailVerified': true,
      'createdAt':     FieldValue.serverTimestamp(),
      ...profileData,
    });

    // Return to the normal sign-in flow after registration completes.
    await _auth.signOut();
  }
}
