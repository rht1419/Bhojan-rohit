import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../auth/providers/vendor_auth_provider.dart';

class VendorProfileScreen extends ConsumerWidget {
  const VendorProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(vendorAuthNotifierProvider);
    final profile = state.profile;
    
    final businessName = profile?.businessName ?? 'MK Foods';
    final tenantId = profile?.tenantId ?? 'Infosys Cafeteria';
    final phone = profile?.phone ?? '+91 98765 43210';
    final email = 'contact@mkfoods.com'; // Mock email

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        title: Text('Bhojan', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/vendor/dashboard'),
        ),
        actions: [
          TextButton(
            onPressed: () {},
            child: Text('Edit', style: AppTextStyles.labelMedium.copyWith(color: Colors.white)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 4),
                    ),
                    child: const CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage('https://i.pravatar.cc/200?img=11'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(businessName, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(12)),
                        child: Text('VENDOR', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(tenantId, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Business Details
            _buildSection(
              title: 'Business Details',
              children: [
                _buildInfoRow('Business Name', '$businessName Enterprise'),
                _buildDivider(),
                _buildInfoRow('Phone', phone),
                _buildDivider(),
                _buildInfoRow('Email', email),
              ],
            ),
            const SizedBox(height: 20),

            // Outlet Info
            _buildSection(
              title: 'Outlet Info',
              children: [
                _buildInfoRow('Outlet Name', 'Main Kitchen - Blr'),
                _buildDivider(),
                _buildInfoRow('Tenant', tenantId),
                _buildDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.lock, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text('Vendor ID', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                      ],
                    ),
                    Text('VND - 84920', style: AppTextStyles.bodyLarge),
                  ],
                )
              ],
            ),
            const SizedBox(height: 20),

            // Operating Hours
            _buildSection(
              title: 'Operating Hours',
              children: [
                _buildInfoRow('Mon - Fri', '08:00 AM - 08:00 PM'),
                _buildDivider(),
                _buildInfoRow('Sat - Sun', 'Closed', valueColor: Colors.grey),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            TextButton.icon(
              onPressed: () async {
                await ref.read(vendorAuthNotifierProvider.notifier).logout();
                if (context.mounted) context.go('/vendor/welcome');
              },
              icon: const Icon(Icons.logout, color: AppColors.error),
              label: Text('LOGOUT', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error, letterSpacing: 1.2)),
              style: TextButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                backgroundColor: AppColors.error.withValues(alpha: 0.05),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.headlineSmall),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
        Text(value, style: AppTextStyles.bodyLarge.copyWith(color: valueColor)),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Divider(color: Colors.grey.shade100, height: 1),
    );
  }
}
