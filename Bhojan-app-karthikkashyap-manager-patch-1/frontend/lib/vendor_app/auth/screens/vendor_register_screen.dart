import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../shared/widgets/vendor_button.dart';
import '../../shared/widgets/vendor_text_field.dart';
import '../models/vendor_auth_models.dart';
import '../providers/vendor_auth_provider.dart';

class VendorRegisterScreen extends ConsumerStatefulWidget {
  const VendorRegisterScreen({super.key});

  @override
  ConsumerState<VendorRegisterScreen> createState() => _VendorRegisterScreenState();
}

class _VendorRegisterScreenState extends ConsumerState<VendorRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _categoryController = TextEditingController();

  final List<String> _categories = ['Cloud Kitchen', 'Restaurant', 'Cafe', 'Bakery'];
  bool _isLoading = false;

  @override
  void dispose() {
    _businessNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) => RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
  bool _isValidPhone(String phone) => phone.length == 10 && RegExp(r'^[0-9]+$').hasMatch(phone);

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Category', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 16),
              ..._categories.map((c) => ListTile(
                title: Text(c, style: AppTextStyles.bodyLarge),
                onTap: () {
                  setState(() => _categoryController.text = c);
                  Navigator.pop(ctx);
                },
              )),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    final phone = _phoneController.text.trim();
    final formattedPhone = phone.startsWith('+91') ? phone : '+91$phone';

    final request = VendorRegisterRequest(
      businessName: _businessNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: formattedPhone,
      category: _categoryController.text.trim(),
    );

    setState(() => _isLoading = true);

    final success = await ref.read(vendorAuthNotifierProvider.notifier).register(request);

    if (!mounted) return;

    if (success) {
      // Navigate to verify phone screen, passing the phone and context
      context.push('/vendor/verify-phone', extra: {
        'phone': formattedPhone,
        'nextRoute': '/vendor/registration-status',
      });
    } else {
      final vendorState = ref.read(vendorAuthNotifierProvider);
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vendorState.errorMessage ?? 'Registration failed')),
      );
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo & Title
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.eco, size: 32, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                
                Text('Register Your Business', style: AppTextStyles.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Create your vendor account to get started',
                  style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Form Fields
                VendorTextField(
                  label: 'BUSINESS NAME',
                  controller: _businessNameController,
                  isValid: _businessNameController.text.length > 2,
                  onChanged: (_) => setState(() {}),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),

                VendorTextField(
                  label: 'EMAIL ADDRESS',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  isValid: _isValidEmail(_emailController.text),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => !_isValidEmail(v ?? '') ? 'Enter valid email' : null,
                ),
                const SizedBox(height: 16),

                VendorTextField(
                  label: 'PHONE NUMBER',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixText: '+91 ',
                  isValid: _isValidPhone(_phoneController.text),
                  onChanged: (_) => setState(() {}),
                  validator: (v) => !_isValidPhone(v ?? '') ? 'Enter 10 digit number' : null,
                ),
                const SizedBox(height: 16),

                VendorTextField(
                  label: 'VENDOR CATEGORY',
                  controller: _categoryController,
                  isDropdown: true,
                  isValid: _categoryController.text.isNotEmpty,
                  onTap: _showCategoryPicker,
                  validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                ),

                const SizedBox(height: 40),

                // Submit
                VendorButton(
                  text: 'Submit & Verify',
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),

                // Login Link
                TextButton(
                  onPressed: () => context.pushReplacement('/vendor/login'),
                  child: Text(
                    'Already have an account? Login',
                    style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
