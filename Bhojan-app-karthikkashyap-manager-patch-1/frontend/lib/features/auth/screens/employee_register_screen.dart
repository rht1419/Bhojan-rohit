import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/phone_utils.dart';
import '../models/auth_response_models.dart';
import '../providers/auth_provider.dart';

/// Screen 4 — Employee Registration (EP-01, EP-02).
/// Employee must have selected a tenant on TenantSelectionScreen first.
class EmployeeRegisterScreen extends ConsumerStatefulWidget {
  final String tenantId;
  final String tenantName;

  const EmployeeRegisterScreen({
    Key? key,
    required this.tenantId,
    required this.tenantName,
  }) : super(key: key);

  @override
  ConsumerState<EmployeeRegisterScreen> createState() => _EmployeeRegisterScreenState();
}

class _EmployeeRegisterScreenState extends ConsumerState<EmployeeRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _agreedToTerms = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _employeeIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    // #region agent log H12 employee submit entry
    debugPrint('[DBG-H12] employee_submit tapped agreed=$_agreedToTerms phoneRaw=${_phoneController.text.trim()} tenant=${widget.tenantId}');
    // #endregion
    if (!_formKey.currentState!.validate() || !_agreedToTerms) {
      // #region agent log H12 employee submit blocked
      debugPrint('[DBG-H12] employee_submit blocked formValid=${_formKey.currentState!.validate()} agreed=$_agreedToTerms');
      // #endregion
      return;
    }

    setState(() => _isSubmitting = true);

    final request = RegisterRequest(
      userType: 'EMPLOYEE',
      fullName: _nameController.text.trim(),
      phone: PhoneUtils.normalizeIndianPhone(_phoneController.text.trim()),
      password: _passwordController.text,
      email: _emailController.text.trim(),
      employeeId: _employeeIdController.text.trim(),
    );

    final authNotifier = ref.read(authNotifierProvider.notifier);
    final result = await authNotifier.register(request);

    setState(() => _isSubmitting = false);

    if (result != null && mounted) {
      context.push('/verify-otp', extra: {
        'phone': PhoneUtils.normalizeIndianPhone(_phoneController.text.trim()),
        'otpReference': result.otpReference,
        'context': 'registration',
      });
    } else {
      final error = ref.read(authNotifierProvider).errorMessage;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.length < AppConstants.passwordMinLength) {
      return 'Password must be at least ${AppConstants.passwordMinLength} characters';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Must contain at least 1 uppercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Must contain at least 1 number';
    if (!RegExp(r'[!@#\$&*~]').hasMatch(value)) return 'Must contain at least 1 special character';
    return null;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Employee Registration', style: AppTextStyles.headlineMedium),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.business, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(widget.tenantName, style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                TextFormField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Full Name', prefixIcon: Icon(Icons.person_outline)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),

                // Work Email
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(hintText: 'Work Email', prefixIcon: Icon(Icons.email_outlined)),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Work email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Phone
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    hintText: 'Enter 10-digit mobile number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_android),
                  ),
                  validator: (v) => (v == null || !PhoneUtils.isValidIndianPhone(v.trim()))
                      ? 'Enter a valid Indian mobile number'
                      : null,
                ),
                const SizedBox(height: 16),

                // Employee ID
                TextFormField(
                  controller: _employeeIdController,
                  decoration: const InputDecoration(hintText: 'Employee ID', prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Employee ID is required' : null,
                ),
                const SizedBox(height: 24),

                Text('Create a password', style: AppTextStyles.labelLarge),
                const SizedBox(height: 12),

                // Password
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    hintText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: _validatePassword,
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Confirm Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                ),
                const SizedBox(height: 16),

                // Terms
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      activeColor: AppColors.primary,
                      onChanged: (v) => setState(() => _agreedToTerms = v ?? false),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          text: 'I agree to ',
                          style: AppTextStyles.bodyMedium,
                          children: [
                            TextSpan(text: 'terms and conditions', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            const TextSpan(text: ' & '),
                            TextSpan(text: 'privacy policy', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Submit
                ElevatedButton(
                  onPressed: (_agreedToTerms && !_isSubmitting) ? _submit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Sign Up', style: TextStyle(fontSize: 16)),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
