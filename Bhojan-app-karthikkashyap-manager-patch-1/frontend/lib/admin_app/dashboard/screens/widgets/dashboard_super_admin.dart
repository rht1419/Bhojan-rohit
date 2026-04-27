import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dashboard_shared_components.dart';

class DashboardSuperAdmin extends StatelessWidget {
  const DashboardSuperAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Pills
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text('SUPER ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/admin/switch-tenant'),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.greenAccent.shade100, borderRadius: BorderRadius.circular(16)),
                  child: Row(
                    children: [
                      Text('All Tenants', style: TextStyle(color: Colors.green.shade900, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: Colors.green.shade900, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Stats Grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.3,
            children: const [
              StatCard(title: 'TOTAL VENDORS', value: '48', icon: Icons.store, isPrimary: true),
              StatCard(title: 'ACTIVE USERS', value: '1,204', icon: Icons.people, isPrimary: true),
              StatCard(title: 'AUDIT EVENTS', value: '37', suffix: 'Today', icon: Icons.security),
              StatCard(title: 'ACTIVE SESSIONS', value: '12', icon: Icons.devices),
            ],
          ),
          const SizedBox(height: 32),

          // Modules Grid
          Text('All Modules', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: [
              ModuleCard(title: 'Audit Logs', icon: Icons.history_edu, route: '/admin/audit'),
              ModuleCard(title: 'Manage Vendors', icon: Icons.store, route: '/admin/vendors'),
              ModuleCard(title: 'Bulk Upload', icon: Icons.cloud_upload, route: '/admin/employees/upload'),
              ModuleCard(title: 'Delegate Access', icon: Icons.manage_accounts, route: '/admin/delegation'),
              ModuleCard(title: 'Active Sessions', icon: Icons.devices, route: '/admin/sessions'),
              ModuleCard(title: 'DB Config', icon: Icons.storage, isLocked: false),
              ModuleCard(title: 'Tenant Switch', icon: Icons.swap_horiz, route: '/admin/switch-tenant'),
              ModuleCard(title: 'Role Permissions', icon: Icons.admin_panel_settings, route: '/admin/permissions'),
              ModuleCard(title: 'System Logs', icon: Icons.terminal, isLocked: false),
            ],
          ),
          const SizedBox(height: 32),

          // Recent Audit Events
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Audit Events', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
              TextButton(onPressed: () => context.go('/admin/audit'), child: const Text('View All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
            ],
          ),
          const SizedBox(height: 8),
          _buildAuditRow('Menu Item Deleted', 'by Vendor ID: #4092', '10m ago', Icons.delete, Colors.red),
          _buildAuditRow('New Tenant Created', 'System Automated', '1h ago', Icons.person_add, Colors.green),
          _buildAuditRow('Database Backup Complete', 'Server: US-East', '3h ago', Icons.backup, Colors.grey),
        ],
      ),
    );
  }

  Widget _buildAuditRow(String title, String subtitle, String time, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          CircleAvatar(backgroundColor: color.withValues(alpha: 0.1), child: Icon(icon, color: color, size: 20)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
          ),
          Text(time, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        ],
      ),
    );
  }
}
