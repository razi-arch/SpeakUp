import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/adult_profile.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).currentUser;
});

final adultProfileProvider = FutureProvider<AdultProfile?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull ??
      ref.watch(authServiceProvider).user;
  if (user == null) return null;
  return ref.watch(authServiceProvider).getAdultProfile(user.uid);
});

final userRoleProvider = Provider<String?>((ref) {
  return ref.watch(adultProfileProvider).valueOrNull?.role;
});

final adultAccessUnlockedProvider = StateProvider<bool>((ref) => false);

final isAdminProvider = Provider<bool>((ref) {
  return ref.watch(adultProfileProvider).valueOrNull != null;
});
