import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/vendor_auth_models.dart';
import '../providers/vendor_auth_provider.dart';

/// Vendor Account Activation Screen (EP-17 / AUTH-02).
/// Vendor opens this via deep link with ?token=xyz in the URL.
class VendorActivateScreen extends ConsumerStatefulWidget {
  final String? activationToken;
  const VendorActivateScreen({super.key, this.activationToken});

  @override
  ConsumerState<VendorActivateScreen> createState() => _VendorActivateScreenState();
}

class _VendorActivateScreenState extends ConsumerState<VendorActivateScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _isPasswordStrong(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) return false;
    return true;
  }

  Future<void> _activate() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.isEmpty || confirm.isEmpty) {
      setState(() => _errorMessage = 'Please fill in both fields.');
      return;
    }
    if (password != confirm) {
      setState(() => _errorMessage = 'Passwords do not match.');
      return;
    }
    if (!_isPasswordStrong(password)) {
      setState(() => _errorMessage = 'Password must be at least 8 characters with 1 uppercase, 1 number, and 1 special character.');
      return;
    }

    final token = widget.activationToken ?? '';
    if (token.isEmpty) {
      setState(() => _errorMessage = 'No activation token found. Please use the link from your email.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final request = VendorActivateRequest(activationToken: token, password: password);
    final success = await ref.read(vendorAuthNotifierProvider.notifier).activateAccount(request);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account activated successfully! Please log in.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/vendor/login');
    } else {
      final vendorState = ref.read(vendorAuthNotifierProvider);
      setState(() {
        _isLoading = false;
        _errorMessage = vendorState.errorMessage;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 60),

              // Logo area
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.store, size: 48, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 32),

              Text('Activate Your Account', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Set a password to activate your vendor account on Bhojan',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Password Field
              Text('Password', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Create a strong password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),

              // Confirm Password Field
              Text('Confirm Password', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  hintText: 'Re-enter your password',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.primary),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),

              // Password strength hint
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Min 8 characters · 1 uppercase · 1 number · 1 special character',
                        style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Activate Button
              ElevatedButton(
                onPressed: _isLoading ? null : _activate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Activate Account', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 24),

              // Already activated link
              TextButton(
                onPressed: () => context.go('/vendor/login'),
                child: Text('Already activated? Log in', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
