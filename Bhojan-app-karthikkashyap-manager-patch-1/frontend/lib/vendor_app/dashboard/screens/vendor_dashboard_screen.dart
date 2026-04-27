import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../auth/providers/vendor_auth_provider.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorAuthNotifierProvider);
    final businessName = state.profile?.businessName ?? 'MK Foods';

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.eco, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Text('BHOJAN', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, letterSpacing: 1.2)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blueGrey.shade800,
              backgroundImage: const NetworkImage('https://i.pravatar.cc/100?img=11'), // Placeholder avatar
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Greeting
            Text('Good Morning, $businessName', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 12),
            
            // Outlet Status Pill
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Text('Your outlet is currently OPEN', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Row(
              children: [
                _buildQuickActionCard(Icons.add, 'Add Dish'),
                const SizedBox(width: 12),
                _buildQuickActionCard(Icons.list, 'View Menu'),
                const SizedBox(width: 12),
                _buildQuickActionCard(Icons.payments_outlined, 'Payouts'),
              ],
            ),
            const SizedBox(height: 32),

            // Active Orders
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Active Orders', style: AppTextStyles.headlineSmall),
                Text('View All', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Order Cards
            _buildOrderCard('#1042', '2x Masala Dosa, 1x Filter Coffee', '₹295', 'NEW', AppColors.primary, true),
            const SizedBox(height: 12),
            _buildOrderCard('#1041', '1x Paneer Butter Masala, 3x Roti', '₹380', 'PREPARING', Colors.orange.shade400, false),
            const SizedBox(height: 12),
            _buildOrderCard('#1040', '4x Samosa', '₹120', 'READY', AppColors.secondary, false),
            
            const SizedBox(height: 32),

            // Business Health
            Text('Business Health', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  _buildHealthStat('Rating', '4.8', Icons.star),
                  _buildDivider(),
                  _buildHealthStat('Prep Time', '12m', null),
                  _buildDivider(),
                  _buildHealthStat('Active\nPromos', '2', null),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Top Sellers
            Text('TOP SELLERS THIS WEEK', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600)),
            const SizedBox(height: 16),
            _buildTopSeller('Masala Dosa', '124 sold', Icons.restaurant_menu),
            const SizedBox(height: 12),
            _buildTopSeller('Filter Coffee', '98 sold', Icons.local_cafe),
            
            const SizedBox(height: 24),
            
            // Support Link
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.help, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Text('Bhojan Support', style: AppTextStyles.bodyLarge),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.labelMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(String id, String items, String price, String status, Color statusColor, bool hasActions) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(id, style: AppTextStyles.headlineSmall),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: status == 'READY' ? 1.0 : 0.8), // Using withValues as requested in flutter
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(status, style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(items, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
              ),
              Text(price, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          if (hasActions) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Accept', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildHealthStat(String label, String value, IconData? icon) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Icon(icon, color: AppColors.primary, size: 20),
              ]
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }

  Widget _buildTopSeller(String name, String sold, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 5)],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: AppColors.neutral, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: AppTextStyles.bodyLarge)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppColors.neutral, borderRadius: BorderRadius.circular(20)),
            child: Text(sold, style: AppTextStyles.labelMedium),
          ),
        ],
      ),
    );
  }
}
