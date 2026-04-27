import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'widgets/audit_log_detail_modal.dart';

class AdminAuditLogsScreen extends StatelessWidget {
  const AdminAuditLogsScreen({super.key});

  void _showDetailModal(BuildContext context, Map<String, dynamic> log) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) => AuditLogDetailModal(log: log),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> logs = [
      {
        'type': 'LOGIN',
        'color': AppColors.primary,
        'time': '10:42 AM',
        'desc': 'User auth token generated...',
        'ip': '192.168.1.45',
        'id': 'LOG-00481',
        'user': 'Ravi Kumar',
        'device': 'Chrome on Mac OS',
        'meta': '{\n  "method": "email_otp",\n  "success": true\n}'
      },
      {
        'type': 'SUSPEND',
        'color': Colors.red.shade700,
        'time': '09:15 AM',
        'desc': 'Vendor account #8493 suspended...',
        'ip': '10.0.0.12',
        'id': 'LOG-00482',
        'user': 'Admin Ravi',
        'device': 'Safari on iOS',
        'meta': '{\n  "vendor_id": "VND-8891",\n  "reason": "Policy violation",\n  "duration": "7 days"\n}'
      },
      {
        'type': 'UPLOAD',
        'color': Colors.blueGrey,
        'time': 'Yesterday, 16:30',
        'desc': 'Bulk menu inventory CSV imported...',
        'ip': '192.168.1.108',
      },
      {
        'type': 'LOGOUT',
        'color': Colors.grey.shade600,
        'time': 'Yesterday, 14:05',
        'desc': 'Session terminated by user request.',
        'ip': '172.16.254.1',
      },
      {
        'type': 'RESET',
        'color': AppColors.primary,
        'time': 'Yesterday, 09:00',
        'desc': 'Admin password reset link...',
        'ip': '192.168.1.45',
      },
    ];

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary), onPressed: () {}),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Audit Logs', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold)),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, size: 16, color: AppColors.primary),
                    label: const Text('Export CSV', style: TextStyle(color: AppColors.primary)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Filters
              Row(
                children: [
                  _buildFilterDropdown('User'),
                  const SizedBox(width: 8),
                  _buildFilterDropdown('Action'),
                  const SizedBox(width: 8),
                  Expanded(child: _buildFilterDropdown('Date Range')),
                ],
              ),
              const SizedBox(height: 24),

              // Log List
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return GestureDetector(
                      onTap: () {
                        if (log.containsKey('id')) {
                          _showDetailModal(context, log);
                        }
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: log['color'], borderRadius: BorderRadius.circular(12)),
                                  child: Text(log['type'], style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                Text(log['time'], style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(log['desc'], style: AppTextStyles.bodyLarge, overflow: TextOverflow.ellipsis),
                                ),
                                const Icon(Icons.chevron_right, color: Colors.grey),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.computer, size: 12, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('IP: ${log['ip']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Load More
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Load more', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    Icon(Icons.keyboard_arrow_down, color: AppColors.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          const Icon(Icons.arrow_drop_down, color: AppColors.primary, size: 16),
        ],
      ),
    );
  }
}
