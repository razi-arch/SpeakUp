import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child_model.dart';

class ChildService {
  final _db = FirebaseFirestore.instance;

  Stream<List<ChildModel>> getLinkedChildren(String uid) {
    return _db
        .collection('children')
        .where('linkedUsers', arrayContains: uid)
        .snapshots()
        .map((snap) => snap.docs.map(ChildModel.fromDoc).toList());
  }

  Future<String> createChild(ChildModel child) async {
    final ref = await _db.collection('children').add(child.toJson());
    return ref.id;
  }

  Future<void> updateChild(String childId, Map<String, dynamic> fields) {
    return _db.collection('children').doc(childId).update(fields);
  }

  Future<void> setActiveChild(
    String childId,
    bool active, {
    List<String> linkedChildIds = const [],
  }) async {
    final batch = _db.batch();

    if (active) {
      // Only touch the already-loaded linked children for this user. This keeps
      // the batch within the caller's permitted documents and avoids a broad
      // collection query that Firestore rules can reject.
      for (final linkedChildId in linkedChildIds) {
        batch.update(
          _db.collection('children').doc(linkedChildId),
          {'isActiveOnDevice': linkedChildId == childId},
        );
      }
    } else {
      batch.update(
        _db.collection('children').doc(childId),
        {'isActiveOnDevice': false},
      );
    }

    await batch.commit();
  }

  Future<ChildModel?> getChild(String childId) async {
    final doc = await _db.collection('children').doc(childId).get();
    if (!doc.exists) return null;
    return ChildModel.fromDoc(doc);
  }
}
