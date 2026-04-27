import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/api/api_client.dart';
import '../../../../core/api/interceptors/auth_interceptor.dart';
import '../../../../core/api/interceptors/error_interceptor.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/storage_service.dart';
import '../models/admin_vendor_models.dart';
import '../services/admin_vendor_service.dart';

// ── Provider ──────────────────────────────────────────────────────────────────

final _adminVendorServiceProvider = Provider<AdminVendorService>((ref) {
  final storage = StorageService.instance;
  final api = ApiClient();
  api.dio.interceptors.add(AuthInterceptor(storage, api.dio));
  api.dio.interceptors.add(ErrorInterceptor());
  return AdminVendorService(api);
});

final _vendorListProvider = FutureProvider.family<List<AdminVendor>, String>((ref, status) {
  return ref.read(_adminVendorServiceProvider).listVendors(status: status);
});

// ── Screen ────────────────────────────────────────────────────────────────────

class AdminVendorListScreen extends ConsumerStatefulWidget {
  const AdminVendorListScreen({super.key});

  @override
  ConsumerState<AdminVendorListScreen> createState() => _AdminVendorListScreenState();
}

class _AdminVendorListScreenState extends ConsumerState<AdminVendorListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _refresh() {
    ref.invalidate(_vendorListProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: const Text('Vendors', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _refresh),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: CircleAvatar(
              backgroundColor: Colors.white24,
              radius: 16,
              child: Text('AU', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending'),
            Tab(text: 'Active'),
            Tab(text: 'Suspended'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _VendorTabView(statusFilter: 'all', onAction: _refresh),
          _VendorTabView(statusFilter: 'pending', onAction: _refresh),
          _VendorTabView(statusFilter: 'active', onAction: _refresh),
          _VendorTabView(statusFilter: 'suspended', onAction: _refresh),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/vendors/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ── Tab content ───────────────────────────────────────────────────────────────

class _VendorTabView extends ConsumerWidget {
  final String statusFilter;
  final VoidCallback onAction;

  const _VendorTabView({required this.statusFilter, required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(_vendorListProvider(statusFilter));

    return async.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            Text('Failed to load vendors', style: AppTextStyles.bodyMedium),
            TextButton(onPressed: onAction, child: const Text('Retry')),
          ],
        ),
      ),
      data: (vendors) {
        if (vendors.isEmpty) {
          return Center(
            child: Text(
              statusFilter == 'pending'
                  ? 'No pending vendor applications'
                  : 'No vendors found',
              style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: vendors.length,
          itemBuilder: (context, index) => _VendorCard(
            vendor: vendors[index],
            onActionDone: onAction,
          ),
        );
      },
    );
  }
}

// ── Vendor card ───────────────────────────────────────────────────────────────

class _VendorCard extends ConsumerWidget {
  final AdminVendor vendor;
  final VoidCallback onActionDone;

  const _VendorCard({required this.vendor, required this.onActionDone});

  Color get _statusColor {
    switch (vendor.status) {
      case 'active':    return Colors.green.shade100;
      case 'pending':   return Colors.orange.shade100;
      case 'suspended': return Colors.red.shade100;
      default:          return Colors.grey.shade200;
    }
  }

  Color get _statusTextColor {
    switch (vendor.status) {
      case 'active':    return Colors.green.shade800;
      case 'pending':   return Colors.orange.shade800;
      case 'suspended': return Colors.red.shade800;
      default:          return Colors.grey.shade700;
    }
  }

  String get _statusLabel {
    switch (vendor.status) {
      case 'active':    return 'Active';
      case 'pending':   return 'Pending Review';
      case 'suspended': return 'Suspended';
      default:          return vendor.status;
    }
  }

  String get _initials {
    final parts = vendor.name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return vendor.name.isNotEmpty ? vendor.name[0].toUpperCase() : 'V';
  }

  void _showCompleteDialog(BuildContext context, WidgetRef ref) {
    final addressCtrl  = TextEditingController();
    final cityCtrl     = TextEditingController();
    final stateCtrl    = TextEditingController();
    final pincodeCtrl  = TextEditingController();
    final tenantCtrl   = TextEditingController();
    final gstinCtrl    = TextEditingController();
    bool saving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Complete Registration — ${vendor.name}', style: AppTextStyles.headlineSmall),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field(addressCtrl, 'Business Address *'),
                const SizedBox(height: 12),
                _field(cityCtrl, 'City *'),
                const SizedBox(height: 12),
                _field(stateCtrl, 'State *'),
                const SizedBox(height: 12),
                _field(pincodeCtrl, 'Pincode *', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _field(tenantCtrl, 'Tenant ID (UUID) *'),
                const SizedBox(height: 12),
                _field(gstinCtrl, 'GSTIN (optional)'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      final address = addressCtrl.text.trim();
                      final city    = cityCtrl.text.trim();
                      final state   = stateCtrl.text.trim();
                      final pincode = pincodeCtrl.text.trim();
                      final tenant  = tenantCtrl.text.trim();

                      if (address.isEmpty || city.isEmpty || state.isEmpty ||
                          pincode.isEmpty || tenant.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please fill all required fields')),
                        );
                        return;
                      }

                      setDialogState(() => saving = true);
                      try {
                        final service = ref.read(_adminVendorServiceProvider);
                        await service.completeVendorRegistration(
                          vendor.id,
                          CompleteVendorRequest(
                            businessAddress: address,
                            city: city,
                            state: state,
                            pincode: pincode,
                            tenantId: tenant,
                            gstin: gstinCtrl.text.trim().isEmpty ? null : gstinCtrl.text.trim(),
                          ),
                        );
                        if (ctx.mounted) Navigator.pop(ctx);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile completed. Activation email sent.'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                        onActionDone();
                      } on AdminVendorException catch (e) {
                        setDialogState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.userMessage), backgroundColor: AppColors.error),
                          );
                        }
                      } catch (_) {
                        setDialogState(() => saving = false);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Something went wrong'), backgroundColor: AppColors.error),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Complete & Send Email', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => context.push('/admin/vendors/detail', extra: {
        'vendorId': vendor.id,
        'vendorName': vendor.name,
      }),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 24,
                  child: Text(_initials, style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor.name, style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text(vendor.email, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(12)),
                  child: Text(_statusLabel, style: TextStyle(color: _statusTextColor, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            if (vendor.status == 'pending') ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: Colors.orange),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Self-registered — complete profile to send activation email',
                      style: TextStyle(fontSize: 11, color: Colors.orange.shade800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showCompleteDialog(context, ref),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Complete Registration'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
