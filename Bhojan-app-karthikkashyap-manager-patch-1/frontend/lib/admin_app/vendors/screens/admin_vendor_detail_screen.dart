import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/api/api_client.dart';
import '../models/admin_vendor_models.dart';
import '../services/admin_vendor_service.dart';

final _vendorServiceProvider = Provider<AdminVendorService>((ref) => AdminVendorService(ApiClient()));

class AdminVendorDetailScreen extends ConsumerStatefulWidget {
  final String vendorId;
  final String? vendorName;

  const AdminVendorDetailScreen({super.key, required this.vendorId, this.vendorName});

  @override
  ConsumerState<AdminVendorDetailScreen> createState() => _AdminVendorDetailScreenState();
}

class _AdminVendorDetailScreenState extends ConsumerState<AdminVendorDetailScreen> {
  AdminVendor? _vendor;
  bool _loading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadVendor();
  }

  Future<void> _loadVendor() async {
    try {
      final service = ref.read(_vendorServiceProvider);
      final vendor = await service.getVendor(widget.vendorId);
      if (mounted) setState(() { _vendor = vendor; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Failed to load vendor details.'; _loading = false; });
    }
  }

  void _showActionSheet(bool isSuspending) {
    final reasonCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        bool sheetLoading = false;
        return StatefulBuilder(
          builder: (ctx, setSheetState) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isSuspending ? 'Suspend ${_vendor?.name}?' : 'Reactivate ${_vendor?.name}?',
                  style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  isSuspending
                      ? 'This will immediately halt all vendor operations.'
                      : 'This vendor will be restored to the active listings.',
                  style: TextStyle(color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 20),
                const Text('REASON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.grey)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: reasonCtrl,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: isSuspending ? 'e.g. Policy violation...' : 'e.g. Issue resolved...',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: sheetLoading ? null : () async {
                      if (reasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please provide a reason'), backgroundColor: Colors.orange),
                        );
                        return;
                      }
                      setSheetState(() { sheetLoading = true; });
                      try {
                        final service = ref.read(_vendorServiceProvider);
                        if (isSuspending) {
                          await service.suspendVendor(widget.vendorId, reasonCtrl.text.trim());
                        } else {
                          await service.reactivateVendor(widget.vendorId, reasonCtrl.text.trim());
                        }
                        if (!mounted) return;
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isSuspending ? 'Vendor suspended.' : 'Vendor reactivated.'),
                            backgroundColor: isSuspending ? Colors.red.shade700 : AppColors.success,
                          ),
                        );
                        setState(() { _actionLoading = false; });
                        _loadVendor(); // refresh
                      } on AdminVendorException catch (e) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.userMessage), backgroundColor: Colors.red),
                        );
                      } catch (_) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Something went wrong. Please try again.'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSuspending ? Colors.red : AppColors.success,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: sheetLoading
                        ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isSuspending ? 'Confirm Suspend' : 'Confirm Reactivate',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Cancel', style: TextStyle(color: AppColors.primary)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.vendorName ?? 'Vendor Detail', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _vendor == null
                  ? const Center(child: Text('Vendor not found.'))
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    final v = _vendor!;
    final isSuspended = v.isSuspended;
    final isActive = v.isActive && !isSuspended;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(v.name, style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isActive ? 'Active' : 'Suspended',
                        style: TextStyle(
                          color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                          fontWeight: FontWeight.bold, fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),
                _infoRow(Icons.person, 'Contact', v.contactName ?? 'N/A'),
                _infoRow(Icons.phone, 'Phone', v.phone),
                _infoRow(Icons.email, 'Email', v.email),
                _infoRow(Icons.location_on, 'Address', '${v.address}, ${v.city}, ${v.state} - ${v.pincode}'),
                if (v.gstin != null && v.gstin!.isNotEmpty)
                  _infoRow(Icons.receipt_long, 'GSTIN', v.gstin!),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Action buttons
          if (isActive)
            _actionButton(
              label: 'Suspend Vendor',
              icon: Icons.block,
              color: Colors.red,
              onTap: () => _showActionSheet(true),
            ),
          if (isSuspended)
            _actionButton(
              label: 'Reactivate Vendor',
              icon: Icons.check_circle_outline,
              color: AppColors.success,
              onTap: () => _showActionSheet(false),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton({required String label, required IconData icon, required Color color, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _actionLoading ? null : onTap,
        icon: Icon(icon, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
