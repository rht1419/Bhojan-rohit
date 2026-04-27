import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/vendor_button.dart';

class VendorRegistrationStatusScreen extends StatelessWidget {
  const VendorRegistrationStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.textPrimary, // Dark green/navy from design
        elevation: 0,
        title: Text('Registration Submitted', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
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
                    color: Colors.orange.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.access_time_filled, size: 48, color: Colors.orange.shade400),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text('Verification Pending', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Your registration has been submitted successfully. Our team is reviewing your details to ensure community standards.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Status Checklist Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatusItem(Icons.check_circle, 'Phone number verified', AppColors.secondary),
                    const Divider(height: 24),
                    _buildStatusItem(Icons.access_time_filled, 'Email verification pending', Colors.orange.shade400),
                    const Divider(height: 24),
                    _buildStatusItem(Icons.access_time_filled, 'Business review in progress', Colors.orange.shade400),
                  ],
                ),
              ),
              
              const Spacer(),
              
              // Actions
              VendorButton(
                text: 'CHECK VERIFICATION STATUS',
                isOutlined: true,
                onPressed: () {}, // Refresh logic in future
              ),
              const SizedBox(height: 16),
              
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.support_agent, color: AppColors.primary),
                label: Text('CONTACT SUPPORT', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 16),
        Text(text, style: AppTextStyles.bodyLarge),
      ],
    );
  }
}
