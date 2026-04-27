import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/services/auth_service.dart';
import '../models/profile_model.dart';

/// Screen 7 — View Profile (EP-06).
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  ProfileModel? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(authServiceProvider);
      final profile = await service.getProfile();
      setState(() { _profile = profile; _isLoading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('My Profile', style: AppTextStyles.headlineSmall),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.primary),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Failed to load profile', style: AppTextStyles.bodyMedium),
                      const SizedBox(height: 12),
                      ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildProfileContent(),
    );
  }

  Widget _buildProfileContent() {
    final p = _profile!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 50,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: p.avatarUrl != null ? NetworkImage(p.avatarUrl!) : null,
            child: p.avatarUrl == null
                ? Text(p.fullName[0].toUpperCase(), style: AppTextStyles.headlineLarge.copyWith(color: AppColors.primary))
                : null,
          ),
          const SizedBox(height: 16),
          Text(p.fullName, style: AppTextStyles.headlineMedium),
          const SizedBox(height: 8),

          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: p.role == 'GUEST' ? Colors.orange.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              p.isEmployee ? 'Employee' : 'Guest',
              style: AppTextStyles.labelMedium.copyWith(
                color: p.role == 'GUEST' ? Colors.orange.shade800 : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Info rows
          _InfoRow(icon: Icons.phone, label: 'Phone', value: p.phone),
          if (p.email != null) _InfoRow(icon: Icons.email_outlined, label: 'Email', value: p.email!),
          if (p.employeeId != null) _InfoRow(icon: Icons.badge_outlined, label: 'Employee ID', value: p.employeeId!),
          if (p.department != null) _InfoRow(icon: Icons.business, label: 'Department', value: p.department!),
          if (p.floor != null) _InfoRow(icon: Icons.stairs, label: 'Floor', value: p.floor!),
          if (p.building != null) _InfoRow(icon: Icons.apartment, label: 'Building', value: p.building!),
          if (p.dietaryPreference != null) _InfoRow(icon: Icons.restaurant, label: 'Dietary Preference', value: p.dietaryPreference!),

          const SizedBox(height: 32),

          // Actions
          if (p.role == 'GUEST') ...[
            OutlinedButton.icon(
              onPressed: () => context.push('/upgrade-to-employee'),
              icon: const Icon(Icons.upgrade, color: AppColors.primary),
              label: const Text('Link Company Account'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 12),
          ],

          OutlinedButton.icon(
            onPressed: () => context.push('/change-contact'),
            icon: const Icon(Icons.swap_horiz, color: AppColors.primary),
            label: const Text('Change Phone / Email'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(height: 12),

          OutlinedButton.icon(
            onPressed: () async {
              await ref.read(authNotifierProvider.notifier).logout();
              if (mounted) context.go('/welcome');
            },
            icon: const Icon(Icons.logout, color: AppColors.error),
            label: Text('Logout', style: TextStyle(color: AppColors.error)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              side: BorderSide(color: AppColors.error.withOpacity(0.3)),
            ),
          ),
          const SizedBox(height: 12),

          TextButton(
            onPressed: () => context.push('/delete-account'),
            child: Text('Delete Account', style: AppTextStyles.labelMedium.copyWith(color: AppColors.error)),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelMedium.copyWith(color: Colors.grey)),
                Text(value, style: AppTextStyles.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
