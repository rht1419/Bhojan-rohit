import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'dashboard_shared_components.dart';

class DashboardSubAdmin extends StatelessWidget {
  const DashboardSubAdmin({super.key});

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
                decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.lock, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    const Text('SUB ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
                child: Row(
                  children: [
                    Icon(Icons.store, color: Colors.grey.shade700, size: 14),
                    const SizedBox(width: 4),
                    Text('Tenant Alpha', style: TextStyle(color: Colors.grey.shade800, fontSize: 12, fontWeight: FontWeight.w600)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Kitchen Orders', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        CircleAvatar(backgroundColor: Colors.teal.shade50, radius: 12, child: Icon(Icons.soup_kitchen, color: Colors.teal.shade700, size: 14)),
                      ],
                    ),
                    Text('43', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Billing Pending', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                        CircleAvatar(backgroundColor: Colors.orange.shade50, radius: 12, child: Icon(Icons.receipt_long, color: Colors.orange.shade700, size: 14)),
                      ],
                    ),
                    Text('7', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold, color: Colors.orange.shade700)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Modules Grid
          Text('Your Modules', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(backgroundColor: Colors.white24, radius: 24, child: const Icon(Icons.restaurant, color: Colors.white)),
                        const SizedBox(height: 12),
                        const Text('Kitchen', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () {},
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.teal.shade400,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(backgroundColor: Colors.white24, radius: 24, child: const Icon(Icons.point_of_sale, color: Colors.white)),
                        const SizedBox(height: 12),
                        const Text('Billing', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Restricted Area Placeholder
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade400, style: BorderStyle.solid), // Placeholder for dashed
            ),
            child: Column(
              children: [
                CircleAvatar(backgroundColor: Colors.grey.shade200, radius: 32, child: Icon(Icons.lock, color: Colors.grey.shade600, size: 32)),
                const SizedBox(height: 24),
                Text('Restricted Area', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('You don\'t have access to other modules.', style: TextStyle(color: Colors.grey.shade600), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
                  label: const Text('Contact Super Admin to request access', style: TextStyle(color: AppColors.primary)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
