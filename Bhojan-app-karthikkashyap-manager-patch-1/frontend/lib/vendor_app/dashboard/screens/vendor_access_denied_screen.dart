import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/vendor_button.dart';

class VendorAccessDeniedScreen extends StatelessWidget {
  const VendorAccessDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text('Access Denied', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/vendor/welcome'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.gpp_bad, size: 48, color: AppColors.error),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text('Access Restricted', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                "You don't have permission to view data outside your assigned outlet.",
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Error Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: const Border(left: BorderSide(color: AppColors.error, width: 4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info, color: AppColors.error, size: 20),
                        const SizedBox(width: 12),
                        Text('Error 403 — Forbidden', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Your current session token does not authorize access to this specific vendor portal. Please verify your credentials or contact administration for an access upgrade.',
                      style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, height: 1.5),
                    ),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Actions
              VendorButton(
                text: 'Go Back',
                onPressed: () => context.pop(),
              ),
              const SizedBox(height: 16),
              
              VendorButton(
                text: 'Contact Admin',
                isOutlined: true,
                onPressed: () {}, 
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
