import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/api/api_client.dart';
import '../models/admin_vendor_models.dart';
import '../services/admin_vendor_service.dart';

final _adminVendorServiceProvider = Provider<AdminVendorService>((ref) {
  return AdminVendorService(ApiClient());
});

class AdminCreateVendorScreen extends ConsumerStatefulWidget {
  const AdminCreateVendorScreen({super.key});

  @override
  ConsumerState<AdminCreateVendorScreen> createState() => _AdminCreateVendorScreenState();
}

class _AdminCreateVendorScreenState extends ConsumerState<AdminCreateVendorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;

  // For SUPER_ADMIN: would be a dropdown from loaded tenants.
  // For simplicity, text input for now.
  final _tenantIdCtrl = TextEditingController();

  @override
  void dispose() {
    _contactNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _businessNameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _pincodeCtrl.dispose();
    _gstinCtrl.dispose();
    _tenantIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final service = ref.read(_adminVendorServiceProvider);
      await service.createVendor(AdminCreateVendorRequest(
        fullName: _contactNameCtrl.text.trim(),
        phone: '+91${_phoneCtrl.text.trim()}',
        email: _emailCtrl.text.trim(),
        businessName: _businessNameCtrl.text.trim(),
        businessAddress: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        state: _stateCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
        gstin: _gstinCtrl.text.trim().isEmpty ? null : _gstinCtrl.text.trim(),
        tenantId: _tenantIdCtrl.text.trim(),
      ));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vendor account created. Activation email sent to ${_emailCtrl.text.trim()}.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } on AdminVendorException catch (e) {
      setState(() { _errorMessage = e.userMessage; });
    } catch (e) {
      setState(() { _errorMessage = 'Something went wrong. Please try again.'; });
    } finally {
      if (mounted) setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('Add New Vendor', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'An activation email will be sent to the vendor\'s email address.',
                      style: TextStyle(color: Colors.blue.shade800, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            _sectionTitle('CONTACT INFORMATION'),
            const SizedBox(height: 12),
            _field('Contact Person Name', _contactNameCtrl, required: true,
                validator: (v) => (v?.isEmpty ?? true) ? 'Name is required' : null),
            _field('Phone Number (10 digits)', _phoneCtrl, keyboardType: TextInputType.phone, required: true,
                prefix: '+91 ',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Phone is required';
                  if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v)) return 'Enter a valid 10-digit Indian number';
                  return null;
                }),
            _field('Business Email', _emailCtrl, keyboardType: TextInputType.emailAddress, required: true,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Email is required';
                  if (!RegExp(r'^[\w.-]+@[\w.-]+\.\w+$').hasMatch(v)) return 'Enter a valid email';
                  return null;
                }),

            const SizedBox(height: 8),
            _sectionTitle('BUSINESS DETAILS'),
            const SizedBox(height: 12),
            _field('Business Name', _businessNameCtrl, required: true,
                validator: (v) => (v?.isEmpty ?? true) ? 'Business name is required' : null),
            _field('Business Address', _addressCtrl, required: true, maxLines: 2,
                validator: (v) => (v?.isEmpty ?? true) ? 'Address is required' : null),
            Row(
              children: [
                Expanded(child: _field('City', _cityCtrl, required: true,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null)),
                const SizedBox(width: 12),
                Expanded(child: _field('State', _stateCtrl, required: true,
                    validator: (v) => (v?.isEmpty ?? true) ? 'Required' : null)),
              ],
            ),
            Row(
              children: [
                Expanded(child: _field('Pincode', _pincodeCtrl, keyboardType: TextInputType.number, required: true,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length != 6) return 'Must be 6 digits';
                      return null;
                    })),
                const SizedBox(width: 12),
                Expanded(child: _field('GSTIN (optional)', _gstinCtrl)),
              ],
            ),

            const SizedBox(height: 8),
            _sectionTitle('TENANT ASSIGNMENT'),
            const SizedBox(height: 12),
            _field('Tenant ID', _tenantIdCtrl, required: true,
                validator: (v) => (v?.isEmpty ?? true) ? 'Tenant is required' : null),

            const SizedBox(height: 28),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Create Vendor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Text(label, style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.bold,
      color: Colors.grey.shade500, letterSpacing: 1.2,
    ));
  }

  Widget _field(
    String label,
    TextEditingController ctrl, {
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? prefix,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
          prefixText: prefix,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}
