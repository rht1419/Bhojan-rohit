import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/constants/error_codes.dart';
import '../models/auth_response_models.dart';
import '../providers/auth_provider.dart';

/// Screen 6 — Password Login (EP-03).
/// Phone-only login with lockout handling.
class LoginPasswordScreen extends ConsumerStatefulWidget {
  const LoginPasswordScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPasswordScreen> createState() => _LoginPasswordScreenState();
}

class _LoginPasswordScreenState extends ConsumerState<LoginPasswordScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isLocked = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.length < 10 || password.isEmpty) {
      setState(() => _errorMessage = 'Please enter your phone number and password.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; _isLocked = false; });

    final request = PasswordLoginRequest(phone: phone, password: password);
    final success = await ref.read(authNotifierProvider.notifier).loginWithPassword(request);

    if (!mounted) return;

    if (success) {
      context.go('/home');
    } else {
      final authState = ref.read(authNotifierProvider);
      setState(() {
        _isLoading = false;
        _errorMessage = authState.errorMessage;
        _isLocked = authState.errorCode == ErrorCodes.accountLocked;
      });
    }
  }

  Future<void> _simulateSsoLogin(String provider) async {
    setState(() { _isLoading = true; _errorMessage = null; _isLocked = false; });
    // Simulate SSO web flow delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    
    // In a real flow, this would call EP-15, get the Google auth code, send to backend EP-16, 
    // and then the backend returns the normal AuthTokenResponse.
    // For now, we mock success and just use the mock password login to set the state to authenticated.
    final request = PasswordLoginRequest(phone: '+919999999999', password: 'MockPassword123!');
    final success = await ref.read(authNotifierProvider.notifier).loginWithPassword(request);
    
    if (!mounted) return;
    if (success) {
      context.go('/home');
    } else {
      setState(() { _isLoading = false; _errorMessage = '$provider login failed (mock)'; });
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Login to Bhojan', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Enter your credentials to continue', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
              const SizedBox(height: 32),

              // Phone Input
              Text('Mobile Number', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'Enter mobile number',
                  prefixIcon: const Icon(Icons.phone_android, color: AppColors.primary),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),

              // Password Input
              Text('Password', style: AppTextStyles.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter your password',
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

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.push('/forgot-password'),
                  child: Text('Forgot Password?', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
              ),

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_isLocked ? AppColors.error : Colors.orange).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(_isLocked ? Icons.lock : Icons.warning_amber, color: _isLocked ? AppColors.error : Colors.orange, size: 20),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: AppTextStyles.bodyMedium.copyWith(color: _isLocked ? AppColors.error : Colors.orange.shade800))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              const SizedBox(height: 8),

              // Login Button
              ElevatedButton(
                onPressed: (_isLoading || _isLocked) ? null : _login,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Login', style: TextStyle(fontSize: 16)),
              ),

              const SizedBox(height: 24),

              // Switch to OTP login
              TextButton(
                onPressed: () {
                  context.pop();
                  context.push('/login-otp');
                },
                child: Text('Login with OTP instead', style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
              ),

              const SizedBox(height: 32),

              // SSO Options (AUTH-10)
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Or continue with', style: AppTextStyles.labelMedium.copyWith(color: Colors.grey)),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              const SizedBox(height: 24),

              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _simulateSsoLogin('Google'),
                icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.red),
                label: const Text('Google'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _isLoading ? null : () => _simulateSsoLogin('Microsoft'),
                icon: const Icon(Icons.window, size: 24, color: Colors.blue),
                label: const Text('Microsoft'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
