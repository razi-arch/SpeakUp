import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/child_model.dart';
import '../services/child_service.dart';
import '../services/invite_service.dart';
import 'auth_provider.dart';

final childServiceProvider = Provider<ChildService>((ref) => ChildService());
final inviteServiceProvider = Provider<InviteService>((ref) => InviteService());

final linkedChildrenProvider = StreamProvider<List<ChildModel>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(authServiceProvider).user;
  // Emit an empty list rather than never emitting, so the Profile Picker can
  // show a "login to set up" state instead of spinning forever.
  if (user == null) return Stream.value(const []);
  return ref.watch(childServiceProvider).getLinkedChildren(user.uid);
});

// The child currently selected for this session
final activeChildProvider = StateProvider<ChildModel?>((ref) => null);

// Convenience — the child flagged isActiveOnDevice in Firestore
final deviceActiveChildProvider = Provider<ChildModel?>((ref) {
  final children = ref.watch(linkedChildrenProvider).valueOrNull ?? [];
  try {
    return children.firstWhere((c) => c.isActiveOnDevice);
  } catch (_) {
    return null;
  }
});
