import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../providers/child_provider.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_text.dart';

const kAdminSidebarBg = Color(0xFF1A5C42);

/// Shared sidebar for all admin screens.
/// Pass [currentPath] to highlight the active item.
class AdminSidebar extends ConsumerWidget {
  const AdminSidebar({required this.currentPath, super.key});
  final String currentPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> signOut() async {
      await ref.read(authServiceProvider).signOut();
      ref.read(adultAccessUnlockedProvider.notifier).state = false;
      ref.read(activeChildProvider.notifier).state = null;
    }

    return Container(
      width: 120,
      color: kAdminSidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'SpeakUp!',
              style: AppText.caption(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 20),
          _SidebarItem(
            icon: Icons.dashboard_rounded,
            label: 'Dashboard',
            isActive: currentPath == '/admin/dashboard',
            onTap: () => context.go('/admin/dashboard'),
          ),
          _SidebarItem(
            icon: Icons.person_add_rounded,
            label: 'Add Child',
            isActive: currentPath == '/admin/add-child',
            onTap: () => context.go('/admin/add-child'),
          ),
          _SidebarItem(
            icon: Icons.link_rounded,
            label: 'Link Code',
            isActive: currentPath == '/admin/link-code',
            onTap: () => context.go('/admin/link-code'),
          ),
          const Spacer(),
          _SidebarItem(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            isActive: false,
            onTap: signOut,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isActive ? Colors.white : Colors.white60;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.18)
              : Colors.transparent,
          borderRadius: AppRadius.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppText.caption(color: fg),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
