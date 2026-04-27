import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../auth/providers/admin_auth_provider.dart';
import '../../auth/models/admin_auth_models.dart';

class AdminProfileScreen extends ConsumerWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthNotifierProvider);
    final AdminProfile? profile = authState.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Text('Profile & Settings', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Avatar + Name
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primary,
                  child: Text(
                    profile.name.isNotEmpty ? profile.name[0].toUpperCase() : 'A',
                    style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 14),
                Text(profile.name, style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: _roleColor(profile.role).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _roleColor(profile.role).withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _formatRole(profile.role),
                    style: TextStyle(
                      color: _roleColor(profile.role),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                if (profile.tenantId != null) ...[
                  const SizedBox(height: 6),
                  Text('Tenant: ${profile.tenantId}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Quick links
          _sectionCard([
            _menuItem(
              context,
              icon: Icons.verified_user_outlined,
              label: 'My Permissions',
              onTap: () => context.push('/admin/permissions'),
            ),
            const Divider(height: 1, indent: 52),
            _menuItem(
              context,
              icon: Icons.people_outline,
              label: 'Active Sessions',
              onTap: () => context.push('/admin/sessions'),
            ),
            const Divider(height: 1, indent: 52),
            _menuItem(
              context,
              icon: Icons.history_edu_outlined,
              label: 'Audit Logs',
              onTap: () => context.push('/admin/audit'),
            ),
          ]),
          const SizedBox(height: 16),

          // Permissions preview
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('PERMISSIONS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                const SizedBox(height: 12),
                if (profile.permissions.isEmpty)
                  Text('No permissions assigned.', style: TextStyle(color: Colors.grey.shade400, fontSize: 13))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: profile.permissions.map((perm) => _permChip(perm)).toList(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Logout button
          SizedBox(
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
                    content: const Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true && context.mounted) {
                  await ref.read(adminAuthNotifierProvider.notifier).logout();
                  if (context.mounted) context.go('/admin/login');
                }
              },
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 15)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red.shade300, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(children: children),
    );
  }

  Widget _menuItem(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary, size: 22),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _permChip(String perm) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Text(perm, style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN': return Colors.purple;
      case 'TECH_ADMIN': return Colors.blue;
      case 'OPS_ADMIN': return AppColors.primary;
      default: return Colors.orange;
    }
  }

  String _formatRole(String role) {
    return role.replaceAll('_', ' ');
  }
}
