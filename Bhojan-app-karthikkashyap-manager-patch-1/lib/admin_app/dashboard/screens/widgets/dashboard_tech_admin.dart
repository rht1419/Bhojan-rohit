import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dashboard_shared_components.dart';

class DashboardTechAdmin extends StatelessWidget {
  const DashboardTechAdmin({super.key});

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
                decoration: BoxDecoration(color: Colors.blueGrey.shade900, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.settings, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    const Text('TECH ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    Icon(Icons.lock, color: Colors.grey.shade700, size: 14),
                    const SizedBox(width: 4),
                    Text('System Root', style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
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
            children: [
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
                    const Text('DB Health', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text('Healthy', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const StatCard(title: 'Config Changes\nToday', value: '4', icon: Icons.settings, isPrimary: true),
              const StatCard(title: 'Active Sessions', value: '12', icon: Icons.devices, isPrimary: false),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade100),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Failed Jobs', style: TextStyle(color: Colors.redAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                    Text('1', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.red)),
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
              ModuleCard(title: 'DB CONFIG', icon: Icons.storage, route: '/admin/config'),
              ModuleCard(title: 'SYSTEM LOGS', icon: Icons.terminal, route: '/admin/system-logs'),
              ModuleCard(title: 'ACTIVE SESSIONS', icon: Icons.devices, route: '/admin/sessions'),
              ModuleCard(title: 'MANAGE VENDORS', icon: Icons.store, isLocked: true),
              ModuleCard(title: 'BULK UPLOAD', icon: Icons.cloud_upload, isLocked: true),
              ModuleCard(title: 'DELEGATE ACCESS', icon: Icons.manage_accounts, isLocked: true),
              ModuleCard(title: 'TENANT', icon: Icons.swap_horiz, isLocked: true),
              ModuleCard(title: 'AUDIT', icon: Icons.history_edu, isLocked: true),
              ModuleCard(title: 'ROLE', icon: Icons.vpn_key, isLocked: true),
            ],
          ),
        ],
      ),
    );
  }
}
