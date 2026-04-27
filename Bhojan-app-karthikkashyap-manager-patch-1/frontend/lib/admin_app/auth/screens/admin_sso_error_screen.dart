import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminSsoErrorScreen extends StatelessWidget {
  final String errorMessage;
  final String? subMessage;

  const AdminSsoErrorScreen({
    super.key, 
    this.errorMessage = 'Error: OAuth authorization failed',
    this.subMessage = 'Domain not mapped to any tenant',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/admin/login'),
        ),
        title: Text('Login Failed', style: AppTextStyles.headlineSmall.copyWith(color: AppColors.textPrimary)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.red, size: 40),
                ),
              ),
              const SizedBox(height: 32),

              // Title & Desc
              Text('SSO Login Failed', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 16),
              Text(
                "We couldn't connect to your Google account. This may be due to a network error or an unrecognized email domain.",
                style: AppTextStyles.bodyLarge.copyWith(color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Error Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border(left: BorderSide(color: Colors.red.shade700, width: 4)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(errorMessage, style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                    if (subMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(subMessage!, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Buttons
              ElevatedButton.icon(
                onPressed: () {
                  // Retry logic (would trigger SSO again)
                  context.go('/admin/login'); // Simply routing back to login for now
                },
                icon: const Icon(Icons.refresh, size: 20),
                label: const Text('Try Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  context.go('/admin/login');
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                ),
                child: const Text('Login with OTP instead', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
              
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text('Contact support', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade600)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
