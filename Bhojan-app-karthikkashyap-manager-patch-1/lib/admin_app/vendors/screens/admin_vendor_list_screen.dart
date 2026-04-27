import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';


class AdminVendorListScreen extends StatefulWidget {
  const AdminVendorListScreen({super.key});

  @override
  State<AdminVendorListScreen> createState() => _AdminVendorListScreenState();
}

class _AdminVendorListScreenState extends State<AdminVendorListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: const Text('Vendors', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white), onPressed: () {}),
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
            Tab(text: 'Active'),
            Tab(text: 'Suspended'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildVendorList(context, filter: 'all'),
          _buildVendorList(context, filter: 'active'),
          _buildVendorList(context, filter: 'suspended'),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/vendors/create'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),

    );
  }

  Widget _buildVendorList(BuildContext context, {required String filter}) {
    final List<Map<String, dynamic>> vendors = [
      {'name': 'MK Foods', 'tenant': 'TENANT A', 'status': 'Active', 'initials': 'MK'},
      {'name': 'Spice Garden', 'tenant': 'TENANT B', 'status': 'Active', 'initials': 'SG'},
      {'name': 'Green Bites', 'tenant': 'TENANT A', 'status': 'Suspended', 'initials': 'GB'},
      {'name': 'Dosa Hub', 'tenant': 'TENANT C', 'status': 'Active', 'initials': 'DH'},
    ];

    final filtered = vendors.where((v) => filter == 'all' || v['status'].toString().toLowerCase() == filter).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final vendor = filtered[index];
        final isActive = vendor['status'] == 'Active';

        return GestureDetector(
          onTap: () {
            context.push('/admin/vendors/detail', extra: {
              'vendorId': vendor['id'] ?? 'mock-id',
              'vendorName': vendor['name'],
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  radius: 24,
                  child: Text(vendor['initials'], style: TextStyle(color: AppColors.tertiary, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendor['name'], style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(4)),
                        child: Text(vendor['tenant'], style: TextStyle(fontSize: 10, color: Colors.grey.shade600, letterSpacing: 0.5)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.shade100 : Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    vendor['status'],
                    style: TextStyle(
                      color: isActive ? Colors.green.shade800 : Colors.red.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        );
      },
    );
  }
}
