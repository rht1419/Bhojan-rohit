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
  final int _otpLength = 6;
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(_otpLength, (index) => FocusNode());
    _controllers = List.generate(_otpLength, (index) => TextEditingController());
  }

  @override
  void dispose() {
    for (var node in _focusNodes) { node.dispose(); }
    for (var controller in _controllers) { controller.dispose(); }
    super.dispose();
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
      // Clear OTP on failure
      for (var c in _controllers) { c.clear(); }
      _focusNodes[0].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
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

              // Title
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

              // Resend timer
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 8),
                  Text('Resend OTP in 0:38', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey.shade700)),
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
                    child: Text('Having trouble? Contact Support', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
