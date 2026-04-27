import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../dashboard/screens/widgets/dashboard_shared_components.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        leading: IconButton(icon: const Icon(Icons.menu, color: Colors.white), onPressed: () {}),
        title: Text('ANALYTICS', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundColor: AppColors.primary, radius: 14, child: const Text('SA', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Analytics', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                  child: Row(
                    children: [
                      const Icon(Icons.stars, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      const Text('SUPER ADMIN', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(16)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, color: Colors.green.shade800, size: 14),
                  const SizedBox(width: 4),
                  Text('Viewing: All Tenants', style: TextStyle(color: Colors.green.shade900, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Cross-Tenant Overview
            Text('Cross-Tenant Overview', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildStatCard('Total Tenants', '4', Icons.business, 'Active', true),
            _buildStatCard('Total Users', '5,240', Icons.people, '12%', true, true),
            _buildStatCard('Total Vendors', '48', Icons.store, null, true),
            _buildStatCard('Total Orders (Today)', '1,820', Icons.receipt_long, '8%', true, true),
            const SizedBox(height: 32),

            // Attention Required
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.black87, size: 20),
                const SizedBox(width: 8),
                Text('Attention Required', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: const Border(left: BorderSide(color: Colors.orange, width: 4)),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.orange.shade50, child: const Icon(Icons.business, color: Colors.orange)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('TechPark North Tower', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                        Text('Last active: 2 mins ago', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(12)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error, color: Colors.red, size: 12),
                              const SizedBox(width: 4),
                              const Text('3 unresolved issues', style: TextStyle(color: Colors.red, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Per Tenant Breakdown
            Text('Per Tenant Breakdown', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  _buildTenantBreakdownRow('IC', 'Infosys Cafeteria', AppColors.primary, '2,100', '15', '650', true),
                  _buildTenantBreakdownRow('TF', 'TCS Food Court', Colors.greenAccent, '1,850', '12', '540', true),
                  _buildTenantBreakdownRow('WC', 'Wipro Canteen', Colors.blueGrey.shade100, '890', '8', '320', true),
                  _buildTenantBreakdownRow('HD', 'HCL Dining', Colors.blueGrey.shade300, '400', '13', '310', false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, String? trend, bool isPrimary, [bool isTrendUp = true]) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? const Border(left: BorderSide(color: AppColors.primary, width: 4)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(icon, size: 80, color: Colors.grey.shade100),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(backgroundColor: AppColors.primary.withValues(alpha: 0.1), radius: 16, child: Icon(icon, color: AppColors.primary, size: 16)),
                  const SizedBox(height: 16),
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(value, style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              if (trend != null)
                Row(
                  children: [
                    if (trend != 'Active') Icon(isTrendUp ? Icons.trending_up : Icons.trending_down, size: 14, color: isTrendUp ? Colors.green : Colors.red),
                    const SizedBox(width: 4),
                    Text(trend, style: TextStyle(color: trend == 'Active' ? Colors.grey : (isTrendUp ? Colors.green : Colors.red), fontSize: 12)),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTenantBreakdownRow(String initials, String name, Color color, String users, String vendors, String orders, bool showBorder) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: showBorder ? Border(bottom: BorderSide(color: Colors.grey.shade100)) : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: color, radius: 16, child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              const SizedBox(width: 12),
              Text(name, style: AppTextStyles.headlineSmall),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMiniStat('Users:', users, true),
              _buildMiniStat('Vendors:', vendors, true),
              _buildMiniStat('Orders:', orders, false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, bool hasBg) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
        const SizedBox(width: 8),
        if (hasBg)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
            child: Text(value, style: TextStyle(color: Colors.green.shade800, fontSize: 12)),
          )
        else
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}
