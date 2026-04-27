import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/vendor_button.dart';
import '../models/vendor_auth_models.dart';
import '../providers/vendor_auth_provider.dart';

class VendorVerifyPhoneScreen extends ConsumerStatefulWidget {
  final String phone;
  final String nextRoute;

  const VendorVerifyPhoneScreen({
    super.key,
    required this.phone,
    required this.nextRoute,
  });

  @override
  ConsumerState<VendorVerifyPhoneScreen> createState() => _VendorVerifyPhoneScreenState();
}

class _VendorVerifyPhoneScreenState extends ConsumerState<VendorVerifyPhoneScreen> {
  static const int _resendSeconds = 60;
  static const int _otpLength = 6;

  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  bool _isLoading = false;
  bool _isResending = false;
  int _secondsRemaining = _resendSeconds;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_otpLength, (_) => FocusNode());
    _controllers = List.generate(_otpLength, (_) => TextEditingController());
    _startResendTimer();
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (final node in _focusNodes) { node.dispose(); }
    for (final c in _controllers) { c.dispose(); }
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _secondsRemaining = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) { timer.cancel(); return; }
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);
    final success = await ref.read(vendorAuthNotifierProvider.notifier).requestOtp(widget.phone);
    if (!mounted) return;
    setState(() => _isResending = false);
    if (success) {
      _startResendTimer();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP resent successfully'), backgroundColor: AppColors.success),
      );
    } else {
      final vendorState = ref.read(vendorAuthNotifierProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vendorState.errorMessage ?? 'Failed to resend OTP'), backgroundColor: AppColors.error),
      );
    }
  }

  void _onOtpChanged(String value, int index) {
    if (value.isNotEmpty) {
      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        _verifyOtp();
      }
    } else {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _controllers.map((c) => c.text).join();
    if (otp.length < _otpLength) return;

    setState(() => _isLoading = true);

    final request = VerifyOtpRequest(phone: widget.phone, otp: otp);
    final success = await ref.read(vendorAuthNotifierProvider.notifier).verifyOtp(request);

    if (!mounted) return;

    if (success) {
      context.go(widget.nextRoute);
    } else {
      final vendorState = ref.read(vendorAuthNotifierProvider);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vendorState.errorMessage ?? 'Invalid OTP'), backgroundColor: AppColors.error),
      );
      for (final c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  String get _timerText {
    final m = _secondsRemaining ~/ 60;
    final s = _secondsRemaining % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final canResend = _secondsRemaining == 0 && !_isResending;

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Verify Phone', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.phone_android, color: Colors.white, size: 32),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              Text('Enter your OTP', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                "We've sent an OTP to\n${widget.phone}",
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // OTP Input Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_otpLength, (index) {
                  return SizedBox(
                    width: 48,
                    height: 56,
                    child: TextFormField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                      onChanged: (val) => _onOtpChanged(val, index),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),

              // Resend timer / button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!canResend) ...[
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Resend OTP in $_timerText',
                      style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade700),
                    ),
                  ] else
                    _isResending
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : TextButton(
                          onPressed: _resendOtp,
                          child: Text(
                            'Resend OTP',
                            style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                          ),
                        ),
                ],
              ),

              const Spacer(),

              // Verify Button
              VendorButton(
                text: widget.nextRoute.contains('loading') || widget.nextRoute.contains('dashboard')
                    ? 'Verify & Login'
                    : 'Verify',
                isLoading: _isLoading,
                onPressed: _verifyOtp,
                icon: widget.nextRoute.contains('loading') ? const Icon(Icons.arrow_forward) : null,
              ),
              const SizedBox(height: 16),

              if (widget.nextRoute.contains('loading'))
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      'Having trouble? Contact Support',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
