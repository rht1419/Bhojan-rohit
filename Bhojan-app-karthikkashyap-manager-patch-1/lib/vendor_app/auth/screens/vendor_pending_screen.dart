import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Vendor Pending / Blocked Screen (AUTH-02a).
/// Shown when vendor hasn't activated their account yet,
/// or their account is suspended/blocked.
class VendorPendingScreen extends StatelessWidget {
  final String? reason;
  final String? errorCode;

  const VendorPendingScreen({super.key, this.reason, this.errorCode});

  @override
  Widget build(BuildContext context) {
    final bool isSuspended = errorCode == 'ACCOUNT_SUSPENDED';
    final bool isDeactivated = errorCode == 'ACCOUNT_DEACTIVATED';
    final bool isBlocked = isSuspended || isDeactivated;

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

              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: (isBlocked ? AppColors.error : Colors.orange).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isBlocked ? Icons.block : Icons.email_outlined,
                    size: 64,
                    color: isBlocked ? AppColors.error : Colors.orange,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                isBlocked ? 'Account Blocked' : 'Check Your Email',
                style: AppTextStyles.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                reason ??
                    (isBlocked
                        ? 'Your vendor account has been ${isSuspended ? "suspended" : "deactivated"}. Please contact your admin for assistance.'
                        : 'An activation email has been sent to your registered email address. Please click the link in the email to activate your account.'),
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              // Resend email button (only for unverified accounts)
              if (!isBlocked) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Activation email resent. Please check your inbox.'),
                        backgroundColor: AppColors.success,
                      ),
                    );
                  },
                  icon: const Icon(Icons.send),
                  label: const Text('Resend Activation Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Contact support (for blocked accounts)
              if (isBlocked) ...[
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please email support@bhojan.app for assistance.')),
                    );
                  },
                  icon: const Icon(Icons.support_agent),
                  label: const Text('Contact Support'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Back to login
              TextButton(
                onPressed: () => context.go('/vendor/login'),
                child: Text('Back to Login', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
