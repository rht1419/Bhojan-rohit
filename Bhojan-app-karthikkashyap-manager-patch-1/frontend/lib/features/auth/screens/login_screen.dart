import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/phone_utils.dart';
import '../providers/auth_provider.dart';

/// Screen 6 — Login with OTP.
/// Phone-only. Sends OTP, navigates to OTP screen.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phoneInput = _phoneController.text.trim();
    // #region agent log H13 login otp entry
    debugPrint('[DBG-H13] login_send_otp tapped phoneRaw=$phoneInput');
    // #endregion
    if (!PhoneUtils.isValidIndianPhone(phoneInput)) {
      // #region agent log H13 login otp blocked
      debugPrint('[DBG-H13] login_send_otp blocked invalid phoneRaw=$phoneInput');
      // #endregion
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid Indian mobile number')),
      );
      return;
    }
    final phone = PhoneUtils.normalizeIndianPhone(phoneInput);

    setState(() => _isLoading = true);

    // Call the newly created requestLoginOtp method
    final res = await ref.read(authNotifierProvider.notifier).requestLoginOtp(phone);
    
    if (mounted) {
      setState(() => _isLoading = false);
    }

    if (res != null && mounted) {
      context.push('/verify-otp', extra: {
        'phone': phone,
        'otpReference': res.otpReference,
        'context': 'login',
      });
    } else if (mounted) {
      final error = ref.read(authNotifierProvider).errorMessage ?? 'Failed to send OTP';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

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
              Text('Welcome Back', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(
                'Enter your registered phone number to receive an OTP.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 48),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter 10-digit mobile number',
                  labelText: 'Phone Number',
                  prefixText: '+91 ',
                  prefixIcon: const Icon(Icons.phone_android),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),

              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Get OTP', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 24),

              TextButton(
                onPressed: () => context.push('/login-password'),
                child: Text('Login with Password instead', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
