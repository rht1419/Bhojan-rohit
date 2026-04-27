import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/admin_auth_provider.dart';

class AdminRoleSelectionScreen extends ConsumerStatefulWidget {
  const AdminRoleSelectionScreen({super.key});

  @override
  ConsumerState<AdminRoleSelectionScreen> createState() => _AdminRoleSelectionScreenState();
}

class _AdminRoleSelectionScreenState extends ConsumerState<AdminRoleSelectionScreen> {
  String _selectedRole = 'SUPER_ADMIN';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _roles = [
    {
      'id': 'SUPER_ADMIN',
      'title': 'Super Admin',
      'desc': 'Full access to all modules',
      'icon': Icons.stars,
      'color': Colors.teal.shade700,
    },
    {
      'id': 'OPS_ADMIN',
      'title': 'Ops Admin',
      'desc': 'Vendors, orders, operations',
      'icon': Icons.bar_chart,
      'color': Colors.blueGrey.shade700,
    },
    {
      'id': 'TECH_ADMIN',
      'title': 'Tech Admin',
      'desc': 'Config, DB, technical settings',
      'icon': Icons.settings,
      'color': Colors.deepPurple.shade700,
    },
    {
      'id': 'SUB_ADMIN',
      'title': 'Sub Admin',
      'desc': 'Limited module access only',
      'icon': Icons.lock,
      'color': Colors.brown.shade700,
    },
  ];

  Future<void> _handleProceed() async {
    setState(() => _isLoading = true);
    await ref.read(adminAuthNotifierProvider.notifier).updateRole(_selectedRole);
    if (!mounted) return;
    context.go('/admin/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Text('Select Role', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false, // Don't allow going back to OTP
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'You have access to multiple roles. Choose how to proceed.',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Role Grid
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: _roles.length,
                  itemBuilder: (context, index) {
                    final role = _roles[index];
                    final isSelected = _selectedRole == role['id'];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedRole = role['id']),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.transparent, width: 0),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: role['color'].withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(role['icon'], color: role['color'], size: 24),
                            ),
                            const Spacer(),
                            Text(role['title'], style: AppTextStyles.headlineSmall.copyWith(fontSize: 16)),
                            const SizedBox(height: 8),
                            Text(role['desc'], style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600, height: 1.3)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Proceed Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleProceed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tertiary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Proceed as ${_roles.firstWhere((r) => r['id'] == _selectedRole)['title']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
