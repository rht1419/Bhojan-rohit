import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/models/auth_response_models.dart';
import '../../auth/providers/auth_provider.dart';

/// Screen 11 — Upgrade Guest to Employee (EP-14).
class UpgradeToEmployeeScreen extends ConsumerStatefulWidget {
  const UpgradeToEmployeeScreen({Key? key}) : super(key: key);
  @override
  ConsumerState<UpgradeToEmployeeScreen> createState() => _UpgradeState();
}

class _UpgradeState extends ConsumerState<UpgradeToEmployeeScreen> {
  final _empIdCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() { _empIdCtrl.dispose(); _emailCtrl.dispose(); super.dispose(); }

  Future<void> _upgrade() async {
    if (_empIdCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final req = UpgradeToEmployeeRequest(employeeId: _empIdCtrl.text.trim(), workEmail: _emailCtrl.text.trim());
    final ok = await ref.read(authNotifierProvider.notifier).upgradeToEmployee(req);
    setState(() => _isLoading = false);
    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employee benefits activated!'), backgroundColor: AppColors.success));
      context.go('/profile');
    } else if (mounted) {
      final err = ref.read(authNotifierProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err ?? 'Upgrade failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () => context.pop())),
      body: SafeArea(child: SingleChildScrollView(padding: const EdgeInsets.all(24), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('Link Company Account', style: AppTextStyles.headlineMedium), const SizedBox(height: 8),
        Text('Enter your employee details to unlock company benefits.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)), const SizedBox(height: 32),
        TextField(controller: _empIdCtrl, decoration: InputDecoration(hintText: 'Employee ID', prefixIcon: const Icon(Icons.badge_outlined), filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        const SizedBox(height: 16),
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(hintText: 'Work Email', prefixIcon: const Icon(Icons.email_outlined), filled: true, fillColor: AppColors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none))),
        const SizedBox(height: 32),
        ElevatedButton(onPressed: _isLoading ? null : _upgrade, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
          child: _isLoading ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Upgrade to Employee', style: TextStyle(fontSize: 16))),
      ]))),
    );
  }
}
