import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/vendor_button.dart';
import '../../shared/widgets/vendor_text_field.dart';
import '../models/vendor_auth_models.dart';
import '../providers/vendor_auth_provider.dart';

class VendorLoginScreen extends ConsumerStatefulWidget {
  const VendorLoginScreen({super.key});

  @override
  ConsumerState<VendorLoginScreen> createState() => _VendorLoginScreenState();
}

class _VendorLoginScreenState extends ConsumerState<VendorLoginScreen> {
  final _identifierController = TextEditingController(); // Phone or Email
  final _passwordController = TextEditingController();
  
  bool _usePassword = false;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleGetOtp() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) {
      setState(() => _errorMessage = 'Please enter your email or phone number.');
      return;
    }

    // For simplicity, we assume if it's mostly digits, it's a phone number.
    // In production, robust validation is needed.
    final isPhone = RegExp(r'^[0-9+]+$').hasMatch(identifier);
    String formattedPhone = identifier;
    if (isPhone && !identifier.startsWith('+')) {
      formattedPhone = '+91$identifier';
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final success = await ref.read(vendorAuthNotifierProvider.notifier).requestOtp(formattedPhone);

    if (!mounted) return;

    if (success) {
      context.push('/vendor/verify-phone', extra: {
        'phone': formattedPhone,
        'nextRoute': '/vendor/loading',
      });
      setState(() => _isLoading = false);
    } else {
      final vendorState = ref.read(vendorAuthNotifierProvider);
      setState(() {
        _isLoading = false;
        _errorMessage = vendorState.errorMessage;
      });
    }
  }

  Future<void> _handlePasswordLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    if (identifier.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your credentials.');
      return;
    }

    final isPhone = RegExp(r'^[0-9+]+$').hasMatch(identifier);
    String formattedPhone = identifier;
    if (isPhone && !identifier.startsWith('+')) {
      formattedPhone = '+91$identifier';
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    final request = VendorLoginRequest(phone: formattedPhone, password: password);
    final success = await ref.read(vendorAuthNotifierProvider.notifier).login(request);

    if (!mounted) return;

    if (success) {
      context.go('/vendor/loading');
    } else {
      final vendorState = ref.read(vendorAuthNotifierProvider);
      final code = vendorState.errorCode;

      // Handle specific errors
      if (code == 'EMAIL_NOT_VERIFIED') {
        context.go('/vendor/pending');
        return;
      }
      if (code == 'ACCOUNT_SUSPENDED' || code == 'ACCOUNT_DEACTIVATED') {
        context.push('/vendor/pending', extra: {
          'reason': vendorState.errorMessage,
          'errorCode': code,
        });
        return;
      }

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go('/vendor/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Logo
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco, size: 40, color: Colors.white),
                ),
              ),
              const SizedBox(height: 24),

              Text('Vendor Login', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                'Welcome back. Sign in to your outlet.',
                style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Identifier Input
              VendorTextField(
                label: 'Email or Phone',
                controller: _identifierController,
                onChanged: (_) => setState(() {}),
              ),
              
              if (_usePassword) ...[
                const SizedBox(height: 16),
                VendorTextField(
                  label: 'Password',
                  controller: _passwordController,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot-password'),
                    child: Text('Forgot Password?', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 24),
              ],

              // Error message
              if (_errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppColors.error, fontSize: 14)),
                ),
              ],

              // Actions
              if (_usePassword) ...[
                VendorButton(
                  text: 'Login',
                  isLoading: _isLoading,
                  onPressed: _handlePasswordLogin,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() { _usePassword = false; _errorMessage = null; }),
                  child: Text('Login with OTP instead', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
              ] else ...[
                VendorButton(
                  text: 'Get OTP',
                  isLoading: _isLoading,
                  onPressed: _handleGetOtp,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 24),
                VendorButton(
                  text: 'Login with Password',
                  isOutlined: true,
                  onPressed: () => setState(() { _usePassword = true; _errorMessage = null; }),
                ),
              ],

              const SizedBox(height: 32),

              // Register Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('New vendor? ', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                  TextButton(
                    onPressed: () => context.pushReplacement('/vendor/register'),
                    child: Text('Register here', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
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
