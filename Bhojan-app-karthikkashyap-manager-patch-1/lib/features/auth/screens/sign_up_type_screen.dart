import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Screen 2 from the plan — Guest vs Employee chooser.
/// No API call on this screen.
class SignUpTypeScreen extends StatelessWidget {
  const SignUpTypeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('How do you want\nto sign up?', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Select the option that best describes you.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 40),

              // ── Employee Card ──────────────────────────────────────
              _SignUpTypeCard(
                icon: Icons.badge_outlined,
                title: "I'm a Company Employee",
                subtitle: 'Register with your company ID to access employee benefits and subsidized meals.',
                onTap: () => context.push('/tenant-select'),
              ),

              const SizedBox(height: 20),

              // ── Guest Card ────────────────────────────────────────
              _SignUpTypeCard(
                icon: Icons.person_outline,
                title: "I'm a Guest / Visitor",
                subtitle: 'Order food as a visitor. You can link your company account later.',
                onTap: () => context.push('/register/guest'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignUpTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SignUpTypeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text(subtitle, style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
