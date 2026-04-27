import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dashboard_shared_components.dart';

class DashboardOpsAdmin extends StatelessWidget {
  const DashboardOpsAdmin({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Pills
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.teal.shade500, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    const Text('Ops Admin', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock, color: Colors.grey.shade600, size: 16),
                const SizedBox(width: 8),
                Text('Tenant: Infosys Cafeteria', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
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
            children: [
              const StatCard(title: 'Active Vendors', value: '6', icon: Icons.store, isPrimary: true),
              const StatCard(title: 'Orders Today', value: '284', icon: Icons.receipt, isPrimary: true),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Pending Issues', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('3', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
                        const Icon(Icons.warning, color: Colors.redAccent, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Resolved Today', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('19', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                        Icon(Icons.check_circle, color: Colors.orange.shade200, size: 20),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Modules Grid
          Text('Your Modules', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
            children: const [
              ModuleCard(title: 'Manage Vendors', icon: Icons.store, route: '/admin/vendors'),
              ModuleCard(title: 'Audit Logs', icon: Icons.history_edu, route: '/admin/audit'),
              ModuleCard(title: 'Bulk Upload', icon: Icons.cloud_upload, route: '/admin/employees/upload'),
              ModuleCard(title: 'Delegate Access', icon: Icons.people, isLocked: true),
              ModuleCard(title: 'DB Config', icon: Icons.storage, isLocked: true),
              ModuleCard(title: 'Tenant Switch', icon: Icons.swap_horiz, isLocked: true),
              ModuleCard(title: 'Active Sessions', icon: Icons.devices, isLocked: true),
              ModuleCard(title: 'Role Permissions', icon: Icons.vpn_key, isLocked: true),
              ModuleCard(title: 'System Logs', icon: Icons.terminal, isLocked: true),
            ],
          ),
        ],
      ),
    );
  }
}
