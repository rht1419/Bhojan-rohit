import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/vendor_button.dart';

class VendorSessionExpiredScreen extends StatefulWidget {
  const VendorSessionExpiredScreen({super.key});

  @override
  State<VendorSessionExpiredScreen> createState() => _VendorSessionExpiredScreenState();
}

class _VendorSessionExpiredScreenState extends State<VendorSessionExpiredScreen> {
  int _countdown = 5;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 1) {
        setState(() => _countdown--);
      } else {
        _timer?.cancel();
        if (mounted) context.go('/vendor/login');
      }
    });
  }

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
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      const Icon(Icons.history, size: 56, color: AppColors.error),
                      Container(
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.cancel, size: 24, color: AppColors.error),
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              // Title
              Text('Session Expired', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Your session has timed out due to inactivity to protect your account security.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              
              // Countdown Card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const Icon(Icons.info, color: AppColors.primary, size: 24),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text('Redirecting to login in $_countdown seconds...', style: AppTextStyles.bodyLarge),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(12), bottomRight: Radius.circular(12)),
                      child: LinearProgressIndicator(
                        value: _countdown / 5.0,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                        minHeight: 4,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Action
              VendorButton(
                text: 'Login Again',
                onPressed: () {
                  _timer?.cancel();
                  context.go('/vendor/login');
                },
              ),
              const SizedBox(height: 16),
              
              Text(
                'All unsaved changes have been discarded.',
                style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
