import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminActiveSessionsScreen extends StatelessWidget {
  const AdminActiveSessionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> sessions = [
      {'device': 'Chrome on Mac OS', 'ip': '192.168.1.45', 'time': 'Active Now', 'isCurrent': true},
      {'device': 'Safari on iOS', 'ip': '10.0.0.12', 'time': 'Last active: 2 hours ago', 'isCurrent': false},
      {'device': 'Firefox on Windows', 'ip': '172.16.254.1', 'time': 'Last active: Yesterday', 'isCurrent': false},
    ];

    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Text('Active Sessions', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Manage Sessions', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Review devices that are currently logged into your account.', style: TextStyle(color: Colors.grey.shade600, height: 1.5)),
            const SizedBox(height: 32),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: session['isCurrent'] ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.grey.shade200),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2))],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: session['isCurrent'] ? Colors.green.shade50 : Colors.grey.shade100, shape: BoxShape.circle),
                        child: Icon(
                          session['device'].contains('iOS') || session['device'].contains('Android') ? Icons.phone_iphone : Icons.computer,
                          color: session['isCurrent'] ? AppColors.primary : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(session['device'], style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${session['ip']} • ${session['time']}', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                            if (session['isCurrent']) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                                child: const Text('Current Session', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (!session['isCurrent'])
                        TextButton(
                          onPressed: () {},
                          child: const Text('Revoke', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Terminate All Button
            OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.exit_to_app, color: Colors.red),
              label: const Text('Terminate All Other Sessions', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                side: BorderSide(color: Colors.red.shade300),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
