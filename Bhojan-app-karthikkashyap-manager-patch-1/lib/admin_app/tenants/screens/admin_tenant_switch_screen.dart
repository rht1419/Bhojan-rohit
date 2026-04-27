import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminTenantSwitchScreen extends StatefulWidget {
  const AdminTenantSwitchScreen({super.key});

  @override
  State<AdminTenantSwitchScreen> createState() => _AdminTenantSwitchScreenState();
}

class _AdminTenantSwitchScreenState extends State<AdminTenantSwitchScreen> {
  final _searchController = TextEditingController();
  String _selectedTenantId = 'tenant_1'; // Infosys selected by default in PNG

  final List<Map<String, dynamic>> _tenants = [
    {'id': 'tenant_1', 'name': 'Infosys Cafeteria', 'schema': 'schema_infosys', 'users': '1.2k', 'initial': 'I'},
    {'id': 'tenant_2', 'name': 'TCS Food Court', 'schema': 'schema_tcs', 'users': '850', 'initial': 'T'},
    {'id': 'tenant_3', 'name': 'Wipro Canteen', 'schema': 'schema_wipro', 'users': '3.4k', 'initial': 'W'},
    {'id': 'tenant_4', 'name': 'HCL Dining', 'schema': 'schema_hcl', 'users': '420', 'initial': 'H'},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Text('Switch Tenant', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Search Bar
              TextFormField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search tenants...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
              const SizedBox(height: 24),

              // Tenant List
              Expanded(
                child: ListView.builder(
                  itemCount: _tenants.length,
                  itemBuilder: (context, index) {
                    final tenant = _tenants[index];
                    final isSelected = _selectedTenantId == tenant['id'];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedTenantId = tenant['id']),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.grey.shade200),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: isSelected ? AppColors.primary : Colors.blueGrey.shade700,
                              radius: 24,
                              child: Text(tenant['initial'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          tenant['name'], 
                                          style: AppTextStyles.headlineSmall.copyWith(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary, size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('ID: ${tenant['schema']}', style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected ? Colors.greenAccent.shade100 : Colors.grey.shade200,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text('${tenant['users']} USERS', style: TextStyle(fontSize: 10, color: isSelected ? Colors.green.shade800 : Colors.grey.shade800)),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Apply Button
              ElevatedButton(
                onPressed: () {
                  // In a real app, update state and fetch tenant data
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tenant switched successfully.')));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Apply Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
