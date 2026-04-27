import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/providers/admin_auth_provider.dart';

class AdminShellScreen extends ConsumerWidget {
  final Widget child;

  const AdminShellScreen({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthNotifierProvider);
    final profile = authState.profile;
    
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final String location = GoRouterState.of(context).matchedLocation;
    
    // Determine current index based on the route
    int currentIndex = 0;
    if (location.startsWith('/admin/dashboard')) currentIndex = 0;
    if (location.startsWith('/admin/vendors')) currentIndex = 1;
    if (location.startsWith('/admin/logs')) currentIndex = 2;
    if (location.startsWith('/admin/profile')) currentIndex = 3;

    // RBAC Check for Bottom Nav Tabs
    final permissions = profile.permissions;
    final canAccessVendors = permissions.contains('all') || permissions.contains('vendors_view');
    final canAccessLogs = permissions.contains('all') || permissions.contains('logs_view');

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index == 0) context.go('/admin/dashboard');
            if (index == 1 && canAccessVendors) context.go('/admin/vendors');
            if (index == 2 && canAccessLogs) context.go('/admin/logs');
            if (index == 3) context.go('/admin/profile');
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.blueGrey.shade300,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 10, letterSpacing: 0.5),
          items: [
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.home_filled)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4), 
                child: _buildIconWithLock(Icons.store, canAccessVendors),
              ),
              label: 'Vendors',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: const EdgeInsets.only(bottom: 4), 
                child: _buildIconWithLock(Icons.history_edu, canAccessLogs),
              ),
              label: 'Logs',
            ),
            const BottomNavigationBarItem(
              icon: Padding(padding: EdgeInsets.only(bottom: 4), child: Icon(Icons.account_circle)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconWithLock(IconData icon, bool hasAccess) {
    if (hasAccess) return Icon(icon);
    
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon, color: Colors.blueGrey.shade100),
        Positioned(
          top: -4,
          right: -8,
          child: Container(
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.lock, size: 12, color: Colors.blueGrey),
          ),
        ),
      ],
    );
  }
}
