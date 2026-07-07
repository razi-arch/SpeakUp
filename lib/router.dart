import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'providers/child_provider.dart';
import 'screens/profile_picker_screen.dart';
import 'screens/confirm_profile_screen.dart';
import 'screens/child/child_home_screen.dart';
import 'screens/child/aac_board_screen.dart';
import 'screens/child/vocab_learning_screen.dart';
import 'screens/child/speech_practice_screen.dart';
import 'screens/child/reward_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/admin/admin_register_screen.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/admin/add_child_screen.dart';
import 'screens/admin/progress_screen.dart';
import 'screens/admin/progress_history_screen.dart';
import 'screens/admin/vocab_manager_screen.dart';
import 'screens/admin/recording_review_screen.dart';
import 'screens/admin/enter_invite_code_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);

  ref.listen(authStateProvider, (previous, next) {
    final nextUser = next.valueOrNull ?? ref.read(authServiceProvider).user;
    if (next.hasValue && nextUser == null) {
      ref.read(adultAccessUnlockedProvider.notifier).state = false;
      ref.read(activeChildProvider.notifier).state = null;
    }
    notifier.notify();
  });
  ref.listen(linkedChildrenProvider, (previous, next) {
    final activeChild = ref.read(activeChildProvider);
    final linkedChildren = next.valueOrNull;
    if (activeChild != null &&
        linkedChildren != null &&
        !linkedChildren.any((child) => child.id == activeChild.id)) {
      ref.read(adultAccessUnlockedProvider.notifier).state = false;
      ref.read(activeChildProvider.notifier).state = null;
    }
    notifier.notify();
  });
  ref.listen(
      adultAccessUnlockedProvider, (previous, next) => notifier.notify());
  ref.listen(activeChildProvider, (previous, next) => notifier.notify());

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ProfilePickerScreen(),
      ),
      GoRoute(
        path: '/confirm/:childId',
        builder: (_, state) => ConfirmProfileScreen(
          childId: state.pathParameters['childId']!,
        ),
      ),
      GoRoute(
        path: '/child/home',
        builder: (context, state) => const ChildHomeScreen(),
      ),
      GoRoute(
        path: '/child/aac',
        builder: (context, state) => const AACBoardScreen(),
      ),
      GoRoute(
        path: '/child/vocab',
        builder: (context, state) => const VocabLearningScreen(),
      ),
      GoRoute(
        path: '/child/speech',
        builder: (context, state) => const SpeechPracticeScreen(),
      ),
      GoRoute(
        path: '/child/reward',
        builder: (context, state) => const RewardScreen(),
      ),
      GoRoute(
        path: '/admin/login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/register',
        builder: (context, state) => const AdminRegisterScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/add-child',
        builder: (context, state) => const AddChildScreen(),
      ),
      GoRoute(
        path: '/admin/progress/:id',
        builder: (_, state) => ProgressScreen(
          childId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/progress/:id/history',
        builder: (_, state) => ProgressHistoryScreen(
          childId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/vocab/:id',
        builder: (_, state) => VocabManagerScreen(
          childId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/recordings/:id',
        builder: (_, state) => RecordingReviewScreen(
          childId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/admin/link-code',
        builder: (context, state) => const EnterInviteCodeScreen(),
      ),
    ],
  );

  ref.onDispose(() {
    router.dispose();   // GoRouter first â€” stops listening to notifier
    notifier.dispose(); // then ChangeNotifier â€” safe to dispose now
  });

  return router;
});

class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref);
  final Ref _ref;

  void notify() => notifyListeners();

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final authResolved = authState.hasValue || authState.hasError;
    final isAuthenticated =
        authState.valueOrNull != null ||
        _ref.read(authServiceProvider).user != null;
    final isAdultUnlocked = _ref.read(adultAccessUnlockedProvider);
    final activeChild = _ref.read(activeChildProvider);
    final hasActiveChild = activeChild != null;
    final linkedChildren = _ref.read(linkedChildrenProvider).valueOrNull;
    final loc = state.matchedLocation;

    if (loc.startsWith('/admin') && !authResolved) {
      return null;
    }

    if (_isChildRoute(loc) && !authResolved) {
      return null;
    }

    // Admin protected routes require auth
    if (loc.startsWith('/admin') &&
        loc != '/admin/login' &&
        loc != '/admin/register' &&
        !isAuthenticated) {
      return '/admin/login';
    }

    if (loc.startsWith('/admin') &&
        loc != '/admin/login' &&
        loc != '/admin/register' &&
        isAuthenticated &&
        !isAdultUnlocked) {
      return '/';
    }

    // Skip admin login/register if already authenticated
    if ((loc == '/admin/login' || loc == '/admin/register') &&
        isAuthenticated) {
      return isAdultUnlocked ? '/admin/dashboard' : null;
    }

    if (_isChildRoute(loc) && !isAuthenticated) {
      return '/';
    }

    if (_isChildRoute(loc) &&
        activeChild != null &&
        linkedChildren != null &&
        !linkedChildren.any((child) => child.id == activeChild.id)) {
      return '/';
    }

    // Child routes require an active child in the session
    if (_isChildRoute(loc) && !hasActiveChild) {
      return '/';
    }

    return null;
  }

  // /confirm/:childId is the gate â€” it must be reachable without an active child.
  // Only /child/* routes sit behind the guard.
  bool _isChildRoute(String loc) => loc.startsWith('/child');
}

