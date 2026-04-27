import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../models/auth_response_models.dart';
import '../providers/auth_provider.dart';

/// Screen 5 — OTP Verification (EP-02).
/// Dual-purpose: used for both Registration OTP and Login OTP.
/// The [context] parameter determines post-verification behaviour.
class OtpScreen extends ConsumerStatefulWidget {
  final String phone;
  final String? otpReference;
  final String otpContext; // 'registration' | 'login'

  const OtpScreen({
    Key? key,
    required this.phone,
    this.otpReference,
    this.otpContext = 'registration',
  }) : super(key: key);

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(AppConstants.otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(AppConstants.otpLength, (_) => FocusNode());

  int _resendSeconds = AppConstants.otpResendSeconds;
  Timer? _timer;
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) { c.dispose(); }
    for (var n in _focusNodes) { n.dispose(); }
    super.dispose();
  }

  void _startResendTimer() {
    _resendSeconds = AppConstants.otpResendSeconds;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_resendSeconds <= 0) {
        t.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  void _onChanged(String value, int index) {
    if (value.isNotEmpty && index < AppConstants.otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    // Auto-submit if all digits filled
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length == AppConstants.otpLength) {
      _verify(otp);
    }
  }

  Future<void> _verify(String otp) async {
    setState(() { _isVerifying = true; _errorMessage = null; });

    final request = OtpVerifyRequest(
      phone: widget.phone,
      otp: otp,
      otpReference: widget.otpReference,
    );

    final success = await ref.read(authNotifierProvider.notifier).verifyOtp(request);

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      final authState = ref.read(authNotifierProvider);
      setState(() {
        _isVerifying = false;
        _errorMessage = authState.errorMessage;
      });
      // Clear OTP fields on error
      for (var c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  Future<void> _resend() async {
    // Re-register or re-request OTP depending on context
    _startResendTimer();
    setState(() => _errorMessage = null);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('OTP resent successfully')),
    );
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
              Text('Verify OTP', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'We have sent a ${AppConstants.otpLength}-digit OTP to\n${widget.phone}',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 32),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(AppConstants.otpLength, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTextStyles.headlineSmall,
                      onChanged: (v) => _onChanged(v, index),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(_errorMessage!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error), textAlign: TextAlign.center),
              ],

              const SizedBox(height: 32),

              // Verify button
              ElevatedButton(
                onPressed: _isVerifying
                    ? null
                    : () {
                        final otp = _controllers.map((c) => c.text).join();
                        if (otp.length == AppConstants.otpLength) {
                          _verify(otp);
                        } else {
                          setState(() => _errorMessage = 'Please enter all ${AppConstants.otpLength} digits');
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isVerifying
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Verify OTP', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 24),

              // Resend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Didn't receive code?", style: AppTextStyles.labelMedium),
                  if (_resendSeconds > 0)
                    Text('  Resend in ${_resendSeconds}s', style: AppTextStyles.labelLarge.copyWith(color: Colors.grey))
                  else
                    TextButton(
                      onPressed: _resend,
                      child: Text('Resend', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
