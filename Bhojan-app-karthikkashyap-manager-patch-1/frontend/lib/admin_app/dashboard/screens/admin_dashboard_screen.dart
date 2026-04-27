import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/admin_auth_provider.dart';
import 'widgets/dashboard_super_admin.dart';
import 'widgets/dashboard_ops_admin.dart';
import 'widgets/dashboard_tech_admin.dart';
import 'widgets/dashboard_sub_admin.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(adminAuthNotifierProvider);
    final profile = authState.profile;

    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    Widget dashboardContent;
    switch (profile.role) {
      case 'SUPER_ADMIN':
        dashboardContent = const DashboardSuperAdmin();
        break;
      case 'OPS_ADMIN':
        dashboardContent = const DashboardOpsAdmin();
        break;
      case 'TECH_ADMIN':
        dashboardContent = const DashboardTechAdmin();
        break;
      case 'SUB_ADMIN':
        dashboardContent = const DashboardSubAdmin();
        break;
      default:
        dashboardContent = const Center(child: Text('Unknown Role'));
    }

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Row(
          children: [
            const Icon(Icons.restaurant_menu, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text('Dashboard', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: Text(
                _getInitials(profile.role),
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: dashboardContent,
    );
  }

  String _getInitials(String role) {
    if (role == 'SUPER_ADMIN') return 'SA';
    if (role == 'OPS_ADMIN') return 'OA';
    if (role == 'TECH_ADMIN') return 'TA';
    if (role == 'SUB_ADMIN') return 'SU';
    return 'AD';
  }
}
