import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminPermissionMatrixScreen extends StatelessWidget {
  const AdminPermissionMatrixScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> modules = [
      {'name': 'Dashboard', 'sa': true, 'oa': true, 'ta': true, 'su': true},
      {'name': 'Vendors (View)', 'sa': true, 'oa': true, 'ta': true, 'su': false},
      {'name': 'Vendors (Edit)', 'sa': true, 'oa': true, 'ta': false, 'su': false},
      {'name': 'Orders', 'sa': true, 'oa': true, 'ta': false, 'su': true},
      {'name': 'System Logs', 'sa': true, 'oa': false, 'ta': true, 'su': false},
      {'name': 'DB Config', 'sa': true, 'oa': false, 'ta': true, 'su': false},
      {'name': 'Audit Trails', 'sa': true, 'oa': true, 'ta': true, 'su': false},
      {'name': 'Role Assign', 'sa': true, 'oa': false, 'ta': false, 'su': false},
      {'name': 'Tenant Config', 'sa': true, 'oa': false, 'ta': true, 'su': false},
    ];

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Text('Permission Matrix', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Role Access Map', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Detailed view of module permissions across all 4 admin personas.', style: TextStyle(color: Colors.grey.shade600)),
              const SizedBox(height: 24),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildLegendItem('SA', 'Super'),
                  _buildLegendItem('OA', 'Ops'),
                  _buildLegendItem('TA', 'Tech'),
                  _buildLegendItem('SU', 'Sub'),
                ],
              ),
              const SizedBox(height: 24),

              // Matrix Table
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                ),
                child: Table(
                  border: TableBorder.symmetric(inside: BorderSide(color: Colors.grey.shade200)),
                  columnWidths: const {
                    0: FlexColumnWidth(2.5),
                    1: FlexColumnWidth(1),
                    2: FlexColumnWidth(1),
                    3: FlexColumnWidth(1),
                    4: FlexColumnWidth(1),
                  },
                  children: [
                    // Header Row
                    TableRow(
                      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(top: Radius.circular(12))),
                      children: [
                        const Padding(padding: EdgeInsets.all(12), child: Text('Module', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        _buildTableHeader('SA'),
                        _buildTableHeader('OA'),
                        _buildTableHeader('TA'),
                        _buildTableHeader('SU'),
                      ],
                    ),
                    // Data Rows
                    ...modules.map((m) {
                      return TableRow(
                        children: [
                          Padding(padding: const EdgeInsets.all(12), child: Text(m['name'], style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                          _buildTableData(m['sa']),
                          _buildTableData(m['oa']),
                          _buildTableData(m['ta']),
                          _buildTableData(m['su']),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(String initials, String label) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: Colors.blueGrey.shade100, shape: BoxShape.circle),
          child: Text(initials, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blueGrey.shade800)),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildTableHeader(String label) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12))),
    );
  }

  Widget _buildTableData(bool hasAccess) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Center(
        child: Icon(
          hasAccess ? Icons.check_circle : Icons.cancel,
          color: hasAccess ? Colors.green : Colors.grey.shade300,
          size: 16,
        ),
      ),
    );
  }
}
