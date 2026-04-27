import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/vendor_button.dart';

class VendorWelcomeScreen extends StatelessWidget {
  const VendorWelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              
              // Logo
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, size: 64, color: Colors.white),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Bhojan Vendor',
                style: AppTextStyles.headlineLarge.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Manage your outlet, track orders, and grow your business with Bhojan.',
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              
              const Spacer(),
              
              // Actions
              VendorButton(
                text: 'Login to Outlet',
                onPressed: () => context.push('/vendor/login'),
              ),
              const SizedBox(height: 16),
              
              VendorButton(
                text: 'Register New Business',
                isOutlined: true,
                onPressed: () => context.push('/vendor/register'),
              ),
              
              const SizedBox(height: 24),
              
              // Switch to User App
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Looking for food? ', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => context.go('/welcome'),
                    child: Text('Go to User App', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
