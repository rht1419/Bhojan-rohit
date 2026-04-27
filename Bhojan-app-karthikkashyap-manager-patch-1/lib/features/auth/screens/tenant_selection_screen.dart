import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/tenant_model.dart';
import '../models/auth_response_models.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';

/// Screen 1 — Tenant Selection (EP-35, EP-37).
/// Employee users must pick their company before registering.
class TenantSelectionScreen extends ConsumerStatefulWidget {
  const TenantSelectionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TenantSelectionScreen> createState() => _TenantSelectionScreenState();
}

class _TenantSelectionScreenState extends ConsumerState<TenantSelectionScreen> {
  List<TenantModel> _allTenants = [];
  List<TenantModel> _filteredTenants = [];
  bool _isLoading = true;
  String? _error;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTenants() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final service = ref.read(authServiceProvider);
      final tenants = await service.getTenants();
      setState(() {
        _allTenants = tenants;
        _filteredTenants = tenants;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  void _filterTenants(String query) {
    setState(() {
      _filteredTenants = _allTenants.where((t) {
        final q = query.toLowerCase();
        return t.name.toLowerCase().contains(q) ||
               t.city.toLowerCase().contains(q) ||
               t.location.toLowerCase().contains(q);
      }).toList();
    });
  }

  Future<void> _onTenantTap(TenantModel tenant) async {
    // Validate via EP-37
    final service = ref.read(authServiceProvider);
    final result = await service.validateTenant(TenantValidateRequest(tenantId: tenant.id));

    if (!mounted) return;

    if (!result.isAccepting) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.message ?? 'This location is not accepting registrations.')),
      );
      return;
    }

    // Navigate to Employee Registration with tenant info
    context.push('/register/employee', extra: {
      'tenantId': tenant.id,
      'tenantName': tenant.name,
    });
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
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Select your company', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 8),
              Text('Find your company to access employee benefits.', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade700)),
              const SizedBox(height: 24),

              // Search bar
              TextField(
                controller: _searchController,
                onChanged: _filterTenants,
                decoration: InputDecoration(
                  hintText: 'Search companies...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: AppColors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),

              // List
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Failed to load companies', style: AppTextStyles.bodyMedium),
                                const SizedBox(height: 12),
                                ElevatedButton(onPressed: _loadTenants, child: const Text('Retry')),
                              ],
                            ),
                          )
                        : _filteredTenants.isEmpty
                            ? Center(child: Text('No companies found', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)))
                            : ListView.separated(
                                itemCount: _filteredTenants.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final tenant = _filteredTenants[index];
                                  return _TenantCard(tenant: tenant, onTap: () => _onTenantTap(tenant));
                                },
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TenantCard extends StatelessWidget {
  final TenantModel tenant;
  final VoidCallback onTap;

  const _TenantCard({required this.tenant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            // Logo placeholder
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: tenant.logoUrl != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(tenant.logoUrl!, fit: BoxFit.cover))
                  : Center(child: Text(tenant.name[0], style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tenant.name, style: AppTextStyles.labelLarge),
                  const SizedBox(height: 4),
                  Text('${tenant.city} · ${tenant.location}', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey.shade600)),
                ],
              ),
            ),
            if (tenant.hasActiveCafeteria)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Text('Active', style: AppTextStyles.labelMedium.copyWith(color: AppColors.success)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
