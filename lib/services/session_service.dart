import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/session_model.dart';

class SessionHistoryPage {
  const SessionHistoryPage({
    required this.sessions,
    required this.cursor,
    required this.hasMore,
  });

  final List<SessionModel> sessions;
  final DocumentSnapshot<Map<String, dynamic>>? cursor;
  final bool hasMore;
}

class SessionService {
  final _db = FirebaseFirestore.instance;

  Future<String> createSession(SessionModel session) async {
    final ref = await _db
        .collection('sessions')
        .doc(session.childId)
        .collection('sessions')
        .add(session.toJson());
    return ref.id;
  }

  Future<void> updateSession({
    required String childId,
    required String sessionId,
    required Map<String, dynamic> fields,
  }) {
    return _db
        .collection('sessions')
        .doc(childId)
        .collection('sessions')
        .doc(sessionId)
        .update(fields);
  }

  Stream<List<SessionModel>> getSessionsForChild(String childId) {
    return _db
        .collection('sessions')
        .doc(childId)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SessionModel.fromJson(doc.id,
                doc.data()))
            .toList());
  }

  Stream<List<SessionModel>> getRecentSessions(String childId, {int limit = 10}) {
    return _db
        .collection('sessions')
        .doc(childId)
        .collection('sessions')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => SessionModel.fromJson(doc.id, doc.data()))
            .toList());
  }

  Future<SessionHistoryPage> fetchSessionHistoryPage({
    required String childId,
    required String filter,
    int limit = 20,
    DocumentSnapshot<Map<String, dynamic>>? startAfter,
  }) async {
    final collection = _db
        .collection('sessions')
        .doc(childId)
        .collection('sessions');

    DocumentSnapshot<Map<String, dynamic>>? cursor = startAfter;
    final matches = <SessionModel>[];
    final batchSize = limit.clamp(10, 50);
    var hasMore = true;

    while (matches.length < limit && hasMore) {
      Query<Map<String, dynamic>> query =
          collection.orderBy('timestamp', descending: true).limit(batchSize);

      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }

      final snap = await query.get();
      if (snap.docs.isEmpty) {
        hasMore = false;
        break;
      }

      for (final doc in snap.docs) {
        final session = SessionModel.fromJson(doc.id, doc.data());
        if (_matchesFilter(session, filter)) {
          matches.add(session);
          cursor = doc;
          if (matches.length >= limit) {
            break;
          }
        } else {
          cursor = doc;
        }
      }

      if (snap.docs.length < batchSize) {
        hasMore = false;
      }
    }

    return SessionHistoryPage(
      sessions: matches.take(limit).toList(),
      cursor: matches.isEmpty ? startAfter : cursor,
      hasMore: hasMore,
    );
  }

  bool _matchesFilter(SessionModel session, String filter) {
    switch (filter) {
      case 'guided':
        return session.activityType == 'guided';
      case 'fill_blank':
        return session.activityType == 'fill_blank';
      case 'speech':
        return session.module == 'speech';
      case 'all':
      default:
        return true;
    }
  }
}
