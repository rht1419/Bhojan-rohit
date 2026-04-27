import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/vendor_auth_provider.dart';

class VendorLoadingScreen extends ConsumerStatefulWidget {
  const VendorLoadingScreen({super.key});

  @override
  ConsumerState<VendorLoadingScreen> createState() => _VendorLoadingScreenState();
}

class _VendorLoadingScreenState extends ConsumerState<VendorLoadingScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-navigate to dashboard after 2 seconds
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        context.go('/vendor/dashboard');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Attempt to grab tenant ID or use a placeholder if not loaded yet
    final state = ref.watch(vendorAuthNotifierProvider);
    final tenantId = state.profile?.tenantId ?? 'INFOSYS CAFETERIA';

    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 60),
            
            // Logo
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)
                  ],
                ),
                child: const Icon(Icons.eco, size: 40, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            
            Text('Bhojan Vendor', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.primary)),
            
            const Spacer(),
            
            // Loading Animation
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                color: AppColors.primary,
                backgroundColor: Colors.transparent,
              ),
            ),
            const SizedBox(height: 32),
            
            Text('Setting up your dashboard...', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text('Loading your outlet data', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade500)),
            
            const Spacer(),
            
            // Tenant Pill
            Container(
              margin: const EdgeInsets.only(bottom: 40),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.business, size: 16, color: AppColors.primary.withValues(alpha: 0.8)),
                  const SizedBox(width: 8),
                  Text(
                    'TENANT: ${tenantId.toUpperCase()}',
                    style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
