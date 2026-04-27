import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/phone_utils.dart';
import '../../auth/models/auth_response_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen 9 — Forgot Password (EP-09, EP-10).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  int _step = 1;
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();

  @override
  void dispose() {
    _phoneCtrl.dispose(); _otpCtrl.dispose();
    _newPwCtrl.dispose(); _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    final phoneInput = _phoneCtrl.text.trim();
    if (!PhoneUtils.isValidIndianPhone(phoneInput)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid Indian mobile number')));
      return;
    }
    setState(() => _isLoading = true);
    await ref.read(authNotifierProvider.notifier).requestPasswordReset(
      PhoneUtils.normalizeIndianPhone(phoneInput),
    );
    setState(() { _isLoading = false; _step = 2; });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('If an account exists, an OTP has been sent.')));
  }

  Future<void> _verifyReset() async {
    if (_otpCtrl.text.trim().length < AppConstants.otpLength) return;
    if (_newPwCtrl.text.length < AppConstants.passwordMinLength) return;
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }
    setState(() => _isLoading = true);
    final req = PasswordResetVerifyRequest(
      phone: PhoneUtils.normalizeIndianPhone(_phoneCtrl.text.trim()),
      otp: _otpCtrl.text.trim(),
      newPassword: _newPwCtrl.text,
    );
    final ok = await ref.read(authNotifierProvider.notifier).verifyPasswordReset(req);
    setState(() => _isLoading = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password updated. Please log in again.')));
      context.go('/login-password');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _step == 1 ? _s1() : _s2())),
    );
  }

  Widget _s1() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('Forgot Password?', style: AppTextStyles.headlineMedium), const SizedBox(height: 8),
    Text("Enter your phone number to receive a reset OTP.", style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
    const SizedBox(height: 32),
    TextField(
      controller: _phoneCtrl,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'Enter 10-digit mobile number',
        prefixText: '+91 ',
        prefixIcon: const Icon(Icons.phone_android),
        filled: true,
        fillColor: AppColors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
      ),
    ),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: _isLoading ? null : _requestReset, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send OTP', style: TextStyle(fontSize: 16))),
  ]);

  Widget _s2() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('Reset Password', style: AppTextStyles.headlineMedium), const SizedBox(height: 32),
    TextField(controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: AppConstants.otpLength, decoration: InputDecoration(hintText: 'Enter OTP', counterText: '', prefixIcon: const Icon(Icons.pin), filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
    const SizedBox(height: 16),
    TextField(controller: _newPwCtrl, obscureText: _obscureNew, decoration: InputDecoration(hintText: 'New Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscureNew = !_obscureNew)), filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
    const SizedBox(height: 16),
    TextField(controller: _confirmPwCtrl, obscureText: _obscureConfirm, decoration: InputDecoration(hintText: 'Confirm Password', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey), onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm)), filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
    const SizedBox(height: 32),
    ElevatedButton(onPressed: _isLoading ? null : _verifyReset, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Reset Password', style: TextStyle(fontSize: 16))),
  ]);
}
