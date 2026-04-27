import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class AdminBulkUploadScreen extends StatelessWidget {
  const AdminBulkUploadScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral,
      appBar: AppBar(
        backgroundColor: AppColors.tertiary,
        title: Text('Bulk Upload', style: AppTextStyles.headlineSmall.copyWith(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Stepper
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildStep(1, 'Upload', isActive: false, isCompleted: true),
                _buildLine(isCompleted: true),
                _buildStep(2, 'Processing', isActive: true, isCompleted: false),
                _buildLine(isCompleted: false),
                _buildStep(3, 'Results', isActive: false, isCompleted: false),
              ],
            ),
            const SizedBox(height: 32),

            // Download Template Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.description, color: AppColors.primary),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Need the format?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Download CSV template', style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                      ],
                    ),
                  ),
                  const Icon(Icons.download, color: AppColors.primary),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // File Upload Area (Dashed)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                // Note: Native Flutter doesn't have a dashed border built-in easily without custom painter or package.
                // Using a solid border here to simulate it.
                border: Border.all(color: AppColors.primary, width: 1.5, style: BorderStyle.solid), 
              ),
              child: Column(
                children: [
                  const Icon(Icons.cloud_upload, color: AppColors.primary, size: 32),
                  const SizedBox(height: 12),
                  Text('employees_batch_04.csv', style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Progress Bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Processing 87 of 120...', style: TextStyle(color: Colors.grey.shade800)),
                      const Text('72%', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(
                    value: 0.72,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Initial Results
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Initial Results', style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  
                  // Success Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 12),
                        Text('104 Successful', style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Failed Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.error, color: Colors.red),
                        const SizedBox(width: 12),
                        Text('16 Failed', style: TextStyle(color: Colors.red.shade900, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Error Table
                  Table(
                    columnWidths: const { 0: FlexColumnWidth(1), 1: FlexColumnWidth(3) },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade100),
                        children: [
                          Padding(padding: const EdgeInsets.all(12), child: Text('Row', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                          Padding(padding: const EdgeInsets.all(12), child: Text('Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700))),
                        ],
                      ),
                      _buildTableRow('#12', 'Invalid Email Format'),
                      _buildTableRow('#45', 'Missing Phone Number'),
                      _buildTableRow('#89', 'Duplicate Record'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Download Failed Rows
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download, color: Colors.red),
                    label: const Text('Download Failed Rows', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      side: BorderSide(color: Colors.red.shade300),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  TableRow _buildTableRow(String row, String error) {
    return TableRow(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.black12))),
      children: [
        Padding(padding: const EdgeInsets.all(12), child: Text(row, style: TextStyle(color: Colors.grey.shade600))),
        Padding(padding: const EdgeInsets.all(12), child: Text(error, style: const TextStyle(color: Colors.red))),
      ],
    );
  }

  Widget _buildStep(int step, String label, {required bool isActive, required bool isCompleted}) {
    Color color = isCompleted ? AppColors.primary : (isActive ? AppColors.primary : Colors.grey.shade300);
    Color textColor = isCompleted || isActive ? AppColors.primary : Colors.grey.shade500;

    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isCompleted ? Colors.grey.shade200 : color, // The PNG shows completed as grey circle, active as green circle
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              step.toString(),
              style: TextStyle(color: isCompleted ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(color: textColor, fontSize: 12, fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildLine({required bool isCompleted}) {
    return Container(
      width: 40,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      color: isCompleted ? AppColors.primary : Colors.grey.shade300,
    );
  }
}
