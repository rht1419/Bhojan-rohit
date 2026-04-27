import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen 12 — Delete Account (EP-13).
class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<DeleteAccountScreen> createState() => _DeleteAccountState();
}

class _DeleteAccountState extends ConsumerState<DeleteAccountScreen> {
  final _otpCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  bool _isLoading = false;
  bool _confirmed = false;

  @override
  void dispose() { _otpCtrl.dispose(); _reasonCtrl.dispose(); super.dispose(); }

  Future<void> _delete() async {
    if (_otpCtrl.text.trim().length < 6) return;
    setState(() => _isLoading = true);
    final ok = await ref.read(authNotifierProvider.notifier).deleteAccount(_otpCtrl.text.trim(), _reasonCtrl.text.trim().isEmpty ? null : _reasonCtrl.text.trim());
    setState(() => _isLoading = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted. We\'re sorry to see you go.')));
      context.go('/welcome');
    } else if (mounted) {
      final err = ref.read(authNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Deletion failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Delete Account', style: AppTextStyles.headlineMedium.copyWith(color: AppColors.error)), const SizedBox(height: 16),
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [const Icon(Icons.warning, color: AppColors.error), const SizedBox(width: 8), Text('This action is permanent', style: AppTextStyles.labelLarge.copyWith(color: AppColors.error))]),
            const SizedBox(height: 8),
            Text('• Your profile and all data will be permanently deleted\n• Any active orders will be cancelled\n• You will lose all wallet balance\n• This cannot be undone', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade800)),
          ]),
        ),
        const SizedBox(height: 24),
        CheckboxListTile(value: _confirmed, activeColor: AppColors.error, onChanged: (v) => setState(() => _confirmed = v ?? false), title: Text('I understand and want to proceed', style: AppTextStyles.bodyMedium), controlAffinity: ListTileControlAffinity.leading),
        if (_confirmed) ...[
          const SizedBox(height: 16),
          TextField(controller: _otpCtrl, keyboardType: TextInputType.number, maxLength: 6, decoration: InputDecoration(hintText: 'Enter OTP sent to your phone', counterText: '', filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
          const SizedBox(height: 16),
          TextField(controller: _reasonCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Reason for leaving (optional)', filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _isLoading ? null : _delete, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Delete My Account', style: TextStyle(fontSize: 16, color: Colors.white))),
        ],
      ]))),
    );
  }
}
