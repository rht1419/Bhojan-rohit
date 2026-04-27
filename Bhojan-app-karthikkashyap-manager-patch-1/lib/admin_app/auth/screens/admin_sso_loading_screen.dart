import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminSsoLoadingScreen extends StatelessWidget {
  const AdminSsoLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            // Logo Container
            Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.eco, color: AppColors.primary, size: 48),
              ),
            ),
            const SizedBox(height: 24),
            Text('Bhojan Admin', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 64),
            
            // Spinner
            const CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 4,
            ),
            const SizedBox(height: 32),
            
            Text('Connecting to Google...', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Please wait while we verify your account.',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
            ),
            const Spacer(),
            
            // Cancel Button
            TextButton(
              onPressed: () {
                // Return to login
                Navigator.of(context).pop();
              },
              child: Text('Cancel', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
