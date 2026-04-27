import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AuditLogDetailModal extends StatelessWidget {
  final Map<String, dynamic> log;

  const AuditLogDetailModal({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 60), // Space for status bar
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        ),
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle Bar
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 24),
                  width: 48,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: log['color'], borderRadius: BorderRadius.circular(16)),
                      child: Text(log['type'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.grey),
                      onPressed: () => Navigator.of(context).pop(),
                      style: IconButton.styleFrom(backgroundColor: Colors.grey.shade100),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text('Vendor Suspended', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(log['id'] ?? '', style: TextStyle(color: Colors.grey.shade500)),
                    const SizedBox(height: 24),

                    // Info Table
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: AppColors.neutral, borderRadius: BorderRadius.circular(12)),
                      child: Column(
                        children: [
                          _buildInfoRow('User', log['user'] ?? ''),
                          const Divider(height: 24, color: Colors.black12),
                          _buildInfoRow('Timestamp', 'Oct 24, 14:32:05'),
                          const Divider(height: 24, color: Colors.black12),
                          _buildInfoRow('IP Address', log['ip'] ?? ''),
                          const Divider(height: 24, color: Colors.black12),
                          _buildInfoRow('Device', log['device'] ?? ''),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Metadata
                    Text('Metadata', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E293B), // Dark code-like background
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log['meta'] ?? '{}',
                        style: const TextStyle(fontFamily: 'monospace', color: Colors.greenAccent, fontSize: 12, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Close Button
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                      child: const Text('Close', style: TextStyle(fontSize: 16, color: AppColors.primary)),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
