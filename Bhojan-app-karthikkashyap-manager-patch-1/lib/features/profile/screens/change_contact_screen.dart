import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/models/auth_response_models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';

/// Screen 10 — Change Contact (EP-11, EP-12).
class ChangeContactScreen extends ConsumerStatefulWidget {
  const ChangeContactScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<ChangeContactScreen> createState() => _ChangeContactScreenState();
}

class _ChangeContactScreenState extends ConsumerState<ChangeContactScreen> {
  int _step = 1;
  String _type = 'phone';
  String? _requestId;
  bool _isLoading = false;
  final _newValueCtrl = TextEditingController();
  final _otpOldCtrl = TextEditingController();
  final _otpNewCtrl = TextEditingController();

  @override
  void dispose() { _newValueCtrl.dispose(); _otpOldCtrl.dispose(); _otpNewCtrl.dispose(); super.dispose(); }

  Future<void> _requestChange() async {
    if (_newValueCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      final resp = await service.requestContactChange(ContactChangeRequest(type: _type, newValue: _newValueCtrl.text.trim()));
      _requestId = resp.requestId;
      setState(() { _step = 2; _isLoading = false; });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent to both your current and new contact')));
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _verifyChange() async {
    if (_otpOldCtrl.text.trim().length < 6 || _otpNewCtrl.text.trim().length < 6) return;
    setState(() => _isLoading = true);
    try {
      final service = ref.read(authServiceProvider);
      final result = await service.verifyContactChange(ContactVerifyRequest(requestId: _requestId!, otpOld: _otpOldCtrl.text.trim(), otpNew: _otpNewCtrl.text.trim()));
      final storage = ref.read(storageServiceProvider);
      await storage.saveTokens(result.accessToken, result.refreshToken);
      setState(() => _isLoading = false);
      if (mounted) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Contact updated successfully'))); context.pop(); }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Verification failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: _step == 1 ? _buildStep1() : _buildStep2())),
    );
  }

  Widget _buildStep1() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('Change Contact', style: AppTextStyles.headlineMedium), const SizedBox(height: 24),
    SegmentedButton<String>(segments: const [ButtonSegment(value: 'phone', label: Text('Phone')), ButtonSegment(value: 'email', label: Text('Email'))], selected: {_type}, onSelectionChanged: (s) => setState(() => _type = s.first)),
    const SizedBox(height: 24),
    TextField(controller: _newValueCtrl, keyboardType: _type == 'phone' ? TextInputType.phone : TextInputType.emailAddress, decoration: InputDecoration(hintText: _type == 'phone' ? 'New phone number' : 'New email address', prefixIcon: Icon(_type == 'phone' ? Icons.phone_android : Icons.email_outlined), filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: _isLoading ? null : _requestChange, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Send OTP')),
  ]);

  Widget _buildStep2() => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('Verify OTPs', style: AppTextStyles.headlineMedium), const SizedBox(height: 8),
    Text('Enter the OTP sent to your current and new $_type.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)), const SizedBox(height: 24),
    TextField(controller: _otpOldCtrl, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(hintText: 'OTP from current $_type', counterText: '', filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
    const SizedBox(height: 16),
    TextField(controller: _otpNewCtrl, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(hintText: 'OTP from new $_type', counterText: '', filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: _isLoading ? null : _verifyChange, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify & Update')),
  ]);
}
