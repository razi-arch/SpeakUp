import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/session_model.dart';
import 'child_provider.dart';

/// Recent sessions across ALL linked children — used for admin dashboard
/// stats and the weekly accuracy chart.
final adminSessionsProvider = FutureProvider<List<SessionModel>>((ref) async {
  final children = ref.watch(linkedChildrenProvider).valueOrNull ?? [];
  if (children.isEmpty) return [];

  final db = FirebaseFirestore.instance;

  final snaps = await Future.wait(
    children.map(
      (child) => db
          .collection('sessions')
          .doc(child.id)
          .collection('sessions')
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get(),
    ),
  );

  final sessions = <SessionModel>[];
  for (final snap in snaps) {
    sessions.addAll(
        snap.docs.map((d) => SessionModel.fromJson(d.id, d.data())));
  }
  sessions.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  return sessions;
});
